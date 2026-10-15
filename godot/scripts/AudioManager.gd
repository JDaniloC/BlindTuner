extends Node
## Autoload singleton — gera e toca tons sintetizados representando cada nota.
## Serializa o playback: um único player ativo por vez. Cada chamada de
## play_note/play_collision_sfx cancela o anterior, garantindo:
##   - notas repetidas sempre tocam (sem silent-fail por overlap)
##   - nunca 2 sons simultâneos (clareza pedagógica)

const MIX_RATE := 44100.0
const NOTE_DURATION_SEC := 0.6
const COLLISION_DURATION_SEC := 0.2
const ATTACK_SEC := 0.01
const DECAY_SEC := 0.15
const SUSTAIN_LEVEL := 0.4
const RELEASE_SEC := 0.3
const COLLISION_FREQ := 80.0
# AudioStreamGeneratorPlayback arredonda o buffer pra cima na proxima potencia
# de 2 (nearest_shift(mix_rate * buffer_length)). Com 44100Hz, 0.04 (1764
# frames) vira 2048 frames (~46ms) -- ainda folgado o bastante acima do
# consumo por frame a 60fps (~735 frames/frame) pra nao dar underrun, mas bem
# mais responsivo que um buffer "cheio" de ~186ms (o que 0.1 geraria: 4410 ->
# 8192 frames). Esse latencia eh o atraso entre mudar _pitch_freq e o som
# realmente mudar, pois o buffer fica sempre cheio de amostras ja geradas.
const PITCH_BUFFER_LEN_SEC := 0.04
const NOTE_MISS_FREQ := 220.0
# Curto porque é feedback de erro, não uma nota a reconhecer. A envoltória NÃO
# impõe piso a esta duração: _envelope_segments comprime os quatro trechos pra
# caber em qualquer duração. Antes disso o piso existia e não era respeitado --
# 0,2s é MENOR que ataque+decay+release (0,46s) e produzia sustain negativo.
const NOTE_MISS_DURATION_SEC := 0.2
# Esmaece o volume antes de parar o tom contínuo, senão .stop() corta a onda
# senoidal num ponto arbitrário do ciclo -- click audível em toda soltada do
# slider no modo Scroll de Afinação. Curto o bastante pra não atrasar
# perceptivelmente a resposta, longo o bastante pra evitar a descontinuidade.
const PITCH_STOP_FADE_SEC := 0.012
const VIBRATO_RATE_HZ := 6.0
const VIBRATO_DEPTH_CENTS := 18.0
const TREMOLO_DEPTH := 0.12
# Deslocamento de fase do tremolo (amplitude) em relação ao vibrato (pitch) --
# num instrumento real, pressão/velocidade do arco e afinação não oscilam em
# lockstep perfeito. Com a mesma fase, pitch e volume sobem/descem juntos de
# forma perfeitamente correlacionada -- efeito de tremor sincronizado (mais
# "trilha de terror" que corda de verdade). 0.27 (~27% do ciclo) desacopla.
const TREMOLO_PHASE_OFFSET := 0.27
const BOW_NOISE_GAIN := 0.03
# Coeficiente do filtro passa-baixa de 1 polo do ruído de arco (lerp por
# amostra). 0.1 (corte ~740Hz) deixa agudo demais passar -- soa como estática
# em vez de sopro. ~0.035 baixa o corte pra ~200-300Hz, mais quente/orgânico.
const NOISE_LOWPASS_COEFF := 0.035
# Amplitudes decrescentes dos harmônicos (fundamental + 4 acima) -- é
# fisicamente o que a fricção do arco contra a corda produz (onda rica em
# harmônicos, tipo dente-de-serra), diferente da senoide pura anterior.
const HARMONIC_GAINS := [1.0, 0.5, 0.3, 0.2, 0.1]
# Soma pré-computada de HARMONIC_GAINS -- evita recalcular a soma toda vez que
# _string_harmonics() roda (por AMOSTRA de áudio, milhares de vezes/segundo).
const HARMONIC_GAIN_TOTAL := 2.1
# LFO de vibrato é 6Hz -- recalcular o multiplicador a cada amostra (44100/s)
# é desnecessário e inaudível a essa taxa de mudança. Recalcula só a cada N
# amostras (ver _fill_pitch_buffer/_vibrato_sample_counter).
const VIBRATO_CONTROL_RATE_SAMPLES := 32

const STRINGS_BUS_NAME := "Strings"
const STRINGS_EQ_BOOST_DB := 2.5
const STRINGS_EQ_BOOST_TARGETS_HZ := [300.0, 700.0, 2500.0]
const EQ10_BAND_FREQS := [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0]
const BEACON_BUS_NAME := "Beacon"

var _current_player: AudioStreamPlayer = null
var _pitch_player: AudioStreamPlayer = null
var _pitch_playback: AudioStreamGeneratorPlayback = null
var _pitch_phase := 0.0
var _pitch_freq := 0.0
var _pitch_lfo_phase := 0.0
var _noise_lp := 0.0
var _vibrato_sample_counter := 0
var _beacon_stream_cache: Dictionary = {}

func _ready() -> void:
    _ensure_strings_bus()
    _ensure_beacon_bus()

## Cria (se ainda não existir) o bus "Strings" com EQ + chorus, só pro tom
## contínuo do Scroll de Afinação -- fica separado do bus Master, onde tocam
## as notas normais e os SFX de colisão/erro, pra não colori-los também.
func _ensure_strings_bus() -> void:
    if AudioServer.get_bus_index(STRINGS_BUS_NAME) != -1:
        return
    var idx := AudioServer.bus_count
    AudioServer.add_bus(idx)
    AudioServer.set_bus_name(idx, STRINGS_BUS_NAME)
    AudioServer.set_bus_send(idx, "Master")
    var eq := AudioEffectEQ10.new()
    for target_hz in STRINGS_EQ_BOOST_TARGETS_HZ:
        eq.set_band_gain_db(_eq10_band_index_for(target_hz), STRINGS_EQ_BOOST_DB)
    AudioServer.add_bus_effect(idx, eq)
    AudioServer.add_bus_effect(idx, _make_strings_chorus())

## Cria (se ainda não existir) o bus "Beacon" para áudio espacial 2D dos objetivos das fases.
func _ensure_beacon_bus() -> void:
    if AudioServer.get_bus_index(BEACON_BUS_NAME) != -1:
        return
    var idx := AudioServer.bus_count
    AudioServer.add_bus(idx)
    AudioServer.set_bus_name(idx, BEACON_BUS_NAME)
    AudioServer.set_bus_send(idx, "Master")
    AudioServer.set_bus_volume_db(idx, -2.0)

## Uma única voz, profundidade/nível baixos -- o padrão (2 vozes, profundidade
## maior) soa metálico/tipo flanger aplicado em cima de só 5 harmônicos
## senoidais discretos e estáticos: sem ruído/dispersão real entre as cópias
## (como haveria numa amostra real), a modulação de delay desloca a fase de
## cada harmônico de um jeito que gera cancelamento/reforço periódico.
func _make_strings_chorus() -> AudioEffectChorus:
    var chorus := AudioEffectChorus.new()
    chorus.voice_count = 1
    chorus.set_voice_depth_ms(0, 1.5)
    chorus.set_voice_level_db(0, -6.0)
    return chorus

## AudioEffectEQ10 tem 10 bandas fixas (31..16000Hz, índices 0-9). Mapeia uma
## frequência-alvo pra o índice da banda mais próxima.
func _eq10_band_index_for(target_hz: float) -> int:
    var best_idx := 0
    var best_diff := INF
    for i in range(EQ10_BAND_FREQS.size()):
        var diff: float = absf(EQ10_BAND_FREQS[i] - target_hz)
        if diff < best_diff:
            best_diff = diff
            best_idx = i
    return best_idx

## Toca a nota pela chave (ex: "A4"). Cancela qualquer player ativo antes.
func play_note(note_key: String) -> AudioStreamPlayer:
    var freq := float(NoteMapping.frequency_for(note_key))
    return _play_synth(freq, false, NOTE_DURATION_SEC)

## Toca SFX de colisão (tom grave e curto). Cancela qualquer player ativo antes.
func play_collision_sfx() -> AudioStreamPlayer:
    return _play_synth(COLLISION_FREQ, true, COLLISION_DURATION_SEC)

## Toca SFX de erro de conhecimento no CALL (curto, não-harsh). Distinto do SFX de colisão física.
func play_note_miss_sfx() -> AudioStreamPlayer:
    return _play_synth(NOTE_MISS_FREQ, false, NOTE_MISS_DURATION_SEC)

## Toca SFX de batida tátil de bengala no chão ("toc-toc").
func play_cane_tap_sfx() -> AudioStreamPlayer:
    _stop_current()
    var player := AudioStreamPlayer.new()
    player.stream = _generate_cane_tap_stream()
    add_child(player)
    _current_player = player
    player.finished.connect(_on_player_finished.bind(player))
    player.play()
    return player

func _generate_cane_tap_stream() -> AudioStreamWAV:
    var duration := 0.2
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var t2 := int(MIX_RATE * 0.07)
    var phase1 := 0.0
    var phase2 := 0.0
    var inc1 := 520.0 / MIX_RATE
    var inc2 := 780.0 / MIX_RATE
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var val := 0.0
        if i < t2:
            var env1 := exp(-t * 45.0)
            val += (sin(phase1 * TAU) * 0.6 + randf_range(-0.4, 0.4) * 0.4) * env1
        else:
            var t_rel := float(i - t2) / float(MIX_RATE)
            var env2 := exp(-t_rel * 55.0)
            val += (sin(phase2 * TAU) * 0.5 + randf_range(-0.3, 0.3) * 0.3) * env2
        samples[i] = val * 0.5
        phase1 = fposmod(phase1 + inc1, 1.0)
        phase2 = fposmod(phase2 + inc2, 1.0)
    return _create_pcm16_wav(samples)

## Toca (ou, já tocando, apenas atualiza) um tom contínuo na frequência dada --
## diferente de play_note, NÃO reinicia o player a cada chamada (permite glissando
## suave). Usado pelo modo de input "Scroll de Afinação".
func play_continuous_pitch(freq_hz: float) -> AudioStreamPlayer:
    _pitch_freq = freq_hz
    if _pitch_player == null or not is_instance_valid(_pitch_player):
        _stop_current()
        _pitch_player = AudioStreamPlayer.new()
        var gen := AudioStreamGenerator.new()
        gen.mix_rate = MIX_RATE
        gen.buffer_length = PITCH_BUFFER_LEN_SEC
        _pitch_player.stream = gen
        _pitch_player.bus = STRINGS_BUS_NAME
        add_child(_pitch_player)
        _pitch_player.play()
        _pitch_playback = _pitch_player.get_stream_playback()
        _pitch_phase = 0.0
    return _pitch_player

## Para o tom contínuo (ex: ao soltar o slider, trocar de modo de input, ou tocar
## uma nota/SFX discreto -- ver _stop_current). As referências (_pitch_player/
## _pitch_playback) somem já-já (síncrono, testável); o player em si esmaece o
## volume por PITCH_STOP_FADE_SEC antes de parar de fato, pra não cortar a
## onda senoidal no meio do ciclo (click audível).
func stop_continuous_pitch() -> void:
    if _pitch_player and is_instance_valid(_pitch_player):
        _fade_out_and_free(_pitch_player)
    _pitch_player = null
    _pitch_playback = null

func _fade_out_and_free(player: AudioStreamPlayer) -> void:
    var tw := create_tween()
    tw.tween_property(player, "volume_db", -80.0, PITCH_STOP_FADE_SEC)
    tw.tween_callback(func():
        if is_instance_valid(player):
            player.stop()
            player.queue_free()
    )

func _process(_delta: float) -> void:
    if _pitch_playback != null:
        _fill_pitch_buffer()

func _fill_pitch_buffer() -> void:
    var lfo_inc := VIBRATO_RATE_HZ / MIX_RATE
    var frames := _pitch_playback.get_frames_available()
    var vibrato_mult := _vibrato_multiplier(_pitch_lfo_phase)
    for i in range(frames):
        # O LFO de vibrato é 6Hz -- recalcular a cada amostra (44100/s) é
        # desnecessário e inaudível a essa taxa de mudança. Recalcula só a
        # cada VIBRATO_CONTROL_RATE_SAMPLES amostras; o valor fica válido
        # (reaproveitado) pras amostras entre atualizações.
        if _vibrato_sample_counter == 0:
            vibrato_mult = _vibrato_multiplier(_pitch_lfo_phase)
        _vibrato_sample_counter = (_vibrato_sample_counter + 1) % VIBRATO_CONTROL_RATE_SAMPLES
        var sample := _pitch_step(_pitch_freq * vibrato_mult)
        _pitch_playback.push_frame(Vector2(sample, sample))
        _pitch_lfo_phase = fposmod(_pitch_lfo_phase + lfo_inc, 1.0)

## Uma amostra do tom contínuo: dada a frequência AGORA, devolve o valor e
## avança o estado da síntese (o ruído de arco filtrado e a fase).
##
## Quem calcula a amostra é _continuous_pitch_sample, que é PURA -- recebe fase,
## LFO e ruído de fora e não toca em estado nenhum. A separação existe pra a
## síntese poder ser testada amostra a amostra sem um player tocando; o avanço de
## estado, que não dá pra testar assim, mora só aqui.
func _pitch_step(freq_hz: float) -> float:
    _noise_lp = lerpf(_noise_lp, randf_range(-1.0, 1.0), NOISE_LOWPASS_COEFF)
    var sample := _continuous_pitch_sample(_pitch_phase, _pitch_lfo_phase, _noise_lp)
    _pitch_phase = fposmod(_pitch_phase + freq_hz / MIX_RATE, 1.0)
    return sample

## Multiplicador de frequência do vibrato (LFO senoidal, ~6Hz, +-18 cents).
## Cents pra multiplicador de frequência: mult = 2^(cents/1200).
## Nota: GDScript 4.6 não tem uma função global exp2() (só existe em shaders) --
## tentar usá-la aqui quebra o parse do script (autoload falha ao carregar).
## pow(2.0, x) é o jeito correto de calcular isso em GDScript puro.
func _vibrato_multiplier(lfo_phase: float) -> float:
    return pow(2.0, (VIBRATO_DEPTH_CENTS / 1200.0) * sin(lfo_phase * TAU))

## Amostra completa do tom contínuo: harmônicos tipo corda + tremolo (LFO de
## amplitude) + ruído de arco filtrado. Função pura (não toca _pitch_playback nem
## estado nenhum) -- testável direto por amostra, sem precisar de um player real
## tocando. Quem avança a fase é _pitch_step().
func _continuous_pitch_sample(phase: float, lfo_phase: float, noise_lp: float) -> float:
    var tone := _string_harmonics(phase)
    var tremolo := 1.0 + TREMOLO_DEPTH * sin((lfo_phase + TREMOLO_PHASE_OFFSET) * TAU)
    return clampf((tone * tremolo * 0.5) + (noise_lp * BOW_NOISE_GAIN), -1.0, 1.0)

## Soma aditiva dos harmônicos (fundamental + 4 acima), normalizada pela soma
## dos ganhos (HARMONIC_GAIN_TOTAL, pré-computada) -- garante |resultado| <= 1
## antes do envelope de amplitude. Roda por AMOSTRA de áudio, então a soma dos
## ganhos fica pré-computada em vez de recalculada a cada chamada.
func _string_harmonics(phase: float) -> float:
    var sum := 0.0
    for h in range(HARMONIC_GAINS.size()):
        var harmonic_num := h + 1
        sum += HARMONIC_GAINS[h] * sin(phase * TAU * harmonic_num)
    return sum / HARMONIC_GAIN_TOTAL

func _play_synth(freq: float, harsh: bool, duration: float) -> AudioStreamPlayer:
    _stop_current()
    var player := AudioStreamPlayer.new()
    player.stream = _make_stream(freq, harsh, duration)
    add_child(player)
    _current_player = player
    player.finished.connect(_on_player_finished.bind(player))
    player.play()
    return player

func _stop_current() -> void:
    if _current_player and is_instance_valid(_current_player):
        _current_player.stop()
        _current_player.queue_free()
    _current_player = null
    stop_continuous_pitch()

func _on_player_finished(player: AudioStreamPlayer) -> void:
    if not is_instance_valid(player):
        return
    if _current_player == player:
        _current_player = null
    player.queue_free()

func _make_stream(freq: float, harsh: bool, duration: float) -> AudioStreamWAV:
    var env := _envelope_segments(duration)
    # O tamanho do buffer vem da SOMA dos trechos, e não de MIX_RATE*duration de
    # novo: assim não existe um jeito de o release terminar fora do buffer (que é
    # o corte seco na última amostra) nem de o buffer sobrar depois do release.
    var total_samples: int = env[0] + env[1] + env[2] + env[3]

    # PCM16 mono (2 bytes por sample). Mono é suficiente — Godot duplica no bus.
    var bytes := PackedByteArray()
    bytes.resize(total_samples * 2)
    var phase := 0.0
    var phase_inc := freq / float(MIX_RATE)
    for idx in range(total_samples):
        var sample := _sample_value(phase, harsh)
        var amplitude := _envelope_at(idx, env[0], env[1], env[2], env[3])
        var value := sample * amplitude * 0.5
        var pcm: int = clampi(int(value * 32767.0), -32768, 32767)
        bytes.encode_s16(idx * 2, pcm)
        phase = fposmod(phase + phase_inc, 1.0)

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = int(MIX_RATE)
    stream.stereo = false
    stream.data = bytes
    return stream

## Reparte a duração pedida nos quatro trechos da envoltória (ataque, decay,
## sustain, release), em amostras. A soma dos quatro é EXATAMENTE o tamanho do
## buffer: é essa igualdade que mantém a envoltória contínua do silêncio ao
## silêncio, e é ela que faltava.
##
## Com os quatro em tamanho fixo, uma duração menor que ataque+decay+release
## deixava o sustain NEGATIVO -- e sustain negativo não encurta nada, ele ADIANTA
## o release, que passa a começar no meio da própria curva. Medido nos 0,2s dos
## SFX de erro e de colisão (8820 amostras contra as 20286 de ataque+decay+
## release, sustain -11466): a envoltória caía de 0,4001 na amostra 7055 pra
## 0,0995 na 7056 -- 12dB num único passo, o tique que se ouvia no feedback de
## erro de que o público-alvo depende.
##
## Não cabendo, os três trechos são comprimidos na MESMA proporção em vez de um
## deles ser sacrificado: a envoltória tem a mesma forma, só mais rápida. Cortar
## só o release (a alternativa óbvia) deixa o som terminar em 0,39 de amplitude e
## troca o degrau do meio por um corte na última amostra -- o mesmo click, de
## lugar. Nos 0,2s isto dá 191/2876/0/5753 amostras.
func _envelope_segments(duration: float) -> PackedInt32Array:
    var total := int(MIX_RATE * duration)
    var attack := int(MIX_RATE * ATTACK_SEC)
    var decay := int(MIX_RATE * DECAY_SEC)
    var release := int(MIX_RATE * RELEASE_SEC)
    if attack + decay + release <= total:
        return PackedInt32Array([attack, decay, total - attack - decay - release, release])
    var squeeze := float(total) / float(attack + decay + release)
    # maxi(1,...) porque _envelope_at divide pelo tamanho do trecho: um trecho de
    # 0 amostra nunca é alcançado (o ramo compara idx < ...), mas 1 é a garantia
    # que não depende de ler os ramos na ordem certa.
    attack = maxi(1, int(attack * squeeze))
    decay = maxi(1, int(decay * squeeze))
    # O release fica com a SOBRA, e não com a sua parte arredondada, porque o que
    # precisa fechar é a soma: uma amostra perdida no arredondamento vira release
    # cortado, que é exatamente o click que este cálculo existe pra evitar.
    return PackedInt32Array([attack, decay, 0, total - attack - decay])

func _sample_value(phase: float, harsh: bool) -> float:
    if harsh:
        # square wave para colisão
        return 1.0 if phase < 0.5 else -1.0
    # Piano-like: fundamental + harmônicos pares e ímpares para corpo.
    # Soma máxima teórica ~1.45; com amplitude 0.5 no _make_stream → ~0.72, sem clip.
    var fundamental := sin(phase * TAU)
    var h2 := 0.3 * sin(phase * TAU * 2.0)
    var h3 := 0.12 * sin(phase * TAU * 3.0)
    var h5 := 0.06 * sin(phase * TAU * 5.0)
    return fundamental + h2 + h3 + h5

func _envelope_at(idx: int, a: int, d: int, s: int, r: int) -> float:
    if idx < a:
        return float(idx) / float(a)
    if idx < a + d:
        var t := float(idx - a) / float(d)
        return lerpf(1.0, SUSTAIN_LEVEL, t)
    if idx < a + d + s:
        return SUSTAIN_LEVEL
    # Release com curva exponencial (t²) — mais musical que linear.
    var t := float(idx - a - d - s) / float(r)
    return lerpf(SUSTAIN_LEVEL, 0.0, t * t)

## Retorna um AudioStreamWAV com síntese temática para o farol sonoro do objetivo.
func get_beacon_stream(beacon_type: String) -> AudioStreamWAV:
    if _beacon_stream_cache.has(beacon_type):
        return _beacon_stream_cache[beacon_type]
    var stream: AudioStreamWAV = null
    match beacon_type:
        "radio":
            stream = _generate_radio_beacon_stream()
        "music_box":
            stream = _generate_music_box_beacon_stream()
        "drip":
            stream = _generate_drip_beacon_stream()
        "clock":
            stream = _generate_clock_beacon_stream()
        _:
            stream = _generate_radio_beacon_stream()
    _beacon_stream_cache[beacon_type] = stream
    return stream

func _create_pcm16_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
    var total_samples := samples.size()
    var bytes := PackedByteArray()
    bytes.resize(total_samples * 2)
    for i in range(total_samples):
        var pcm: int = clampi(int(clampf(samples[i], -1.0, 1.0) * 32767.0), -32768, 32767)
        bytes.encode_s16(i * 2, pcm)
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = int(MIX_RATE)
    stream.stereo = false
    stream.data = bytes
    return stream

func _generate_radio_beacon_stream() -> AudioStreamWAV:
    var duration := 0.65
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase1 := 0.0
    var phase2 := 0.0
    var inc1 := 329.63 / MIX_RATE # E4
    var inc2 := 440.0 / MIX_RATE   # A4
    var noise_val := 0.0
    for i in range(total_samples):
        var t := float(i) / float(total_samples)
        var env: float
        if t < 0.1:
            env = t / 0.1
        elif t > 0.8:
            env = (1.0 - t) / 0.2
        else:
            env = 1.0
        noise_val = lerpf(noise_val, randf_range(-1.0, 1.0), 0.08)
        var tone := (sin(phase1 * TAU) * 0.6 + sin(phase2 * TAU) * 0.3) + noise_val * 0.1
        samples[i] = tone * env * 0.4
        phase1 = fposmod(phase1 + inc1, 1.0)
        phase2 = fposmod(phase2 + inc2, 1.0)
    return _create_pcm16_wav(samples)

func _generate_music_box_beacon_stream() -> AudioStreamWAV:
    var duration := 0.8
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    var inc := 659.25 / MIX_RATE # E5
    var attack_samples := int(MIX_RATE * 0.006)
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env: float
        if i < attack_samples:
            env = float(i) / float(attack_samples)
        else:
            env = exp(-t * 4.5)
        var tone := sin(phase * TAU) + 0.35 * sin(phase * TAU * 2.0) + 0.15 * sin(phase * TAU * 3.0)
        samples[i] = tone * env * 0.4
        phase = fposmod(phase + inc, 1.0)
    return _create_pcm16_wav(samples)

func _generate_drip_beacon_stream() -> AudioStreamWAV:
    var duration := 0.25
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    var attack_samples := int(MIX_RATE * 0.004)
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var cur_freq := lerpf(1350.0, 600.0, clampf(t / 0.08, 0.0, 1.0))
        var inc := cur_freq / MIX_RATE
        var env: float
        if i < attack_samples:
            env = float(i) / float(attack_samples)
        else:
            env = exp(-t * 18.0)
        var tone := sin(phase * TAU) + 0.2 * sin(phase * TAU * 2.0)
        samples[i] = tone * env * 0.5
        phase = fposmod(phase + inc, 1.0)
    return _create_pcm16_wav(samples)

func _generate_clock_beacon_stream() -> AudioStreamWAV:
    var duration := 0.15
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    var inc := 820.0 / MIX_RATE
    var attack_samples := int(MIX_RATE * 0.003)
    var noise_val := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env: float
        if i < attack_samples:
            env = float(i) / float(attack_samples)
        else:
            env = exp(-t * 32.0)
        noise_val = lerpf(noise_val, randf_range(-1.0, 1.0), 0.3)
        var tone := sin(phase * TAU) * 0.6 + noise_val * 0.4
        samples[i] = tone * env * 0.5
        phase = fposmod(phase + inc, 1.0)
    return _create_pcm16_wav(samples)

