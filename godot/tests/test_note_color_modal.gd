extends GutTest

const ModalScene := preload("res://scenes/NoteColorModal.tscn")

func before_each():
	ColorSchemeSettings.reset_to_defaults()
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)

func after_each():
	ColorSchemeSettings.reset_to_defaults()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ColorSchemeSettings.CONFIG_PATH))

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

func test_changing_hue_keeps_saturation_and_value():
	var m = _make()
	m.open_for(0)
	var antes = m._pending
	m._on_hue_changed(200.0)
	assert_almost_eq(m._pending.s, antes.s, 0.02)
	assert_almost_eq(m._pending.v, antes.v, 0.02)

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

func test_auto_adjust_resolves_the_conflict():
	var m = _make()
	m.open_for(0)
	m._set_pending(NoteMapping.color_for("Cs4"))
	m._on_auto_adjust_pressed()
	assert_false(m._warning.visible, "depois do ajuste automático não deveria haver conflito")

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
