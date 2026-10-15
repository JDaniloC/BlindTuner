extends Node2D
class_name TactileRipple
## Onda visual tátil isométrica em expansão.
## Modela a propagação da batida da bengala pelo piso isométrico (proporção 2:1).

const EXPAND_DURATION := 0.65
const MAX_RADIUS_X := 160.0
const MAX_RADIUS_Y := 80.0
const NUM_POINTS := 36

var _radius_x: float = 8.0
var _radius_y: float = 4.0
var _alpha: float = 0.85
var _color: Color = Color(0.85, 0.95, 1.0)

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
	var pts := PackedVector2Array()
	for i in range(NUM_POINTS + 1):
		var theta := float(i) * TAU / float(NUM_POINTS)
		pts.append(Vector2(cos(theta) * _radius_x, sin(theta) * _radius_y))
	var c := Color(_color.r, _color.g, _color.b, _alpha)
	draw_polyline(pts, c, 2.5, true)
	var fill_c := Color(_color.r, _color.g, _color.b, _alpha * 0.15)
	draw_colored_polygon(pts, fill_c)
