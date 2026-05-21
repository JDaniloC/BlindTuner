extends GutTest

const CharacterScene := preload("res://scenes/Character.tscn")

func _make_character() -> Node:
	var c = CharacterScene.instantiate()
	c.grid_position = Vector2i(5, 5)
	c.blocked_tiles = {}
	add_child_autofree(c)
	return c

func test_movement_note_moves_one_tile():
	var c = _make_character()
	c.handle_note("C4")  # joystick ↑ → grid NW (-1, -1)
	assert_eq(c.grid_position, Vector2i(4, 4))

func test_reserved_note_does_not_move():
	var c = _make_character()
	c.handle_note("A4")
	assert_eq(c.grid_position, Vector2i(5, 5))

func test_blocked_tile_prevents_movement():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }
	c.handle_note("C4")
	assert_eq(c.grid_position, Vector2i(5, 5))

func test_cardinal_north_movement():
	var c = _make_character()
	c.handle_note("Cs4")  # Vector2i(0, -1) no novo mapeamento
	assert_eq(c.grid_position, Vector2i(5, 4))

func test_animation_for_south_uses_native_row():
	var c = _make_character()
	var result = c._animation_for("walk", Vector2i(0, 1))
	assert_eq(result.anim, "walk_s")
	assert_false(result.flip)

func test_animation_for_north_uses_native_row():
	var c = _make_character()
	var result = c._animation_for("walk", Vector2i(0, -1))
	assert_eq(result.anim, "walk_n")
	assert_false(result.flip)

func test_animation_for_southeast_uses_native_row():
	var c = _make_character()
	var result = c._animation_for("walk", Vector2i(1, 1))
	assert_eq(result.anim, "walk_se")
	assert_false(result.flip)

func test_animation_for_southwest_mirrors_southeast():
	var c = _make_character()
	var result = c._animation_for("walk", Vector2i(-1, 1))
	assert_eq(result.anim, "walk_se")
	assert_true(result.flip)

func test_animation_for_west_mirrors_east():
	var c = _make_character()
	var result = c._animation_for("walk", Vector2i(-1, 0))
	assert_eq(result.anim, "walk_e")
	assert_true(result.flip)

func test_animation_for_northwest_mirrors_northeast():
	var c = _make_character()
	var result = c._animation_for("walk", Vector2i(-1, -1))
	assert_eq(result.anim, "walk_ne")
	assert_true(result.flip)

func test_animation_for_idle_state():
	var c = _make_character()
	var result = c._animation_for("idle", Vector2i(0, 1))
	assert_eq(result.anim, "idle_s")

func test_state_starts_as_idle():
	var c = _make_character()
	assert_eq(c.state, c.State.IDLE)

func test_walk_sets_state_to_walk():
	var c = _make_character()
	c.handle_note("C4")
	assert_eq(c.state, c.State.WALK)

func test_blocked_sets_state_to_trip():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }
	c.handle_note("C4")
	assert_eq(c.state, c.State.TRIP)

func test_input_ignored_during_trip():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }
	c.handle_note("C4")  # trip
	var pos_after_trip = c.grid_position
	c.handle_note("D4")  # ignorado
	assert_eq(c.grid_position, pos_after_trip)

func test_run_triggered_by_double_tap_same_note():
	var c = _make_character()
	c.handle_note("C4")
	c._last_note_time_ms = Time.get_ticks_msec()
	c.handle_note("C4")
	assert_eq(c.state, c.State.RUN)

func test_run_moves_one_tile_when_path_clear():
	var c = _make_character()
	c.handle_note("C4")
	var pos_after_walk = c.grid_position  # (4,4)
	c._last_note_time_ms = Time.get_ticks_msec()
	c.handle_note("C4")
	assert_eq(c.grid_position, pos_after_walk + Vector2i(-1, -1))


func test_run_blocked_at_first_tile_trips():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }
	c.handle_note("C4")
	c._last_note_time_ms = Time.get_ticks_msec()
	c.handle_note("C4")
	assert_eq(c.state, c.State.TRIP)

func test_trip_state_resets_after_window():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }
	c.handle_note("C4")
	assert_eq(c.state, c.State.TRIP)
	await get_tree().create_timer(c.TRIP_DURATION_SEC + 0.1).timeout
	assert_eq(c.state, c.State.IDLE)

func test_last_direction_persists_after_idle():
	var c = _make_character()
	c.handle_note("Cs4")  # Vector2i(0, -1) no novo mapeamento
	await get_tree().create_timer(c.MOVE_DURATION + 0.1).timeout
	assert_eq(c.state, c.State.IDLE)
	assert_eq(c._last_direction, Vector2i(0, -1))

func test_handle_action_pegar_emits_action_performed():
	var c = _make_character()
	watch_signals(c)
	c.handle_action("A4")
	assert_signal_emitted_with_parameters(c, "action_performed",
		["pegar", c.grid_position, c._last_direction])

func test_handle_action_interagir_emits():
	var c = _make_character()
	watch_signals(c)
	c.handle_action("Gs4")
	assert_signal_emitted_with_parameters(c, "action_performed",
		["interagir", c.grid_position, c._last_direction])

func test_handle_action_pular_emits():
	var c = _make_character()
	watch_signals(c)
	c.handle_action("B4")
	assert_signal_emitted_with_parameters(c, "action_performed",
		["pular", c.grid_position, c._last_direction])

func test_handle_action_correr_sets_run_next_flag():
	var c = _make_character()
	assert_false(c._run_next)
	c.handle_action("As4")
	assert_true(c._run_next)

func test_handle_action_movement_note_is_noop():
	var c = _make_character()
	watch_signals(c)
	c.handle_action("C4")  # nota de movimento — não é ação
	assert_signal_emit_count(c, "action_performed", 0)

func test_handle_action_ignored_during_trip():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }
	c.handle_note("C4")  # trip
	watch_signals(c)
	c.handle_action("A4")
	assert_signal_emit_count(c, "action_performed", 0)

func test_handle_note_routes_action_notes_to_handle_action():
	# handle_note(A4) deve disparar action_performed=pegar e não mover
	var c = _make_character()
	watch_signals(c)
	c.handle_note("A4")
	assert_signal_emitted_with_parameters(c, "action_performed",
		["pegar", c.grid_position, c._last_direction])
	assert_eq(c.grid_position, Vector2i(5, 5))

func test_run_next_makes_next_walk_become_run():
	var c = _make_character()
	c.handle_action("As4")  # arma o correr
	c.handle_note("C4")     # próximo movimento
	assert_eq(c.state, c.State.RUN)
	assert_eq(c.grid_position, Vector2i(4, 4))  # 1 tile diagonal (era 2)
	assert_false(c._run_next, "flag consumida")

func test_run_next_consumed_only_on_movement():
	# Armar correr e em seguida chamar outra ação NÃO deve consumir a flag
	var c = _make_character()
	c.handle_action("As4")
	c.handle_action("A4")  # pegar não consome
	assert_true(c._run_next, "ação não consome _run_next")

func test_run_next_cleared_on_trip():
	# Cenário: armar correr, depois tropeçar numa parede. Após o trip,
	# _run_next deve estar limpo — tropeçar quebra a corrida armada.
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }
	c.handle_action("As4")
	assert_true(c._run_next, "armado antes do trip")
	c.handle_note("C4")  # bate na parede -> TRIP, deve limpar _run_next
	assert_eq(c.state, c.State.TRIP)
	assert_false(c._run_next, "trip cancela a corrida armada")


func test_pegar_plays_interact_animation():
	var c = _make_character()
	c.handle_action("A4")  # pegar
	assert_true(c._animated_sprite.animation.begins_with("interact"),
		"anim 'interact' após pegar; era %s" % c._animated_sprite.animation)

func test_pegar_returns_to_idle_after_interact_duration():
	var c = _make_character()
	c.handle_action("A4")
	await get_tree().create_timer(c.INTERACT_DURATION_SEC + 0.1).timeout
	if not is_instance_valid(c):
		return
	assert_true(c._animated_sprite.animation.begins_with("idle"),
		"volta a idle; era %s" % c._animated_sprite.animation)

func test_interagir_plays_attack_animation():
	var c = _make_character()
	c.handle_action("Gs4")  # interagir
	assert_true(c._animated_sprite.animation.begins_with("attack"),
		"anim 'attack' após interagir; era %s" % c._animated_sprite.animation)

func test_interagir_returns_to_idle_after_attack_duration():
	var c = _make_character()
	c.handle_action("Gs4")
	await get_tree().create_timer(c.ATTACK_DURATION_SEC + 0.1).timeout
	if not is_instance_valid(c):
		return
	assert_true(c._animated_sprite.animation.begins_with("idle"),
		"volta a idle; era %s" % c._animated_sprite.animation)

func test_correr_armed_plays_run_animation_in_place():
	var c = _make_character()
	var start_pos = c.grid_position
	c.handle_action("As4")  # correr arma
	assert_true(c._run_next, "correr armado")
	assert_true(c._animated_sprite.animation.begins_with("run"),
		"anim 'run' enquanto armado; era %s" % c._animated_sprite.animation)
	assert_eq(c.grid_position, start_pos, "armar não move")

func test_pular_armed_plays_jump_animation_in_place():
	var c = _make_character()
	var start_pos = c.grid_position
	c.handle_action("B4")  # pular arma
	assert_true(c._jump_next, "pular armado")
	assert_true(c._animated_sprite.animation.begins_with("jump"),
		"anim 'jump' enquanto armado; era %s" % c._animated_sprite.animation)
	assert_eq(c.grid_position, start_pos, "armar não move")
	# Confirma que a anim jump está loopando (não congela)
	assert_true(c._animated_sprite.sprite_frames.get_animation_loop(c._animated_sprite.animation),
		"jump anim deveria estar loopando enquanto armado")

func test_jump_consumed_moves_1_tile_with_jump_anim():
	var c = _make_character()
	c.handle_action("B4")  # pular arma
	c.handle_note("C4")    # movimento consome
	assert_eq(c.grid_position, Vector2i(4, 4))  # 1 tile na direção (-1,-1)
	assert_true(c._animated_sprite.animation.begins_with("jump"),
		"anim 'jump' durante o movimento; era %s" % c._animated_sprite.animation)
	assert_false(c._jump_next, "flag consumida")
	assert_false(c._animated_sprite.sprite_frames.get_animation_loop(c._animated_sprite.animation),
		"loop desativado após consumo (para tween_finished voltar ao idle)")

func test_combo_run_plus_jump_moves_2_tiles_with_jump_anim():
	var c = _make_character()
	c.handle_action("As4")  # correr arma
	c.handle_action("B4")   # pular arma — combo!
	assert_true(c._run_next and c._jump_next, "ambas armadas")
	c.handle_note("C4")     # movimento consome combo
	assert_eq(c.grid_position, Vector2i(3, 3))  # 2 tiles na direção (-1,-1)
	# anim ao consumir começa como 'run', troca pra 'jump' no meio via tween_callback.
	# Imediatamente após o consume, anim é 'run' (ainda não passou pelo callback).
	assert_true(c._animated_sprite.animation.begins_with("run"),
		"anim 'run' no início do combo; era %s" % c._animated_sprite.animation)
	assert_false(c._run_next, "run flag consumida")
	assert_false(c._jump_next, "jump flag consumida")

func test_trip_clears_both_armed_flags():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }
	c.handle_action("As4")
	c.handle_action("B4")
	assert_true(c._run_next and c._jump_next)
	c.handle_note("C4")  # bate parede → TRIP
	assert_eq(c.state, c.State.TRIP)
	assert_false(c._run_next, "run flag limpa no trip")
	assert_false(c._jump_next, "jump flag limpa no trip")
	# Trip usa anim 'jump' mas não pode loopar
	assert_false(c._animated_sprite.sprite_frames.get_animation_loop("jump_n"),
		"loop de jump desativado para anim de trip não loopar")

func test_combo_blocked_at_2nd_tile_moves_only_1():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(3, 3): true }  # 2º tile bloqueado
	c.handle_action("As4")
	c.handle_action("B4")
	c.handle_note("C4")
	assert_eq(c.grid_position, Vector2i(4, 4), "move só 1 tile (2º bloqueado)")
	assert_true(c._animated_sprite.animation.begins_with("run"),
		"anim 'run' quando 2º bloqueado (sem trocar pra jump)")

func test_combo_blocked_at_1st_tile_trips():
	var c = _make_character()
	c.blocked_tiles = { Vector2i(4, 4): true }  # 1º tile bloqueado
	c.handle_action("As4")
	c.handle_action("B4")
	c.handle_note("C4")
	assert_eq(c.state, c.State.TRIP)
