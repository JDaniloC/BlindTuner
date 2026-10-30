extends GutTest
## Testes de validação das melodias autênticas e do sistema de ritmo nos Cadernos Suzuki Vol. 1 e 2.
## Valida notas musicais do repertório, BPM, durações, pausas na repetição e integridade de caminho.

const ConductorScript := preload("res://scripts/Conductor.gd")

func test_suzuki_vol1_melodies_and_rhythm():
	var s1_1 = LevelCatalog.by_id("arcade_suzuki_1_1")
	assert_not_null(s1_1)
	assert_eq(s1_1.notes, ["A4", "A4", "E4", "E4", "Fs4", "Fs4", "E4", "D4", "D4", "Cs4", "Cs4", "B4", "B4", "A4"], "Brilha Estrelinha: tema A A E E | F# F# E | D D C# C# | B B A")
	assert_eq(s1_1.bpm, 100.0)
	assert_eq(s1_1.note_durations.size(), s1_1.notes.size())
	assert_eq(s1_1.note_rests.size(), s1_1.notes.size())
	assert_eq(s1_1.note_durations[0], 1.0, "Primeira nota deve ser semínima")
	assert_eq(s1_1.note_durations[6], 2.0, "E4 do fim da semifrase é mínima")
	assert_eq(s1_1.note_durations[13], 2.0, "Nota final da frase deve ser mínima")
	assert_eq(s1_1.note_rests[13], 1.0, "Pausa musical no fim da frase")

	var s1_2 = LevelCatalog.by_id("arcade_suzuki_1_2")
	assert_not_null(s1_2)
	assert_eq(s1_2.notes, ["E4", "Cs4", "Cs4", "D4", "B4", "B4", "A4", "B4", "Cs4", "D4", "E4", "E4", "E4"], "Remando Suavemente (Lightly Row)")
	assert_eq(s1_2.bpm, 104.0)
	assert_eq(s1_2.note_durations[2], 2.0, "Mínima no fim do compasso 1")
	assert_eq(s1_2.note_durations[12], 2.0, "Mínima de repouso no fim do compasso 4")

	var s1_3 = LevelCatalog.by_id("arcade_suzuki_1_3")
	assert_not_null(s1_3)
	assert_eq(s1_3.notes, ["A4", "B4", "Cs4", "D4", "E4", "E4", "E4", "E4", "Fs4", "D4", "A4", "Fs4", "E4"], "Canção do Vento (Song of the Wind)")
	assert_eq(s1_3.bpm, 104.0)
	assert_eq(s1_3.note_durations[0], 0.5, "Primeira nota deve ser colcheia")
	assert_eq(s1_3.note_durations[12], 1.0, "Nota final da frase deve ser semínima")
	assert_eq(s1_3.note_rests[12], 1.0, "Deve haver pausa musical de repouso no fim da frase")

	var s1_4 = LevelCatalog.by_id("arcade_suzuki_1_4")
	assert_not_null(s1_4)
	assert_true(s1_4.song_title.contains("Tia Rhody"))
	assert_eq(s1_4.bpm, 96.0)
	assert_eq(s1_4.note_durations[0], 1.0)
	assert_eq(s1_4.note_durations[1], 0.5)

	var s1_13 = LevelCatalog.by_id("arcade_suzuki_1_13")
	assert_not_null(s1_13)
	assert_eq(s1_13.notes, ["D4", "G4", "A4", "B4", "C4", "D4", "E4", "D4", "C4", "B4", "A4", "G4"], "Minueto nº 1 (Bach / Petzold)")
	assert_eq(s1_13.bpm, 112.0)
	assert_eq(s1_13.note_durations[0], 1.0, "Primeira nota do minueto é semínima")

	var s1_16 = LevelCatalog.by_id("arcade_suzuki_1_16")
	assert_not_null(s1_16)
	assert_eq(s1_16.notes, ["D4", "G4", "B4", "D4", "C4", "A4", "C4", "A4", "B4", "G4"], "O Fazendeiro Alegre (Schumann)")
	assert_eq(s1_16.bpm, 104.0)
	assert_eq(s1_16.note_durations[0], 0.5, "Anacruse de colcheia")
	assert_eq(s1_16.note_durations[1], 1.5, "G4 semínima pontuada")

	var s1_17 = LevelCatalog.by_id("arcade_suzuki_1_17")
	assert_not_null(s1_17)
	assert_eq(s1_17.notes, ["D4", "E4", "D4", "Cs4", "D4", "B4", "Cs4", "A4", "D4", "Fs4", "D4"], "Gavotte Gossec: anacruse e tema")
	assert_eq(s1_17.bpm, 108.0)
	assert_eq(s1_17.note_durations[8], 1.0, "D4 longo da cadência da gavotta")
	assert_eq(s1_17.note_rests[10], 1.0, "Pausa final no fim do compasso da gavotta")

func test_suzuki_vol2_melodies_and_rhythm():
	var s2_1 = LevelCatalog.by_id("arcade_suzuki_2_1")
	assert_not_null(s2_1)
	assert_eq(s2_1.notes, ["D4", "E4", "Fs4", "G4", "Fs4", "E4", "D4"], "Coro dos Caçadores (Weber)")
	assert_eq(s2_1.bpm, 116.0)

	var s2_2 = LevelCatalog.by_id("arcade_suzuki_2_2")
	assert_not_null(s2_2)
	assert_eq(s2_2.notes, ["D4", "D4", "E4", "Fs4", "G4", "E4", "D4"], "Valsa de Brahms")
	assert_eq(s2_2.bpm, 120.0)
	assert_eq(s2_2.note_durations[1], 2.0, "Valsa: nota longa no segundo compasso (mínima)")

	var s2_3 = LevelCatalog.by_id("arcade_suzuki_2_3")
	assert_not_null(s2_3)
	assert_eq(s2_3.notes, ["D4", "D4", "E4", "Fs4", "E4", "Cs4", "D4"], "Minueto em Sol Maior (Beethoven)")
	assert_eq(s2_3.bpm, 108.0)

	var s2_4 = LevelCatalog.by_id("arcade_suzuki_2_4")
	assert_not_null(s2_4)
	assert_eq(s2_4.notes, ["D4", "D4", "E4", "Fs4", "G4", "E4", "D4"], "Gavotte (Lully)")
	assert_eq(s2_4.bpm, 108.0)

func test_conductor_applies_level_bpm_and_rhythm():
	var c = ConductorScript.new()
	add_child_autofree(c)
	var s1_3 = LevelCatalog.by_id("arcade_suzuki_1_3")
	c.load_preset(s1_3)
	
	assert_eq(c.bpm, 104.0, "Conductor deve herdar o BPM do nível")
	var expected_beat_sec := 60.0 / 104.0
	assert_almost_eq(c.beat_sec(), expected_beat_sec, 0.001)
	
	# Primeira nota (colcheia: 0.5 batidas)
	var dur_sec_0 := c.get_replay_note_duration_sec(0)
	assert_almost_eq(dur_sec_0, 0.5 * expected_beat_sec, 0.001)
	assert_almost_eq(c.get_replay_note_rest_sec(0), 0.0, 0.001)
	
	# Nota final (semínima: 1.0 batida + repouso: 1.0 batida)
	var last_idx: int = s1_3.notes.size() - 1
	var dur_sec_last := c.get_replay_note_duration_sec(last_idx)
	var rest_sec_last := c.get_replay_note_rest_sec(last_idx)
	assert_almost_eq(dur_sec_last, 1.0 * expected_beat_sec, 0.001)
	assert_almost_eq(rest_sec_last, 1.0 * expected_beat_sec, 0.001)
	assert_almost_eq(c.get_replay_step_sec(last_idx), 2.0 * expected_beat_sec, 0.001)

func test_rest_handling_in_notemapping_and_audio():
	assert_true(NoteMapping.is_rest("REST"))
	assert_true(NoteMapping.is_rest("PAUSE"))
	assert_false(NoteMapping.is_rest("D4"))
	
	assert_eq(NoteMapping.direction_for("REST"), Vector2i.ZERO)
	assert_false(NoteMapping.is_movement_note("REST"))
	assert_false(NoteMapping.is_action_note("REST"))
	assert_eq(NoteMapping.label_for("REST"), "Pausa")
	
	# AudioManager deve produzir silêncio (retornar null) para notas de pausa
	var p = AudioManager.play_note("REST", 0.5)
	assert_null(p, "Pausa não deve instanciar AudioStreamPlayer sonoro")

func test_suzuki_replay_progression_with_rhythm():
	var c = ConductorScript.new()
	add_child_autofree(c)
	var s1_1 = LevelCatalog.by_id("arcade_suzuki_1_1")
	c.load_preset(s1_1)
	
	watch_signals(c)
	# Transiciona para CALL completando PREVIEW
	c.start()
	for i in range(s1_1.notes.size() + 1):
		c._advance()
	assert_eq(c.phase, c.Phase.CALL)
	
	# Completa o CALL submetendo as notas corretas
	for note in s1_1.notes:
		c.submit_note(note)
	
	assert_eq(c.phase, c.Phase.REPLAY)
	
	# Avança pelo REPLAY
	for i in range(s1_1.notes.size()):
		c._advance()
	assert_signal_emit_count(c, "replay_note", s1_1.notes.size())
	
	# Último avanço conclui para DONE
	c._advance()
	assert_eq(c.phase, c.Phase.DONE)
	assert_signal_emitted(c, "sequence_complete")
