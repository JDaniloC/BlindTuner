extends GutTest

const ScreenScene := preload("res://scenes/ColorSchemeScreen.tscn")

## A tela salva em disco a cada troca de esquema. Redireciona o autoload para um
## arquivo de teste: antes daqui a suíte gravava e apagava o color_scheme.cfg
## REAL, destruindo a paleta de quem joga na mesma máquina.
const TEST_PATH := "user://test_color_screen.cfg"

func before_each():
	ColorSchemeSettings.config_path = TEST_PATH
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	ColorSchemeSettings.reset_to_defaults()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	ColorSchemeSettings.config_path = ColorSchemeSettings.CONFIG_PATH

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

func test_reset_asks_for_confirmation_before_wiping():
	# O botão fica colado no "Fechar" e apagava as 12 cores personalizadas na
	# hora, gravando em disco. Agora só abre a confirmação.
	var s = _make()
	ColorSchemeSettings.set_scheme("alto_contraste")
	assert_false(s._confirm_panel.visible, "confirmação começa escondida")
	s._on_reset_pressed()
	assert_true(s._confirm_panel.visible, "deveria pedir confirmação")
	assert_eq(ColorSchemeSettings.scheme_id, "alto_contraste", "nada muda antes de confirmar")

func test_reset_confirmed_restores_defaults():
	var s = _make()
	ColorSchemeSettings.set_scheme("alto_contraste")
	s._on_reset_pressed()
	s._on_reset_confirmed()
	assert_eq(ColorSchemeSettings.scheme_id, "pedagogico")
	assert_false(s._confirm_panel.visible)

func test_reset_cancelled_keeps_everything():
	var s = _make()
	ColorSchemeSettings.set_scheme("alto_contraste")
	s._on_reset_pressed()
	s._on_reset_cancelled()
	assert_false(s._confirm_panel.visible)
	assert_eq(ColorSchemeSettings.scheme_id, "alto_contraste", "cancelar não pode restaurar")

func test_peeking_at_custom_in_the_dropdown_does_not_freeze_the_palette():
	# Caminho pela UI, que é onde o beco sem saída aparecia: a tela grava em disco
	# a cada troca, então espiar "Personalizado" gravava 12 cores semeadas e a
	# única saída passava a ser "Restaurar tudo ao padrão".
	var s = _make()
	var custom_idx: int = ColorSchemes.SCHEME_IDS.size()
	s._on_scheme_selected(custom_idx)                                    # espiou
	s._on_scheme_selected(ColorSchemes.SCHEME_IDS.find("alto_contraste"))
	s._on_scheme_selected(custom_idx)
	assert_eq(s._rows[0].swatch.color, Color("#0D4A74"),
		"o editor tem que partir do Alto Contraste, o esquema que estava na tela")

func test_edit_buttons_have_readable_disabled_text():
	# Estado em que a tela SEMPRE abre (esquema fixo): o padrão do tema deixava
	# o rótulo em 1,14:1 contra o fundo do botão.
	var s = _make()
	var cor = s._rows[0].button.get_theme_color("font_disabled_color")
	assert_eq(cor, s.DISABLED_TEXT, "precisa de override de cor no estado desabilitado")

func test_sync_selector_matches_the_active_scheme():
	var s = _make()
	ColorSchemeSettings.set_scheme("alto_contraste")
	s._sync_selector()
	assert_eq(s._scheme_opt.selected, ColorSchemes.SCHEME_IDS.find("alto_contraste"))
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	s._sync_selector()
	assert_eq(s._scheme_opt.selected, ColorSchemes.SCHEME_IDS.size(),
		"personalizado é o último item da lista")

func test_swatch_has_dark_border_so_light_colors_stay_visible():
	# O Si do Pedagógico (#FFADFB) e o Lá# do Alto Contraste (#A5EEFE) somem
	# contra fundo claro sem moldura.
	var s = _make()
	var moldura = s._rows[0].swatch.get_parent()
	assert_true(moldura is PanelContainer, "o swatch precisa estar dentro da moldura")
	var estilo = moldura.get_theme_stylebox("panel")
	assert_eq(estilo.bg_color, s.SWATCH_BORDER)

func test_opening_the_editor_closes_a_pending_reset_confirmation():
	# A confirmação ficava aberta por trás do modal e reaparecia quando o jogador
	# confirmasse a cor, com o botão "Restaurar" à mostra -- que se lê como
	# confirmação da cor recém escolhida, e apaga as 12 personalizadas.
	var s = _make()
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	s._on_reset_pressed()
	assert_true(s._confirm_panel.visible, "pré-condição: a confirmação está aberta")
	s._on_edit_pressed(1)
	assert_false(s._confirm_panel.visible, "abrir o editor tem que fechar a confirmação")
	s._modal._set_pending(Color("#123456"))
	s._modal._on_confirm_pressed()
	assert_false(s._confirm_panel.visible,
		"confirmar a cor não pode devolver o botão Restaurar para a tela")

func test_editing_a_color_updates_the_row_swatch():
	# Caminho de integração completo: Editar -> modal abre -> confirma -> o
	# swatch da lista reflete a cor nova.
	var s = _make()
	ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	s._on_edit_pressed(0)
	assert_true(s._modal.visible, "o modal deveria ter aberto")
	s._modal._set_pending(Color("#123456"))
	s._modal._on_confirm_pressed()
	assert_eq(s._rows[0].swatch.color, Color("#123456"))

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

func test_color_screen_rows_fit_the_design_width():
	# A versão anterior deste teste media o retângulo da PRÓPRIA tela, que é
	# ancorada em FULL_RECT -- ou seja, sempre exatamente igual ao viewport, e a
	# asserção não tinha como falhar. O que pode transbordar de verdade é o
	# CONTEÚDO: uma linha (moldura + swatch + rótulo + botão) mais larga que 720.
	_screen_vp = SubViewport.new()
	_screen_vp.size = _design_size()
	add_child_autofree(_screen_vp)
	var s = ScreenScene.instantiate()
	_screen_vp.add_child(s)
	await wait_frames(2)
	var visivel := _screen_vp.get_visible_rect()
	for i in range(s._rows.size()):
		var linha: Control = s._rows[i].button.get_parent()
		var r := linha.get_global_rect()
		assert_lte(r.end.x, visivel.end.x,
			"a linha da nota %d passa da borda direita (%s > %s)" % [i, r.end.x, visivel.end.x])
		assert_gte(r.position.x, visivel.position.x,
			"a linha da nota %d começa antes da borda esquerda" % i)

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
