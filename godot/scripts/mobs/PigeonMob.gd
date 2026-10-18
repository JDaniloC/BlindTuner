extends "res://scripts/mobs/BaseMob.gd"
class_name PigeonMob
## Pombos da Praça — Aves urbanas ao redor do chafariz.
## Arrulham suavemente; se o jogador se aproximar ou tatear, batem asas e voam.

const PIGEON_TEXTURE_PATH := "res://assets/sprites/mobs/pigeon_24x24.png"

func _ready() -> void:
	mob_name = "Pombo da Praça"
	idle_sound_id = "pigeon_coo"
	alert_sound_id = "pigeon_flutter"
	idle_interval = 4.5
	is_passable = true
	base_scale = Vector2(1.5, 1.5)
	super._ready()
	if _sprite != null:
		set_texture(load_texture_safe(PIGEON_TEXTURE_PATH), 4)
		_sprite.scale = base_scale
		_sprite.offset = Vector2(0, -6)
		_start_breathing_animation(1.5, 0.03)

func _animate_alert() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_callback(func(): if _sprite.hframes > 1: _sprite.frame = 3)
	tw.tween_property(_sprite, "position:y", -14.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_sprite, "scale", Vector2(1.2, 0.8) * base_scale, 0.15)
	tw.tween_callback(func(): if _sprite.hframes > 1: _sprite.frame = 0)
	tw.tween_property(_sprite, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_sprite, "scale", base_scale, 0.2)

func _on_cane_heard(dist: float, is_rhythmic: bool, _note_key: String) -> void:
	super._on_cane_heard(dist, is_rhythmic, _note_key)
	if dist < 45.0:
		alert()
	elif dist <= 130.0:
		play_mob_sound("pigeon_coo")
		_animate_head_bob()

func _animate_head_bob() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_callback(func(): if _sprite.hframes > 1: _sprite.frame = 1)
	tw.tween_property(_sprite, "position:x", 3.0, 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): if _sprite.hframes > 1: _sprite.frame = 0)
	tw.tween_property(_sprite, "position:x", 0.0, 0.08).set_trans(Tween.TRANS_SINE)
