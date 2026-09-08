extends GutTest

const PlaygroundScene := preload("res://scenes/Playground.tscn")

func _playground() -> Node:
	var p = PlaygroundScene.instantiate()
	add_child_autofree(p)
	return p

func test_start_positions_character_at_preset_start():
	var p = _playground()
	p._begin_preset("curto", 0)
	assert_eq(p._character.grid_position, Vector2i(1, 6))
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
	# Ds4 dir agora é (1,0) no novo mapeamento; (1,6) + (1,0) = (2,6).
	assert_eq(p._conductor.phase, p._conductor.Phase.IDLE)
	p._on_note_triggered("Ds4")  # dir (1,0) a partir de (1,6)
	assert_eq(p._character.grid_position, Vector2i(2, 6))

func test_free_roam_wall_collision_trips():
	var p = _playground()
	# F4 dir agora é (0,1) no novo mapeamento; (4,6) + (0,1) = (4,7) é parede.
	p._character.grid_position = Vector2i(4, 6)
	p._on_note_triggered("F4")  # dir (0,1) -> (4,7) é parede
	assert_eq(p._character.grid_position, Vector2i(4, 6))
	assert_eq(p._character.state, p._character.State.TRIP)
	assert_true(p._shake_remaining > 0.0)

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
	for i in range(7):
		p._conductor._advance()  # PREVIEW (6 notas) -> CALL
	assert_eq(p._conductor.phase, p._conductor.Phase.CALL)
	p._on_note_triggered("Cs4")  # 1ª nota do preset "curto"
	assert_eq(p._character.grid_position, Vector2i(1, 5))
	CueSettings.set_level(0)

func test_miss_trips_character_in_place():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(7):
		p._conductor._advance()
	var before = p._character.grid_position
	p._on_note_triggered("C4")  # errado (alvo Cs4)
	assert_eq(p._character.grid_position, before)
	assert_eq(p._character.state, p._character.State.TRIP)
	assert_eq(p._conductor._index, 0)
	assert_eq(p._shake_remaining, 0.0)
	CueSettings.set_level(0)

func test_note_miss_sfx_is_delayed_to_not_mask_wrong_note():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(7):
		p._conductor._advance()
	p._on_note_triggered("C4")  # errado (alvo Cs4) -> NOTE_MISS trip
	assert_eq(p._character.state, p._character.State.TRIP)
	# Imediatamente após o miss (mesmo frame, síncrono), o player ativo ainda deve
	# ser a NOTA ERRADA que o jogador tocou (0.6s) -- não o SFX de erro. Se o SFX
	# tocar sem delay, ele cancela a nota do jogador quase instantaneamente
	# (AudioManager serializa playback a um único player ativo).
	var stream: AudioStreamWAV = AudioManager._current_player.stream
	var duration_sec: float = (stream.data.size() / 2.0) / AudioManager.MIX_RATE
	assert_almost_eq(duration_sec, AudioManager.NOTE_DURATION_SEC, 0.01,
		"o SFX de erro não deveria substituir a nota do jogador imediatamente")
	await get_tree().create_timer(p.COLLISION_SFX_DELAY + 0.1).timeout
	stream = AudioManager._current_player.stream
	duration_sec = (stream.data.size() / 2.0) / AudioManager.MIX_RATE
	assert_almost_eq(duration_sec, AudioManager.NOTE_MISS_DURATION_SEC, 0.01,
		"o SFX de erro deveria tocar depois do delay, como a colisão de parede")
	CueSettings.set_level(0)

func test_full_run_replays_path_and_shows_stats():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(7):
		p._conductor._advance()
	for n in ["Cs4", "D4", "D4", "D4", "Ds4", "D4"]:
		p._on_note_triggered(n)
	assert_eq(p._conductor.phase, p._conductor.Phase.REPLAY)
	assert_eq(p._character.grid_position, Vector2i(1, 6))
	for i in range(7):
		p._conductor._advance()
	assert_eq(p._conductor.phase, p._conductor.Phase.DONE)
	assert_true(p._hud._stats_panel.visible)
	assert_eq(p._character.grid_position, Vector2i(6, 1))
	CueSettings.set_level(0)

func test_restart_resets_to_preset_start():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(7):
		p._conductor._advance()
	p._on_note_triggered("Cs4")  # char sai de (1,6) -> (1,5)
	p._on_restart_requested()
	assert_eq(p._character.grid_position, Vector2i(1, 6))
	assert_eq(p._conductor.phase, p._conductor.Phase.PREVIEW)
	assert_false(p._hud._stats_panel.visible)
	CueSettings.set_level(0)

func test_restart_preserves_active_input_mode():
	# Regressão: restart não deve resetar o modo de input pro default (Joystick)
	# quando o jogador estava jogando em Piano. _on_restart_requested precisa
	# repassar InputModeSettings.mode explicitamente pro _begin_preset.
	var p = _playground()
	p._begin_preset("curto", 0, InputModeSettings.Mode.PIANO)
	for i in range(7):
		p._conductor._advance()
	p._on_note_triggered("Cs4")  # char sai de (1,6) -> (1,5)
	p._on_restart_requested()
	assert_eq(InputModeSettings.mode, InputModeSettings.Mode.PIANO)
	assert_true(p._piano_input.visible)
	InputModeSettings.set_mode(InputModeSettings.Mode.JOYSTICK)

func test_input_ignored_during_replay():
	var p = _playground()
	p._begin_preset("curto", 0)
	for i in range(7):
		p._conductor._advance()
	for n in ["Cs4", "D4", "D4", "D4", "Ds4", "D4"]:
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
	# personagem em (1,6) (quarto start_grid), last_direction default (0,1), ação=pegar.
	assert_signal_emitted_with_parameters(p._character, "action_performed",
		["pegar", Vector2i(1, 6), Vector2i(0, 1)])
	assert_eq(p._character.grid_position, Vector2i(1, 6))

func test_call_with_action_note_advances_conductor():
	# Vamos forçar um preset só com A4 (pegar) para testar a integração com o loop.
	var p = _playground()
	var Preset := preload("res://scripts/SequencePreset.gd")
	var preset = Preset.new()
	preset.id = "tact"
	preset.map_id = "quarto"  # start (1,6), 8×8
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

func test_goal_reached_true_when_character_on_goal():
	var p = _playground()
	p._begin_preset("curto", 0)
	p._character.grid_position = Vector2i(6, 1)  # goal_grid do mapa "quarto"
	assert_true(p._goal_reached())
	CueSettings.set_level(0)

func test_goal_reached_false_when_character_off_goal():
	var p = _playground()
	p._begin_preset("curto", 0)
	p._character.grid_position = Vector2i(0, 0)  # fora do goal
	assert_false(p._goal_reached())
	CueSettings.set_level(0)

func test_replay_with_action_note_triggers_action_without_moving():
	# REPLAY com uma nota de ação deve chamar handle_action (anim + signal)
	# sem mover o personagem (action notes têm direction=ZERO).
	var p = _playground()
	var Preset := preload("res://scripts/SequencePreset.gd")
	var preset = Preset.new()
	preset.id = "trep"
	preset.map_id = "quarto"  # start (1,6), 8×8
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

func test_begin_preset_with_piano_mode_shows_piano_hides_joystick():
	var p = _playground()
	p._begin_preset("curto", 0, InputModeSettings.Mode.PIANO)
	assert_true(p._piano_input.visible)
	assert_false(p._joystick.visible)
	assert_false(p._special_actions.visible)
	InputModeSettings.set_mode(InputModeSettings.Mode.JOYSTICK)

func test_begin_preset_back_to_joystick_hides_piano():
	var p = _playground()
	p._begin_preset("curto", 0, InputModeSettings.Mode.PIANO)
	p._begin_preset("curto", 0, InputModeSettings.Mode.JOYSTICK)
	assert_true(p._joystick.visible)
	assert_true(p._special_actions.visible)
	assert_false(p._piano_input.visible)

func test_piano_input_note_triggered_routes_through_playground():
	var p = _playground()
	# Não chama _begin_preset aqui de propósito: isso poria o Conductor em
	# PREVIEW, e _on_note_triggered só trata movimento em IDLE ou CALL (ver
	# Playground.gd, match _conductor.phase em _on_note_triggered) -- emitir
	# a nota seria ignorado. Ativa o modo direto via InputModeSettings +
	# _apply_input_mode(), mantendo o Conductor em IDLE (mesmo padrão de
	# test_free_roam_moves_character_in_idle, que também não chama _begin_preset).
	InputModeSettings.set_mode(InputModeSettings.Mode.PIANO)
	p._apply_input_mode()
	p._piano_input.note_triggered.emit("Ds4")  # dir (1,0) a partir de (1,6)
	assert_eq(p._character.grid_position, Vector2i(2, 6))
	InputModeSettings.set_mode(InputModeSettings.Mode.JOYSTICK)

func test_begin_preset_with_blind_touch_mode_shows_it_hides_joystick():
	var p = _playground()
	p._begin_preset("curto", 0, InputModeSettings.Mode.BLIND_TOUCH)
	assert_true(p._blind_touch_input.visible)
	assert_false(p._joystick.visible)
	assert_false(p._special_actions.visible)
	assert_false(p._piano_input.visible)
	InputModeSettings.set_mode(InputModeSettings.Mode.JOYSTICK)

func test_blind_touch_input_note_triggered_routes_through_playground():
	var p = _playground()
	# Sem _begin_preset (mesmo motivo documentado em
	# test_piano_input_note_triggered_routes_through_playground): fica em
	# IDLE de propósito.
	InputModeSettings.set_mode(InputModeSettings.Mode.BLIND_TOUCH)
	p._apply_input_mode()
	p._blind_touch_input.note_triggered.emit("Ds4")  # dir (1,0) a partir de (1,6)
	assert_eq(p._character.grid_position, Vector2i(2, 6))
	InputModeSettings.set_mode(InputModeSettings.Mode.JOYSTICK)

func test_begin_preset_with_pitch_scroll_mode_shows_it_hides_others():
	var p = _playground()
	p._begin_preset("curto", 0, InputModeSettings.Mode.PITCH_SCROLL)
	assert_true(p._pitch_scroll_input.visible)
	assert_false(p._joystick.visible)
	assert_false(p._special_actions.visible)
	assert_false(p._piano_input.visible)
	assert_false(p._blind_touch_input.visible)
	InputModeSettings.set_mode(InputModeSettings.Mode.JOYSTICK)

func test_pitch_scroll_input_note_triggered_routes_through_playground():
	var p = _playground()
	# Sem _begin_preset (mesmo motivo documentado em
	# test_piano_input_note_triggered_routes_through_playground): fica em
	# IDLE de propósito.
	InputModeSettings.set_mode(InputModeSettings.Mode.PITCH_SCROLL)
	p._apply_input_mode()
	p._pitch_scroll_input.note_triggered.emit("Ds4")  # dir (1,0) a partir de (1,6)
	assert_eq(p._character.grid_position, Vector2i(2, 6))
	InputModeSettings.set_mode(InputModeSettings.Mode.JOYSTICK)
