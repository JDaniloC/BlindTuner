extends GutTest

const MainMenuScene := preload("res://scenes/MainMenu.tscn")
const SettingsScene := preload("res://scenes/SettingsScreen.tscn")
const LevelSelectScene := preload("res://scenes/LevelSelectScreen.tscn")
const PauseModalScene := preload("res://scenes/PauseModal.tscn")
const VictoryModalScene := preload("res://scenes/VictoryModal.tscn")

func test_main_menu_instantiation():
	var menu = MainMenuScene.instantiate()
	add_child_autofree(menu)
	assert_not_null(menu)
	assert_not_null(menu._play_btn)
	assert_not_null(menu._select_btn)
	assert_not_null(menu._settings_btn)

func test_settings_screen_instantiation():
	var settings = SettingsScene.instantiate()
	add_child_autofree(settings)
	assert_not_null(settings)
	assert_not_null(settings._master_slider)
	assert_not_null(settings._cues_toggle)
	assert_not_null(settings._mode_opt)

func test_level_select_screen_instantiation():
	var select_screen = LevelSelectScene.instantiate()
	add_child_autofree(select_screen)
	assert_not_null(select_screen)
	assert_not_null(select_screen._chapter_opt)
	assert_not_null(select_screen._cards_container)
	assert_gt(select_screen._cards_container.get_child_count(), 0)

func test_pause_modal_instantiation():
	var pause = PauseModalScene.instantiate()
	add_child_autofree(pause)
	assert_not_null(pause)
	assert_not_null(pause._resume_btn)
	assert_not_null(pause._restart_btn)

func test_victory_modal_display_result():
	var victory = VictoryModalScene.instantiate()
	add_child_autofree(victory)
	assert_not_null(victory)
	
	var lvl = LevelCatalog.get_first_level()
	var summary := {
		"stars": 3,
		"elapsed_sec": 14.2,
		"trips": 0,
		"first_try_hits": 6,
		"has_next_level": true
	}
	victory.display_result(lvl, summary)
	assert_eq(victory._stars_lbl.text, "★★★")
	assert_true(victory._next_btn.visible)

func test_game_hud_pause_button_emits():
	var HudScene := preload("res://scenes/GameHUD.tscn")
	var h = HudScene.instantiate()
	add_child_autofree(h)
	assert_not_null(h._pause_btn)
	watch_signals(h)
	h._pause_btn.pressed.emit()
	assert_signal_emitted(h, "pause_requested")

func test_playground_pause_and_victory_modals():
	var PgScene := preload("res://scenes/Playground.tscn")
	var pg = PgScene.instantiate()
	add_child_autofree(pg)
	
	# Testa pausa
	pg._on_pause_requested()
	assert_not_null(pg._pause_modal)
	assert_true(pg._pause_modal.is_inside_tree())
	pg._on_resume_from_pause()
	assert_null(pg._pause_modal)
	
	# Testa modal de vitória
	var lvl = LevelCatalog.get_first_level()
	pg._show_victory_modal(lvl, {"stars": 3, "has_next_level": false})
	assert_not_null(pg._victory_modal)
	assert_true(pg._victory_modal.is_inside_tree())

func test_game_hud_campaign_and_sandbox_modes():
	var HudScene := preload("res://scenes/GameHUD.tscn")
	var h = HudScene.instantiate()
	add_child_autofree(h)
	
	h.set_campaign_mode("A Canção de Ninar")
	assert_false(h._row1.visible)
	assert_true(h._title_label.visible)
	assert_string_contains(h._title_label.text, "A Canção de Ninar")
	assert_false(h._color_btn.visible)
	
	h.set_sandbox_mode()
	assert_true(h._row1.visible)
	assert_false(h._title_label.visible)
	assert_true(h._color_btn.visible)

func test_playground_auto_starts_in_campaign_mode():
	var PgScene := preload("res://scenes/Playground.tscn")
	LevelManager.is_sandbox = false
	LevelManager.select_level("ch1_lullaby_dormir")
	
	var pg = PgScene.instantiate()
	add_child_autofree(pg)
	
	assert_false(pg._hud._row1.visible)
	assert_true(pg._hud._title_label.visible)
	assert_not_null(pg._story_intro_modal, "Modal narrativo deve ser exibido antes de iniciar a fase")
	pg._story_intro_modal._on_start_pressed()
	assert_eq(pg._conductor.phase, pg._conductor.Phase.PREVIEW)
	assert_eq(pg._current_map_id, "quarto_lullaby")
	
	# Restaura sandbox para não vazar para outros testes
	LevelManager.is_sandbox = true
