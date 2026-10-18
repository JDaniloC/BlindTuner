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
	base_scale = Vector2(1.4, 1.4)
	super._ready()
	if _sprite != null:
		set_texture(load_texture_safe(CANARY_TEXTURE_PATH), 4)
		_sprite.scale = base_scale
		_sprite.offset = Vector2(0, -6)
		_start_singing_animation()

func _start_singing_animation() -> void:
	if _sprite == null:
		return
	var tw := create_tween().set_loops()
	tw.tween_callback(func(): if _sprite.hframes > 1: _sprite.frame = 1)
	tw.tween_property(_sprite, "position:y", -2.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): if _sprite.hframes > 1: _sprite.frame = 0)
	tw.tween_property(_sprite, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_SINE)

func _on_cane_heard(dist: float, is_rhythmic: bool, _note_key: String) -> void:
	super._on_cane_heard(dist, is_rhythmic, _note_key)
	if dist <= 160.0:
		play_mob_sound("canary_sing")
		_animate_hop()

func _animate_hop() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_callback(func(): if _sprite.hframes > 1: _sprite.frame = 2)
	tw.tween_property(_sprite, "position:y", -6.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): if _sprite.hframes > 1: _sprite.frame = 0)
	tw.tween_property(_sprite, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
