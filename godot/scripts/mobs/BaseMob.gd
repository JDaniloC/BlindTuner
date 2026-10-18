extends Node2D
class_name BaseMob
## Entidade áudio-tátil viva do BlindTuner (Gato Mimi, Cão Thor, Pombos).
## Atua como marco acústico dinâmico e obstáculo afetivo no grid isométrico.
## Emite sons espaciais 2D via panning estéreo para guiar jogadores com baixa visão.

signal alerted
signal stepped_on
signal cane_heard(distance: float, is_rhythmic: bool, note_key: String)

const TILE_WIDTH := 64
const TILE_HEIGHT := 32

@export var grid_position: Vector2i = Vector2i.ZERO
@export var mob_name: String = "Mob"
@export var idle_sound_id: String = ""
@export var alert_sound_id: String = ""
@export var is_passable: bool = true
@export var is_interactable: bool = false
@export var can_radiate_waves: bool = false
@export var base_scale: Vector2 = Vector2(2.0, 2.0)
@export var idle_interval: float = 4.0
@export var max_audio_distance: float = 600.0
@export var audio_attenuation: float = 1.5

var _shadow: Polygon2D
var _sprite: Sprite2D
var _audio_player: AudioStreamPlayer2D
var _idle_timer: Timer
var _last_alert_time_ms: int = 0
const ALERT_COOLDOWN_MS: int = 1200

var _cane_tap_history: Array[int] = []
var _last_cane_reaction_time_ms: int = 0
const CANE_REACTION_COOLDOWN_MS: int = 350
const CANE_HEARING_DISTANCE: float = 180.0

var _is_animating_movement: bool = false
var _anim_timer: float = 0.0
var _anim_fps: float = 8.0

static func load_texture_safe(res_path: String) -> Texture2D:
	var global_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(res_path):
		var img := Image.load_from_file(global_path)
		if img != null:
			return ImageTexture.create_from_image(img)
	return null

func _ready() -> void:
	_setup_nodes()
	position = grid_to_world(grid_position)
	z_index = int(position.y)
	if not idle_sound_id.is_empty():
		start_idle_sound()

func _setup_nodes() -> void:
	if _audio_player == null:
		_audio_player = AudioStreamPlayer2D.new()
		_audio_player.bus = "Master"
		_audio_player.max_distance = max_audio_distance
		_audio_player.attenuation = audio_attenuation
		_audio_player.panning_strength = 1.0
		add_child(_audio_player)

	if _idle_timer == null:
		_idle_timer = Timer.new()
		_idle_timer.wait_time = maxf(0.1, idle_interval)
		_idle_timer.one_shot = false
		_idle_timer.timeout.connect(_on_idle_timeout)
		add_child(_idle_timer)

	if _shadow == null:
		_shadow = Polygon2D.new()
		_shadow.name = "ContactShadow"
		var pts: Array[Vector2] = []
		for i in range(20):
			var a := TAU * float(i) / 20.0
			pts.append(Vector2(cos(a) * 16.0, sin(a) * 8.0))
		_shadow.polygon = PackedVector2Array(pts)
		_shadow.color = Color(0.05, 0.03, 0.02, 0.32)
		_shadow.position = Vector2(0.0, 2.0)
		add_child(_shadow)

	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.scale = base_scale
		add_child(_sprite)

func set_texture(tex: Texture2D, frame_count: int = 4) -> void:
	_setup_nodes()
	if _sprite == null or tex == null:
		return
	_sprite.texture = tex
	if tex.get_width() >= tex.get_height() * 2:
		_sprite.hframes = frame_count
	else:
		_sprite.hframes = 1
	_sprite.frame = 0

func _process(delta: float) -> void:
	if _is_animating_movement and _sprite != null and _sprite.hframes > 1:
		_anim_timer += delta * _anim_fps
		_sprite.frame = int(_anim_timer) % _sprite.hframes

func start_movement_animation(fps: float = 8.0) -> void:
	_is_animating_movement = true
	_anim_fps = fps
	_anim_timer = 0.0

func stop_movement_animation() -> void:
	_is_animating_movement = false
	_anim_timer = 0.0
	if _sprite != null:
		_sprite.frame = 0

func setup(p_grid: Vector2i, p_name: String = "") -> void:
	grid_position = p_grid
	if not p_name.is_empty():
		mob_name = p_name
	position = grid_to_world(grid_position)
	z_index = int(position.y)

func grid_to_world(g: Vector2i) -> Vector2:
	return Vector2(
		(g.x - g.y) * (TILE_WIDTH * 0.5),
		(g.x + g.y) * (TILE_HEIGHT * 0.5)
	)

func start_idle_sound() -> void:
	_setup_nodes()
	if _idle_timer.is_stopped() and idle_interval > 0.0:
		_idle_timer.start()

func stop_idle_sound() -> void:
	if _idle_timer != null and not _idle_timer.is_stopped():
		_idle_timer.stop()

func play_mob_sound(sound_key: String) -> void:
	if sound_key.is_empty() or _audio_player == null:
		return
	_audio_player.stream = AudioManager.get_mob_stream(sound_key)
	_audio_player.play()
	if can_radiate_waves:
		_spawn_acoustic_ring(Color(0.96, 0.78, 0.35, 0.75))

func _on_idle_timeout() -> void:
	if not idle_sound_id.is_empty():
		play_mob_sound(idle_sound_id)

## Verifica se as batidas recentes da bengala formam uma cadência rítmica regular (passo firme)
func is_rhythmic_cadence() -> bool:
	if _cane_tap_history.size() < 2:
		return false
	var now := Time.get_ticks_msec()
	if now - _cane_tap_history[-1] > 1400:
		return false
	var intervals: Array[int] = []
	for i in range(1, _cane_tap_history.size()):
		var dt: int = _cane_tap_history[i] - _cane_tap_history[i - 1]
		intervals.append(dt)
	for dt in intervals:
		if dt < 150 or dt > 800:
			return false
	if intervals.size() >= 2:
		var diff: int = abs(intervals[-1] - intervals[-2])
		return diff < 280
	return true

## Define explicitamente o histórico de toques (usado por testes ou sincronização)
func set_cane_tap_history(history: Array) -> void:
	_cane_tap_history.clear()
	for h in history:
		_cane_tap_history.append(int(h))

## Reage ao toque da bengala no solo (emitido a cada passo ou tatear)
func on_cane_tap(cane_world_pos: Vector2, note_key: String = "") -> void:
	var dist: float = position.distance_to(cane_world_pos)
	if dist > CANE_HEARING_DISTANCE:
		return
	var now := Time.get_ticks_msec()
	_cane_tap_history.append(now)
	if _cane_tap_history.size() > 4:
		_cane_tap_history.pop_front()
	
	var is_rhythmic: bool = is_rhythmic_cadence()
	if now - _last_cane_reaction_time_ms >= CANE_REACTION_COOLDOWN_MS:
		_last_cane_reaction_time_ms = now
		_on_cane_heard(dist, is_rhythmic, note_key)
		cane_heard.emit(dist, is_rhythmic, note_key)

## Implementação base para reação à bengala (sobrescrita por cada pet/npc)
func _on_cane_heard(dist: float, _is_rhythmic: bool, _note_key: String) -> void:
	if can_radiate_waves and dist <= 110.0:
		_spawn_acoustic_ring(Color(0.92, 0.85, 0.65, 0.65))

## Reage ao pulso de bengala do jogador (ação Tatear / Gs4)
func on_tactile_pulse(_world_pos: Vector2, pulse_grid: Vector2i) -> void:
	var dist: int = maxi(abs(pulse_grid.x - grid_position.x), abs(pulse_grid.y - grid_position.y))
	if dist <= 2:
		alert()

## Reage à movimentação do jogador no grid
func on_player_moved(player_grid: Vector2i) -> void:
	if player_grid == grid_position:
		on_stepped_on()
		return
	var dist: int = maxi(abs(player_grid.x - grid_position.x), abs(player_grid.y - grid_position.y))
	if dist == 1:
		_on_player_adjacent()

func _on_player_adjacent() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_alert_time_ms > ALERT_COOLDOWN_MS:
		_last_alert_time_ms = now
		if not idle_sound_id.is_empty():
			play_mob_sound(idle_sound_id)

func alert() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_alert_time_ms < ALERT_COOLDOWN_MS:
		return
	_last_alert_time_ms = now
	if not alert_sound_id.is_empty():
		play_mob_sound(alert_sound_id)
	alerted.emit()
	if can_radiate_waves:
		_spawn_acoustic_ring(Color(0.40, 0.88, 1.0, 0.88))
	_animate_alert()

func on_stepped_on() -> void:
	stepped_on.emit()
	alert()

func _animate_alert() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(1.2, 0.8) * base_scale, 0.08)
	tw.tween_property(_sprite, "scale", Vector2(0.9, 1.15) * base_scale, 0.1)
	tw.tween_property(_sprite, "scale", base_scale, 0.1)

## Onda 2D isométrica (elipse 2:1) indicando no chão a vocalização/ronronar do mob
func _spawn_acoustic_ring(color: Color) -> void:
	if not can_radiate_waves or not is_inside_tree():
		return
	var ring := Line2D.new()
	ring.width = 1.8
	ring.default_color = color
	var pts: Array[Vector2] = []
	for i in range(21):
		var a := TAU * float(i) / 20.0
		pts.append(Vector2(cos(a) * 12.0, sin(a) * 6.0))
	ring.points = PackedVector2Array(pts)
	ring.position = Vector2(0.0, 4.0)
	add_child(ring)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(2.6, 2.6), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(ring.queue_free)

func _start_breathing_animation(cycle_time: float = 1.2, scale_amount: float = 0.04) -> void:
	if _sprite == null:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(_sprite, "scale:y", base_scale.y * (1.0 + scale_amount), cycle_time).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "scale:y", base_scale.y * (1.0 - scale_amount * 0.8), cycle_time).set_trans(Tween.TRANS_SINE)
