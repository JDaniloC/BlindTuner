extends Control
## Painel das 4 ações especiais (Gs4=interagir, A4=pegar, As4=correr, B4=pular).
## Emite o mesmo sinal note_triggered do DirectionJoystick — Playground roteia.

signal note_triggered(note_key: String)

const ACTION_NOTES := ["Gs4", "A4", "As4", "B4"]
const BUTTON_SIZE := Vector2(96, 96)
const NEUTRAL_BUTTON := Color(0.55, 0.55, 0.58)  # espelha DirectionJoystick.NEUTRAL_SLICE
const ARMED_BRIGHTNESS := 1.6  # multiplicador da cor da placa quando a ação está armada
const CORNER_RADIUS := 8
## Faixa reservada ao glifo e respiro até o nome. O ActionIcon desenha o glifo
## centrado no próprio rect a ICON_FRAC do menor lado, então esta altura é que
## define o tamanho do símbolo (44 * 0.7 = ~31px).
const ICON_MIN_HEIGHT := 44.0
const ICON_TEXT_GAP := 8
const ActionIconScript := preload("res://scripts/ActionIcon.gd")
# ColorDistance é RefCounted, não autoload -- precisa de preload pra ser usado.
const ColorDistance := preload("res://scripts/ColorDistance.gd")

var _buttons: Array[Button] = []
var _button_notes: Array[String] = []
# Paralelo a _buttons -- guardado para poder retingir o glifo a cada _apply_cue().
var _icons: Array[Control] = []
# Paralelo a _buttons -- o nome da nota saiu do Button.text para uma Label
# dentro da VBox, que é o que permite centrar glifo e nome como um grupo.
var _labels: Array[Label] = []
# Paralelo a _buttons; true quando o flag correspondente está armado no Character.
# Atualizado por on_armed_state_changed (conectado pelo Playground).
var _armed: Array[bool] = [false, false, false, false]

func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	for note_key in ACTION_NOTES:
		var btn := Button.new()
		btn.custom_minimum_size = BUTTON_SIZE
		btn.pressed.connect(_emit_note.bind(note_key))
		grid.add_child(btn)
		# Glifo e nome vivem numa VBox que os trata como UM grupo: ela centra o
		# par verticalmente e dá o respiro entre eles pela constante de
		# separação. Antes o ícone era ancorado na faixa de cima do botão e o
		# nome era o text do próprio Button -- que o Godot centra no botão
		# INTEIRO, então o glifo terminava onde o nome começava, sem respiro, e
		# o conjunto ficava alto. Fazer isso na mão exigiria medir a fonte.
		var box := VBoxContainer.new()
		box.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", ICON_TEXT_GAP)
		# Sem isto a VBox engole o clique e os 4 botões param de responder.
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(box)

		var icon := ActionIconScript.new()
		icon.custom_minimum_size = Vector2(0, ICON_MIN_HEIGHT)
		box.add_child(icon)
		icon.set_action(NoteMapping.action_id_for(note_key))

		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lbl)

		_buttons.append(btn)
		_button_notes.append(note_key)
		_icons.append(icon)
		_labels.append(lbl)
	CueSettings.cue_level_changed.connect(_on_cue_changed)
	# Repinta na troca de esquema de cor, sem precisar reiniciar a fase.
	ColorSchemeSettings.scheme_changed.connect(_on_scheme_changed)
	_apply_cue()

func _emit_note(note_key: String) -> void:
	note_triggered.emit(note_key)

func _on_scheme_changed(_id: String) -> void:
	_apply_cue()

func _on_cue_changed(_level: int) -> void:
	_apply_cue()

func _apply_cue() -> void:
	var show_name := CueSettings.shows_name()
	var show_color := CueSettings.shows_color()
	for i in range(_buttons.size()):
		var note_key := _button_notes[i]
		_labels[i].text = NoteMapping.label_for(note_key) if show_name else ""
		# Escondida (não só vazia) para a VBox não reservar a altura da linha:
		# assim, sem o nome, o glifo fica centrado sozinho em vez de alto.
		_labels[i].visible = show_name
		var base_color: Color = NoteMapping.color_for(note_key) if show_color else NEUTRAL_BUTTON
		if _armed[i]:
			base_color = Color(base_color.r * ARMED_BRIGHTNESS,
				base_color.g * ARMED_BRIGHTNESS,
				base_color.b * ARMED_BRIGHTNESS, base_color.a)
		# A cor vai no fundo da placa, não no modulate: modulate se PROPAGA pros
		# filhos, e o ícone é filho do botão -- tingir por modulate deixava o
		# glifo exatamente da cor do fundo, ou seja, invisível. Mesma receita já
		# usada no PianoInput.
		var sb := StyleBoxFlat.new()
		sb.bg_color = base_color
		sb.corner_radius_top_left = CORNER_RADIUS
		sb.corner_radius_top_right = CORNER_RADIUS
		sb.corner_radius_bottom_left = CORNER_RADIUS
		sb.corner_radius_bottom_right = CORNER_RADIUS
		_buttons[i].add_theme_stylebox_override("normal", sb)
		_buttons[i].add_theme_stylebox_override("hover", sb)
		# "pressed" ganha o mesmo desenho com o fundo escurecido, pra apertar o
		# botão mudar alguma coisa visualmente.
		var pressed_sb := StyleBoxFlat.new()
		pressed_sb.bg_color = Color(base_color.r * 0.85, base_color.g * 0.85,
			base_color.b * 0.85, base_color.a)
		pressed_sb.corner_radius_top_left = CORNER_RADIUS
		pressed_sb.corner_radius_top_right = CORNER_RADIUS
		pressed_sb.corner_radius_bottom_left = CORNER_RADIUS
		pressed_sb.corner_radius_bottom_right = CORNER_RADIUS
		_buttons[i].add_theme_stylebox_override("pressed", pressed_sb)
		_buttons[i].modulate = Color.WHITE  # neutro: qualquer cor aqui tingiria o ícone junto
		# Glifo e NOME da nota recebem a MESMA tinta: é a mesma decisão ("tinta
		# escura em placa clara e vice-versa"), e duas tintas diferentes na mesma
		# placa leriam como dois elementos distintos.
		#
		# Sem isto o nome ficava no cinza claro do tema padrão do Godot sobre a
		# cor da nota: medido no esquema Pedagógico (o de fábrica), 1,25:1 no Si e
		# 1,36:1 no Lá -- ilegível. Levar a cor da placa pro bg_color da
		# StyleBoxFlat pinta o FUNDO e não mexe no rótulo; enquanto ela vinha do
		# modulate, o rótulo era tingido junto e por acidente dava 4,9 a 8,5:1.
		var ink := ColorDistance.icon_tint_for(base_color)
		# A Label não está sob blindtuner_theme.tres (este painel é irmão do
		# GameHUD na CanvasLayer, não filho), então sem override ela herda o
		# cinza claro do tema padrão do Godot sobre a cor da nota -- medido em
		# 1,25:1 no Si e 1,36:1 no Lá, ilegível. Uma Label tem um único estado
		# de cor, ao contrário do Button, que ainda clareia no hover/pressed.
		_labels[i].add_theme_color_override("font_color", ink)
		_icons[i].set_tint(ink)

## Conectado pelo Playground ao sinal armed_state_changed do Character.
## Atualiza brilho dos botões correspondentes a correr (índice 2) e pular (índice 3).
func on_armed_state_changed(running: bool, jumping: bool) -> void:
	_armed[2] = running
	_armed[3] = jumping
	_apply_cue()
