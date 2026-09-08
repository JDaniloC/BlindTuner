extends Control
## Desenha o ícone de uma nota -- seta direcional (movimento) ou pictograma
## (ação). Usa os SVGs do Material Symbols importados em res://assets/ui/icons.
## Os desenhos procedurais anteriores (draw_line/draw_arc) foram substituídos:
## no playtest, "correr" e "pular" não liam como as ações que representavam.

const ICON_COLOR := Color.WHITE
const ICON_FRAC := 0.7  # lado do ícone relativo ao menor lado do Control

const ICON_DIR := "res://assets/ui/icons/"

## Ícone escolhido para cada ação (validado com o usuário na maquete visual).
const ICON_FOR_ACTION := {
	"interagir": "priority_high",
	"pegar": "back_hand",
	"correr": "directions_run",
	"pular": "keyboard_double_arrow_up",
}

## Seta direcional por vetor de direção. 0,-1 é norte (y cresce pra baixo).
const ICON_FOR_DIRECTION := {
	Vector2i( 0, -1): "north",
	Vector2i( 1, -1): "north_east",
	Vector2i( 1,  0): "east",
	Vector2i( 1,  1): "south_east",
	Vector2i( 0,  1): "south",
	Vector2i(-1,  1): "south_west",
	Vector2i(-1,  0): "west",
	Vector2i(-1, -1): "north_west",
}

var action_id: String = ""
var _texture: Texture2D = null

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

## Compatibilidade: chamadores antigos passam o action_id direto.
func set_action(id: String) -> void:
	action_id = id
	_set_texture_by_name(ICON_FOR_ACTION.get(id, ""))

## Caminho novo: aceita qualquer uma das 12 notas (ação ou movimento).
func set_note(note_key: String) -> void:
	if NoteMapping.is_action_note(note_key):
		action_id = NoteMapping.action_id_for(note_key)
	else:
		action_id = ""
	_set_texture_by_name(icon_name_for_note(note_key))

func _set_texture_by_name(icon_name: String) -> void:
	if icon_name == "":
		_texture = null
	else:
		var path := ICON_DIR + icon_name + ".svg"
		_texture = load(path) if ResourceLoader.exists(path) else null
	queue_redraw()

## Nome do ícone (sem extensão) da nota: ação pelo action_id, movimento pela
## direção. Função pura -- não depende de nó nem de textura carregada.
static func icon_name_for_note(note_key: String) -> String:
	if NoteMapping.is_action_note(note_key):
		return ICON_FOR_ACTION.get(NoteMapping.action_id_for(note_key), "")
	return ICON_FOR_DIRECTION.get(NoteMapping.direction_for(note_key), "")

func _draw() -> void:
	if _texture == null:
		return
	var side := minf(size.x, size.y) * ICON_FRAC
	var rect := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
	# O SVG é branco; o 4º argumento tinge pra qualquer cor sem precisar de
	# outra cópia do asset.
	draw_texture_rect(_texture, rect, false, ICON_COLOR)
