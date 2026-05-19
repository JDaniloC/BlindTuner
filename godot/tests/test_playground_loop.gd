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
	CueSettings.set_level(0)

func test_cue_level_applied_on_begin():
	var p = _playground()
	p._begin_preset("curto", 2)
	assert_eq(CueSettings.cue_level, 2)
	CueSettings.set_level(0)

func test_free_roam_moves_character_in_idle():
	var p = _playground()
	# Sem _begin_preset: conductor em IDLE, joystick anda livre.
	assert_eq(p._conductor.phase, p._conductor.Phase.IDLE)
	p._on_note_triggered("Ds4")  # dir (1,-1) a partir de (5,5)
	assert_eq(p._character.grid_position, Vector2i(6, 4))

func test_free_roam_wall_collision_trips():
	var p = _playground()
	p._character.grid_position = Vector2i(4, 6)
	p._on_note_triggered("Gs4")  # dir (0,1) -> (4,7) é parede
	assert_eq(p._character.grid_position, Vector2i(4, 6))
	assert_eq(p._character.state, p._character.State.TRIP)

func test_input_ignored_during_preview():
	var p = _playground()
	p._begin_preset("curto", 0)  # PREVIEW
	var before = p._character.grid_position
	p._on_note_triggered("Ds4")
	assert_eq(p._character.grid_position, before)
	assert_eq(p._conductor._index, 0)
	CueSettings.set_level(0)

func test_hit_moves_character_along_path():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()  # esgota PREVIEW -> CALL
	assert_eq(p._conductor.phase, p._conductor.Phase.CALL)
	p._on_note_triggered("Ds4")  # 1ª nota; resolve na hora
	assert_eq(p._character.grid_position, Vector2i(6, 4))
	CueSettings.set_level(0)

func test_miss_trips_character_in_place():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	var before = p._character.grid_position
	p._on_note_triggered("C4")  # errado (alvo Ds4)
	assert_eq(p._character.grid_position, before)
	assert_eq(p._character.state, p._character.State.TRIP)
	assert_eq(p._conductor._index, 0)  # miss não avança
	CueSettings.set_level(0)

func test_full_run_replays_path_and_shows_stats():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()  # -> CALL
	for n in ["Ds4", "Ds4", "Gs4", "Gs4"]:
		p._on_note_triggered(n)
	assert_eq(p._conductor.phase, p._conductor.Phase.REPLAY)
	# Ao entrar em REPLAY o personagem volta ao start_grid:
	assert_eq(p._character.grid_position, Vector2i(5, 5))
	for i in range(5):
		p._conductor._advance()  # replay anda o caminho -> DONE
	assert_eq(p._conductor.phase, p._conductor.Phase.DONE)
	assert_true(p._hud._stats_panel.visible)
	assert_eq(p._character.grid_position, Vector2i(7, 5))
	CueSettings.set_level(0)

func test_restart_resets_to_preset_start():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	p._on_note_triggered("Ds4")  # char sai de (5,5) -> (6,4)
	p._on_restart_requested()
	assert_eq(p._character.grid_position, Vector2i(5, 5))
	assert_eq(p._conductor.phase, p._conductor.Phase.PREVIEW)
	assert_false(p._hud._stats_panel.visible)
	CueSettings.set_level(0)

func test_input_ignored_during_replay():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()  # -> CALL
	for n in ["Ds4", "Ds4", "Gs4", "Gs4"]:
		p._on_note_triggered(n)  # -> REPLAY, char volta a (5,5)
	assert_eq(p._conductor.phase, p._conductor.Phase.REPLAY)
	var before = p._character.grid_position
	p._on_note_triggered("Ds4")  # deve ser ignorado silenciosamente
	assert_eq(p._character.grid_position, before)
	CueSettings.set_level(0)
