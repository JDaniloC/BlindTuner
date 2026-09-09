extends GutTest

const ScreenScene := preload("res://scenes/ColorSchemeScreen.tscn")

func before_each():
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	ColorSchemeSettings.reset_to_defaults()
	# A tela salva em disco ao trocar de esquema; não deixar o arquivo pra trás,
	# senão o autoload de uma execução seguinte carregaria estado de teste.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ColorSchemeSettings.CONFIG_PATH))

func _make():
	var s = ScreenScene.instantiate()
	add_child_autofree(s)
	return s

func test_lists_all_twelve_notes():
	var s = _make()
	assert_eq(s._rows.size(), 12)

func test_swatches_are_large_enough_for_low_vision():
	var s = _make()
	for row in s._rows:
		assert_gte(row.swatch.custom_minimum_size.x, 44.0, "swatch menor que o alvo mínimo de toque")
		assert_gte(row.swatch.custom_minimum_size.y, 44.0)

func test_each_row_shows_the_note_label():
	var s = _make()
	var keys = NoteMapping.NOTES.keys()
	for i in range(12):
		assert_eq(s._rows[i].label.text, NoteMapping.label_for(keys[i]))

func test_scheme_selector_lists_all_schemes_plus_custom():
	var s = _make()
	assert_eq(s._scheme_opt.item_count, ColorSchemes.SCHEME_IDS.size() + 1,
		"3 esquemas fixos + personalizado")

func test_choosing_a_scheme_updates_the_swatches():
	var s = _make()
	s._on_scheme_selected(ColorSchemes.SCHEME_IDS.find("alto_contraste"))
	assert_eq(s._rows[0].swatch.color, Color("#0D4A74"))

func test_swatches_follow_the_default_scheme_on_open():
	var s = _make()
	assert_eq(s._rows[0].swatch.color, Color("#9C000A"), "abre mostrando o esquema ativo")

func test_edit_buttons_only_enabled_in_custom_scheme():
	var s = _make()
	assert_true(s._rows[0].button.disabled, "esquema fixo não é editável")
	s._on_scheme_selected(ColorSchemes.SCHEME_IDS.size())  # Personalizado
	assert_false(s._rows[0].button.disabled, "personalizado é editável")

func test_reset_button_restores_defaults():
	var s = _make()
	ColorSchemeSettings.set_scheme("alto_contraste")
	s._on_reset_pressed()
	assert_eq(ColorSchemeSettings.scheme_id, "pedagogico")

func test_close_emits_signal():
	var s = ScreenScene.instantiate()
	add_child(s)
	watch_signals(s)
	s._on_close_pressed()
	assert_signal_emitted(s, "closed")
