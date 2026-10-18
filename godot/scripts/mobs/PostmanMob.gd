extends "res://scripts/mobs/BaseMob.gd"
class_name PostmanMob
## Tiago o Carteiro — Entregador postal da vizinhança com bicicleta vintage.
## Anda suavemente pelas calçadas e esquinas. Sua campainha niquelada ("plim-plim")
## funciona como marco acústico dinâmico para orientação de jogadores cegos.
## Ao ouvir a cadência da bengala longa, reduz a velocidade, toca a campainha cordialmente
## e, se necessário, encosta a bicicleta na margem da calçada liberando a passagem.

const POSTMAN_TEXTURE_PATH := "res://assets/sprites/mobs/postman_bike_48x40.png"

var _is_stepping_aside: bool = false
var _original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	mob_name = "Tiago o Carteiro"
	idle_sound_id = "postman_bell"
	alert_sound_id = "postman_bell"
	idle_interval = 5.5
	is_passable = true
	base_scale = Vector2(2.0, 2.0)
	super._ready()
	_original_position = position
	if _sprite != null:
		set_texture(load_texture_safe(POSTMAN_TEXTURE_PATH), 4)
		_sprite.scale = base_scale
		_sprite.offset = Vector2(0, -18)
		_start_breathing_animation(2.0, 0.02)
	
	# Ajusta a sombra para acomodar a bicicleta mais longa
	if _shadow != null:
		var pts: Array[Vector2] = []
		for i in range(20):
			var a := TAU * float(i) / 20.0
			pts.append(Vector2(cos(a) * 32.0, sin(a) * 14.0))
		_shadow.polygon = PackedVector2Array(pts)
		_shadow.position = Vector2(0.0, 4.0)

func is_stepping_aside() -> bool:
	return _is_stepping_aside

func _on_cane_heard(dist: float, is_rhythmic: bool, _note_key: String) -> void:
	super._on_cane_heard(dist, is_rhythmic, _note_key)
	if dist <= 170.0:
		_greet_with_bike(dist, is_rhythmic)

func _greet_with_bike(dist: float, _is_rhythmic: bool) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_alert_time_ms > ALERT_COOLDOWN_MS:
		_last_alert_time_ms = now
		play_mob_sound("postman_bell")
		_animate_bike_pause()

	if dist < 55.0 and not _is_stepping_aside:
		_step_aside_courtesy()

func _animate_bike_pause() -> void:
	if _sprite == null:
		return
	var tw := create_tween()
	# Leve recuo e retorno suave simulando desaceleração de bicicleta
	tw.tween_property(_sprite, "position:x", -3.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sprite, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_SINE)

func _step_aside_courtesy() -> void:
	_is_stepping_aside = true
	start_movement_animation(9.0)
	var tw := create_tween()
	var side_offset := Vector2(18.0, -9.0) # Deslocamento isométrico para a borda
	tw.tween_property(self, "position", _original_position + side_offset, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(stop_movement_animation)
	tw.tween_interval(2.5)
	tw.tween_callback(func(): start_movement_animation(9.0))
	tw.tween_property(self, "position", _original_position, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		stop_movement_animation()
		_is_stepping_aside = false
	)
