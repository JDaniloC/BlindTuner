extends Control
## Modal de vitória exibido após a conclusão com sucesso de um nível.
## Apresenta as 3 estrelas categóricas (DEC-0005):
##   1. 🏅 Memória Resgatada (conclusão do percurso)
##   2. 👂 Ouvido Fino (afinação melódica de 1ª sem desafinar)
##   3. 🦯 Passo Firme (navegação limpa sem esbarrões)
## Exibe retrato emocional, citação poética, estatísticas e opções acessíveis.

signal next_level_requested
signal restart_requested
signal level_select_requested

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const PORTRAIT_SCENE := preload("res://scenes/CharacterPortrait.tscn")

var _title_lbl: Label
var _song_lbl: Label
var _portrait: Control
var _stars_lbl: Label
var _badges_container: VBoxContainer
var _story_panel: PanelContainer
var _story_lbl: Label
var _stats_lbl: Label
var _next_btn: Button
var _retry_btn: Button
var _menu_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Fundo escurecido semitransparente para isolamento visual e foco
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.04, 0.07, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var sparkles := VictorySparkles2D.new()
	sparkles.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sparkles)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 620)
	center.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(460, 600)
	panel.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(s, 20)
	scroll.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	# 1. Título do Nível / Conquista
	_title_lbl = Label.new()
	_title_lbl.text = "Memória Concluída!"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_lbl.add_theme_font_size_override("font_size", 24)
	_title_lbl.add_theme_color_override("font_color", Color(0.14, 0.11, 0.08))
	col.add_child(_title_lbl)

	# 2. Informação da Obra Musical e Compositor
	_song_lbl = Label.new()
	_song_lbl.text = ""
	_song_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_song_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_song_lbl.add_theme_font_size_override("font_size", 16)
	_song_lbl.add_theme_color_override("font_color", Color(0.10, 0.25, 0.38))
	col.add_child(_song_lbl)

	# 3. Retrato Emocional do Idoso Feliz
	var portrait_box := CenterContainer.new()
	col.add_child(portrait_box)
	_portrait = PORTRAIT_SCENE.instantiate()
	portrait_box.add_child(_portrait)
	if _portrait.has_method("on_victory"):
		_portrait.on_victory()

	# 4. Resumo das Estrelas (★ ★ ★)
	_stars_lbl = Label.new()
	_stars_lbl.text = "★★★"
	_stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars_lbl.add_theme_font_size_override("font_size", 30)
	_stars_lbl.add_theme_color_override("font_color", Color(0.30, 0.16, 0.04))
	col.add_child(_stars_lbl)

	# 5. Lista de Badges / Selos Categóricos (DEC-0005)
	_badges_container = VBoxContainer.new()
	_badges_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_badges_container.add_theme_constant_override("separation", 8)
	col.add_child(_badges_container)

	# 6. Painel Poético da Memória Desbloqueada
	_story_panel = PanelContainer.new()
	var story_sb := StyleBoxFlat.new()
	story_sb.set_corner_radius_all(6)
	story_sb.bg_color = Color(0.12, 0.10, 0.08, 0.94)
	story_sb.border_width_left = 3
	story_sb.border_color = Color(0.85, 0.65, 0.25, 0.95)
	story_sb.content_margin_left = 14
	story_sb.content_margin_right = 14
	story_sb.content_margin_top = 10
	story_sb.content_margin_bottom = 10
	_story_panel.add_theme_stylebox_override("panel", story_sb)
	col.add_child(_story_panel)

	_story_lbl = Label.new()
	_story_lbl.text = ""
	_story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_lbl.add_theme_font_size_override("font_size", 15)
	_story_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86))
	_story_panel.add_child(_story_lbl)

	# 7. Estatísticas de Telemetria (Tempo, Acertos, Tropeços)
	_stats_lbl = Label.new()
	_stats_lbl.text = ""
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_lbl.add_theme_font_size_override("font_size", 14)
	_stats_lbl.add_theme_color_override("font_color", Color(0.26, 0.22, 0.18))
	col.add_child(_stats_lbl)

	# 8. Botão Principal: Seguir para a Próxima Lembrança
	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(0, 50)
	_next_btn.text = "Seguir para a Próxima Lembrança"
	_next_btn.pressed.connect(func(): next_level_requested.emit())
	_next_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Seguir para a próxima lembrança. Botão principal.")
	)
	col.add_child(_next_btn)

	# 9. Linha de Ações Secundárias (Tocar Outra Vez + Folhear Diário)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)

	_retry_btn = Button.new()
	_retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_retry_btn.custom_minimum_size = Vector2(0, 46)
	_retry_btn.text = "Tocar Outra Vez"
	_retry_btn.pressed.connect(func(): restart_requested.emit())
	_retry_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Tocar outra vez. Repete esta memória para aperfeiçoar afinação e passos.")
	)
	row.add_child(_retry_btn)

	_menu_btn = Button.new()
	_menu_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu_btn.custom_minimum_size = Vector2(0, 46)
	_menu_btn.text = "Folhear Diário"
	_menu_btn.pressed.connect(func(): level_select_requested.emit())
	_menu_btn.focus_entered.connect(func():
		AccessibleAnnouncer.announce("focus", "Folhear Diário. Retorna à lista de memórias e capítulos.")
	)
	row.add_child(_menu_btn)

func display_result(level_data, summary: Dictionary) -> void:
	var stars: int = int(summary.get("stars", 1))
	var hits: int = int(summary.get("first_try_hits", 0))
	var trips: int = int(summary.get("trips", 0))
	var wall_bumps: int = int(summary.get("wall_bumps", trips))
	var pitch_misses: int = int(summary.get("pitch_misses", 0))
	var elapsed: float = float(summary.get("elapsed_sec", 0.0))
	var has_next: bool = bool(summary.get("has_next_level", false))

	var total_notes: int = hits
	var max_bumps: int = 0
	if level_data != null:
		total_notes = level_data.total_steps()
		max_bumps = level_data.max_trips_for_three_stars

	var has_mem: bool = true # Chegar ao fim sempre conquista a estrela de conclusão
	var has_ear: bool = (total_notes > 0 and hits >= total_notes) if level_data != null else (stars >= 2)
	var has_step: bool = (wall_bumps <= max_bumps) if level_data != null else (stars >= 3)

	# Título e cabeçalho
	if level_data != null:
		if stars == 3:
			_title_lbl.text = "%s Afinada com Afeto!" % level_data.title
		else:
			_title_lbl.text = "%s Guardada no Coração!" % level_data.title
	else:
		_title_lbl.text = "Memória Afinada com Afeto!" if stars == 3 else "Memória Guardada no Coração!"

	# Metadados da obra musical
	var song_title: String = str(level_data.get("song_title")) if level_data != null and ("song_title" in level_data) else ""
	var composer: String = str(level_data.get("composer")) if level_data != null and ("composer" in level_data) else ""
	if not song_title.is_empty():
		_song_lbl.text = "Peça: %s • %s" % [song_title, composer]
		_song_lbl.visible = true
	else:
		_song_lbl.visible = false

	# Resumo em estrelas com celebração elástica
	var stars_text := ""
	for i in range(3):
		stars_text += "★" if i < stars else "☆"
	_stars_lbl.text = stars_text
	if is_inside_tree() and stars >= 2:
		_stars_lbl.pivot_offset = _stars_lbl.size * 0.5
		var s_tw := create_tween()
		s_tw.tween_property(_stars_lbl, "scale", Vector2(1.22, 1.22), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		s_tw.tween_property(_stars_lbl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)

	# Retrato
	if _portrait != null and _portrait.has_method("on_victory"):
		_portrait.on_victory()

	# Recria os cartões com os 3 selos categóricos (DEC-0005)
	for child in _badges_container.get_children():
		child.queue_free()

	var card_mem := _create_badge_card(
		"🏅 Memória Resgatada",
		"Alcançou o objetivo final e completou o percurso.",
		has_mem,
		"Conquistada"
	)
	_badges_container.add_child(card_mem)

	var ear_detail := "Conquistada" if has_ear else (
		"%d nota(s) desafinada(s)" % pitch_misses if pitch_misses > 0 else "%d/%d de 1ª" % [hits, total_notes]
	)
	var card_ear := _create_badge_card(
		"👂 Ouvido Fino",
		"Afinação melódica de 1ª tentativa sem desafinar nenhuma nota.",
		has_ear,
		ear_detail
	)
	_badges_container.add_child(card_ear)

	var step_detail := "Conquistada" if has_step else ("%d tropeço(s)" % wall_bumps)
	var card_step := _create_badge_card(
		"🦯 Passo Firme",
		"Caminhada segura com a bengala sem esbarrar nas paredes ou quinas.",
		has_step,
		step_detail
	)
	_badges_container.add_child(card_step)

	# Poema / Outro narrativo
	var outro_text: String = str(level_data.get("story_outro")) if level_data != null and ("story_outro" in level_data) else ""
	if not outro_text.is_empty():
		_story_lbl.text = "\"%s\"" % outro_text
		_story_panel.visible = true
	else:
		_story_panel.visible = false

	# Estatísticas numéricas
	var steps_desc: String = "Passos firmes e seguros" if wall_bumps == 0 else ("%d tropeço(s)" % wall_bumps)
	_stats_lbl.text = "Afinação de 1ª: %d/%d  •  Passos: %s  •  Tempo: %.1fs" % [hits, total_notes, steps_desc, elapsed]

	# Visibilidade e foco dos botões
	_next_btn.visible = has_next
	if has_next:
		_next_btn.focus_neighbor_bottom = _retry_btn.get_path()
		_retry_btn.focus_neighbor_top = _next_btn.get_path()
		_retry_btn.focus_neighbor_right = _menu_btn.get_path()
		_menu_btn.focus_neighbor_left = _retry_btn.get_path()
		_menu_btn.focus_neighbor_top = _next_btn.get_path()
		_next_btn.call_deferred("grab_focus")
	else:
		_retry_btn.focus_neighbor_top = NodePath("")
		_retry_btn.focus_neighbor_right = _menu_btn.get_path()
		_menu_btn.focus_neighbor_left = _retry_btn.get_path()
		_menu_btn.focus_neighbor_top = NodePath("")
		_retry_btn.call_deferred("grab_focus")

	# Narração TalkBack / Acessibilidade Plena
	var earned_list: Array[String] = ["Memória Resgatada"]
	if has_ear:
		earned_list.append("Ouvido Fino")
	if has_step:
		earned_list.append("Passo Firme")

	var stars_narrative: String
	if stars == 3:
		stars_narrative = "Todas as 3 estrelas conquistadas: Memória Resgatada, Ouvido Fino e Passo Firme."
	elif stars == 2:
		var missing_badge: String = "Passo Firme" if not has_step else "Ouvido Fino"
		stars_narrative = "2 de 3 estrelas conquistadas: %s. Tente outra vez para conquistar %s." % [
			" e ".join(earned_list),
			missing_badge
		]
	else:
		stars_narrative = "1 de 3 estrelas conquistada: Memória Resgatada. Tente outra vez para conquistar Ouvido Fino e Passo Firme."

	var song_extra: String = (" Peça musical: %s de %s." % [song_title, composer]) if not song_title.is_empty() else ""
	var outro_speech: String = (" Memória resgatada: %s." % outro_text) if not outro_text.is_empty() else ""
	var nav_hint: String = "Pressione Enter ou A para seguir para a próxima lembrança." if has_next else "Pressione Enter ou A para tocar outra vez."
	var full_speech := "Vitória! %s.%s %s%s %s" % [_title_lbl.text, song_extra, stars_narrative, outro_speech, nav_hint]
	AccessibleAnnouncer.announce("confirm", full_speech)

func _create_badge_card(badge_name: String, requirement: String, earned: bool, reason_detail: String) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8

	if earned:
		sb.bg_color = Color(0.16, 0.13, 0.08, 0.96)
		sb.border_color = Color(0.92, 0.76, 0.20, 0.98)
	else:
		sb.bg_color = Color(0.12, 0.12, 0.15, 0.94)
		sb.border_color = Color(0.45, 0.45, 0.52, 0.75)

	card.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	var star_lbl := Label.new()
	star_lbl.text = "★" if earned else "☆"
	star_lbl.custom_minimum_size = Vector2(32, 0)
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_lbl.add_theme_font_size_override("font_size", 22)
	star_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20) if earned else Color(0.80, 0.80, 0.86))
	hbox.add_child(star_lbl)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)

	var title_lbl := Label.new()
	title_lbl.text = badge_name
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88) if earned else Color(0.88, 0.88, 0.92))
	text_vbox.add_child(title_lbl)

	var req_lbl := Label.new()
	req_lbl.text = requirement
	req_lbl.add_theme_font_size_override("font_size", 13)
	req_lbl.add_theme_color_override("font_color", Color(0.90, 0.86, 0.78) if earned else Color(0.76, 0.76, 0.82))
	req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(req_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "✓ Conquistada" if earned else ("✗ " + reason_detail)
	status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55) if earned else Color(0.96, 0.72, 0.58))
	hbox.add_child(status_lbl)

	return card

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		level_select_requested.emit()

class VictorySparkles2D extends Control:
	var _time: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 0 or h <= 0:
			return
		# 16 partículas douradas de celebração subindo suavemente
		for i in range(16):
			var speed := 0.18 + float(i % 5) * 0.04
			var phase := fmod(_time * speed + float(i) * 0.0625, 1.0)
			var seed_x := fmod(float(i * 97) + 33.0, w)
			var x := seed_x + sin(_time * 1.5 + float(i)) * 18.0
			var y := h - phase * (h + 40.0)
			var alpha := sin(phase * PI) * 0.75
			var is_gold := (i % 3) != 0
			var col := Color(1.0, 0.88, 0.35, alpha) if is_gold else Color(0.40, 0.90, 1.0, alpha)
			var d_size := 3.5 if is_gold else 2.5
			# Desenha losango de celebração
			var pts := PackedVector2Array([
				Vector2(x, y - d_size),
				Vector2(x + d_size, y),
				Vector2(x, y + d_size),
				Vector2(x - d_size, y)
			])
			draw_colored_polygon(pts, col)
