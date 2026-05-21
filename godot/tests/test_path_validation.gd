extends GutTest

# Invariante crítica: para cada preset, simular as notas a partir do start do
# seu mapa garante que (a) nenhuma nota cruza parede/borda, e (b) o endpoint
# bate exatamente em map.goal_grid. Qualquer desync música ↔ mapa quebra aqui.
func test_each_preset_path_ends_on_its_map_goal():
	for preset in SequencePresets.ALL:
		var map = MapPresets.by_id(preset.map_id)
		assert_not_null(map, "preset %s sem mapa" % preset.id)
		var pos: Vector2i = map.start_grid
		var walls_set := {}
		for w in map.walls:
			walls_set[w] = true
		for note in preset.notes:
			if not NoteMapping.is_movement_note(note):
				continue
			var dir: Vector2i = NoteMapping.direction_for(note)
			var next: Vector2i = pos + dir
			assert_false(walls_set.has(next),
				"preset %s passa por parede em %s" % [preset.id, next])
			assert_true(next.x > 0 and next.x < map.size.x - 1
					and next.y > 0 and next.y < map.size.y - 1,
				"preset %s sai do interior em %s (size=%s)" % [preset.id, next, map.size])
			pos = next
		assert_eq(pos, map.goal_grid,
			"preset %s termina em %s mas goal é %s" % [preset.id, pos, map.goal_grid])
