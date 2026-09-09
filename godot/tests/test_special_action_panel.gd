extends GutTest

const PanelScene := preload("res://scenes/SpecialActionPanel.tscn")
# ColorDistance é RefCounted, não autoload -- precisa de preload pra ser usado.
const ColorDistance := preload("res://scripts/ColorDistance.gd")

func _make() -> Node:
	var p = PanelScene.instantiate()
	add_child_autofree(p)
	return p

## Cor da placa do botão. Ela mora na StyleBoxFlat e NÃO no modulate: modulate
## se propaga pros filhos, e tingir o botão com a cor da nota deixava o ícone
## branco exatamente da cor do próprio fundo -- invisível.
func _bg(btn: Button) -> Color:
	return btn.get_theme_stylebox("normal").bg_color

func before_each():
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	# O painel não consulta mais o nível de pista, mas há teste aqui que o sobe
	# justamente para provar isso -- e CueSettings é autoload, não se reseta
	# sozinho. reset_to_defaults() religa o interruptor de pistas junto.
	CueSettings.set_level(0)
	ColorSchemeSettings.reset_to_defaults()

func test_four_buttons_created():
	var p = _make()
	assert_eq(p._buttons.size(), 4)

func test_button_notes_in_expected_order():
	var p = _make()
	assert_eq(p._button_notes, ["Gs4", "A4", "As4", "B4"])

func test_button_press_emits_note_triggered_gs4():
	var p = _make()
	watch_signals(p)
	p._buttons[0].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["Gs4"])

func test_button_press_emits_note_triggered_a4():
	var p = _make()
	watch_signals(p)
	p._buttons[1].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["A4"])

func test_button_press_emits_note_triggered_as4():
	var p = _make()
	watch_signals(p)
	p._buttons[2].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["As4"])

func test_button_press_emits_note_triggered_b4():
	var p = _make()
	watch_signals(p)
	p._buttons[3].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["B4"])

func test_panel_visible_in_all_cue_levels():
	var p = _make()
	for lvl in range(4):
		CueSettings.set_level(lvl)
		assert_true(p.visible, "nível %d: painel visível" % lvl)

func test_control_cues_on_shows_name_and_color():
	var p = _make()
	assert_eq(p._labels[0].text, NoteMapping.label_for("Gs4"))
	assert_eq(_bg(p._buttons[0]), NoteMapping.color_for("Gs4"))

func test_control_cues_off_is_neutral_and_empty():
	ColorSchemeSettings.set_control_cues(false)
	var p = _make()
	assert_eq(p._labels[0].text, "")
	assert_eq(_bg(p._buttons[0]), p.NEUTRAL_BUTTON)

func test_flipping_the_switch_repaints_without_restarting():
	# Este painel NÃO escutava o interruptor: só se repintava de carona no sinal
	# do nível de pista. Sem a conexão de control_cues_changed, virar a chave não
	# mexeria nas 4 placas até a fase reiniciar -- e nenhum outro teste pega isso.
	var p = _make()
	ColorSchemeSettings.set_control_cues(false)
	assert_eq(_bg(p._buttons[0]), p.NEUTRAL_BUTTON, "a placa tem que ficar neutra na hora")
	assert_eq(p._labels[0].text, "", "o nome tem que sumir na hora")
	ColorSchemeSettings.set_control_cues(true)
	assert_eq(_bg(p._buttons[0]), NoteMapping.color_for("Gs4"), "e voltar na hora")
	assert_eq(p._labels[0].text, NoteMapping.label_for("Gs4"))

func test_the_cue_level_no_longer_touches_the_plates():
	# A consequência deliberada da inversão: em TODOS os níveis, inclusive o "só
	# som", as placas continuam coloridas e nomeadas se o interruptor estiver
	# ligado. Parece bug e alguém vai querer "consertar" um dia -- não é: o
	# desafio é reconhecer a nota tocada de ouvido, não adivinhar onde ela mora.
	var p = _make()
	for lvl in range(4):
		CueSettings.set_level(lvl)
		assert_eq(p._labels[0].text, NoteMapping.label_for("Gs4"),
			"nível %d: o nome da placa é material didático, não dificuldade" % lvl)
		assert_eq(_bg(p._buttons[0]), NoteMapping.color_for("Gs4"),
			"nível %d: a cor da placa é material didático, não dificuldade" % lvl)

const ActionIconScript := preload("res://scripts/ActionIcon.gd")

func test_each_button_has_action_icon_child():
	var p = _make()
	var expected_actions = ["interagir", "pegar", "correr", "pular"]
	for i in range(p._buttons.size()):
		var btn = p._buttons[i]
		# O ícone é NETO do botão desde que glifo e nome passaram a viver numa
		# VBox que os centra como um grupo -- busca recursiva, não só nos filhos.
		var icon: Node = null
		for child in btn.find_children("*", "", true, false):
			if child.get_script() == ActionIconScript:
				icon = child
				break
		assert_not_null(icon, "botão %d sem ActionIcon" % i)
		assert_eq(icon.action_id, expected_actions[i],
			"ActionIcon do botão %d deveria ser %s" % [i, expected_actions[i]])

func test_set_action_updates_action_id():
	var icon = ActionIconScript.new()
	icon.size = Vector2(64, 64)
	add_child_autofree(icon)
	icon.set_action("pular")
	assert_eq(icon.action_id, "pular")

func test_action_icon_ignores_unknown_action():
	var icon = ActionIconScript.new()
	icon.size = Vector2(64, 64)
	add_child_autofree(icon)
	icon.set_action("inexistente")
	await get_tree().process_frame  # força _draw() para garantir que o match no-op não quebra
	assert_eq(icon.action_id, "inexistente")

func test_on_armed_state_changed_brightens_correr_button():
	var p = _make()
	var base = _bg(p._buttons[2])  # As4 = correr (índice 2)
	p.on_armed_state_changed(true, false)
	assert_gt(_bg(p._buttons[2]).get_luminance(), base.get_luminance(), "armed brighten")
	assert_eq(p._armed, [false, false, true, false])

func test_on_armed_state_changed_brightens_pular_button():
	var p = _make()
	var base = _bg(p._buttons[3])  # B4 = pular (índice 3)
	p.on_armed_state_changed(false, true)
	assert_gt(_bg(p._buttons[3]).get_luminance(), base.get_luminance(), "armed brighten")
	assert_eq(p._armed, [false, false, false, true])

func test_disarm_restores_plate_color_to_cue_base():
	var p = _make()
	var base = _bg(p._buttons[2])
	p.on_armed_state_changed(true, false)
	p.on_armed_state_changed(false, false)
	assert_eq(_bg(p._buttons[2]), base, "a placa volta ao base após disarm")

func test_armed_brighten_respects_the_neutral_plate():
	# Com o interruptor desligado a cor base é NEUTRAL_BUTTON; armed multiplica
	# em cima dela, e não da cor da nota.
	var p = _make()
	ColorSchemeSettings.set_control_cues(false)
	p.on_armed_state_changed(true, false)
	var expected = Color(p.NEUTRAL_BUTTON.r * p.ARMED_BRIGHTNESS,
		p.NEUTRAL_BUTTON.g * p.ARMED_BRIGHTNESS,
		p.NEUTRAL_BUTTON.b * p.ARMED_BRIGHTNESS, p.NEUTRAL_BUTTON.a)
	assert_eq(_bg(p._buttons[2]), expected)

func test_buttons_repaint_when_scheme_changes():
	var p = _make()
	var antes = _bg(p._buttons[0])
	ColorSchemeSettings.set_scheme("alto_contraste")
	var depois = _bg(p._buttons[0])
	assert_ne(antes, depois, "os botões de ação deveriam seguir o esquema ativo")
	ColorSchemeSettings.reset_to_defaults()

func test_action_icons_have_nonzero_width():
	# Regressão: set_anchors_preset com keep_offsets preservava o rect 0x0 do
	# Control recém-criado, e o ícone desenhava um retângulo de lado zero --
	# invisível, sem erro nem warning.
	var p = _make()
	await wait_frames(2)  # o GridContainer só dimensiona os botões no sort
	for i in range(p._buttons.size()):
		for child in p._buttons[i].find_children("*", "", true, false):
			if child.get_script() == ActionIconScript:
				assert_gt(child.size.x, 0.0, "ícone %d com largura zero não desenha nada" % i)
				assert_gt(child.size.y, 0.0, "ícone %d com altura zero não desenha nada" % i)

func test_button_color_is_in_the_stylebox_not_in_modulate():
	# modulate propaga pros filhos: com a cor da nota no modulate, o ícone
	# branco vira exatamente a cor do fundo do botão.
	var p = _make()
	assert_eq(p._buttons[0].modulate, Color.WHITE, "a cor não pode morar no modulate")
	assert_eq(_bg(p._buttons[0]), NoteMapping.color_for("Gs4"))

func test_icon_tint_contrasts_with_its_own_button():
	var p = _make()
	for i in range(p._buttons.size()):
		var fundo = _bg(p._buttons[i])
		for child in p._buttons[i].find_children("*", "", true, false):
			if child.get_script() == ActionIconScript:
				assert_gt(ColorDistance.contrast_ratio(fundo, child._tint), 3.0,
					"glifo do botão %d se confunde com a própria placa" % i)

## O nome saiu do Button.text para uma Label dentro da VBox que centra glifo e
## nome como um grupo. Isso simplificou o contraste: uma Label tem UM estado de
## cor, enquanto o Button ainda clareava o rótulo no hover/pressed/focus e exigia
## sobrescrever os cinco.
func _piores_contrastes(lbl: Label, fundo: Color) -> Array:
	return [ColorDistance.contrast_ratio(fundo, lbl.get_theme_color("font_color")), "font_color"]

func test_note_name_contrasts_with_its_own_plate():
	# Regressão da rodada 3: a cor da nota saiu do modulate (que tingia o rótulo
	# junto, por acidente) e foi pro bg_color da StyleBoxFlat, que pinta só o
	# FUNDO. O nome ficou no cinza claro do tema padrão do Godot -- e este painel
	# NÃO está sob blindtuner_theme.tres, é irmão do GameHUD na CanvasLayer.
	# Medido no esquema de fábrica: 1,25:1 no Si, 1,36:1 no Lá. Ilegível.
	#
	# O nome aparece sempre que o interruptor de pistas estiver ligado, que é o
	# padrão de fábrica -- ou seja, este é o caso comum, não o caso de borda.
	var p = _make()
	for esquema in ["classico", "pedagogico", "alto_contraste"]:
		ColorSchemeSettings.set_scheme(esquema)
		for i in range(p._buttons.size()):
			assert_ne(p._labels[i].text, "", "pré-condição: o botão %d exibe o nome" % i)
			var res := _piores_contrastes(p._labels[i], _bg(p._buttons[i]))
			assert_gte(res[0], 4.5,
				"%s: o nome do botão %d dá %.2f:1 contra a própria placa em %s (WCAG pede 4,5:1 pra texto)" % [
					esquema, i, res[0], res[1]])

func test_note_name_stays_legible_while_the_action_is_armed():
	# A placa armada é a MESMA cor multiplicada por 1.6, e o corte de luminância
	# pode virar a tinta do rótulo do claro pro escuro no meio do caminho. Aqui a
	# barra é a de elemento gráfico (3:1) e não a de texto (4,5:1): o pior caso
	# medido é o azul #3949ab do Clássico clareado, que dá 3,70:1, e o estado é
	# transitório -- some assim que a ação dispara.
	var p = _make()
	for esquema in ["classico", "pedagogico", "alto_contraste"]:
		ColorSchemeSettings.set_scheme(esquema)
		p.on_armed_state_changed(true, true)
		for i in [2, 3]:  # correr e pular são as únicas armáveis
			var res := _piores_contrastes(p._labels[i], _bg(p._buttons[i]))
			assert_gte(res[0], 3.0,
				"%s: o nome do botão armado %d dá %.2f:1 em %s" % [esquema, i, res[0], res[1]])
	p.on_armed_state_changed(false, false)

func test_icon_and_label_have_breathing_room_between_them():
	# O nome colava no glifo: o ícone era ancorado na faixa de cima do botão e
	# o nome era o text do Button, que o Godot centra no botão INTEIRO.
	var p = _make()
	await wait_frames(2)
	for i in range(p._buttons.size()):
		var fim_do_glifo = p._icons[i].position.y + p._icons[i].size.y
		var topo_do_nome = p._labels[i].position.y
		assert_gte(topo_do_nome - fim_do_glifo, float(p.ICON_TEXT_GAP) - 0.5,
			"botão %d: glifo e nome sem respiro entre eles" % i)

func test_icon_and_label_are_centered_as_a_group():
	var p = _make()
	await wait_frames(2)
	for i in range(p._buttons.size()):
		var topo = p._icons[i].position.y
		var base = p._labels[i].position.y + p._labels[i].size.y
		var centro_do_grupo = (topo + base) * 0.5
		var centro_do_botao = p._buttons[i].size.y * 0.5
		assert_almost_eq(centro_do_grupo, centro_do_botao, 2.0,
			"botão %d: o par glifo+nome não está centrado" % i)

func test_children_do_not_swallow_the_press():
	# Regressão em potencial: um Control filho com mouse_filter STOP come o
	# clique e o botão inteiro para de responder.
	var p = _make()
	for i in range(p._buttons.size()):
		assert_eq(p._labels[i].mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_eq(p._icons[i].mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_eq(p._labels[i].get_parent().mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_label_is_hidden_when_the_control_cues_are_off():
	# Escondida, não só vazia: uma Label vazia ainda reserva a altura da linha
	# na VBox e o glifo ficaria alto em vez de centrado sozinho.
	var p = _make()
	ColorSchemeSettings.set_control_cues(false)
	for lbl in p._labels:
		assert_false(lbl.visible)
