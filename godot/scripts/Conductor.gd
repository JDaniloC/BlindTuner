extends Node
class_name Conductor
## Dono da máquina de estados do loop (jogo de conhecimento, sem pressão de tempo).
## IDLE (livre) → PREVIEW (ouve a melodia 1×) → CALL (eco nota-a-nota, sem relógio)
## → REPLAY (personagem "toca" e anda o caminho) → DONE (stats).
## CALL avança SÓ por submit_note (resolução imediata); sem dano, sem fail.

signal preview_note(note_key: String, index: int)
signal call_cue(note_key: String, index: int)
signal replay_note(note_key: String, index: int)
signal note_resolved(hit: bool, index: int)
signal phase_changed(phase: int)
signal sequence_complete(stats: Dictionary)

enum Phase { IDLE, PREVIEW, CALL, REPLAY, DONE }

const DEFAULT_BPM := 90.0
const CUE_GAP_AFTER_USER_SEC := 0.7  # ~note_duration + margem; cancelável por novo submit_note

var bpm: float = DEFAULT_BPM
var phase: int = Phase.IDLE

var _preset: Resource = null
var _index: int = 0
var _preview_index: int = 0
var _replay_index: int = 0
var _attempted_current: bool = false  # true se o índice atual já teve ao menos um erro
var _stats: Dictionary = {}
var _start_ticks_ms: int = 0
var _timer: Timer = null
var _pending_cue_timer: SceneTreeTimer = null

func _ready() -> void:
	_reset_state()
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_advance)
	add_child(_timer)

func beat_sec() -> float:
	return 60.0 / bpm

## Carrega o preset e volta a IDLE. Não re-emite phase_changed se já estava em IDLE.
func load_preset(preset: Resource) -> void:
	_preset = preset
	if _timer:
		_timer.stop()
	_reset_state()
	_set_phase(Phase.IDLE)

func _reset_state() -> void:
	_index = 0
	_preview_index = 0
	_replay_index = 0
	_attempted_current = false
	_stats = { "first_try_hits": 0, "total_trips": 0, "elapsed_sec": 0.0 }

func start() -> void:
	if _preset == null:
		return
	if _timer:
		_timer.stop()
	_reset_state()
	if _preset.notes.is_empty():
		_finish()  # nada a tocar: IDLE -> DONE
		return
	_set_phase(Phase.PREVIEW)
	if _timer:
		_timer.start(beat_sec())

## Entrada do jogador no CALL. Resolve imediatamente (sem esperar tick).
## O próximo call_cue é agendado via timer para dar tempo à nota do jogador tocar.
func submit_note(note_key: String) -> void:
	if phase != Phase.CALL:
		return
	if _preset == null:
		return
	if _index >= _preset.notes.size():
		return
	# Cancela qualquer cue agendada — entrada do usuário interrompe o cue pendente
	_pending_cue_timer = null
	var target: String = _preset.notes[_index]
	if note_key == target:
		if not _attempted_current:
			_stats.first_try_hits += 1
		note_resolved.emit(true, _index)
		_index += 1
		_attempted_current = false
		if _index >= _preset.notes.size():
			_begin_replay()
		else:
			_schedule_call_cue(_preset.notes[_index], _index)
	else:
		_stats.total_trips += 1
		_attempted_current = true
		note_resolved.emit(false, _index)
		_schedule_call_cue(_preset.notes[_index], _index)

func _schedule_call_cue(note: String, idx: int) -> void:
	var t := get_tree().create_timer(CUE_GAP_AFTER_USER_SEC)
	_pending_cue_timer = t
	t.timeout.connect(_fire_call_cue.bind(note, idx, t))

func _fire_call_cue(note: String, idx: int, timer: SceneTreeTimer) -> void:
	# Bail se outra submit_note do usuário substituiu este timer pendente
	if _pending_cue_timer != timer:
		return
	if phase != Phase.CALL:
		return
	if _index != idx:
		return
	_pending_cue_timer = null
	call_cue.emit(note, idx)

## Reemite o call_cue da nota atual no modo CALL sem computar tropeço nem penalizar estrelas.
func replay_current_cue() -> void:
	if phase != Phase.CALL:
		return
	if _preset == null:
		return
	if _index >= _preset.notes.size():
		return
	_pending_cue_timer = null
	call_cue.emit(_preset.notes[_index], _index)

func _set_phase(p: int) -> void:
	if phase == p:
		return
	phase = p
	phase_changed.emit(p)

## Dispatcher de tick. Timer chama isto; testes chamam direto (relógio injetável).
## CALL NÃO é pautado por tick — ausente do match de propósito (sem pressão de tempo).
func _advance() -> void:
	match phase:
		Phase.PREVIEW:
			_preview_step()
		Phase.REPLAY:
			_replay_step()

func _preview_step() -> void:
	if _preview_index >= _preset.notes.size():
		_begin_call()
		return
	preview_note.emit(_preset.notes[_preview_index], _preview_index)
	_preview_index += 1

func _begin_call() -> void:
	if _timer:
		_timer.stop()  # CALL é orientado a input, sem relógio
	_pending_cue_timer = null
	_index = 0
	_attempted_current = false
	_start_ticks_ms = Time.get_ticks_msec()
	_set_phase(Phase.CALL)
	call_cue.emit(_preset.notes[_index], _index)

func _begin_replay() -> void:
	_pending_cue_timer = null
	_stats.elapsed_sec = float(Time.get_ticks_msec() - _start_ticks_ms) / 1000.0
	_replay_index = 0
	_set_phase(Phase.REPLAY)
	if _timer:
		_timer.start(beat_sec())

func _replay_step() -> void:
	if _replay_index >= _preset.notes.size():
		_finish()
		return
	replay_note.emit(_preset.notes[_replay_index], _replay_index)
	_replay_index += 1

func _finish() -> void:
	if _timer:
		_timer.stop()
	_set_phase(Phase.DONE)
	sequence_complete.emit(_stats.duplicate())
