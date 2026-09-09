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

## O vetor de `direction` é de GRID isométrico, não bússola de tela.
## Character.grid_to_world projeta (x-y, x+y), então cada vetor de grid cai
## num octante de tela diferente do que o vetor "parece" sugerir --
## ex.: (-1,-1) não é noroeste, é reto para cima.
const ICON_FOR_DIRECTION := {
	Vector2i(-1, -1): "north",
	Vector2i( 0, -1): "north_east",
	Vector2i( 1, -1): "east",
	Vector2i( 1,  0): "south_east",
	Vector2i( 1,  1): "south",
	Vector2i( 0,  1): "south_west",
	Vector2i(-1,  1): "west",
	Vector2i(-1,  0): "north_west",
}

var action_id: String = ""
var _texture: Texture2D = null
var _tint: Color = ICON_COLOR

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	# O projeto usa Nearest como filtro global (sprites pixel-art do
	# personagem). Os SVGs são rasterizados a 96x96 e desenhados bem
	# menores; com Nearest os traços finos (a barra do priority_high, os
	# membros do directions_run) somem no downscale. Filtro local ao ícone,
	# não afeta os sprites do jogo.
	texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

## Cor do glifo. Quem desenha o ícone sobre um fundo claro precisa pedir um
## tint escuro -- branco sobre tecla branca dá contraste ~1.25:1.
##
## O padrão branco NÃO serve a ninguém aqui: os três painéis que usam este ícone
## chamam set_tint() com ColorDistance.icon_tint_for(fundo), e ícone novo em
## qualquer um deles precisa fazer o mesmo.
##
## O DirectionJoystick foi o último a entrar nessa regra, e a lição é o motivo
## desta nota: ele desenhava a seta em branco fixo alegando "fundo escuro
## garantido" (fatia translúcida sobre o disco). O disco era alfa 0,30, então o
## que estava atrás da seta era o CENÁRIO -- e o Banheiro tem chão #E8E4D8.
## Fundo SUPOSTO não é fundo pintado; o disco virou opaco e a seta passou a
## seguir a mesma regra dos outros dois.
func set_tint(color: Color) -> void:
	_tint = color
	queue_redraw()

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
		if ResourceLoader.exists(path):
			_texture = load(path)
		else:
			_texture = null
			push_warning("ActionIcon: asset não encontrado em %s -- o ícone vai desenhar vazio" % path)
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
	draw_texture_rect(_texture, rect, false, _tint)
