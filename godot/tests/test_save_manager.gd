extends GutTest

const TEST_SAVE_PATH := "user://test_save_data.json"

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

func test_default_save_state():
	assert_true(SaveManager.is_level_unlocked("ch1_quarto_radio"))
	assert_false(SaveManager.is_level_unlocked("ch1_banheiro_cautela"))
	assert_eq(SaveManager.get_total_stars(), 0)

func test_unlock_level():
	assert_false(SaveManager.is_level_unlocked("ch1_banheiro_cautela"))
	var unlocked := SaveManager.unlock_level("ch1_banheiro_cautela")
	assert_true(unlocked)
	assert_true(SaveManager.is_level_unlocked("ch1_banheiro_cautela"))
	# Desbloquear novamente retorna false (já estava desbloqueado)
	assert_false(SaveManager.unlock_level("ch1_banheiro_cautela"))

func test_record_level_completion():
	SaveManager.record_level_completion("ch1_quarto_radio", 2, 20.5, 1, 5)
	assert_eq(SaveManager.get_level_stars("ch1_quarto_radio"), 2)
	assert_eq(SaveManager.get_total_stars(), 2)
	
	var rec := SaveManager.get_level_record("ch1_quarto_radio")
	assert_eq(rec.get("stars"), 2)
	assert_eq(rec.get("best_time"), 20.5)
	assert_eq(rec.get("min_trips"), 1)
	
	# Nova tentativa melhorando estrelas e tempo
	SaveManager.record_level_completion("ch1_quarto_radio", 3, 15.0, 0, 6)
	assert_eq(SaveManager.get_level_stars("ch1_quarto_radio"), 3)
	rec = SaveManager.get_level_record("ch1_quarto_radio")
	assert_eq(rec.get("stars"), 3)
	assert_eq(rec.get("best_time"), 15.0)
	assert_eq(rec.get("min_trips"), 0)

func test_save_and_reload_persistence():
	SaveManager.unlock_level("ch1_sala_poltrona")
	SaveManager.record_level_completion("ch1_sala_poltrona", 3, 30.0, 0, 10)
	
	# Recria o estado lendo do arquivo gravado
	SaveManager.load_data()
	assert_true(SaveManager.is_level_unlocked("ch1_sala_poltrona"))
	assert_eq(SaveManager.get_level_stars("ch1_sala_poltrona"), 3)
