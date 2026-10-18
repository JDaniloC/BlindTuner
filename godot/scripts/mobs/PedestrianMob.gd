extends "res://scripts/mobs/BaseMob.gd"
class_name PedestrianMob
## Dona Rosa — A vizinha atenciosa / pedestre da vizinhança.
## Caminha pela calçada com sua bolsa de feira.
## Ao ouvir a batida cadenciada da bengala de orientação, vira-se cordialmente,
## saúda o idoso com uma voz/sino acolhedor e, se estiver no caminho direto,
## dá um passo cortês para o lado abrindo espaço na calçada.

const PEDESTRIAN_TEXTURE_PATH := "res://assets/sprites/mobs/pedestrian_rosa_32x32.png"

var _is_stepping_aside: bool = false
var _original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	mob_name = "Dona Rosa"
	idle_sound_id = ""
	alert_sound_id = "pedestrian_greeting"
	idle_interval = 0.0
	is_passable = true
	base_scale = Vector2(2.0, 2.0)
	super._ready()
	_original_position = position
	if _sprite != null:
		set_texture(load_texture_safe(PEDESTRIAN_TEXTURE_PATH), 4)
		_sprite.scale = base_scale
		_sprite.offset = Vector2(0, -16)
		_start_breathing_animation(1.8, 0.02)

func is_stepping_aside() -> bool:
	return _is_stepping_aside

func _on_cane_heard(dist: float, is_rhythmic: bool, _note_key: String) -> void:
	super._on_cane_heard(dist, is_rhythmic, _note_key)
	if dist <= 160.0:
		_greet_player(dist, is_rhythmic)

func _greet_player(dist: float, _is_rhythmic: bool) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_alert_time_ms > ALERT_COOLDOWN_MS:
		_last_alert_time_ms = now
		play_mob_sound("pedestrian_greeting")
		_animate_courtesy_nod()

	if dist < 50.0 and not _is_stepping_aside:
		_step_aside_courtesy()

func _animate_courtesy_nod() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(_sprite, "scale:y", base_scale.y * 0.90, 0.12).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "scale:y", base_scale.y * 1.04, 0.16).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "scale:y", base_scale.y, 0.12).set_trans(Tween.TRANS_SINE)

## Movimento cortês de abrir espaço na calçada ao perceber a pessoa com bengala
func _step_aside_courtesy() -> void:
	_is_stepping_aside = true
	start_movement_animation(8.0)
	var tw := create_tween()
	var side_offset := Vector2(16.0, -8.0)
	tw.tween_property(self, "position", _original_position + side_offset, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(stop_movement_animation)
	tw.tween_interval(2.2)
	tw.tween_callback(func(): start_movement_animation(8.0))
	tw.tween_property(self, "position", _original_position, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		stop_movement_animation()
		_is_stepping_aside = false
	)
