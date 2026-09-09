extends Control
## Painel das 4 ações especiais (Gs4=interagir, A4=pegar, As4=correr, B4=pular).
## Emite o mesmo sinal note_triggered do DirectionJoystick — Playground roteia.

signal note_triggered(note_key: String)

const ACTION_NOTES := ["Gs4", "A4", "As4", "B4"]
const BUTTON_SIZE := Vector2(96, 96)
const NEUTRAL_BUTTON := Color(0.55, 0.55, 0.58)  # espelha DirectionJoystick.NEUTRAL_SLICE
const ARMED_BRIGHTNESS := 1.6  # multiplicador da cor da placa quando a ação está armada
const CORNER_RADIUS := 8
const ActionIconScript := preload("res://scripts/ActionIcon.gd")
# ColorDistance é RefCounted, não autoload -- precisa de preload pra ser usado.
const ColorDistance := preload("res://scripts/ColorDistance.gd")

var _buttons: Array[Button] = []
var _button_notes: Array[String] = []
# Paralelo a _buttons -- guardado para poder retingir o glifo a cada _apply_cue().
var _icons: Array[Control] = []
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
		var icon := ActionIconScript.new()
		btn.add_child(icon)
		# NÃO usar set_anchors_preset aqui: no Godot 4 ele roda com
		# keep_offsets=true e converte o rect atual em offsets, preservando o
		# 0x0 de um Control recém-criado -- offset_right virava -96 e o ícone
		# ficava com largura zero (medido: size=(0.0, 52.8)). Ancorar
		# explicitamente com offsets zerados dá o rect certo.
		icon.anchor_left = 0.0
		icon.anchor_right = 1.0
		icon.anchor_top = 0.0
		icon.anchor_bottom = 0.55  # ícone ocupa a faixa de cima; texto fica embaixo
		icon.offset_left = 0.0
		icon.offset_right = 0.0
		icon.offset_top = 0.0
		icon.offset_bottom = 0.0
		icon.set_action(NoteMapping.action_id_for(note_key))
		_buttons.append(btn)
		_button_notes.append(note_key)
		_icons.append(icon)
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
		_buttons[i].text = NoteMapping.label_for(note_key) if show_name else ""
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
		_icons[i].set_tint(ColorDistance.icon_tint_for(base_color))

## Conectado pelo Playground ao sinal armed_state_changed do Character.
## Atualiza brilho dos botões correspondentes a correr (índice 2) e pular (índice 3).
func on_armed_state_changed(running: bool, jumping: bool) -> void:
	_armed[2] = running
	_armed[3] = jumping
	_apply_cue()
