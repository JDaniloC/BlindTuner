extends Control
## HUD do loop: seletor de preset + nível de pista, progresso, painel de stats.

signal start_requested(preset_id: String, cue_level: int)
signal restart_requested

var _preset_opt: OptionButton
var _cue_opt: OptionButton
var _start_btn: Button
var _progress: Label
var _stats_panel: PanelContainer
var _stats_label: Label

func _ready() -> void:
	var top := HBoxContainer.new()
	top.position = Vector2(16, 16)
	add_child(top)

	_preset_opt = OptionButton.new()
	for p in SequencePresets.ALL:
		_preset_opt.add_item(p.label)
	top.add_child(_preset_opt)

	_cue_opt = OptionButton.new()
	for lvl in ["Pista 0 (tudo)", "Pista 1 (freq+cor)", "Pista 2 (só cor)", "Pista 3 (só som)"]:
		_cue_opt.add_item(lvl)
	top.add_child(_cue_opt)

	_start_btn = Button.new()
	_start_btn.text = "Começar"
	_start_btn.pressed.connect(_on_start_pressed)
	top.add_child(_start_btn)

	_progress = Label.new()
	_progress.position = Vector2(16, 56)
	_progress.text = "—"
	add_child(_progress)

	_stats_panel = PanelContainer.new()
	_stats_panel.position = Vector2(16, 88)
	_stats_panel.visible = false
	add_child(_stats_panel)
	var col := VBoxContainer.new()
	_stats_panel.add_child(col)
	_stats_label = Label.new()
	col.add_child(_stats_label)
	var again := Button.new()
	again.text = "Repetir"
	again.pressed.connect(_on_restart_pressed)
	col.add_child(again)

func _on_start_pressed() -> void:
	if _preset_opt.selected < 0 or _preset_opt.selected >= SequencePresets.ALL.size():
		return
	var pid: String = SequencePresets.ALL[_preset_opt.selected].id
	start_requested.emit(pid, _cue_opt.selected)

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
