extends GutTest

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

func test_every_preset_has_resolvable_map():
	for p in SequencePresets.ALL:
		assert_not_null(MapPresets.by_id(p.map_id),
			"preset %s referencia map_id %s inexistente" % [p.id, p.map_id])

func test_by_id_returns_preset_or_null():
	assert_eq(SequencePresets.by_id("medio").id, "medio")
	assert_null(SequencePresets.by_id("inexistente"))
