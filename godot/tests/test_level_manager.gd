extends GutTest

const TEST_SAVE_PATH := "user://test_lm_save_data.json"

func before_each():
	SaveManager.save_file_path = TEST_SAVE_PATH
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.load_data()

func after_each():
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	SaveManager.save_file_path = SaveManager.DEFAULT_SAVE_PATH
	SaveManager.load_data()

func test_select_level():
	assert_true(LevelManager.select_level("ch1_quarto_radio"))
	assert_eq(LevelManager.get_current_level().id, "ch1_quarto_radio")
	assert_false(LevelManager.select_level("nivel_inexistente"))

func test_calculate_stars():
	var lvl = LevelCatalog.by_id("ch1_quarto_radio")
	assert_not_null(lvl)
	
	# Caso 1: Concluiu com erros de pitch e tropeços -> 1 estrela
	var stats_1 := {
		"first_try_hits": 3,
		"total_notes": 6,
		"total_trips": 2,
		"elapsed_sec": 20.0
	}
	assert_eq(LevelManager.calculate_stars(lvl, stats_1), 1)
	
	# Caso 2: Concluiu sem erros de pitch mas com tropeços -> 2 estrelas
	var stats_2 := {
		"first_try_hits": 6,
		"total_notes": 6,
		"total_trips": 1,
		"elapsed_sec": 20.0
	}
	assert_eq(LevelManager.calculate_stars(lvl, stats_2), 2)
	
	# Caso 3: Concluiu perfeito sem erros e sem tropeços -> 3 estrelas
	var stats_3 := {
		"first_try_hits": 6,
		"total_notes": 6,
		"total_trips": 0,
		"elapsed_sec": 18.0
	}
	assert_eq(LevelManager.calculate_stars(lvl, stats_3), 3)

	# Caso 4: Concluiu com erros de pitch (sem Ouvido Fino), mas sem esbarrar nas paredes (Passo Firme) -> 2 estrelas
	var stats_4 := {
		"first_try_hits": 4,
		"total_notes": 6,
		"pitch_misses": 2,
		"wall_bumps": 0,
		"total_trips": 2,
		"elapsed_sec": 22.0
	}
	assert_eq(LevelManager.calculate_stars(lvl, stats_4), 2)

func test_complete_level_unlocks_next():
	LevelManager.select_level("ch1_quarto_radio")
	assert_false(SaveManager.is_level_unlocked("ch1_lullaby_dormir"))
	
	var stats := {
		"first_try_hits": 6,
		"total_notes": 6,
		"total_trips": 0,
		"elapsed_sec": 18.0
	}
	var summary := LevelManager.complete_level(stats)
	
	assert_eq(summary.get("stars"), 3)
	assert_true(summary.get("is_new_unlock"))
	assert_eq(summary.get("next_level_id"), "ch1_lullaby_dormir")
	assert_eq(summary.get("wall_bumps"), 0)
	assert_eq(summary.get("pitch_misses"), 0)
	assert_true(SaveManager.is_level_unlocked("ch1_lullaby_dormir"))
