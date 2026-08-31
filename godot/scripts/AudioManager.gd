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
const NOTE_MISS_FREQ := 220.0
# Precisa ser > ATTACK_SEC+DECAY_SEC (0.16s), senão o buffer termina no meio do
# decay (nunca alcança release) e corta com um click audível em vez de esmaecer.
const NOTE_MISS_DURATION_SEC := 0.2

var _current_player: AudioStreamPlayer = null

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

## Stub para o modo cello futuro (pitch contínuo controlável em tempo real).
func play_continuous_pitch(_freq_hz: float):
    return null

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
