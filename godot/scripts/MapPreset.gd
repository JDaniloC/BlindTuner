extends Resource
class_name MapPreset
## Layout de um cômodo: tamanho, paredes internas (sem borda — gerada no runtime),
## start (onde o personagem aparece) e goal (tile-alvo, marcador pulsante).

@export var id: String = ""
@export var label: String = ""
@export var size: Vector2i = Vector2i.ZERO
@export var walls: Array[Vector2i] = []
@export var start_grid: Vector2i = Vector2i.ZERO
@export var goal_grid: Vector2i = Vector2i.ZERO
@export var theme_id: String = ""
