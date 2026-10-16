extends Node2D
class_name BaseMob
## Entidade áudio-tátil viva do BlindTuner (Gato Mimi, Cão Thor, Pombos).
## Atua como marco acústico dinâmico e obstáculo afetivo no grid isométrico.
## Emite sons espaciais 2D via panning estéreo para guiar jogadores com baixa visão.

signal alerted
signal stepped_on

const TILE_WIDTH := 64
const TILE_HEIGHT := 32

@export var grid_position: Vector2i = Vector2i.ZERO
@export var mob_name: String = "Mob"
@export var idle_sound_id: String = ""
@export var alert_sound_id: String = ""
@export var is_passable: bool = true
@export var idle_interval: float = 4.0
@export var max_audio_distance: float = 600.0
@export var audio_attenuation: float = 1.5

var _sprite: Sprite2D
var _audio_player: AudioStreamPlayer2D
var _idle_timer: Timer
var _last_alert_time_ms: int = 0
const ALERT_COOLDOWN_MS: int = 1200

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
		_idle_timer.wait_time = idle_interval
		_idle_timer.one_shot = false
		_idle_timer.timeout.connect(_on_idle_timeout)
		add_child(_idle_timer)

	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_sprite)

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

func _on_idle_timeout() -> void:
	if not idle_sound_id.is_empty():
		play_mob_sound(idle_sound_id)

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
	_animate_alert()

func on_stepped_on() -> void:
	stepped_on.emit()
	alert()

func _animate_alert() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(1.2, 0.8), 0.08)
	tw.tween_property(_sprite, "scale", Vector2(0.9, 1.15), 0.1)
	tw.tween_property(_sprite, "scale", Vector2(1.0, 1.0), 0.1)
