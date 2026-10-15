extends Control
## Menu Principal do BlindTuner.
## Oferece acesso à campanha ("Continuar" e "Diário de Memórias"), configurações e cores.

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const RADIO_ICON := preload("res://assets/sprites/props/radio_vintage_48x48.png")
const COLOR_SCREEN_SCENE := preload("res://scenes/ColorSchemeScreen.tscn")
const SETTINGS_SCENE := preload("res://scenes/SettingsScreen.tscn")

var _play_btn: Button
var _select_btn: Button
var _settings_btn: Button
var _colors_btn: Button
var _stars_label: Label
var _sub_screen: Control = null

func _ready() -> void:
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	bg.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 24)
	margin.add_child(col)

	# --- Cabeçalho ---
	var header_box := VBoxContainer.new()
	header_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header_box.add_theme_constant_override("separation", 8)
	col.add_child(header_box)

	var title := Label.new()
	title.text = "BlindTuner"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Uma jornada de sons e memórias"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_box.add_child(subtitle)

	# --- Ilustração Central ---
	var center_box := CenterContainer.new()
	col.add_child(center_box)

	var radio_tex := TextureRect.new()
	radio_tex.texture = RADIO_ICON
	radio_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	radio_tex.custom_minimum_size = Vector2(96, 96)
	radio_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center_box.add_child(radio_tex)

	# --- Contador de Estrelas ---
	_stars_label = Label.new()
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_update_stars_display()
	col.add_child(_stars_label)

	# --- Lista de Botões ---
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 16)
	col.add_child(btn_box)

	_play_btn = Button.new()
	_play_btn.custom_minimum_size = Vector2(260, 56)
	_play_btn.text = "Continuar Jornada"
	_play_btn.pressed.connect(_on_play_pressed)
	btn_box.add_child(_play_btn)

	_select_btn = Button.new()
	_select_btn.custom_minimum_size = Vector2(260, 56)
	_select_btn.text = "Diário de Memórias"
	_select_btn.pressed.connect(_on_select_pressed)
	btn_box.add_child(_select_btn)

	var sandbox_btn := Button.new()
	sandbox_btn.custom_minimum_size = Vector2(260, 56)
	sandbox_btn.text = "Modo Livre (Sandbox)"
	sandbox_btn.pressed.connect(func(): SceneManager.start_sandbox())
	btn_box.add_child(sandbox_btn)

	_settings_btn = Button.new()
	_settings_btn.custom_minimum_size = Vector2(260, 56)
	_settings_btn.text = "Configurações"
	_settings_btn.pressed.connect(_on_settings_pressed)
	btn_box.add_child(_settings_btn)

	_colors_btn = Button.new()
	_colors_btn.custom_minimum_size = Vector2(260, 56)
	_colors_btn.text = "Cores das Notas"
	_colors_btn.pressed.connect(_on_colors_pressed)
	btn_box.add_child(_colors_btn)

	# --- Rodapé ---
	var footer := Label.new()
	footer.text = "BlindTuner • Godot 4"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(footer)

func _update_stars_display() -> void:
	var total: int = SaveManager.get_total_stars()
	if total > 0:
		_stars_label.text = "⭐ %d Estrelas Conquistadas" % total
	else:
		_stars_label.text = "Toque em 'Continuar' para iniciar"

func _on_play_pressed() -> void:
	# Encontra o último nível desbloqueado
	var current = LevelManager.get_current_level()
	var target_id: String = current.id if current != null else "ch1_quarto_radio"
	SceneManager.start_level(target_id)

func _on_select_pressed() -> void:
	SceneManager.go_to_level_select()

func _on_settings_pressed() -> void:
	if _sub_screen != null:
		return
	var screen = SETTINGS_SCENE.instantiate()
	_sub_screen = screen
	add_child(screen)
	screen.closed.connect(func():
		_sub_screen.queue_free()
		_sub_screen = null
		_update_stars_display()
	)

func _on_colors_pressed() -> void:
	if _sub_screen != null:
		return
	var screen = COLOR_SCREEN_SCENE.instantiate()
	_sub_screen = screen
	add_child(screen)
	screen.closed.connect(func():
		_sub_screen.queue_free()
		_sub_screen = null
	)
