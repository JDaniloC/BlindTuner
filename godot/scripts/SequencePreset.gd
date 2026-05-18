extends Resource
class_name SequencePreset
## Dados de uma sequência autoral: caminho de notas de movimento até um tile-alvo.

@export var id: String = ""
@export var label: String = ""
@export var size_class: String = ""  # "curto" | "medio" | "longo"
@export var start_grid: Vector2i = Vector2i.ZERO
@export var notes: Array[String] = []

## Tile final, derivado caminhando as notas a partir de start_grid.
func target_grid() -> Vector2i:
	var g := start_grid
	for n in notes:
		g += NoteMapping.direction_for(n)
	return g

## Lista de tiles visitados (um por nota), na ordem.
func path_tiles() -> Array:
	var g := start_grid
	var tiles: Array = []
	for n in notes:
		g += NoteMapping.direction_for(n)
		tiles.append(g)
	return tiles

## True se qualquer tile do caminho está num dicionário { Vector2i -> bool } de bloqueados.
func crosses_any(blocked: Dictionary) -> bool:
	for t in path_tiles():
		if blocked.get(t, false):
			return true
	return false
