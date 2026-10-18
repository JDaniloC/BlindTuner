extends GutTest

const VISION_OVERLAY_SCENE := preload("res://scenes/VisionImpairmentOverlay.tscn")
const LevelDataScript := preload("res://scripts/LevelData.gd")

var _overlay: CanvasLayer = null

func before_each():
	_overlay = VISION_OVERLAY_SCENE.instantiate()
	add_child_autofree(_overlay)

func test_overlay_instantiates_with_canvas_layer_and_material():
	assert_not_null(_overlay)
	assert_eq(_overlay.layer, 1, "Overlay de visão deve ficar na camada 1 (acima do mundo, abaixo do HUD)")
	assert_not_null(_overlay._color_rect, "ColorRect deve existir")
	assert_not_null(_overlay._material, "ShaderMaterial deve existir")

func test_set_parameters_updates_shader_uniforms():
	_overlay.set_parameters(1.5, 0.7, 0.4, 0.5)
	var mat: ShaderMaterial = _overlay._material
	assert_eq(mat.get_shader_parameter("blur_amount"), 1.5)
	assert_eq(mat.get_shader_parameter("vignette_radius"), 0.7)
	assert_eq(mat.get_shader_parameter("darkness"), 0.4)
	assert_eq(mat.get_shader_parameter("desaturation"), 0.5)

func test_setup_from_level_data_applies_level_optical_degradation():
	var lvl = LevelDataScript.new()
	lvl.id = "ch1_lullaby_dormir"
	lvl.vision_blur = 0.8
	lvl.vision_vignette = 0.75
	lvl.vision_darkness = 0.35
	lvl.vision_desaturation = 0.2

	_overlay.setup_from_level_data(lvl)

	var mat: ShaderMaterial = _overlay._material
	assert_eq(mat.get_shader_parameter("blur_amount"), 0.8)
	assert_eq(mat.get_shader_parameter("vignette_radius"), 0.75)
	assert_eq(mat.get_shader_parameter("darkness"), 0.35)
	assert_eq(mat.get_shader_parameter("desaturation"), 0.2)

func test_update_character_screen_position_calculates_uv_and_aspect():
	_overlay.update_character_screen_position(Vector2(360, 640), Vector2(720, 1280))
	var mat: ShaderMaterial = _overlay._material
	var uv: Vector2 = mat.get_shader_parameter("character_screen_uv")
	var aspect: float = mat.get_shader_parameter("aspect_ratio")
	assert_almost_eq(uv.x, 0.5, 0.001)
	assert_almost_eq(uv.y, 0.5, 0.001)
	assert_almost_eq(aspect, 720.0 / 1280.0, 0.001)

func test_toggle_effect_enabled():
	_overlay.set_effect_enabled(false)
	assert_false(_overlay.is_effect_enabled())
	assert_false(_overlay._material.get_shader_parameter("is_effect_enabled"))

	_overlay.set_effect_enabled(true)
	assert_true(_overlay.is_effect_enabled())
	assert_true(_overlay._material.get_shader_parameter("is_effect_enabled"))

func test_all_catalog_levels_have_vision_parameters():
	for lvl in LevelCatalog.ALL:
		assert_gte(lvl.vision_blur, 0.0, "Blur do nível %s não pode ser negativo" % lvl.id)
		assert_gt(lvl.vision_vignette, 0.0, "Vinheta do nível %s deve ser positiva" % lvl.id)
		assert_gte(lvl.vision_darkness, 0.0, "Darkness do nível %s não pode ser negativa" % lvl.id)

func test_contour_strength_shader_uniform():
	var mat: ShaderMaterial = _overlay._material
	var cs: float = mat.get_shader_parameter("contour_strength")
	assert_gt(cs, 0.0, "Shader deve preservar traço 2D de contorno na névoa periférica")

func test_playground_ui_layer_is_strictly_above_vision_overlay():
	var PlaygroundScene := preload("res://scenes/Playground.tscn")
	var p = PlaygroundScene.instantiate()
	add_child_autofree(p)
	var ui: CanvasLayer = p.get_node_or_null("UI")
	assert_not_null(ui, "UI CanvasLayer deve existir na cena Playground")
	assert_gt(ui.layer, p._vision_overlay.layer, "Camada da UI (layer=%d) deve estar estritamente ACIMA da camada de degradação ótica (layer=%d)" % [ui.layer, p._vision_overlay.layer])
	assert_eq(ui.layer, 10, "UI deve estar na camada 10")
	assert_eq(p._vision_overlay.layer, 1, "VisionImpairmentOverlay deve estar na camada 1")

func test_all_interactive_ui_components_are_inside_ui_canvas_layer():
	var PlaygroundScene := preload("res://scenes/Playground.tscn")
	var p = PlaygroundScene.instantiate()
	add_child_autofree(p)
	var ui: CanvasLayer = p.get_node("UI")
	var expected_nodes := [
		"DirectionJoystick",
		"PianoInput",
		"PitchScrollInput",
		"SpecialActionPanel",
		"CharacterPortrait",
		"NotePanel",
		"GameHUD"
	]
	for node_name in expected_nodes:
		var node = ui.get_node_or_null(node_name)
		assert_not_null(node, "Componente '%s' deve ser filho da UI CanvasLayer (layer 10)" % node_name)

func test_level_remove_control_colors_applies_neutral_mode_to_controls():
	var PlaygroundScene := preload("res://scenes/Playground.tscn")
	var p = PlaygroundScene.instantiate()
	add_child_autofree(p)
	
	var lvl = LevelCatalog.by_id("ch3_teatro_recital")
	assert_not_null(lvl, "Nível 3.4 deve existir no catálogo")
	assert_true(lvl.remove_control_colors, "Nível 3.4 (Recital no Vazio) deve retirar cores dos controles")
	
	p._apply_level_visual_cues(lvl)
	assert_false(p._joystick._level_cues_allowed, "Joystick deve ter pistas bloqueadas no nível 3.4")
	assert_false(p._piano_input._level_cues_allowed, "Piano deve ter pistas bloqueadas no nível 3.4")
	assert_false(p._pitch_scroll_input._level_cues_allowed, "Scroll deve ter pistas bloqueadas no nível 3.4")
	assert_false(p._special_actions._level_cues_allowed, "Ações devem ter pistas bloqueadas no nível 3.4")
	
	# Ao carregar um nível comum (como 1.1), as cores voltam normalmente
	var lvl_1_1 = LevelCatalog.by_id("ch1_quarto_radio")
	assert_not_null(lvl_1_1, "Nível 1.1 deve existir no catálogo")
	assert_false(lvl_1_1.remove_control_colors)
	p._apply_level_visual_cues(lvl_1_1)
	assert_true(p._joystick._level_cues_allowed)
	assert_true(p._piano_input._level_cues_allowed)
	assert_true(p._pitch_scroll_input._level_cues_allowed)
	assert_true(p._special_actions._level_cues_allowed)

