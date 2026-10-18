extends GutTest

const PlaygroundScene := preload("res://scenes/Playground.tscn")

func test_level_1_3_exists_in_catalog():
	var lvl = LevelCatalog.by_id("ch1_banheiro_cautela")
	assert_not_null(lvl, "Nível 1.3 deve existir no catálogo")
	assert_eq(lvl.chapter, 1)
	assert_eq(lvl.level_number, 3)
	assert_eq(lvl.map_id, "banheiro")
	assert_eq(lvl.beacon_sound_id, "drip")
	assert_eq(lvl.vision_blur, 0.0, "Nível 1.3 não deve usar borrão artificial")
	assert_gt(lvl.vision_desaturation, 0.5, "Nível 1.3 deve ter desaturação cromática avançada")
	assert_lt(lvl.vision_vignette, 0.8)
	assert_false(lvl.show_visual_cues, "Nível 1.3 não deve ter pistas visuais do mundo")
	assert_false(lvl.show_obstacle_outlines, "Nível 1.3 não deve ter contornos neon na bengala")
	assert_false(lvl.beacon_hint.is_empty())

func test_level_1_3_path_reaches_goal_without_collision():
	var lvl = LevelCatalog.by_id("ch1_banheiro_cautela")
	var map = MapPresets.by_id(lvl.map_id)
	assert_not_null(map)
	var pos: Vector2i = map.start_grid
	assert_eq(pos, Vector2i(8, 8))

	var wall_dict := {}
	for w in map.walls:
		wall_dict[w] = true

	for note in lvl.notes:
		var dir := NoteMapping.direction_for(note)
		pos += dir
		assert_false(wall_dict.has(pos), "Caminho não pode colidir com parede em %s (nota %s)" % [pos, note])
		assert_true(pos.x > 0 and pos.x < map.size.x - 1, "Posição %s dentro da borda X" % pos)
		assert_true(pos.y > 0 and pos.y < map.size.y - 1, "Posição %s dentro da borda Y" % pos)

	assert_eq(pos, map.goal_grid, "Caminho melódico deve terminar exatamente no objetivo (pia)")

func test_level_1_4_exists_in_catalog():
	var lvl = LevelCatalog.by_id("ch1_sala_poltrona")
	assert_not_null(lvl, "Nível 1.4 deve existir no catálogo")
	assert_eq(lvl.chapter, 1)
	assert_eq(lvl.level_number, 4)
	assert_eq(lvl.map_id, "sala")
	assert_eq(lvl.beacon_sound_id, "clock")
	assert_gt(lvl.vision_blur, 0.0, "Nível 1.4 deve usar desfoque dinâmico de percepção")
	assert_gt(lvl.vision_desaturation, 0.0)
	assert_gte(lvl.vision_vignette, 0.5)
	assert_true(lvl.show_floor, "Nível 1.4 deve manter o chão visível sob desfoque dinâmico")
	assert_eq(lvl.default_cue_level, 3, "Nível 1.4 deve operar na pista 3 (só som)")
	assert_false(lvl.beacon_hint.is_empty())

func test_level_1_4_path_reaches_goal_without_collision():
	var lvl = LevelCatalog.by_id("ch1_sala_poltrona")
	var map = MapPresets.by_id(lvl.map_id)
	assert_not_null(map)
	var pos: Vector2i = map.start_grid
	assert_eq(pos, Vector2i(10, 10))

	var wall_dict := {}
	for w in map.walls:
		wall_dict[w] = true

	for note in lvl.notes:
		var dir := NoteMapping.direction_for(note)
		pos += dir
		assert_false(wall_dict.has(pos), "Caminho não pode colidir com parede em %s (nota %s)" % [pos, note])
		assert_true(pos.x > 0 and pos.x < map.size.x - 1, "Posição %s dentro da borda X" % pos)
		assert_true(pos.y > 0 and pos.y < map.size.y - 1, "Posição %s dentro da borda Y" % pos)

	assert_eq(pos, map.goal_grid, "Caminho melódico deve terminar exatamente no objetivo (relógio de pêndulo)")

func test_playground_loads_banheiro_with_furniture_and_sink():
	var pg = PlaygroundScene.instantiate()
	add_child_autofree(pg)
	pg._begin_preset("ch1_banheiro_cautela", 1, 0, false)
	assert_eq(pg._current_map_id, "banheiro")
	assert_not_null(pg._goal_beacon)
	assert_eq(pg._goal_beacon.beacon_type, "drip")
	
	# Verifica que o nó Goal possui o sprite da pia
	var has_sink := false
	for child in pg._goal_node.get_children():
		if child is Sprite2D and child.texture == pg.SINK_PROP:
			has_sink = true
			break
	assert_true(has_sink, "Pia de cerâmica com torneira deve estar no objetivo do banheiro")

	# Verifica mobílias no Walls e Floor
	var has_toilet := false
	var has_tub := false
	for child in pg._walls_node.get_children():
		if child is Sprite2D and child.texture == pg.TOILET_PROP:
			has_toilet = true
		if child is Sprite2D and child.texture == pg.BATHTUB_PROP:
			has_tub = true
	assert_true(has_toilet, "Vaso sanitário deve ser spawnado nas paredes do banheiro")
	assert_true(has_tub, "Banheira clássica deve ser spawnada nas paredes do banheiro")

	var has_mat := false
	for child in pg._floor_node.get_children():
		if child is Sprite2D and child.texture == pg.BATH_MAT_PROP:
			has_mat = true
			break
	assert_true(has_mat, "Tapete de banheiro deve ser spawnado no piso")
	assert_true(pg._floor_node.visible, "Chão deve estar visível no nível 1.3")
	assert_false(pg._goal_diamond_marker.visible, "Marcador de chão do objetivo deve estar invisível no nível 1.3")

func test_playground_loads_sala_with_furniture_and_clock():
	var pg = PlaygroundScene.instantiate()
	add_child_autofree(pg)
	pg._begin_preset("ch1_sala_poltrona", 3, 1, false)
	assert_eq(pg._current_map_id, "sala")
	assert_not_null(pg._goal_beacon)
	assert_eq(pg._goal_beacon.beacon_type, "clock")

	# Verifica que o nó Goal possui o sprite do relógio de pêndulo
	var has_clock := false
	for child in pg._goal_node.get_children():
		if child is Sprite2D and child.texture == pg.CLOCK_PROP:
			has_clock = true
			break
	assert_true(has_clock, "Relógio de pêndulo deve estar no objetivo da sala")

	# Verifica mobílias na sala
	var has_chair := false
	var has_table := false
	var has_dresser := false
	for child in pg._walls_node.get_children():
		if child is Sprite2D and child.texture == pg.ARMCHAIR_PROP:
			has_chair = true
		if child is Sprite2D and child.texture == pg.COFFEE_TABLE_PROP:
			has_table = true
		if child is Sprite2D and child.texture == pg.DRESSER_PROP:
			has_dresser = true
	assert_true(has_chair, "Poltrona aconchegante deve ser spawnada na sala")
	assert_true(has_table, "Mesa de centro deve ser spawnada na sala")
	assert_true(has_dresser, "Estante/cômoda deve ser spawnada na sala")

	var has_rug := false
	for child in pg._floor_node.get_children():
		if child is Sprite2D and child.texture == pg.RUG_FOLDED_PROP:
			has_rug = true
			break
	assert_true(has_rug, "Tapete dobrado deve ser spawnado no piso da sala")
	assert_true(pg._floor_node.visible, "Visualização do chão deve estar ativa sob desfoque dinâmico no nível 1.4")
	assert_false(pg._goal_diamond_marker.visible, "Marcador de chão do objetivo deve estar invisível no nível 1.4")
