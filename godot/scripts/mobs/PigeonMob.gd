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
	super._ready()
	if _sprite != null:
		_sprite.texture = load_texture_safe(PIGEON_TEXTURE_PATH)
		_sprite.offset = Vector2(0, -4)
		_start_breathing_animation(1.5, 0.03)

func _animate_alert() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(_sprite, "position:y", -14.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_sprite, "scale", Vector2(1.2, 0.8), 0.15)
	tw.tween_property(_sprite, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_sprite, "scale", Vector2(1.0, 1.0), 0.2)

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
	tw.tween_property(_sprite, "position:x", 3.0, 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "position:x", 0.0, 0.08).set_trans(Tween.TRANS_SINE)
