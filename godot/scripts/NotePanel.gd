extends PanelContainer
## HUD da última nota. Visibilidade dos elementos segue CueSettings.

signal replay_cue_requested

## ColorDistance é RefCounted, não autoload -- precisa de preload pra ser usado.
const ColorDistance := preload("res://scripts/ColorDistance.gd")

@onready var _label: Label = $Margin/HBox/Label
@onready var _freq: Label = $Margin/HBox/Freq
@onready var _guide_lbl: Label = $Margin/HBox/Guide
@onready var _chip_frame: PanelContainer = $Margin/HBox/ChipFrame
@onready var _color_chip: ColorRect = $Margin/HBox/ChipFrame/ColorChip
@onready var _replay_btn: Button = $Margin/HBox/ReplayBtn

## Espessura da moldura em volta do chip, em px de cada lado.
##
## Por que o chip precisa de moldura: na pista 2 ele é o ÚNICO portador de
## informação da tela -- _apply_cue() esconde nome e frequência -- e sem moldura
## ele some dentro do painel. Medido contra o miolo do painel (#ADB7C4, luminância
## WCAG 0,4674), 28 das 36 combinações nota x esquema ficam abaixo dos 3:1 do WCAG
## 1.4.11 para elemento gráfico -- 8 das 12 do Clássico, 11 das 12 do Pedagógico,
## 9 das 12 do Alto Contraste, que é o esquema que existe PARA baixa visão. As
## piores: Ré do Clássico (#FF9800) e Ré# do Pedagógico (#F8AD00) em 1,06:1, Sol
## do Alto Contraste (#E29E18) em 1,13:1. Com a moldura, a borda do quadrado fica
## em 8,58:1 contra o painel, seja qual for a nota.
##
## É a terceira vez que o projeto esbarra neste modo de falha, e a saída é a
## mesma das outras duas: a moldura escura dos swatches em ColorSchemeScreen e a
## TAPE_EDGE das fitinhas em PitchScrollInput. Mexer na COR do chip está fora de
## questão -- ela é o código de cores que o piano, o joystick e o braço usam para
## a MESMA nota, o sistema didático inteiro do jogo.
##
## Não confundir com o halo do NOME da nota, que deixou de ser padrão: contorno
## em volta de LETRA engorda o traço e lê como adesivo. Moldura em volta de
## AMOSTRA DE COR é o que qualquer paleta de tinta tem, e é o que diz onde o
## quadrado começa e termina.
##
## 3px de cada lado, como os swatches da tela de esquemas. O miolo colorido
## continua com os 28px autorados, porque a moldura cresce PARA FORA: a área de
## cor é a informação, não pode encolher para pagar a borda.
const CHIP_BORDER_PX := 3

## Miolo do quadro do tema (UI_Flat_Frame01a.png), lido no pixel central.
##
## Só entra em cena se a textura não puder ser lida. Sem ele, um fundo lido como
## transparente daria luminância zero, a regra de tinta escolheria BRANCO e a
## moldura sairia a 2,03:1 contra o painel claro -- exatamente o buraco que ela
## veio fechar, e em silêncio.
const PANEL_FALLBACK := Color("#ADB7C4")

## Última nota exibida, para repintar o chip quando o esquema de cor muda.
## Sem isso, o chip ficava com a cor do esquema antigo enquanto o controle de
## input já mostrava a nova -- a MESMA nota em duas cores ao mesmo tempo.
var _last_note: String = ""
var _chip_tween: Tween

func _ready() -> void:
	CueSettings.cue_level_changed.connect(_on_cue_changed)
	ColorSchemeSettings.scheme_changed.connect(_on_scheme_changed)
	if _label != null:
		_label.add_theme_color_override("font_color", Color(0.10, 0.08, 0.06))
	if _freq != null:
		_freq.add_theme_color_override("font_color", Color(0.06, 0.16, 0.26))
	if _guide_lbl != null:
		_guide_lbl.add_theme_color_override("font_color", Color(0.28, 0.08, 0.04))
	if _replay_btn != null:
		_replay_btn.pressed.connect(func(): replay_cue_requested.emit())
		_replay_btn.focus_entered.connect(func():
			AccessibleAnnouncer.announce("focus", "Ouvir a nota novamente sem penalidade de tropeço. Botão.")
		)
	_paint_chip_frame()
	_apply_cue()

## A moldura é decidida sobre o fundo do painel, então precisa ser refeita quando
## esse fundo muda -- não basta pintar uma vez no boot.
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_paint_chip_frame()

## Tinta da moldura pelo fundo em que ela CAI (o painel), pela mesma regra das
## outras duas correções. Cor fixa aposta no fundo: se o quadro do tema escurecer
## um dia, esta aqui vira clara sozinha em vez de reabrir o buraco calada.
##
## Decidida contra o PAINEL e não contra o chip, de propósito. Não existe cor
## única que alcance 3:1 dos dois lados: com o chip #0D4A74 sobre o painel
## #ADB7C4, a tinta escura dá 8,58:1 contra o painel e 1,87:1 contra o chip, e a
## clara inverte (2,03:1 contra o painel). Só que um chip escuro assim já se acha
## sozinho contra o painel claro -- 4,60:1 --; quem precisa de ajuda é o chip
## claro, e para esse a moldura escura separa os dois. Ou seja: o que a moldura
## garante é que o QUADRADO INTEIRO é achável contra o painel, e é assim que ele
## deve ser medido -- moldura escura colada em chip escuro é um bloco escuro só,
## e um bloco escuro é exatamente o que se acha num painel claro.
func _paint_chip_frame() -> void:
	var borda := StyleBoxFlat.new()
	borda.bg_color = ColorDistance.icon_tint_for(_panel_backdrop())
	for lado in ["content_margin_left", "content_margin_top", "content_margin_right", "content_margin_bottom"]:
		borda.set(lado, CHIP_BORDER_PX)
	_chip_frame.add_theme_stylebox_override("panel", borda)

## Cor que o painel realmente pinta atrás do chip. StyleBoxTexture é 9-slice: o
## pixel central da textura é o que fica embaixo do chip.
func _panel_backdrop() -> Color:
	var sb: StyleBox = get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		var flat := sb as StyleBoxFlat
		if flat.draw_center and flat.bg_color.a >= 1.0:
			return flat.bg_color
	elif sb is StyleBoxTexture:
		var tex := (sb as StyleBoxTexture).texture
		if tex != null:
			var img := tex.get_image()
			if img != null:
				if img.is_compressed():
					img.decompress()
				var c := img.get_pixel(int(img.get_width() / 2), int(img.get_height() / 2))
				# Fundo translúcido não é fundo: medir a moldura contra ele daria
				# um número que o olho nunca vê.
				if c.a >= 1.0:
					return c * (sb as StyleBoxTexture).modulate_color
	return PANEL_FALLBACK

func _on_cue_changed(_level: int) -> void:
	_apply_cue()

func _on_scheme_changed(_id: String) -> void:
	if _last_note != "":
		_color_chip.color = NoteMapping.color_for(_last_note)

func _apply_cue() -> void:
	visible = CueSettings.cue_level < 3
	_label.visible = CueSettings.shows_name()
	_freq.visible = CueSettings.shows_freq()
	if _guide_lbl != null:
		_guide_lbl.visible = not _guide_lbl.text.is_empty() and (CueSettings.shows_name() or CueSettings.shows_freq())
	# Os dois juntos: esconder só o chip deixaria a moldura sozinha, um quadrado
	# escuro vazio; esconder só a moldura deixaria o chip sem borda de novo.
	_chip_frame.visible = CueSettings.shows_color()
	_color_chip.visible = CueSettings.shows_color()

func display_note(note_key: String) -> void:
	_last_note = note_key
	_label.text = NoteMapping.label_for(note_key)
	_freq.text = "%d Hz" % NoteMapping.frequency_for(note_key)
	_color_chip.color = NoteMapping.color_for(note_key)
	if _chip_frame != null and _chip_frame.visible and is_inside_tree():
		_chip_frame.pivot_offset = _chip_frame.size * 0.5
		if _chip_tween != null and _chip_tween.is_valid():
			_chip_tween.kill()
		_chip_tween = create_tween()
		_chip_tween.tween_property(_chip_frame, "scale", Vector2(1.14, 1.14), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_chip_tween.tween_property(_chip_frame, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)

func display_miss(played_note: String, target_note: String) -> void:
	var played_freq := NoteMapping.frequency_for(played_note)
	var target_freq := NoteMapping.frequency_for(target_note)
	var is_lower := played_freq < target_freq
	
	if _guide_lbl != null:
		_guide_lbl.text = "▲ Suba (Mais agudo)" if is_lower else "▼ Desça (Mais grave)"
		_guide_lbl.visible = CueSettings.shows_name() or CueSettings.shows_freq()
	
	var dir_speech := "mais aguda" if is_lower else "mais grave"
	AccessibleAnnouncer.announce("miss", "Nota %s tocada. A afinação correta é %s." % [
		NoteMapping.label_for(played_note), dir_speech
	])

func clear_guide() -> void:
	if _guide_lbl != null:
		_guide_lbl.text = ""
		_guide_lbl.visible = false
