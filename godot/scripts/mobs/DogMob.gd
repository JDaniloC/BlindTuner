extends "res://scripts/mobs/BaseMob.gd"
class_name DogMob
## Thor o Cão Guardião — Cão leal do portão/vizinhança.
## Respira suavemente e dá um latido amigável ao ouvir o toque da bengala.

const DOG_TEXTURE_PATH := "res://assets/sprites/mobs/dog_thor_32x32.png"

func _ready() -> void:
	mob_name = "Thor"
	idle_sound_id = "dog_pant"
	alert_sound_id = "dog_bark"
	idle_interval = 4.0
	is_passable = true
	super._ready()
	if _sprite != null:
		_sprite.texture = load_texture_safe(DOG_TEXTURE_PATH)
		_sprite.offset = Vector2(0, -6)
		_start_breathing_animation(0.9, 0.05)

func _on_cane_heard(dist: float, is_rhythmic: bool, _note_key: String) -> void:
	super._on_cane_heard(dist, is_rhythmic, _note_key)
	if dist <= 150.0:
		if is_rhythmic:
			play_mob_sound("dog_pant")
			_animate_tail_wag()
		if dist <= 75.0:
			play_mob_sound("dog_bark")

func _animate_tail_wag() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(_sprite, "rotation", 0.08, 0.07).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "rotation", -0.08, 0.07).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "rotation", 0.06, 0.07).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "rotation", 0.0, 0.07).set_trans(Tween.TRANS_SINE)
