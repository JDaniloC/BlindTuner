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
	# A cor da nota vai no bg_color da tecla (fundo), não no modulate (que
	# multiplicaria o texto do label também, matando o contraste) -- ver I1.
	assert_eq(p._buttons[idx].modulate, Color.WHITE)
	var sb = p._buttons[idx].get_theme_stylebox("normal")
	assert_eq(sb.bg_color, NoteMapping.color_for("C4"))

func test_level_three_white_key_shows_authentic_color_no_tint():
	CueSettings.set_level(0)
	var p = _make()
	CueSettings.set_level(3)
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, "")
	assert_eq(p._buttons[idx].modulate, Color.WHITE)
	var sb = p._buttons[idx].get_theme_stylebox("normal")
	assert_eq(sb.bg_color, p.WHITE_KEY_COLOR)

func test_level_three_black_key_shows_authentic_color():
	CueSettings.set_level(0)
	var p = _make()
	CueSettings.set_level(3)
	var idx = p._button_notes.find("Cs4")
	var sb = p._buttons[idx].get_theme_stylebox("normal")
	assert_eq(sb.bg_color, p.BLACK_KEY_COLOR)

func test_on_armed_state_changed_brightens_correr_button():
	# No nível 0, quem clareia com o armed é o bg_color da tecla (não mais o
	# modulate, que agora fica fixo em Color.WHITE -- ver I1).
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("As4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(true, false)
	assert_gt(p._buttons[idx].get_theme_stylebox("normal").bg_color.r, base.r, "armed brighten R")

func test_on_armed_state_changed_brightens_pular_button():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("B4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(false, true)
	assert_gt(p._buttons[idx].get_theme_stylebox("normal").bg_color.r, base.r, "armed brighten R")

func test_disarm_restores_modulate_to_cue_base():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("As4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(true, false)
	p.on_armed_state_changed(false, false)
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, base, "bg_color volta ao base após disarm")

func test_pressed_stylebox_is_darker_than_normal():
	# Apertar uma tecla precisa mudar visualmente algo (feedback de toque) --
	# antes, normal/hover/pressed compartilhavam o MESMO StyleBoxFlat. Ver I3.
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("C4")
	var normal_color = p._buttons[idx].get_theme_stylebox("normal").bg_color
	var pressed_color = p._buttons[idx].get_theme_stylebox("pressed").bg_color
	assert_lt(pressed_color.r, normal_color.r, "pressed deve ser mais escuro que normal (R)")
	assert_lt(pressed_color.g, normal_color.g, "pressed deve ser mais escuro que normal (G)")
	assert_lt(pressed_color.b, normal_color.b, "pressed deve ser mais escuro que normal (B)")

func test_focus_stylebox_override_is_not_set():
	# O indicador de foco (navegação por teclado/acessibilidade) some se a
	# gente sobrescrever "focus" com uma stylebox sem borda -- não sobrescrever
	# deixa o tema padrão do Godot desenhar o indicador. Ver I3.
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_false(p._buttons[idx].has_theme_stylebox_override("focus"),
		"focus não deveria ter override -- deixa o tema padrão desenhar o indicador de foco")

func test_key_positions_match_real_keyboard_layout():
	var p = _make()
	var idx_c4 = p._button_notes.find("C4")
	var idx_d4 = p._button_notes.find("D4")
	var idx_cs4 = p._button_notes.find("Cs4")
	assert_eq(p._buttons[idx_c4].position.x, 0.0)
	assert_eq(p._buttons[idx_d4].position.x, 54.0)
	assert_eq(p._buttons[idx_cs4].position.x, 37.0)

func test_black_keys_drawn_on_top_of_white_keys():
	var p = _make()
	var idx_cs4 = p._button_notes.find("Cs4")
	var black_child_index = p._buttons[idx_cs4].get_index()
	for note in ["C4", "D4"]:
		var white_child_index = p._buttons[p._button_notes.find(note)].get_index()
		assert_gt(black_child_index, white_child_index, "tecla preta deve ser filha posterior (desenhada por cima)")
