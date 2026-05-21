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
	# Ds4 dir agora é (1,0) no novo mapeamento; (5,5) + (1,0) = (6,5).
	assert_eq(p._conductor.phase, p._conductor.Phase.IDLE)
	p._on_note_triggered("Ds4")  # dir (1,0) a partir de (5,5)
	assert_eq(p._character.grid_position, Vector2i(6, 5))

func test_free_roam_wall_collision_trips():
	var p = _playground()
	# F4 dir agora é (0,1) no novo mapeamento; (4,6) + (0,1) = (4,7) é parede.
	p._character.grid_position = Vector2i(4, 6)
	p._on_note_triggered("F4")  # dir (0,1) -> (4,7) é parede
	assert_eq(p._character.grid_position, Vector2i(4, 6))
	assert_eq(p._character.state, p._character.State.TRIP)

func test_input_ignored_during_preview():
	var p = _playground()
	p._begin_preset("curto", 0)
	var before = p._character.grid_position
	p._on_note_triggered("D4")
	assert_eq(p._character.grid_position, before)
	assert_eq(p._conductor._index, 0)
	CueSettings.set_level(0)

func test_hit_moves_character_along_path():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()  # PREVIEW -> CALL
	assert_eq(p._conductor.phase, p._conductor.Phase.CALL)
	p._on_note_triggered("D4")  # 1ª nota do preset "curto"
	assert_eq(p._character.grid_position, Vector2i(6, 4))
	CueSettings.set_level(0)

func test_miss_trips_character_in_place():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	var before = p._character.grid_position
	p._on_note_triggered("C4")  # errado (alvo D4)
	assert_eq(p._character.grid_position, before)
	assert_eq(p._character.state, p._character.State.TRIP)
	assert_eq(p._conductor._index, 0)
	CueSettings.set_level(0)

func test_full_run_replays_path_and_shows_stats():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	for n in ["D4", "D4", "F4", "F4"]:
		p._on_note_triggered(n)
	assert_eq(p._conductor.phase, p._conductor.Phase.REPLAY)
	assert_eq(p._character.grid_position, Vector2i(5, 5))
	for i in range(5):
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
	p._on_note_triggered("D4")  # char sai de (5,5) -> (6,4)
	p._on_restart_requested()
	assert_eq(p._character.grid_position, Vector2i(5, 5))
	assert_eq(p._conductor.phase, p._conductor.Phase.PREVIEW)
	assert_false(p._hud._stats_panel.visible)
	CueSettings.set_level(0)

func test_input_ignored_during_replay():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(5):
		p._conductor._advance()
	for n in ["D4", "D4", "F4", "F4"]:
		p._on_note_triggered(n)
	assert_eq(p._conductor.phase, p._conductor.Phase.REPLAY)
	var before = p._character.grid_position
	p._on_note_triggered("D4")  # deve ser ignorado silenciosamente
	assert_eq(p._character.grid_position, before)
	CueSettings.set_level(0)

func test_special_action_panel_present_in_scene():
	var p = _playground()
	var panel = p.get_node_or_null("UI/SpecialActionPanel")
	assert_not_null(panel, "SpecialActionPanel instanciado em UI")

func test_free_roam_action_note_triggers_character_action():
	var p = _playground()
	# IDLE (sem _begin_preset): toque numa nota de ação dispara action_performed
	# A4 = pegar no novo mapeamento.
	assert_eq(p._conductor.phase, p._conductor.Phase.IDLE)
	watch_signals(p._character)
	p._on_note_triggered("A4")
	# Valores literais (não ler do objeto após o emit) — fixa o contrato:
	# personagem em (5,5) default, last_direction default (0,1), ação=pegar.
	assert_signal_emitted_with_parameters(p._character, "action_performed",
		["pegar", Vector2i(5, 5), Vector2i(0, 1)])
	assert_eq(p._character.grid_position, Vector2i(5, 5))

func test_call_with_action_note_advances_conductor():
	# Vamos forçar um preset só com A4 (pegar) para testar a integração com o loop.
	var p = _playground()
	var Preset := preload("res://scripts/SequencePreset.gd")
	var preset = Preset.new()
	preset.id = "tact"
	preset.start_grid = Vector2i(5, 5)
	var notes: Array[String] = ["A4"]
	preset.notes = notes
	p._conductor.load_preset(preset)
	p._conductor.start()
	for i in range(2):
		p._conductor._advance()  # PREVIEW (1 emissão) -> CALL
	assert_eq(p._conductor.phase, p._conductor.Phase.CALL)
	var before = p._character.grid_position
	p._on_note_triggered("A4")
	assert_eq(p._conductor._index, 1)
	assert_eq(p._character.grid_position, before)  # ação não move
	CueSettings.set_level(0)

func test_replay_with_action_note_triggers_action_without_moving():
	# REPLAY com uma nota de ação deve chamar handle_action (anim + signal)
	# sem mover o personagem (action notes têm direction=ZERO).
	var p = _playground()
	var Preset := preload("res://scripts/SequencePreset.gd")
	var preset = Preset.new()
	preset.id = "trep"
	preset.start_grid = Vector2i(5, 5)
	var notes: Array[String] = ["A4"]
	preset.notes = notes
	p._conductor.load_preset(preset)
	p._conductor.start()
	for i in range(2):
		p._conductor._advance()  # PREVIEW -> CALL
	p._on_note_triggered("A4")   # CALL hit -> REPLAY
	assert_eq(p._conductor.phase, p._conductor.Phase.REPLAY)
	var before = p._character.grid_position
	watch_signals(p._character)
	p._on_replay_note("A4", 0)
	assert_signal_emitted_with_parameters(p._character, "action_performed",
		["pegar", before, p._character._last_direction])
	assert_eq(p._character.grid_position, before, "ação não move no REPLAY")
	CueSettings.set_level(0)
