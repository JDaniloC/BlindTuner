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
