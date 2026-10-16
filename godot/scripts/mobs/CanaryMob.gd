extends "res://scripts/mobs/BaseMob.gd"
class_name CanaryMob
## Canário da Varanda — Pássaro cantor na gaiola aberta perto da samambaia.
## Canta melodiosamente em intervalos regulares, servindo de âncora musical.

const CANARY_TEXTURE_PATH := "res://assets/sprites/mobs/canary_24x24.png"

func _ready() -> void:
	mob_name = "Canário da Varanda"
	idle_sound_id = "canary_sing"
	alert_sound_id = "canary_flap"
	idle_interval = 4.0
	is_passable = true
	super._ready()
	if _sprite != null:
		_sprite.texture = load_texture_safe(CANARY_TEXTURE_PATH)
		_sprite.offset = Vector2(0, -6)
		_start_singing_animation()

func _start_singing_animation() -> void:
	if _sprite == null:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(_sprite, "position:y", -2.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
