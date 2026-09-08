extends Control
## Modo de input "Toque no Escuro": arrasta em qualquer lugar da tela pra indicar
## direção (sem zona/cor desenhada); tipo de gesto (tap/hold/double-tap/flick)
## indica as 4 notas de ação. Ver docs/superpowers/specs/2026-09-08-alternate-input-modes-design.md.

signal note_triggered(note_key: String)

const DRAG_MIN_DISTANCE := 25.0    # px -- acima disso, é arrasto de direção
const FLICK_MAX_MS := 150          # arrasto curto+rápido = flick = pular
const LONG_PRESS_MS := 500         # segurar sem arrastar = interagir
const DOUBLE_TAP_WINDOW_MS := 400  # espelha Character.DOUBLE_TAP_WINDOW_MS

var _press_pos := Vector2.ZERO
var _press_time_ms := 0
var _had_drag := false
var _pending_tap_timer: SceneTreeTimer = null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_press_pos = event.position
			_press_time_ms = Time.get_ticks_msec()
			_had_drag = false
			accept_event()
		else:
			_resolve_gesture(event.position)
			accept_event()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if (event.position - _press_pos).length() >= DRAG_MIN_DISTANCE:
			_had_drag = true

func _resolve_gesture(release_pos: Vector2) -> void:
	var now := Time.get_ticks_msec()
	var elapsed_ms := now - _press_time_ms
	var offset := release_pos - _press_pos
	var note := _classify_gesture(_had_drag, offset, elapsed_ms)
	if note != "":
		_pending_tap_timer = null
		_emit(note)
		return
	# Toque simples ambíguo: pode ser "pegar" (1º de um par) ou "correr" (2º dentro da janela).
	if _pending_tap_timer != null:
		_pending_tap_timer = null
		_emit("As4")
		return
	var t := get_tree().create_timer(DOUBLE_TAP_WINDOW_MS / 1000.0)
	_pending_tap_timer = t
	t.timeout.connect(_confirm_pending_tap.bind(t))

func _confirm_pending_tap(timer: SceneTreeTimer) -> void:
	if _pending_tap_timer != timer:
		return  # superado por um 2º toque ou outro gesto
	_pending_tap_timer = null
	_emit("A4")

func _emit(note: String) -> void:
	if note != "":
		note_triggered.emit(note)

## Função pura -- sem estado, sem Time.get_ticks_msec(). Retorna a nota se o
## gesto é INEQUÍVOCO (arrasto de direção / flick / hold longo). Retorna "" se
## foi um toque simples no lugar -- quem chama decide entre "pegar" e "correr"
## via _pending_tap_timer, não aqui.
func _classify_gesture(had_drag: bool, offset: Vector2, elapsed_ms: int) -> String:
	if had_drag and offset.length() >= DRAG_MIN_DISTANCE:
		var angle_rad := atan2(offset.x, -offset.y)
		return NoteMapping.snap_angle_to_note(rad_to_deg(angle_rad), true)
	if had_drag and elapsed_ms < FLICK_MAX_MS:
		return "B4"
	if elapsed_ms >= LONG_PRESS_MS:
		return "Gs4"
	return ""
