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
