extends CanvasLayer
## Camada de pós-processamento ótico para simulação de baixa visão progressiva.
## Posicionada acima do cenário do jogo e abaixo dos controles de UI.

const SHADER := preload("res://shaders/vision_impairment.gdshader")

var _material: ShaderMaterial
var _color_rect: ColorRect
var _is_enabled: bool = true

func _ready() -> void:
	layer = 1
	_setup_nodes()
	if is_inside_tree():
		var cs = get_node_or_null(^"/root/CueSettings")
		if cs != null:
			cs.vision_effects_changed.connect(set_effect_enabled)
			set_effect_enabled(cs.vision_effects_enabled)

func _setup_nodes() -> void:
	if _color_rect == null:
		_color_rect = ColorRect.new()
		_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_color_rect)

	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		_material.set_shader_parameter("contour_strength", 0.55)
		_color_rect.material = _material

## Configura os parâmetros do shader baseados no nível atual.
func setup_from_level_data(lvl_data: Resource) -> void:
	_setup_nodes()
	if lvl_data == null:
		set_parameters(0.0, 1.2, 0.0, 0.0)
		return
	var raw_blur = lvl_data.get("vision_blur")
	var blur: float = float(raw_blur) if raw_blur != null else 0.0
	var raw_vignette = lvl_data.get("vision_vignette")
	var vignette: float = float(raw_vignette) if raw_vignette != null and float(raw_vignette) > 0.0 else 1.2
	var raw_darkness = lvl_data.get("vision_darkness")
	var darkness: float = float(raw_darkness) if raw_darkness != null else 0.0
	var raw_desat = lvl_data.get("vision_desaturation")
	var desat: float = float(raw_desat) if raw_desat != null else 0.0
	set_parameters(blur, vignette, darkness, desat)

## Define os parâmetros uniformes do shader diretamente.
func set_parameters(blur: float, vignette: float, darkness: float, desat: float) -> void:
	_setup_nodes()
	_material.set_shader_parameter("blur_amount", blur)
	_material.set_shader_parameter("vignette_radius", vignette)
	_material.set_shader_parameter("darkness", darkness)
	_material.set_shader_parameter("desaturation", desat)

## Atualiza o centro de foco do túnel de visão baseado na posição do personagem na tela.
func update_character_screen_position(screen_pos: Vector2, viewport_size: Vector2) -> void:
	if _material == null:
		return
	if viewport_size.x > 0.0 and viewport_size.y > 0.0:
		var uv := Vector2(screen_pos.x / viewport_size.x, screen_pos.y / viewport_size.y)
		var aspect: float = viewport_size.x / viewport_size.y
		_material.set_shader_parameter("character_screen_uv", uv)
		_material.set_shader_parameter("aspect_ratio", aspect)

## Liga ou desliga o efeito (para acessibilidade).
func set_effect_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	_setup_nodes()
	_material.set_shader_parameter("is_effect_enabled", enabled)

func is_effect_enabled() -> bool:
	return _is_enabled
