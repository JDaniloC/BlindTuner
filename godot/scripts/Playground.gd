extends Node2D
## Cena raiz do MVP. Compõe Character + Joystick + NotePanel, gera paredes do cenário,
## e conecta o fluxo de signals.

const ROOM_SIZE := Vector2i(10, 10)

@onready var _character: Node2D = $Character
@onready var _joystick: Control = $UI/DirectionJoystick
@onready var _note_panel: PanelContainer = $UI/NotePanel
@onready var _walls_node: Node2D = $Walls
@onready var _camera: Camera2D = $Camera2D

var _wall_tiles: Dictionary = {}

func _ready() -> void:
	_build_room()
	_character.grid_position = Vector2i(5, 5)
	_character.blocked_tiles = _wall_tiles
	_character.position = _character.grid_to_world(_character.grid_position)
	_character.moved.connect(_on_character_moved)
	_character.blocked.connect(_on_character_blocked)
	_joystick.note_triggered.connect(_on_note_triggered)

func _build_room() -> void:
	# Paredes formando um retângulo + alguns obstáculos internos
	var walls: Array[Vector2i] = []
	for x in range(ROOM_SIZE.x):
		walls.append(Vector2i(x, 0))
		walls.append(Vector2i(x, ROOM_SIZE.y - 1))
	for y in range(ROOM_SIZE.y):
		walls.append(Vector2i(0, y))
		walls.append(Vector2i(ROOM_SIZE.x - 1, y))
	walls.append(Vector2i(3, 4))
	walls.append(Vector2i(7, 6))
	walls.append(Vector2i(4, 7))

	for tile in walls:
		_wall_tiles[tile] = true
		_spawn_wall_visual(tile)

func _spawn_wall_visual(tile: Vector2i) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(56, 28)
	rect.color = Color(0.25, 0.22, 0.30, 1)
	rect.position = _character.grid_to_world(tile) - rect.size / 2.0
	_walls_node.add_child(rect)

func _process(delta: float) -> void:
	# Camera smooth follow, frame-rate independent (alpha calibrated to 0.1 at 60 FPS).
	var alpha := 1.0 - pow(0.9, delta * 60.0)
	_camera.position = _camera.position.lerp(_character.position, alpha)

func _on_note_triggered(note_key: String) -> void:
	AudioManager.play_note(note_key)
	_note_panel.display_note(note_key)
	_character.handle_note(note_key)

func _on_character_moved(_pos: Vector2i) -> void:
	pass  # animação futura

func _on_character_blocked(_dir: Vector2i) -> void:
	AudioManager.play_collision_sfx()
