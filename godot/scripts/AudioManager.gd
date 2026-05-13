extends Node
## Autoload singleton — gera e toca tons sintetizados representando cada nota.

const MIX_RATE := 44100.0
const NOTE_DURATION_SEC := 0.6
const ATTACK_SEC := 0.01
const DECAY_SEC := 0.15
const SUSTAIN_LEVEL := 0.4
const RELEASE_SEC := 0.3
const BUFFER_LENGTH_SEC := NOTE_DURATION_SEC
const COLLISION_FREQ := 80.0

## Toca a nota pela chave (ex: "A4"). Retorna o AudioStreamPlayer instanciado.
func play_note(note_key: String) -> AudioStreamPlayer:
    var freq := float(NoteMapping.frequency_for(note_key))
    return _play_synth(freq, false)

## Toca SFX de colisão (tom grave e curto).
func play_collision_sfx() -> AudioStreamPlayer:
    return _play_synth(COLLISION_FREQ, true)

## Stub para o modo cello futuro (pitch contínuo controlável em tempo real).
func play_continuous_pitch(_freq_hz: float):
    return null

func _play_synth(freq: float, harsh: bool) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = MIX_RATE
    generator.buffer_length = BUFFER_LENGTH_SEC
    player.stream = generator
    add_child(player)
    player.play()

    var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
    _fill_buffer(playback, freq, harsh)
    # auto-remove após terminar
    player.finished.connect(func(): player.queue_free())
    return player

func _fill_buffer(playback: AudioStreamGeneratorPlayback, freq: float, harsh: bool) -> void:
    var total_samples := int(MIX_RATE * NOTE_DURATION_SEC)
    var attack_samples := int(MIX_RATE * ATTACK_SEC)
    var decay_samples := int(MIX_RATE * DECAY_SEC)
    var release_samples := int(MIX_RATE * RELEASE_SEC)
    var sustain_samples := total_samples - attack_samples - decay_samples - release_samples

    var phase := 0.0
    var phase_inc := freq / MIX_RATE
    var idx := 0
    while idx < total_samples and playback.can_push_buffer(1):
        var sample := _sample_value(phase, harsh)
        var amplitude := _envelope_at(idx, attack_samples, decay_samples, sustain_samples, release_samples)
        var value := sample * amplitude * 0.5
        playback.push_frame(Vector2(value, value))
        phase = fposmod(phase + phase_inc, 1.0)
        idx += 1

func _sample_value(phase: float, harsh: bool) -> float:
    if harsh:
        # square wave para colisão
        return 1.0 if phase < 0.5 else -1.0
    # piano-like: senoidal + 2º harmônico atenuado
    var fundamental := sin(phase * TAU)
    var harmonic := 0.3 * sin(phase * TAU * 2.0)
    return fundamental + harmonic

func _envelope_at(idx: int, a: int, d: int, s: int, r: int) -> float:
    if idx < a:
        return float(idx) / float(a)
    if idx < a + d:
        var t := float(idx - a) / float(d)
        return lerpf(1.0, SUSTAIN_LEVEL, t)
    if idx < a + d + s:
        return SUSTAIN_LEVEL
    var t := float(idx - a - d - s) / float(r)
    return lerpf(SUSTAIN_LEVEL, 0.0, t)
