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
const NOTE_MISS_FREQ_1 := 186.4
const NOTE_MISS_FREQ_2 := 194.8
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
var _mob_stream_cache: Dictionary = {}

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
## Suporta duração customizada para notas ritmadas no PREVIEW/REPLAY.
func play_note(note_key: String, duration: float = NOTE_DURATION_SEC) -> AudioStreamPlayer:
    if note_key == "REST" or note_key == "PAUSE" or note_key.is_empty():
        return null
    if not NoteMapping.NOTES.has(note_key):
        return null
    var freq := float(NoteMapping.frequency_for(note_key))
    return _play_synth(freq, false, duration)

## Toca SFX de colisão (tom grave e curto). Cancela qualquer player ativo antes.
func play_collision_sfx() -> AudioStreamPlayer:
    return _play_synth(COLLISION_FREQ, true, COLLISION_DURATION_SEC)

## Toca SFX de erro de conhecimento no CALL (corda acústica desafinada com batimento harmônico).
func play_note_miss_sfx() -> AudioStreamPlayer:
    _stop_current()
    var player := AudioStreamPlayer.new()
    player.stream = _generate_detuned_pluck_stream(NOTE_MISS_DURATION_SEC)
    add_child(player)
    _current_player = player
    player.finished.connect(_on_player_finished.bind(player))
    player.play()
    return player

## Gera stream sintetizado com batimento acústico de cordas desafinadas (~8.4Hz de batimento dissonante).
func _generate_detuned_pluck_stream(duration: float) -> AudioStreamWAV:
    var env := _envelope_segments(duration)
    var total_samples: int = env[0] + env[1] + env[2] + env[3]
    var bytes := PackedByteArray()
    bytes.resize(total_samples * 2)

    var phase1 := 0.0
    var phase2 := 0.0
    var inc1 := NOTE_MISS_FREQ_1 / MIX_RATE
    var inc2 := NOTE_MISS_FREQ_2 / MIX_RATE
    var noise := 0.0

    for idx in range(total_samples):
        var amp := _envelope_at(idx, env[0], env[1], env[2], env[3])
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.12)
        var s1 := _string_harmonics(phase1)
        var s2 := _string_harmonics(phase2)
        var val := (s1 * 0.45 + s2 * 0.45 + noise * 0.1) * amp * 0.5
        var pcm: int = clampi(int(val * 32767.0), -32768, 32767)
        bytes.encode_s16(idx * 2, pcm)
        phase1 = fposmod(phase1 + inc1, 1.0)
        phase2 = fposmod(phase2 + inc2, 1.0)

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = int(MIX_RATE)
    stream.stereo = false
    stream.data = bytes
    return stream

## Toca SFX sutil de toque bloqueado/recuperação de tropeço (tap abafado de madeira, 0.05s).
func play_trip_blocked_sfx() -> AudioStreamPlayer:
    _stop_current()
    var player := AudioStreamPlayer.new()
    player.stream = _generate_blocked_tap_stream()
    add_child(player)
    _current_player = player
    player.finished.connect(_on_player_finished.bind(player))
    player.play()
    return player

func _generate_blocked_tap_stream() -> AudioStreamWAV:
    var duration := 0.05
    var total_samples := int(MIX_RATE * duration)
    var bytes := PackedByteArray()
    bytes.resize(total_samples * 2)
    var phase := 0.0
    var inc := 115.0 / MIX_RATE
    var noise := 0.0
    for idx in range(total_samples):
        var t := float(idx) / float(MIX_RATE)
        var env := exp(-t * 85.0)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.25)
        var val := (sin(phase * TAU) * 0.7 + noise * 0.3) * env * 0.35
        var pcm: int = clampi(int(val * 32767.0), -32768, 32767)
        bytes.encode_s16(idx * 2, pcm)
        phase = fposmod(phase + inc, 1.0)

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = int(MIX_RATE)
    stream.stereo = false
    stream.data = bytes
    return stream

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

## Toca um clique sutil da ponta da bengala no piso a cada passo, sem mascarar ou interromper a nota musical.
func play_cane_step_sfx() -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.stream = _generate_cane_tap_stream()
    player.volume_db = -8.0
    add_child(player)
    player.finished.connect(func():
        if is_instance_valid(player):
            player.queue_free()
    )
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
        "gate_latch":
            stream = _generate_gate_latch_beacon_stream()
        "shop_bell":
            stream = _generate_shop_bell_beacon_stream()
        "fountain_birds":
            stream = _generate_fountain_birds_beacon_stream()
        "church_bell":
            stream = _generate_church_bell_beacon_stream()
        "window_wind":
            stream = _generate_window_wind_beacon_stream()
        "wrist_watch":
            stream = _generate_wrist_watch_beacon_stream()
        "watering_can":
            stream = _generate_watering_can_beacon_stream()
        "tea_cup":
            stream = _generate_tea_cup_beacon_stream()
        "cat_bell":
            stream = _generate_cat_bell_beacon_stream()
        "broom_sweep":
            stream = _generate_broom_sweep_beacon_stream()
        "keys_jingle":
            stream = _generate_keys_jingle_beacon_stream()
        "ocean_waves":
            stream = _generate_ocean_waves_beacon_stream()
        "train_whistle":
            stream = _generate_train_whistle_beacon_stream()
        "cello_drone":
            stream = _generate_cello_drone_beacon_stream()
        "wind_chimes":
            stream = _generate_wind_chimes_beacon_stream()
        "bike_bell":
            stream = _generate_bike_bell_beacon_stream()
        "paper_rustle":
            stream = _generate_paper_rustle_beacon_stream()
        "coffee_grinder":
            stream = _generate_coffee_grinder_beacon_stream()
        "kettle_whistle":
            stream = _generate_kettle_whistle_beacon_stream()
        "loom_shuttle":
            stream = _generate_loom_shuttle_beacon_stream()
        "accordion_drone":
            stream = _generate_accordion_drone_beacon_stream()
        "castanets_click":
            stream = _generate_castanets_click_beacon_stream()
        "dock_bell":
            stream = _generate_dock_bell_beacon_stream()
        "organ_pipe":
            stream = _generate_organ_pipe_beacon_stream()
        "tambourine_shake":
            stream = _generate_tambourine_shake_beacon_stream()
        "cathedral_echo":
            stream = _generate_cathedral_echo_beacon_stream()
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

## Retorna um AudioStreamWAV com síntese temática para sons de entidades/mobs.
func get_mob_stream(mob_sound: String) -> AudioStreamWAV:
    if _mob_stream_cache.has(mob_sound):
        return _mob_stream_cache[mob_sound]
    var stream: AudioStreamWAV = null
    match mob_sound:
        "cat_purr":
            stream = _generate_cat_purr_stream()
        "cat_meow":
            stream = _generate_cat_meow_stream()
        "dog_pant":
            stream = _generate_dog_pant_stream()
        "dog_bark":
            stream = _generate_dog_bark_stream()
        "pigeon_coo":
            stream = _generate_pigeon_coo_stream()
        "pigeon_flutter":
            stream = _generate_pigeon_flutter_stream()
        "canary_sing":
            stream = _generate_canary_sing_stream()
        "canary_flap":
            stream = _generate_canary_flap_stream()
        "pedestrian_greeting":
            stream = _generate_pedestrian_greeting_stream()
        "postman_bell", "bike_bell":
            stream = _generate_bike_bell_beacon_stream()
        "baker_greeting":
            stream = _generate_baker_greeting_stream()
        _:
            stream = _generate_cat_meow_stream()
    _mob_stream_cache[mob_sound] = stream
    return stream

func _generate_gate_latch_beacon_stream() -> AudioStreamWAV:
    var duration := 0.4
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase_click := 0.0
    var phase_iron1 := 0.0
    var phase_iron2 := 0.0
    var inc_click := 1600.0 / MIX_RATE
    var inc_iron1 := 420.0 / MIX_RATE
    var inc_iron2 := 580.0 / MIX_RATE
    var noise_val := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var click_env := exp(-t * 80.0) if t < 0.08 else 0.0
        var iron_t := t - 0.06
        var iron_env := exp(-iron_t * 16.0) if iron_t >= 0.0 else 0.0
        noise_val = lerpf(noise_val, randf_range(-1.0, 1.0), 0.25)
        var click_sound := (sin(phase_click * TAU) * 0.7 + noise_val * 0.3) * click_env
        var iron_sound := (sin(phase_iron1 * TAU) * 0.6 + sin(phase_iron2 * TAU) * 0.4 + noise_val * 0.1) * iron_env
        samples[i] = (click_sound * 0.6 + iron_sound * 0.5) * 0.6
        phase_click = fposmod(phase_click + inc_click, 1.0)
        phase_iron1 = fposmod(phase_iron1 + inc_iron1, 1.0)
        phase_iron2 = fposmod(phase_iron2 + inc_iron2, 1.0)
    return _create_pcm16_wav(samples)

func _generate_shop_bell_beacon_stream() -> AudioStreamWAV:
    var duration := 0.7
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase_b1 := 0.0
    var phase_b2 := 0.0
    var inc_b1 := 1567.98 / MIX_RATE # G6
    var inc_b2 := 2093.0 / MIX_RATE   # C7
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env1 := exp(-t * 9.0)
        var t2 := t - 0.1
        var env2 := exp(-t2 * 8.0) if t2 >= 0.0 else 0.0
        var bell1 := (sin(phase_b1 * TAU) + 0.3 * sin(phase_b1 * TAU * 2.0)) * env1
        var bell2 := (sin(phase_b2 * TAU) + 0.25 * sin(phase_b2 * TAU * 2.0)) * env2
        samples[i] = (bell1 * 0.5 + bell2 * 0.5) * 0.45
        phase_b1 = fposmod(phase_b1 + inc_b1, 1.0)
        phase_b2 = fposmod(phase_b2 + inc_b2, 1.0)
    return _create_pcm16_wav(samples)

func _generate_fountain_birds_beacon_stream() -> AudioStreamWAV:
    var duration := 0.85
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var chirp_phase := 0.0
    var noise_lp := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        noise_lp = lerpf(noise_lp, randf_range(-1.0, 1.0), 0.06)
        var water := noise_lp * (0.8 + 0.2 * sin(t * 18.0))
        var t_chirp := t - 0.25
        var chirp_sound := 0.0
        if t_chirp >= 0.0 and t_chirp < 0.18:
            var c_env := sin((t_chirp / 0.18) * PI)
            var c_freq := lerpf(2300.0, 2900.0, sin((t_chirp / 0.18) * PI))
            chirp_phase = fposmod(chirp_phase + (c_freq / MIX_RATE), 1.0)
            chirp_sound = sin(chirp_phase * TAU) * c_env * 0.4
        samples[i] = (water * 0.25 + chirp_sound * 0.35)
    return _create_pcm16_wav(samples)

func _generate_church_bell_beacon_stream() -> AudioStreamWAV:
    var duration := 1.6
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phases := [0.0, 0.0, 0.0, 0.0]
    var freqs := [110.0, 220.0, 264.0, 440.0]
    var gains := [0.4, 0.6, 0.3, 0.4]
    var attack_samples := int(MIX_RATE * 0.008)
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env: float
        if i < attack_samples:
            env = float(i) / float(attack_samples)
        else:
            env = exp(-t * 2.4)
        var tone := 0.0
        for p in range(phases.size()):
            tone += sin(phases[p] * TAU) * gains[p]
            phases[p] = fposmod(phases[p] + (freqs[p] / MIX_RATE), 1.0)
        samples[i] = tone * env * 0.45
    return _create_pcm16_wav(samples)

func _generate_cat_purr_stream() -> AudioStreamWAV:
    var duration := 1.1
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase1 := 0.0
    var phase2 := 0.0
    var inc1 := 28.0 / MIX_RATE
    var inc2 := 56.0 / MIX_RATE
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var purr_lfo := (sin(t * TAU * 22.0) * 0.5 + 0.5)
        var breath_env := sin((t / duration) * PI)
        var tone := (sin(phase1 * TAU) * 0.7 + sin(phase2 * TAU) * 0.3)
        samples[i] = tone * purr_lfo * breath_env * 0.5
        phase1 = fposmod(phase1 + inc1, 1.0)
        phase2 = fposmod(phase2 + inc2, 1.0)
    return _create_pcm16_wav(samples)

func _generate_cat_meow_stream() -> AudioStreamWAV:
    var duration := 0.5
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    var attack_samples := int(MIX_RATE * 0.06)
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var cur_freq: float
        var norm_t := t / duration
        if norm_t < 0.45:
            cur_freq = lerpf(460.0, 780.0, norm_t / 0.45)
        else:
            cur_freq = lerpf(780.0, 560.0, (norm_t - 0.45) / 0.55)
        var env: float
        if i < attack_samples:
            env = float(i) / float(attack_samples)
        else:
            env = exp(-(t - 0.06) * 4.8)
        var inc := cur_freq / MIX_RATE
        var tone := sin(phase * TAU) + 0.45 * sin(phase * TAU * 2.0) + 0.2 * sin(phase * TAU * 3.0)
        samples[i] = tone * env * 0.38
        phase = fposmod(phase + inc, 1.0)
    return _create_pcm16_wav(samples)

func _generate_dog_pant_stream() -> AudioStreamWAV:
    var duration := 0.45
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := (sin(t * TAU * 2.2) * 0.5 + 0.5) * sin((t / duration) * PI)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.07)
        samples[i] = noise * env * 0.35
    return _create_pcm16_wav(samples)

func _generate_dog_bark_stream() -> AudioStreamWAV:
    var duration := 0.32
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var cur_freq := lerpf(240.0, 160.0, t / duration)
        var env := exp(-t * 12.0)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.18)
        var tone := sin(phase * TAU) * 0.65 + noise * 0.35
        samples[i] = tone * env * 0.5
        phase = fposmod(phase + (cur_freq / MIX_RATE), 1.0)
    return _create_pcm16_wav(samples)

func _generate_pigeon_coo_stream() -> AudioStreamWAV:
    var duration := 0.6
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var vibrato := sin(t * TAU * 11.0) * 22.0
        var cur_freq := 320.0 + vibrato
        var env := sin((t / duration) * PI)
        var tone := sin(phase * TAU) + 0.25 * sin(phase * TAU * 2.0)
        samples[i] = tone * env * 0.4
        phase = fposmod(phase + (cur_freq / MIX_RATE), 1.0)
    return _create_pcm16_wav(samples)

func _generate_pigeon_flutter_stream() -> AudioStreamWAV:
    var duration := 0.38
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var flap_lfo := maxf(0.0, sin(t * TAU * 14.0))
        var overall_env := exp(-t * 5.0)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.12)
        samples[i] = noise * flap_lfo * overall_env * 0.4
    return _create_pcm16_wav(samples)

func _generate_window_wind_beacon_stream() -> AudioStreamWAV:
    var duration := 0.65
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var noise := 0.0
    var clack_phase := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.04)
        var wind_env := sin((t / duration) * PI)
        var clack := 0.0
        var t1 := t - 0.16
        var t2 := t - 0.38
        if t1 >= 0.0 and t1 < 0.05:
            clack += sin(clack_phase * TAU) * exp(-t1 * 60.0)
            clack_phase = fposmod(clack_phase + (240.0 / MIX_RATE), 1.0)
        if t2 >= 0.0 and t2 < 0.05:
            clack += sin(clack_phase * TAU) * exp(-t2 * 60.0)
            clack_phase = fposmod(clack_phase + (260.0 / MIX_RATE), 1.0)
        samples[i] = (noise * wind_env * 0.4 + clack * 0.5) * 0.6
    return _create_pcm16_wav(samples)

func _generate_wrist_watch_beacon_stream() -> AudioStreamWAV:
    var duration := 0.35
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    var inc := 3200.0 / MIX_RATE
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var t1 := t - 0.02
        var t2 := t - 0.18
        var tick := 0.0
        if t1 >= 0.0 and t1 < 0.04:
            tick += sin(phase * TAU) * exp(-t1 * 100.0)
        if t2 >= 0.0 and t2 < 0.04:
            tick += sin(phase * TAU) * exp(-t2 * 110.0)
        samples[i] = tick * 0.5
        phase = fposmod(phase + inc, 1.0)
    return _create_pcm16_wav(samples)

func _generate_watering_can_beacon_stream() -> AudioStreamWAV:
    var duration := 0.45
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var t1 := t - 0.05
        var t2 := t - 0.22
        var drip := 0.0
        if t1 >= 0.0 and t1 < 0.08:
            var freq1 := lerpf(750.0, 520.0, t1 / 0.08)
            phase = fposmod(phase + (freq1 / MIX_RATE), 1.0)
            drip += (sin(phase * TAU) + 0.3 * sin(phase * TAU * 2.0)) * exp(-t1 * 30.0)
        if t2 >= 0.0 and t2 < 0.08:
            var freq2 := lerpf(820.0, 580.0, t2 / 0.08)
            phase = fposmod(phase + (freq2 / MIX_RATE), 1.0)
            drip += (sin(phase * TAU) + 0.3 * sin(phase * TAU * 2.0)) * exp(-t2 * 30.0)
        samples[i] = drip * 0.5
    return _create_pcm16_wav(samples)

func _generate_tea_cup_beacon_stream() -> AudioStreamWAV:
    var duration := 0.6
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase1 := 0.0
    var phase2 := 0.0
    var inc1 := 2489.0 / MIX_RATE # D#7
    var inc2 := 4978.0 / MIX_RATE
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := exp(-t * 7.5)
        var tone := sin(phase1 * TAU) * 0.7 + sin(phase2 * TAU) * 0.3
        samples[i] = tone * env * 0.45
        phase1 = fposmod(phase1 + inc1, 1.0)
        phase2 = fposmod(phase2 + inc2, 1.0)
    return _create_pcm16_wav(samples)

func _generate_cat_bell_beacon_stream() -> AudioStreamWAV:
    var duration := 0.5
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    var inc := 2960.0 / MIX_RATE
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var jingle := (sin(t * TAU * 18.0) * 0.4 + 0.6)
        var env := exp(-t * 6.0)
        samples[i] = sin(phase * TAU) * jingle * env * 0.45
        phase = fposmod(phase + inc, 1.0)
    return _create_pcm16_wav(samples)

func _generate_broom_sweep_beacon_stream() -> AudioStreamWAV:
    var duration := 0.5
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var stroke := sin((t / duration) * PI)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.09)
        samples[i] = noise * stroke * 0.4
    return _create_pcm16_wav(samples)

func _generate_keys_jingle_beacon_stream() -> AudioStreamWAV:
    var duration := 0.45
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p1 := 0.0
    var p2 := 0.0
    var p3 := 0.0
    var inc1 := 1350.0 / MIX_RATE
    var inc2 := 1820.0 / MIX_RATE
    var inc3 := 2400.0 / MIX_RATE
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := exp(-t * 9.0)
        var tone := sin(p1 * TAU) * 0.4 + sin(p2 * TAU) * 0.35 + sin(p3 * TAU) * 0.25
        samples[i] = tone * env * 0.45
        p1 = fposmod(p1 + inc1, 1.0)
        p2 = fposmod(p2 + inc2, 1.0)
        p3 = fposmod(p3 + inc3, 1.0)
    return _create_pcm16_wav(samples)

func _generate_canary_sing_stream() -> AudioStreamWAV:
    var duration := 0.65
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var trill := sin(t * TAU * 16.0) * 180.0
        var cur_freq := 2800.0 + (sin(t * TAU * 3.0) * 400.0) + trill
        var env := sin((t / duration) * PI)
        samples[i] = sin(phase * TAU) * env * 0.35
        phase = fposmod(phase + (cur_freq / MIX_RATE), 1.0)
    return _create_pcm16_wav(samples)

func _generate_canary_flap_stream() -> AudioStreamWAV:
    var duration := 0.35
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase := 0.0
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var flap := maxf(0.0, sin(t * TAU * 18.0))
        var env := exp(-t * 6.0)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.15)
        var chirp := sin(phase * TAU) * 0.2
        samples[i] = (noise * flap * 0.3 + chirp) * env
        var cur_freq := 3200.0 + (sin(t * TAU * 8.0) * 600.0)
        phase = fposmod(phase + (cur_freq / MIX_RATE), 1.0)
    return _create_pcm16_wav(samples)

func _generate_pedestrian_greeting_stream() -> AudioStreamWAV:
    var duration := 0.45
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase1 := 0.0
    var phase2 := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env1 := sin((t / 0.16) * PI) if (t < 0.16) else 0.0
        var t2 := t - 0.12
        var env2 := exp(-t2 * 7.5) if (t2 >= 0.0) else 0.0
        var tone1 := (sin(phase1 * TAU) + 0.3 * sin(phase1 * TAU * 2.0)) * env1
        var tone2 := (sin(phase2 * TAU) + 0.25 * sin(phase2 * TAU * 2.0) + 0.1 * sin(phase2 * TAU * 3.0)) * env2
        samples[i] = (tone1 * 0.4 + tone2 * 0.45) * 0.5
        phase1 = fposmod(phase1 + (622.25 / MIX_RATE), 1.0)
        phase2 = fposmod(phase2 + (783.99 / MIX_RATE), 1.0)
    return _create_pcm16_wav(samples)

func _generate_baker_greeting_stream() -> AudioStreamWAV:
    var duration := 0.42
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase1 := 0.0
    var phase2 := 0.0
    var phase3 := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env1 := sin((t / 0.14) * PI) if (t < 0.14) else 0.0
        var t2 := t - 0.10
        var env2 := sin((t2 / 0.14) * PI) if (t2 >= 0.0 and t2 < 0.14) else 0.0
        var t3 := t - 0.18
        var env3 := exp(-t3 * 8.0) if (t3 >= 0.0) else 0.0
        var tone1 := (sin(phase1 * TAU) + 0.3 * sin(phase1 * TAU * 2.0)) * env1
        var tone2 := (sin(phase2 * TAU) + 0.3 * sin(phase2 * TAU * 2.0)) * env2
        var tone3 := (sin(phase3 * TAU) + 0.25 * sin(phase3 * TAU * 2.0) + 0.15 * sin(phase3 * TAU * 3.0)) * env3
        samples[i] = (tone1 * 0.35 + tone2 * 0.4 + tone3 * 0.45) * 0.5
        phase1 = fposmod(phase1 + (523.25 / MIX_RATE), 1.0)
        phase2 = fposmod(phase2 + (659.25 / MIX_RATE), 1.0)
        phase3 = fposmod(phase3 + (783.99 / MIX_RATE), 1.0)
    return _create_pcm16_wav(samples)

func _generate_ocean_waves_beacon_stream() -> AudioStreamWAV:
    var duration := 1.2
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var noise := 0.0
    var low_phase := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var wave_env := sin((t / duration) * PI)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.08)
        var low_rumble := sin(low_phase * TAU) * 0.35
        low_phase = fposmod(low_phase + (55.0 / MIX_RATE), 1.0)
        samples[i] = (noise * 0.65 + low_rumble) * wave_env * 0.4
    return _create_pcm16_wav(samples)

func _generate_train_whistle_beacon_stream() -> AudioStreamWAV:
    var duration := 0.9
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p1 := 0.0
    var p2 := 0.0
    var breath := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := sin((t / duration) * PI)
        var vib := sin(t * TAU * 5.0) * 4.0
        var f1 := 349.2 + vib
        var f2 := 440.0 + vib
        p1 = fposmod(p1 + (f1 / MIX_RATE), 1.0)
        p2 = fposmod(p2 + (f2 / MIX_RATE), 1.0)
        breath = lerpf(breath, randf_range(-1.0, 1.0), 0.2)
        var tone := (sin(p1 * TAU) * 0.5 + sin(p2 * TAU) * 0.4)
        samples[i] = (tone * 0.8 + breath * 0.2) * env * 0.38
    return _create_pcm16_wav(samples)

func _generate_cello_drone_beacon_stream() -> AudioStreamWAV:
    var duration := 1.0
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p1 := 0.0
    var p2 := 0.0
    var p3 := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := sin((t / duration) * PI)
        var f1 := 65.41 # C2
        var f2 := 130.81 # C3
        var f3 := 196.00 # G3
        p1 = fposmod(p1 + (f1 / MIX_RATE), 1.0)
        p2 = fposmod(p2 + (f2 / MIX_RATE), 1.0)
        p3 = fposmod(p3 + (f3 / MIX_RATE), 1.0)
        var s1 := (p1 * 2.0 - 1.0) * 0.5
        var s2 := sin(p2 * TAU) * 0.3
        var s3 := sin(p3 * TAU) * 0.2
        samples[i] = (s1 + s2 + s3) * env * 0.45
    return _create_pcm16_wav(samples)

func _generate_wind_chimes_beacon_stream() -> AudioStreamWAV:
    var duration := 1.1
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var freqs: Array[float] = [1760.0, 2349.3, 3135.9, 4186.0]
    var phases: Array[float] = [0.0, 0.0, 0.0, 0.0]
    var delays: Array[float] = [0.0, 0.08, 0.18, 0.32]
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var total := 0.0
        for j in range(4):
            if t >= delays[j]:
                var dt: float = t - delays[j]
                var env := exp(-dt * 4.5)
                phases[j] = fposmod(phases[j] + (freqs[j] / MIX_RATE), 1.0)
                total += sin(phases[j] * TAU) * env * 0.22
        samples[i] = total * 0.5
    return _create_pcm16_wav(samples)

func _generate_bike_bell_beacon_stream() -> AudioStreamWAV:
    var duration := 0.6
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var f1 := 1760.0 # A6
    var f2 := 2093.0 # C7
    var p1 := 0.0
    var p2 := 0.0
    var p3 := 0.0
    var p4 := 0.0
    var delay2 := 0.14
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var total := 0.0
        # Primeiro ding
        var env1 := exp(-t * 14.0)
        p1 = fposmod(p1 + (f1 / MIX_RATE), 1.0)
        p2 = fposmod(p2 + ((f1 * 1.5) / MIX_RATE), 1.0)
        total += (sin(p1 * TAU) * 0.7 + sin(p2 * TAU) * 0.3) * env1
        # Segundo ding
        if t >= delay2:
            var dt: float = t - delay2
            var env2 := exp(-dt * 12.0)
            p3 = fposmod(p3 + (f2 / MIX_RATE), 1.0)
            p4 = fposmod(p4 + ((f2 * 1.5) / MIX_RATE), 1.0)
            total += (sin(p3 * TAU) * 0.7 + sin(p4 * TAU) * 0.3) * env2
        samples[i] = total * 0.45
    return _create_pcm16_wav(samples)

func _generate_paper_rustle_beacon_stream() -> AudioStreamWAV:
    var duration := 0.7
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := sin((t / duration) * PI) * (sin(t * TAU * 4.5) * 0.35 + 0.65)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.25)
        samples[i] = noise * env * 0.35
    return _create_pcm16_wav(samples)

func _generate_coffee_grinder_beacon_stream() -> AudioStreamWAV:
    var duration := 0.65
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p_ratchet := 0.0
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        # Três pulsos mecânicos de moagem com ruído áspero de grãos triturados
        var turn_phase: float = fposmod(t * 3.5, 1.0)
        var click_env: float = exp(-turn_phase * 18.0)
        p_ratchet = fposmod(p_ratchet + (420.0 / MIX_RATE), 1.0)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.35)
        var crunch := (sin(p_ratchet * TAU) * 0.4 + noise * 0.6) * click_env
        var body_env := sin((t / duration) * PI)
        samples[i] = crunch * body_env * 0.45
    return _create_pcm16_wav(samples)

func _generate_kettle_whistle_beacon_stream() -> AudioStreamWAV:
    var duration := 0.75
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var phase1 := 0.0
    var phase2 := 0.0
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := sin((t / duration) * PI)
        var vibrato := sin(t * TAU * 5.2) * 14.0
        var f1 := 1260.0 + vibrato
        var f2 := 2520.0 + vibrato * 1.5
        phase1 = fposmod(phase1 + (f1 / MIX_RATE), 1.0)
        phase2 = fposmod(phase2 + (f2 / MIX_RATE), 1.0)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.08)
        var steam := sin(phase1 * TAU) * 0.75 + sin(phase2 * TAU) * 0.20 + noise * 0.08
        samples[i] = steam * env * 0.40
    return _create_pcm16_wav(samples)

func _generate_loom_shuttle_beacon_stream() -> AudioStreamWAV:
    var duration := 0.60
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p_wood := 0.0
    var noise := 0.0
    var t_tap2 := 0.28
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        # Batida inicial de madeira da lançadeira
        var env1 := exp(-t * 35.0)
        # Fricção do fio de linho deslizando pela urdidura
        var glide_env := sin(clampf(t / 0.50, 0.0, 1.0) * PI)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.22)
        p_wood = fposmod(p_wood + (320.0 / MIX_RATE), 1.0)
        var sound := (sin(p_wood * TAU) * 0.7 + noise * 0.3) * env1 + noise * glide_env * 0.25
        # Segunda batida no batente oposto
        if t >= t_tap2:
            var dt: float = t - t_tap2
            var env2 := exp(-dt * 38.0)
            sound += (sin(p_wood * TAU * 1.2) * 0.7 + noise * 0.3) * env2 * 0.8
        samples[i] = sound * 0.45
    return _create_pcm16_wav(samples)

func _generate_accordion_drone_beacon_stream() -> AudioStreamWAV:
    var duration := 0.85
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p1 := 0.0
    var p2 := 0.0
    var p3 := 0.0
    var f1 := 220.0 # A3
    var f2 := 330.0 # E4
    var f3 := 221.5 # Detune reed para tremolo natural de sanfona (~1.5Hz)
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := sin((t / duration) * PI)
        p1 = fposmod(p1 + (f1 / MIX_RATE), 1.0)
        p2 = fposmod(p2 + (f2 / MIX_RATE), 1.0)
        p3 = fposmod(p3 + (f3 / MIX_RATE), 1.0)
        # Timbre palhetado rico em harmônicos ímpares
        var s1 := (1.0 if p1 < 0.5 else -1.0) * 0.35 + sin(p1 * TAU) * 0.35
        var s2 := sin(p2 * TAU) * 0.30
        var s3 := (1.0 if p3 < 0.5 else -1.0) * 0.35 + sin(p3 * TAU) * 0.35
        samples[i] = (s1 * 0.45 + s2 * 0.30 + s3 * 0.45) * env * 0.38
    return _create_pcm16_wav(samples)

func _generate_castanets_click_beacon_stream() -> AudioStreamWAV:
    var duration := 0.45
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p1 := 0.0
    var p2 := 0.0
    var t2 := 0.11
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var sound := 0.0
        # Primeiro clique da castanhola ("ta")
        var env1 := exp(-t * 55.0)
        p1 = fposmod(p1 + (1150.0 / MIX_RATE), 1.0)
        sound += (sin(p1 * TAU) * 0.65 + randf_range(-0.35, 0.35)) * env1
        # Segundo clique decisivo ("tac")
        if t >= t2:
            var dt: float = t - t2
            var env2 := exp(-dt * 48.0)
            p2 = fposmod(p2 + (980.0 / MIX_RATE), 1.0)
            sound += (sin(p2 * TAU) * 0.70 + randf_range(-0.30, 0.30)) * env2 * 1.15
        samples[i] = sound * 0.45
    return _create_pcm16_wav(samples)

func _generate_dock_bell_beacon_stream() -> AudioStreamWAV:
    var duration := 1.20
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p1 := 0.0
    var p2 := 0.0
    var p3 := 0.0
    var noise := 0.0
    var f1 := 349.23 # F4
    var f2 := 698.46 # F5
    var f3 := 880.00 # A5
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var bell_env := exp(-t * 2.8)
        p1 = fposmod(p1 + (f1 / MIX_RATE), 1.0)
        p2 = fposmod(p2 + (f2 / MIX_RATE), 1.0)
        p3 = fposmod(p3 + (f3 / MIX_RATE), 1.0)
        var bell := sin(p1 * TAU) * 0.55 + sin(p2 * TAU) * 0.30 + sin(p3 * TAU) * 0.15
        # Marulho suave de água no fundo
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.05)
        var tide := noise * sin((t / duration) * PI) * 0.12
        samples[i] = (bell * bell_env * 0.45 + tide)
    return _create_pcm16_wav(samples)

func _generate_organ_pipe_beacon_stream() -> AudioStreamWAV:
    var duration := 1.10
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p1 := 0.0
    var p2 := 0.0
    var p3 := 0.0
    var f1 := 130.81 # C3
    var f2 := 261.63 # C4
    var f3 := 392.00 # G4
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := sin((t / duration) * PI)
        # Chiff de ar no ataque do tubo
        var chiff := exp(-t * 25.0) * 0.20
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.15)
        p1 = fposmod(p1 + (f1 / MIX_RATE), 1.0)
        p2 = fposmod(p2 + (f2 / MIX_RATE), 1.0)
        p3 = fposmod(p3 + (f3 / MIX_RATE), 1.0)
        var organ := sin(p1 * TAU) * 0.55 + sin(p2 * TAU) * 0.30 + sin(p3 * TAU) * 0.15
        samples[i] = (organ + noise * chiff) * env * 0.45
    return _create_pcm16_wav(samples)

func _generate_tambourine_shake_beacon_stream() -> AudioStreamWAV:
    var duration := 0.55
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p_zil1 := 0.0
    var p_zil2 := 0.0
    var p_skin := 0.0
    var noise := 0.0
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        var env := sin((t / duration) * PI)
        var shake_lfo := maxf(0.0, sin(t * TAU * 14.0))
        p_zil1 = fposmod(p_zil1 + (3400.0 / MIX_RATE), 1.0)
        p_zil2 = fposmod(p_zil2 + (4600.0 / MIX_RATE), 1.0)
        noise = lerpf(noise, randf_range(-1.0, 1.0), 0.30)
        var zils := (sin(p_zil1 * TAU) * 0.4 + sin(p_zil2 * TAU) * 0.3 + noise * 0.3) * shake_lfo
        # Toque suave na pele do tamborim no início
        var tap := exp(-t * 40.0)
        p_skin = fposmod(p_skin + (240.0 / MIX_RATE), 1.0)
        var skin := sin(p_skin * TAU) * tap * 0.4
        samples[i] = (zils * 0.65 + skin * 0.35) * env * 0.45
    return _create_pcm16_wav(samples)

func _generate_cathedral_echo_beacon_stream() -> AudioStreamWAV:
    var duration := 1.40
    var total_samples := int(MIX_RATE * duration)
    var samples := PackedFloat32Array()
    samples.resize(total_samples)
    var p1 := 0.0
    var p2 := 0.0
    var p3 := 0.0
    var f1 := 146.83 # D3
    var f2 := 220.00 # A3
    var f3 := 293.66 # D4
    for i in range(total_samples):
        var t := float(i) / float(MIX_RATE)
        # Ataque suave com longa curva de reverberação de abóbada de pedra
        var attack: float = clampf(t / 0.12, 0.0, 1.0)
        var decay: float = exp(-(t - 0.12) * 1.8) if t > 0.12 else 1.0
        var env: float = attack * decay
        p1 = fposmod(p1 + (f1 / MIX_RATE), 1.0)
        p2 = fposmod(p2 + (f2 / MIX_RATE), 1.0)
        p3 = fposmod(p3 + (f3 / MIX_RATE), 1.0)
        var tone := sin(p1 * TAU) * 0.50 + sin(p2 * TAU) * 0.30 + sin(p3 * TAU) * 0.20
        samples[i] = tone * env * 0.45
    return _create_pcm16_wav(samples)
