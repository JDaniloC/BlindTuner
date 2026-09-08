extends GutTest

const PianoScene := preload("res://scenes/PianoInput.tscn")

func _make() -> Node:
	var p = PianoScene.instantiate()
	add_child_autofree(p)
	return p

func after_each():
	CueSettings.set_level(0)

func test_twelve_buttons_created():
	var p = _make()
	assert_eq(p._buttons.size(), 12)

func test_button_notes_match_note_mapping_order():
	var p = _make()
	assert_eq(p._button_notes, NoteMapping.NOTES.keys())

func test_button_press_emits_note_triggered_for_movement_note():
	var p = _make()
	watch_signals(p)
	var idx = p._button_notes.find("D4")
	p._buttons[idx].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["D4"])

func test_button_press_emits_note_triggered_for_action_note():
	var p = _make()
	watch_signals(p)
	var idx = p._button_notes.find("A4")
	p._buttons[idx].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["A4"])

func test_level_zero_shows_name_and_color():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, NoteMapping.label_for("C4"))
	assert_eq(p._buttons[idx].modulate, NoteMapping.color_for("C4"))

func test_level_three_neutral_and_empty():
	CueSettings.set_level(0)
	var p = _make()
	CueSettings.set_level(3)
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, "")
	assert_eq(p._buttons[idx].modulate, p.NEUTRAL_BUTTON)

func test_on_armed_state_changed_brightens_correr_button():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("As4")
	var base = p._buttons[idx].modulate
	p.on_armed_state_changed(true, false)
	assert_gt(p._buttons[idx].modulate.r, base.r, "armed brighten R")

func test_on_armed_state_changed_brightens_pular_button():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("B4")
	var base = p._buttons[idx].modulate
	p.on_armed_state_changed(false, true)
	assert_gt(p._buttons[idx].modulate.r, base.r, "armed brighten R")

func test_disarm_restores_modulate_to_cue_base():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("As4")
	var base = p._buttons[idx].modulate
	p.on_armed_state_changed(true, false)
	p.on_armed_state_changed(false, false)
	assert_eq(p._buttons[idx].modulate, base, "modulate volta ao base após disarm")
