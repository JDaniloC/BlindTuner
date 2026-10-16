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
	_chapter_opt.add_item("Capítulo 1: A Casa Conhecida")
	_chapter_opt.set_item_metadata(0, 1)
	_chapter_opt.add_item("Capítulo 2: O Bairro e o Cotidiano")
	_chapter_opt.set_item_metadata(1, 2)
	_chapter_opt.add_item("Capítulo 3: As Últimas Paisagens")
	_chapter_opt.set_item_metadata(2, 3)
	_chapter_opt.add_item("Caderno Suzuki: Vol. 1 — Primeiros Passos")
	_chapter_opt.set_item_metadata(3, 101)
	_chapter_opt.add_item("Caderno Suzuki: Vol. 2 — A Casa em Movimento")
	_chapter_opt.set_item_metadata(4, 102)
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
	var meta = _chapter_opt.get_item_metadata(idx)
	var chapter_num: int = int(meta) if meta != null else (idx + 1)
	AccessibleAnnouncer.announce("confirm", "Capítulo selecionado: %s" % chapter_text)
	_populate_levels_for_chapter(chapter_num)
	call_deferred("_focus_initial_element")

func _populate_levels_for_chapter(chapter_num: int) -> void:
	_first_focusable = null
	for child in _cards_container.get_children():
		child.queue_free()

	var ch_info: Dictionary = LevelCatalog.get_chapter_info(chapter_num)
	if not ch_info.is_empty() and not str(ch_info.get("subtitle", "")).is_empty():
		var banner := PanelContainer.new()
		_cards_container.add_child(banner)
		var b_margin := MarginContainer.new()
		for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			b_margin.add_theme_constant_override(s, 10)
		banner.add_child(b_margin)
		var b_vbox := VBoxContainer.new()
		b_vbox.add_theme_constant_override("separation", 2)
		b_margin.add_child(b_vbox)

		var sub_lbl := Label.new()
		sub_lbl.text = "“%s”" % ch_info.get("subtitle")
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b_vbox.add_child(sub_lbl)

	var levels := LevelCatalog.by_chapter(chapter_num)
	if levels.is_empty():
		var teasers: Array = ch_info.get("teasers", [])
		if teasers.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "Novas memórias serão desbloqueadas em breve."
			_cards_container.add_child(empty_lbl)
			AccessibleAnnouncer.speak("Capítulo em breve. Nenhuma memória disponível ainda.")
		else:
			for t in teasers:
				var btn = _create_teaser_card(t)
				if _first_focusable == null and btn != null:
					_first_focusable = btn
			AccessibleAnnouncer.speak("%s. Memórias em breve disponíveis para consulta." % ch_info.get("title", ""))
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
		"banheiro": return "Banheiro"
		"jardim_portao": return "Jardim da Frente"
		"padaria_calcada": return "Calçada da Padaria"
		"praca_chafariz": return "Praça do Chafariz"
		"largo_matriz": return "Largo da Matriz"
		"jardim": return "Jardim"
		"arcade_s1_vento": return "Sala da Veneziana"
		"arcade_s1_oculos": return "Escrivaninha de Leitura"
		"arcade_s1_planta": return "Canto da Samambaia"
		"arcade_s1_louca": return "Bancada de Porcelana"
		"arcade_s2_gato": return "Sala de Estar do Mimi"
		"arcade_s2_valsa": return "Corredor Ensolarado"
		"arcade_s2_chaves": return "Aparador da Entrada"
		"praia_mirante": return "Praia do Mirante"
		"estacao_plataforma": return "Plataforma da Estação"
		"estudio_conservatorio": return "Estúdio do Conservatório"
		"teatro_palco": return "Palco do Grande Teatro"
		_: return map_id.replace("_", " ").capitalize()

func _format_beacon_name(beacon_id: String) -> String:
	match beacon_id:
		"radio": return "📻 Farol: Rádio Vintage"
		"music_box": return "🧸 Farol: Caixa de Música"
		"drip": return "💧 Farol: Fio d'Água na Pia"
		"clock": return "🕰️ Farol: Carrilhão da Sala"
		"gate_latch": return "🗝️ Farol: Trinco do Portão"
		"shop_bell": return "🔔 Farol: Sino da Padaria"
		"fountain_birds": return "🐦 Farol: Chafariz e Pássaros"
		"church_bell": return "⛪ Farol: Sino da Matriz"
		"window_wind": return "🪟 Farol: Veneziana ao Vento"
		"wrist_watch": return "⌚ Farol: Relógio de Pulso"
		"watering_can": return "🪴 Farol: Regador de Bico Fino"
		"tea_cup": return "☕ Farol: Colher na Porcelana"
		"cat_bell": return "🔔 Farol: Sininho da Coleira"
		"broom_sweep": return "🧹 Farol: Roçar de Vassoura"
		"keys_jingle": return "🔑 Farol: Chaves de Latão"
		"ocean_waves": return "🌊 Farol: Ondas na Areia"
		"train_whistle": return "🚂 Farol: Apito e Vapor do Trem"
		"cello_drone": return "🎻 Farol: Corda Solta do Cello"
		"wind_chimes": return "✨ Farol: Sinos de Vento do Palco"
		_: return "👂 Farol Sonoro"

func _stars_taxonomy_text(stars: int) -> String:
	match stars:
		3: return "3 de 3 estrelas: Memória Resgatada, Ouvido Fino e Passo Firme"
		2: return "2 de 3 estrelas: Memória Resgatada e Ouvido Fino"
		1: return "1 de 3 estrelas: Memória Resgatada"
		_: return "Nenhuma estrela conquistada ainda"

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

	var num_str: String
	if lvl.chapter == 101:
		num_str = "S1.%d" % lvl.level_number
	elif lvl.chapter == 102:
		num_str = "S2.%d" % lvl.level_number
	else:
		num_str = "%d.%d" % [lvl.chapter, lvl.level_number]

	# Linha 1: Título e Estrelas
	var top_row := HBoxContainer.new()
	card_vbox.add_child(top_row)

	var title_lbl := Label.new()
	title_lbl.text = "%s %s" % [num_str, lvl.title]
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title_lbl)

	var stars_lbl := Label.new()
	var stars_text := ""
	for i in range(3):
		stars_text += "★" if i < stars else "☆"
	stars_lbl.text = "%s (%d/3)" % [stars_text, stars]
	top_row.add_child(stars_lbl)

	# Linha 2: Resumo / Detalhes da música e farol sonoro
	var details_lbl := Label.new()
	var inst_name: String = "Piano" if lvl.instrument == "piano" else "Cello"
	var scenario_name: String = _format_scenario_name(lvl.map_id)
	var beacon_desc: String = _format_beacon_name(lvl.beacon_sound_id)
	var song_info: String = ("🎵 %s • " % lvl.song_title) if not lvl.song_title.is_empty() else ""
	details_lbl.text = "%s%s • %s • %s • %d notas" % [song_info, beacon_desc, scenario_name, inst_name, lvl.total_steps()]
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

	var stars_desc := _stars_taxonomy_text(stars)
	var song_speech: String = (" Música: %s de %s." % [lvl.song_title, lvl.composer]) if not lvl.song_title.is_empty() else ""
	var speech_text: String
	
	if is_unlocked:
		play_level_btn.text = "Reviver Memória %s: %s" % [num_str, lvl.title]
		speech_text = "Memória %s: %s.%s %s. %s, Cenário %s, Instrumento %s, %d notas. Pressione Enter ou A para reviver." % [
			num_str, lvl.title, song_speech, stars_desc, beacon_desc, scenario_name, inst_name, lvl.total_steps()
		]
		play_level_btn.pressed.connect(func():
			AccessibleAnnouncer.announce("confirm", "Iniciando memória %s" % lvl.title)
			SceneManager.start_level(lvl.id)
		)
	else:
		play_level_btn.text = "🔒 Memória %s: Bloqueada (%s)" % [num_str, lvl.title]
		speech_text = "Memória %s: %s, bloqueada. Conclua as memórias anteriores para desbloquear." % [
			num_str, lvl.title
		]
		play_level_btn.pressed.connect(func():
			AccessibleAnnouncer.announce("error", "Esta memória está bloqueada. Conclua as memórias anteriores primeiro.")
		)

	play_level_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus" if is_unlocked else "locked", speech_text)
	)

	return play_level_btn

func _create_teaser_card(t: Dictionary) -> Button:
	var card_panel := PanelContainer.new()
	_cards_container.add_child(card_panel)

	var card_margin := MarginContainer.new()
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		card_margin.add_theme_constant_override(s, 12)
	card_panel.add_child(card_margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	card_margin.add_child(card_vbox)

	# Linha 1: Título e Status Em Breve
	var top_row := HBoxContainer.new()
	card_vbox.add_child(top_row)

	var title_lbl := Label.new()
	title_lbl.text = "%s %s" % [t.get("num", ""), t.get("title", "")]
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title_lbl)

	var badge_lbl := Label.new()
	badge_lbl.text = "🔒 Em Breve"
	top_row.add_child(badge_lbl)

	# Linha 2: Farol Sonoro
	var beacon_lbl := Label.new()
	beacon_lbl.text = "%s Farol Sonoro: %s" % [t.get("icon", "👂"), t.get("beacon", "")]
	card_vbox.add_child(beacon_lbl)

	# Linha 3: Texto de história poética
	var story_lbl := Label.new()
	story_lbl.text = "\"%s\"" % t.get("story", "")
	story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(story_lbl)

	# Linha 4: Botão de Foco Acessível
	var teaser_btn := Button.new()
	teaser_btn.custom_minimum_size = Vector2(0, 48)
	card_vbox.add_child(teaser_btn)

	var num_str: String = str(t.get("num", ""))
	var title_str: String = str(t.get("title", ""))
	var beacon_str: String = str(t.get("beacon", ""))
	var story_str: String = str(t.get("story", ""))

	teaser_btn.text = "🔒 Memória %s: Bloqueada (Em breve)" % num_str
	var speech_text := "Memória %s: %s. Em breve. Farol sonoro: %s. %s" % [
		num_str, title_str, beacon_str, story_str
	]

	teaser_btn.pressed.connect(func():
		AccessibleAnnouncer.announce("locked", "Esta memória faz parte de um próximo capítulo e estará disponível em breve.")
	)
	teaser_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("locked", speech_text)
	)

	return teaser_btn

func _on_back_pressed() -> void:
	AccessibleAnnouncer.announce("cancel", "Retornando ao Menu Principal.")
	SceneManager.go_to_main_menu()

