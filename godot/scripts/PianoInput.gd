extends Control
## Modo de input "Piano Virtual": 12 teclas (8 movimento + 4 ação), uma por nota.
## Emite o mesmo sinal note_triggered que DirectionJoystick/SpecialActionPanel.

signal note_triggered(note_key: String)

const BUTTON_SIZE := Vector2(56, 56)
const NEUTRAL_BUTTON := Color(0.55, 0.55, 0.58)  # espelha SpecialActionPanel.NEUTRAL_BUTTON
const ARMED_BRIGHTNESS := 1.6  # espelha SpecialActionPanel.ARMED_BRIGHTNESS

var _buttons: Array[Button] = []
var _button_notes: Array[String] = []
# Paralelo às notas armáveis (correr/pular); atualizado por on_armed_state_changed.
var _armed: Array[bool] = [false, false, false, false]

func _ready() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	add_child(col)

	var movement_row := GridContainer.new()
	movement_row.columns = 8
	movement_row.add_theme_constant_override("h_separation", 4)
	col.add_child(movement_row)

	var action_row := GridContainer.new()
	action_row.columns = 4
	action_row.add_theme_constant_override("h_separation", 4)
	col.add_child(action_row)

	for key in NoteMapping.NOTES.keys():
		var note_key: String = key
		var parent := action_row if NoteMapping.is_action_note(note_key) else movement_row
		var btn := Button.new()
		btn.custom_minimum_size = BUTTON_SIZE
		btn.pressed.connect(_emit_note.bind(note_key))
		parent.add_child(btn)
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
		var armed_idx := _armed_index_for(note_key)
		if armed_idx >= 0 and _armed[armed_idx]:
			base_color = Color(base_color.r * ARMED_BRIGHTNESS,
				base_color.g * ARMED_BRIGHTNESS,
				base_color.b * ARMED_BRIGHTNESS, base_color.a)
		_buttons[i].modulate = base_color

## As4=correr (índice 2) e B4=pular (índice 3) espelham a convenção de índice
## já usada em SpecialActionPanel._armed. Demais notas não são armáveis (-1).
func _armed_index_for(note_key: String) -> int:
	match note_key:
		"As4": return 2
		"B4": return 3
		_: return -1

## Conectado pelo Playground ao sinal armed_state_changed do Character quando
## este modo está ativo (mesmo contrato de SpecialActionPanel.on_armed_state_changed).
func on_armed_state_changed(running: bool, jumping: bool) -> void:
	_armed[2] = running
	_armed[3] = jumping
	_apply_cue()
