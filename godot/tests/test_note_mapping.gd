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

func test_direction_for_north_note():
    assert_eq(NoteMapping.direction_for("C4"), Vector2i(0, -1))

func test_direction_for_reserved_returns_zero():
    assert_eq(NoteMapping.direction_for("Cs4"), Vector2i.ZERO)

func test_snap_angle_to_note_exact_midpoint_breaks_to_lower():
    # 15° é equidistante entre C4 (0°) e Cs4 (30°). A iteração do dicionário
    # em GDScript 4 é por ordem de inserção, então C4 ganha o desempate.
    # Este teste documenta esse comportamento como contrato.
    assert_eq(NoteMapping.snap_angle_to_note(15.0), "C4")

func test_frequency_for_a4_is_440():
    assert_eq(NoteMapping.frequency_for("A4"), 440)
