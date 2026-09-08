extends Control
## Desenha um ícone procedural representando uma ação especial.
## Sem dependência de fonte/sprite — usa draw_line/draw_arc.

const ICON_COLOR := Color.WHITE
const LINE_WIDTH := 4.0
const RADIUS_FRAC := 0.35  # raio do ícone relativo ao menor lado do Control

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

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func set_action(id: String) -> void:
	action_id = id
	queue_redraw()

## Nome do ícone (sem extensão) da nota: ação pelo action_id, movimento pela
## direção. Função pura -- não depende de nó nem de textura carregada.
static func icon_name_for_note(note_key: String) -> String:
	if NoteMapping.is_action_note(note_key):
		return ICON_FOR_ACTION.get(NoteMapping.action_id_for(note_key), "")
	return ICON_FOR_DIRECTION.get(NoteMapping.direction_for(note_key), "")

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * RADIUS_FRAC
	match action_id:
		"pegar":    _draw_pegar(c, r)
		"interagir": _draw_interagir(c, r)
		"correr":  _draw_correr(c, r)
		"pular":   _draw_pular(c, r)

## Seta vertical apontando para baixo + linha do chão. Símbolo "pegar do chão".
func _draw_pegar(c: Vector2, r: float) -> void:
	var top := c + Vector2(0, -r)
	var bottom := c + Vector2(0, r * 0.4)
	draw_line(top, bottom, ICON_COLOR, LINE_WIDTH, true)
	draw_line(bottom, bottom + Vector2(-r * 0.5, -r * 0.4), ICON_COLOR, LINE_WIDTH, true)
	draw_line(bottom, bottom + Vector2( r * 0.5, -r * 0.4), ICON_COLOR, LINE_WIDTH, true)
	draw_line(c + Vector2(-r, r * 0.8), c + Vector2(r, r * 0.8), ICON_COLOR, LINE_WIDTH, true)

## Símbolo "!" — exclamação para "interagir / aqui!".
func _draw_interagir(c: Vector2, r: float) -> void:
	# Linha vertical (corpo do !)
	draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, r * 0.2), ICON_COLOR, LINE_WIDTH, true)
	# Ponto (base do !) — circulo pequeno preenchido
	draw_circle(c + Vector2(0, r * 0.6), LINE_WIDTH * 0.9, ICON_COLOR)

## Três linhas horizontais (motion) + chevron » direita.
func _draw_correr(c: Vector2, r: float) -> void:
	var spacing := r * 0.35
	draw_line(c + Vector2(-r,          -spacing), c + Vector2(r * 0.55, -spacing), ICON_COLOR, LINE_WIDTH, true)
	draw_line(c + Vector2(-r * 0.85,    0      ), c + Vector2(r * 0.75,  0      ), ICON_COLOR, LINE_WIDTH, true)
	draw_line(c + Vector2(-r,           spacing), c + Vector2(r * 0.55,  spacing), ICON_COLOR, LINE_WIDTH, true)
	var tip := c + Vector2(r, 0)
	draw_line(c + Vector2(r * 0.55, -spacing - r * 0.15), tip, ICON_COLOR, LINE_WIDTH, true)
	draw_line(c + Vector2(r * 0.55,  spacing + r * 0.15), tip, ICON_COLOR, LINE_WIDTH, true)

## Arco semicircular pra cima + setinha no topo + linha do chão.
func _draw_pular(c: Vector2, r: float) -> void:
	var arc_center := c + Vector2(0, r * 0.45)
	draw_arc(arc_center, r, PI, TAU, 24, ICON_COLOR, LINE_WIDTH, true)
	var top := arc_center + Vector2(0, -r)
	draw_line(top + Vector2(-r * 0.25, r * 0.2), top, ICON_COLOR, LINE_WIDTH, true)
	draw_line(top + Vector2( r * 0.25, r * 0.2), top, ICON_COLOR, LINE_WIDTH, true)
	draw_line(c + Vector2(-r, r * 0.5), c + Vector2(r, r * 0.5), ICON_COLOR, LINE_WIDTH, true)
