extends Node
## Autoload — catálogo dos esquemas de cor fixos. Não guarda qual está ativo
## (isso é ColorSchemeSettings); só sabe quais existem e quais cores têm.
##
## Não existe convenção nota->cor com base científica (cromestesia é
## idiossincrática; Boomwhacker é convenção comercial). A única correlação com
## lastro empírico é altura<->luminosidade, aplicada dentro de cada esquema.

const SCHEME_IDS := ["classico", "pedagogico", "alto_contraste"]

const DISPLAY_NAMES := {
	"classico": "Clássico",
	"pedagogico": "Pedagógico",
	"alto_contraste": "Alto Contraste",
}

## Arco-íris com a luminância corrigida: os três verdes viraram escuro/médio/claro
## e a cauda azul->azul->violeta virou ciano->azul claro->violeta->rosa. Todos os
## 11 pares adjacentes ficam >= 1.62:1 de contraste.
const PEDAGOGICO := [
	"#9C000A", "#CE3000", "#EB6D00", "#F8AD00", "#FFF200", "#009218",
	"#00BC58", "#00ECA6", "#00A0C1", "#81C8FF", "#9D84FF", "#FFADFB",
]

## 7 matizes (um por letra) escolhidos com consciência de protanopia/deuteranopia,
## e cada sustenido é a mesma letra com L* +10 -- lê como "a letra, mais clara",
## não como uma 8ª cor independente.
const ALTO_CONTRASTE := [
	"#0D4A74", "#126296", "#9B4507", "#C1580C", "#168763", "#DC68AC",
	"#F686C5", "#E29E18", "#F0BE76", "#2FD9F4", "#A5EEFE", "#EAEA26",
]

func display_name(scheme_id: String) -> String:
	return DISPLAY_NAMES.get(scheme_id, scheme_id)

## 12 cores do esquema, em ordem cromática (C4..B4). Array vazio se o id não existe.
func colors_for(scheme_id: String) -> Array[Color]:
	match scheme_id:
		"classico": return _classico()
		"pedagogico": return _from_hex(PEDAGOGICO)
		"alto_contraste": return _from_hex(ALTO_CONTRASTE)
	var vazio: Array[Color] = []
	return vazio

## Lê as cores de fábrica de NoteMapping em vez de redigitá-las -- fonte única.
func _classico() -> Array[Color]:
	var out: Array[Color] = []
	for key in NoteMapping.NOTES.keys():
		out.append(NoteMapping.default_color_for(key))
	return out

func _from_hex(hexes: Array) -> Array[Color]:
	var out: Array[Color] = []
	for h in hexes:
		out.append(Color(h))
	return out

## Esta cor é a DE FÁBRICA desta nota, em algum esquema fixo?
##
## É por ÍNDICE, não "existe em alguma paleta": a cor do Dó# não é cor de fábrica
## do Dó. O editor usa isto para saber se a cor que a nota tem agora tem álibi
## (veio da paleta embarcada) ou é escolha do jogador -- sem a distinção, um
## conflito que o próprio jogador gravou virava desculpa para nunca mais avisar
## sobre ele.
func is_stock_color(chromatic_index: int, color: Color) -> bool:
	for id in SCHEME_IDS:
		var cores := colors_for(id)
		if chromatic_index < 0 or chromatic_index >= cores.size():
			continue
		if cores[chromatic_index] == color:
			return true
	return false

## Válido = exatamente 12 cores opacas. Usado na carga do disco e nos testes.
func is_valid_palette(colors: Array) -> bool:
	if colors.size() != 12:
		return false
	for c in colors:
		if not (c is Color) or c.a < 1.0:
			return false
	return true
