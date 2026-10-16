extends GutTest
## Testes de validação da expansão do Modo Arcade (Caderno Suzuki Volumes 3 a 6).
## Valida integridade de dados, caminhos no grid, repertório em domínio público,
## sintetizadores de farol sonoro e desbloqueios.

func test_chapters_101_to_106_metadata_present():
	for ch in [101, 102, 103, 104, 105, 106]:
		var info: Dictionary = LevelCatalog.get_chapter_info(ch)
		assert_not_null(info, "Info do volume %d deve existir" % ch)
		assert_true(info.has("title"), "Volume %d deve conter título" % ch)
		assert_true(info.has("subtitle"), "Volume %d deve conter subtítulo" % ch)
		assert_true(info.has("description"), "Volume %d deve conter descrição" % ch)
		assert_eq(info.get("status"), "available", "Volume %d deve estar disponível" % ch)

func test_all_expanded_arcade_levels_registered():
	var level_ids: Array[String] = [
		"arcade_suzuki_3_1",
		"arcade_suzuki_3_2",
		"arcade_suzuki_4_1",
		"arcade_suzuki_4_2",
		"arcade_suzuki_5_1",
		"arcade_suzuki_6_1"
	]
	
	for lvl_id in level_ids:
		var lvl = LevelCatalog.by_id(lvl_id)
		assert_not_null(lvl, "Nível %s deve estar no LevelCatalog" % lvl_id)
		assert_gt(lvl.notes.size(), 0, "Nível %s deve possuir notas" % lvl_id)
		assert_false(lvl.song_title.is_empty(), "Nível %s deve ter título musical" % lvl_id)
		assert_false(lvl.composer.is_empty(), "Nível %s deve ter compositor" % lvl_id)
		assert_false(lvl.beacon_sound_id.is_empty(), "Nível %s deve ter farol sonoro" % lvl_id)
		assert_false(lvl.beacon_hint.is_empty(), "Nível %s deve ter dica de farol" % lvl_id)

func test_expanded_arcade_maps_and_paths_valid():
	var level_ids: Array[String] = [
		"arcade_suzuki_3_1",
		"arcade_suzuki_3_2",
		"arcade_suzuki_4_1",
		"arcade_suzuki_4_2",
		"arcade_suzuki_5_1",
		"arcade_suzuki_6_1"
	]
	
	for lvl_id in level_ids:
		var lvl = LevelCatalog.by_id(lvl_id)
		assert_not_null(lvl)
		var map = MapPresets.by_id(lvl.map_id)
		assert_not_null(map, "Mapa %s deve existir para o nível %s" % [lvl.map_id, lvl_id])
		
		# Ponto de partida e objetivo não colidem com paredes
		assert_false(map.start_grid in map.walls, "Início não pode ser parede no mapa %s" % map.id)
		assert_false(map.goal_grid in map.walls, "Objetivo não pode ser parede no mapa %s" % map.id)
		
		# Simula a caminhada exata pelas notas
		var current_pos: Vector2i = map.start_grid
		for i in range(lvl.notes.size()):
			var note_key: String = lvl.notes[i]
			var dir: Vector2i = NoteMapping.direction_for(note_key)
			current_pos += dir
			assert_false(current_pos in map.walls, "Passo %d da nota %s colide com parede no mapa %s em %s" % [i, note_key, map.id, current_pos])
		
		assert_eq(current_pos, map.goal_grid, "Caminho de notas do nível %s deve terminar exatamente no objetivo" % lvl_id)

func test_new_procedural_beacons_generate_valid_audio():
	var beacons: Array[String] = ["bike_bell", "paper_rustle"]
	for b in beacons:
		var stream: AudioStreamWAV = AudioManager.get_beacon_stream(b)
		assert_not_null(stream, "Stream para farol '%s' não pode ser nulo" % b)
		assert_gt(stream.data.size(), 0, "Stream para farol '%s' deve ter bytes de áudio" % b)

func test_arcade_initial_levels_unlocked_by_default():
	var entry_levels: Array[String] = [
		"arcade_suzuki_1_1",
		"arcade_suzuki_2_1",
		"arcade_suzuki_3_1",
		"arcade_suzuki_4_1",
		"arcade_suzuki_5_1",
		"arcade_suzuki_6_1"
	]
	for lvl_id in entry_levels:
		assert_true(SaveManager.is_level_unlocked(lvl_id), "Nível de entrada %s deve estar desbloqueado por padrão" % lvl_id)

func test_intra_volume_next_level_progression():
	var next_s3 = LevelCatalog.get_next_level("arcade_suzuki_3_1")
	assert_not_null(next_s3)
	assert_eq(next_s3.id, "arcade_suzuki_3_2")
	
	var next_s4 = LevelCatalog.get_next_level("arcade_suzuki_4_1")
	assert_not_null(next_s4)
	assert_eq(next_s4.id, "arcade_suzuki_4_2")
