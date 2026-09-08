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
