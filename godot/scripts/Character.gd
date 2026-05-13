extends Node2D
## Personagem isométrico do MVP. Move 1 tile por nota de movimento; bloqueado por paredes; ignora reservadas.

signal moved(new_grid_position: Vector2i)
signal blocked(direction: Vector2i)

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MOVE_DURATION := 0.18

@export var grid_position: Vector2i = Vector2i(5, 5)
## Dicionário { Vector2i -> bool } populado pela cena pai (Playground) com tiles bloqueados.
var blocked_tiles: Dictionary = {}
var _tween: Tween

func _ready() -> void:
    position = grid_to_world(grid_position)

## Recebe a nota disparada pelo joystick. Trata movimento ou ignora se for reservada.
func handle_note(note_key: String) -> void:
    if not NoteMapping.is_movement_note(note_key):
        return
    var dir := NoteMapping.direction_for(note_key)
    var target := grid_position + dir
    if blocked_tiles.get(target, false):
        blocked.emit(dir)
        return
    grid_position = target
    moved.emit(grid_position)
    _tween_to(grid_to_world(target))

func _tween_to(target_world: Vector2) -> void:
    if _tween and _tween.is_running():
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(self, "position", target_world, MOVE_DURATION)

## Conversão grade → coordenadas de mundo (projeção isométrica padrão 2:1).
func grid_to_world(g: Vector2i) -> Vector2:
    var wx := float(g.x - g.y) * TILE_WIDTH * 0.5
    var wy := float(g.x + g.y) * TILE_HEIGHT * 0.5
    return Vector2(wx, wy)
