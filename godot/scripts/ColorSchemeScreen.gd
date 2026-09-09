extends Control
## Tela de configuração da paleta: escolhe o esquema e, no "personalizado",
## abre o modal de edição por nota. Alvos grandes e lista vertical -- picker
## miúdo é hostil pra baixa visão, que é o público do jogo.
##
## Monta a UI em código, como GameHUD.gd já faz, em vez de depender de caminhos
## de nó dentro do .tscn.

signal closed

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const ModalScript := preload("res://scripts/NoteColorModal.gd")

const SWATCH_MIN := Vector2(56, 56)  # acima do mínimo de 44pt recomendado
const CUSTOM_LABEL := "Personalizado"

class Row:
	var swatch: ColorRect
	var label: Label
	var button: Button

var _rows: Array[Row] = []
var _scheme_opt: OptionButton
var _note_list: VBoxContainer
var _reset_btn: Button
var _close_btn: Button
var _modal: Control

func _ready() -> void:
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Fundo opaco: a tela cobre o jogo, e um fundo translúcido deixaria o
	# cenário competir com os swatches -- justamente o que não pode acontecer
	# numa tela cujo assunto é discriminar cor.
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	for lado in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(lado, 16)
	bg.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	var titulo := Label.new()
	titulo.text = "Cores das notas"
	col.add_child(titulo)

	_scheme_opt = OptionButton.new()
	for id in ColorSchemes.SCHEME_IDS:
		_scheme_opt.add_item(ColorSchemes.display_name(id))
	_scheme_opt.add_item(CUSTOM_LABEL)
	_scheme_opt.item_selected.connect(_on_scheme_selected)
	col.add_child(_scheme_opt)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	_note_list = VBoxContainer.new()
	_note_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_note_list)

	_reset_btn = Button.new()
	_reset_btn.text = "Restaurar tudo ao padrão"
	_reset_btn.pressed.connect(_on_reset_pressed)
	col.add_child(_reset_btn)

	_close_btn = Button.new()
	_close_btn.text = "Fechar"
	_close_btn.pressed.connect(_on_close_pressed)
	col.add_child(_close_btn)

	_build_rows()

	_modal = ModalScript.new()
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)

	ColorSchemeSettings.scheme_changed.connect(_on_scheme_changed)
	_sync_selector()
	_refresh()

func _build_rows() -> void:
	var keys := NoteMapping.NOTES.keys()
	for i in range(keys.size()):
		var row := Row.new()
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)

		row.swatch = ColorRect.new()
		row.swatch.custom_minimum_size = SWATCH_MIN
		line.add_child(row.swatch)

		row.label = Label.new()
		row.label.text = NoteMapping.label_for(keys[i])
		row.label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(row.label)

		row.button = Button.new()
		row.button.text = "Editar"
		row.button.pressed.connect(_on_edit_pressed.bind(i))
		line.add_child(row.button)

		_note_list.add_child(line)
		_rows.append(row)

func _refresh() -> void:
	var keys := NoteMapping.NOTES.keys()
	for i in range(_rows.size()):
		_rows[i].swatch.color = NoteMapping.color_for(keys[i])
	# Só faz sentido editar cor no esquema personalizado.
	var editavel := ColorSchemeSettings.scheme_id == ColorSchemeSettings.CUSTOM_ID
	for row in _rows:
		row.button.disabled = not editavel

func _sync_selector() -> void:
	if ColorSchemeSettings.scheme_id == ColorSchemeSettings.CUSTOM_ID:
		_scheme_opt.select(ColorSchemes.SCHEME_IDS.size())
	else:
		_scheme_opt.select(ColorSchemes.SCHEME_IDS.find(ColorSchemeSettings.scheme_id))

func _on_scheme_changed(_id: String) -> void:
	_refresh()

func _on_scheme_selected(index: int) -> void:
	if index < ColorSchemes.SCHEME_IDS.size():
		ColorSchemeSettings.set_scheme(ColorSchemes.SCHEME_IDS[index])
	else:
		ColorSchemeSettings.set_scheme(ColorSchemeSettings.CUSTOM_ID)
	ColorSchemeSettings.save_to_disk()

func _on_reset_pressed() -> void:
	ColorSchemeSettings.reset_to_defaults()
	ColorSchemeSettings.save_to_disk()
	_sync_selector()

func _on_edit_pressed(chromatic_index: int) -> void:
	_modal.open_for(chromatic_index)

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
