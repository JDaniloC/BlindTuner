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
	var movement_notes = ["C4","Cs4","D4","Ds4","E4","F4","Fs4","G4"]
	for n in movement_notes:
		assert_true(NoteMapping.is_movement_note(n), "%s deveria mover" % n)

func test_is_movement_note_false_for_four():
	var reserved = ["Gs4","A4","As4","B4"]
	for n in reserved:
		assert_false(NoteMapping.is_movement_note(n), "%s deveria ser reservada" % n)

func test_direction_cardinals_align_with_screen():
	# Joystick ↑/→/↓/← devem mover reto na tela após a remapagem isométrica.
	assert_eq(NoteMapping.direction_for("C4"),  Vector2i(-1, -1), "C4 (↑) = cima")
	assert_eq(NoteMapping.direction_for("D4"),  Vector2i( 1, -1), "D4 (→) = direita")
	assert_eq(NoteMapping.direction_for("E4"),  Vector2i( 1,  1), "E4 (↓) = baixo")
	assert_eq(NoteMapping.direction_for("Fs4"), Vector2i(-1,  1), "Fs4 (←) = esquerda")

func test_direction_intercardinals():
	assert_eq(NoteMapping.direction_for("Cs4"), Vector2i( 0, -1))
	assert_eq(NoteMapping.direction_for("Ds4"), Vector2i( 1,  0))
	assert_eq(NoteMapping.direction_for("F4"),  Vector2i( 0,  1))
	assert_eq(NoteMapping.direction_for("G4"),  Vector2i(-1,  0))

func test_direction_for_reserved_returns_zero():
	for n in ["Gs4","A4","As4","B4"]:
		assert_eq(NoteMapping.direction_for(n), Vector2i.ZERO, "%s reservada" % n)

func test_movement_directions_are_eight_unique_neighbors():
	var seen := {}
	for n in ["C4","Cs4","D4","Ds4","E4","F4","Fs4","G4"]:
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

func test_is_action_note_true_for_four():
	for n in ["Gs4","A4","As4","B4"]:
		assert_true(NoteMapping.is_action_note(n), "%s deveria ser ação" % n)

func test_is_action_note_false_for_eight_movement():
	for n in ["C4","Cs4","D4","Ds4","E4","F4","Fs4","G4"]:
		assert_false(NoteMapping.is_action_note(n), "%s não é ação" % n)

func test_action_id_for_returns_expected():
	assert_eq(NoteMapping.action_id_for("Gs4"), "abaixar")
	assert_eq(NoteMapping.action_id_for("A4"),  "pegar")
	assert_eq(NoteMapping.action_id_for("As4"), "correr")
	assert_eq(NoteMapping.action_id_for("B4"),  "pular")

func test_action_id_for_empty_for_movement():
	for n in ["C4","Cs4","D4","Ds4","E4","F4","Fs4","G4"]:
		assert_eq(NoteMapping.action_id_for(n), "", "%s sem action_id" % n)

func test_snap_angle_movement_only_at_30deg_snaps_to_cs4():
	# Layout direcional 8x45°: C4=0°, Cs4=45°. Em 30° a mais próxima é Cs4 (15° away)
	# vs C4 (30° away).
	assert_eq(NoteMapping.snap_angle_to_note(30.0, true), "Cs4")

func test_snap_angle_movement_only_at_120deg_snaps_to_ds4():
	# 120° no layout direcional: D4=90° (30° away), Ds4=135° (15° away). Ds4 vence.
	assert_eq(NoteMapping.snap_angle_to_note(120.0, true), "Ds4")

func test_snap_angle_default_keeps_old_behavior():
	# Sem o filtro, 30° continua sendo Cs4 (layout cromático preservado).
	assert_eq(NoteMapping.snap_angle_to_note(30.0), "Cs4")

func test_snap_angle_movement_only_at_90deg_is_d4():
	# D4 = 90° no layout direcional (cardinal leste no novo mapeamento).
	assert_eq(NoteMapping.snap_angle_to_note(90.0, true), "D4")

func test_snap_angle_movement_only_full_circle_8_cardinals():
	# Layout direcional: 8 notas de movimento em ordem de inserção a 45° cada.
	var expected = ["C4","Cs4","D4","Ds4","E4","F4","Fs4","G4"]
	for i in range(8):
		var note = NoteMapping.snap_angle_to_note(float(i * 45), true)
		assert_eq(note, expected[i], "ângulo %d deveria mapear para %s" % [i*45, expected[i]])

func test_snap_angle_movement_only_exact_midpoint_breaks_to_lower():
	# 22.5° é equidistante entre C4 (0°) e Cs4 (45°). Ordem de inserção: C4 ganha.
	assert_eq(NoteMapping.snap_angle_to_note(22.5, true), "C4")

func test_action_notes_are_contiguous_at_top_of_chromatic():
	var keys = NoteMapping.NOTES.keys()
	for i in range(8):
		assert_true(NoteMapping.is_movement_note(keys[i]),
			"%s (índice %d) deveria ser movement (bloco contíguo na base)" % [keys[i], i])
	for i in range(8, 12):
		assert_true(NoteMapping.is_action_note(keys[i]),
			"%s (índice %d) deveria ser ação (topo)" % [keys[i], i])
