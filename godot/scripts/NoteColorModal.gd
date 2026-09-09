extends Control
## Edição de UMA cor, em tela cheia. Slider de matiz grande em vez de roda de
## cor miúda -- roda pequena é hostil pra baixa visão e pra motricidade reduzida.
##
## Monta a UI em código, como GameHUD.gd já faz.

signal color_confirmed(chromatic_index: int, color: Color)

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const ColorDistance := preload("res://scripts/ColorDistance.gd")
const PREVIEW_MIN := Vector2(160, 120)
const SLIDER_MIN := Vector2(0, 48)  # alvo de arrasto alto, não um fio de 8px

var _index: int = -1
var _pending: Color = Color.WHITE

var _title: Label
var _preview: ColorRect
var _hue: HSlider
var _warning: PanelContainer
var _warning_label: Label
var _auto_btn: Button
var _confirm_btn: Button
var _cancel_btn: Button

func _ready() -> void:
	theme = UI_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	for lado in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(lado, 20)
	bg.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	_title = Label.new()
	col.add_child(_title)

	_preview = ColorRect.new()
	_preview.custom_minimum_size = PREVIEW_MIN
	col.add_child(_preview)

	_hue = HSlider.new()
	_hue.min_value = 0.0
	_hue.max_value = 360.0
	_hue.step = 1.0
	_hue.custom_minimum_size = SLIDER_MIN
	_hue.value_changed.connect(_on_hue_changed)
	col.add_child(_hue)

	_warning = PanelContainer.new()
	_warning.visible = false
	col.add_child(_warning)
	var wcol := VBoxContainer.new()
	wcol.add_theme_constant_override("separation", 8)
	_warning.add_child(wcol)
	_warning_label = Label.new()
	_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wcol.add_child(_warning_label)
	_auto_btn = Button.new()
	_auto_btn.text = "Ajustar automaticamente"
	_auto_btn.pressed.connect(_on_auto_adjust_pressed)
	wcol.add_child(_auto_btn)

	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 12)
	col.add_child(botoes)
	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirmar"
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	botoes.add_child(_confirm_btn)
	_cancel_btn = Button.new()
	_cancel_btn.text = "Cancelar"
	_cancel_btn.pressed.connect(_on_cancel_pressed)
	botoes.add_child(_cancel_btn)

	visible = false

func open_for(chromatic_index: int) -> void:
	_index = chromatic_index
	var key := NoteMapping.note_key_at(chromatic_index)
	if key == "":
		_title.text = "Cor"
	else:
		_title.text = "Cor de %s" % NoteMapping.label_for(key)
	_set_pending(NoteMapping.color_for(key))
	_hue.set_value_no_signal(_pending.h * 360.0)
	visible = true

func _on_hue_changed(value: float) -> void:
	# Mexe só no matiz: alterar a luminância quebraria a regra altura<->luminosidade
	# que organiza a paleta inteira.
	_set_pending(Color.from_hsv(value / 360.0, _pending.s, _pending.v, 1.0))

func _set_pending(c: Color) -> void:
	_pending = c
	_preview.color = c
	_refresh_warning()

## Aviso não-bloqueante: mostra COM QUAL nota a cor escolhida se parece e
## oferece o atalho, mas nunca impede confirmar -- autonomia do jogador vem
## antes da "correção" do sistema.
func _refresh_warning() -> void:
	var palette := ColorSchemeSettings.custom_colors()
	var conflitos := ColorDistance.conflicts_for(_pending, palette, _index)
	if conflitos.is_empty():
		_warning.visible = false
		return
	var nomes := []
	for idx in conflitos:
		nomes.append(NoteMapping.label_for(NoteMapping.note_key_at(idx)))
	_warning_label.text = "Essa cor está parecida com a de %s" % ", ".join(nomes)
	_warning.visible = true

func _on_auto_adjust_pressed() -> void:
	var palette := ColorSchemeSettings.custom_colors()
	_set_pending(ColorDistance.suggest_adjustment(_pending, palette, _index))
	_hue.set_value_no_signal(_pending.h * 360.0)

func _on_confirm_pressed() -> void:
	ColorSchemeSettings.set_custom_color(_index, _pending)
	ColorSchemeSettings.save_to_disk()
	color_confirmed.emit(_index, _pending)
	visible = false

func _on_cancel_pressed() -> void:
	visible = false
