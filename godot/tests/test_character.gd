extends GutTest

const CharacterScript := preload("res://scripts/Character.gd")

func _make_character() -> Node:
    var c = CharacterScript.new()
    c.grid_position = Vector2i(5, 5)
    c.blocked_tiles = {}
    # add_child_autofree garante que _ready() rode e que create_tween() funcione (precisa estar no SceneTree)
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
