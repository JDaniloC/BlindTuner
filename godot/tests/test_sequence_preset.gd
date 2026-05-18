extends GutTest

const Preset := preload("res://scripts/SequencePreset.gd")

func _make() -> Preset:
	var p := Preset.new()
	p.id = "t"
	p.label = "T"
	p.size_class = "curto"
	p.start_grid = Vector2i(5, 5)
	var n: Array[String] = ["Ds4", "Ds4", "Gs4", "Gs4"]  # (1,-1)(1,-1)(0,1)(0,1)
	p.notes = n
	return p

func test_target_grid_derived_from_notes():
	var p = _make()
	# (5,5)->(6,4)->(7,3)->(7,4)->(7,5)
	assert_eq(p.target_grid(), Vector2i(7, 5))

func test_path_tiles_lists_every_step():
	var p = _make()
	assert_eq(p.path_tiles(), [
		Vector2i(6, 4), Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5)
	])

func test_crosses_any_true_when_path_hits_blocked():
	var p = _make()
	assert_true(p.crosses_any({ Vector2i(7, 3): true }))

func test_crosses_any_false_when_path_clear():
	var p = _make()
	assert_false(p.crosses_any({ Vector2i(0, 0): true }))

func test_empty_notes_target_is_start():
	var p = Preset.new()
	p.start_grid = Vector2i(2, 2)
	p.notes = [] as Array[String]
	assert_eq(p.target_grid(), Vector2i(2, 2))
	assert_eq(p.path_tiles(), [])
