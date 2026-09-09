extends GutTest

const HudScene := preload("res://scenes/GameHUD.tscn")

## Arquivo próprio para o teste do botão de pintura, que dispara save_to_disk()
## no autoload de verdade. Sem a redireção a suíte sobrescreveria o
## color_scheme.cfg REAL de quem joga na mesma máquina.
const PAINT_TEST_PATH := "user://test_hud_paint.cfg"

func _hud() -> Node:
	var h = HudScene.instantiate()
	add_child_autofree(h)
	return h

## A restauração mora aqui, e não no fim do teste: se ele falhar no meio, a
## redireção vazaria para os outros scripts da suíte -- e o próximo save_to_disk()
## de qualquer um deles cairia no arquivo do jogador.
func after_each():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PAINT_TEST_PATH))
	ColorSchemeSettings.config_path = ColorSchemeSettings.CONFIG_PATH
	ColorSchemeSettings.reset_to_defaults()

func test_preset_dropdown_filled_from_presets():
	var h = _hud()
	assert_eq(h._preset_opt.item_count, SequencePresets.ALL.size())

func test_cue_dropdown_has_four_levels():
	var h = _hud()
	assert_eq(h._cue_opt.item_count, 4)

func test_start_button_emits_selection():
	var h = _hud()
	watch_signals(h)
	h._preset_opt.select(1)   # "medio"
	h._cue_opt.select(2)      # nível 2
	h._mode_opt.select(1)     # Piano Virtual
	h._on_start_pressed()
	assert_signal_emitted_with_parameters(h, "start_requested", ["medio", 2, 1])

func test_set_progress_updates_label():
	var h = _hud()
	h.set_progress(3, 8)
	assert_eq(h._progress.text, "Nota 3 / 8")

func test_show_stats_reveals_panel_and_text():
	var h = _hud()
	h.show_stats({ "first_try_hits": 4, "total_trips": 2, "elapsed_sec": 12.5 })
	assert_true(h._stats_panel.visible)
	assert_string_contains(h._stats_label.text, "4")
	assert_string_contains(h._stats_label.text, "2")
	assert_string_contains(h._stats_label.text, "12.5")

func test_restart_button_emits():
	var h = _hud()
	watch_signals(h)
	h._on_restart_pressed()
	assert_signal_emitted(h, "restart_requested")

func test_start_button_default_selection_emits_first_preset():
	var h = _hud()
	watch_signals(h)
	h._on_start_pressed()  # sem select() — usa defaults (índice 0 auto-selecionado)
	assert_signal_emitted_with_parameters(h, "start_requested",
		[SequencePresets.ALL[0].id, 0, 0])

func test_hide_stats_conceals_panel():
	var h = _hud()
	h.show_stats({ "first_try_hits": 1, "total_trips": 0, "elapsed_sec": 1.0 })
	h.hide_stats()
	assert_false(h._stats_panel.visible)

func test_mode_dropdown_has_three_options():
	# Um item por valor de InputModeSettings.Mode: o índice do dropdown é
	# emitido cru como input_mode em start_requested. Sobrar item aqui
	# mandaria um modo inexistente para o Playground.
	var h = _hud()
	assert_eq(h._mode_opt.item_count, 3)

func test_hud_has_color_settings_button():
	var h = _hud()
	assert_not_null(h._color_btn)
	assert_eq(h._color_btn.text, "Cores")

func test_color_button_emits_request():
	var h = _hud()
	watch_signals(h)
	h._color_btn.pressed.emit()
	assert_signal_emitted(h, "color_settings_requested")

# --- Botão "Piano colorido" ----------------------------------------------------

func test_paint_toggle_starts_in_sync_with_the_setting():
	var h = _hud()
	assert_not_null(h._paint_btn)
	assert_true(h._paint_btn.toggle_mode, "é um interruptor, não um botão de ação")
	assert_eq(h._paint_btn.button_pressed, ColorSchemeSettings.paints_piano_keys())

func test_paint_toggle_sits_before_the_progress_label():
	# _progress tem SIZE_EXPAND_FILL e come toda a sobra da linha: inserido
	# depois dele, o botão seria empurrado pra borda da tela.
	var h = _hud()
	assert_eq(h._paint_btn.get_parent(), h._progress.get_parent(),
		"o botão mora na segunda linha -- uma terceira cobriria o NotePanel")
	assert_lt(h._paint_btn.get_index(), h._progress.get_index())

func test_paint_toggle_applies_and_persists_the_choice():
	ColorSchemeSettings.config_path = PAINT_TEST_PATH
	var h = _hud()
	h._paint_btn.button_pressed = false  # o setter do Button já emite toggled
	assert_false(ColorSchemeSettings.paints_piano_keys(), "o botão tem que mandar na preferência")
	assert_true(FileAccess.file_exists(PAINT_TEST_PATH),
		"a escolha é ajuste de acessibilidade: tem que sobreviver a fechar o jogo")

func test_paint_toggle_does_not_write_to_disk_just_by_being_created():
	# button_pressed é setado ANTES do connect de propósito: o setter emite
	# `toggled`, e conectar primeiro faria o HUD gravar em disco só por nascer.
	ColorSchemeSettings.config_path = PAINT_TEST_PATH
	_hud()
	assert_false(FileAccess.file_exists(PAINT_TEST_PATH),
		"montar o HUD não pode escrever a configuração do jogador")

func test_paint_toggle_follows_a_change_made_somewhere_else():
	# O interruptor não é a única porta pra essa preferência: "Restaurar tudo ao
	# padrão", na tela de Cores, religa a pintura. Sem escutar paint_mode_changed,
	# o botão ficava mostrando "desligado" com a pintura ligada -- e o toque
	# seguinte era um toque MORTO: button_pressed ia pra true, set_paints_piano
	# recebia o valor que já estava lá e não emitia nada, então o jogador
	# precisava apertar duas vezes pra ver qualquer coisa acontecer.
	ColorSchemeSettings.set_paints_piano(false)
	var h = _hud()
	assert_false(h._paint_btn.button_pressed, "pré-condição: nasce desligado")
	ColorSchemeSettings.reset_to_defaults()  # é o que _on_reset_confirmed chama
	assert_true(ColorSchemeSettings.paints_piano_keys(), "pré-condição: o reset religa a pintura")
	assert_true(h._paint_btn.button_pressed,
		"o interruptor tem que refletir a preferência, não a última vez que foi tocado")

func test_reflecting_an_external_change_does_not_write_to_disk():
	# set_pressed_no_signal, não button_pressed: reentrar em _on_paint_toggled
	# gravaria a configuração do jogador a cada mudança vinda de outra tela -- e,
	# no boot, gravaria só por ter LIDO a configuração dele.
	ColorSchemeSettings.config_path = PAINT_TEST_PATH
	ColorSchemeSettings.set_paints_piano(false)
	_hud()
	ColorSchemeSettings.set_paints_piano(true)
	assert_false(FileAccess.file_exists(PAINT_TEST_PATH),
		"refletir uma mudança externa não é o jogador tocando no interruptor")

# --- Layout na largura de projeto (720px) --------------------------------------

func _design_width() -> int:
	return ProjectSettings.get_setting("display/window/size/viewport_width")

func test_top_rows_fit_the_design_width():
	# O botão "Cores" tinha sido enfiado na primeira linha, que ficou com 7px de
	# folga em 720 -- qualquer rótulo maior (ou fonte maior por acessibilidade)
	# já transbordaria, e nenhum teste media isso.
	#
	# A comparação é contra a largura REAL da linha, não contra os 720px da tela:
	# a HBox vive dentro de um MarginContainer (16 de cada lado) dentro de um
	# PanelContainer cuja moldura come outros 16, então o orçamento é 656px. Medir
	# contra 720 concedia 64px de folga fantasma.
	var vp = SubViewport.new()
	vp.size = Vector2i(_design_width(), ProjectSettings.get_setting("display/window/size/viewport_height"))
	add_child_autofree(vp)
	var h = HudScene.instantiate()
	vp.add_child(h)
	await wait_frames(2)

	var linha1: Control = h._preset_opt.get_parent()
	var linha2: Control = h._color_btn.get_parent()
	for par in [["primeira", linha1], ["segunda", linha2]]:
		var nome: String = par[0]
		var linha: Control = par[1]
		assert_lt(linha.size.x, float(_design_width()),
			"a %s linha não pode ocupar a tela inteira -- as margens do painel existem" % nome)
		assert_lte(linha.get_combined_minimum_size().x, linha.size.x,
			"a %s linha do HUD precisa de %.0fpx e só tem %.0f" % [
				nome, linha.get_combined_minimum_size().x, linha.size.x])

func test_note_panel_is_not_covered_by_the_top_bar():
	# A barra do topo cresceu ~16px quando "Cores" foi para a segunda linha, e o
	# NotePanel estava fixado em offset_top=140 no Playground.tscn: o painel opaco
	# do HUD (irmão posterior na CanvasLayer) desenhava 10px por cima do chip de
	# pista, que é a única informação visível no nível 2.
	var vp = SubViewport.new()
	vp.size = Vector2i(_design_width(), ProjectSettings.get_setting("display/window/size/viewport_height"))
	add_child_autofree(vp)
	var pg = load("res://scenes/Playground.tscn").instantiate()
	vp.add_child(pg)
	await wait_frames(4)

	var hud: Control = pg.get_node("UI/GameHUD")
	var note_panel: Control = pg.get_node("UI/NotePanel")
	var barra: Rect2 = hud._top_panel.get_global_rect()
	var painel: Rect2 = note_panel.get_global_rect()
	assert_gt(barra.size.y, 0.0, "pré-condição: a barra do topo já foi disposta")
	assert_gte(painel.position.y, barra.end.y,
		"o HUD termina em y=%.0f e o NotePanel começa em y=%.0f" % [barra.end.y, painel.position.y])
	assert_lte(painel.end.y, float(ProjectSettings.get_setting("display/window/size/viewport_height")),
		"o NotePanel não pode ser empurrado para fora da tela")
