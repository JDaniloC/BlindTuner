extends Control
## Joystick virtual circular com 12 fatias coloridas (uma por nota cromática).
## Trava em 12 ângulos, emite a nota correspondente ao soltar.

signal note_triggered(note_key: String)

const RADIUS := 80.0
const DEAD_ZONE := 15.0
const SLICE_COUNT := 12
const SLICE_ANGLE_DEG := 30.0
const THUMB_RADIUS := 28.0
const SLICE_VERTICES := 12  # vértices ao longo do arco

var _dragging := false
var _thumb_offset := Vector2.ZERO
var _slice_polygons: Array[Polygon2D] = []
var _active_slice_index: int = -1
var _flash_tween: Tween

@onready var _slices_root: Node2D = $Slices
@onready var _thumb: Polygon2D = $Thumb

func _ready() -> void:
	_build_slices()
	_build_thumb()
	_refresh_slice_alphas()

func _build_slices() -> void:
	_slice_polygons.clear()
	var note_keys := NoteMapping.NOTES.keys()
	# NOTES está ordenado por ângulo: C4=0, Cs4=30, ..., B4=330
	for i in range(SLICE_COUNT):
		var slice := Polygon2D.new()
		slice.polygon = _build_slice_polygon(i)
		var note_key: String = note_keys[i]
		slice.color = NoteMapping.color_for(note_key)
		_slices_root.add_child(slice)
		_slice_polygons.append(slice)

func _build_slice_polygon(slice_index: int) -> PackedVector2Array:
	var points: Array[Vector2] = [Vector2.ZERO]
	# ângulo 0° aponta pra Norte (-y); fatia começa 15° antes (centro alinhado com nota)
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
	if _active_slice_index < 0:
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
func vector_to_note(v: Vector2) -> String:
	if v.length() < DEAD_ZONE:
		return ""
	var angle_rad := atan2(v.x, -v.y)
	var angle_deg := rad_to_deg(angle_rad)
	return NoteMapping.snap_angle_to_note(angle_deg)

## Índice da fatia (0-11) correspondente ao ângulo em graus.
## 0° = Norte (C4 / fatia 0). Sentido horário.
func slice_index_for_angle(angle_deg: float) -> int:
	var normalized := fposmod(angle_deg, 360.0)
	return int(round(normalized / SLICE_ANGLE_DEG)) % SLICE_COUNT

func slice_index_for_offset(offset: Vector2) -> int:
	if offset.length() < DEAD_ZONE:
		return -1
	return slice_index_for_angle(rad_to_deg(atan2(offset.x, -offset.y)))
