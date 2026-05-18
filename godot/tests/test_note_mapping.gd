extends GutTest

func test_snap_angle_to_note_exact_north():
	assert_eq(NoteMapping.snap_angle_to_note(0.0), "C4")

func test_snap_angle_to_note_below_threshold_snaps_down():
	assert_eq(NoteMapping.snap_angle_to_note(14.0), "C4")

func test_snap_angle_to_note_above_threshold_snaps_up():
	assert_eq(NoteMapping.snap_angle_to_note(16.0), "Cs4")

func test_snap_angle_to_note_wraps_360():
	assert_eq(NoteMapping.snap_angle_to_note(360.0), "C4")

func test_snap_angle_to_note_handles_negative():
	assert_eq(NoteMapping.snap_angle_to_note(-10.0), "C4")

func test_snap_angle_to_note_full_circle():
	var expected = ["C4","Cs4","D4","Ds4","E4","F4","Fs4","G4","Gs4","A4","As4","B4"]
	for i in range(12):
		var note = NoteMapping.snap_angle_to_note(float(i * 30))
		assert_eq(note, expected[i], "ângulo %d deveria mapear para %s" % [i*30, expected[i]])

func test_is_movement_note_true_for_eight():
	var movement_notes = ["C4","D4","Ds4","F4","Fs4","Gs4","A4","B4"]
	for n in movement_notes:
		assert_true(NoteMapping.is_movement_note(n), "%s deveria mover" % n)

func test_is_movement_note_false_for_four():
	var reserved = ["Cs4","E4","G4","As4"]
	for n in reserved:
		assert_false(NoteMapping.is_movement_note(n), "%s deveria ser reservada" % n)

func test_direction_cardinals_align_with_screen():
	# Joystick ↑/→/↓/← devem mover reto na tela após a remapagem isométrica.
	assert_eq(NoteMapping.direction_for("C4"),  Vector2i(-1, -1), "C4 (↑) = cima")
	assert_eq(NoteMapping.direction_for("Ds4"), Vector2i( 1, -1), "Ds4 (→) = direita")
	assert_eq(NoteMapping.direction_for("Fs4"), Vector2i( 1,  1), "Fs4 (↓) = baixo")
	assert_eq(NoteMapping.direction_for("A4"),  Vector2i(-1,  1), "A4 (←) = esquerda")

func test_direction_intercardinals():
	assert_eq(NoteMapping.direction_for("D4"),  Vector2i( 0, -1))
	assert_eq(NoteMapping.direction_for("F4"),  Vector2i( 1,  0))
	assert_eq(NoteMapping.direction_for("Gs4"), Vector2i( 0,  1))
	assert_eq(NoteMapping.direction_for("B4"),  Vector2i(-1,  0))

func test_direction_for_reserved_returns_zero():
	for n in ["Cs4","E4","G4","As4"]:
		assert_eq(NoteMapping.direction_for(n), Vector2i.ZERO, "%s reservada" % n)

func test_movement_directions_are_eight_unique_neighbors():
	var seen := {}
	for n in ["C4","D4","Ds4","F4","Fs4","Gs4","A4","B4"]:
		var d = NoteMapping.direction_for(n)
		assert_false(seen.has(d), "direção %s duplicada" % str(d))
		seen[d] = true
	assert_eq(seen.size(), 8)

func test_snap_angle_to_note_exact_midpoint_breaks_to_lower():
	# 15° é equidistante entre C4 (0°) e Cs4 (30°). A iteração do dicionário
	# em GDScript 4 é por ordem de inserção, então C4 ganha o desempate.
	# Este teste documenta esse comportamento como contrato.
	assert_eq(NoteMapping.snap_angle_to_note(15.0), "C4")

func test_frequency_for_a4_is_440():
	assert_eq(NoteMapping.frequency_for("A4"), 440)
