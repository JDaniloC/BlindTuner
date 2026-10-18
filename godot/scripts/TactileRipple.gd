extends Node2D
class_name TactileRipple
## Onda visual tátil isométrica 2D em expansão multi-frente.
## Modela a propagação da batida da bengala pelo piso isométrico (proporção 2:1)
## com três frentes harmônicas e marcações radiais de orientação espacial.

const EXPAND_DURATION := 0.72
const MAX_RADIUS_X := 160.0
const MAX_RADIUS_Y := 80.0
const NUM_POINTS := 40

var _radius_x: float = 8.0
var _radius_y: float = 4.0
var _alpha: float = 0.90
var _color: Color = Color(0.75, 0.94, 1.0)

func _ready() -> void:
	z_index = 200
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "_radius_x", MAX_RADIUS_X, EXPAND_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "_radius_y", MAX_RADIUS_Y, EXPAND_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "_alpha", 0.0, EXPAND_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _alpha <= 0.01:
		return
	var pts_outer := _build_ellipse(_radius_x, _radius_y)
	var fill_c := Color(_color.r, _color.g, _color.b, _alpha * 0.12)
	draw_colored_polygon(pts_outer, fill_c)

	# 1. Frente principal tátil (borda nítida 2D)
	var c_primary := Color(_color.r, _color.g, _color.b, _alpha)
	draw_polyline(pts_outer, c_primary, 2.5, true)

	# 2. Segunda frente harmônica (eco intermediário a 68% do raio)
	if _radius_x > 24.0:
		var pts_mid := _build_ellipse(_radius_x * 0.68, _radius_y * 0.68)
		var c_mid := Color(0.95, 0.90, 0.72, _alpha * 0.65)
		draw_polyline(pts_mid, c_mid, 1.6, true)

	# 3. Terceira frente interna (ressoar próximo aos pés a 38% do raio)
	if _radius_x > 42.0:
		var pts_inner := _build_ellipse(_radius_x * 0.38, _radius_y * 0.38)
		var c_inner := Color(_color.r, _color.g, _color.b, _alpha * 0.40)
		draw_polyline(pts_inner, c_inner, 1.2, true)

	# 4. Filamentos de bússola isométrica (8 direções) na crista da onda
	var tick_col := Color(1.0, 0.98, 0.90, _alpha * 0.55)
	for dir_idx in range(8):
		var a := float(dir_idx) * TAU / 8.0
		var p_in := Vector2(cos(a) * _radius_x * 0.86, sin(a) * _radius_y * 0.86)
		var p_out := Vector2(cos(a) * _radius_x * 1.02, sin(a) * _radius_y * 1.02)
		draw_line(p_in, p_out, tick_col, 1.5, true)

func _build_ellipse(rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(NUM_POINTS + 1):
		var theta := float(i) * TAU / float(NUM_POINTS)
		pts.append(Vector2(cos(theta) * rx, sin(theta) * ry))
	return pts
