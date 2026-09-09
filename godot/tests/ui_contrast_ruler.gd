extends RefCounted
## Régua de contraste da UI REAL, por ESTADO de desenho.
##
## Por que existe: quatro rodadas seguidas consertaram contraste de texto num nó
## de cada vez (o rótulo do joystick, o nome na placa de ação, o nome na tecla do
## piano, o "Editar" desabilitado) e o defeito voltou com outra roupa toda vez,
## porque nenhum teste media um estado que não fosse o de repouso. Este arquivo é
## a régua; test_ui_contrast_sweep.gd é quem a passa na cena inteira.
##
## Três decisões que a régua toma, e que são o motivo dela não ser "chamar
## contrast_ratio() e pronto":
##
## 1. Mede o que é EFETIVAMENTE PINTADO, não o item de tema. `modulate` se
##    propaga pros filhos e `self_modulate` tinge o próprio desenho; medir a cor
##    declarada na StyleBox ignora os dois e mente exatamente onde o projeto já
##    se queimou (a cor da nota já morou no modulate e tingia o rótulo junto).
## 2. Compõe ALFA sobre a cadeia de ancestrais. Um `font_disabled_color` com
##    alfa 0,5 não é a cor que chega no olho.
## 3. Reconhece CONTORNO de fonte. Quem tem contorno opaco e grosso o bastante é
##    lido contra o contorno, não contra o fundo -- é assim que o rótulo do
##    joystick sobrevive a cair sobre o cenário. Sem isso a régua reprovaria a
##    única solução que já funciona no projeto.

const ColorDistance := preload("res://scripts/ColorDistance.gd")

## WCAG 2.1 1.4.3 (texto normal) e 1.4.11 (elemento gráfico / glifo).
const TEXT_MIN := 4.5
const GLYPH_MIN := 3.0
## Contorno mais fino que isto não é halo, é serrilhado: não conta como fundo.
const MIN_OUTLINE_PX := 2

## Os 6 estados de desenho de um BaseButton, com o item de cor de fonte, o item
## de cor de ícone e a stylebox de fundo que o Godot usa em cada um.
## Espelha Button::_notification(NOTIFICATION_DRAW): `focus` não troca a
## stylebox, ela é desenhada POR CIMA da `normal` -- mas troca a cor da fonte.
const BUTTON_DRAW_STATES := [
	{"state": "normal", "font": "font_color", "icon": "icon_normal_color", "style": "normal", "focus_overlay": false},
	{"state": "hover", "font": "font_hover_color", "icon": "icon_hover_color", "style": "hover", "focus_overlay": false},
	{"state": "pressed", "font": "font_pressed_color", "icon": "icon_pressed_color", "style": "pressed", "focus_overlay": false},
	{"state": "hover_pressed", "font": "font_hover_pressed_color", "icon": "icon_hover_pressed_color", "style": "hover_pressed", "focus_overlay": false},
	{"state": "disabled", "font": "font_disabled_color", "icon": "icon_disabled_color", "style": "disabled", "focus_overlay": false},
	{"state": "focus", "font": "font_focus_color", "icon": "icon_focus_color", "style": "normal", "focus_overlay": true},
]

## Estados de um PopupMenu (a lista que o OptionButton abre). Ele NÃO é filho do
## Control na árvore -- é uma Window à parte --, então some de qualquer varredura
## que só ande em get_children(). Daí ele ter passado quatro rodadas sem tema.
const POPUP_DRAW_STATES := [
	{"state": "normal", "font": "font_color", "style": ""},
	{"state": "hover", "font": "font_hover_color", "style": "hover"},
	{"state": "disabled", "font": "font_disabled_color", "style": ""},
]

## Quem pinta o próprio fundo por Node2D/_draw() -- e não por stylebox de
## ancestral -- declara aqui o que fica atrás de cada filho seu.
##
## Existe porque o DirectionJoystick desenha as fatias como IRMÃS das setas e dos
## nomes, dentro de um Node2D: o fundo de uma seta é o polígono ao lado dela na
## ordem de desenho, e nenhuma caminhada por ancestrais consegue enxergar isso.
## A alternativa seria a régua adivinhar geometria e ordem de z; esta aqui deixa
## o conhecimento no controle, que é quem realmente sabe o que pintou.
const BACKDROP_HOOK := "contrast_backdrop_for"

static var _image_cache := {}

# --------------------------------------------------------------------------
# Composição de cor
# --------------------------------------------------------------------------

## `fg` sobre `bg` (source-over). Alfa premultiplicado na saída pra que uma
## cadeia inteira de camadas translúcidas componha sem erro acumulado.
static func over(fg: Color, bg: Color) -> Color:
	if fg.a >= 1.0:
		return Color(fg.r, fg.g, fg.b, 1.0)
	if fg.a <= 0.0:
		return bg
	var out_a := fg.a + bg.a * (1.0 - fg.a)
	if out_a <= 0.0:
		return Color(0, 0, 0, 0)
	var k := bg.a * (1.0 - fg.a)
	return Color(
		(fg.r * fg.a + bg.r * k) / out_a,
		(fg.g * fg.a + bg.g * k) / out_a,
		(fg.b * fg.a + bg.b * k) / out_a,
		out_a)

## Cor que uma StyleBox pinta ATRÁS DO TEXTO -- o miolo, não a borda.
##
## StyleBoxTexture é 9-slice: o pixel central da textura é o que fica embaixo do
## rótulo. As quatro texturas de botão do pack flat têm bordas diferentes e
## miolos idênticos, então ler qualquer outro pixel daria uma diferença que o
## texto nunca vê.
static func stylebox_fill(sb: StyleBox) -> Color:
	if sb == null:
		return Color(0, 0, 0, 0)
	if sb is StyleBoxFlat:
		return sb.bg_color if sb.draw_center else Color(0, 0, 0, 0)
	if sb is StyleBoxTexture:
		if sb.texture == null:
			return Color(0, 0, 0, 0)
		return _texture_center(sb.texture) * sb.modulate_color
	# StyleBoxEmpty, StyleBoxLine: não pintam miolo.
	return Color(0, 0, 0, 0)

static func _texture_center(tex: Texture2D) -> Color:
	var key := tex.get_rid().get_id()
	if _image_cache.has(key):
		return _image_cache[key]
	var img := tex.get_image()
	var c := Color(0, 0, 0, 0)
	if img != null:
		if img.is_compressed():
			img.decompress()
		c = img.get_pixel(int(img.get_width() / 2), int(img.get_height() / 2))
	_image_cache[key] = c
	return c

## Fração da área opaca do ícone que precisa alcançar o piso de contraste.
##
## Não é a MÉDIA dos pixels, e a diferença importa: UI_Flat_ButtonPlay01a é um
## sprite de duas tintas (163px de #FFFDF5, 84px de #000000, 25px de #FFC579), e
## a média dele dá um cinza claro que reprovaria o ícone inteiro por 2,27:1
## quando o que o olho vê é o traço preto a 21:1 sobre o botão claro. Também não
## é o MELHOR pixel, que aprovaria um ícone por um respingo. A pergunta certa é
## "que contraste um quinto do desenho alcança".
const ICON_COVERAGE := 0.20

## [[cor, peso], ...] dos pixels opacos da textura, agrupados por cor.
static func icon_buckets(tex: Texture2D) -> Array:
	var key := -tex.get_rid().get_id()
	if _image_cache.has(key):
		return _image_cache[key]
	var img := tex.get_image()
	var contagem := {}
	var total := 0
	if img != null:
		if img.is_compressed():
			img.decompress()
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var p := img.get_pixel(x, y)
				if p.a < 0.5:
					continue
				var k := p.to_rgba32()
				contagem[k] = contagem.get(k, 0) + 1
				total += 1
	var out: Array = []
	if total > 0:
		for k in contagem:
			out.append([Color.hex(k), float(contagem[k]) / float(total)])
	_image_cache[key] = out
	return out

## Contraste que pelo menos ICON_COVERAGE da área do ícone alcança contra `bg`,
## já com o modulate do estado aplicado. INF quando não há pixel opaco nenhum
## (nada desenhado, nada a cobrar).
static func icon_ratio(tex: Texture2D, modulate: Color, bg: Color) -> float:
	var buckets := icon_buckets(tex)
	if buckets.is_empty():
		return INF
	var linhas: Array = []
	for b in buckets:
		linhas.append([ColorDistance.contrast_ratio(over(b[0] * modulate, bg), bg), b[1]])
	linhas.sort_custom(func(a, b): return a[0] > b[0])
	var acumulado := 0.0
	for l in linhas:
		acumulado += l[1]
		if acumulado >= ICON_COVERAGE:
			return l[0]
	return linhas[-1][0]

# --------------------------------------------------------------------------
# Cadeia de ancestrais
# --------------------------------------------------------------------------

## Stylebox que fica atrás do texto de um botão no estado `state`, já com a
## sobreposição de foco. `hover_pressed` cai em `pressed` quando o tema não a
## define (é o que o Godot faz).
static func button_fill(btn: BaseButton, state: Dictionary) -> Color:
	var name: String = state["style"]
	if not btn.has_theme_stylebox(name):
		name = "pressed" if name == "hover_pressed" else "normal"
	var fill := stylebox_fill(btn.get_theme_stylebox(name))
	if state["focus_overlay"] and btn.has_theme_stylebox("focus"):
		fill = over(stylebox_fill(btn.get_theme_stylebox("focus")), fill)
	return fill

## O que um nó pinta de fundo por conta própria, ANTES de modulate.
##
## BaseButton entra aqui porque o SpecialActionPanel tirou o nome da nota do
## Button.text e o pôs numa Label DENTRO do botão: o fundo daquela Label é a
## stylebox do botão, e ela muda com o estado. Uma varredura que só olhasse o
## fundo do ancestral "em repouso" mediria o texto contra a placa errada em cinco
## dos seis estados.
static func _own_fill(node: Node, state: Dictionary) -> Color:
	if node is ColorRect:
		return node.color
	if node is Polygon2D:
		return node.color
	if node is BaseButton:
		return button_fill(node, state)
	if node is Panel or node is PanelContainer or node is PopupMenu:
		return stylebox_fill(node.get_theme_stylebox("panel"))
	return Color(0, 0, 0, 0)

## Fundo efetivo atrás de `node`, e o modulate acumulado que o PRÓPRIO desenho de
## `node` sofre. Devolve {"bg": Color, "tint": Color}.
##
## `modulate` vale pro nó e pra descendência; `self_modulate` só pro desenho do
## próprio nó. Compor de fora pra dentro é a única ordem que respeita os dois.
static func chain_of(node: CanvasItem, base: Color, state: Dictionary = BUTTON_DRAW_STATES[0]) -> Dictionary:
	var chain: Array[CanvasItem] = []
	var walker: Node = node
	while walker is CanvasItem:
		chain.push_front(walker)
		walker = walker.get_parent()
	var bg := base
	var tint := Color.WHITE
	for item in chain:
		tint = tint * item.modulate
		if item == node:
			continue
		var fill := _own_fill(item, state) * tint * item.self_modulate
		bg = over(fill, bg)
		if item.has_method(BACKDROP_HOOK):
			var declarado: Variant = item.call(BACKDROP_HOOK, node)
			if declarado is Color:
				bg = over((declarado as Color) * tint, bg)
	return {"bg": bg, "tint": tint * node.self_modulate}

## Ancestral BaseButton mais próximo (inclusive o próprio nó), ou null. Quem tem
## um responde a 6 fundos diferentes, não a um.
static func owning_button(node: Node) -> BaseButton:
	var walker: Node = node
	while walker != null:
		if walker is BaseButton:
			return walker
		walker = walker.get_parent()
	return null

# --------------------------------------------------------------------------
# Veredito
# --------------------------------------------------------------------------

## Razão efetiva de um texto: contra o fundo, ou contra o CONTORNO quando existe
## um grosso e opaco o bastante -- o que for melhor. Um halo escuro em volta de
## letra clara é lido contra o halo; foi assim que o rótulo do joystick resolveu
## cair sobre cenário de cor imprevisível.
static func text_ratio(ink: Color, bg: Color, outline: Color, outline_px: int) -> float:
	var r := ColorDistance.contrast_ratio(over(ink, bg), bg)
	if outline_px >= MIN_OUTLINE_PX and outline.a > 0.0:
		var halo := over(outline, bg)
		r = maxf(r, ColorDistance.contrast_ratio(over(ink, halo), halo))
	return r

static func glyph_ratio(ink: Color, bg: Color) -> float:
	return ColorDistance.contrast_ratio(over(ink, bg), bg)

static func hex(c: Color) -> String:
	return "#" + c.to_html(false) + ("" if is_equal_approx(c.a, 1.0) else " a%.2f" % c.a)
