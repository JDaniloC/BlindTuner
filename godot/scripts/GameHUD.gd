extends Control
## HUD do loop: seletor de preset + nível de pista, progresso, painel de stats.

signal start_requested(preset_id: String, cue_level: int, input_mode: int)
signal restart_requested
signal color_settings_requested
## A barra do topo mudou de altura. Quem desenha logo abaixo dela (o NotePanel
## do Playground) precisa se reposicionar: a altura depende do número de linhas
## de controle e do tamanho da fonte, que sobe por acessibilidade.
signal top_bar_resized

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const PLAY_ICON := preload("res://assets/ui/flat/UI_Flat_ButtonPlay01a.png")

var _top_panel: PanelContainer
var _preset_opt: OptionButton
var _cue_opt: OptionButton
var _mode_opt: OptionButton
var _start_btn: Button
var _color_btn: Button
var _paint_btn: Button
var _progress: Label
var _stats_panel: PanelContainer
var _stats_label: Label

func _ready() -> void:
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_top_panel = PanelContainer.new()
	_top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_panel.resized.connect(func(): top_bar_resized.emit())
	add_child(_top_panel)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 16)
	top_margin.add_theme_constant_override("margin_top", 16)
	top_margin.add_theme_constant_override("margin_right", 16)
	top_margin.add_theme_constant_override("margin_bottom", 16)
	_top_panel.add_child(top_margin)

	var top_vbox := VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 8)
	top_margin.add_child(top_vbox)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	top_vbox.add_child(row)

	_preset_opt = OptionButton.new()
	for p in SequencePresets.ALL:
		_preset_opt.add_item(p.label)
	row.add_child(_preset_opt)

	_cue_opt = OptionButton.new()
	for lvl in ["Pista 0 (tudo)", "Pista 1 (freq+cor)", "Pista 2 (só cor)", "Pista 3 (só som)"]:
		_cue_opt.add_item(lvl)
	row.add_child(_cue_opt)

	_mode_opt = OptionButton.new()
	for m in ["Joystick", "Piano Virtual", "Scroll de Afinação"]:
		_mode_opt.add_item(m)
	row.add_child(_mode_opt)

	_start_btn = Button.new()
	_start_btn.text = "Começar"
	_start_btn.icon = PLAY_ICON
	_start_btn.pressed.connect(_on_start_pressed)
	row.add_child(_start_btn)

	# "Cores" vai para a segunda linha: enfiado na primeira, os 5 controles
	# deixavam 7px de folga em 720px de largura -- qualquer rótulo um pouco
	# maior (ou uma fonte maior por acessibilidade) já transbordaria.
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	top_vbox.add_child(row2)

	_color_btn = Button.new()
	_color_btn.text = "Cores"
	_color_btn.pressed.connect(_on_color_pressed)
	row2.add_child(_color_btn)

	# Vai na SEGUNDA linha, e antes do _progress: uma terceira linha levaria a
	# barra do topo a 197px e cobriria 57 dos 82px do NotePanel, e o _progress
	# tem SIZE_EXPAND_FILL -- inserido depois dele, o botão seria empurrado
	# contra a borda da tela.
	_paint_btn = Button.new()
	_paint_btn.toggle_mode = true
	# button_pressed antes de conectar: o setter emite `toggled`, e conectar
	# primeiro faria o HUD gravar em disco só por ter nascido.
	_paint_btn.button_pressed = ColorSchemeSettings.paints_piano_keys()
	_paint_btn.text = "Piano colorido"
	_paint_btn.toggled.connect(_on_paint_toggled)
	row2.add_child(_paint_btn)

	_progress = Label.new()
	_progress.text = "—"
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(_progress)

	var stats_center := CenterContainer.new()
	stats_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats_center)

	_stats_panel = PanelContainer.new()
	_stats_panel.visible = false
	stats_center.add_child(_stats_panel)
	var col := VBoxContainer.new()
	_stats_panel.add_child(col)
	_stats_label = Label.new()
	col.add_child(_stats_label)
	var again := Button.new()
	again.text = "Repetir"
	again.pressed.connect(_on_restart_pressed)
	col.add_child(again)

## Altura ocupada pela barra do topo, medida (não estimada): é o que separa o
## HUD de quem desenha logo abaixo dele.
func top_bar_height() -> float:
	return _top_panel.size.y if _top_panel != null else 0.0

func _on_start_pressed() -> void:
	if _preset_opt.selected < 0 or _preset_opt.selected >= SequencePresets.ALL.size():
		return
	var pid: String = SequencePresets.ALL[_preset_opt.selected].id
	start_requested.emit(pid, _cue_opt.selected, _mode_opt.selected)

func _on_color_pressed() -> void:
	color_settings_requested.emit()

## Grava na hora: é ajuste de acessibilidade, feito uma vez, e o jogador não tem
## por que passar pela tela de Cores só para ele sobreviver ao próximo boot.
func _on_paint_toggled(enabled: bool) -> void:
	ColorSchemeSettings.set_paints_piano(enabled)
	ColorSchemeSettings.save_to_disk()

func _on_restart_pressed() -> void:
	restart_requested.emit()

func set_progress(index: int, total: int) -> void:
	_progress.text = "Nota %d / %d" % [index, total]

func show_stats(stats: Dictionary) -> void:
	_stats_label.text = "Acertos de 1ª: %d\nErros: %d\nTempo: %.1f s" % [
		stats.first_try_hits, stats.total_trips, stats.elapsed_sec]
	_stats_panel.visible = true

func hide_stats() -> void:
	_stats_panel.visible = false
