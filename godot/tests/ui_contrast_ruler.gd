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
##
## Texto e glifo não são tudo o que carrega informação. Duas classes inteiras
## entraram depois, cada uma porque um defeito passou por baixo da régua:
##
## 4. SUPERFÍCIE DE COR (ColorRect/Polygon2D). O chip do NotePanel é o único
##    portador de informação da tela na pista 2, e ficou em 1,06:1 contra o painel
##    em 28 das 36 combinações nota x esquema sem que nada acusasse -- a régua não
##    tinha ramo para quem informa pela cor da própria superfície, que é
##    exatamente o que o WCAG 1.4.11 cobre.
## 5. ANEL DE FOCO. button_fill() compõe o MIOLO da stylebox de foco, que é vazio
##    numa caixa draw_center=false: a linha "focus" media o mesmo fundo da linha
##    "normal" e o anel nunca era sujeito de medição nenhuma. Num aparelho de
##    toque o foco fica onde o dedo passou, então é indicador de repouso.

const ColorDistance := preload("res://scripts/ColorDistance.gd")

## WCAG 2.1 1.4.3 (texto normal) e 1.4.11 (elemento gráfico / glifo).
const TEXT_MIN := 4.5
const GLYPH_MIN := 3.0
## Contorno mais fino que isto não é halo, é serrilhado: não conta como fundo.
const MIN_OUTLINE_PX := 2
## Borda mais fina que isto não é anel de foco, é fio: não conta como indicador.
## Mesmo piso que o tema já exige de Button/focus.
const MIN_RING_PX := 2
## Quanto um ancestral precisa transbordar da superfície para APARECER em volta
## dela, e quanto pode transbordar para ainda ser MOLDURA dela em vez de painel.
## As três molduras do jogo (swatch da tela de esquemas, preview do modal, chip do
## NotePanel) usam 3px de cada lado: 2 é o mesmo piso do contorno de fonte (abaixo
## disso é serrilhado, não borda) e 8 dá espaço para uma quarta moldura sem deixar
## passar por moldura o que é PAINEL com a amostra solta dentro.
const FRAME_MIN_PX := 2.0
const FRAME_HUG_PX := 8.0

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

## Leituras de pixel de textura, uma entrada por TEXTURA -- não por RID.
##
## A chave era `tex.get_rid().get_id()` para o pixel central e o NEGATIVO do mesmo
## id para as faixas do ícone, num dicionário só. Duas coisas quebram nisso:
##
## (1) chave numérica não segura referência nenhuma, então a entrada sobrevive à
##     textura que mediu e passa a descrever um objeto que não existe mais;
## (2) uma Texture2D sem RID próprio -- Resource.get_rid() devolve RID vazio, id 0
##     -- faz 0 e -0 caírem na MESMA entrada, e icon_buckets() lê o Color que
##     _texture_center() gravou.
##
## O (2) foi reproduzido aqui antes da correção: "Trying to return value of type
## Color from a function whose return type is Array", erro que o GDScript engole
## devolvendo array VAZIO -- e array vazio era justamente o "nada desenhado, nada a
## cobrar" que aprovava a medição em silêncio. Já o id REPETIDO por reciclagem, que
## seria o pior caso do (1), não foi reproduzido: no Godot 4.6 o id carrega um
## contador que só cresce, então RID livre devolve o índice mas não o mesmo id.
##
## Chaveado pelo objeto: identidade em vez de número, as duas leituras em campos
## separados da mesma entrada (não há mais dois espaços de chave para colidir), e a
## chave mantém a textura viva enquanto a medição durar.
static var _leituras := {}

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

## Pixel central e faixas de cor de uma textura: {"ok", "centro", "faixas"}.
##
## `ok` é false quando get_image() não devolveu imagem. Não é hipótese de
## laboratório: godot/**/*.import é gitignored e nenhum CI roda esta suíte, então
## clone frio é o caso real. Quem chama tem que ACUSAR isso -- medir contra um
## transparente inventado faz o texto de botão cair para as cores do cenário e a
## suíte fica verde com a superfície do botão nunca medida.
static func _read(tex: Texture2D) -> Dictionary:
	if tex == null:
		return {"ok": false, "centro": Color(0, 0, 0, 0), "faixas": []}
	if _leituras.has(tex):
		return _leituras[tex]
	var img: Image = tex.get_image()
	var out := {"ok": img != null, "centro": Color(0, 0, 0, 0), "faixas": []}
	if img != null:
		if img.is_compressed():
			img.decompress()
		out["centro"] = img.get_pixel(int(img.get_width() / 2), int(img.get_height() / 2))
		out["faixas"] = _buckets_of(img)
	_leituras[tex] = out
	return out

## O cache vale por teste, não pelo run: textura gerada em código (o trilho de
## matiz do modal) é recriada com outro conteúdo, e servir a leitura da anterior
## seria a mesma falha dependente de ordem que a chave por RID tinha.
static func forget_reads() -> void:
	_leituras.clear()

static func texture_is_readable(tex: Texture2D) -> bool:
	return _read(tex).ok

## Descrição das texturas que a régua TENTOU ler e não conseguiu. Quem varre
## acrescenta isto às reprovações: é pré-condição da medição, não detalhe.
static func unreadable_textures() -> Array[String]:
	var out: Array[String] = []
	for tex in _leituras:
		if not _leituras[tex].ok:
			var t: Texture2D = tex
			out.append(t.resource_path if t.resource_path != "" else str(t))
	return out

static func _texture_center(tex: Texture2D) -> Color:
	return _read(tex).centro

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
	return _read(tex).faixas

static func _buckets_of(img: Image) -> Array:
	var contagem := {}
	var total := 0
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
	return out

## Contraste que pelo menos ICON_COVERAGE da área do ícone alcança contra `bg`,
## já com o modulate do estado aplicado. INF quando não há pixel opaco nenhum
## (nada desenhado, nada a cobrar).
static func icon_ratio(tex: Texture2D, modulate: Color, bg: Color) -> float:
	# Textura ilegível não é "nada a cobrar", é medição que não aconteceu: devolve
	# o PIOR valor possível para reprovar alto. Enquanto isto era INF, um ícone que
	# falhasse ao carregar passava com nota máxima.
	if not _read(tex).ok:
		return 0.0
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
# Superfície de cor
# --------------------------------------------------------------------------

## O que `node` PINTA de si mesmo e o que fica atrás: {"fill", "bg"}.
static func painted_fill(node: CanvasItem, base: Color, state: Dictionary) -> Dictionary:
	var ch := chain_of(node, base, state)
	return {"fill": _own_fill(node, state) * ch.tint, "bg": ch.bg}

## O quanto `fora` transborda de `dentro`, pelo lado mais apertado dos quatro.
## Negativo quando `fora` não circunda `dentro`.
static func _folga(fora: Rect2, dentro: Rect2) -> float:
	return minf(
		minf(dentro.position.x - fora.position.x, dentro.position.y - fora.position.y),
		minf(fora.end.x - dentro.end.x, fora.end.y - dentro.end.y))

## Cores que APARECEM em volta de uma superfície de cor, dela para fora:
## [{"cor", "folga", "quem"}, ...].
##
## Existe porque uma amostra de cor não é achável só por si mesma. O chip do
## NotePanel em #0D4A74 fica a 1,87:1 da própria moldura escura, e isso não é
## defeito: moldura escura colada em chip escuro é UM BLOCO escuro, e um bloco
## escuro é exatamente o que se acha num painel claro. O que precisa existir é uma
## borda visível em algum lugar entre a cor e o que a cerca -- medir só a
## superfície contra o fundo imediato reprovaria a solução que o projeto já usa em
## três telas.
##
## Dois cuidados, e os dois vêm de mutação que passava sem eles:
##
## - APARECER é ter área própria. Um ancestral do mesmo tamanho da amostra pinta
##   atrás dela e não se vê; contá-lo como fundo mediria a amostra contra uma cor
##   que o olho nunca encontra. Por isso a folga mínima -- e ela é a mesma do
##   contorno de fonte: abaixo de 2px não é borda, é serrilhado.
## - MOLDURA não é PAINEL. A borda de um painel largo é visível e não diz nada
##   sobre onde a amostra começa. Quem decide isso é surface_edge, que para de
##   subir depois do primeiro anel que transborda mais que FRAME_HUG_PX.
static func visible_rings(node: CanvasItem, base: Color, state: Dictionary) -> Array:
	var p := painted_fill(node, base, state)
	var out: Array = [{"cor": over(p.fill, p.bg), "folga": 0.0, "quem": "superfície"}]
	if not (node is Control):
		return out
	var dentro: Control = node as Control
	var walker: Node = node.get_parent()
	while walker is Control:
		var c := walker as Control
		var pf := painted_fill(c, base, state)
		if pf.fill.a > 0.0:
			var folga := _folga(c.get_global_rect(), dentro.get_global_rect())
			if folga >= FRAME_MIN_PX:
				out.append({"cor": over(pf.fill, pf.bg), "folga": folga, "quem": "moldura"})
				dentro = c
		walker = c.get_parent()
	return out

## Melhor borda visível entre dois anéis CONSECUTIVOS -- e qual delas.
##
## Só conta par cujas duas cores fecham opacas: contra fundo que a régua não
## enxerga não há medição, e inventar uma é pior que não medir. `ratio` = -1.0
## quando nenhum par é mensurável; quem varre trata isso como "não medido", não
## como aprovado -- o que segura essa fronteira é o censo por tipo.
static func surface_edge(rings: Array) -> Dictionary:
	var melhor := -1.0
	var quem := ""
	var fill := Color(0, 0, 0, 0)
	var bg := Color(0, 0, 0, 0)
	for i in range(rings.size() - 1):
		var dentro: Dictionary = rings[i]
		var fora: Dictionary = rings[i + 1]
		if dentro.cor.a < 0.999 or fora.cor.a < 0.999:
			break
		var r: float = ColorDistance.contrast_ratio(dentro.cor, fora.cor)
		if r > melhor:
			melhor = r
			quem = "superfície" if i == 0 else "moldura"
			fill = dentro.cor
			bg = fora.cor
		# Daqui pra fora quem cerca a amostra é PAINEL, não moldura dela: a borda
		# de um painel largo é visível e não diz onde o quadrado começa.
		if fora.folga > FRAME_HUG_PX:
			break
	return {"ratio": melhor, "quem": quem, "fill": fill, "bg": bg}

# --------------------------------------------------------------------------
# Anel de foco
# --------------------------------------------------------------------------

## Espessura e cor do anel de foco de um botão: {"px", "color", "tipo"}.
##
## button_fill() NÃO serve para isto: ela compõe o MIOLO da stylebox de foco, que é
## vazio numa caixa draw_center=false. O anel é só borda, e borda não entra em
## nenhuma composição de fundo -- por isso a linha "focus" da varredura media
## exatamente o mesmo fundo da linha "normal" e o anel nunca era medido.
##
## px = a MENOR das quatro bordas: anel que só existe de um lado não circunda nada.
static func focus_ring(btn: BaseButton, tint: Color) -> Dictionary:
	if not btn.has_theme_stylebox("focus"):
		return {"px": 0, "color": Color(0, 0, 0, 0), "tipo": "sem stylebox de foco"}
	var sb := btn.get_theme_stylebox("focus")
	if sb is StyleBoxFlat:
		var f := sb as StyleBoxFlat
		var px: int = mini(mini(f.border_width_left, f.border_width_top),
			mini(f.border_width_right, f.border_width_bottom))
		return {"px": px, "color": f.border_color * tint, "tipo": "borda"}
	# StyleBoxTexture/Empty/Line: a régua não sabe dizer que cor tem a borda. Devolve
	# espessura zero de propósito -- quem varre reprova, em vez de aprovar por não
	# ter conseguido medir.
	return {"px": 0, "color": Color(0, 0, 0, 0), "tipo": sb.get_class()}

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
