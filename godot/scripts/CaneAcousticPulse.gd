extends Node2D
class_name CaneAcousticPulse
## Pulso acústico 2D emitido pela ponta da bengala ao tocar o solo.
## Visualiza que cada nota musical e passo é reverberado pelo impacto da ponteira
## no piso isométrico (proporção 2:1), colorindo o chão com o tom da nota tocada.

const EXPAND_DURATION := 0.34
const MAX_RADIUS_X := 26.0
const MAX_RADIUS_Y := 13.0
const NUM_POINTS := 24

var _radius_x: float = 3.0
var _radius_y: float = 1.5
var _alpha: float = 0.85
var _note_color: Color = Color(0.75, 0.94, 1.0)
var _motes: Array[Dictionary] = []

func setup(p_pos: Vector2, p_color: Color) -> void:
	position = p_pos
	_note_color = p_color
	z_index = int(position.y) - 1

func _ready() -> void:
	# Spawna 3 micro-partículas acústicas verticais da batida da ponteira
	for i in range(3):
		var angle := (float(i) - 1.0) * 0.7
		_motes.append({
			"pos": Vector2(sin(angle) * 3.0, -1.0),
			"vel": Vector2(sin(angle) * 8.0, -14.0 - float(i) * 3.0),
			"age": 0.0,
			"duration": 0.28 + float(i) * 0.04,
			"size": 1.5,
		})

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "_radius_x", MAX_RADIUS_X, EXPAND_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "_radius_y", MAX_RADIUS_Y, EXPAND_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "_alpha", 0.0, EXPAND_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(queue_free)

func _process(delta: float) -> void:
	for m in _motes:
		m["age"] = float(m["age"]) + delta
		m["pos"] = (m["pos"] as Vector2) + (m["vel"] as Vector2) * delta
	queue_redraw()

func _draw() -> void:
	if _alpha <= 0.01:
		return
	
	var pts := _build_ellipse(_radius_x, _radius_y)
	
	# Preenchimento leve translúcido
	var fill_col := Color(_note_color.r, _note_color.g, _note_color.b, _alpha * 0.18)
	draw_colored_polygon(pts, fill_col)
	
	# Onda primária da nota
	var rim_col := Color(_note_color.r, _note_color.g, _note_color.b, _alpha * 0.95)
	draw_polyline(pts, rim_col, 1.8, true)
	
	# Mini-anel interno de ressonância
	if _radius_x > 8.0:
		var pts_inner := _build_ellipse(_radius_x * 0.45, _radius_y * 0.45)
		var inner_col := Color(1.0, 1.0, 1.0, _alpha * 0.50)
		draw_polyline(pts_inner, inner_col, 1.0, true)

	# Fagulhas acústicas do impacto da bengala
	for m in _motes:
		var m_age: float = float(m["age"])
		var m_dur: float = float(m["duration"])
		if m_age < m_dur:
			var p_alpha := (1.0 - (m_age / m_dur)) * _alpha
			var p_col := Color(_note_color.r, _note_color.g, _note_color.b, p_alpha)
			draw_circle(m["pos"], float(m["size"]), p_col)

func _build_ellipse(rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(NUM_POINTS + 1)
	for i in range(NUM_POINTS):
		var a := float(i) * TAU / float(NUM_POINTS)
		pts[i] = Vector2(cos(a) * rx, sin(a) * ry)
	pts[NUM_POINTS] = pts[0]
	return pts
