extends GutTest

# Espelha Playground.gd _build_room (perímetro 10x10 + obstáculos internos).
# Duplicado de propósito: ainda não há fonte única; o teste pega drift se Playground mudar.
func _playground_walls() -> Dictionary:
	var w := {}
	for x in range(10):
		w[Vector2i(x, 0)] = true
		w[Vector2i(x, 9)] = true
	for y in range(10):
		w[Vector2i(0, y)] = true
		w[Vector2i(9, y)] = true
	w[Vector2i(3, 4)] = true
	w[Vector2i(7, 6)] = true
	w[Vector2i(4, 7)] = true
	return w

func test_has_three_presets():
	assert_eq(SequencePresets.ALL.size(), 3)

func test_ids_unique_and_known():
	var ids := []
	for p in SequencePresets.ALL:
		ids.append(p.id)
	assert_eq(ids, ["curto", "medio", "longo"])

func test_only_movement_notes():
	for p in SequencePresets.ALL:
		for n in p.notes:
			assert_true(NoteMapping.is_movement_note(n),
				"%s no preset %s não é nota de movimento" % [n, p.id])

func test_no_preset_crosses_playground_walls():
	var walls := _playground_walls()
	for p in SequencePresets.ALL:
		assert_false(p.crosses_any(walls),
			"preset %s cruza parede do Playground" % p.id)

func test_targets_are_inside_room():
	for p in SequencePresets.ALL:
		var t = p.target_grid()
		assert_true(t.x >= 1 and t.x <= 8 and t.y >= 1 and t.y <= 8,
			"alvo de %s fora da sala: %s" % [p.id, str(t)])

func test_by_id_returns_preset_or_null():
	assert_eq(SequencePresets.by_id("medio").id, "medio")
	assert_null(SequencePresets.by_id("inexistente"))
