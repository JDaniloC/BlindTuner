extends Control
## Modal narrativo exibido antes do início de uma fase na campanha.
## Apresenta o contexto poético da tarefa cotidiana, o farol sonoro a ser seguido
## e permite ao jogador respirar e se orientar antes da primeira nota.

signal started

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const PORTRAIT_SCENE := preload("res://scenes/CharacterPortrait.tscn")

var _chapter_tag_lbl: Label
var _title_lbl: Label
var _portrait: Control
var _story_lbl: Label
var _beacon_lbl: Label
var _config_lbl: Label
var _start_btn: Button
var _is_closing: bool = false
var _level_data: Resource = null

func _ready() -> void:
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Fundo escurecido semi-transparente
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 520)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(s, 24)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	# Tag do Capítulo
	_chapter_tag_lbl = Label.new()
	_chapter_tag_lbl.text = "CAPÍTULO 1 • MEMÓRIA"
	_chapter_tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_tag_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	col.add_child(_chapter_tag_lbl)

	# Título do Nível
	_title_lbl = Label.new()
	_title_lbl.text = "A Canção de Ninar"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title_lbl)

	# Retrato do Personagem ouvindo atentamente
	var portrait_box := CenterContainer.new()
	col.add_child(portrait_box)
	_portrait = PORTRAIT_SCENE.instantiate()
	portrait_box.add_child(_portrait)
	if _portrait.has_method("set_listening"):
		_portrait.set_listening(true)

	# Texto da História / Tarefa
	_story_lbl = Label.new()
	_story_lbl.text = ""
	_story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_story_lbl)

	# Caixa de Destaque do Farol Sonoro
	var beacon_panel := PanelContainer.new()
	col.add_child(beacon_panel)
	var beacon_margin := MarginContainer.new()
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		beacon_margin.add_theme_constant_override(s, 8)
	beacon_panel.add_child(beacon_margin)

	_beacon_lbl = Label.new()
	_beacon_lbl.text = "👂 Farol Sonoro: Siga o som no ambiente."
	_beacon_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_beacon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_beacon_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	beacon_margin.add_child(_beacon_lbl)

	# Resumo de Pistas & Modo
	_config_lbl = Label.new()
	_config_lbl.text = ""
	_config_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_config_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	col.add_child(_config_lbl)

	# Botão de Início
	_start_btn = Button.new()
	_start_btn.custom_minimum_size = Vector2(0, 48)
	_start_btn.text = "Começar a Ouvir"
	_start_btn.pressed.connect(_on_start_pressed)
	col.add_child(_start_btn)
	_start_btn.grab_focus()

	# Dica de tecla rápida
	var hint_lbl := Label.new()
	hint_lbl.text = "(Toque ou pressione Espaço / Enter)"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	col.add_child(hint_lbl)

	if _level_data != null:
		_apply_data(_level_data)

## Preenche os campos do modal com as informações do LevelData fornecido.
func setup(level_data: Resource) -> void:
	_level_data = level_data
	if is_inside_tree() and _title_lbl != null:
		_apply_data(_level_data)

func _apply_data(data: Resource) -> void:
	var ch: int = int(data.get("chapter"))
	var num: int = int(data.get("level_number"))
	_chapter_tag_lbl.text = "CAPÍTULO %d • FASE %d.%d" % [ch, ch, num]
	_title_lbl.text = str(data.get("title"))
	_story_lbl.text = str(data.get("story_intro"))

	var hint: String = str(data.get("beacon_hint"))
	if hint.is_empty():
		hint = "Siga o som guia no espaço para alcançar o objetivo."
	_beacon_lbl.text = "👂 Farol Sonoro: %s" % hint

	var cue_lvl: int = int(data.get("default_cue_level"))
	var cue_desc := "Pistas: Todas ativas"
	match cue_lvl:
		1: cue_desc = "Pistas: Nomes ocultos (Freq + Cor)"
		2: cue_desc = "Pistas: Somente Cor"
		3: cue_desc = "Pistas: Somente Audição"

	var mode_val: int = int(data.get("default_input_mode"))
	var mode_desc := "Modo: Joystick"
	match mode_val:
		1: mode_desc = "Modo: Piano Virtual"
		2: mode_desc = "Modo: Scroll de Afinação"

	_config_lbl.text = "%s  •  %s" % [cue_desc, mode_desc]

func _unhandled_input(event: InputEvent) -> void:
	if _is_closing:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select") or event.is_action_pressed("ui_cancel"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if _is_closing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_start_pressed()
		accept_event()

func _on_start_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	started.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	tw.finished.connect(queue_free)
