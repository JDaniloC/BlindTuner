extends GutTest

const JoystickScene := preload("res://scenes/DirectionJoystick.tscn")

func _make_joystick():
	var j = JoystickScene.instantiate()
	add_child_autofree(j)
	return j

func test_vector_to_note_snaps_to_north():
	# No Godot 2D, Y aponta pra baixo. "Norte" no joystick = thumb pra cima = y negativo.
	var note = _make_joystick().vector_to_note(Vector2(0, -50))
	assert_eq(note, "C4")

func test_vector_to_note_snaps_to_east():
	var note = _make_joystick().vector_to_note(Vector2(50, 0))
	assert_eq(note, "Ds4")

func test_vector_to_note_snaps_to_south():
	var note = _make_joystick().vector_to_note(Vector2(0, 50))
	assert_eq(note, "Fs4")

func test_vector_to_note_snaps_to_west():
	var note = _make_joystick().vector_to_note(Vector2(-50, 0))
	assert_eq(note, "A4")

func test_zero_vector_returns_empty():
	assert_eq(_make_joystick().vector_to_note(Vector2.ZERO), "")

func test_slice_index_for_angle_zero():
	assert_eq(_make_joystick().slice_index_for_angle(0.0), 0)

func test_slice_index_for_angle_30():
	assert_eq(_make_joystick().slice_index_for_angle(30.0), 1)

func test_slice_index_for_angle_180():
	assert_eq(_make_joystick().slice_index_for_angle(180.0), 6)

func test_slice_index_for_angle_wraps_360():
	assert_eq(_make_joystick().slice_index_for_angle(360.0), 0)

func test_slice_index_for_angle_negative_wraps():
	assert_eq(_make_joystick().slice_index_for_angle(-30.0), 11)

func test_slice_color_uses_note_color_when_cue_shows_color():
	CueSettings.set_level(0)
	var j = _make_joystick()
	assert_eq(j.slice_display_color("C4"), NoteMapping.color_for("C4"))
	CueSettings.set_level(0)

func test_slice_color_neutral_at_level_three():
	CueSettings.set_level(3)
	var j = _make_joystick()
	assert_eq(j.slice_display_color("C4"), j.NEUTRAL_SLICE)
	CueSettings.set_level(0)

func test_slices_recolor_on_cue_level_changed():
	CueSettings.set_level(0)
	var j = _make_joystick()
	CueSettings.set_level(3)  # sinal dispara com joystick já vivo
	assert_eq(Color(j._slice_polygons[0].color.r, j._slice_polygons[0].color.g, j._slice_polygons[0].color.b), j.NEUTRAL_SLICE)
	CueSettings.set_level(0)

func test_only_eight_slices_built():
	var j = _make_joystick()
	assert_eq(j._slice_polygons.size(), 8, "4 fatias mortas (ações) saem do círculo")

func test_slice_note_keys_are_movement_only():
	var j = _make_joystick()
	for k in j._slice_note_keys:
		assert_true(NoteMapping.is_movement_note(k), "%s deveria ser movement" % k)
		assert_false(NoteMapping.is_action_note(k), "%s não é ação" % k)

func test_vector_to_note_at_action_angle_snaps_to_movement():
	# Ângulo 30° é Cs4 (ação). Com filtro movement_only, vetor nesse ângulo
	# resolve para a movement note mais próxima (C4 — empate desempatado pela
	# ordem de inserção do dicionário).
	var j = _make_joystick()
	var rad := deg_to_rad(30.0)
	var v := Vector2(sin(rad), -cos(rad)) * 50.0  # mesma convenção do código
	assert_eq(j.vector_to_note(v), "C4")

func test_vector_to_note_at_120_snaps_to_movement():
	var j = _make_joystick()
	var rad := deg_to_rad(120.0)
	var v := Vector2(sin(rad), -cos(rad)) * 50.0
	assert_eq(j.vector_to_note(v), "Ds4")

func test_slice_index_for_angle_unchanged_returns_0_to_11():
	# slice_index_for_angle continua sendo o índice angular bruto (0..11)
	# para preservar a semântica mnemônica; só vector_to_note filtra.
	var j = _make_joystick()
	assert_eq(j.slice_index_for_angle(30.0), 1)  # ainda 1 (posição angular de Cs4)

func test_action_angle_highlights_no_slice():
	# Quando _active_slice_index aponta para uma posição de ação (ex.: 1 = Cs4),
	# nenhuma fatia deve destacar — a invariante de "vão sem highlight".
	var j = _make_joystick()
	j._active_slice_index = 1  # posição angular de Cs4 (ação)
	j._refresh_slice_alphas()
	for poly in j._slice_polygons:
		assert_almost_eq(poly.color.a, 0.35, 0.001, "nenhuma fatia destaca em ângulo de ação")
