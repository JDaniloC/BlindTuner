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
		_start_breathing_animation(1.2, 0.05)

func _on_cane_heard(dist: float, is_rhythmic: bool, _note_key: String) -> void:
	super._on_cane_heard(dist, is_rhythmic, _note_key)
	if dist <= 140.0:
		if is_rhythmic:
			play_mob_sound("cat_purr")
			_animate_tail_swish()
		elif dist <= 60.0:
			play_mob_sound("cat_meow")

func _animate_tail_swish() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(_sprite, "scale:x", 1.15, 0.14).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "scale:x", 0.95, 0.14).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "scale:x", 1.0, 0.12).set_trans(Tween.TRANS_SINE)
