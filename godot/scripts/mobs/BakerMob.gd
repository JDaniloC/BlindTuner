extends "res://scripts/mobs/BaseMob.gd"
class_name BakerMob
## Seu Alberto o Padeiro — O caloroso mestre da padaria da esquina.
## Fica na entrada com sua tábua de pães dourados recém-saídos do forno.
## Ao ouvir a cadência da bengala de orientação, saúda o idoso com voz acolhedora
## e recua um passo cortês para não obstruir o balcão nem a porta da padaria.

const BAKER_TEXTURE_PATH := "res://assets/sprites/mobs/baker_alberto_32x32.png"

var _is_stepping_aside: bool = false
var _original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	mob_name = "Seu Alberto o Padeiro"
	idle_sound_id = ""
	alert_sound_id = "baker_greeting"
	idle_interval = 0.0
	is_passable = true
	base_scale = Vector2(2.0, 2.0)
	super._ready()
	_original_position = position
	if _sprite != null:
		set_texture(load_texture_safe(BAKER_TEXTURE_PATH), 4)
		_sprite.scale = base_scale
		_sprite.offset = Vector2(0, -16)
		_start_breathing_animation(1.7, 0.03)

func is_stepping_aside() -> bool:
	return _is_stepping_aside

func _on_cane_heard(dist: float, is_rhythmic: bool, _note_key: String) -> void:
	super._on_cane_heard(dist, is_rhythmic, _note_key)
	if dist <= 160.0:
		_greet_customer(dist, is_rhythmic)

func _greet_customer(dist: float, _is_rhythmic: bool) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_alert_time_ms > ALERT_COOLDOWN_MS:
		_last_alert_time_ms = now
		play_mob_sound("baker_greeting")
		_animate_offer_bread()

	if dist < 50.0 and not _is_stepping_aside:
		_step_aside_courtesy()

func _animate_offer_bread() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	# Leve elevação do sprite e tábua de pães oferecendo acolhimento
	tw.tween_property(_sprite, "position:y", -3.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_sprite, "scale", Vector2(1.06, 0.96) * base_scale, 0.15)
	tw.tween_property(_sprite, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_sprite, "scale", base_scale, 0.2)

func _step_aside_courtesy() -> void:
	_is_stepping_aside = true
	start_movement_animation(7.0)
	var tw := create_tween()
	var side_offset := Vector2(-14.0, 7.0) # Recuo para a lateral da porta
	tw.tween_property(self, "position", _original_position + side_offset, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(stop_movement_animation)
	tw.tween_interval(2.2)
	tw.tween_callback(func(): start_movement_animation(7.0))
	tw.tween_property(self, "position", _original_position, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		stop_movement_animation()
		_is_stepping_aside = false
	)
