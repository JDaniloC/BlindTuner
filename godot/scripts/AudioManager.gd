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
# Precisa ser > ATTACK_SEC+DECAY_SEC (0.16s), senão o buffer termina no meio do
# decay (nunca alcança release) e corta com um click audível em vez de esmaecer.
const NOTE_MISS_DURATION_SEC := 0.2
# Esmaece o volume antes de parar o tom contínuo, senão .stop() corta a onda
# senoidal num ponto arbitrário do ciclo -- click audível em toda soltada do
# slider no modo Scroll de Afinação. Curto o bastante pra não atrasar
# perceptivelmente a resposta, longo o bastante pra evitar a descontinuidade.
const PITCH_STOP_FADE_SEC := 0.012
const VIBRATO_RATE_HZ := 6.0
const VIBRATO_DEPTH_CENTS := 18.0
const TREMOLO_DEPTH := 0.12
const BOW_NOISE_GAIN := 0.03
# Amplitudes decrescentes dos harmônicos (fundamental + 4 acima) -- é
# fisicamente o que a fricção do arco contra a corda produz (onda rica em
# harmônicos, tipo dente-de-serra), diferente da senoide pura anterior.
const HARMONIC_GAINS := [1.0, 0.5, 0.3, 0.2, 0.1]

var _current_player: AudioStreamPlayer = null
var _pitch_player: AudioStreamPlayer = null
var _pitch_playback: AudioStreamGeneratorPlayback = null
var _pitch_phase := 0.0
var _pitch_freq := 0.0
var _pitch_lfo_phase := 0.0
var _noise_lp := 0.0

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
    for i in range(frames):
        var vibrato_mult := _vibrato_multiplier(_pitch_lfo_phase)
        var phase_inc := (_pitch_freq * vibrato_mult) / MIX_RATE
        _noise_lp = lerpf(_noise_lp, randf_range(-1.0, 1.0), 0.1)
        var sample := _continuous_pitch_sample(_pitch_phase, _pitch_lfo_phase, _noise_lp)
        _pitch_playback.push_frame(Vector2(sample, sample))
        _pitch_phase = fposmod(_pitch_phase + phase_inc, 1.0)
        _pitch_lfo_phase = fposmod(_pitch_lfo_phase + lfo_inc, 1.0)

## Multiplicador de frequência do vibrato (LFO senoidal, ~6Hz, +-18 cents).
## Cents pra multiplicador de frequência: mult = 2^(cents/1200).
func _vibrato_multiplier(lfo_phase: float) -> float:
    return pow(2.0, (VIBRATO_DEPTH_CENTS / 1200.0) * sin(lfo_phase * TAU))

## Amostra completa do tom contínuo: harmônicos tipo corda + tremolo (LFO de
## amplitude) + ruído de arco filtrado. Função pura (não toca _pitch_playback)
## -- testável direto por amostra, sem precisar de um player real tocando.
func _continuous_pitch_sample(phase: float, lfo_phase: float, noise_lp: float) -> float:
    var tone := _string_harmonics(phase)
    var tremolo := 1.0 + TREMOLO_DEPTH * sin(lfo_phase * TAU)
    return clampf((tone * tremolo * 0.5) + (noise_lp * BOW_NOISE_GAIN), -1.0, 1.0)

## Soma aditiva dos harmônicos (fundamental + 4 acima), normalizada pela soma
## dos ganhos -- garante |resultado| <= 1 antes do envelope de amplitude.
func _string_harmonics(phase: float) -> float:
    var sum := 0.0
    var gain_total := 0.0
    for h in range(HARMONIC_GAINS.size()):
        var harmonic_num := h + 1
        sum += HARMONIC_GAINS[h] * sin(phase * TAU * harmonic_num)
        gain_total += HARMONIC_GAINS[h]
    return sum / gain_total

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
    var total_samples := int(MIX_RATE * duration)
    var attack_samples := int(MIX_RATE * ATTACK_SEC)
    var decay_samples := int(MIX_RATE * DECAY_SEC)
    var release_samples := int(MIX_RATE * RELEASE_SEC)
    var sustain_samples := total_samples - attack_samples - decay_samples - release_samples

    # PCM16 mono (2 bytes por sample). Mono é suficiente — Godot duplica no bus.
    var bytes := PackedByteArray()
    bytes.resize(total_samples * 2)
    var phase := 0.0
    var phase_inc := freq / float(MIX_RATE)
    for idx in range(total_samples):
        var sample := _sample_value(phase, harsh)
        var amplitude := _envelope_at(idx, attack_samples, decay_samples, sustain_samples, release_samples)
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
