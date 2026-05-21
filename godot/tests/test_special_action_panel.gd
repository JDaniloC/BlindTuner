extends GutTest

const PanelScene := preload("res://scenes/SpecialActionPanel.tscn")

func _make() -> Node:
	var p = PanelScene.instantiate()
	add_child_autofree(p)
	return p

func after_each():
	CueSettings.set_level(0)

func test_four_buttons_created():
	var p = _make()
	assert_eq(p._buttons.size(), 4)

func test_button_notes_in_expected_order():
	var p = _make()
	assert_eq(p._button_notes, ["Gs4", "A4", "As4", "B4"])

func test_button_press_emits_note_triggered_gs4():
	var p = _make()
	watch_signals(p)
	p._buttons[0].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["Gs4"])

func test_button_press_emits_note_triggered_a4():
	var p = _make()
	watch_signals(p)
	p._buttons[1].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["A4"])

func test_button_press_emits_note_triggered_as4():
	var p = _make()
	watch_signals(p)
	p._buttons[2].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["As4"])

func test_button_press_emits_note_triggered_b4():
	var p = _make()
	watch_signals(p)
	p._buttons[3].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["B4"])

func test_panel_visible_in_all_cue_levels():
	var p = _make()
	for lvl in range(4):
		CueSettings.set_level(lvl)
		assert_true(p.visible, "nível %d: painel visível" % lvl)

func test_level_zero_shows_name_and_color():
	CueSettings.set_level(0)
	var p = _make()
	assert_eq(p._buttons[0].text, NoteMapping.label_for("Gs4"))
	assert_eq(p._buttons[0].modulate, NoteMapping.color_for("Gs4"))

func test_level_one_hides_name_keeps_color():
	CueSettings.set_level(0)
	var p = _make()
	CueSettings.set_level(1)
	assert_eq(p._buttons[0].text, "")
	assert_eq(p._buttons[0].modulate, NoteMapping.color_for("Gs4"))

func test_level_three_neutral_and_empty():
	CueSettings.set_level(0)
	var p = _make()
	CueSettings.set_level(3)
	assert_eq(p._buttons[0].text, "")
	assert_eq(p._buttons[0].modulate, p.NEUTRAL_BUTTON)

func test_level_two_hides_name_keeps_color():
	CueSettings.set_level(0)
	var p = _make()
	CueSettings.set_level(2)
	assert_eq(p._buttons[0].text, "")
	assert_eq(p._buttons[0].modulate, NoteMapping.color_for("Gs4"))
