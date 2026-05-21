extends Control
## Painel das 4 ações especiais (Gs4=interagir, A4=pegar, As4=correr, B4=pular).
## Emite o mesmo sinal note_triggered do DirectionJoystick — Playground roteia.

signal note_triggered(note_key: String)

const ACTION_NOTES := ["Gs4", "A4", "As4", "B4"]
const BUTTON_SIZE := Vector2(96, 96)
const NEUTRAL_BUTTON := Color(0.55, 0.55, 0.58)  # espelha DirectionJoystick.NEUTRAL_SLICE
const ARMED_BRIGHTNESS := 1.6  # multiplicador de modulate quando a ação está armada
const ActionIconScript := preload("res://scripts/ActionIcon.gd")

var _buttons: Array[Button] = []
var _button_notes: Array[String] = []
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
		icon.set_anchors_preset(Control.PRESET_TOP_WIDE)
		icon.anchor_bottom = 0.55  # icon ocupa o terço superior; texto fica embaixo
		icon.set_action(NoteMapping.action_id_for(note_key))
		_buttons.append(btn)
		_button_notes.append(note_key)
	CueSettings.cue_level_changed.connect(_on_cue_changed)
	_apply_cue()

func _emit_note(note_key: String) -> void:
	note_triggered.emit(note_key)

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
		_buttons[i].modulate = base_color

## Conectado pelo Playground ao sinal armed_state_changed do Character.
## Atualiza brilho dos botões correspondentes a correr (índice 2) e pular (índice 3).
func on_armed_state_changed(running: bool, jumping: bool) -> void:
	_armed[2] = running
	_armed[3] = jumping
	_apply_cue()
