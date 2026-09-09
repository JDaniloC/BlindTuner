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

# --- Layout na tela de projeto (720x1280) -------------------------------------
# Mesma rede de segurança de test_playground_input_layout.gd: a janela raiz em
# headless não tem o tamanho de projeto, então medir contra ela daria folga
# demais e deixaria passar transbordo. Foi assim que dois Critical do Plano A
# escaparam da suíte.

const PlaygroundScene := preload("res://scenes/Playground.tscn")

var _screen_vp: SubViewport

func _design_size() -> Vector2i:
	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	return Vector2i(w, h)

func test_color_screen_fits_the_design_screen():
	_screen_vp = SubViewport.new()
	_screen_vp.size = _design_size()
	add_child_autofree(_screen_vp)
	var s = ScreenScene.instantiate()
	_screen_vp.add_child(s)
	await wait_frames(2)
	var visivel := _screen_vp.get_visible_rect()
	assert_true(visivel.encloses(s.get_global_rect()),
		"a tela de cores não cabe em %s: %s" % [visivel, s.get_global_rect()])

func test_opening_from_playground_adds_exactly_one_screen():
	# O handler do Playground usa $UI; só um teste que instancia a cena de jogo
	# de verdade prova que esse caminho existe.
	_screen_vp = SubViewport.new()
	_screen_vp.size = _design_size()
	add_child_autofree(_screen_vp)
	var p = PlaygroundScene.instantiate()
	_screen_vp.add_child(p)
	await wait_frames(2)
	p._on_color_settings_requested()
	p._on_color_settings_requested()  # segunda vez não pode abrir outra
	await wait_frames(2)
	var abertas := 0
	for child in p.get_node("UI").get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("ColorSchemeScreen.gd"):
			abertas += 1
	assert_eq(abertas, 1, "deveria haver exatamente uma tela de cores aberta")

func test_action_buttons_stay_on_screen_with_all_twelve_rows():
	# A lista de 12 linhas fica num ScrollContainer justamente pra não empurrar
	# "Restaurar" e "Fechar" pra fora em 1280px de altura. Se alguém trocar o
	# ScrollContainer por um VBox solto, é aqui que quebra.
	_screen_vp = SubViewport.new()
	_screen_vp.size = _design_size()
	add_child_autofree(_screen_vp)
	var s = ScreenScene.instantiate()
	_screen_vp.add_child(s)
	await wait_frames(2)
	var visivel := _screen_vp.get_visible_rect()
	assert_true(visivel.encloses(s._reset_btn.get_global_rect()),
		"botão de restaurar fora da tela: %s" % s._reset_btn.get_global_rect())
	assert_true(visivel.encloses(s._close_btn.get_global_rect()),
		"botão de fechar fora da tela: %s" % s._close_btn.get_global_rect())
