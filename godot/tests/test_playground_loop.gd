extends GutTest

const PlaygroundScene := preload("res://scenes/Playground.tscn")

func _playground() -> Node:
	var p = PlaygroundScene.instantiate()
	add_child_autofree(p)
	return p

func test_start_positions_character_at_preset_start():
	var p = _playground()
	p._begin_preset("curto", 0)
	assert_eq(p._character.grid_position, Vector2i(5, 5))
	assert_eq(p._conductor.phase, p._conductor.Phase.PREVIEW)

func test_cue_level_applied_on_begin():
	var p = _playground()
	p._begin_preset("curto", 2)
	assert_eq(CueSettings.cue_level, 2)
	CueSettings.set_level(0)

func test_hit_moves_character_along_path():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	assert_eq(p._conductor.phase, p._conductor.Phase.FOLLOW)
	p._conductor.submit_note("Ds4")  # 1ª nota do preset "curto"
	p._conductor._advance()
	assert_eq(p._character.grid_position, Vector2i(6, 4))

func test_miss_trips_character_in_place():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	var before = p._character.grid_position
	p._conductor.submit_note("C4")  # errado (alvo é Ds4)
	p._conductor._advance()
	assert_eq(p._character.grid_position, before)
	assert_eq(p._character.state, p._character.State.TRIP)

func test_full_run_completes_and_shows_stats():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	for n in ["Ds4", "Ds4", "Gs4", "Gs4"]:
		p._conductor.submit_note(n)
		p._conductor._advance()
	assert_eq(p._conductor.phase, p._conductor.Phase.DONE)
	assert_true(p._hud._stats_panel.visible)
	assert_eq(p._character.grid_position, Vector2i(7, 5))
	CueSettings.set_level(0)

func test_restart_resets_to_preset_start():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	p._conductor.submit_note("Ds4")
	p._conductor._advance()  # anda 1 nota (char saiu de (5,5))
	p._on_restart_requested()
	assert_eq(p._character.grid_position, Vector2i(5, 5))
	assert_eq(p._conductor.phase, p._conductor.Phase.PREVIEW)
	assert_false(p._hud._stats_panel.visible)
	CueSettings.set_level(0)
