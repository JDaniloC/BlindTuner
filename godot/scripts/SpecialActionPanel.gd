extends Control
## Painel das 4 ações especiais (Gs4=interagir, A4=pegar, As4=correr, B4=pular).
## Emite o mesmo sinal note_triggered do DirectionJoystick — Playground roteia.

signal note_triggered(note_key: String)

const ACTION_NOTES := ["Gs4", "A4", "As4", "B4"]
## Subiu de 96: o joystick desenhava um disco de 347px ao lado de placas de 96,
## quase o dobro em cada eixo e 3,6x em área. O disco encolheu pra 308 (era aro
## sobrando, não área de toque), e as placas sobem pra 116 -- a proporção fecha
## de 1,74x pra 1,28x vindo dos dois lados, e alvo de toque maior é ganho direto
## pro público. A caixa que hospeda o painel em Playground.tscn tem que subir
## junto (2*116 + 8 de separação = 240): custom_minimum_size perde pros offsets
## da cena quando o Control é filho de CanvasLayer, e o desenho cresceria sem o
## toque crescer.
const BUTTON_SIZE := Vector2(116, 116)
## Aparência com o interruptor de pistas desligado. Espelha DirectionJoystick.NEUTRAL_SLICE.
const NEUTRAL_BUTTON := Color(0.55, 0.55, 0.58)
const ARMED_BRIGHTNESS := 1.6  # multiplicador da cor da placa quando a ação está armada
const CORNER_RADIUS := 8
## Faixa reservada ao glifo e respiro até o nome. O ActionIcon desenha o glifo
## centrado no próprio rect a ICON_FRAC do menor lado, então esta altura é que
## define o tamanho do símbolo (44 * 0.7 = ~31px).
const ICON_MIN_HEIGHT := 44.0
const ICON_TEXT_GAP := 8
## Espessura do anel de foco. Mesma escala do piano (a placa tem 116px de lado; o
## botão do HUD tem ~64 de altura e usa 3). O teto é a folga até o desenho: o
## glifo começa a 26,6px do topo e o nome termina a 21px da base, então o anel só
## encostaria em algum dos dois a partir de ~21px.
const FOCUS_RING_PX := 4
const ActionIconScript := preload("res://scripts/ActionIcon.gd")
# ColorDistance é RefCounted, não autoload -- precisa de preload pra ser usado.
const ColorDistance := preload("res://scripts/ColorDistance.gd")

var _buttons: Array[Button] = []
var _button_notes: Array[String] = []
# Paralelo a _buttons -- guardado para poder retingir o glifo a cada _apply_cue().
var _icons: Array[Control] = []
# Paralelo a _buttons -- o nome da nota saiu do Button.text para uma Label
# dentro da VBox, que é o que permite centrar glifo e nome como um grupo.
var _labels: Array[Label] = []
# Paralelo a _buttons; true quando o flag correspondente está armado no Character.
# Atualizado por on_armed_state_changed (conectado pelo Playground).
var _armed: Array[bool] = [false, false, false, false]
var _active_tweens: Array = [null, null, null, null]

func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	for note_key in ACTION_NOTES:
		var btn := Button.new()
		btn.custom_minimum_size = BUTTON_SIZE
		btn.pivot_offset = BUTTON_SIZE * 0.5
		btn.pressed.connect(_emit_note.bind(note_key))
		grid.add_child(btn)
		# Glifo e nome vivem numa VBox que os trata como UM grupo: ela centra o
		# par verticalmente e dá o respiro entre eles pela constante de
		# separação. Antes o ícone era ancorado na faixa de cima do botão e o
		# nome era o text do próprio Button -- que o Godot centra no botão
		# INTEIRO, então o glifo terminava onde o nome começava, sem respiro, e
		# o conjunto ficava alto. Fazer isso na mão exigiria medir a fonte.
		var box := VBoxContainer.new()
		box.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", ICON_TEXT_GAP)
		# Sem isto a VBox engole o clique e os 4 botões param de responder.
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(box)

		var icon := ActionIconScript.new()
		icon.custom_minimum_size = Vector2(0, ICON_MIN_HEIGHT)
		box.add_child(icon)
		icon.set_action(NoteMapping.action_id_for(note_key))

		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lbl)

		_buttons.append(btn)
		_button_notes.append(note_key)
		_icons.append(icon)
		_labels.append(lbl)
	# Repinta na troca de esquema de cor, sem precisar reiniciar a fase.
	ColorSchemeSettings.scheme_changed.connect(_on_scheme_changed)
	# Quem manda nas pistas DO CONTROLE é o interruptor, não o nível de pista --
	# e este painel não escutava nada disso antes: só se repintava porque o
	# nível de pista mudava. Sem esta conexão, virar o interruptor não teria
	# efeito nenhum nas 4 placas até a fase reiniciar.
	ColorSchemeSettings.control_cues_changed.connect(_on_control_cues_changed)
	_apply_cue()

func _emit_note(note_key: String) -> void:
	note_triggered.emit(note_key)
	var idx := ACTION_NOTES.find(note_key)
	if idx == 0 or idx == 1:
		_pulse_action_button(idx, 2.5)

func _pulse_action_button(idx: int, duration: float) -> void:
	if idx < 0 or idx >= _buttons.size():
		return
	var btn := _buttons[idx]
	if _active_tweens[idx] != null and _active_tweens[idx].is_valid():
		_active_tweens[idx].kill()
	var tw := create_tween()
	_active_tweens[idx] = tw
	tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(duration - 0.45)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_SINE)

func _on_scheme_changed(_id: String) -> void:
	_apply_cue()

func _on_control_cues_changed(_enabled: bool) -> void:
	_apply_cue()

func _apply_cue() -> void:
	# Cor e nome são a MESMA condição: um interruptor único, que NÃO é o nível
	# de pista. Aquele governa o que o HUD conta sobre a nota tocada (é a
	# dificuldade); as placas são material didático permanente e continuam
	# coloridas e nomeadas no "só som" se o jogador quiser.
	var show_cues := ColorSchemeSettings.shows_control_cues()
	for i in range(_buttons.size()):
		var note_key := _button_notes[i]
		_labels[i].text = NoteMapping.label_for(note_key) if show_cues else ""
		# Escondida (não só vazia) para a VBox não reservar a altura da linha:
		# assim, sem o nome, o glifo fica centrado sozinho em vez de alto.
		_labels[i].visible = show_cues
		var base_color: Color = NoteMapping.color_for(note_key) if show_cues else NEUTRAL_BUTTON
		if _armed[i]:
			base_color = armed_shade(base_color)
		# A cor vai no fundo da placa, não no modulate: modulate se PROPAGA pros
		# filhos, e o ícone é filho do botão -- tingir por modulate deixava o
		# glifo exatamente da cor do fundo, ou seja, invisível. Mesma receita já
		# usada no PianoInput.
		var sb := StyleBoxFlat.new()
		sb.bg_color = base_color
		sb.corner_radius_top_left = CORNER_RADIUS
		sb.corner_radius_top_right = CORNER_RADIUS
		sb.corner_radius_bottom_left = CORNER_RADIUS
		sb.corner_radius_bottom_right = CORNER_RADIUS
		_buttons[i].add_theme_stylebox_override("normal", sb)
		_buttons[i].add_theme_stylebox_override("hover", sb)
		# Rede, não recurso: nada desabilita uma placa hoje. Sem o override, uma
		# placa desabilitada cairia na caixa cinza escura do tema padrão do Godot
		# com a tinta calculada pra cor da NOTA -- 1,00:1.
		_buttons[i].add_theme_stylebox_override("disabled", sb)
		# "pressed" ganha o mesmo desenho com o fundo deslocado, pra apertar o
		# botão mudar alguma coisa visualmente.
		#
		# O deslocamento AFASTA o fundo da tinta em vez de escurecer sempre: a
		# tinta é decidida uma vez, sobre a cor de REPOUSO, e escurecer uma placa
		# de tinta escura aproximava as duas -- a placa Sol# caía a 4,20:1
		# justamente com o dedo em cima. A regra mora em ColorDistance.
		var pressed_sb := StyleBoxFlat.new()
		pressed_sb.bg_color = ColorDistance.pressed_shade_for(base_color)
		pressed_sb.corner_radius_top_left = CORNER_RADIUS
		pressed_sb.corner_radius_top_right = CORNER_RADIUS
		pressed_sb.corner_radius_bottom_left = CORNER_RADIUS
		pressed_sb.corner_radius_bottom_right = CORNER_RADIUS
		_buttons[i].add_theme_stylebox_override("pressed", pressed_sb)
		_buttons[i].modulate = Color.WHITE  # neutro: qualquer cor aqui tingiria o ícone junto
		# Glifo e NOME da nota recebem a MESMA tinta: é a mesma decisão ("tinta
		# escura em placa clara e vice-versa"), e duas tintas diferentes na mesma
		# placa leriam como dois elementos distintos.
		#
		# Sem isto o nome ficava no cinza claro do tema padrão do Godot sobre a
		# cor da nota: medido no esquema Pedagógico (o de fábrica), 1,25:1 no Si e
		# 1,36:1 no Lá -- ilegível. Levar a cor da placa pro bg_color da
		# StyleBoxFlat pinta o FUNDO e não mexe no rótulo; enquanto ela vinha do
		# modulate, o rótulo era tingido junto e por acidente dava 4,9 a 8,5:1.
		var ink := ColorDistance.icon_tint_for(base_color)
		# A Label não está sob blindtuner_theme.tres (este painel é irmão do
		# GameHUD na CanvasLayer, não filho), então sem override ela herda o
		# cinza claro do tema padrão do Godot sobre a cor da nota -- medido em
		# 1,25:1 no Si e 1,36:1 no Lá, ilegível. Uma Label tem um único estado
		# de cor, ao contrário do Button, que ainda clareia no hover/pressed.
		_labels[i].add_theme_color_override("font_color", ink)
		# Contorno na tinta OPOSTA, pela mesma razão do piano: a cor da nota
		# responde por distinguir a nota das outras 11, não por contrastar com o
		# rótulo, e existe meio-tom em que nenhuma das duas tintas chega aos
		# 4,5:1 de texto. Com o halo, o que fica encostado na letra é ele --
		# 17,4:1 contra a tinta em qualquer placa e qualquer estado, inclusive
		# armada (bg x1,6) e apertada.
		_labels[i].add_theme_color_override("font_outline_color", ColorDistance.outline_tint_for(base_color))
		# ...mas SÓ onde ele é necessário: numa placa clara e saturada a franja
		# branca em volta da letra escura engorda o traço e lê como adesivo. A
		# regra decide por placa, testando repouso e apertado.
		_labels[i].add_theme_constant_override("outline_size", ColorDistance.text_outline_px_for(base_color))
		_icons[i].set_tint(ink)
		# Anel de foco DESENHADO AQUI, e não herdado. Este painel é irmão do
		# GameHUD na CanvasLayer, logo não vê blindtuner_theme.tres, e sem override
		# as 4 placas caíam no `focus` do tema padrão do Godot -- uma borda #CCCCCC
		# de 2px, feita pra skin escura. É o mesmo defeito medido nas teclas do
		# piano (1,28:1 sobre a tecla branca, 1,37:1 sobre o amarelo do Mi), contra
		# um piso de 3:1. Nas 4 placas x 3 esquemas x armado/desarmado o anel fica
		# em 3,87:1 no pior caso (o Lá# armado do Clássico) e 5,24:1 na placa
		# neutra, que é o que o interruptor de pistas desligado mostra.
		#
		# E o foco não é transitório num aparelho de toque: com
		# emulate_mouse_from_touch (ligado por padrão) tocar uma placa dá foco a ela
		# e o foco FICA até outro controle tomá-lo. É o indicador de "você está
		# aqui", em estado de repouso.
		#
		# A cor é a MESMA tinta do glifo e do nome, decidida contra a placa em que o
		# anel cai -- inclusive na placa ARMADA, que é outra cor.
		var anel := StyleBoxFlat.new()
		# Miolo transparente: quem pinta o fundo continua sendo a stylebox do
		# estado, e o anel só acrescenta a borda -- é o que garante que ele não
		# tape o glifo nem o nome, que moram no centro da placa.
		anel.draw_center = false
		anel.set_border_width_all(FOCUS_RING_PX)
		anel.border_color = ink
		anel.set_corner_radius_all(CORNER_RADIUS)
		_buttons[i].add_theme_stylebox_override("focus", anel)

## Cor da placa com a ação ARMADA -- clareada, mas dentro do gamut.
##
## O clamp não é zelo. Sem ele o azul #3949AB do Clássico armado virava
## (0,358 / 0,458 / 1,073): a tela pinta o azul em 1,0 e icon_tint_for /
## text_outline_px_for / pressed_shade_for / contrast_ratio calculavam sobre
## 1,073 -- a única superfície do jogo onde a régua e o pixel liam cores
## DIFERENTES. Medido nesse caso: o nome dá 3,70:1 na conta antiga e 3,87:1 no que
## o olho vê. Nas 6 combinações embarcadas (3 esquemas x correr e pular) a cor
## armada estourava o gamut e NENHUMA decisão de tinta ou de halo vira com o
## clamp -- todas elas é que estavam sendo tomadas sobre uma cor não pintada.
##
## Espelha PianoInput.armed_shade(): as duas superfícies armam as mesmas duas
## notas (correr/pular) e têm que clarear igual.
static func armed_shade(base: Color) -> Color:
	return Color(minf(base.r * ARMED_BRIGHTNESS, 1.0),
		minf(base.g * ARMED_BRIGHTNESS, 1.0),
		minf(base.b * ARMED_BRIGHTNESS, 1.0), base.a)

## Conectado pelo Playground ao sinal armed_state_changed do Character.
## Atualiza brilho dos botões correspondentes a correr (índice 2) e pular (índice 3).
func on_armed_state_changed(running: bool, jumping: bool) -> void:
	_armed[2] = running
	_armed[3] = jumping
	_apply_cue()
