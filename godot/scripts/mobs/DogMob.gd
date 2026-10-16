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
