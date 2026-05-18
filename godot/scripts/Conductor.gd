extends Node
class_name Conductor
## Dono da máquina de estados do loop e do metrônomo.
## Híbrido: PREVIEW (toca a sequência 1×) → FOLLOW (jogador reproduz).
## "Só avança se acertou": erro/sem input = tropeço, índice não avança.

signal preview_note(note_key: String, index: int)
signal beat(target_note: String, index: int)
signal note_resolved(hit: bool, index: int)
signal phase_changed(phase: int)
signal sequence_complete(stats: Dictionary)

enum Phase { IDLE, PREVIEW, FOLLOW, DONE }

const DEFAULT_BPM := 90.0

var bpm: float = DEFAULT_BPM
var phase: int = Phase.IDLE

var _preset: Resource = null
var _index: int = 0
var _preview_index: int = 0
var _input_buffer: String = ""
var _attempted_current: bool = false
var _stats: Dictionary = {}
var _start_ticks_ms: int = 0
var _timer: Timer = null

func _ready() -> void:
	_reset_state()
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_advance)
	add_child(_timer)

func beat_sec() -> float:
	return 60.0 / bpm

func load_preset(preset: Resource) -> void:
	_preset = preset
	_reset_state()
	_set_phase(Phase.IDLE)

func _reset_state() -> void:
	_index = 0
	_preview_index = 0
	_input_buffer = ""
	_attempted_current = false
	_stats = { "first_try_hits": 0, "total_trips": 0, "elapsed_sec": 0.0 }

func start() -> void:
	if _preset == null:
		return
	if _timer:
		_timer.stop()
	_reset_state()
	_set_phase(Phase.PREVIEW)
	if _timer:
		_timer.start(beat_sec())

func submit_note(note_key: String) -> void:
	if phase != Phase.FOLLOW:
		return
	_input_buffer = note_key

func _set_phase(p: int) -> void:
	if phase == p:
		return
	phase = p
	phase_changed.emit(p)

## Dispatcher de tick. Timer chama isto; testes chamam direto (relógio injetável).
func _advance() -> void:
	match phase:
		Phase.PREVIEW:
			_preview_step()
		Phase.FOLLOW:
			_resolve_beat()

func _preview_step() -> void:
	if _preview_index >= _preset.notes.size():
		_begin_follow()
		return
	preview_note.emit(_preset.notes[_preview_index], _preview_index)
	_preview_index += 1

func _begin_follow() -> void:
	if _preset.notes.is_empty():
		_start_ticks_ms = Time.get_ticks_msec()
		_finish()
		return
	_index = 0
	_input_buffer = ""
	_attempted_current = false
	_start_ticks_ms = Time.get_ticks_msec()
	_set_phase(Phase.FOLLOW)
	_emit_beat()

func _emit_beat() -> void:
	if _index < _preset.notes.size():
		beat.emit(_preset.notes[_index], _index)

func _resolve_beat() -> void:
	if _index >= _preset.notes.size():
		return
	var target: String = _preset.notes[_index]
	if _input_buffer == target:
		if not _attempted_current:
			_stats.first_try_hits += 1
		note_resolved.emit(true, _index)
		_index += 1
		_attempted_current = false
		_input_buffer = ""
		if _index >= _preset.notes.size():
			_finish()
			return
		_emit_beat()
	else:
		_stats.total_trips += 1
		_attempted_current = true
		note_resolved.emit(false, _index)
		_input_buffer = ""
		_emit_beat()

func _finish() -> void:
	_stats.elapsed_sec = float(Time.get_ticks_msec() - _start_ticks_ms) / 1000.0
	if _timer:
		_timer.stop()
	_set_phase(Phase.DONE)
	sequence_complete.emit(_stats.duplicate())
