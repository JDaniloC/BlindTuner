extends GutTest

const PanelScene := preload("res://scenes/NotePanel.tscn")
const ColorDistance := preload("res://scripts/ColorDistance.gd")

## Estado do jogador, salvo e devolvido inteiro. A suíte já apagou paleta de quem
## joga na mesma máquina: reset_to_defaults() zera as 12 cores personalizadas, e
## estes testes ainda por cima escrevem nelas.
var _scheme_antes: String = ""
var _cues_antes: bool = true
var _custom_antes: Array[Color] = []

func _panel() -> Node:
	var p = PanelScene.instantiate()
	add_child_autofree(p)
	return p

func before_each():
	_scheme_antes = ColorSchemeSettings.scheme_id
	_cues_antes = ColorSchemeSettings.control_cues
	_custom_antes = ColorSchemeSettings.custom_colors()
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	CueSettings.set_level(0)
	ColorSchemeSettings.reset_to_defaults()
	for i in range(_custom_antes.size()):
		ColorSchemeSettings.set_custom_color(i, _custom_antes[i])
	ColorSchemeSettings.set_scheme(_scheme_antes)
	ColorSchemeSettings.set_control_cues(_cues_antes)

func test_level_zero_all_visible():
	CueSettings.set_level(0)
	var p = _panel()
	p.display_note("C4")
	assert_true(p.visible)
	assert_true(p._label.visible)
	assert_true(p._freq.visible)
	assert_true(p._color_chip.visible)

func test_level_one_hides_name():
	CueSettings.set_level(1)
	var p = _panel()
	p.display_note("C4")
	assert_false(p._label.visible)
	assert_true(p._freq.visible)
	assert_true(p._color_chip.visible)

func test_level_two_only_chip():
	CueSettings.set_level(2)
	var p = _panel()
	p.display_note("C4")
	assert_false(p._label.visible)
	assert_false(p._freq.visible)
	assert_true(p._color_chip.visible)

func test_level_three_panel_hidden():
	CueSettings.set_level(3)
	var p = _panel()
	p.display_note("C4")
	assert_false(p.visible)

func test_chip_repaints_when_scheme_changes():
	# O defeito que motivou a correção e ficou sem teste: o chip guardava a cor do
	# esquema antigo enquanto o controle de input já mostrava a nova -- a MESMA
	# nota em duas cores ao mesmo tempo, num jogo cuja pista É a cor.
	CueSettings.set_level(0)
	var p = _panel()
	p.display_note("C4")
	var antes = p._color_chip.color
	ColorSchemeSettings.set_scheme("alto_contraste")
	assert_ne(p._color_chip.color, antes, "o chip precisa repintar sem reiniciar a fase")
	assert_eq(p._color_chip.color, Color("#0D4A74"), "e com a cor do esquema novo")

func test_chip_stays_put_when_the_scheme_changes_before_any_note():
	# Sem nota exibida não há o que repintar; repintar assim mesmo mostraria a cor
	# de uma nota que o jogador não recebeu.
	CueSettings.set_level(0)
	var p = _panel()
	var antes = p._color_chip.color
	ColorSchemeSettings.set_scheme("alto_contraste")
	assert_eq(p._color_chip.color, antes)

func test_reacts_to_cue_level_changed_after_instantiation():
	CueSettings.set_level(0)
	var p = _panel()
	p.display_note("C4")
	assert_true(p._label.visible)
	CueSettings.set_level(2)  # sinal dispara com painel já vivo
	assert_false(p._label.visible)
	assert_false(p._freq.visible)
	assert_true(p._color_chip.visible)

# --------------------------------------------------------------------------
# Moldura do chip
#
# Na pista 2 o chip é a tela inteira: nome e frequência somem (é o contrato de
# test_level_two_only_chip) e sobra um quadrado de cor sobre o painel. Sem
# moldura, 28 das 36 combinações nota x esquema ficavam abaixo dos 3:1 do WCAG
# 1.4.11 -- Ré do Clássico e Ré# do Pedagógico em 1,06:1.
#
# O que estes testes cobram é a PROPRIEDADE (o quadrado é achável contra o
# painel, em qualquer nota, em qualquer esquema, e num painel de qualquer cor),
# não o mecanismo. Por isso medem a caixa que está DESENHADA em volta do chip --
# stylebox composta com modulate, e a espessura tirada da geometria depois do
# passe de layout -- em vez de conferir que existe um override chamado X.
# --------------------------------------------------------------------------

## Source-over. Moldura translúcida é a moldura que o olho vê, não a declarada:
## `modulate` se propaga pros filhos e `self_modulate` tinge o próprio desenho,
## e medir a StyleBox sem os dois já mentiu neste projeto.
func _sobre(fg: Color, bg: Color) -> Color:
	if fg.a >= 1.0:
		return Color(fg.r, fg.g, fg.b, 1.0)
	return Color(
		fg.r * fg.a + bg.r * (1.0 - fg.a),
		fg.g * fg.a + bg.g * (1.0 - fg.a),
		fg.b * fg.a + bg.b * (1.0 - fg.a),
		1.0)

func _pixel_central(tex: Texture2D) -> Color:
	var img := tex.get_image()
	# Precondição, e reprova alto de propósito: sem pixel não há medição
	# nenhuma, e uma textura que não carrega (os .import são gitignored) faria a
	# régua devolver transparente e aprovar tudo em silêncio.
	assert_not_null(img, "a textura do painel não devolveu imagem")
	if img == null:
		return Color(0, 0, 0, 0)
	if img.is_compressed():
		img.decompress()
	var c := img.get_pixel(int(img.get_width() / 2), int(img.get_height() / 2))
	assert_almost_eq(c.a, 1.0, 0.001, "o miolo do painel precisa ser opaco pra servir de fundo")
	return c

## Cor que o painel pinta atrás do chip, calculada aqui e não perguntada ao
## NotePanel: perguntar moveria o alvo junto com o código medido.
func _fundo_do_painel(p) -> Color:
	var sb: StyleBox = p.get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		return (sb as StyleBoxFlat).bg_color
	if sb is StyleBoxTexture and (sb as StyleBoxTexture).texture != null:
		return _pixel_central((sb as StyleBoxTexture).texture)
	assert_true(false, "o painel do NotePanel não pinta fundo: não há contra o que medir")
	return Color(0, 0, 0, 0)

## Cor efetivamente pintada em volta do chip -- o desenho do nó que ENVOLVE o
## chip, seja ele qual for. Transparente quando não há moldura nenhuma, que é o
## que faz o teste ficar vermelho se alguém tirar a caixa.
func _moldura_pintada(p) -> Color:
	var frame := (p._color_chip as Control).get_parent() as Control
	if frame == null:
		return Color(0, 0, 0, 0)
	var fill := Color(0, 0, 0, 0)
	if frame is Panel or frame is PanelContainer:
		var sb: StyleBox = frame.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			var flat := sb as StyleBoxFlat
			fill = flat.bg_color if flat.draw_center else Color(0, 0, 0, 0)
		elif sb is StyleBoxTexture and (sb as StyleBoxTexture).texture != null:
			fill = _pixel_central((sb as StyleBoxTexture).texture) * (sb as StyleBoxTexture).modulate_color
	elif frame is ColorRect:
		fill = (frame as ColorRect).color
	var tint := frame.self_modulate
	var walker: Node = frame
	while walker is CanvasItem:
		tint *= (walker as CanvasItem).modulate
		walker = walker.get_parent()
	return fill * tint

## Espessura da TINTA da moldura: a menor das quatro folgas entre a caixa que
## desenha e o chip, medida na geometria já resolvida. Ler a margem declarada
## deixaria passar uma moldura de 0px com a cor certinha.
func _espessura_da_moldura(p) -> float:
	var chip := p._color_chip as Control
	var frame := chip.get_parent() as Control
	if frame == null:
		return 0.0
	var c := chip.get_global_rect()
	var f := frame.get_global_rect()
	return minf(
		minf(c.position.x - f.position.x, c.position.y - f.position.y),
		minf(f.end.x - c.end.x, f.end.y - c.end.y))

func test_a_moldura_acha_o_chip_nas_12_notas_dos_3_esquemas():
	# Pista 2: o chip é o único portador de informação da tela.
	CueSettings.set_level(2)
	var p = _panel()
	# O await é obrigatório: custom_minimum_size só vira size no passe de layout.
	await wait_frames(1)
	var fundo := _fundo_do_painel(p)

	var pior := INF
	var pior_caso := ""
	var pior_chip := INF
	var pior_chip_caso := ""
	var medidos := 0
	for esquema in ColorSchemes.SCHEME_IDS:
		ColorSchemeSettings.set_scheme(esquema)
		for key in NoteMapping.NOTES:
			p.display_note(key)
			var moldura := _sobre(_moldura_pintada(p), fundo)
			var r := ColorDistance.contrast_ratio(moldura, fundo)
			if r < pior:
				pior = r
				pior_caso = "%s/%s moldura %s" % [esquema, key, moldura.to_html(false)]
			var chip := ColorDistance.contrast_ratio(p._color_chip.color, fundo)
			if chip < pior_chip:
				pior_chip = chip
				pior_chip_caso = "%s/%s" % [esquema, key]
			medidos += 1

	# Sem isto, um esquema removido ou um dicionário vazio aprovariam por vacuidade.
	assert_eq(medidos, 36, "a varredura tem que medir as 12 notas dos 3 esquemas")
	assert_gte(pior, ColorDistance.GRAPHIC_MIN,
		"moldura a %.2f:1 contra o painel (%s) -- o chip sozinho fica em %.2f:1 no %s" \
			% [pior, pior_caso, pior_chip, pior_chip_caso])
	assert_gte(_espessura_da_moldura(p), 2.0,
		"moldura mais fina que 2px não é moldura, é serrilhado")

func test_a_moldura_e_decidida_contra_o_painel_em_que_cai():
	# Cor fixa aposta no fundo. Se o painel escurecer -- outro tema, outra tela --
	# uma moldura escura chapada some, e some calada: é o mesmo modo de falha que
	# ela veio consertar.
	var p = _panel()
	await wait_frames(1)
	p.display_note("C4")
	var medidos := 0
	for fundo in [Color("#ADB7C4"), Color("#101014"), Color.WHITE, Color("#7F7F7F"), Color("#0D4A74")]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fundo
		p.add_theme_stylebox_override("panel", sb)
		await wait_frames(1)
		var moldura := _sobre(_moldura_pintada(p), fundo)
		var r := ColorDistance.contrast_ratio(moldura, fundo)
		assert_gte(r, ColorDistance.GRAPHIC_MIN,
			"moldura %s a %.2f:1 sobre painel %s" % [moldura.to_html(false), r, fundo.to_html(false)])
		medidos += 1
	assert_eq(medidos, 5, "a varredura de fundos precisa rodar")

func test_a_moldura_cresce_pra_fora_e_nao_come_a_area_de_cor():
	# A cor É a informação. Uma moldura grossa o bastante para reduzir o chip a um
	# ponto passaria em contraste e reprovaria no olho do jogador.
	CueSettings.set_level(2)
	var p = _panel()
	p.display_note("C4")
	await wait_frames(1)
	var chip := p._color_chip as Control
	var frame := chip.get_parent() as Control
	assert_gte(chip.size.x, 28.0, "a área de cor não pode encolher para pagar a moldura")
	assert_gte(chip.size.y, 28.0, "a área de cor não pode encolher para pagar a moldura")
	assert_gte(chip.get_rect().get_area() / maxf(frame.get_rect().get_area(), 1.0), 0.5,
		"a moldura ficou maior que o miolo colorido")

func test_a_moldura_vale_pra_paleta_do_jogador():
	# A paleta personalizada é do jogador: pode ter QUALQUER cor, inclusive a do
	# próprio painel. Nenhuma delas pode deixar o chip sem contorno achável.
	var extremos: Array[Color] = [
		Color("#ADB7C4"),  # a cor exata do painel: o chip sozinho fica em 1,00:1
		Color.WHITE, Color.BLACK, Color("#7F7F7F"),
		Color("#FFF200"), Color("#00ECA6"), Color("#F686C5"), Color("#0D4A74"),
		Color("#FF00FF"), Color("#00FF00"), Color("#1A1A1A"), Color("#FDFDF0"),
	]
	CueSettings.set_level(2)
	var p = _panel()
	await wait_frames(1)
	var fundo := _fundo_do_painel(p)
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	for i in range(extremos.size()):
		ColorSchemeSettings.set_custom_color(i, extremos[i])

	var pior := INF
	var pior_chip := INF
	var medidos := 0
	for key in NoteMapping.NOTES:
		p.display_note(key)
		var moldura := _sobre(_moldura_pintada(p), fundo)
		pior = minf(pior, ColorDistance.contrast_ratio(moldura, fundo))
		pior_chip = minf(pior_chip, ColorDistance.contrast_ratio(p._color_chip.color, fundo))
		medidos += 1

	assert_eq(medidos, 12, "a paleta do jogador tem 12 cores")
	assert_lt(pior_chip, ColorDistance.GRAPHIC_MIN,
		"fixture frouxa: se todo chip já se acha sozinho, a moldura não está sendo testada")
	assert_gte(pior, ColorDistance.GRAPHIC_MIN,
		"pior moldura da paleta livre: %.2f:1 (chip sozinho chega a %.2f:1)" % [pior, pior_chip])

func test_display_miss_shows_relative_pitch_guidance():
	var p = _panel()
	# Tocando D4 (294 Hz) quando o alvo é G4 (392 Hz) -> alvo é mais agudo -> "▲ Suba"
	p.display_miss("D4", "G4")
	assert_true(p._guide_lbl.visible)
	assert_true(p._guide_lbl.text.contains("Suba"))
	
	# Tocando B4 (494 Hz) quando o alvo é E4 (330 Hz) -> alvo é mais grave -> "▼ Desça"
	p.display_miss("B4", "E4")
	assert_true(p._guide_lbl.visible)
	assert_true(p._guide_lbl.text.contains("Desça"))
	
	p.clear_guide()
	assert_false(p._guide_lbl.visible)
	assert_eq(p._guide_lbl.text, "")

func test_replay_button_emits_signal():
	var p = _panel()
	watch_signals(p)
	p._replay_btn.emit_signal("pressed")
	assert_signal_emitted(p, "replay_cue_requested")

