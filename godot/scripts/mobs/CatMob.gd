extends "res://scripts/mobs/BaseMob.gd"
class_name CatMob
## Mimi o Gato — Companheiro felino do protagonista.
## Ronrona suavemente servindo de âncora acústica no ambiente.
## Quando o jogador tateia por perto com a bengala, solta um miado manhoso.

const CAT_TEXTURE_PATH := "res://assets/sprites/mobs/cat_mimi_32x32.png"

func _ready() -> void:
	mob_name = "Mimi"
	idle_sound_id = "cat_purr"
	alert_sound_id = "cat_meow"
	idle_interval = 3.5
	is_passable = true
	super._ready()
	if _sprite != null:
		_sprite.texture = load_texture_safe(CAT_TEXTURE_PATH)
		_sprite.offset = Vector2(0, -6)
		_start_breathing_animation()

func _start_breathing_animation() -> void:
	if _sprite == null:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(_sprite, "scale:y", 1.05, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "scale:y", 0.96, 1.2).set_trans(Tween.TRANS_SINE)
