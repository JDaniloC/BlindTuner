extends Node
## Autoload — paletas dos 3 cômodos do MVP.

const SceneryThemeRes := preload("res://scripts/SceneryTheme.gd")

var ALL: Array = []

func _ready() -> void:
    if ALL.is_empty():
        ALL = _build_all()

func _build_all() -> Array:
    return [
        _make("quarto", "Quarto",
            Color("#8B5A2B"), Color("#7A4F25"),
            Color("#7A6448"), Color("#5A4530"), Color("#2A1F18"),
            Color("#FFD27A")),
        _make("banheiro", "Banheiro",
            Color("#E8E4D8"), Color("#D8D4C8"),
            Color("#C8D0D8"), Color("#AAB4C0"), Color("#5A6470"),
            Color("#66CCFF")),
        _make("sala", "Sala",
            Color("#C8A878"), Color("#B89868"),
            Color("#8B7858"), Color("#6B5840"), Color("#3A2D1E"),
            Color("#FFA040")),
    ]

func _make(p_id: String, p_label: String,
        p_floor_a: Color, p_floor_b: Color,
        p_wall_top: Color, p_wall_front: Color, p_wall_outline: Color,
        p_goal_marker: Color) -> Resource:
    var t := SceneryThemeRes.new()
    t.id = p_id
    t.label = p_label
    t.floor_a = p_floor_a
    t.floor_b = p_floor_b
    t.wall_top = p_wall_top
    t.wall_front = p_wall_front
    t.wall_outline = p_wall_outline
    t.goal_marker_color = p_goal_marker
    return t

func by_id(p_id: String) -> Resource:
    for t in ALL:
        if t.id == p_id:
            return t
    return null
