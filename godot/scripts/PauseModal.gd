extends Control
## Modal de pausa suspenso sobre a gameplay.
## Permite pausar o Conductor, reiniciar a fase ou retornar ao menu,
## com focus trap, navegação por gamepad/teclado, contraste e retorno sonoro acessível.

signal resume_requested
signal restart_requested
signal level_select_requested

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const COLOR_SCREEN_SCENE := preload("res://scenes/ColorSchemeScreen.tscn")

var _resume_btn: Button
var _restart_btn: Button
var _menu_btn: Button
var _colors_btn: Button
var _cues_toggle: Button
var _talkback_toggle: Button
var _sub_modal: Control = null
var _previous_focus: Control = null
var _confirm_dialog: PanelContainer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Fundo semitransparente escurecido para isolar o modal da cena
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.07, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 500)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(s, 24)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	var title := Label.new()
	title.text = "Um Instante de Silêncio"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.14, 0.11, 0.08))
	col.add_child(title)

	# 1. Continuar
	_resume_btn = Button.new()
	_resume_btn.custom_minimum_size = Vector2(0, 50)
	_resume_btn.text = "Retomar os Passos"
	_resume_btn.pressed.connect(_on_resume_pressed)
	_resume_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Retomar os passos. Volta à melodia e à caminhada. Botão 1 de 6.")
	)
	col.add_child(_resume_btn)

	# 2. Reiniciar
	_restart_btn = Button.new()
	_restart_btn.custom_minimum_size = Vector2(0, 50)
	_restart_btn.text = "Recomeçar a Memória"
	_restart_btn.pressed.connect(_on_restart_pressed)
	_restart_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Recomeçar a memória do primeiro passo. Pede confirmação. Botão 2 de 6.")
	)
	col.add_child(_restart_btn)

	# 3. Pistas nos Controles (Toggle com texto, glifo e som dinâmicos)
	_cues_toggle = Button.new()
	_cues_toggle.custom_minimum_size = Vector2(0, 50)
	_cues_toggle.toggle_mode = true
	_cues_toggle.button_pressed = ColorSchemeSettings.shows_control_cues()
	_update_cues_toggle_text()
	_cues_toggle.toggled.connect(_on_cues_toggled)
	_cues_toggle.focus_entered.connect(func():
		var estado := "Ligadas" if _cues_toggle.button_pressed else "Desligadas"
		AccessibleAnnouncer.announce("focus", "Pistas nos Controles: %s. Pressione A ou Espaço para alterar. Botão 3 de 6." % estado)
	)
	col.add_child(_cues_toggle)

	# 4. Voz do Narrador / Talkback (Opcional)
	_talkback_toggle = Button.new()
	_talkback_toggle.custom_minimum_size = Vector2(0, 50)
	_talkback_toggle.toggle_mode = true
	_talkback_toggle.button_pressed = AccessibleAnnouncer.is_tts_enabled()
	_update_talkback_toggle_text()
	_talkback_toggle.toggled.connect(_on_talkback_toggled)
	_talkback_toggle.focus_entered.connect(func():
		var estado := "Ligada" if _talkback_toggle.button_pressed else "Desligada"
		AccessibleAnnouncer.announce("focus", "Voz do Narrador: %s. Pressione A ou Espaço para alterar. Botão 4 de 6." % estado)
	)
	col.add_child(_talkback_toggle)

	# 5. Cores das Notas
	_colors_btn = Button.new()
	_colors_btn.custom_minimum_size = Vector2(0, 50)
	_colors_btn.text = "Cores e Contrastes..."
	_colors_btn.pressed.connect(_on_colors_pressed)
	_colors_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Cores e Contrastes. Abre tela de personalização da paleta. Botão 5 de 6.")
	)
	col.add_child(_colors_btn)

	# 6. Diário de Memórias
	_menu_btn = Button.new()
	_menu_btn.custom_minimum_size = Vector2(0, 50)
	_menu_btn.text = "Guardar Diário e Sair"
	_menu_btn.pressed.connect(_on_menu_pressed)
	_menu_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Guardar Diário e Sair. O progresso desta tentativa será desfeito. Botão 6 de 6.")
	)
	col.add_child(_menu_btn)

	_setup_focus_trap()
	call_deferred("_focus_initial")

func _setup_focus_trap() -> void:
	# F2: Configura focus trap fechando o loop de navegação vertical
	_resume_btn.focus_neighbor_top = _menu_btn.get_path()
	_resume_btn.focus_neighbor_bottom = _restart_btn.get_path()

	_restart_btn.focus_neighbor_top = _resume_btn.get_path()
	_restart_btn.focus_neighbor_bottom = _cues_toggle.get_path()

	_cues_toggle.focus_neighbor_top = _restart_btn.get_path()
	_cues_toggle.focus_neighbor_bottom = _talkback_toggle.get_path()

	_talkback_toggle.focus_neighbor_top = _cues_toggle.get_path()
	_talkback_toggle.focus_neighbor_bottom = _colors_btn.get_path()

	_colors_btn.focus_neighbor_top = _talkback_toggle.get_path()
	_colors_btn.focus_neighbor_bottom = _menu_btn.get_path()

	_menu_btn.focus_neighbor_top = _colors_btn.get_path()
	_menu_btn.focus_neighbor_bottom = _resume_btn.get_path()

func _focus_initial() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	if _resume_btn != null and is_instance_valid(_resume_btn):
		_resume_btn.grab_focus()
	AccessibleAnnouncer.announce("pause", "Um instante de silêncio. Jogo pausado. Foco em Retomar os Passos.")

func _update_cues_toggle_text() -> void:
	var on := _cues_toggle.button_pressed
	_cues_toggle.text = "Pistas nos Controles: %s [%s]" % [
		"Ligadas" if on else "Desligadas",
		"✓" if on else "✕"
	]

func _on_cues_toggled(enabled: bool) -> void:
	ColorSchemeSettings.set_control_cues(enabled)
	ColorSchemeSettings.save_to_disk()
	_update_cues_toggle_text()
	var earcon := "toggle_on" if enabled else "toggle_off"
	var estado := "Ligadas" if enabled else "Desligadas"
	AccessibleAnnouncer.announce(earcon, "Pistas nos controles: %s" % estado)

func _update_talkback_toggle_text() -> void:
	var on := _talkback_toggle.button_pressed
	_talkback_toggle.text = "Voz do Narrador: %s [%s]" % [
		"Ligada" if on else "Desligada",
		"✓" if on else "✕"
	]

func _on_talkback_toggled(enabled: bool) -> void:
	AccessibleAnnouncer.set_tts_enabled(enabled)
	_update_talkback_toggle_text()
	var earcon := "toggle_on" if enabled else "toggle_off"
	var estado := "Ligada" if enabled else "Desligada"
	AccessibleAnnouncer.announce(earcon, "Voz do narrador: %s" % estado)

func _unhandled_input(event: InputEvent) -> void:
	# F3: Atalho para fechar pausa (Esc, P, Joypad Start, ui_cancel)
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirm_dialog != null and is_instance_valid(_confirm_dialog):
			_close_confirm_dialog()
		elif _sub_modal != null and is_instance_valid(_sub_modal):
			_close_sub_modal()
		else:
			_on_resume_pressed()

func _on_resume_pressed() -> void:
	_restore_previous_focus()
	resume_requested.emit()

func _on_restart_pressed() -> void:
	_show_confirmation(
		"Deseja recomeçar esta lembrança do primeiro passo?",
		func():
			_restore_previous_focus()
			restart_requested.emit(),
		"Continuar Ouvindo",
		"Recomeçar"
	)

func _on_menu_pressed() -> void:
	_show_confirmation(
		"Deseja fechar esta página por enquanto? Os passos desta tentativa serão desfeitos.",
		func():
			_restore_previous_focus()
			level_select_requested.emit(),
		"Ficar na Memória",
		"Fechar Página"
	)

func _show_confirmation(message: String, on_confirm: Callable, cancel_text: String = "Cancelar", confirm_text: String = "Confirmar") -> void:
	if _confirm_dialog != null and is_instance_valid(_confirm_dialog):
		_close_confirm_dialog()
	
	_confirm_dialog = PanelContainer.new()
	_confirm_dialog.custom_minimum_size = Vector2(360, 180)
	add_child(_confirm_dialog)
	_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	
	var m := MarginContainer.new()
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		m.add_theme_constant_override(s, 16)
	_confirm_dialog.add_child(m)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	m.add_child(vbox)
	
	var lbl := Label.new()
	lbl.text = message
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)
	
	var cancel_btn := Button.new()
	cancel_btn.name = "CancelBtn"
	cancel_btn.custom_minimum_size = Vector2(130, 44)
	cancel_btn.text = cancel_text
	cancel_btn.pressed.connect(_close_confirm_dialog)
	hbox.add_child(cancel_btn)
	
	var confirm_btn := Button.new()
	confirm_btn.name = "ConfirmBtn"
	confirm_btn.custom_minimum_size = Vector2(130, 44)
	confirm_btn.text = confirm_text
	confirm_btn.pressed.connect(func():
		_close_confirm_dialog()
		on_confirm.call()
	)
	hbox.add_child(confirm_btn)
	
	cancel_btn.focus_neighbor_right = confirm_btn.get_path()
	confirm_btn.focus_neighbor_left = cancel_btn.get_path()
	
	# Foco padrão no Cancelar por segurança
	cancel_btn.call_deferred("grab_focus")
	AccessibleAnnouncer.announce("focus", "%s Foco em %s." % [message, cancel_text])

func _close_confirm_dialog() -> void:
	if _confirm_dialog != null and is_instance_valid(_confirm_dialog):
		_confirm_dialog.queue_free()
		_confirm_dialog = null
	if _resume_btn != null and is_instance_valid(_resume_btn):
		_resume_btn.grab_focus()
	AccessibleAnnouncer.announce("cancel", "Cancelado. De volta ao menu de pausa.")

func _on_colors_pressed() -> void:
	if _sub_modal != null:
		return
	var modal = COLOR_SCREEN_SCENE.instantiate()
	_sub_modal = modal
	add_child(modal)
	AccessibleAnnouncer.announce("confirm", "Tela de cores das notas aberta.")
	modal.closed.connect(_close_sub_modal)

func _close_sub_modal() -> void:
	if _sub_modal != null and is_instance_valid(_sub_modal):
		_sub_modal.queue_free()
		_sub_modal = null
	# F9: Restaura o foco para o botão de origem ao fechar
	if _colors_btn != null and is_instance_valid(_colors_btn):
		_colors_btn.grab_focus()
	AccessibleAnnouncer.announce("cancel", "Cores das notas fechado. Foco em Cores das Notas.")

func _restore_previous_focus() -> void:
	if _previous_focus != null and is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree():
		_previous_focus.grab_focus()
