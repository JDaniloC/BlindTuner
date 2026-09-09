extends Control
## Edição de UMA cor, em tela cheia. Slider de matiz grande em vez de roda de
## cor miúda -- roda pequena é hostil pra baixa visão e pra motricidade reduzida.
##
## Monta a UI em código, como GameHUD.gd já faz.

signal color_confirmed(chromatic_index: int, color: Color)

const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")
const ColorDistance := preload("res://scripts/ColorDistance.gd")

const PREVIEW_MIN := Vector2(160, 140)
## Altura do trilho do slider. O padrão do tema desenha um fio de ~8px com
## pegador de 16x16 -- alvo pequeno demais para o público do jogo, que tem
## baixa visão e pode ter motricidade reduzida.
const SLIDER_TRACK_H := 56
const GRABBER_PX := 44
const BORDER := Color(0.12, 0.10, 0.09)
const BORDER_PX := 3
const WARNING_BG := Color(0.32, 0.24, 0.06)
## O Label do aviso herdava a fonte escura do tema (0.16, 0.13, 0.10) sobre o
## oliva escuro do painel: 1,53:1, abaixo até do piso de 3:1 de texto grande. É
## a única frase que explica POR QUE o aviso apareceu, num jogo para baixa visão.
const WARNING_TEXT := Color(0.98, 0.97, 0.94)

## ΔE de piora a partir do qual um conflito que já existia passa a ser culpa do
## jogador. Abaixo do JND (~2,3) a diferença nem é perceptível, então acusá-lo
## seria ruído.
const AGRAVO_MIN := 2.0

var _index: int = -1
var _pending: Color = Color.WHITE
## ΔE dos conflitos que a cor ORIGINAL desta nota já tinha, medidos na abertura.
## O aviso só fala dos conflitos que o jogador criou ou agravou: as paletas
## embarcadas têm pares abaixo de MIN_DELTA_E de propósito (o Alto Contraste
## repete matiz entre natural e sustenido em 8 das 12 notas), e acusá-lo por
## eles é culpar o jogador por um conflito que veio de fábrica.
var _baseline_conflicts: Dictionary = {}
var _warning_dismissed := false

var _title: Label
var _preview: ColorRect
var _hue: HSlider
var _warning: PanelContainer
var _warning_label: Label
var _auto_btn: Button
var _keep_btn: Button
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

	# Moldura escura em volta do preview, igual à dos swatches da lista: sem ela
	# as cores claras da paleta somem contra um fundo claro e não dá pra ver
	# onde o quadrado começa.
	var moldura := PanelContainer.new()
	var borda := StyleBoxFlat.new()
	borda.bg_color = BORDER
	for lado in ["content_margin_left", "content_margin_top", "content_margin_right", "content_margin_bottom"]:
		borda.set(lado, BORDER_PX)
	moldura.add_theme_stylebox_override("panel", borda)
	moldura.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(moldura)

	_preview = ColorRect.new()
	_preview.custom_minimum_size = PREVIEW_MIN
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	moldura.add_child(_preview)

	_hue = HSlider.new()
	_hue.min_value = 0.0
	_hue.max_value = 360.0
	_hue.step = 1.0
	_hue.custom_minimum_size = Vector2(0, SLIDER_TRACK_H + 8)
	_hue.add_theme_stylebox_override("slider", _make_hue_track())
	# O tema do projeto não define HSlider, então "grabber_area" vem do tema
	# padrão da engine: uma camada clara desenhada POR CIMA do trilho, da borda
	# esquerda até o pegador, que lavava justamente a parte do espectro para onde
	# o jogador arrasta quando quer ir pro vermelho/laranja.
	_hue.add_theme_stylebox_override("grabber_area", StyleBoxEmpty.new())
	_hue.add_theme_stylebox_override("grabber_area_highlight", StyleBoxEmpty.new())
	var grabber := _make_grabber()
	_hue.add_theme_icon_override("grabber", grabber)
	_hue.add_theme_icon_override("grabber_highlight", grabber)
	_hue.value_changed.connect(_on_hue_changed)
	col.add_child(_hue)

	_warning = PanelContainer.new()
	_warning.visible = false
	var wbox := StyleBoxFlat.new()
	wbox.bg_color = WARNING_BG
	for lado in ["content_margin_left", "content_margin_top", "content_margin_right", "content_margin_bottom"]:
		wbox.set(lado, 10)
	_warning.add_theme_stylebox_override("panel", wbox)
	col.add_child(_warning)
	var wcol := VBoxContainer.new()
	wcol.add_theme_constant_override("separation", 8)
	_warning.add_child(wcol)
	_warning_label = Label.new()
	_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning_label.add_theme_color_override("font_color", WARNING_TEXT)
	wcol.add_child(_warning_label)
	var wbtns := HBoxContainer.new()
	wbtns.add_theme_constant_override("separation", 10)
	wcol.add_child(wbtns)
	_auto_btn = Button.new()
	_auto_btn.text = "Ajustar automaticamente"
	_auto_btn.pressed.connect(_on_auto_adjust_pressed)
	wbtns.add_child(_auto_btn)
	# A spec define o aviso como não-bloqueante: precisa existir uma saída que
	# preserve a escolha do jogador, não só a que "corrige" pra ele.
	_keep_btn = Button.new()
	_keep_btn.text = "Manter assim mesmo"
	_keep_btn.pressed.connect(_on_keep_pressed)
	wbtns.add_child(_keep_btn)

	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 12)
	col.add_child(botoes)
	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirmar"
	_confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	botoes.add_child(_confirm_btn)
	_cancel_btn = Button.new()
	_cancel_btn.text = "Cancelar"
	_cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel_btn.pressed.connect(_on_cancel_pressed)
	botoes.add_child(_cancel_btn)

	visible = false

## Trilho com o espectro de matiz desenhado nele -- o jogador vê para onde está
## arrastando, em vez de adivinhar num trilho cinza.
func _make_hue_track() -> StyleBoxTexture:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0 / 6.0, 2.0 / 6.0, 3.0 / 6.0, 4.0 / 6.0, 5.0 / 6.0, 1.0])
	grad.colors = PackedColorArray([
		Color.from_hsv(0.0, 0.85, 0.95), Color.from_hsv(1.0 / 6.0, 0.85, 0.95),
		Color.from_hsv(2.0 / 6.0, 0.85, 0.95), Color.from_hsv(3.0 / 6.0, 0.85, 0.95),
		Color.from_hsv(4.0 / 6.0, 0.85, 0.95), Color.from_hsv(5.0 / 6.0, 0.85, 0.95),
		Color.from_hsv(1.0, 0.85, 0.95),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = SLIDER_TRACK_H
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	return sb

## Pegador circular grande, gerado em código (o projeto não usa asset de imagem
## para UI). O padrão do tema é 16x16, menos da metade do alvo de toque mínimo.
func _make_grabber() -> ImageTexture:
	var img := Image.create(GRABBER_PX, GRABBER_PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var raio := GRABBER_PX * 0.5
	for y in range(GRABBER_PX):
		for x in range(GRABBER_PX):
			var d := Vector2(x - raio + 0.5, y - raio + 0.5).length()
			if d <= raio - 1.0:
				img.set_pixel(x, y, Color(0.98, 0.97, 0.94))
			elif d <= raio:
				img.set_pixel(x, y, BORDER)
	return ImageTexture.create_from_image(img)

func open_for(chromatic_index: int) -> void:
	var key := NoteMapping.note_key_at(chromatic_index)
	if key == "":
		# Índice fora da faixa: não há nota para editar. Antes daqui o código
		# seguia e quebrava ao pedir a cor de uma chave vazia.
		push_warning("NoteColorModal.open_for: índice cromático inválido (%d)" % chromatic_index)
		return
	_index = chromatic_index
	_title.text = "Cor de %s" % NoteMapping.label_for(key)
	_warning_dismissed = false
	var original := NoteMapping.color_for(key)
	_baseline_conflicts = ColorDistance.conflict_distances(
		original, ColorSchemeSettings.active_palette(), _index)
	_set_pending(original, false)
	_hue.set_value_no_signal(_pending.h * 360.0)
	visible = true

func _on_hue_changed(value: float) -> void:
	# Mexe só no matiz: alterar a luminância quebraria a regra altura<->luminosidade
	# que organiza a paleta inteira.
	_set_pending(Color.from_hsv(value / 360.0, _pending.s, _pending.v, 1.0))

func _set_pending(c: Color, from_user: bool = true) -> void:
	_pending = c
	_preview.color = c
	if from_user:
		_warning_dismissed = false
	_refresh_warning()

## Aviso não-bloqueante: mostra COM QUAL nota a cor escolhida se parece e
## oferece o atalho, mas nunca impede confirmar -- autonomia do jogador vem
## antes da "correção" do sistema.
##
## Só entram no aviso os conflitos que o jogador CRIOU ou AGRAVOU. Um flag de
## "já mexeu" não bastava: mexer um grau no slider já acendia o aviso por um
## conflito que a paleta de fábrica trazia desde sempre.
func _refresh_warning() -> void:
	if _warning_dismissed:
		_warning.visible = false
		return
	var palette := ColorSchemeSettings.active_palette()
	var atuais := ColorDistance.conflict_distances(_pending, palette, _index)
	var nomes := []
	for idx in ColorDistance.conflicts_for(_pending, palette, _index):
		var antes: float = _baseline_conflicts.get(idx, INF)
		if atuais[idx] >= antes - AGRAVO_MIN:
			continue
		nomes.append(NoteMapping.label_for(NoteMapping.note_key_at(idx)))
	if nomes.is_empty():
		_warning.visible = false
		return
	_warning_label.text = "Essa cor está parecida com a de %s" % ", ".join(nomes)
	_warning.visible = true

func _on_auto_adjust_pressed() -> void:
	var palette := ColorSchemeSettings.active_palette()
	_set_pending(ColorDistance.suggest_adjustment(_pending, palette, _index))
	_hue.set_value_no_signal(_pending.h * 360.0)

func _on_keep_pressed() -> void:
	_warning_dismissed = true
	_warning.visible = false

func _on_confirm_pressed() -> void:
	ColorSchemeSettings.set_custom_color(_index, _pending)
	ColorSchemeSettings.save_to_disk()
	color_confirmed.emit(_index, _pending)
	visible = false

func _on_cancel_pressed() -> void:
	visible = false
