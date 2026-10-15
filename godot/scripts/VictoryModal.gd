extends Control
## Modal de vitória exibido após a conclusão com sucesso de um nível.
## Mostra estrelas ganhas, memória poética desbloqueada e opções de progressão.

signal next_level_requested
signal restart_requested
signal level_select_requested

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const PORTRAIT_SCENE := preload("res://scenes/CharacterPortrait.tscn")

var _title_lbl: Label
var _stars_lbl: Label
var _story_lbl: Label
var _stats_lbl: Label
var _next_btn: Button
var _retry_btn: Button
var _menu_btn: Button
var _portrait: Control

func _ready() -> void:
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Fundo semitransparente escurecido
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.04, 0.06, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 500)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(s, 24)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	_title_lbl = Label.new()
	_title_lbl.text = "Memória Concluída!"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title_lbl)

	# Retrato Emocional do Idoso Feliz
	var portrait_box := CenterContainer.new()
	col.add_child(portrait_box)
	_portrait = PORTRAIT_SCENE.instantiate()
	portrait_box.add_child(_portrait)
	if _portrait.has_method("on_victory"):
		_portrait.on_victory()

	# Estrelas
	_stars_lbl = Label.new()
	_stars_lbl.text = "★★★"
	_stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_stars_lbl)

	# Poema / Memória Desbloqueada
	_story_lbl = Label.new()
	_story_lbl.text = ""
	_story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_story_lbl)

	# Estatísticas (Acertos, Tropeços, Tempo)
	_stats_lbl = Label.new()
	_stats_lbl.text = ""
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_stats_lbl)

	# Botões
	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(0, 48)
	_next_btn.text = "Próxima Memória"
	_next_btn.pressed.connect(func(): next_level_requested.emit())
	col.add_child(_next_btn)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)

	_retry_btn = Button.new()
	_retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_retry_btn.custom_minimum_size = Vector2(0, 44)
	_retry_btn.text = "Repetir"
	_retry_btn.pressed.connect(func(): restart_requested.emit())
	row.add_child(_retry_btn)

	_menu_btn = Button.new()
	_menu_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu_btn.custom_minimum_size = Vector2(0, 44)
	_menu_btn.text = "Diário"
	_menu_btn.pressed.connect(func(): level_select_requested.emit())
	row.add_child(_menu_btn)

func display_result(level_data, summary: Dictionary) -> void:
	if level_data != null:
		_title_lbl.text = "%s Concluído!" % level_data.title
		_story_lbl.text = "\"%s\"" % level_data.story_outro
	
	var stars: int = int(summary.get("stars", 1))
	var stars_text := ""
	for i in range(3):
		stars_text += "★" if i < stars else "☆"
	_stars_lbl.text = stars_text
	
	var hits: int = int(summary.get("first_try_hits", 0))
	var trips: int = int(summary.get("trips", 0))
	var elapsed: float = float(summary.get("elapsed_sec", 0.0))
	_stats_lbl.text = "Acertos de 1ª: %d\nTropeços: %d  •  Tempo: %.1fs" % [hits, trips, elapsed]
	
	var has_next: bool = bool(summary.get("has_next_level", false))
	_next_btn.visible = has_next
	if _portrait != null and _portrait.has_method("on_victory"):
		_portrait.on_victory()
