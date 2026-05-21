extends Resource
class_name SceneryTheme
## Paleta visual de um cômodo. Cores procedurais hoje; Fase B adiciona atlas PNG.

@export var id: String = ""
@export var label: String = ""
@export var floor_a: Color = Color(0, 0, 0, 0)
@export var floor_b: Color = Color(0, 0, 0, 0)
@export var wall_top: Color = Color(0, 0, 0, 0)
@export var wall_front: Color = Color(0, 0, 0, 0)
@export var wall_outline: Color = Color(0, 0, 0, 0)
@export var goal_marker_color: Color = Color(0, 0, 0, 0)
