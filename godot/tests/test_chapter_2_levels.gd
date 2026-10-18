extends GutTest

func test_chapter_2_levels_exist_and_have_metadata():
	var levels = LevelCatalog.by_chapter(2)
	assert_eq(levels.size(), 4, "Capítulo 2 deve ter exatamente 4 fases")
	
	var expected_ids := ["ch2_portao_ferro", "ch2_pao_esquina", "ch2_praca_chafariz", "ch2_igreja_carrilhao"]
	for i in range(4):
		var lvl = levels[i]
		assert_eq(lvl.id, expected_ids[i])
		assert_eq(lvl.chapter, 2)
		assert_eq(lvl.level_number, i + 1)
		assert_false(lvl.title.is_empty())
		assert_false(lvl.song_title.is_empty(), "Fase %s deve ter música clássica definida" % lvl.id)
		assert_false(lvl.composer.is_empty(), "Fase %s deve ter compositor definido" % lvl.id)
		assert_false(lvl.beacon_sound_id.is_empty(), "Fase %s deve ter farol sonoro" % lvl.id)
		assert_false(lvl.beacon_hint.is_empty(), "Fase %s deve ter dica de farol" % lvl.id)

func test_chapter_2_beacons_in_audio_manager():
	var expected_beacons := ["gate_latch", "shop_bell", "fountain_birds", "church_bell"]
	for b in expected_beacons:
		var stream = AudioManager.get_beacon_stream(b)
		assert_not_null(stream, "Farol %s deve ser sintetizado pelo AudioManager" % b)

func test_chapter_2_classical_songs_in_public_domain():
	var lvl_2_1 = LevelCatalog.by_id("ch2_portao_ferro")
	assert_eq(lvl_2_1.song_title, "Musette em Ré Maior (BWV Anh. 126)")
	assert_eq(lvl_2_1.composer, "J.S. Bach (1725)")

	var lvl_2_2 = LevelCatalog.by_id("ch2_pao_esquina")
	assert_eq(lvl_2_2.song_title, "Ah! vous dirai-je, maman (K. 265)")
	assert_eq(lvl_2_2.composer, "W.A. Mozart (1781)")

	var lvl_2_3 = LevelCatalog.by_id("ch2_praca_chafariz")
	assert_eq(lvl_2_3.song_title, "Primavera: Allegro (Op. 8 nº 1)")
	assert_eq(lvl_2_3.composer, "Antonio Vivaldi (1725)")

	var lvl_2_4 = LevelCatalog.by_id("ch2_igreja_carrilhao")
	assert_eq(lvl_2_4.song_title, "See, the Conquering Hero Comes (Judas Macabeu)")
	assert_eq(lvl_2_4.composer, "G.F. Händel (1746)")
	assert_eq(lvl_2_4.instrument, "cello")

func test_chapter_2_visual_scaffolding_progression():
	var lvl_2_1 = LevelCatalog.by_id("ch2_portao_ferro")
	assert_eq(lvl_2_1.default_cue_level, 1, "2.1 deve usar Pista 1 (freq + cor)")
	assert_true(lvl_2_1.show_floor)
	assert_true(lvl_2_1.show_visual_cues)

	var lvl_2_2 = LevelCatalog.by_id("ch2_pao_esquina")
	assert_eq(lvl_2_2.default_cue_level, 2, "2.2 deve usar Pista 2 (só cor)")
	assert_true(lvl_2_2.show_floor)

	var lvl_2_3 = LevelCatalog.by_id("ch2_praca_chafariz")
	assert_eq(lvl_2_3.default_cue_level, 2, "2.3 deve usar Pista 2 (só cor)")
	assert_false(lvl_2_3.show_visual_cues, "2.3 deve retirar pistas visuais de chão")

	var lvl_2_4 = LevelCatalog.by_id("ch2_igreja_carrilhao")
	assert_eq(lvl_2_4.default_cue_level, 3, "2.4 deve usar Pista 3 (só som)")
	assert_true(lvl_2_4.show_floor, "2.4 deve ter chão visível sob desfoque dinâmico")
	assert_false(lvl_2_4.show_visual_cues)
