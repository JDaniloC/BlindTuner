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
		_make("curto", "Curto", "curto", "quarto",
			["D4", "D4", "F4", "F4"]),
		_make("medio", "Médio", "medio", "banheiro",
			["D4", "D4", "F4", "F4", "G4", "G4", "Cs4", "Cs4"]),
		_make("longo", "Longo", "longo", "sala",
			["D4", "D4", "F4", "F4", "G4", "G4", "Cs4", "Cs4",
			 "Ds4", "Ds4", "E4", "Fs4", "Fs4", "Fs4"]),
	]

func _make(p_id: String, p_label: String, p_size: String,
		p_map_id: String, p_notes: Array) -> Resource:
	var p := Preset.new()
	p.id = p_id
	p.label = p_label
	p.size_class = p_size
	p.map_id = p_map_id
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
