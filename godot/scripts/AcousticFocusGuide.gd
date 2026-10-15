extends Node2D
class_name AcousticFocusGuide
## Guia visual acústico que viaja do objetivo sonoro até o personagem.
## Demonstra o foco auditivo ("Escutar"), orientando visual e auditivamente o jogador.

var from_pos: Vector2
var to_pos: Vector2
var _progress: float = 0.0
var _alpha: float = 0.9

func setup(origin: Vector2, target: Vector2) -> void:
	from_pos = origin
	to_pos = target
	position = Vector2.ZERO
	z_index = 250

func _ready() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_progress", 1.0, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(self, "_alpha", 0.0, 1.2).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _alpha <= 0.01:
		return
	var current_pos: Vector2 = from_pos.lerp(to_pos, _progress)
	var dir := (to_pos - from_pos).normalized()
	var normal := Vector2(-dir.y, dir.x)

	for i in range(3):
		var ring_offset := float(i) * 18.0
		var ring_center := current_pos - dir * ring_offset
		var arc_pts := PackedVector2Array()
		for a in range(-6, 7):
			var angle_rad := float(a) * 0.18
			var p := ring_center + normal * (float(a) * 5.0) + dir * (cos(angle_rad) * 8.0)
			arc_pts.append(p)
		var c := Color(0.4, 0.8, 1.0, _alpha * (1.0 - float(i) * 0.25))
		draw_polyline(arc_pts, c, 2.0, true)
