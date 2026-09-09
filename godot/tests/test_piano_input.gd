extends GutTest

const PianoScene := preload("res://scenes/PianoInput.tscn")
const PianoInputScript := preload("res://scripts/PianoInput.gd")
# A regra de tint do ícone saiu do PianoInput e virou compartilhada; ColorDistance
# é RefCounted, não autoload, então precisa de preload.
const ColorDistance := preload("res://scripts/ColorDistance.gd")
# O glifo é ICON_FRAC do menor lado do rect do ícone, não o rect inteiro -- a
# geometria do anel de foco precisa da tinta, não da caixa.
const ActionIconScript := preload("res://scripts/ActionIcon.gd")

func _make() -> Node:
	var p = PianoScene.instantiate()
	add_child_autofree(p)
	return p

func before_each():
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	# O piano não consulta mais o nível de pista, mas há teste aqui que o sobe
	# justamente para provar isso -- e CueSettings é autoload, não se reseta
	# sozinho. reset_to_defaults() religa o interruptor de pistas junto.
	CueSettings.set_level(0)
	ColorSchemeSettings.reset_to_defaults()

func test_twelve_buttons_created():
	var p = _make()
	assert_eq(p._buttons.size(), 12)

func test_button_notes_match_note_mapping_order():
	var p = _make()
	assert_eq(p._button_notes, NoteMapping.NOTES.keys())

func test_button_press_emits_note_triggered_for_movement_note():
	var p = _make()
	watch_signals(p)
	var idx = p._button_notes.find("D4")
	p._buttons[idx].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["D4"])

func test_button_press_emits_note_triggered_for_action_note():
	var p = _make()
	watch_signals(p)
	var idx = p._button_notes.find("A4")
	p._buttons[idx].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["A4"])

func test_control_cues_on_shows_name_and_color():
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, NoteMapping.label_for("C4"))
	# A cor da nota vai no bg_color da tecla (fundo), não num tint do nó (que
	# multiplicaria o texto do label também, matando o contraste) -- ver I1.
	# O tint neutro fica em self_modulate, não em modulate: modulate se propaga
	# pros filhos e tingiria o ícone da tecla junto.
	assert_eq(p._buttons[idx].self_modulate, Color.WHITE)
	assert_eq(p._buttons[idx].modulate, Color.WHITE, "modulate tem que ficar neutro: ele se propaga pro ícone filho")
	var sb = p._buttons[idx].get_theme_stylebox("normal")
	assert_eq(sb.bg_color, NoteMapping.color_for("C4"))

func test_keys_are_authentic_when_control_cues_are_off():
	# Quem manda nas pistas das teclas é ColorSchemeSettings, não o nível de
	# pista: aquele governa o que o HUD conta sobre a nota TOCADA, e amarrar as
	# duas coisas obrigava quem quisesse o teclado autêntico a jogar sem o nome
	# das notas -- e vice-versa.
	ColorSchemeSettings.set_control_cues(false)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].self_modulate, Color.WHITE)
	assert_eq(p._buttons[idx].modulate, Color.WHITE, "modulate tem que ficar neutro: ele se propaga pro ícone filho")
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, p.WHITE_KEY_COLOR)

func test_black_key_is_authentic_when_control_cues_are_off():
	ColorSchemeSettings.set_control_cues(false)
	var p = _make()
	var idx = p._button_notes.find("Cs4")
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, p.BLACK_KEY_COLOR)

func test_the_cue_level_no_longer_touches_the_keyboard():
	# A consequência deliberada da inversão, e a que parece bug: no nível "só
	# som", com o interruptor ligado, o teclado CONTINUA colorido e nomeado. O
	# desafio é reconhecer a nota tocada de ouvido, não adivinhar onde ela mora
	# no teclado. Alguém vai querer "consertar" isto um dia.
	CueSettings.set_level(3)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, NoteMapping.label_for("C4"),
		"o nome do controle é material didático, não dificuldade")
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, NoteMapping.color_for("C4"))

func test_the_cue_level_cannot_resurrect_the_name_either():
	# O cruzamento oposto: nível 0 (tudo visível na nota tocada) com o
	# interruptor desligado deixa o teclado autêntico e sem nome nenhum.
	CueSettings.set_level(0)
	ColorSchemeSettings.set_control_cues(false)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, "")
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, p.WHITE_KEY_COLOR)

func test_toggling_repaints_without_restarting():
	var p = _make()
	var antes = p._buttons[0].get_theme_stylebox("normal").bg_color
	var nome_antes = p._buttons[0].text
	ColorSchemeSettings.set_control_cues(false)
	assert_ne(p._buttons[0].get_theme_stylebox("normal").bg_color, antes,
		"desligar as pistas tem que repintar na hora, sem reiniciar a fase")
	assert_ne(p._buttons[0].text, nome_antes,
		"o nome também some na hora: é o mesmo interruptor")

func test_on_armed_state_changed_brightens_correr_button():
	# Com as pistas ligadas, quem clareia com o armed é o bg_color da tecla (não
	# mais o tint do nó, que agora fica fixo em Color.WHITE -- ver I1).
	var p = _make()
	var idx = p._button_notes.find("As4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(true, false)
	assert_gt(p._buttons[idx].get_theme_stylebox("normal").bg_color.get_luminance(), base.get_luminance(), "armed brighten")

func test_on_armed_state_changed_brightens_pular_button():
	var p = _make()
	var idx = p._button_notes.find("B4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(false, true)
	assert_gt(p._buttons[idx].get_theme_stylebox("normal").bg_color.get_luminance(), base.get_luminance(), "armed brighten")

func test_disarm_restores_modulate_to_cue_base():
	var p = _make()
	var idx = p._button_notes.find("As4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(true, false)
	p.on_armed_state_changed(false, false)
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, base, "bg_color volta ao base após disarm")

func test_pressed_stylebox_moves_away_from_the_ink_never_toward_it():
	# Apertar uma tecla precisa mudar visualmente algo (feedback de toque) --
	# antes, normal/hover/pressed compartilhavam o MESMO StyleBoxFlat. Ver I3.
	#
	# Mas a regra deixou de ser "mais escuro". A TINTA da tecla é decidida uma
	# vez, sobre a cor de REPOUSO, e escurecer sempre significava que numa tecla
	# de tinta escura o fundo caminhava na direção da tinta: o Ré ia a 4,15:1
	# justamente com o dedo em cima. Agora o fundo se AFASTA da tinta -- escurece
	# quando a tinta é clara, clareia quando é escura --, e as duas coisas valem
	# ao mesmo tempo: o estado muda E fica mais legível, nunca menos.
	var p = _make()
	for esquema in ["classico", "pedagogico", "alto_contraste"]:
		ColorSchemeSettings.set_scheme(esquema)
		for i in range(p._buttons.size()):
			var normal_color = p._buttons[i].get_theme_stylebox("normal").bg_color
			var pressed_color = p._buttons[i].get_theme_stylebox("pressed").bg_color
			assert_ne(pressed_color, normal_color,
				"%s: a tecla %s não muda nada ao ser apertada" % [esquema, p._button_notes[i]])
			var tinta: Color = p._key_icons[i]._tint
			assert_gte(ColorDistance.contrast_ratio(pressed_color, tinta),
				ColorDistance.contrast_ratio(normal_color, tinta),
				"%s: apertar a tecla %s PIORA o contraste do glifo" % [esquema, p._button_notes[i]])

## Todo estado em que uma tecla pode ser desenhada: os dois lados do interruptor
## de pistas, os 3 esquemas, armado/desarmado e os 2 fundos que o anel pode ter
## embaixo. 12 teclas x 2 x 3 x 2 x 2.
const ESTADOS_DE_TECLA := 12 * 2 * 3 * 2 * 2

func test_focus_ring_is_visible_against_the_key_it_marks():
	# O teste que morava aqui afirmava o CONTRÁRIO: que "focus" não podia ter
	# override, "pra deixar o tema padrão do Godot desenhar o indicador". O tema
	# padrão desenha mesmo -- uma borda #CCCCCC de 2px, feita pra skin escura, que
	# dá 1,28:1 sobre a tecla branca autêntica e 1,37:1 sobre o Mi #FFF200 do
	# Pedagógico. O indicador existia e era invisível, que é pior do que não
	# existir: ninguém procura o que acha que já tem.
	#
	# E o foco não é transitório aqui: com emulate_mouse_from_touch (ligado por
	# padrão) tocar uma tecla dá foco a ela e o foco FICA até outro controle
	# tomá-lo. Para o público-alvo este é o "você está aqui" da tela.
	#
	# A barra é a de elemento gráfico do WCAG (1.4.11), lida de ColorDistance em
	# vez de redigitada. Mede contra os DOIS fundos que podem ficar embaixo do
	# anel: o Godot desenha `focus` POR CIMA da stylebox do estado, então numa
	# tecla focada e apertada o anel cai sobre o fundo do pressed.
	var p = _make()
	var piores: Array[String] = []
	var medidas := 0
	for pistas in [true, false]:
		ColorSchemeSettings.set_control_cues(pistas)
		for esquema in ["classico", "pedagogico", "alto_contraste"]:
			ColorSchemeSettings.set_scheme(esquema)
			for armado in [false, true]:
				p.on_armed_state_changed(armado, armado)
				for i in range(p._buttons.size()):
					var btn: Button = p._buttons[i]
					var anel := btn.get_theme_stylebox("focus") as StyleBoxFlat
					assert_not_null(anel, "tecla %s sem anel de foco próprio" % p._button_notes[i])
					if anel == null:
						continue
					assert_false(anel.draw_center,
						"tecla %s: o anel pinta o miolo e tapa glifo e nome" % p._button_notes[i])
					assert_gte(anel.border_width_top, 2,
						"tecla %s: borda de %dpx não é anel, é serrilhado" % [
							p._button_notes[i], anel.border_width_top])
					for estado in ["normal", "pressed"]:
						var fundo: Color = btn.get_theme_stylebox(estado).bg_color
						var razao := ColorDistance.contrast_ratio(anel.border_color, fundo)
						medidas += 1
						if razao < ColorDistance.GRAPHIC_MIN:
							piores.append("%s/%s %s armado=%s %s: %.2f:1" % [
								esquema, "pistas" if pistas else "autêntico",
								p._button_notes[i], str(armado), estado, razao])
	p.on_armed_state_changed(false, false)
	assert_eq(piores.size(), 0, "anel de foco abaixo de %.1f:1 em: %s" % [
		ColorDistance.GRAPHIC_MIN, ", ".join(piores)])
	# Sem esta linha a varredura aprova de graça se algum laço deixar de iterar --
	# uma lista de esquemas vazia, um _buttons vazio, um `continue` mal posto.
	assert_eq(medidas, ESTADOS_DE_TECLA,
		"a varredura mediu %d fundos, e a tecla tem %d estados de desenho" % [medidas, ESTADOS_DE_TECLA])

func test_focus_ring_does_not_cover_the_glyph_or_the_name():
	# O anel é a única coisa desenhada DEPOIS do glifo e do nome, e por cima
	# deles. Duas coisas o mantêm fora do caminho: o miolo transparente e a
	# espessura, que tem que caber na folga até a TINTA -- não até a caixa. O
	# ActionIcon desenha ICON_FRAC do menor lado do próprio rect, então o glifo é
	# bem menor que o Control dele; e o contorno do nome é desenhado FORA da caixa
	# do texto, por isso entra na conta.
	#
	# Folga medida hoje: 16,5px na base da tecla preta (o menor caso das 12) e
	# 19,1px na base da branca, contra um anel de 4px.
	var p = _make()
	await wait_frames(2)
	for i in range(p._buttons.size()):
		var btn: Button = p._buttons[i]
		var nota: String = p._button_notes[i]
		var anel := btn.get_theme_stylebox("focus") as StyleBoxFlat
		assert_not_null(anel, "tecla %s sem anel de foco próprio" % nota)
		if anel == null:
			continue
		assert_false(anel.draw_center, "tecla %s: miolo pintado tapa glifo e nome" % nota)
		var banda := float(maxi(maxi(anel.border_width_left, anel.border_width_right),
			maxi(anel.border_width_top, anel.border_width_bottom)))
		var icone: Control = p._key_icons[i]
		var lado: float = minf(icone.size.x, icone.size.y) * ActionIconScript.ICON_FRAC
		var gx: float = icone.position.x + (icone.size.x - lado) * 0.5
		var gy: float = icone.position.y + (icone.size.y - lado) * 0.5
		var folga_glifo: float = minf(minf(gx, btn.size.x - (gx + lado)),
			minf(gy, btn.size.y - (gy + lado)))
		assert_gt(folga_glifo, banda,
			"tecla %s: anel de %.0fpx sobre um glifo que começa a %.1fpx da borda" % [nota, banda, folga_glifo])
		var fonte: Font = btn.get_theme_font("font")
		var tam: Vector2 = fonte.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_CENTER, -1,
			btn.get_theme_font_size("font_size"))
		var folga_nome: float = minf((btn.size.x - tam.x) * 0.5, (btn.size.y - tam.y) * 0.5) \
			- float(btn.get_theme_constant("outline_size"))
		assert_gt(folga_nome, banda,
			"tecla %s: anel de %.0fpx sobre um nome que começa a %.1fpx da borda" % [nota, banda, folga_nome])

func test_the_armed_key_never_leaves_the_gamut():
	# A tela pinta qualquer canal acima de 1,0 como 1,0, mas icon_tint_for,
	# text_outline_px_for, pressed_shade_for e contrast_ratio calculam sobre o
	# número. Sem o clamp de armed_shade() o Si autêntico (o branco #EBE6D9)
	# armado ia a (1,472 / 1,440 / 1,360): a régua lia o glifo a 39,22:1 e o olho
	# via 17,42:1. Nenhuma decisão de tinta ou de halo virava -- mas todas eram
	# tomadas sobre uma cor que a tela nunca chegou a pintar.
	var p = _make()
	var fora: Array[String] = []
	var medidas := 0
	for pistas in [true, false]:
		ColorSchemeSettings.set_control_cues(pistas)
		for esquema in ["classico", "pedagogico", "alto_contraste"]:
			ColorSchemeSettings.set_scheme(esquema)
			p.on_armed_state_changed(true, true)
			for i in range(p._buttons.size()):
				for estado in ["normal", "pressed", "disabled"]:
					var c: Color = p._buttons[i].get_theme_stylebox(estado).bg_color
					medidas += 1
					if maxf(maxf(c.r, c.g), maxf(c.b, c.a)) > 1.0:
						fora.append("%s/%s %s %s: (%.3f, %.3f, %.3f)" % [
							esquema, "pistas" if pistas else "autêntico",
							p._button_notes[i], estado, c.r, c.g, c.b])
	p.on_armed_state_changed(false, false)
	assert_eq(fora.size(), 0,
		"a tela pinta 1,0 e a régua lê outra coisa em: %s" % ", ".join(fora))
	assert_eq(medidas, 12 * 2 * 3 * 3,
		"a varredura de gamut mediu %d styleboxes, e há %d" % [medidas, 12 * 2 * 3 * 3])

func test_key_positions_match_real_keyboard_layout():
	var p = _make()
	var idx_c4 = p._button_notes.find("C4")
	var idx_d4 = p._button_notes.find("D4")
	var idx_cs4 = p._button_notes.find("Cs4")
	assert_eq(p._buttons[idx_c4].position.x, 0.0)
	assert_eq(p._buttons[idx_d4].position.x, 96.0)
	assert_eq(p._buttons[idx_cs4].position.x, 66.0)

func test_black_keys_drawn_on_top_of_white_keys():
	var p = _make()
	var idx_cs4 = p._button_notes.find("Cs4")
	var black_child_index = p._buttons[idx_cs4].get_index()
	for note in ["C4", "D4"]:
		var white_child_index = p._buttons[p._button_notes.find(note)].get_index()
		assert_gt(black_child_index, white_child_index, "tecla preta deve ser filha posterior (desenhada por cima)")

func test_each_key_has_an_icon():
	var p = _make()
	assert_eq(p._key_icons.size(), 12, "um ícone por tecla")
	for icon in p._key_icons:
		assert_not_null(icon._texture, "tecla sem ícone")

func test_key_icon_scales_with_the_key():
	# 24px fixo foi dimensionado pra tecla antiga de 54x160: numa tecla de
	# 96x280 o glifo ficava com ~17px, pequeno demais pro público-alvo
	# (idoso com baixa visão) -- justo a motivação de ter ícone.
	var p = _make()
	var white = p._key_icons[p._button_notes.find("C4")]
	var black = p._key_icons[p._button_notes.find("Cs4")]
	assert_eq(white.size.x, minf((p.WHITE_KEY_WIDTH - 2.0) * 0.5, p.ICON_MAX_SIDE),
		"ícone da tecla branca deve ser metade da largura da tecla (com teto)")
	assert_eq(black.size.x, p.BLACK_KEY_WIDTH * 0.5,
		"ícone da tecla preta deve ser metade da largura da tecla")
	assert_gt(white.size.x, black.size.x, "tecla maior, ícone maior")

func test_key_icons_fit_inside_their_keys():
	# O Control da tecla não faz clip: ícone que vaza da tecla vaza pra tela.
	var p = _make()
	for i in range(p._buttons.size()):
		var btn = p._buttons[i]
		var icon = p._key_icons[i]
		var note = p._button_notes[i]
		assert_between(icon.position.x, 0.0, btn.size.x - icon.size.x, "ícone de %s vaza em X" % note)
		assert_between(icon.position.y, 0.0, btn.size.y - icon.size.y, "ícone de %s vaza em Y" % note)

func test_key_icon_is_below_the_label():
	# O rótulo de texto do Button fica centrado verticalmente; o ícone mora no
	# rodapé da tecla justamente pra não disputar espaço com ele.
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_gt(p._key_icons[idx].position.y, p._buttons[idx].size.y * 0.5,
		"ícone deve ficar abaixo do centro da tecla, onde mora o rótulo")

func test_icon_tint_is_dark_on_light_key():
	# Ícone branco sobre tecla branca dá contraste ~1.25:1 -- abaixo do mínimo
	# 3:1 do WCAG pra elemento gráfico, ou seja, a redundância visual que o
	# ícone existe pra dar simplesmente não acontecia.
	ColorSchemeSettings.set_control_cues(false)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._key_icons[idx]._tint, ColorDistance.ICON_DARK, "tecla branca pede ícone escuro")

func test_icon_tint_is_white_on_dark_key():
	ColorSchemeSettings.set_control_cues(false)
	var p = _make()
	var idx = p._button_notes.find("Cs4")
	assert_eq(p._key_icons[idx]._tint, Color.WHITE, "tecla preta pede ícone branco")

func test_icon_tint_follows_note_color_luminance():
	# Com as pistas ligadas o fundo é a cor da nota, então o tint tem que variar
	# nota a nota. Os hexadecimais citados aqui eram os do Clássico, mas o esquema
	# padrão é o Pedagógico: as asserções passavam por acaso, documentando cores
	# que o teste não estava usando. O esquema agora é escolhido explicitamente.
	ColorSchemeSettings.set_scheme("pedagogico")
	var p = _make()
	assert_eq(NoteMapping.color_for("E4"), Color("#FFF200"), "pré-condição: o Mi é o amarelo claro")
	assert_eq(NoteMapping.color_for("C4"), Color("#9C000A"), "pré-condição: o Dó é o vermelho escuro")
	assert_eq(p._key_icons[p._button_notes.find("E4")]._tint, ColorDistance.ICON_DARK,
		"fundo claro (#FFF200) pede ícone escuro")
	assert_eq(p._key_icons[p._button_notes.find("C4")]._tint, Color.WHITE,
		"fundo escuro (#9C000A) pede ícone branco")

## Pior contraste do NOME contra o que fica ENCOSTADO nele, entre TODOS os
## estados de cor de texto do Button.
##
## O que encosta na letra depende de existir halo. Com contorno, é ele -- os seis
## estados de cor de fonte levam a tinta e o contorno é a tinta oposta. Sem
## contorno, é a própria tecla, e aí os estados de FUNDO passam a importar
## (normal e pressed pintam cores diferentes).
##
## Esta distinção nasceu quando o halo virou exceção em vez de padrão: medir
## sempre contra o halo passaria a medir uma cor que, na maioria das teclas, não
## chega a ser desenhada -- e daria aprovação a um rótulo que ninguém consegue
## ler.
func _pior_contraste_do_rotulo(btn: Button) -> float:
	var halo: Color = btn.get_theme_color("font_outline_color")
	var fundos: Array[Color] = []
	if btn.get_theme_constant("outline_size") >= 2 and halo.a > 0.0:
		fundos.append(halo)
	else:
		for estado in ["normal", "pressed"]:
			var sb := btn.get_theme_stylebox(estado)
			if sb is StyleBoxFlat:
				fundos.append((sb as StyleBoxFlat).bg_color * btn.self_modulate)
	# O acumulador começa em INF porque é o neutro do minf -- e não em 99.0, que era
	# o que tinha antes e o que criava o defeito: com `fundos` vazia (nenhuma
	# stylebox normal/pressed sendo StyleBoxFlat) ou BUTTON_FONT_COLORS vazia, o
	# laço não roda, e o 99.0 saía INTACTO. A função aprovava justamente quando não
	# tinha o que medir. Agora quem não mediu nada reprova alto: devolve 0,0, que é
	# menor que qualquer razão de contraste possível (o mínimo real é 1,0).
	var pior := INF
	var medidas := 0
	for nome in PianoInputScript.BUTTON_FONT_COLORS:
		for fundo in fundos:
			pior = minf(pior, ColorDistance.contrast_ratio(btn.get_theme_color(nome), fundo))
			medidas += 1
	return pior if medidas > 0 else 0.0

func test_key_name_contrasts_with_its_own_key_when_the_cues_are_on():
	# Mesmo defeito que o SpecialActionPanel tinha: a cor mora no bg_color da
	# stylebox (pinta só o FUNDO) e o PianoInput não está sob blindtuner_theme.tres,
	# então o rótulo herdava o cinza claro do tema padrão do Godot. Numa tecla
	# clara da paleta isso era ilegível.
	#
	# A barra é a de texto do WCAG, 4,5. Ela era 4,0 enquanto o nome era lido
	# contra a própria tecla: as cores das paletas embarcadas não chegam lá (o
	# #009218 do Pedagógico dá 4,10 e o #388E3C do Clássico 4,12), porque a cor da
	# nota responde por distinguir a nota das outras 11 e não por contrastar com o
	# rótulo. Com o contorno na tinta oposta, quem encosta na letra é o halo, e as
	# duas exigências deixam de disputar a mesma cor.
	ColorSchemeSettings.set_control_cues(true)
	var p = _make()
	for esquema in ["classico", "pedagogico", "alto_contraste"]:
		ColorSchemeSettings.set_scheme(esquema)
		for i in range(p._buttons.size()):
			assert_ne(p._buttons[i].text, "", "pré-condição: a tecla %s exibe o nome" % p._button_notes[i])
			# A barra é a PROPRIEDADE (o nome é legível), não o MECANISMO (tem
			# contorno). A versão anterior exigia outline_size >= 2 em toda tecla,
			# o que fixava a implementação: quando o halo virou exceção -- ele
			# desenha uma franja branca em volta de letra escura e engorda o traço,
			# então só entra onde a tinta não se vira sozinha -- 11 teclas
			# reprovaram sem que nada tivesse ficado ilegível.
			assert_gte(_pior_contraste_do_rotulo(p._buttons[i]), 4.5,
				"%s: o nome da tecla %s dá %.2f:1 contra o próprio contorno" % [
					esquema, p._button_notes[i], _pior_contraste_do_rotulo(p._buttons[i])])

func test_the_label_ruler_fails_loud_when_it_has_nothing_to_measure():
	# A régua acima é quem decide se o nome da tecla é legível, e ela escolhe o
	# fundo por ramo: com halo mede contra o halo, sem halo mede contra a tecla.
	# Se nenhum dos dois ramos produzir fundo -- basta "normal" e "pressed"
	# deixarem de ser StyleBoxFlat -- o laço interno não roda. Até aqui ela
	# devolvia o sentinela 99.0 nesse caso, ou seja, APROVAVA o rótulo sem ter
	# medido nada. É a mesma família de defeito que a revisão achou nas fitas do
	# braço, e o motivo de a régua reprovar alto agora.
	var btn := Button.new()
	add_child_autofree(btn)
	btn.add_theme_constant_override("outline_size", 0)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	assert_lt(_pior_contraste_do_rotulo(btn), ColorDistance.TEXT_MIN,
		"sem fundo medível a régua tem que reprovar, não aprovar por vacuidade")

func test_the_authentic_keyboard_has_no_names_and_keeps_the_glyphs_legible():
	# Com o interruptor único, "teclado autêntico" e "sem nome" viraram o MESMO
	# estado -- não há mais como ter as duas coisas separadas. O que sobra pra
	# distinguir uma tecla da outra é o glifo, então ele é que precisa de
	# contraste aqui: no fundo branco, ícone branco daria 1,25:1, abaixo do
	# mínimo de 3:1 do WCAG pra elemento gráfico.
	ColorSchemeSettings.set_control_cues(false)
	var p = _make()
	for i in range(p._buttons.size()):
		assert_eq(p._buttons[i].text, "",
			"a tecla %s não pode exibir nome com as pistas desligadas" % p._button_notes[i])
		var fundo: Color = p._buttons[i].get_theme_stylebox("normal").bg_color
		var razao: float = ColorDistance.contrast_ratio(fundo, p._key_icons[i]._tint)
		assert_gte(razao, 3.0,
			"o glifo da tecla %s dá %.2f:1 no teclado autêntico" % [p._button_notes[i], razao])

func test_keys_repaint_when_scheme_changes():
	# Trocar de esquema tem que repintar sem reiniciar a fase.
	var p = _make()
	var idx = p._button_notes.find("C4")
	# A cor da nota mora no bg_color da stylebox (o modulate fica neutro de
	# propósito, senão tingiria o ícone filho junto -- ver I1 do Plano A).
	var antes = p._buttons[idx].get_theme_stylebox("normal").bg_color
	ColorSchemeSettings.set_scheme("alto_contraste")
	var depois = p._buttons[idx].get_theme_stylebox("normal").bg_color
	assert_ne(depois, antes, "as teclas deveriam repintar ao trocar de esquema")
	assert_eq(depois, Color("#0D4A74"), "deveria pintar com a cor do esquema novo")
