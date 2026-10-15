extends Node
## Autoload — layouts dos 3 cômodos do MVP. Paredes listadas aqui são SÓ as internas;
## Playground._build_room adiciona a borda automaticamente via _border_walls.

const MapPresetRes := preload("res://scripts/MapPreset.gd")

var ALL: Array = []

func _ready() -> void:
    if ALL.is_empty():
        ALL = _build_all()

func _build_all() -> Array:
    return [
        _make("quarto", "Quarto", Vector2i(8, 8),
            _quarto_walls(), Vector2i(1, 6), Vector2i(6, 1), "quarto"),
        _make("banheiro", "Banheiro", Vector2i(10, 10),
            _banheiro_walls(), Vector2i(8, 8), Vector2i(3, 1), "banheiro"),
        _make("sala", "Sala", Vector2i(12, 12),
            _sala_walls(), Vector2i(10, 10), Vector2i(1, 1), "sala"),
        _make("quarto_lullaby", "Quarto (Noite)", Vector2i(10, 10),
            _quarto_lullaby_walls(), Vector2i(2, 2), Vector2i(3, 6), "quarto"),
    ]

# Quarto de dormir no escuro (Lullaby): obstáculos em volta do caminho seguro.
func _quarto_lullaby_walls() -> Array[Vector2i]:
    return [
        Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4),
        Vector2i(2, 3), Vector2i(2, 4),
        Vector2i(5, 4), Vector2i(5, 5),
        Vector2i(2, 5), Vector2i(2, 6),
        Vector2i(3, 5),
        Vector2i(4, 3),
        Vector2i(2, 7), Vector2i(3, 7),
        Vector2i(6, 6), Vector2i(6, 7),
        Vector2i(5, 8),
        Vector2i(3, 8),
    ]

# Cama 2×3 no canto NW + criado-mudo.
func _quarto_walls() -> Array[Vector2i]:
    return [
        Vector2i(1,1), Vector2i(2,1),
        Vector2i(1,2), Vector2i(2,2),
        Vector2i(1,3), Vector2i(2,3),
        Vector2i(3,1), Vector2i(3,2),
    ]

# Pia L (3) + vaso (2) + lixeira (1). Total 6 tiles.
func _banheiro_walls() -> Array[Vector2i]:
    return [
        Vector2i(1,1), Vector2i(2,1), Vector2i(1,2),
        Vector2i(7,1), Vector2i(7,2),
        Vector2i(8,1),
    ]

# Sofá 3 + mesinha 1 + estante 4 + TV 1. Total 9 tiles.
func _sala_walls() -> Array[Vector2i]:
    return [
        Vector2i(3,8), Vector2i(4,8), Vector2i(5,8),
        Vector2i(4,6),
        Vector2i(10,2), Vector2i(10,3), Vector2i(10,4), Vector2i(10,5),
        Vector2i(1,4),
    ]

func _make(p_id: String, p_label: String, p_size: Vector2i,
        p_walls: Array[Vector2i], p_start: Vector2i, p_goal: Vector2i,
        p_theme_id: String) -> Resource:
    var m := MapPresetRes.new()
    m.id = p_id
    m.label = p_label
    m.size = p_size
    m.walls = p_walls
    m.start_grid = p_start
    m.goal_grid = p_goal
    m.theme_id = p_theme_id
    return m

func by_id(p_id: String) -> Resource:
    for m in ALL:
        if m.id == p_id:
            return m
    return null
