extends GutTest
## Testes de validação do Capítulo 3: As Últimas Paisagens (Clímax Narrativo)
## Valida cegueira plena (sem chão, sem pistas visuais, só som), violoncelo solo,
## faróis sonoros do epílogo e progressão de desbloqueio da história.

func test_chapter_3_metadata():
	var ch3 = LevelCatalog.get_chapter_info(3)
	assert_eq(ch3.get("status"), "available", "Capítulo 3 deve estar disponível")
	assert_true(str(ch3.get("title")).contains("As Últimas Paisagens"))
	assert_false(str(ch3.get("subtitle", "")).is_empty())

func test_chapter_3_level_count_and_ids():
	var ch3_levels = LevelCatalog.by_chapter(3)
	assert_eq(ch3_levels.size(), 4, "Capítulo 3 deve conter 4 fases (3.1 a 3.4)")
	
	var expected_ids := [
		"ch3_praia_mare",
		"ch3_estacao_neblina",
		"ch3_estudio_violoncelo",
		"ch3_teatro_recital"
	]
	for i in range(expected_ids.size()):
		assert_eq(ch3_levels[i].id, expected_ids[i])

func test_chapter_3_blindness_and_cello_invariants():
	var ch3_levels = LevelCatalog.by_chapter(3)
	for lvl in ch3_levels:
		assert_eq(lvl.instrument, "cello", "Fase %s deve utilizar violoncelo solo" % lvl.id)
		assert_true(lvl.show_floor, "Fase %s deve ter o chão visível sob desfoque dinâmico" % lvl.id)
		assert_eq(lvl.default_cue_level, 3, "Fase %s deve estar no nível de pista 3 (só som)" % lvl.id)
		assert_gt(lvl.vision_blur, 0.0, "Fase %s deve usar desfoque dinâmico que ganha nitidez com movimento" % lvl.id)

func test_chapter_3_songs_and_composers():
	var l3_1 = LevelCatalog.by_id("ch3_praia_mare")
	assert_eq(l3_1.song_title, "Prélude da Suíte para Cello nº 1 (BWV 1007)")
	assert_true(l3_1.composer.contains("J.S. Bach"))
	assert_eq(l3_1.beacon_sound_id, "ocean_waves")
	
	var l3_2 = LevelCatalog.by_id("ch3_estacao_neblina")
	assert_eq(l3_2.song_title, "O Cisne (Le Cygne)")
	assert_true(l3_2.composer.contains("Saint-Saëns"))
	assert_eq(l3_2.beacon_sound_id, "train_whistle")
	
	var l3_3 = LevelCatalog.by_id("ch3_estudio_violoncelo")
	assert_eq(l3_3.song_title, "Élégie, Op. 24")
	assert_true(l3_3.composer.contains("Fauré"))
	assert_eq(l3_3.beacon_sound_id, "cello_drone")
	
	var l3_4 = LevelCatalog.by_id("ch3_teatro_recital")
	assert_eq(l3_4.song_title, "Largo da Sinfonia do Novo Mundo (Going Home)")
	assert_true(l3_4.composer.contains("Dvořák"))
	assert_eq(l3_4.beacon_sound_id, "wind_chimes")

func test_chapter_3_beacon_audio_streams():
	var beacons := ["ocean_waves", "train_whistle", "cello_drone", "wind_chimes"]
	for b in beacons:
		var stream = AudioManager.get_beacon_stream(b)
		assert_not_null(stream, "Stream para farol %s não deve ser nulo" % b)
		assert_true(stream is AudioStreamWAV)
		assert_eq(stream.mix_rate, 44100)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
		assert_gt(stream.data.size(), 0)

func test_chapter_3_mobs():
	var l3_3 = LevelCatalog.by_id("ch3_estudio_violoncelo")
	assert_eq(l3_3.mobs_data.size(), 1, "Fase 3.3 deve conter o gato Mimi no estúdio")
	assert_eq(l3_3.mobs_data[0].get("type"), "cat")
	assert_eq(l3_3.mobs_data[0].get("grid"), Vector2i(7, 3))

func test_story_campaign_progression_chain():
	# 1.4 -> 2.1
	var next_from_1_4 = LevelCatalog.get_next_level("ch1_sala_poltrona")
	assert_not_null(next_from_1_4)
	assert_eq(next_from_1_4.id, "ch2_portao_ferro")
	
	# 2.4 -> 3.1 (Transição para o Capítulo 3)
	var next_from_2_4 = LevelCatalog.get_next_level("ch2_igreja_carrilhao")
	assert_not_null(next_from_2_4)
	assert_eq(next_from_2_4.id, "ch3_praia_mare", "Concluir 2.4 deve conduzir ao início do Capítulo 3 (3.1)")
	
	# 3.1 -> 3.2
	var next_from_3_1 = LevelCatalog.get_next_level("ch3_praia_mare")
	assert_not_null(next_from_3_1)
	assert_eq(next_from_3_1.id, "ch3_estacao_neblina")
	
	# 3.2 -> 3.3
	var next_from_3_2 = LevelCatalog.get_next_level("ch3_estacao_neblina")
	assert_not_null(next_from_3_2)
	assert_eq(next_from_3_2.id, "ch3_estudio_violoncelo")
	
	# 3.3 -> 3.4
	var next_from_3_3 = LevelCatalog.get_next_level("ch3_estudio_violoncelo")
	assert_not_null(next_from_3_3)
	assert_eq(next_from_3_3.id, "ch3_teatro_recital")
