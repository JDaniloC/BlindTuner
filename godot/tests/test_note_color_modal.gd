extends GutTest

const ModalScene := preload("res://scenes/NoteColorModal.tscn")

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
