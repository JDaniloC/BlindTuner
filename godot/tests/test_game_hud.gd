extends GutTest

const HudScene := preload("res://scenes/GameHUD.tscn")

func _hud() -> Node:
	var h = HudScene.instantiate()
	add_child_autofree(h)
	return h

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
	h._mode_opt.select(1)     # Toque no Escuro
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

func test_mode_dropdown_has_four_options():
	var h = _hud()
	assert_eq(h._mode_opt.item_count, 4)

func test_hud_has_color_settings_button():
	var h = _hud()
	assert_not_null(h._color_btn)
	assert_eq(h._color_btn.text, "Cores")

func test_color_button_emits_request():
	var h = _hud()
	watch_signals(h)
	h._color_btn.pressed.emit()
	assert_signal_emitted(h, "color_settings_requested")

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
