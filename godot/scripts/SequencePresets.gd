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
		# quarto 8×8, start (1,6), goal (6,1).
		# Path: (1,6)→Cs4(1,5)→D4(2,4)→D4(3,3)→D4(4,2)→Ds4(5,2)→D4(6,1).
		# Evita cama (1-2,1-3) e criado-mudo (3,2).
		_make("curto", "Curto", "curto", "quarto",
			["Cs4", "D4", "D4", "D4", "Ds4", "D4"]),

		# banheiro 10×10, start (8,8), goal (3,1).
		# Path: (8,8)→C4(7,7)→Cs4(7,6)→C4(6,5)→Cs4(6,4)→C4(5,3)→Cs4(5,2)→
		#       G4(4,2)→Cs4(4,1)→G4(3,1). Evita pia (1-2,1)/(1,2), vaso (7,1-2), lixeira (8,1).
		_make("medio", "Médio", "medio", "banheiro",
			["C4", "Cs4", "C4", "Cs4", "C4", "Cs4", "G4", "Cs4", "G4"]),

		# sala 12×12, start (10,10), goal (1,1).
		# Path zig-zag NW de 14 passos. Evita sofá (3-5,8), mesinha (4,6),
		# estante (10,2-5), TV (1,4).
		# (10,10)→C4(9,9)→Cs4(9,8)→C4(8,7)→G4(7,7)→Cs4(7,6)→C4(6,5)→Cs4(6,4)→
		# C4(5,3)→G4(4,3)→Cs4(4,2)→Cs4(4,1)→G4(3,1)→G4(2,1)→G4(1,1).
		_make("longo", "Longo", "longo", "sala",
			["C4", "Cs4", "C4", "G4", "Cs4", "C4", "Cs4", "C4",
			 "G4", "Cs4", "Cs4", "G4", "G4", "G4"]),
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
