extends GutTest

const ModalScene := preload("res://scenes/NoteColorModal.tscn")
const CD := preload("res://scripts/ColorDistance.gd")

## Nunca o arquivo real do jogador -- ver test_color_scheme_settings.gd.
const TEST_PATH := "user://test_note_modal.cfg"

func before_each():
	ColorSchemeSettings.config_path = TEST_PATH
	ColorSchemeSettings.reset_to_defaults()
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)

func after_each():
	ColorSchemeSettings.reset_to_defaults()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	ColorSchemeSettings.config_path = ColorSchemeSettings.CONFIG_PATH

func _make():
	var m = ModalScene.instantiate()
	add_child_autofree(m)
	return m

func test_open_for_shows_the_current_color_of_that_note():
	var m = _make()
	m.open_for(0)
	assert_eq(m._pending, NoteMapping.color_for("C4"))

func test_open_for_makes_it_visible():
	var m = _make()
	assert_false(m.visible, "começa escondido")
	m.open_for(0)
	assert_true(m.visible)

func test_open_for_out_of_range_does_not_open_or_crash():
	var m = _make()
	m.open_for(99)
	assert_false(m.visible, "índice inválido não abre o modal")

func test_open_for_syncs_the_hue_slider_with_the_note_color():
	# O slider é o ÚNICO controle de edição do modal e não era asseverado.
	var m = _make()
	m.open_for(0)
	assert_almost_eq(m._hue.value, NoteMapping.color_for("C4").h * 360.0, 1.0)

func test_hue_slider_is_a_large_touch_target():
	# A spec pede slider grande; o padrão do tema é um fio de ~8px com pegador
	# de 16x16, hostil pra baixa visão e motricidade reduzida.
	var m = _make()
	assert_gte(m._hue.custom_minimum_size.y, 44.0)

func test_changing_hue_updates_the_preview():
	var m = _make()
	m.open_for(0)
	m._on_hue_changed(200.0)
	assert_eq(m._preview.color, m._pending, "o preview precisa acompanhar a cor pendente")

func test_changing_hue_keeps_saturation_and_value():
	var m = _make()
	m.open_for(0)
	var antes = m._pending
	m._on_hue_changed(200.0)
	assert_almost_eq(m._pending.s, antes.s, 0.02)
	assert_almost_eq(m._pending.v, antes.v, 0.02)

func test_no_warning_before_the_player_touches_anything():
	# O Alto Contraste repete matiz entre natural e sustenido DE PROPÓSITO, o
	# que acendia o aviso em 8 das 12 notas assim que o modal abria. O jogador
	# não é culpado por um conflito que veio de fábrica.
	ColorSchemeSettings.reset_to_defaults()
	ColorSchemeSettings.set_scheme("alto_contraste")
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	var m = _make()
	for i in range(12):
		m.open_for(i)
		assert_false(m._warning.visible,
			"nota %d não pode avisar antes de o jogador mexer" % i)

func test_conflict_warning_appears_for_a_near_duplicate():
	var m = _make()
	m.open_for(0)
	# Copia a cor da nota vizinha -- conflito garantido.
	m._set_pending(NoteMapping.color_for("Cs4"))
	assert_true(m._warning.visible, "deveria avisar que ficou parecida com outra nota")
	assert_true(m._warning_label.text.contains(NoteMapping.label_for("Cs4")),
		"o aviso precisa dizer COM QUAL nota conflita")

func test_no_warning_for_a_distinct_color():
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("C4"))
	assert_false(m._warning.visible, "a própria cor da nota não conflita consigo mesma")

func test_warning_never_blocks_confirmation():
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	assert_false(m._confirm_btn.disabled, "o aviso é não-bloqueante; a escolha é do jogador")

func test_keep_anyway_dismisses_the_warning_without_changing_the_color():
	# A spec exige uma saída que preserve a escolha do jogador, não só a que
	# "corrige" pra ele.
	var m = _make()
	m.open_for(0)
	var escolhida = NoteMapping.color_for("Cs4")
	m._set_pending(escolhida)
	assert_true(m._warning.visible)
	m._on_keep_pressed()
	assert_false(m._warning.visible, "o aviso some")
	assert_eq(m._pending, escolhida, "mas a cor escolhida continua intacta")

func test_auto_adjust_resolves_the_conflict():
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	m._on_auto_adjust_pressed()
	assert_false(m._warning.visible, "depois do ajuste automático não deveria haver conflito")

func test_auto_adjust_syncs_the_slider():
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	m._on_auto_adjust_pressed()
	assert_almost_eq(m._hue.value, m._pending.h * 360.0, 1.0,
		"o slider precisa acompanhar o ajuste automático")

func test_confirm_applies_the_color_to_the_scheme():
	var m = _make()
	m.open_for(0)
	m._set_pending(Color("#123456"))
	m._on_confirm_pressed()
	assert_eq(NoteMapping.color_for("C4"), Color("#123456"))

func test_cancel_does_not_apply():
	var m = _make()
	var antes = NoteMapping.color_for("C4")
	m.open_for(0)
	m._set_pending(Color("#123456"))
	m._on_cancel_pressed()
	assert_eq(NoteMapping.color_for("C4"), antes, "cancelar não pode alterar a paleta")

func test_a_factory_conflict_is_not_blamed_on_the_player_after_one_slider_step():
	# O flag "já mexeu" só adiava o problema um passo: no Alto Contraste, 8 das 12
	# notas já nascem em conflito (o sustenido é a natural com L* +10), e um grau
	# de slider acendia o aviso acusando o jogador por isso.
	ColorSchemeSettings.reset_to_defaults()
	ColorSchemeSettings.set_scheme("alto_contraste")
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	var m = _make()
	m.open_for(0)  # Dó, que conflita de fábrica com o Dó#
	assert_false(CD.conflicts_for(m._pending, ColorSchemeSettings.active_palette(), 0).is_empty(),
		"pré-condição: a cor de fábrica do Dó conflita mesmo com outra nota")
	m._on_hue_changed(m._hue.value + 1.0)
	assert_false(m._warning.visible,
		"um grau de slider não pode fazer o jogo acusar um conflito de fábrica")

func test_the_warning_still_appears_when_the_player_creates_the_conflict():
	# A contrapartida do teste acima: o aviso não pode ter virado decorativo.
	ColorSchemeSettings.reset_to_defaults()
	ColorSchemeSettings.set_scheme("alto_contraste")
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))  # copiou a cor da vizinha
	assert_true(m._warning.visible, "agravar um conflito até a cor idêntica precisa avisar")

func test_reopening_a_note_the_player_broke_keeps_warning_about_it():
	# Regressão: a linha de base saía da cor ATUAL da nota. Quem confirmasse (por
	# engano, ou depois de "Manter assim mesmo") uma cor idêntica à do Dó# e
	# reabrisse o Dó justamente para consertar recebia {Dó#: ~0} como linha de
	# base -- e como ΔE nunca é negativo, "atuais >= antes - AGRAVO_MIN" ficava
	# sempre verdadeiro. O conflito que o jogador criou virava desculpa para si
	# mesmo, e o editor cegava justamente na nota que ele já tinha errado.
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	m._on_confirm_pressed()

	m.open_for(0)
	assert_true(m._warning.visible, "reabrir a nota errada tem que continuar avisando")
	assert_true(m._warning_label.text.contains(NoteMapping.label_for("Cs4")),
		"o aviso precisa nomear o Dó#, que é com quem a cor gravada colide")

func test_a_broken_note_still_warns_when_the_player_slides_back_onto_the_conflict():
	# O mesmo beco dentro de UMA sessão de edição: com a linha de base
	# contaminada, o aviso funcionava nos outros matizes e emudecia justamente
	# quando o jogador voltava para a cor que colide.
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	m._on_confirm_pressed()

	m.open_for(0)
	m._on_hue_changed(150.0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	assert_true(m._warning.visible, "voltar para a cor que colide não pode emudecer o aviso")

func test_reopening_a_note_edited_to_a_distinct_color_stays_quiet():
	# A contrapartida: tirar o álibi da cor gravada não pode transformar o modal
	# num acusador que abre gritando. Cor sem conflito nenhum continua sem aviso.
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	m._on_auto_adjust_pressed()
	m._on_confirm_pressed()

	m.open_for(0)
	assert_false(m._warning.visible, "cor sem conflito não pode avisar ao reabrir")

func test_no_scheme_opens_the_editor_already_accusing_the_player():
	# Contrapartida do achado acima, nos TRÊS esquemas e nas 12 notas: a linha de
	# base passou a exigir cor de fábrica, e o risco de conserto era o modal virar
	# acusador e abrir gritando em cima de uma paleta que o jogador nem tocou.
	# O Clássico entra de propósito -- é a paleta reconhecidamente ruim (Ré e Lá a
	# ΔE ~8), e nem ela pode ser cobrada de quem só a escolheu.
	for id in ColorSchemes.SCHEME_IDS:
		ColorSchemeSettings.reset_to_defaults()
		ColorSchemeSettings.set_scheme(id)
		ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
		var m = _make()
		for i in range(12):
			m.open_for(i)
			assert_false(m._warning.visible,
				"%s: nota %d acusada sem o jogador ter mexido em nada" % [id, i])

func test_auto_adjust_still_works_on_a_note_reopened_in_conflict():
	# Caminho novo criado pelo conserto: o aviso agora aparece já na abertura de
	# uma nota que o jogador estragou. A saída oferecida ali não pode ser um botão
	# que não resolve nada.
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	m._on_confirm_pressed()

	m.open_for(0)
	assert_true(m._warning.visible, "pré-condição: reabre avisando")
	m._on_auto_adjust_pressed()
	assert_false(m._warning.visible, "'Ajustar automaticamente' precisa resolver o conflito")
	assert_true(CD.conflicts_for(m._pending, ColorSchemeSettings.active_palette(), 0).is_empty(),
		"e resolver de verdade, não só esconder o aviso")

func test_warning_text_is_readable_against_the_warning_panel():
	# O painel ganhou fundo próprio, mas o Label herdava a fonte escura do tema:
	# 1,53:1, abaixo até do piso de 3:1 de texto grande. É a única frase que
	# explica por que o aviso apareceu.
	var m = _make()
	var fundo = m._warning.get_theme_stylebox("panel").bg_color
	var texto = m._warning_label.get_theme_color("font_color")
	var razao = CD.contrast_ratio(texto, fundo)
	assert_gte(razao, 4.5,
		"texto do aviso a %.2f:1 sobre o painel -- ilegível para o público do jogo" % razao)

func test_warning_panel_is_visually_distinct_from_the_screen_background():
	var m = _make()
	var estilo = m._warning.get_theme_stylebox("panel")
	assert_true(estilo is StyleBoxFlat, "o aviso precisa de fundo próprio, não o painel padrão")
	assert_eq(estilo.bg_color, m.WARNING_BG)

func test_preview_has_a_dark_frame_so_light_colors_stay_visible():
	# Mesma razão dos swatches da lista: o Si do Pedagógico (#FFADFB) some contra
	# um fundo claro, e o preview é a tela onde o jogador julga aquela cor.
	var m = _make()
	var moldura = m._preview.get_parent()
	assert_true(moldura is PanelContainer, "o preview precisa estar dentro da moldura")
	assert_eq(moldura.get_theme_stylebox("panel").bg_color, m.BORDER)

func test_hue_track_spectrum_is_not_covered_by_the_default_grabber_area():
	# O tema do projeto não define HSlider: sem override, o "grabber_area" padrão
	# da engine desenha por cima do trilho, da borda esquerda até o pegador, e
	# lava o pedaço do espectro para onde o jogador arrasta.
	var m = _make()
	assert_true(m._hue.get_theme_stylebox("grabber_area") is StyleBoxEmpty,
		"o espectro do trilho não pode ficar coberto")
	assert_true(m._hue.get_theme_stylebox("slider") is StyleBoxTexture,
		"o trilho precisa continuar sendo o espectro de matiz")
