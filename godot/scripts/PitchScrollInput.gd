extends Control
## Modo de input "Scroll de Afinação": braço fretless de instrumento de corda
## (sem marcador de posição -- violino/cello de verdade não têm). Arrasta o
## dedo verticalmente pra ouvir a frequência mudar ao vivo; ao soltar,
## resolve pra nota mais próxima do valor largado.

signal note_triggered(note_key: String)

# O braço ocupa o corredor livre abaixo do NotePanel (medido no viewport de
# projeto 720x1280: y=240 até y=1280). As medidas de SEÇÃO -- cravelhal,
# cravelhas, largura do braço, cordas, dedo -- cresceram pelo fator horizontal
# 150/110 (~1,36); o comprimento extra é todo do braço, que é o que o dedo
# percorre. Ampliar a altura sem ampliar a seção deixaria um espeto fino de
# 780px, difícil de acertar justamente pro público de baixa visão.
#
# AO MUDAR ESTE VALOR, mude junto os offsets do nó PitchScrollInput em
# Playground.tscn. O custom_minimum_size abaixo PERDE para eles quando o
# Control é filho do CanvasLayer (medido: minsize (150,780) e size (110,400) ao
# mesmo tempo). Como _gui_input só recebe evento dentro do rect do nó, o excesso
# de braço vira zona morta e as notas graves ficam inalcançáveis -- sem erro e
# sem warning. test_playground_input_layout.gd vigia isso na cena de verdade.
const BOARD_SIZE := Vector2(150, 780)
const BOARD_MARGIN := Vector2(10, 10)
const HEAD_SIZE := Vector2(79, 106)         # cravelhal no topo
const PEG_SIZE := Vector2(27, 11)
const PEG_ROW_TOP := 33.0                   # y da 1a cravelha de cada lado
const PEG_ROW_SPACING := 27.0               # desnível entre as duas do mesmo lado
const PEG_INSET := 5.0                      # quanto a cravelha entra no cravelhal
const NECK_WIDTH := 84.0
const NECK_TOP := 101.0
# 4 cordas, como violino/cello de verdade. A ativa é a que responde ao dedo.
const STRING_OFFSETS_X: Array[float] = [-29.0, -10.0, 10.0, 25.0]
const ACTIVE_STRING_INDEX := 1
const BOARD_COLOR_TOP := Color(0.227, 0.165, 0.102)     # #3a2a1a
const BOARD_COLOR_BOTTOM := Color(0.141, 0.094, 0.063)  # #241809
const HEAD_COLOR := Color(0.290, 0.200, 0.125)
const PEG_COLOR := Color(0.851, 0.725, 0.541)
const STRING_COLOR := Color(0.910, 0.886, 0.816)        # #e8e2d0
const STRING_ACTIVE_COLOR := Color(1.0, 0.992, 0.949)
const FINGER_FILL := Color(0.949, 0.788, 0.541)         # #f2c98a
const FINGER_BORDER := Color(0.478, 0.290, 0.071)       # #7a4a12
const FINGER_RADIUS := 18.0
# Precisa ser alto o bastante pro passo de cor entre faixas cair abaixo do
# limiar perceptível (~1 unidade de 8 bits). Uma borda visível em Y fixo vira
# um marco de afinação sempre no mesmo lugar -- ou seja, funcionalmente um
# traste, o que quebra a restrição fretless. Não reduza sem refazer essa conta.
# Conta refeita quando o braço cresceu: o canal que mais varia é o R, de 58
# para 36 (22 unidades de 8 bits). 64 faixas dão 0,34 unidade por faixa, bem
# abaixo do limiar -- e mantêm a faixa em ~10px, como era no braço de 400px.
const GRADIENT_STRIPS := 64

var _dragging := false
var _finger_y := 0.0

func _ready() -> void:
	custom_minimum_size = BOARD_SIZE
	mouse_filter = MOUSE_FILTER_STOP
	_finger_y = NECK_TOP + BOARD_MARGIN.y

func _draw() -> void:
	var cx := BOARD_SIZE.x * 0.5
	# Cravelhal (topo) + 4 cravelhas, 2 de cada lado
	var head_pos := Vector2(cx - HEAD_SIZE.x * 0.5, 0.0)
	draw_rect(Rect2(head_pos, HEAD_SIZE), HEAD_COLOR)
	for i in range(4):
		var on_left := i < 2
		var py := PEG_ROW_TOP + float(i % 2) * PEG_ROW_SPACING
		var px := head_pos.x - PEG_SIZE.x + PEG_INSET if on_left else head_pos.x + HEAD_SIZE.x - PEG_INSET
		draw_rect(Rect2(Vector2(px, py), PEG_SIZE), PEG_COLOR)

	# Braço, com gradiente simulado por faixas (sem asset de imagem)
	var neck_h := BOARD_SIZE.y - NECK_TOP
	var strip_h := neck_h / float(GRADIENT_STRIPS)
	for i in range(GRADIENT_STRIPS):
		var t := float(i) / float(GRADIENT_STRIPS - 1)
		var c := BOARD_COLOR_TOP.lerp(BOARD_COLOR_BOTTOM, t)
		draw_rect(Rect2(Vector2(cx - NECK_WIDTH * 0.5, NECK_TOP + strip_h * i), Vector2(NECK_WIDTH, strip_h + 1.0)), c)

	# 4 cordas -- a ativa mais grossa e mais clara. Sem nenhuma marca de
	# posição ao longo do braço: violino/cello são fretless, e marcar posição
	# entregaria a nota que o jogador deveria achar de ouvido.
	var top := NECK_TOP + BOARD_MARGIN.y
	var bottom := BOARD_SIZE.y - BOARD_MARGIN.y
	for i in range(STRING_OFFSETS_X.size()):
		var sx: float = cx + STRING_OFFSETS_X[i]
		var is_active := i == ACTIVE_STRING_INDEX
		var col := STRING_ACTIVE_COLOR if is_active else STRING_COLOR
		var w := 3.0 if is_active else 2.0
		draw_line(Vector2(sx, top), Vector2(sx, bottom), col, w, true)

	# Marcador de dedo, sempre sobre a corda ativa
	var fx: float = cx + STRING_OFFSETS_X[ACTIVE_STRING_INDEX]
	draw_circle(Vector2(fx, _finger_y), FINGER_RADIUS, FINGER_FILL)
	draw_arc(Vector2(fx, _finger_y), FINGER_RADIUS, 0, TAU, 24, FINGER_BORDER, 2.0, true)

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
	_finger_y = clampf(local_y, NECK_TOP + BOARD_MARGIN.y, BOARD_SIZE.y - BOARD_MARGIN.y)
	queue_redraw()
	AudioManager.play_continuous_pitch(_frequency_for_finger_y())

## Topo do braço útil (logo abaixo do cravelhal) = nota mais aguda, igual
## à posição de dedo mais próxima da cravelha num instrumento de corda real.
func _frequency_for_finger_y() -> float:
	var top := NECK_TOP + BOARD_MARGIN.y
	var usable_height := (BOARD_SIZE.y - BOARD_MARGIN.y) - top
	var t := (_finger_y - top) / usable_height
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
