extends GutTest

const JoystickScript := preload("res://scripts/DirectionJoystick.gd")

func _make_joystick():
	var j = JoystickScript.new()
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
