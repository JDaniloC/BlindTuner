extends Control
## Tela unificada de Configurações e Acessibilidade do BlindTuner.
## Oferece controle de volumes, pistas visuais, modo de input e reset de progresso.

signal closed

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const COLOR_SCREEN_SCENE := preload("res://scenes/ColorSchemeScreen.tscn")

var _master_slider: HSlider
var _sfx_slider: HSlider
var _cues_toggle: Button
var _mode_opt: OptionButton
var _reset_btn: Button
var _close_btn: Button
var _colors_btn: Button
var _sub_modal: Control = null

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
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)

	var title := Label.new()
	title.text = "Configurações & Acessibilidade"
	col.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	scroll.add_child(content)

	# --- Seção Áudio ---
	_build_section_header(content, "Áudio")
	
	var vol_box := VBoxContainer.new()
	vol_box.add_theme_constant_override("separation", 8)
	content.add_child(vol_box)

	var vol_label := Label.new()
	vol_label.text = "Volume Geral:"
	vol_box.add_child(vol_label)

	_master_slider = HSlider.new()
	_master_slider.min_value = 0.0
	_master_slider.max_value = 1.0
	_master_slider.step = 0.05
	_master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	_master_slider.value_changed.connect(_on_master_volume_changed)
	vol_box.add_child(_master_slider)

	# --- Seção Visual & Acessibilidade ---
	_build_section_header(content, "Acessibilidade Visual")

	_cues_toggle = Button.new()
	_cues_toggle.toggle_mode = true
	_cues_toggle.text = "Pistas nos controles"
	_cues_toggle.button_pressed = ColorSchemeSettings.shows_control_cues()
	_cues_toggle.toggled.connect(_on_cues_toggled)
	content.add_child(_cues_toggle)

	_colors_btn = Button.new()
	_colors_btn.text = "Paleta de Cores das Notas..."
	_colors_btn.pressed.connect(_on_colors_pressed)
	content.add_child(_colors_btn)

	var vision_toggle := Button.new()
	vision_toggle.toggle_mode = true
	vision_toggle.text = "Efeitos de Transição Visual (Cores/Túnel)"
	vision_toggle.button_pressed = CueSettings.vision_effects_enabled
	vision_toggle.toggled.connect(func(pressed: bool): CueSettings.set_vision_effects_enabled(pressed))
	content.add_child(vision_toggle)

	var talkback_toggle := Button.new()
	talkback_toggle.toggle_mode = true
	talkback_toggle.button_pressed = AccessibleAnnouncer.is_tts_enabled()
	_update_talkback_button_text(talkback_toggle)
	talkback_toggle.toggled.connect(func(pressed: bool):
		AccessibleAnnouncer.set_tts_enabled(pressed)
		_update_talkback_button_text(talkback_toggle)
		var earcon := "toggle_on" if pressed else "toggle_off"
		var estado := "Ligada" if pressed else "Desligada"
		AccessibleAnnouncer.announce(earcon, "Voz do narrador: %s" % estado)
	)
	content.add_child(talkback_toggle)

	# --- Seção Controles ---
	_build_section_header(content, "Modo de Entrada Padrão")

	_mode_opt = OptionButton.new()
	for m in ["Joystick (12 direções)", "Piano Virtual", "Scroll de Afinação"]:
		_mode_opt.add_item(m)
	_mode_opt.selected = InputModeSettings.mode
	_mode_opt.item_selected.connect(_on_mode_selected)
	content.add_child(_mode_opt)

	# --- Botões de Ação Inferiores ---
	var footer_box := HBoxContainer.new()
	footer_box.add_theme_constant_override("separation", 16)
	col.add_child(footer_box)

	_reset_btn = Button.new()
	_reset_btn.text = "Redefinir Progresso"
	_reset_btn.pressed.connect(_on_reset_pressed)
	footer_box.add_child(_reset_btn)

	_close_btn = Button.new()
	_close_btn.text = "Salvar e Voltar"
	_close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_btn.pressed.connect(func(): closed.emit())
	footer_box.add_child(_close_btn)

func _build_section_header(parent: Control, header_text: String) -> void:
	var lbl := Label.new()
	lbl.text = "— %s —" % header_text
	parent.add_child(lbl)

func _on_master_volume_changed(val: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(val, 0.0001)))

func _on_cues_toggled(enabled: bool) -> void:
	ColorSchemeSettings.set_control_cues(enabled)
	ColorSchemeSettings.save_to_disk()

func _update_talkback_button_text(btn: Button) -> void:
	var on := btn.button_pressed
	btn.text = "Voz do Narrador (Talkback): %s [%s]" % [
		"Ligada" if on else "Desligada",
		"✓" if on else "✕"
	]

func _on_colors_pressed() -> void:
	if _sub_modal != null:
		return
	var modal = COLOR_SCREEN_SCENE.instantiate()
	_sub_modal = modal
	add_child(modal)
	modal.closed.connect(func():
		_sub_modal.queue_free()
		_sub_modal = null
	)

func _on_mode_selected(idx: int) -> void:
	InputModeSettings.set_mode(idx)

func _on_reset_pressed() -> void:
	SaveManager.reset_progress()
	_reset_btn.text = "Progresso Redefinido!"
