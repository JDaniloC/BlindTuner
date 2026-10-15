extends GutTest
## Varredura de contraste: TODO texto, TODO glifo, TODA superfície de cor e TODO
## anel de foco da UI real, em TODO estado de desenho -- inclusive o ARMADO --,
## contra o que é EFETIVAMENTE PINTADO atrás dele.
##
## Por que este arquivo existe. Quatro rodadas seguidas consertaram contraste um
## nó por vez -- o rótulo do joystick, o nome na placa de ação, o nome na tecla
## do piano, o "Editar" desabilitado -- e o defeito voltou com outra roupa toda
## vez. Os 516 testes que havia não podiam pegar nenhuma delas: test_ui_theme.gd
## conferia que as styleboxes EXISTEM e que font_color é escura, e as seis
## medições de contraste espalhadas pela suíte olhavam sempre o estado de
## REPOUSO. Nenhuma enumerava estado. Enquanto isso valesse, a quinta ocorrência
## era questão de tempo -- e ela chegou: font_hover_color, font_pressed_color,
## font_hover_pressed_color, font_focus_color e font_disabled_color caíam no tema
## padrão do Godot (desenhado pra skin ESCURA, tinta quase branca) sobre as
## texturas quase brancas do pack flat. 29 nós em 1,02:1 a 1,14:1.
##
## Dois desses estados nem são transitórios: com emulate_mouse_from_touch, tocar
## um botão dá FOCO a ele e o foco fica -- o rótulo do último botão tocado
## permanecia em 1,10:1. E "Pistas nos controles" nasce com button_pressed=true,
## ou seja, em 1,02:1 antes de qualquer interação.
##
## O que a varredura cobre: os dois mundos com a mesma régua -- o que está sob
## blindtuner_theme.tres (GameHUD, ColorSchemeScreen, NoteColorModal, NotePanel)
## e o que é IRMÃO do GameHUD na CanvasLayer e portanto não herda tema nenhum
## (PianoInput, SpecialActionPanel, DirectionJoystick, PitchScrollInput), mais a
## lista do OptionButton, que não é filha de ninguém (é uma Window à parte).
##
## E a sexta ocorrência chegou do mesmo jeito das outras cinco -- num nó que a
## varredura não alcançava --, então três buracos foram fechados de uma vez:
##
## - SUPERFÍCIE DE COR. O chip do NotePanel é o único portador de informação da
##   tela na pista 2 e ficou em 1,06:1 contra o painel em 28 das 36 combinações
##   nota x esquema. A varredura media texto e glifo; quem informa pela cor da
##   própria superfície não tinha ramo nenhum.
## - ANEL DE FOCO fora do tema. O teste do anel olhava só Button/focus e
##   OptionButton/focus do .tres -- e as 12 teclas do piano e as 4 placas de ação,
##   que são o que o jogador mais toca, não usam o tema. Ficavam no `focus` padrão
##   do Godot: borda #CCCCCC de 2px, 1,28:1 sobre a tecla branca.
## - ESTADO ARMADO. A palavra "armed" não aparecia neste arquivo: a varredura
##   montava o Playground e nunca chamava on_armed_state_changed, justamente o
##   estado que ColorDistance documenta como o pior (3,70:1).
##
## A régua em si mora em ui_contrast_ruler.gd.

const Ruler := preload("res://tests/ui_contrast_ruler.gd")
const ColorDistance := preload("res://scripts/ColorDistance.gd")
const ActionIconScript := preload("res://scripts/ActionIcon.gd")
const PlaygroundScene := preload("res://scenes/Playground.tscn")
const ColorSchemeScreenScene := preload("res://scenes/ColorSchemeScreen.tscn")
const LevelSelectScreenScene := preload("res://scenes/LevelSelectScreen.tscn")
const PauseModalScene := preload("res://scenes/PauseModal.tscn")

var _screen: SubViewport
var _saved_scheme: String
var _saved_cues: bool
## Quantas medições a última varredura fez, por controle. Uma varredura que não
## alcança nada passa com folga e não protege nada -- ver
## test_the_sweep_actually_measures_every_control.
var _censo: Dictionary = {}
## O mesmo censo, por TIPO de medição (texto, glifo, ícone, anel, superfície).
## Separado do de cima porque é o que segura as classes novas: uma superfície de
## cor que saia de dentro de um painel deixa de ser mensurável e simplesmente
## SOME da varredura, sem reprovar nada -- o piso por tipo é quem acusa.
var _censo_tipo: Dictionary = {}

func before_each() -> void:
	_saved_scheme = ColorSchemeSettings.scheme_id
	_saved_cues = ColorSchemeSettings.control_cues
	ColorSchemeSettings.reset_to_defaults()
	# Cache de leitura de textura vale por teste: o trilho de matiz do modal é
	# gerado em código e recriado a cada montagem.
	Ruler.forget_reads()

func after_each() -> void:
	# reset antes de restaurar: um teste daqui grava uma paleta personalizada
	# hostil, e ela vazaria para os próximos arquivos da suíte.
	ColorSchemeSettings.reset_to_defaults()
	ColorSchemeSettings.set_scheme(_saved_scheme)
	ColorSchemeSettings.set_control_cues(_saved_cues)

# --------------------------------------------------------------------------
# Montagem
# --------------------------------------------------------------------------

## Mesmo truque de test_playground_input_layout.gd: SubViewport no tamanho de
## PROJETO. A janela raiz em headless vem 1280x1280 e daria folga que o aparelho
## não tem.
func _mount(scene: PackedScene) -> Node:
	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	_screen = SubViewport.new()
	_screen.size = Vector2i(w, h)
	add_child_autofree(_screen)
	var node := scene.instantiate()
	_screen.add_child(node)
	return node

## Fundos possíveis atrás de quem NÃO se apoia numa superfície opaca de UI.
## Os controles são irmãos do GameHUD dentro da CanvasLayer: o que fica atrás
## deles é o cenário, e o jogo tem três. Medir contra um cinza inventado deixaria
## passar justamente o Banheiro, que é claro (#E8E4D8).
func _backdrops() -> Array[Color]:
	var out: Array[Color] = []
	for tema in SceneryThemes.ALL:
		out.append(tema.floor_a)
		out.append(tema.floor_b)
		out.append(tema.wall_top)
		out.append(tema.wall_front)
	return out

## Põe texto em tudo que só ganha texto em tempo de execução, e abre os painéis
## que nascem escondidos. Sem isto a varredura pularia o painel de stats, o aviso
## de cor parecida, a confirmação de "restaurar" e o modal inteiro -- que é
## exatamente onde moram 6 dos 29 botões quebrados.
## Chama os setters REAIS em vez de enfiar texto em toda Label vazia: uma Label
## que fica vazia de propósito (o nome da fatia com as pistas desligadas) não
## exibe texto nenhum e medi-la seria inventar uma falha.
func _populate(root: Node) -> void:
	for node in _all_nodes(root):
		if node.has_method("show_stats"):
			node.show_stats({"first_try_hits": 1, "total_trips": 1, "elapsed_sec": 1.0})
		if node.has_method("set_progress"):
			node.set_progress(1, 8)
		if node.has_method("display_note"):
			node.display_note("C4")

func _all_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var pilha: Array[Node] = [root]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		out.append(n)
		for c in n.get_children():
			pilha.append(c)
	return out

func _path_of(node: Node) -> String:
	var partes: Array[String] = []
	var w: Node = node
	while w != null and not (w is SubViewport):
		partes.push_front(w.name)
		w = w.get_parent()
	return "/".join(partes)

# --------------------------------------------------------------------------
# Medição
# --------------------------------------------------------------------------

## Pior razão de `ink` contra `bg`. Quando a cadeia não fecha em superfície opaca
## (o controle está sobre o cenário), mede contra TODOS os cenários e devolve o
## pior -- não a média, não um representativo.
func _worst(ink: Color, bg: Color, outline: Color, outline_px: int, is_text: bool) -> Dictionary:
	var candidatos: Array[Color] = [bg]
	if bg.a < 0.999:
		candidatos = []
		for atras in _backdrops():
			candidatos.append(Ruler.over(bg, atras))
	var pior := INF
	var pior_bg := bg
	for c in candidatos:
		var r := Ruler.text_ratio(ink, c, outline, outline_px) if is_text else Ruler.glyph_ratio(ink, c)
		if r < pior:
			pior = r
			pior_bg = c
	return {"ratio": pior, "bg": pior_bg}

func _falha(node: Node, estado: String, tipo: String, ink: Color, r: Dictionary, minimo: float) -> Dictionary:
	return {
		"path": _path_of(node), "estado": estado, "tipo": tipo,
		"ratio": r.ratio, "min": minimo,
		"ink": Ruler.hex(ink), "bg": Ruler.hex(r.bg),
	}

## Percorre a árvore e devolve TODAS as reprovações. Devolver lista em vez de
## assertar item a item é de propósito: 29 falhas idênticas viram uma mensagem
## legível em vez de 29 linhas de ruído, e a mensagem diz de onde vem a cor.
func _sweep(root: Node) -> Array:
	var falhas: Array = []
	_censo = {}
	_censo_tipo = {}
	for node in _all_nodes(root):
		if not (node is CanvasItem):
			continue
		var dono := Ruler.owning_button(node)
		var estados := Ruler.BUTTON_DRAW_STATES if dono != null else [Ruler.BUTTON_DRAW_STATES[0]]
		for st in estados:
			var ch := Ruler.chain_of(node, Color(0, 0, 0, 0), st)
			var bg: Color = ch.bg
			if node is BaseButton:
				bg = Ruler.over(Ruler.button_fill(node, st) * ch.tint, ch.bg)
			_medir(node, st, bg, ch.tint, falhas)
	# Pré-condição, não detalhe: uma textura que não abre faz a régua medir o texto
	# do botão contra o CENÁRIO em vez da superfície do botão, e todo o resto passa.
	# Entra na mesma lista de reprovações para não depender de ninguém lembrar de
	# conferir um flag.
	for caminho in Ruler.unreadable_textures():
		falhas.append({
			"path": caminho, "estado": "-", "tipo": "textura ilegível",
			"ratio": 0.0, "min": Ruler.GLYPH_MIN, "ink": "-", "bg": "-",
		})
	return falhas

## Nome do controle "de topo" a que um nó pertence -- o filho direto da
## CanvasLayer (Playground) ou a raiz da cena. É por ele que o censo agrupa.
func _controle_de(node: Node) -> String:
	var w: Node = node
	while w != null:
		var pai := w.get_parent()
		if pai == null or pai is CanvasLayer or pai is SubViewport:
			return w.name
		w = pai
	return "?"

func _conta(node: Node, tipo: String) -> void:
	var k := _controle_de(node)
	_censo[k] = _censo.get(k, 0) + 1
	_censo_tipo[tipo] = _censo_tipo.get(tipo, 0) + 1

func _medir(node: CanvasItem, st: Dictionary, bg: Color, tint: Color, falhas: Array) -> void:
	if node is BaseButton:
		if st.focus_overlay:
			_medir_anel(node, st, bg, tint, falhas)
		if node.text != "":
			_conta(node, "texto")
			var ink: Color = node.get_theme_color(st.font) * tint
			var r := _worst(ink, bg, _outline_color(node, tint), _outline_px(node), true)
			if r.ratio < Ruler.TEXT_MIN:
				falhas.append(_falha(node, st.state, "texto", ink, r, Ruler.TEXT_MIN))
		if node is Button and node.icon != null:
			_medir_icone(node, node.icon, node.get_theme_color(st.icon) * tint, bg, st.state, falhas)
		if node is OptionButton and node.has_theme_icon("arrow"):
			# O Godot só modula a seta pela cor da fonte quando a constante
			# modulate_arrow está ligada; senão desenha a textura como ela é.
			var mod := Color.WHITE
			if node.has_theme_constant("modulate_arrow") and node.get_theme_constant("modulate_arrow") != 0:
				mod = node.get_theme_color(st.font)
			_medir_icone(node, node.get_theme_icon("arrow"), mod * tint, bg, st.state + "/seta", falhas)
	elif node is Label:
		if node.text == "":
			return
		_conta(node, "texto")
		var ink: Color = node.get_theme_color("font_color") * tint
		var r := _worst(ink, bg, _outline_color(node, tint), _outline_px(node), true)
		if r.ratio < Ruler.TEXT_MIN:
			falhas.append(_falha(node, st.state, "texto", ink, r, Ruler.TEXT_MIN))
	elif node.get_script() == ActionIconScript:
		if node._texture == null:
			return
		_conta(node, "glifo")
		var ink: Color = node._tint * tint
		var r := _worst(ink, bg, Color(0, 0, 0, 0), 0, false)
		if r.ratio < Ruler.GLYPH_MIN:
			falhas.append(_falha(node, st.state, "glifo", ink, r, Ruler.GLYPH_MIN))
	elif node is ColorRect or node is Polygon2D:
		_medir_superficie(node, st, falhas)

## Superfície que informa pela PRÓPRIA COR (WCAG 1.4.11, mesmo piso do glifo): o
## chip da nota no HUD, o swatch da tela de esquemas, o preview do modal.
##
## Mede a melhor BORDA VISÍVEL entre a cor e o que está em volta, e não a cor
## contra o fundo imediato: o chip #0D4A74 fica a 1,87:1 da própria moldura escura
## e isso não é defeito -- moldura escura colada em chip escuro é um bloco escuro
## só, e um bloco escuro é o que se acha num painel claro. Ver Ruler.visible_rings.
##
## Só entra superfície que tenha um par de cores OPACAS para comparar -- ou seja,
## cujo entorno a régua enxerga. É por isso que as fatias do joystick e o cenário
## ficam de fora, e não por serem Polygon2D: são polígonos irmãos
## dentro de um Node2D, o fundo de um é o vizinho na ordem de desenho, e nenhuma
## caminhada por ancestrais chega lá. Quem sabe essa adjacência é o próprio
## controle -- test_direction_joystick mede a seta contra a fatia composta sobre o
## disco, test_pitch_scroll_input mede a fita contra a madeira que o _draw() pinta.
## O que protege ESTA fronteira de virar buraco de novo é o censo por tipo: uma
## amostra que saia de dentro do painel deixa de ser mensurável e derruba o piso.
func _medir_superficie(node: CanvasItem, st: Dictionary, falhas: Array) -> void:
	# Alfa 0 não é superfície de cor: o ScreenFlash do Playground nasce assim e só
	# existe durante o feedback de erro.
	if Ruler.painted_fill(node, Color(0, 0, 0, 0), st).fill.a <= 0.0:
		return
	var borda := Ruler.surface_edge(Ruler.visible_rings(node, Color(0, 0, 0, 0), st))
	if borda.ratio < 0.0:
		return
	_conta(node, "superfície")
	if borda.ratio < Ruler.GLYPH_MIN:
		falhas.append(_falha(node, st.state, "superfície/%s" % borda.quem, borda.fill,
			{"ratio": borda.ratio, "bg": borda.bg}, Ruler.GLYPH_MIN))

## Anel de foco do botão, contra o preenchimento do botão que ele marca.
##
## Num aparelho de toque o foco NÃO é transitório: com emulate_mouse_from_touch,
## tocar um botão dá foco a ele e o foco fica até outro controle tomá-lo. O anel é
## o "você está aqui" em estado de repouso, e é elemento gráfico -- piso de 3:1.
##
## Botão que não aceita foco não precisa de indicador, e é a única saída daqui.
## Fora isso a régua reprova mesmo sem conseguir medir (stylebox de foco que não
## seja StyleBoxFlat devolve espessura 0): aprovar por não ter enxergado é o modo
## de falha que este arquivo inteiro existe para acabar.
func _medir_anel(btn: BaseButton, st: Dictionary, bg: Color, tint: Color, falhas: Array) -> void:
	if btn.focus_mode == Control.FOCUS_NONE:
		return
	var anel := Ruler.focus_ring(btn, tint)
	_conta(btn, "anel")
	if anel.px < Ruler.MIN_RING_PX:
		falhas.append(_falha(btn, st.state, "anel(%s %dpx)" % [anel.tipo, anel.px],
			anel.color, {"ratio": 0.0, "bg": bg}, Ruler.GLYPH_MIN))
		return
	var r := _worst(anel.color, bg, Color(0, 0, 0, 0), 0, false)
	if r.ratio < Ruler.GLYPH_MIN:
		falhas.append(_falha(btn, st.state, "anel", anel.color, r, Ruler.GLYPH_MIN))

## Ícone de sprite (não glifo monocromático tingido): cobra o contraste que pelo
## menos um quinto da área do desenho alcança. Quando o fundo não fecha opaco,
## repete a conta sobre cada cenário e fica com o pior.
func _medir_icone(node: Node, tex: Texture2D, modulate: Color, bg: Color, estado: String, falhas: Array) -> void:
	var fundos: Array[Color] = [bg]
	if bg.a < 0.999:
		fundos = []
		for atras in _backdrops():
			fundos.append(Ruler.over(bg, atras))
	var pior := INF
	var pior_bg := bg
	for f in fundos:
		var r := Ruler.icon_ratio(tex, modulate, f)
		if r < pior:
			pior = r
			pior_bg = f
	_conta(node, "ícone")
	if pior < Ruler.GLYPH_MIN:
		falhas.append(_falha(node, estado, "ícone", modulate, {"ratio": pior, "bg": pior_bg}, Ruler.GLYPH_MIN))

func _outline_color(node: Control, tint: Color) -> Color:
	if not node.has_theme_color("font_outline_color"):
		return Color(0, 0, 0, 0)
	return node.get_theme_color("font_outline_color") * tint

func _outline_px(node: Control) -> int:
	if not node.has_theme_constant("outline_size"):
		return 0
	return node.get_theme_constant("outline_size")

## A lista do OptionButton é uma Window, não um filho na árvore de Control --
## qualquer varredura que só ande em get_children() passa por cima dela. Foi
## assim que ela ficou quatro rodadas abrindo no escuro padrão do Godot dentro de
## uma UI clara.
func _sweep_popups(root: Node) -> Array:
	var falhas: Array = []
	for node in _all_nodes(root):
		if not (node is OptionButton):
			continue
		var popup: PopupMenu = node.get_popup()
		var painel := Ruler.stylebox_fill(popup.get_theme_stylebox("panel"))
		for st in Ruler.POPUP_DRAW_STATES:
			var bg := painel
			if st.style != "" and popup.has_theme_stylebox(st.style):
				bg = Ruler.over(Ruler.stylebox_fill(popup.get_theme_stylebox(st.style)), painel)
			var ink: Color = popup.get_theme_color(st.font)
			var r := _worst(ink, bg, Color(0, 0, 0, 0), 0, true)
			if r.ratio < Ruler.TEXT_MIN:
				falhas.append(_falha(node, "popup/" + st.state, "texto", ink, r, Ruler.TEXT_MIN))
	return falhas

func _relato(falhas: Array) -> String:
	falhas.sort_custom(func(a, b): return a.ratio < b.ratio)
	var linhas: Array[String] = ["%d reprovação(ões) de contraste:" % falhas.size()]
	for f in falhas.slice(0, 12):
		linhas.append("  %.2f:1 (min %.1f) %s [%s] %s tinta %s sobre %s"
			% [f.ratio, f.min, f.tipo, f.estado, f.path, f.ink, f.bg])
	if falhas.size() > 12:
		linhas.append("  ... e mais %d" % (falhas.size() - 12))
	return "\n".join(linhas)

# --------------------------------------------------------------------------
# Testes
# --------------------------------------------------------------------------

## Arma correr e pular em quem responde por isso (as teclas Lá#/Si do piano e as
## placas correspondentes), e devolve quantos controles foram armados.
##
## Existe porque a varredura montava o Playground e media só o estado inicial: o
## ARMADO é outra cor de fundo (bg x1,6 clareado), e é o pior caso documentado em
## ColorDistance -- 3,70:1 no azul do Clássico. Enquanto ele ficou de fora, tinta,
## halo e anel de foco podiam ser decididos contra a cor de REPOUSO e ninguém via.
func _arma(root: Node) -> int:
	var quantos := 0
	for n in _all_nodes(root):
		if n.has_method("on_armed_state_changed"):
			n.call("on_armed_state_changed", true, true)
			quantos += 1
	return quantos

## As 12 notas no mesmo chip. O piano, o joystick e as placas exibem as 12 cores
## ao mesmo tempo, mas o chip do HUD mostra UMA -- e a varredura mostra sempre Dó.
## Como o defeito que motivou medir superfície aparecia em 28 das 36 combinações
## nota x esquema, medir só o Dó deixaria a rede a um sorteio de distância: no
## Clássico o Dó reprova, no Alto Contraste ele passa (4,60:1) e quem reprova é o
## Sol. Aqui só as superfícies são remedidas -- é o único desenho que muda com a
## nota, e a geometria não mexe, então não há layout novo pra esperar.
func _varre_todas_as_notas(root: Node, falhas: Array) -> void:
	var superficies: Array[CanvasItem] = []
	var mostradores: Array[Node] = []
	for n in _all_nodes(root):
		if n is ColorRect or n is Polygon2D:
			superficies.append(n)
		elif n.has_method("display_note"):
			mostradores.append(n)
	for key in NoteMapping.NOTES.keys():
		for m in mostradores:
			m.call("display_note", key)
		for s in superficies:
			_medir_superficie(s, Ruler.BUTTON_DRAW_STATES[0], falhas)

## Varre a cena montada em repouso E armada. Duas varreduras e não uma porque a
## cor armada existe só enquanto a ação está armada: medir depois de armar sem
## medir antes trocaria um buraco por outro.
func _varre_montado(p: Node, rotulo: String) -> void:
	var falhas := _sweep(p)
	_varre_todas_as_notas(p, falhas)
	assert_eq(falhas.size(), 0, "%s\n%s" % [rotulo, _relato(falhas)])
	assert_gte(_arma(p), 2, "%s: ninguém recebeu o estado armado" % rotulo)
	await wait_frames(1)
	var armado := _sweep(p)
	assert_eq(armado.size(), 0, "%s, ARMADO\n%s" % [rotulo, _relato(armado)])

func _varre_playground(esquema: String, pistas: bool) -> void:
	ColorSchemeSettings.set_scheme(esquema)
	ColorSchemeSettings.set_control_cues(pistas)
	var p := _mount(PlaygroundScene)
	await wait_frames(2)
	_populate(p)
	await wait_frames(1)
	await _varre_montado(p, "esquema %s, pistas %s" % [esquema, pistas])

func test_playground_contrast_classico_com_pistas():
	await _varre_playground("classico", true)

func test_playground_contrast_pedagogico_com_pistas():
	await _varre_playground("pedagogico", true)

func test_playground_contrast_alto_contraste_com_pistas():
	await _varre_playground("alto_contraste", true)

func test_playground_contrast_pedagogico_sem_pistas():
	await _varre_playground("pedagogico", false)

## A PIOR paleta que o jogador consegue montar, e não uma inventada: o editor de
## cor gira SÓ o matiz (NoteColorModal._on_hue_changed preserva S e V, senão
## quebraria a regra altura<->luminosidade), então o espaço alcançável de cada
## nota é o círculo de matiz no S/V que aquela nota tem em algum dos 3 esquemas
## embarcados. Aqui esse círculo é varrido e fica o matiz em que a MELHOR das
## duas tintas dá o menor contraste -- o meio-tom.
##
## Por que isso precisa existir: as 4 placas de ação carregam as notas agudas, que
## pela regra de luminosidade são as cores claras, e nos 3 esquemas embarcados
## elas já passavam de 4,5:1 sem contorno nenhum. Sem esta paleta, apagar o
## contorno das placas não reprovava NADA -- medido, a suíte seguia 530/530 com o
## defeito de volta. A cor personalizada não é hipótese: é a tela de Cores.
func _hostile_palette() -> Array[Color]:
	var out: Array[Color] = []
	var keys := NoteMapping.NOTES.keys()
	for i in range(keys.size()):
		var pior := Color.WHITE
		var pior_r := INF
		for esquema in ColorSchemes.SCHEME_IDS:
			var base: Color = ColorSchemes.colors_for(esquema)[i]
			for passo in range(72):
				var c := Color.from_hsv(passo / 72.0, base.s, base.v, 1.0)
				var r: float = maxf(
					ColorDistance.contrast_ratio(ColorDistance.ICON_DARK, c),
					ColorDistance.contrast_ratio(ColorDistance.ICON_LIGHT, c))
				if r < pior_r:
					pior_r = r
					pior = c
		out.append(pior)
	return out

func test_playground_contrast_with_the_worst_palette_a_player_can_build():
	var hostil := _hostile_palette()
	# Trocar de esquema PRIMEIRO: set_scheme(CUSTOM_ID) semeia a paleta
	# personalizada a partir da ativa e apagaria as cores gravadas antes dele.
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	for i in range(hostil.size()):
		ColorSchemeSettings.set_custom_color(i, hostil[i])
	ColorSchemeSettings.set_control_cues(true)
	var p := _mount(PlaygroundScene)
	await wait_frames(2)
	_populate(p)
	await wait_frames(1)
	await _varre_montado(p, "paleta hostil %s" % [hostil])

func test_playground_popup_lists_contrast():
	var p := _mount(PlaygroundScene)
	await wait_frames(2)
	var falhas := _sweep_popups(p)
	assert_eq(falhas.size(), 0, _relato(falhas))

func test_color_scheme_screen_contrast():
	var s := _mount(ColorSchemeScreenScene)
	await wait_frames(2)
	# A tela abre com os "Editar" DESABILITADOS (o esquema inicial não é o
	# personalizado) e com a confirmação e o modal escondidos -- os três estados
	# que nenhum teste anterior olhava.
	s._confirm_panel.visible = true
	s._modal.open_for(0)
	s._modal._warning_label.text = "Essa cor está parecida com a de Ré"
	s._modal._warning.visible = true
	_populate(s)
	await wait_frames(1)
	var falhas := _sweep(s)
	assert_eq(falhas.size(), 0, _relato(falhas))

func test_color_scheme_screen_popup_contrast():
	var s := _mount(ColorSchemeScreenScene)
	await wait_frames(2)
	var falhas := _sweep_popups(s)
	assert_eq(falhas.size(), 0, _relato(falhas))

func test_level_select_screen_contrast():
	var s := _mount(LevelSelectScreenScene)
	await wait_frames(2)
	var falhas := _sweep(s)
	assert_eq(falhas.size(), 0, _relato(falhas))

func test_level_select_screen_popup_contrast():
	var s := _mount(LevelSelectScreenScene)
	await wait_frames(2)
	var falhas := _sweep_popups(s)
	assert_eq(falhas.size(), 0, _relato(falhas))

func test_pause_modal_contrast():
	var s := _mount(PauseModalScene)
	await wait_frames(2)
	var falhas := _sweep(s)
	assert_eq(falhas.size(), 0, _relato(falhas))

## Uma varredura que não alcança nada passa com folga -- e passaria também com o
## defeito de volta. Este teste é a prova de que a régua está apontada pra alguma
## coisa: fixa o MÍNIMO de medições por controle, incluindo os quatro que são
## irmãos do GameHUD na CanvasLayer e portanto os primeiros a sumir de qualquer
## varredura ingênua.
##
## Os números são pisos, não igualdades: crescer a UI não deve quebrar isto, mas
## um controle que pare de ser medido, sim.
func test_the_sweep_actually_measures_every_control():
	ColorSchemeSettings.set_control_cues(true)
	var p := _mount(PlaygroundScene)
	await wait_frames(2)
	_populate(p)
	await wait_frames(1)
	_sweep(p)
	# 12 teclas x (nome + glifo) x 6 estados de desenho, mais 1 anel de foco cada.
	assert_gte(int(_censo.get("PianoInput", 0)), 156, "PianoInput mal varrido: %s" % _censo)
	# 4 placas x (nome + glifo) x 6 estados, mais 1 anel cada.
	assert_gte(int(_censo.get("SpecialActionPanel", 0)), 52, "SpecialActionPanel mal varrido: %s" % _censo)
	# 8 fatias x (nome + seta).
	assert_gte(int(_censo.get("DirectionJoystick", 0)), 16, "DirectionJoystick mal varrido: %s" % _censo)
	# 3 dropdowns + 5 botões (x6 estados + anel) + o progresso + os stats.
	assert_gte(int(_censo.get("GameHUD", 0)), 57, "GameHUD mal varrido: %s" % _censo)
	# nome + frequência + o chip de cor.
	assert_gte(int(_censo.get("NotePanel", 0)), 3, "NotePanel mal varrido: %s" % _censo)

## Companheiro do teste acima, por TIPO de medição -- e é este que segura as duas
## classes que a varredura deixava passar inteiras.
##
## O piso por controle não bastava: as 12 teclas do piano somam 156 medições, e
## perder as 12 de anel deixaria 144, ainda acima de qualquer piso redondo que se
## escrevesse por controle. Uma classe inteira pode sumir sem derrubar um total.
func test_the_sweep_measures_every_class_of_element():
	ColorSchemeSettings.set_control_cues(true)
	var p := _mount(PlaygroundScene)
	await wait_frames(2)
	_populate(p)
	await wait_frames(1)
	_sweep(p)
	# 12 teclas + 4 placas + 7 botões/dropdowns do HUD.
	assert_gte(int(_censo_tipo.get("anel", 0)), 23, "anéis de foco mal varridos: %s" % _censo_tipo)
	# O chip do NotePanel -- a única superfície de cor do Playground que a régua
	# consegue enxergar o fundo (as fatias do joystick e o cenário são polígonos
	# irmãos dentro de Node2D; ver _medir_superficie).
	assert_gte(int(_censo_tipo.get("superfície", 0)), 1, "superfícies mal varridas: %s" % _censo_tipo)
	assert_gte(int(_censo_tipo.get("glifo", 0)), 100, "glifos mal varridos: %s" % _censo_tipo)
	assert_gte(int(_censo_tipo.get("texto", 0)), 140, "textos mal varridos: %s" % _censo_tipo)

## As 12 amostras de cor da lista mais o preview do modal. Mora aqui e não no
## teste de contraste da tela porque é pergunta diferente: lá é "as que foram
## medidas passam", aqui é "foram medidas".
func test_the_sweep_measures_the_colour_samples_of_the_palette_screen():
	var s := _mount(ColorSchemeScreenScene)
	await wait_frames(2)
	s._modal.open_for(0)
	await wait_frames(1)
	_sweep(s)
	assert_gte(int(_censo_tipo.get("superfície", 0)), 13,
		"swatches/preview mal varridos: %s" % _censo_tipo)

## O foco NÃO é transitório num aparelho de toque: com emulate_mouse_from_touch,
## tocar um botão dá foco a ele e o foco fica até outro controle tomá-lo. Se o
## anel de foco for invisível, o jogador não tem como saber onde está -- e o
## `focus` padrão do Godot é uma borda quase branca, feita pra skin escura, sobre
## botões #FFFDF5.
##
## É contraste de elemento gráfico (WCAG 1.4.11), medido entre a borda do anel e
## o preenchimento do próprio botão. A varredura de texto não alcança isto: ela
## mede o miolo, e este anel é só borda.
##
## Este teste olha o RECURSO de tema, e sozinho ele nunca foi suficiente: os dois
## tipos daqui não cobrem as 12 teclas do piano nem as 4 placas de ação, que são
## irmãs do GameHUD na CanvasLayer e não veem tema nenhum -- é onde o defeito
## estava. Quem mede os anéis dos nós de verdade é a varredura (_medir_anel);
## este continua porque pega um tipo do tema que nenhuma cena montada instancie.
func test_the_theme_focus_ring_is_visible_against_the_button_it_marks():
	var tema: Theme = load("res://assets/ui/blindtuner_theme.tres")
	for tipo in ["Button", "OptionButton"]:
		assert_true(tema.has_stylebox("focus", tipo), "%s/focus definido" % tipo)
		var anel := tema.get_stylebox("focus", tipo) as StyleBoxFlat
		assert_not_null(anel, "%s/focus precisa ser StyleBoxFlat (só borda)" % tipo)
		assert_false(anel.draw_center, "%s/focus não pode pintar o miolo (tapa o estado normal)" % tipo)
		assert_gte(anel.border_width_top, Ruler.MIN_RING_PX, "%s/focus com borda fina demais pra enxergar" % tipo)
		var fundo := Ruler.stylebox_fill(tema.get_stylebox("normal", tipo))
		var razao := ColorDistance.contrast_ratio(anel.border_color, fundo)
		assert_gte(razao, Ruler.GLYPH_MIN,
			"%s: anel de foco a %.2f:1 do próprio botão" % [tipo, razao])

## PRÉ-CONDIÇÃO da régua, e o motivo dela reprovar alto: a medição de superfície de
## botão é PIXEL DE TEXTURA, e textura que não abre não dá erro -- dá transparente.
##
## Com stylebox_fill() devolvendo transparente, todo texto de botão passa a ser
## medido contra as cores do CENÁRIO em vez da superfície do botão, e a varredura
## fica verde medindo a coisa errada. Não é hipótese: godot/**/*.import é
## gitignored e nenhum CI roda esta suíte, então clone frio é o caso real e o
## "537/537" é o número de uma máquina só.
func test_the_theme_textures_hand_the_ruler_a_real_opaque_pixel():
	var tema: Theme = load("res://assets/ui/blindtuner_theme.tres")
	var conferidas := 0
	for tipo in tema.get_stylebox_type_list():
		for nome in tema.get_stylebox_list(tipo):
			var sb := tema.get_stylebox(nome, tipo)
			if not (sb is StyleBoxTexture):
				continue
			var tex := (sb as StyleBoxTexture).texture
			assert_not_null(tex, "%s/%s sem textura" % [tipo, nome])
			assert_true(Ruler.texture_is_readable(tex),
				"%s/%s: get_image() não devolveu imagem (clone sem .import?)" % [tipo, nome])
			assert_gte(Ruler.stylebox_fill(sb).a, 0.999,
				"%s/%s: o pixel que fica embaixo do texto não é opaco (%s)"
					% [tipo, nome, Ruler.hex(Ruler.stylebox_fill(sb))])
			conferidas += 1
	# Piso: as 4 do Button, as 4 do OptionButton (a de foco é Flat) e o quadro do
	# PanelContainer. Sem isto, um tema que perdesse todas as StyleBoxTexture
	# passaria com o laço vazio -- a aprovação-por-vacuidade de sempre.
	assert_gte(conferidas, 9, "poucas texturas conferidas (%d)" % conferidas)
	var seta: Texture2D = tema.get_icon("arrow", "OptionButton")
	assert_false(Ruler.icon_buckets(seta).is_empty(), "a seta do OptionButton não tem pixel opaco")
	assert_eq(Ruler.unreadable_textures().size(), 0,
		"texturas ilegíveis: %s" % [Ruler.unreadable_textures()])

## Um ícone que não carrega passava com NOTA MÁXIMA: icon_buckets devolvia array
## vazio, icon_ratio lia isso como "nada desenhado, nada a cobrar" e devolvia INF.
## Agora é o contrário -- 0,0, o pior valor possível --, porque textura ilegível
## não é ausência de desenho, é medição que não aconteceu.
func test_an_unreadable_icon_fails_instead_of_scoring_infinity():
	var fantasma := PlaceholderTexture2D.new()
	assert_null(fantasma.get_image(), "premissa: esta textura não devolve imagem")
	assert_false(Ruler.texture_is_readable(fantasma), "deveria acusar a leitura falha")
	assert_eq(Ruler.icon_ratio(fantasma, Color.WHITE, Color.WHITE), 0.0,
		"ícone ilegível tem que reprovar, não pontuar INF")
	assert_eq(Ruler.unreadable_textures().size(), 1, "a régua tem que saber dizer QUAL falhou")

## A régua devolve a medição DAQUELA textura, e não a da anterior.
##
## O cache era chaveado por `tex.get_rid().get_id()` para o pixel central e pelo
## NEGATIVO do mesmo id para as faixas do ícone, num dicionário só. Uma Texture2D
## sem RID próprio (Resource.get_rid() devolve RID vazio, id 0) fazia 0 e -0
## caírem na MESMA entrada: icon_buckets() lia o Color que _texture_center() tinha
## gravado. Reproduzido antes da correção -- "Trying to return value of type Color
## from a function whose return type is Array" --, e o pior é que o GDScript engole
## esse erro devolvendo array VAZIO, que era justamente o valor que aprovava a
## medição por vacuidade. A suíte ficava verde.
class TexturaSemRid extends Texture2D:
	func _get_width() -> int: return 4
	func _get_height() -> int: return 4

func test_the_ruler_never_serves_one_textures_reading_for_another():
	var vermelha := _textura_chapada(Color(1, 0, 0))
	var azul := _textura_chapada(Color(0, 0, 1))
	var sem_rid_a := TexturaSemRid.new()
	var sem_rid_b := TexturaSemRid.new()
	assert_eq(sem_rid_a.get_rid().get_id(), 0, "premissa: Texture2D de script não tem RID")
	assert_eq(sem_rid_b.get_rid().get_id(), sem_rid_a.get_rid().get_id(), "premissa: as duas têm o mesmo id")

	# Ordem de propósito: centro primeiro, faixas depois, alternando as texturas --
	# é a sequência em que as duas chaves colidiam.
	assert_eq(Ruler.stylebox_fill(_stylebox_de(vermelha)), Color(1, 0, 0, 1))
	assert_eq(Ruler.stylebox_fill(_stylebox_de(sem_rid_a)), Color(0, 0, 0, 0))
	assert_eq(Ruler.stylebox_fill(_stylebox_de(azul)), Color(0, 0, 1, 1))
	var faixas_sem_rid := Ruler.icon_buckets(sem_rid_b)
	assert_true(faixas_sem_rid is Array, "faixas de ícone não podem sair como Color")
	assert_true(faixas_sem_rid.is_empty(), "textura sem imagem não tem faixa nenhuma")
	assert_eq(Ruler.icon_buckets(vermelha), [[Color(1, 0, 0, 1), 1.0]])
	assert_eq(Ruler.icon_buckets(azul), [[Color(0, 0, 1, 1), 1.0]])
	# Reler não pode mudar a resposta: é o cache servindo a mesma entrada, não outra.
	assert_eq(Ruler.stylebox_fill(_stylebox_de(vermelha)), Color(1, 0, 0, 1))
	# Duas entradas, e não uma: é aqui que a chave numérica se denuncia. As duas
	# texturas sem RID compartilhavam a entrada 0, e a régua passava a conhecer UMA
	# leitura falha onde houve duas -- o mesmo mecanismo que fazia uma textura
	# responder pela medição da outra.
	assert_eq(Ruler.unreadable_textures().size(), 2,
		"cada textura ilegível é uma entrada: %s" % [Ruler.unreadable_textures()])

func _textura_chapada(c: Color) -> ImageTexture:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)

func _stylebox_de(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	return sb

## A paleta personalizada é do JOGADOR: gira o matiz preservando S e V, então a
## cor de fundo de uma placa pode ser qualquer matiz. Varrer só os 3 esquemas
## embarcados deixaria a regra de tinta sem rede justamente onde ela é aplicada a
## uma cor que ninguém revisou. Aqui a regra é testada como função pura, sobre
## uma amostragem densa do cubo -- é o único jeito de cobrir o espaço inteiro.
func test_icon_tint_rule_clears_the_graphic_minimum_for_any_background():
	var piores := []
	for r in range(0, 6):
		for g in range(0, 6):
			for b in range(0, 6):
				var bg := Color(r / 5.0, g / 5.0, b / 5.0)
				var razao := ColorDistance.contrast_ratio(ColorDistance.icon_tint_for(bg), bg)
				if razao < Ruler.GLYPH_MIN:
					piores.append("%s -> %.2f:1" % [Ruler.hex(bg), razao])
	assert_eq(piores.size(), 0,
		"icon_tint_for abaixo de %.1f:1 em: %s" % [Ruler.GLYPH_MIN, ", ".join(piores)])

## Companheiro do teste acima: apertar NUNCA pode custar contraste. Como função
## pura, sobre o cubo inteiro -- é o que garante a regra também na paleta
## personalizada, cuja cor ninguém revisou.
func test_pressed_shade_never_costs_contrast_against_the_ink():
	var piores := []
	for r in range(0, 6):
		for g in range(0, 6):
			for b in range(0, 6):
				var bg := Color(r / 5.0, g / 5.0, b / 5.0)
				var tinta := ColorDistance.icon_tint_for(bg)
				var apertado := ColorDistance.pressed_shade_for(bg)
				var antes := ColorDistance.contrast_ratio(tinta, bg)
				var depois := ColorDistance.contrast_ratio(tinta, apertado)
				if depois < antes - 0.001:
					piores.append("%s: %.2f -> %.2f" % [Ruler.hex(bg), antes, depois])
				elif depois < Ruler.GLYPH_MIN:
					piores.append("%s apertado a %.2f:1" % [Ruler.hex(bg), depois])
	assert_eq(piores.size(), 0, "pressed_shade_for piora o contraste em: %s" % ", ".join(piores))

