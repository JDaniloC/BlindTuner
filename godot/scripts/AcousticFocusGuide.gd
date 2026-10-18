extends Node2D
class_name AcousticFocusGuide
## Guia visual acústico 2D que viaja do objetivo sonoro até o personagem.
## Demonstra o foco auditivo ("Escutar"), desenhando um filamento harmônico 2D,
## frentes de onda acústica e partículas em losango ao longo do trajeto do som.

var from_pos: Vector2
var to_pos: Vector2
var _progress: float = 0.0
var _alpha: float = 0.92

func setup(origin: Vector2, target: Vector2) -> void:
	from_pos = origin
	to_pos = target
	position = Vector2.ZERO
	z_index = 250

func _ready() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_progress", 1.0, 1.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(self, "_alpha", 0.0, 1.25).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _alpha <= 0.01:
		return
	var span := to_pos - from_pos
	var dist := span.length()
	if dist < 1.0:
		return
	var dir := span / dist
	var normal := Vector2(-dir.y, dir.x)
	var current_pos: Vector2 = from_pos.lerp(to_pos, _progress)

	# 1. Trilha pontilhada harmônica 2D entre a fonte sonora e o ouvinte
	var num_dots := clampi(int(dist / 22.0), 4, 24)
	for d_idx in range(num_dots + 1):
		var frac := float(d_idx) / float(num_dots)
		var dot_pos := from_pos.lerp(to_pos, frac)
		var dist_to_wave := absf(frac - _progress)
		var boost := maxf(0.0, 1.0 - dist_to_wave * 3.5)
		var dot_r := 1.8 + boost * 2.0
		var dot_col := Color(1.0, 0.88, 0.52, _alpha * (0.22 + boost * 0.55))
		var diamond := PackedVector2Array([
			dot_pos + Vector2(0, -dot_r),
			dot_pos + Vector2(dot_r, 0),
			dot_pos + Vector2(0, dot_r),
			dot_pos + Vector2(-dot_r, 0),
		])
		draw_colored_polygon(diamond, dot_col)

	# 2. Três frentes de onda acústica 2D (gradiente dourado -> ciano)
	for i in range(3):
		var ring_offset := float(i) * 18.0
		var ring_center := current_pos - dir * ring_offset
		var arc_pts := PackedVector2Array()
		var spread := 1.0 - float(i) * 0.15
		for a in range(-8, 9):
			var angle_rad := float(a) * 0.15
			var p := ring_center + normal * (float(a) * 4.8 * spread) + dir * (cos(angle_rad) * 9.0)
			arc_pts.append(p)
		var ring_col := Color(0.45, 0.88, 1.0).lerp(Color(1.0, 0.86, 0.45), float(i) * 0.4)
		ring_col.a = _alpha * (1.0 - float(i) * 0.25)
		draw_polyline(arc_pts, ring_col, 2.4 - float(i) * 0.4, true)
