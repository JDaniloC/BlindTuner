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
	# 180° = Fs4 (cardinal sul). Índice da fatia = 4 no layout direcional.
	assert_eq(_make_joystick().slice_index_for_angle(180.0), 4)

func test_slice_index_for_angle_wraps_360():
	assert_eq(_make_joystick().slice_index_for_angle(360.0), 0)

func test_slice_index_for_angle_negative_wraps():
	# -30° = 330°: mais próximo de B4 (315°, 15° away) que C4 (360°, 30° away). B4 = índice 7.
	assert_eq(_make_joystick().slice_index_for_angle(-30.0), 7)

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

func test_vector_to_note_at_30deg_snaps_to_d4():
	# 30° no layout direcional: D4 (45°, 15° away) vence C4 (0°, 30° away).
	var j = _make_joystick()
	var rad := deg_to_rad(30.0)
	var v := Vector2(sin(rad), -cos(rad)) * 50.0
	assert_eq(j.vector_to_note(v), "D4")

func test_vector_to_note_at_120deg_snaps_to_f4():
	# 120° → F4 (135°, 15° away) vence Ds4 (90°, 30° away).
	var j = _make_joystick()
	var rad := deg_to_rad(120.0)
	var v := Vector2(sin(rad), -cos(rad)) * 50.0
	assert_eq(j.vector_to_note(v), "F4")

func test_slice_index_for_angle_is_fatia_index_0_to_7():
	# Layout direcional: 8 fatias a 45°. slice_index_for_angle retorna 0..7
	# usando o mesmo snap que vector_to_note (consistência highlight ↔ emit).
	var j = _make_joystick()
	var expected = [0, 1, 2, 3, 4, 5, 6, 7]
	for i in range(8):
		assert_eq(j.slice_index_for_angle(float(i * 45)), expected[i],
			"ângulo %d deveria mapear para fatia %d" % [i*45, expected[i]])

func test_eight_slices_cover_full_circle():
	# Nenhuma das 8 fatias é "gap" — todas representam direções.
	var j = _make_joystick()
	assert_eq(j._slice_polygons.size(), 8)
	for i in range(8):
		assert_true(NoteMapping.is_movement_note(j._slice_note_keys[i]))
