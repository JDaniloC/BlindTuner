extends CanvasLayer
## Autoload singleton — Gerenciador de transições de telas e cenas.
## Cria um overlay com fade suave de vídeo e áudio entre menus e gameplay.

signal transition_started(target_scene: String)
signal transition_finished(target_scene: String)

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/LevelSelectScreen.tscn"
const GAMEPLAY_SCENE := "res://scenes/Playground.tscn"

var _overlay: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
	layer = 100 # Camada superior a todas as cenas
	_overlay = ColorRect.new()
	_overlay.color = Color(0.08, 0.08, 0.1, 1.0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	add_child(_overlay)

func change_scene(scene_path: String, fade_duration: float = 0.25) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	transition_started.emit(scene_path)
	
	if not is_inside_tree() or get_tree() == null:
		_is_transitioning = false
		return
	
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 1.0, fade_duration)
	tw.tween_callback(func():
		var err := get_tree().change_scene_to_file(scene_path)
		if err != OK:
			push_error("SceneManager: Erro ao carregar cena: %s" % scene_path)
	)
	tw.tween_interval(0.05)
	tw.tween_property(_overlay, "modulate:a", 0.0, fade_duration)
	tw.tween_callback(func():
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_is_transitioning = false
		transition_finished.emit(scene_path)
	)

func go_to_main_menu() -> void:
	change_scene(MAIN_MENU_SCENE)

func go_to_level_select() -> void:
	change_scene(LEVEL_SELECT_SCENE)

func start_level(level_id: String) -> void:
	LevelManager.is_sandbox = false
	if LevelManager.select_level(level_id):
		change_scene(GAMEPLAY_SCENE)
	else:
		push_error("SceneManager: Nível não encontrado: %s" % level_id)

func start_sandbox() -> void:
	LevelManager.is_sandbox = true
	change_scene(GAMEPLAY_SCENE)

func reload_current_scene() -> void:
	if get_tree() != null and get_tree().current_scene != null:
		change_scene(get_tree().current_scene.scene_file_path)
