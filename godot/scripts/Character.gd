extends Node2D
## Personagem isométrico do MVP. Move 1 tile por nota de movimento; bloqueado por paredes; ignora reservadas.

signal moved(new_grid_position: Vector2i)
signal blocked(direction: Vector2i)
signal action_performed(action_id: String, grid_position: Vector2i, facing: Vector2i)

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MOVE_DURATION := 0.18
const RUN_MOVE_DURATION := 0.11  # ~MOVE_DURATION * 0.6
const DOUBLE_TAP_WINDOW_MS := 400
const TRIP_DURATION_SEC := 0.6
const JUMP_DURATION_SEC := 0.4     # 4 frames / 10 fps
const ACTION_FX_DURATION_SEC := 0.3
const ARMED_RUN_TINT := Color(1.4, 1.2, 0.8)  # amarelo quente, brilho > 1.0

enum State { IDLE, WALK, RUN, TRIP }

@export var grid_position: Vector2i = Vector2i(5, 5)
## Dicionário { Vector2i -> bool } populado pela cena pai (Playground) com tiles bloqueados.
var blocked_tiles: Dictionary = {}
var _base_scale: Vector2 = Vector2.ONE  # capturado em _ready (cena define scale 2,2)
var _tween: Tween
var _action_fx_tween: Tween

var state: State = State.IDLE
var _last_direction: Vector2i = Vector2i(0, 1)
var _last_note_key: String = ""
var _last_note_time_ms: int = 0
var _run_next: bool = false  # armado por handle_action(As4); consumido pelo próximo handle_note de movimento

const SHEET_BASE := "res://assets/sprites/character/16x32/"
const SHEETS := {
	"idle":   { "file": "16x32 Idle-Sheet.png",   "cols": 4, "frame_w": 32, "frame_h": 32, "loop": true,  "fps": 6 },
	"walk":   { "file": "16x32 Walk-Sheet.png",   "cols": 4, "frame_w": 32, "frame_h": 32, "loop": true,  "fps": 10 },
	"run":    { "file": "16x32 Run-Sheet.png",    "cols": 6, "frame_w": 32, "frame_h": 32, "loop": true,  "fps": 14 },
	"rotate": { "file": "16x32 Rotate-Sheet.png", "cols": 4, "frame_w": 32, "frame_h": 32, "loop": false, "fps": 10 },
	"jump":   { "file": "16x32 Jump-Sheet.png",   "cols": 4, "frame_w": 32, "frame_h": 32, "loop": false, "fps": 10 },
}
const DIRECTION_ROWS := ["s", "se", "e", "ne", "n"]
const DIRECTION_TO_KEY := {
	Vector2i(0, 1):   { "key": "s",  "flip": false },
	Vector2i(1, 1):   { "key": "se", "flip": false },
	Vector2i(1, 0):   { "key": "e",  "flip": false },
	Vector2i(1, -1):  { "key": "ne", "flip": false },
	Vector2i(0, -1):  { "key": "n",  "flip": false },
	Vector2i(-1, -1): { "key": "ne", "flip": true },
	Vector2i(-1, 0):  { "key": "e",  "flip": true },
	Vector2i(-1, 1):  { "key": "se", "flip": true },
}

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _animation_for(state_name: String, direction: Vector2i) -> Dictionary:
	var entry = DIRECTION_TO_KEY.get(direction, { "key": "s", "flip": false })
	return { "anim": "%s_%s" % [state_name, entry.key], "flip": entry.flip }

func _build_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")
	for state_name in SHEETS:
		var info = SHEETS[state_name]
		var texture: Texture2D = load(SHEET_BASE + info.file)
		for row in range(DIRECTION_ROWS.size()):
			var dir_key = DIRECTION_ROWS[row]
			var anim_name = "%s_%s" % [state_name, dir_key]
			sprite_frames.add_animation(anim_name)
			sprite_frames.set_animation_loop(anim_name, info.loop)
			sprite_frames.set_animation_speed(anim_name, info.fps)
			for col in range(info.cols):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(col * info.frame_w, row * info.frame_h, info.frame_w, info.frame_h)
				sprite_frames.add_frame(anim_name, atlas)
	return sprite_frames

func _play_animation(state_name: String, direction: Vector2i) -> void:
	var info = _animation_for(state_name, direction)
	_animated_sprite.flip_h = info.flip
	_animated_sprite.play(info.anim)

func _ready() -> void:
	position = grid_to_world(grid_position)
	_animated_sprite.sprite_frames = _build_sprite_frames()
	_base_scale = _animated_sprite.scale
	_play_animation("idle", Vector2i(0, 1))

## Recebe a nota disparada pelo joystick. Trata movimento, ação ou ignora se for reservada.
func handle_note(note_key: String) -> void:
	if state == State.TRIP:
		return
	if NoteMapping.is_action_note(note_key):
		handle_action(note_key)
		return
	if not NoteMapping.is_movement_note(note_key):
		return
	var dir := NoteMapping.direction_for(note_key)
	var now := Time.get_ticks_msec()
	var is_double_tap := (note_key == _last_note_key
						  and now - _last_note_time_ms < DOUBLE_TAP_WINDOW_MS)
	if _run_next or is_double_tap:
		_run_next = false
		_animated_sprite.modulate = Color.WHITE
		_try_run(dir)
	else:
		_try_walk(dir)
	_last_note_key = note_key
	_last_note_time_ms = now

func _try_walk(dir: Vector2i) -> void:
	var target := grid_position + dir
	if blocked_tiles.get(target, false):
		_enter_trip(dir)
		return
	_last_direction = dir
	state = State.WALK
	grid_position = target
	moved.emit(grid_position)
	_play_animation("walk", dir)
	_tween_to(grid_to_world(target), MOVE_DURATION)

func _try_run(dir: Vector2i) -> void:
	var target1 := grid_position + dir
	if blocked_tiles.get(target1, false):
		_enter_trip(dir)
		return
	var target2 := target1 + dir
	_last_direction = dir
	state = State.RUN
	_play_animation("run", dir)
	if blocked_tiles.get(target2, false):
		grid_position = target1
		moved.emit(grid_position)
		_tween_to(grid_to_world(target1), RUN_MOVE_DURATION)
	else:
		grid_position = target2
		moved.emit(grid_position)
		_tween_chain([grid_to_world(target1), grid_to_world(target2)], RUN_MOVE_DURATION)

func _tween_to(target_world: Vector2, duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", target_world, duration)
	_tween.finished.connect(_on_tween_finished)

func _tween_chain(waypoints: Array, segment_duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	for wp in waypoints:
		_tween.tween_property(self, "position", wp, segment_duration)
	_tween.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
	if state == State.TRIP:
		return
	state = State.IDLE
	_play_animation("idle", _last_direction)

func _enter_trip(dir: Vector2i) -> void:
	_run_next = false  # tropeçar cancela qualquer corrida armada (semântica de "quebra")
	_animated_sprite.modulate = Color.WHITE
	state = State.TRIP
	_last_direction = dir
	_play_animation("jump", dir)
	blocked.emit(dir)
	get_tree().create_timer(TRIP_DURATION_SEC).timeout.connect(_exit_trip)

func _exit_trip() -> void:
	if not is_instance_valid(self):
		return  # Character foi liberado antes do timer disparar
	if state != State.TRIP:
		return
	state = State.IDLE
	_play_animation("idle", _last_direction)

## Conversão grade → coordenadas de mundo (projeção isométrica padrão 2:1).
func grid_to_world(g: Vector2i) -> Vector2:
	var wx := float(g.x - g.y) * TILE_WIDTH * 0.5
	var wy := float(g.x + g.y) * TILE_HEIGHT * 0.5
	return Vector2(wx, wy)

## Executa uma ação especial (não-movimento). No-op se state==TRIP ou se a nota não é ação.
func handle_action(note_key: String) -> void:
	if state == State.TRIP:
		return
	if not NoteMapping.is_action_note(note_key):
		return
	var aid := NoteMapping.action_id_for(note_key)
	match aid:
		"pegar":    _do_pegar()
		"interagir": _do_interagir()
		"correr":  _do_correr()
		"pular":   _do_pular()
		_:         push_warning("handle_action: action_id desconhecido '%s'" % aid)
	action_performed.emit(aid, grid_position, _last_direction)

func _do_pegar() -> void:
	# Squash vertical relativo à scale base: "abaixa para pegar do chão".
	_play_action_fx_y(_base_scale.y * 0.85)

func _play_action_fx_y(squash_target: float) -> void:
	if _action_fx_tween:
		_action_fx_tween.kill()
		_animated_sprite.scale = _base_scale
	_action_fx_tween = create_tween()
	_action_fx_tween.tween_property(_animated_sprite, "scale:y",
		squash_target, ACTION_FX_DURATION_SEC * 0.5)
	_action_fx_tween.tween_property(_animated_sprite, "scale:y",
		_base_scale.y, ACTION_FX_DURATION_SEC * 0.5)

func _do_interagir() -> void:
	# Pulse horizontal relativo à scale base: "se inclina pra examinar/usar".
	_play_action_fx_x(_base_scale.x * 1.1)

func _play_action_fx_x(stretch_target: float) -> void:
	if _action_fx_tween:
		_action_fx_tween.kill()
		_animated_sprite.scale = _base_scale
	_action_fx_tween = create_tween()
	_action_fx_tween.tween_property(_animated_sprite, "scale:x",
		stretch_target, ACTION_FX_DURATION_SEC * 0.5)
	_action_fx_tween.tween_property(_animated_sprite, "scale:x",
		_base_scale.x, ACTION_FX_DURATION_SEC * 0.5)

func _do_correr() -> void:
	# One-shot: o próximo handle_note de movimento vira _try_run.
	_run_next = true
	_animated_sprite.modulate = ARMED_RUN_TINT

func _do_pular() -> void:
	_play_animation("jump", _last_direction)
	get_tree().create_timer(JUMP_DURATION_SEC).timeout.connect(_return_to_idle_if_static)

func _return_to_idle_if_static() -> void:
	if not is_instance_valid(self):
		return
	if state == State.IDLE:
		_play_animation("idle", _last_direction)
