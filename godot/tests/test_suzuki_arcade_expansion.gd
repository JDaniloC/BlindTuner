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
	var all_arcade_ids: Array[String] = []
	for vol in [1, 2, 3, 4, 5, 6]:
		for lvl_num in [1, 2, 3, 4]:
			all_arcade_ids.append("arcade_suzuki_%d_%d" % [vol, lvl_num])
	
	assert_eq(all_arcade_ids.size(), 24, "Devem existir exatamente 24 fases no Modo Arcade Suzuki")
	
	for lvl_id in all_arcade_ids:
		var lvl = LevelCatalog.by_id(lvl_id)
		assert_not_null(lvl, "Nível %s deve estar no LevelCatalog" % lvl_id)
		assert_gt(lvl.notes.size(), 0, "Nível %s deve possuir notas" % lvl_id)
		assert_false(lvl.song_title.is_empty(), "Nível %s deve ter título musical" % lvl_id)
		assert_false(lvl.composer.is_empty(), "Nível %s deve ter compositor" % lvl_id)
		assert_false(lvl.beacon_sound_id.is_empty(), "Nível %s deve ter farol sonoro" % lvl_id)
		assert_false(lvl.beacon_hint.is_empty(), "Nível %s deve ter dica de farol" % lvl_id)

func test_expanded_arcade_maps_and_paths_valid():
	var all_arcade_ids: Array[String] = []
	for vol in [1, 2, 3, 4, 5, 6]:
		for lvl_num in [1, 2, 3, 4]:
			all_arcade_ids.append("arcade_suzuki_%d_%d" % [vol, lvl_num])
	
	for lvl_id in all_arcade_ids:
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
	var beacons: Array[String] = [
		"bike_bell", "paper_rustle",
		"coffee_grinder", "kettle_whistle", "loom_shuttle",
		"accordion_drone", "castanets_click", "dock_bell",
		"organ_pipe", "tambourine_shake", "cathedral_echo"
	]
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
	for vol in [1, 2, 3, 4, 5, 6]:
		for lvl_num in [1, 2, 3]:
			var current_id := "arcade_suzuki_%d_%d" % [vol, lvl_num]
			var expected_next_id := "arcade_suzuki_%d_%d" % [vol, lvl_num + 1]
			var next_lvl = LevelCatalog.get_next_level(current_id)
			assert_not_null(next_lvl, "Nível seguinte a %s deve existir" % current_id)
			assert_eq(next_lvl.id, expected_next_id, "Nível seguinte a %s deve ser %s" % [current_id, expected_next_id])
