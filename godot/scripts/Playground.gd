extends Node2D
## Cena raiz. Chão/paredes procedurais + loop de jogo (Conductor + GameHUD).

const ROOM_SIZE := Vector2i(10, 10)

@onready var _character: Node2D = $Character
@onready var _joystick: Control = $UI/DirectionJoystick
@onready var _note_panel: PanelContainer = $UI/NotePanel
@onready var _floor_node: Node2D = $Floor
@onready var _walls_node: Node2D = $Walls
@onready var _camera: Camera2D = $Camera2D
@onready var _screen_flash: ColorRect = $UI/ScreenFlash
@onready var _conductor: Node = $Conductor
@onready var _hud: Control = $UI/GameHUD
@onready var _special_actions: Control = $UI/SpecialActionPanel

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const WALL_HEIGHT := 32
const FLOOR_COLOR_A := Color(0.55, 0.40, 0.28, 1.0)
const FLOOR_COLOR_B := Color(0.50, 0.36, 0.25, 1.0)
const WALL_TOP_COLOR := Color(0.62, 0.55, 0.48, 1.0)
const WALL_FRONT_COLOR := Color(0.50, 0.42, 0.35, 1.0)
const WALL_OUTLINE := Color(0.20, 0.16, 0.12, 1.0)

const SHAKE_INTENSITY := 8.0
const SHAKE_DURATION := 0.25
const FLASH_PEAK_ALPHA := 0.45
const FLASH_DURATION := 0.18
# Atrasa o SFX de colisão para não mascarar a nota tocada pelo jogador.
# A nota dura NOTE_DURATION_SEC=0.6s; 0.5s deixa o pitch ser percebido antes do "erro".
const COLLISION_SFX_DELAY := 0.5

var _wall_tiles: Dictionary = {}
var _shake_remaining := 0.0
var _flash_tween: Tween

func _ready() -> void:
	_build_room()
	_character.grid_position = Vector2i(5, 5)
	_character.blocked_tiles = _wall_tiles
	_character.position = _character.grid_to_world(_character.grid_position)
	_character.blocked.connect(_on_character_blocked)
	_character.armed_state_changed.connect(_special_actions.on_armed_state_changed)
	_joystick.note_triggered.connect(_on_note_triggered)
	_special_actions.note_triggered.connect(_on_note_triggered)
	_conductor.preview_note.connect(_on_preview_note)
	_conductor.call_cue.connect(_on_call_cue)
	_conductor.replay_note.connect(_on_replay_note)
	_conductor.note_resolved.connect(_on_note_resolved)
	_conductor.phase_changed.connect(_on_phase_changed)
	_conductor.sequence_complete.connect(_on_sequence_complete)
	_hud.start_requested.connect(_on_start_requested)
	_hud.restart_requested.connect(_on_restart_requested)

func _on_start_requested(preset_id: String, cue_level: int) -> void:
	_begin_preset(preset_id, cue_level)

func _on_restart_requested() -> void:
	if _conductor._preset != null:
		_begin_preset(_conductor._preset.id, CueSettings.cue_level)

func _begin_preset(preset_id: String, cue_level: int) -> void:
	var preset = SequencePresets.by_id(preset_id)
	if preset == null:
		return
	var map = MapPresets.by_id(preset.map_id)
	CueSettings.set_level(cue_level)
	_hud.hide_stats()
	_character.grid_position = map.start_grid
	_character.position = _character.grid_to_world(map.start_grid)
	_conductor.load_preset(preset)
	_conductor.start()
	_hud.set_progress(0, preset.notes.size())

func _on_preview_note(note_key: String, _index: int) -> void:
	# PREVIEW: só ouvir, personagem não se move.
	AudioManager.play_note(note_key)
	_note_panel.display_note(note_key)

func _on_call_cue(note_key: String, index: int) -> void:
	# Toca o alvo + mostra a pista (conforme CueSettings, via NotePanel).
	AudioManager.play_note(note_key)
	_note_panel.display_note(note_key)
	_hud.set_progress(index, _conductor._preset.notes.size())

func _on_replay_note(note_key: String, index: int) -> void:
	# REPLAY: o personagem "toca" e (se movement) anda o caminho canônico do preset.
	AudioManager.play_note(note_key)
	if NoteMapping.is_action_note(note_key):
		_character.handle_action(note_key)
	else:
		_character._try_walk(NoteMapping.direction_for(note_key))
	_hud.set_progress(index, _conductor._preset.notes.size())

func _on_phase_changed(phase: int) -> void:
	# Ao entrar no REPLAY, reposiciona o personagem no início do preset.
	if phase == _conductor.Phase.REPLAY:
		var preset = _conductor._preset
		var sg: Vector2i = MapPresets.by_id(preset.map_id).start_grid
		_character.grid_position = sg
		_character.position = _character.grid_to_world(sg)

func _on_note_triggered(note_key: String) -> void:
	match _conductor.phase:
		_conductor.Phase.IDLE:
			# Modo livre: anda de verdade (Character.handle_note trata
			# nota de movimento, double-tap e colisão de parede) + toca a nota.
			AudioManager.play_note(note_key)
			_note_panel.display_note(note_key)
			_character.handle_note(note_key)
		_conductor.Phase.CALL:
			AudioManager.play_note(note_key)
			_note_panel.display_note(note_key)
			_conductor.submit_note(note_key)
		_:
			pass  # PREVIEW/REPLAY: não conflita com playback; DONE: sem nota ativa para submeter

func _on_note_resolved(hit: bool, index: int) -> void:
	var note_key: String = _conductor._preset.notes[index]
	if NoteMapping.is_action_note(note_key):
		# Acerto numa ação: dispara a ação; erro: tropeço com a última direção.
		if hit:
			_character.handle_action(note_key)
		else:
			_character._enter_trip(_character._last_direction)
		return
	var dir: Vector2i = NoteMapping.direction_for(note_key)
	if hit:
		# Preset validado contra _wall_tiles; _try_walk não deveria tropeçar.
		# Se tropeçar (preset com bug), Conductor já avançou _index — dessincronia visual.
		_character._try_walk(dir)
	else:
		# Erro de conhecimento: tropeço no lugar (cosmético, sem dano).
		_character._enter_trip(dir)

func _on_sequence_complete(stats: Dictionary) -> void:
	_hud.show_stats(stats)

func _build_room() -> void:
	for x in range(ROOM_SIZE.x):
		for y in range(ROOM_SIZE.y):
			_spawn_floor_tile(Vector2i(x, y))
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

func _spawn_floor_tile(tile: Vector2i) -> void:
	var center: Vector2 = _character.grid_to_world(tile)
	var poly := Polygon2D.new()
	poly.polygon = _diamond_polygon(TILE_WIDTH, TILE_HEIGHT)
	var checker := (tile.x + tile.y) % 2 == 0
	poly.color = FLOOR_COLOR_A if checker else FLOOR_COLOR_B
	poly.position = center
	_floor_node.add_child(poly)

func _spawn_wall_visual(tile: Vector2i) -> void:
	var center: Vector2 = _character.grid_to_world(tile)
	var node := Node2D.new()
	node.position = center
	var front := Polygon2D.new()
	var hw := TILE_WIDTH * 0.5
	front.polygon = PackedVector2Array([
		Vector2(-hw,  0),
		Vector2( hw,  0),
		Vector2( hw, -WALL_HEIGHT),
		Vector2(-hw, -WALL_HEIGHT),
	])
	front.color = WALL_FRONT_COLOR
	node.add_child(front)
	var top := Polygon2D.new()
	top.polygon = _diamond_polygon(TILE_WIDTH, TILE_HEIGHT)
	top.color = WALL_TOP_COLOR
	top.position = Vector2(0, -WALL_HEIGHT)
	node.add_child(top)
	var outline := Line2D.new()
	var pts := _diamond_polygon(TILE_WIDTH, TILE_HEIGHT)
	var pts_closed: Array[Vector2] = []
	for p in pts:
		pts_closed.append(p)
	pts_closed.append(pts[0])
	outline.points = PackedVector2Array(pts_closed)
	outline.width = 1.0
	outline.default_color = WALL_OUTLINE
	outline.position = Vector2(0, -WALL_HEIGHT)
	node.add_child(outline)
	_walls_node.add_child(node)

func _diamond_polygon(w: int, h: int) -> PackedVector2Array:
	var hw := w * 0.5
	var hh := h * 0.5
	return PackedVector2Array([
		Vector2(0, -hh),
		Vector2(hw,  0),
		Vector2(0,  hh),
		Vector2(-hw, 0),
	])

func _process(delta: float) -> void:
	var alpha := 1.0 - pow(0.9, delta * 60.0)
	_camera.position = _camera.position.lerp(_character.position, alpha)
	if _shake_remaining > 0.0:
		_shake_remaining = max(0.0, _shake_remaining - delta)
		var t := _shake_remaining / SHAKE_DURATION
		var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * SHAKE_INTENSITY * t
		_camera.offset = offset
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO

func _on_character_blocked(_dir: Vector2i) -> void:
	_shake_remaining = SHAKE_DURATION
	_flash_screen()
	# Delay no SFX para a nota do jogador ser ouvida antes (pista auditiva de cima/baixo).
	get_tree().create_timer(COLLISION_SFX_DELAY).timeout.connect(AudioManager.play_collision_sfx)

func _flash_screen() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_screen_flash, "color:a", FLASH_PEAK_ALPHA, FLASH_DURATION * 0.3)
	_flash_tween.tween_property(_screen_flash, "color:a", 0.0, FLASH_DURATION * 0.7)
