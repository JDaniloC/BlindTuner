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
	# Caminhos validados manualmente contra paredes (3,4), (7,6), (4,7) e bordas.
	# Início em (5,5). Direções (novo mapeamento):
	#   C4(-1,-1) Cs4(0,-1) D4(1,-1) Ds4(1,0) E4(1,1) F4(0,1) Fs4(-1,1) G4(-1,0)
	return [
		# curto: (5,5)→(6,4)→(7,3)→(7,4)→(7,5). 4 passos.
		_make("curto", "Curto", "curto", Vector2i(5, 5),
			["D4", "D4", "F4", "F4"]),
		# medio: (5,5)→(6,4)→(7,3)→(7,4)→(7,5)→(6,5)→(5,5)→(5,4)→(5,3). 8 passos.
		_make("medio", "Médio", "medio", Vector2i(5, 5),
			["D4", "D4", "F4", "F4", "G4", "G4", "Cs4", "Cs4"]),
		# longo: passeio cobrindo 8 direções, fim em (5,7). 14 passos.
		# (5,5)→(6,4)→(7,3)→(7,4)→(7,5)→(6,5)→(5,5)→(5,4)→(5,3)→
		# (6,3)→(7,3)→(8,4)→(7,5)→(6,6)→(5,7).
		_make("longo", "Longo", "longo", Vector2i(5, 5),
			["D4", "D4", "F4", "F4", "G4", "G4", "Cs4", "Cs4",
			 "Ds4", "Ds4", "E4", "Fs4", "Fs4", "Fs4"]),
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
