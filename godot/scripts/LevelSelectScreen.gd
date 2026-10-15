extends Control
## Tela do Diário de Memórias (Seleção de Níveis).
## Permite ao jogador navegar entre capítulos e selecionar fases desbloqueadas
## com suporte completo a navegação por teclado/gamepad, foco visível,
## leitura acessível e retorno sonoro.

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")

var _chapter_opt: OptionButton
var _cards_container: VBoxContainer
var _scroll: ScrollContainer
var _back_btn: Button
var _first_focusable: Control = null

func _ready() -> void:
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	bg.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	margin.add_child(col)

	# --- Cabeçalho ---
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	col.add_child(header_box)

	var title := Label.new()
	title.text = "Diário de Memórias"
	header_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Escolha uma recordação para afinar e praticar"
	header_box.add_child(subtitle)

	# --- Seletor de Capítulos ---
	_chapter_opt = OptionButton.new()
	_chapter_opt.add_item("Capítulo 1: O Refúgio Conhecido (A Casa)")
	_chapter_opt.add_item("Capítulo 2: O Bairro e a Rotina (Em breve)")
	_chapter_opt.add_item("Capítulo 3: As Últimas Imagens (Em breve)")
	_chapter_opt.item_selected.connect(_on_chapter_selected)
	_chapter_opt.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Seletor de Capítulos: %s. Use as setas ou clique para alterar." % _chapter_opt.get_item_text(_chapter_opt.selected))
	)
	col.add_child(_chapter_opt)

	# --- Lista Rolável de Cards de Nível ---
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true # F6: Rolagem acompanha o foco automaticamente
	col.add_child(_scroll)

	_cards_container = VBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("separation", 12)
	_scroll.add_child(_cards_container)

	# --- Rodapé com botão de voltar ---
	_back_btn = Button.new()
	_back_btn.custom_minimum_size = Vector2(0, 52)
	_back_btn.text = "Voltar ao Menu Principal"
	_back_btn.pressed.connect(_on_back_pressed)
	_back_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Voltar ao Menu Principal. Botão.")
	)
	col.add_child(_back_btn)

	_populate_levels_for_chapter(1)
	call_deferred("_focus_initial_element")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func _focus_initial_element() -> void:
	if _first_focusable != null and is_instance_valid(_first_focusable):
		_first_focusable.grab_focus()
	elif _back_btn != null and is_instance_valid(_back_btn):
		_back_btn.grab_focus()

func _on_chapter_selected(idx: int) -> void:
	var chapter_text := _chapter_opt.get_item_text(idx)
	AccessibleAnnouncer.announce("confirm", "Capítulo selecionado: %s" % chapter_text)
	_populate_levels_for_chapter(idx + 1)
	call_deferred("_focus_initial_element")

func _populate_levels_for_chapter(chapter_num: int) -> void:
	_first_focusable = null
	for child in _cards_container.get_children():
		child.queue_free()

	var levels := LevelCatalog.by_chapter(chapter_num)
	if levels.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Novas memórias serão desbloqueadas em breve."
		_cards_container.add_child(empty_lbl)
		AccessibleAnnouncer.speak("Capítulo em breve. Nenhuma memória disponível ainda.")
		return

	for lvl in levels:
		var btn = _create_level_card(lvl)
		if _first_focusable == null and btn != null:
			_first_focusable = btn

func _format_scenario_name(map_id: String) -> String:
	match map_id:
		"quarto": return "Quarto"
		"quarto_lullaby": return "Quarto à Noite"
		"sala": return "Sala de Estar"
		"jardim": return "Jardim"
		_: return map_id.replace("_", " ").capitalize()

func _create_level_card(lvl) -> Button:
	var card_panel := PanelContainer.new()
	_cards_container.add_child(card_panel)

	var card_margin := MarginContainer.new()
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		card_margin.add_theme_constant_override(s, 12)
	card_panel.add_child(card_margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	card_margin.add_child(card_vbox)

	var is_unlocked := SaveManager.is_level_unlocked(lvl.id)
	var stars := SaveManager.get_level_stars(lvl.id)

	# Linha 1: Título e Estrelas
	var top_row := HBoxContainer.new()
	card_vbox.add_child(top_row)

	var title_lbl := Label.new()
	title_lbl.text = "%d.%d %s" % [lvl.chapter, lvl.level_number, lvl.title]
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title_lbl)

	var stars_lbl := Label.new()
	var stars_text := ""
	for i in range(3):
		stars_text += "★" if i < stars else "☆"
	stars_lbl.text = "%s (%d/3)" % [stars_text, stars]
	top_row.add_child(stars_lbl)

	# Linha 2: Resumo / Detalhes da música
	var details_lbl := Label.new()
	var inst_name: String = "Piano" if lvl.instrument == "piano" else "Cello"
	var scenario_name: String = _format_scenario_name(lvl.map_id)
	details_lbl.text = "Cenário: %s • Instrumento: %s • %d notas" % [scenario_name, inst_name, lvl.total_steps()]
	card_vbox.add_child(details_lbl)

	# Linha 3: Texto de história
	var story_lbl := Label.new()
	story_lbl.text = "\"%s\"" % lvl.story_intro
	story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(story_lbl)

	# Linha 4: Botão de Ação Acessível
	var play_level_btn := Button.new()
	play_level_btn.custom_minimum_size = Vector2(0, 48)
	card_vbox.add_child(play_level_btn)

	var stars_desc := "%d de 3 estrelas" % stars if stars > 0 else "Nenhuma estrela ainda"
	var speech_text: String
	
	if is_unlocked:
		play_level_btn.text = "Reviver Memória %d.%d: %s" % [lvl.chapter, lvl.level_number, lvl.title]
		speech_text = "Memória %d.%d: %s. %s. Cenário %s, Instrumento %s, %d notas. Pressione Enter ou A para reviver." % [
			lvl.chapter, lvl.level_number, lvl.title, stars_desc, scenario_name, inst_name, lvl.total_steps()
		]
		play_level_btn.pressed.connect(func():
			AccessibleAnnouncer.announce("confirm", "Iniciando memória %s" % lvl.title)
			SceneManager.start_level(lvl.id)
		)
	else:
		play_level_btn.text = "🔒 Memória %d.%d: Bloqueada (%s)" % [lvl.chapter, lvl.level_number, lvl.title]
		speech_text = "Memória %d.%d: %s, bloqueada. Conclua as memórias anteriores para desbloquear." % [
			lvl.chapter, lvl.level_number, lvl.title
		]
		# Permite foco para navegação não-visual sem crashar ou travar o cursor
		play_level_btn.pressed.connect(func():
			AccessibleAnnouncer.announce("error", "Esta memória está bloqueada. Conclua as memórias anteriores primeiro.")
		)

	play_level_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus" if is_unlocked else "locked", speech_text)
	)

	return play_level_btn

func _on_back_pressed() -> void:
	AccessibleAnnouncer.announce("cancel", "Retornando ao Menu Principal.")
	SceneManager.go_to_main_menu()
