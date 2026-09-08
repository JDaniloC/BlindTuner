extends Control
## Modo de input "Scroll de Afinação": braço fretless de instrumento de corda
## (sem marcador de posição -- violino/cello de verdade não têm). Arrasta o
## dedo verticalmente pra ouvir a frequência mudar ao vivo; ao soltar,
## resolve pra nota mais próxima do valor largado.

signal note_triggered(note_key: String)

const BOARD_SIZE := Vector2(70, 340)
const BOARD_MARGIN := Vector2(10, 10)
const BOARD_COLOR_TOP := Color(0.227, 0.165, 0.102)     # #3a2a1a
const BOARD_COLOR_BOTTOM := Color(0.165, 0.114, 0.071)  # #2a1d12
const STRING_COLOR := Color(0.910, 0.886, 0.816)        # #e8e2d0
const FINGER_FILL := Color(0.949, 0.788, 0.541)         # #f2c98a
const FINGER_BORDER := Color(0.478, 0.290, 0.071)       # #7a4a12
const FINGER_RADIUS := 13.0
const GRADIENT_STRIPS := 6

var _dragging := false
var _finger_y := 0.0

func _ready() -> void:
	custom_minimum_size = BOARD_SIZE
	mouse_filter = MOUSE_FILTER_STOP
	_finger_y = BOARD_MARGIN.y

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, BOARD_SIZE), BOARD_COLOR_TOP)
	var strip_height := BOARD_SIZE.y / float(GRADIENT_STRIPS)
	for i in range(GRADIENT_STRIPS):
		var t := float(i) / float(GRADIENT_STRIPS - 1)
		var c := BOARD_COLOR_TOP.lerp(BOARD_COLOR_BOTTOM, t)
		draw_rect(Rect2(Vector2(0, strip_height * i), Vector2(BOARD_SIZE.x, strip_height + 1)), c)
	var string_x := BOARD_SIZE.x * 0.5
	draw_line(Vector2(string_x, BOARD_MARGIN.y), Vector2(string_x, BOARD_SIZE.y - BOARD_MARGIN.y), STRING_COLOR, 2.0, true)
	draw_circle(Vector2(string_x, _finger_y), FINGER_RADIUS, FINGER_FILL)
	draw_arc(Vector2(string_x, _finger_y), FINGER_RADIUS, 0, TAU, 24, FINGER_BORDER, 2.0, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_dragging = true
			_move_finger_to(event.position.y)
			accept_event()
		else:
			if _dragging:
				_dragging = false
				_on_drag_ended()
			accept_event()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging:
			_move_finger_to(event.position.y)
			accept_event()

func _move_finger_to(local_y: float) -> void:
	_finger_y = clampf(local_y, BOARD_MARGIN.y, BOARD_SIZE.y - BOARD_MARGIN.y)
	queue_redraw()
	AudioManager.play_continuous_pitch(_frequency_for_finger_y())

## Topo do braço (perto de onde ficaria a cravelha) = nota mais aguda, igual
## à posição de dedo mais próxima da cravelha num instrumento de corda real.
func _frequency_for_finger_y() -> float:
	var usable_height := BOARD_SIZE.y - BOARD_MARGIN.y * 2.0
	var t := (_finger_y - BOARD_MARGIN.y) / usable_height
	return lerpf(_highest_frequency(), _lowest_frequency(), t)

func _lowest_frequency() -> float:
	var lowest := INF
	for key in NoteMapping.NOTES:
		lowest = minf(lowest, float(NoteMapping.NOTES[key]["freq"]))
	return lowest

func _highest_frequency() -> float:
	var highest := 0.0
	for key in NoteMapping.NOTES:
		highest = maxf(highest, float(NoteMapping.NOTES[key]["freq"]))
	return highest

func _on_drag_ended() -> void:
	AudioManager.stop_continuous_pitch()
	var note := NoteMapping.nearest_note_for_frequency(_frequency_for_finger_y())
	note_triggered.emit(note)

func _exit_tree() -> void:
	# Sai da árvore (troca de cena, ou removido enquanto o tom ainda soa --
	# ex: arrasto em progresso quando o jogo troca de preset/mapa) sem passar
	# por _on_drag_ended: o tom contínuo não pode ficar tocando indefinidamente.
	AudioManager.stop_continuous_pitch()
