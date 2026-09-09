extends GutTest

const PanelScene := preload("res://scenes/SpecialActionPanel.tscn")

func _make() -> Node:
	var p = PanelScene.instantiate()
	add_child_autofree(p)
	return p

func before_each():
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	CueSettings.set_level(0)
	ColorSchemeSettings.reset_to_defaults()

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

const ActionIconScript := preload("res://scripts/ActionIcon.gd")

func test_each_button_has_action_icon_child():
	var p = _make()
	var expected_actions = ["interagir", "pegar", "correr", "pular"]
	for i in range(p._buttons.size()):
		var btn = p._buttons[i]
		var icon: Node = null
		for child in btn.get_children():
			if child.get_script() == ActionIconScript:
				icon = child
				break
		assert_not_null(icon, "botão %d sem ActionIcon" % i)
		assert_eq(icon.action_id, expected_actions[i],
			"ActionIcon do botão %d deveria ser %s" % [i, expected_actions[i]])

func test_set_action_updates_action_id():
	var icon = ActionIconScript.new()
	icon.size = Vector2(64, 64)
	add_child_autofree(icon)
	icon.set_action("pular")
	assert_eq(icon.action_id, "pular")

func test_action_icon_ignores_unknown_action():
	var icon = ActionIconScript.new()
	icon.size = Vector2(64, 64)
	add_child_autofree(icon)
	icon.set_action("inexistente")
	await get_tree().process_frame  # força _draw() para garantir que o match no-op não quebra
	assert_eq(icon.action_id, "inexistente")

func test_on_armed_state_changed_brightens_correr_button():
	CueSettings.set_level(0)  # cor visível
	var p = _make()
	var base = p._buttons[2].modulate  # As4 = correr (índice 2)
	p.on_armed_state_changed(true, false)
	assert_gt(p._buttons[2].modulate.get_luminance(), base.get_luminance(), "armed brighten")
	assert_eq(p._armed, [false, false, true, false])

func test_on_armed_state_changed_brightens_pular_button():
	CueSettings.set_level(0)
	var p = _make()
	var base = p._buttons[3].modulate  # B4 = pular (índice 3)
	p.on_armed_state_changed(false, true)
	assert_gt(p._buttons[3].modulate.get_luminance(), base.get_luminance(), "armed brighten")
	assert_eq(p._armed, [false, false, false, true])

func test_disarm_restores_modulate_to_cue_base():
	CueSettings.set_level(0)
	var p = _make()
	var base = p._buttons[2].modulate
	p.on_armed_state_changed(true, false)
	p.on_armed_state_changed(false, false)
	assert_eq(p._buttons[2].modulate, base, "modulate volta ao base após disarm")

func test_armed_brighten_respects_neutral_at_cue_3():
	# Em cue 3 a cor base é NEUTRAL_BUTTON; armed multiplica em cima.
	CueSettings.set_level(0)
	var p = _make()
	CueSettings.set_level(3)
	p.on_armed_state_changed(true, false)
	var expected = Color(p.NEUTRAL_BUTTON.r * p.ARMED_BRIGHTNESS,
		p.NEUTRAL_BUTTON.g * p.ARMED_BRIGHTNESS,
		p.NEUTRAL_BUTTON.b * p.ARMED_BRIGHTNESS, p.NEUTRAL_BUTTON.a)
	assert_eq(p._buttons[2].modulate, expected)
