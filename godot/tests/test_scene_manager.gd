extends GutTest

func test_scene_manager_exists_and_has_overlay():
	assert_not_null(SceneManager)
	assert_eq(SceneManager.layer, 100)
	assert_not_null(SceneManager._overlay)
	assert_eq(SceneManager._overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_scene_constants_valid_format():
	assert_true(SceneManager.MAIN_MENU_SCENE.begins_with("res://"))
	assert_true(SceneManager.LEVEL_SELECT_SCENE.begins_with("res://"))
	assert_true(SceneManager.GAMEPLAY_SCENE.begins_with("res://"))
