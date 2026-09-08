extends Control
## Joystick virtual circular com 8 fatias iguais (4 cardinais + 4 diagonais).
## Cada fatia ocupa 45° e mapeia para uma nota de movimento. As 4 notas de
## ação saíram do círculo (vão pro SpecialActionPanel).

signal note_triggered(note_key: String)

const RADIUS := 80.0
const BACKDROP_OVERHANG := 12.0  # px que o disco/anel ultrapassam o raio das fatias
const DEAD_ZONE := 15.0
const SLICE_COUNT := 8
const SLICE_ANGLE_DEG := 45.0
const THUMB_RADIUS := 28.0
const SLICE_VERTICES := 16  # vértices ao longo do arco
const NEUTRAL_SLICE := Color(0.55, 0.55, 0.58)  # usado quando a pista de cor some

var _dragging := false
var _thumb_offset := Vector2.ZERO
var _slice_polygons: Array[Polygon2D] = []
var _slice_note_keys: Array[String] = []  # paralelo a _slice_polygons (8 entradas)
var _slice_icons: Array[Control] = []     # paralelo a _slice_note_keys (8 entradas)
var _active_slice_index: int = -1         # 0..7 (índice da fatia em _slice_polygons), ou -1
var _flash_tween: Tween
var _backdrop_disc: Polygon2D
var _backdrop_ring: Line2D

@onready var _slices_root: Node2D = $Slices
@onready var _thumb: Polygon2D = $Thumb

func _ready() -> void:
	_build_backdrop()
	_build_slices()
	_build_thumb()
	_refresh_slice_alphas()
	CueSettings.cue_level_changed.connect(_on_cue_changed)

## Disco + anel circulares atrás das fatias (substitui o antigo NinePatchRect).
## Adicionados primeiro em _slices_root, logo desenhados atrás das fatias.
func _build_backdrop() -> void:
	var r := RADIUS + BACKDROP_OVERHANG
	var pts: Array[Vector2] = []
	for v in range(32):
		var a := TAU * float(v) / 32.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	_backdrop_disc = Polygon2D.new()
	_backdrop_disc.polygon = PackedVector2Array(pts)
	_backdrop_disc.color = Color(0.12, 0.10, 0.09, 0.30)
	_slices_root.add_child(_backdrop_disc)
	var ring_pts: Array[Vector2] = pts.duplicate()
	ring_pts.append(pts[0])
	_backdrop_ring = Line2D.new()
	_backdrop_ring.points = PackedVector2Array(ring_pts)
	_backdrop_ring.width = 2.0
	_backdrop_ring.default_color = Color(0.20, 0.17, 0.14, 0.6)
	_slices_root.add_child(_backdrop_ring)

func _build_slices() -> void:
	_slice_polygons.clear()
	_slice_note_keys.clear()
	# 8 notas de movimento em ordem de inserção do dicionário ocupam
	# 0°, 45°, 90°, ..., 315° (N, NE, E, SE, S, SW, W, NW).
	var idx := 0
	for k in NoteMapping.NOTES.keys():
		var key: String = k
		if NoteMapping.is_action_note(key):
			continue
		var slice := Polygon2D.new()
		slice.polygon = _build_slice_polygon(idx)
		slice.color = slice_display_color(key)
		_slices_root.add_child(slice)
		_slice_polygons.append(slice)
		_slice_note_keys.append(key)
		idx += 1
	_build_slice_icons()

## Uma seta por fatia, posicionada no meio do arco (60% do raio), apontando
## na direção que a nota daquela fatia representa.
func _build_slice_icons() -> void:
	var IconScript := load("res://scripts/ActionIcon.gd")
	_slice_icons.clear()
	for i in range(_slice_note_keys.size()):
		var icon: Control = IconScript.new()
		icon.custom_minimum_size = Vector2(30, 30)
		icon.size = Vector2(30, 30)
		var deg := i * SLICE_ANGLE_DEG
		var rad := deg_to_rad(deg)
		var center := Vector2(sin(rad), -cos(rad)) * (RADIUS * 0.6)
		icon.position = center - icon.size * 0.5
		_slices_root.add_child(icon)
		icon.set_note(_slice_note_keys[i])
		_slice_icons.append(icon)

func slice_display_color(note_key: String) -> Color:
	if CueSettings.shows_color():
		return NoteMapping.color_for(note_key)
	return NEUTRAL_SLICE

func _on_cue_changed(_level: int) -> void:
	for i in range(_slice_polygons.size()):
		var c := slice_display_color(_slice_note_keys[i])
		c.a = _slice_polygons[i].color.a  # preserva alpha atual (gerido por _refresh_slice_alphas)
		_slice_polygons[i].color = c

func _build_slice_polygon(slice_index: int) -> PackedVector2Array:
	var points: Array[Vector2] = [Vector2.ZERO]
	# ângulo 0° aponta pra Norte (-y); fatia começa metade do passo antes
	# (centro alinhado com a direção da nota).
	var start_deg := slice_index * SLICE_ANGLE_DEG - SLICE_ANGLE_DEG * 0.5
	for v in range(SLICE_VERTICES + 1):
		var t := float(v) / SLICE_VERTICES
		var deg := start_deg + t * SLICE_ANGLE_DEG
		var rad := deg_to_rad(deg)
		# 0°=Norte (sentido horário): x = sin(rad), y = -cos(rad)
		var x := sin(rad) * RADIUS
		var y := -cos(rad) * RADIUS
		points.append(Vector2(x, y))
	return PackedVector2Array(points)

func _build_thumb() -> void:
	var points: Array[Vector2] = []
	for v in range(24):
		var t := float(v) / 24.0
		var rad := t * TAU
		points.append(Vector2(cos(rad), sin(rad)) * THUMB_RADIUS)
	_thumb.polygon = PackedVector2Array(points)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_dragging = true
			_update_thumb(_local_pointer(event))
			accept_event()
		else:
			if _dragging:
				_emit_for_offset(_thumb_offset)
			_dragging = false
			_reset_thumb()
			accept_event()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging:
			_update_thumb(_local_pointer(event))
			accept_event()

func _local_pointer(event: InputEvent) -> Vector2:
	return event.position - size / 2.0

func _update_thumb(offset: Vector2) -> void:
	_thumb_offset = offset.limit_length(RADIUS)
	var center := size / 2.0
	_thumb.position = center + _thumb_offset
	_active_slice_index = slice_index_for_offset(_thumb_offset)
	_refresh_slice_alphas()

func _reset_thumb() -> void:
	_thumb_offset = Vector2.ZERO
	var center := size / 2.0
	_thumb.position = center
	_active_slice_index = -1
	_refresh_slice_alphas()

func _refresh_slice_alphas() -> void:
	for i in range(_slice_polygons.size()):
		var slice := _slice_polygons[i]
		var base := slice.color
		base.a = 0.85 if i == _active_slice_index else 0.35
		slice.color = base

func _emit_for_offset(offset: Vector2) -> void:
	var note := vector_to_note(offset)
	if note != "":
		_flash_active_slice()
		note_triggered.emit(note)

func _flash_active_slice() -> void:
	if _active_slice_index < 0 or _active_slice_index >= _slice_polygons.size():
		return
	if _flash_tween:
		_flash_tween.kill()
	var slice := _slice_polygons[_active_slice_index]
	var bright := slice.color
	bright.a = 1.0
	var dim := slice.color
	dim.a = 0.35
	_flash_tween = create_tween()
	_flash_tween.tween_property(slice, "color", bright, 0.06)
	_flash_tween.tween_property(slice, "color", dim, 0.16)

## Converte um vetor 2D (relativo ao centro) em uma chave de nota.
## Só retorna notas de movimento (snap em layout direcional 8x45°).
func vector_to_note(v: Vector2) -> String:
	if v.length() < DEAD_ZONE:
		return ""
	var angle_rad := atan2(v.x, -v.y)
	var angle_deg := rad_to_deg(angle_rad)
	return NoteMapping.snap_angle_to_note(angle_deg, true)

## Índice da fatia (0..7) correspondente ao ângulo em graus. 0°=N, 45°=NE, etc.
## Consistente com vector_to_note: usa o mesmo snap para resolver empates exatos.
func slice_index_for_angle(angle_deg: float) -> int:
	var note := NoteMapping.snap_angle_to_note(angle_deg, true)
	return _slice_note_keys.find(note)

func slice_index_for_offset(offset: Vector2) -> int:
	if offset.length() < DEAD_ZONE:
		return -1
	return slice_index_for_angle(rad_to_deg(atan2(offset.x, -offset.y)))
