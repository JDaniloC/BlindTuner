extends GutTest

const LevelDataScript := preload("res://scripts/LevelData.gd")

func test_level_data_validation():
	var lvl = LevelDataScript.new()
	assert_false(lvl.is_valid(), "novo LevelData vazio deve ser inválido")
	
	lvl.id = "test_lvl"
	lvl.title = "Teste"
	lvl.map_id = "quarto"
	lvl.notes = ["Cs4", "D4"]
	lvl.chapter = 1
	lvl.level_number = 1
	assert_true(lvl.is_valid(), "LevelData preenchido deve ser válido")
	assert_eq(lvl.total_steps(), 2)

func test_catalog_levels_exist_and_are_valid():
	assert_gt(LevelCatalog.ALL.size(), 0)
	for lvl in LevelCatalog.ALL:
		assert_true(lvl.is_valid(), "Nível %s do catálogo deve ser válido" % lvl.id)
		assert_false(lvl.song_title.is_empty(), "Nível %s deve ter música de domínio público definida" % lvl.id)
		assert_false(lvl.composer.is_empty(), "Nível %s deve ter compositor definido" % lvl.id)

func test_catalog_level_ids_are_unique():
	var seen := {}
	for lvl in LevelCatalog.ALL:
		assert_false(seen.has(lvl.id), "ID duplicado no catálogo: %s" % lvl.id)
		seen[lvl.id] = true

func test_catalog_maps_exist():
	for lvl in LevelCatalog.ALL:
		var map = MapPresets.by_id(lvl.map_id)
		assert_not_null(map, "Nível %s referencia mapa inexistente %s" % [lvl.id, lvl.map_id])

func test_catalog_paths_reach_goal_without_collision():
	for lvl in LevelCatalog.ALL:
		var map = MapPresets.by_id(lvl.map_id)
		assert_not_null(map)
		var pos: Vector2i = map.start_grid
		var walls_set := {}
		for w in map.walls:
			walls_set[w] = true
		for note in lvl.notes:
			if not NoteMapping.is_movement_note(note):
				continue
			var dir: Vector2i = NoteMapping.direction_for(note)
			var next: Vector2i = pos + dir
			assert_false(walls_set.has(next), "Nível %s colide com parede em %s" % [lvl.id, next])
			assert_true(next.x > 0 and next.x < map.size.x - 1 and next.y > 0 and next.y < map.size.y - 1,
				"Nível %s sai dos limites em %s" % [lvl.id, next])
			pos = next
		assert_eq(pos, map.goal_grid, "Nível %s deve terminar no goal_grid" % lvl.id)

func test_catalog_query_helpers():
	var first = LevelCatalog.get_first_level()
	assert_not_null(first)
	assert_eq(first.id, "ch1_quarto_radio")
	
	var by_id_lvl = LevelCatalog.by_id("ch1_quarto_radio")
	assert_not_null(by_id_lvl)
	assert_eq(by_id_lvl.title, "O Despertar do Rádio")
	
	var ch1_levels = LevelCatalog.by_chapter(1)
	assert_eq(ch1_levels.size(), 4)
	
	var next = LevelCatalog.get_next_level("ch1_quarto_radio")
	assert_not_null(next)
	assert_eq(next.id, "ch1_lullaby_dormir")
