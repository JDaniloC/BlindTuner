extends Node
## Autoload — presets autorais hardcoded (sem arquivo/arte externo).

const Preset := preload("res://scripts/SequencePreset.gd")

# Array[SequencePreset] omitido de propósito: GUT requer preload sem class_name.
var ALL: Array = []

func _ready() -> void:
	if ALL.is_empty():
		ALL = _build_all()

## Os 3 presets do MVP usam id == size_class por coincidência (curto/medio/longo);
## os campos têm papéis distintos (id = chave estável; size_class = classificador).
func _build_all() -> Array:
	return [
		_make("curto", "Curto", "curto", Vector2i(5, 5),
			["Ds4", "Ds4", "Gs4", "Gs4"]),
		_make("medio", "Médio", "medio", Vector2i(5, 5),
			["D4", "D4", "Ds4", "F4", "Gs4", "Gs4", "Gs4", "A4"]),
		_make("longo", "Longo", "longo", Vector2i(5, 5),
			["F4", "F4", "D4", "D4", "D4", "A4", "A4", "A4", "A4",
			 "Gs4", "B4", "C4", "D4", "Ds4"]),
	]

func _make(p_id: String, p_label: String, p_size: String,
		p_start: Vector2i, p_notes: Array) -> Resource:
	var p := Preset.new()
	p.id = p_id
	p.label = p_label
	p.size_class = p_size
	p.start_grid = p_start
	var typed: Array[String] = []
	for n in p_notes:
		typed.append(n)
	p.notes = typed
	return p

func by_id(p_id: String) -> Resource:
	for p in ALL:
		if p.id == p_id:
			return p
	return null
