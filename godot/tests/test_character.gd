extends GutTest

const CharacterScene := preload("res://scenes/Character.tscn")

func _make_character() -> Node:
    var c = CharacterScene.instantiate()
    c.grid_position = Vector2i(5, 5)
    c.blocked_tiles = {}
    # add_child_autofree garante que _ready() rode (com AnimatedSprite construído) e que create_tween() funcione
    add_child_autofree(c)
    return c

func test_movement_note_moves_one_tile():
    var c = _make_character()
    c.handle_note("C4")  # Norte → Vector2i(0, -1)
    assert_eq(c.grid_position, Vector2i(5, 4))

func test_reserved_note_does_not_move():
    var c = _make_character()
    c.handle_note("Cs4")
    assert_eq(c.grid_position, Vector2i(5, 5))

func test_blocked_tile_prevents_movement():
    var c = _make_character()
    c.blocked_tiles = { Vector2i(5, 4): true }
    c.handle_note("C4")
    assert_eq(c.grid_position, Vector2i(5, 5))

func test_diagonal_movement():
    var c = _make_character()
    c.handle_note("D4")  # NE → Vector2i(1, -1)
    assert_eq(c.grid_position, Vector2i(6, 4))

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
    c.blocked_tiles = { Vector2i(5, 4): true }
    c.handle_note("C4")
    assert_eq(c.state, c.State.TRIP)

func test_input_ignored_during_trip():
    var c = _make_character()
    c.blocked_tiles = { Vector2i(5, 4): true }
    c.handle_note("C4")  # trip
    var pos_after_trip = c.grid_position
    c.handle_note("D4")  # tenta NE, deveria ser ignorado
    assert_eq(c.grid_position, pos_after_trip)

func test_run_triggered_by_double_tap_same_note():
    var c = _make_character()
    c.handle_note("C4")
    c._last_note_time_ms = Time.get_ticks_msec()  # garantir janela
    c.handle_note("C4")
    assert_eq(c.state, c.State.RUN)

func test_run_moves_two_tiles_when_path_clear():
    var c = _make_character()
    c.handle_note("C4")
    var pos_after_walk = c.grid_position
    c._last_note_time_ms = Time.get_ticks_msec()
    c.handle_note("C4")
    assert_eq(c.grid_position, pos_after_walk + Vector2i(0, -2))

func test_run_blocked_at_second_tile_moves_one():
    var c = _make_character()
    c.blocked_tiles = { Vector2i(5, 3): true }  # 2 acima do start (5,5) -> (5,4) -> bloqueado
    c.handle_note("C4")
    var pos_after_walk = c.grid_position  # (5, 4)
    c._last_note_time_ms = Time.get_ticks_msec()
    c.handle_note("C4")
    assert_eq(c.grid_position, pos_after_walk)  # nao avancou

func test_run_blocked_at_first_tile_trips():
    var c = _make_character()
    c.grid_position = Vector2i(5, 5)
    c.blocked_tiles = { Vector2i(5, 4): true }
    c.handle_note("C4")  # tenta walk, vira trip
    c._last_note_time_ms = Time.get_ticks_msec()
    c.handle_note("C4")  # ignorado por estar em trip
    assert_eq(c.state, c.State.TRIP)

func test_trip_state_resets_after_window():
    var c = _make_character()
    c.blocked_tiles = { Vector2i(5, 4): true }
    c.handle_note("C4")  # trip enters
    assert_eq(c.state, c.State.TRIP)
    # Aguarda TRIP_DURATION_SEC + margem
    await get_tree().create_timer(c.TRIP_DURATION_SEC + 0.1).timeout
    assert_eq(c.state, c.State.IDLE)

func test_last_direction_persists_after_idle():
    var c = _make_character()
    c.handle_note("D4")  # NE → Vector2i(1, -1)
    # tween termina rápido (0.18s), depois volta a IDLE
    await get_tree().create_timer(c.MOVE_DURATION + 0.1).timeout
    assert_eq(c.state, c.State.IDLE)
    assert_eq(c._last_direction, Vector2i(1, -1))
