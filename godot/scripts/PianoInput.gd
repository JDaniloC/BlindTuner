extends Control
## Modo de input "Piano Virtual": teclado real de uma oitava (C4-B4), teclas
## brancas/pretas na posição de um piano de verdade. Emite o mesmo sinal
## note_triggered que DirectionJoystick/SpecialActionPanel/PitchScrollInput.

signal note_triggered(note_key: String)

const WHITE_KEY_WIDTH := 96.0
const WHITE_KEY_HEIGHT := 280.0
const BLACK_KEY_WIDTH := 60.0
const BLACK_KEY_HEIGHT := 175.0
const BLACK_KEY_INDICES := [1, 3, 6, 8, 10]
const WHITE_INDEX_FOR_CHROMATIC := {0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6}
const LEFT_WHITE_FOR_BLACK := {1: 0, 3: 1, 6: 3, 8: 4, 10: 5}
const CORNER_RADIUS := 6
## Este modo de input é irmão do GameHUD na CanvasLayer, logo NÃO herda
## blindtuner_theme.tres: cai no tema padrão do Godot, que é de skin escura e por
## isso pinta o rótulo de quase branco em todos os estados menos o de repouso.
## Os SEIS precisam de override -- `font_disabled_color` entrou junto porque uma
## varredura por estado não tem como saber que ninguém desabilita uma tecla, e
## uma tecla desabilitada com o padrão do Godot fica em 1,00:1.
const BUTTON_FONT_COLORS := ["font_color", "font_hover_color", "font_pressed_color",
	"font_hover_pressed_color", "font_focus_color", "font_disabled_color"]
const ICON_MAX_SIDE := 48.0
const ICON_BOTTOM_MARGIN := 12.0
## Espessura do anel de foco. O tema usa 3 nos botões do HUD; aqui vai 4 porque a
## tecla é muito maior (96x280 contra ~64 de altura no HUD) e um traço de 3px lê
## como serrilhado nessa escala. O teto é a folga até o glifo: o desenho do ícone
## começa a 16,5px da base numa tecla preta (o menor caso das 12), então o anel
## só encostaria nele passando de 16px.
const FOCUS_RING_PX := 4
## ColorDistance é RefCounted, não autoload -- precisa de preload pra ser usado.
const ColorDistance := preload("res://scripts/ColorDistance.gd")
const ARMED_BRIGHTNESS := 1.6  # espelha SpecialActionPanel.ARMED_BRIGHTNESS
const WHITE_KEY_COLOR := Color(0.92, 0.90, 0.85)
const BLACK_KEY_COLOR := Color(0.12, 0.12, 0.14)

var _buttons: Array[Button] = []
var _button_notes: Array[String] = []
var _key_icons: Array[Control] = []
var _key_tweens: Array = []
# Paralelo às notas armáveis (correr/pular); atualizado por on_armed_state_changed.
var _armed: Array[bool] = [false, false, false, false]
var _level_cues_allowed: bool = true

## Índices 1,3,6,8,10 (C#,D#,F#,G#,A#) são as teclas pretas de uma oitava --
## os únicos 5 "buracos" no padrão cromático de 12 semitons (não há preta
## entre E-F nem entre B-C, por isso o piano tem esse desenho assimétrico).
static func is_black_key(chromatic_index: int) -> bool:
	return chromatic_index in BLACK_KEY_INDICES

## Posição X (em px, relativa à borda esquerda do teclado) da tecla, seguindo
## o layout real de um piano de uma oitava. Fórmula padrão: uma tecla preta
## fica centrada no limite entre a tecla branca à sua esquerda e a próxima --
## x = (índice_branco_à_esquerda + 1) * largura_branca - largura_preta/2.
static func key_x_position(chromatic_index: int) -> float:
	if is_black_key(chromatic_index):
		var left_white: int = LEFT_WHITE_FOR_BLACK[chromatic_index]
		return (left_white + 1) * WHITE_KEY_WIDTH - BLACK_KEY_WIDTH / 2.0
	var white_index: int = WHITE_INDEX_FOR_CHROMATIC[chromatic_index]
	return white_index * WHITE_KEY_WIDTH

func _ready() -> void:
	custom_minimum_size = Vector2(7 * WHITE_KEY_WIDTH, WHITE_KEY_HEIGHT)
	var keys := NoteMapping.NOTES.keys()
	for i in range(keys.size()):
		var note_key: String = keys[i]
		var black := is_black_key(i)
		var btn := Button.new()
		btn.position = Vector2(key_x_position(i), 0)
		btn.size = Vector2(BLACK_KEY_WIDTH, BLACK_KEY_HEIGHT) if black else Vector2(WHITE_KEY_WIDTH - 2, WHITE_KEY_HEIGHT)
		btn.pivot_offset = Vector2(btn.size.x * 0.5, 0.0)
		btn.pressed.connect(_emit_note.bind(note_key))
		add_child(btn)
		var icon: Control = load("res://scripts/ActionIcon.gd").new()
		# Proporcional à tecla (com teto): um lado fixo de 24px foi dimensionado
		# pra tecla antiga de 54x160 e deixava o glifo com ~17px numa tecla de
		# 96x280 -- pequeno demais pro público-alvo (baixa visão).
		# branca 94x280 -> lado 47, y=221..268 (dentro de 280);
		# preta  60x175 -> lado 30, y=133..163 (dentro de 175).
		var icon_side: float = minf(btn.size.x * 0.5, ICON_MAX_SIDE)
		icon.custom_minimum_size = Vector2(icon_side, icon_side)
		icon.size = Vector2(icon_side, icon_side)
		# Rodapé da tecla -- não colide com o rótulo de texto, que fica no centro.
		icon.position = Vector2((btn.size.x - icon_side) * 0.5, btn.size.y - icon_side - ICON_BOTTOM_MARGIN)
		btn.add_child(icon)
		icon.set_note(note_key)
		_key_icons.append(icon)
		_buttons.append(btn)
		_button_notes.append(note_key)
		_key_tweens.append(null)
	# Reordena os FILHOS (não os arrays _buttons/_button_notes, que ficam na
	# ordem cromática de NoteMapping) pra que as teclas pretas desenhem por
	# cima das brancas -- igual a um piano de verdade.
	for i in range(keys.size()):
		if is_black_key(i):
			move_child(_buttons[i], -1)

	# Repinta na troca de esquema de cor, sem precisar reiniciar a fase.
	ColorSchemeSettings.scheme_changed.connect(_on_scheme_changed)
	# Sinal separado de propósito: ligar/desligar as pistas não é trocar de
	# paleta, e reaproveitar scheme_changed quebraria o teste que assere os
	# parâmetros daquele sinal.
	ColorSchemeSettings.control_cues_changed.connect(_on_control_cues_changed)
	_apply_cue()
	queue_redraw()

func _draw() -> void:
	var total_w := 7.0 * WHITE_KEY_WIDTH
	# Caixa de mogno escuro + friso de latão + feltro carmesim no topo do teclado
	var bed_rect := Rect2(Vector2(-6.0, -12.0), Vector2(total_w + 12.0, WHITE_KEY_HEIGHT + 18.0))
	draw_rect(bed_rect, Color(0.14, 0.09, 0.06, 0.96))
	draw_rect(bed_rect, Color(0.72, 0.56, 0.32, 0.70), false, 2.0)
	draw_rect(Rect2(Vector2(-2.0, -6.0), Vector2(total_w + 4.0, 6.0)), Color(0.58, 0.12, 0.14, 0.95))

func _emit_note(note_key: String) -> void:
	var idx := _button_notes.find(note_key)
	if idx >= 0 and idx < _buttons.size():
		_animate_key_press(idx)
	note_triggered.emit(note_key)

func _animate_key_press(idx: int) -> void:
	var btn := _buttons[idx]
	if _key_tweens[idx] != null and _key_tweens[idx].is_valid():
		_key_tweens[idx].kill()
	var tw := create_tween()
	_key_tweens[idx] = tw
	tw.tween_property(btn, "scale", Vector2(0.98, 0.96), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_level_cues_allowed(allowed: bool) -> void:
	if _level_cues_allowed == allowed:
		return
	_level_cues_allowed = allowed
	_apply_cue()

func _effective_show_cues() -> bool:
	return ColorSchemeSettings.shows_control_cues() and _level_cues_allowed

func _on_scheme_changed(_id: String) -> void:
	_apply_cue()

func _on_control_cues_changed(_enabled: bool) -> void:
	_apply_cue()

func _apply_cue() -> void:
	# Cor E nome das teclas são o mesmo interruptor, e ele NÃO é o nível de
	# pista: aquele governa o que o HUD conta sobre a nota tocada (a
	# dificuldade), este aqui é material didático permanente sobre o controle.
	# No "só som" com o interruptor ligado o teclado continua colorido e
	# nomeado, de propósito -- o desafio é reconhecer a nota de ouvido, não
	# adivinhar onde ela mora no teclado.
	var show_cues := _effective_show_cues()
	for i in range(_buttons.size()):
		var note_key := _button_notes[i]
		_buttons[i].text = NoteMapping.label_for(note_key) if show_cues else ""
		var armed_idx := _armed_index_for(note_key)
		var is_armed := armed_idx >= 0 and _armed[armed_idx]
		var sb := StyleBoxFlat.new()
		sb.corner_radius_bottom_left = CORNER_RADIUS
		sb.corner_radius_bottom_right = CORNER_RADIUS
		if show_cues:
			# Pistas ligadas: prioriza a cor distintiva por nota (igual
			# aos outros modos de input) sobre o realismo do teclado -- a cor
			# vai direto no fundo da tecla (bg_color). O tint do nó fica neutro
			# (Color.WHITE): tingir o botão multiplicaria também o texto do
			# label, deixando-o quase da mesma cor do fundo (contraste ~1.12,
			# ilegível). E é self_modulate, não modulate: modulate se PROPAGA
			# pros filhos, e o ícone da tecla é filho do botão -- tingir por
			# modulate deixaria o ícone da cor exata do fundo (invisível).
			sb.bg_color = NoteMapping.color_for(note_key)
			if is_armed:
				sb.bg_color = armed_shade(sb.bg_color)
			_buttons[i].self_modulate = Color.WHITE
		else:
			# Pistas desligadas: teclado autêntico, branco e preto pela posição
			# cromática -- inclusive nas 4 notas de ação, que num piano de verdade
			# não teriam cor especial. O que as distingue é o ícone.
			sb.bg_color = _key_base_color(i, note_key)
			if is_armed:
				sb.bg_color = armed_shade(sb.bg_color)
			_buttons[i].self_modulate = Color.WHITE
		# Contraste do ícone: branco fixo sumia na tecla branca (~1.25:1) e
		# nas cores claras da paleta de notas -- todas abaixo do mínimo de
		# 3:1 do WCAG pra elemento gráfico, o que anulava a redundância
		# visual que o ícone existe pra dar. Escolhe o tint pela luminância
		# perceptual (Rec. 709) do fundo efetivo da tecla; como _apply_cue()
		# roda de novo a cada virada do interruptor de pistas, troca de esquema
		# ou de estado armado, o tint acompanha o fundo sozinho. A regra mora em
		# ColorDistance porque o SpecialActionPanel precisa da mesma decisão.
		var bg: Color = sb.bg_color * _buttons[i].self_modulate
		var ink := ColorDistance.icon_tint_for(bg)
		if i < _key_icons.size():
			_key_icons[i].set_tint(ink)
		# O NOME da nota segue a MESMA tinta do glifo, pela mesma razão e com o
		# mesmo defeito por trás: com a cor no bg_color da stylebox (e não no
		# modulate), o rótulo continuava no cinza claro do tema padrão do Godot --
		# ilegível numa tecla branca ou numa cor clara da paleta.
		for nome in BUTTON_FONT_COLORS:
			_buttons[i].add_theme_color_override(nome, ink)
		# Contorno na tinta OPOSTA. A cor da nota é escolhida pra distinguir uma
		# nota das outras 11, não pra contrastar com o rótulo, e nas paletas
		# embarcadas existe meio-tom onde NENHUMA das duas tintas alcança os
		# 4,5:1 de texto (o #009218 do Pedagógico dá 4,10). O halo separa as duas
		# exigências: o que fica encostado na letra passa a ser ele, e ele está a
		# 17,4:1 da tinta em qualquer tecla e em qualquer estado -- inclusive no
		# pressed, que mexe no fundo. Mesma saída que o joystick já usava.
		_buttons[i].add_theme_color_override("font_outline_color", ColorDistance.outline_tint_for(bg))
		# ...mas SÓ onde ele é necessário. Numa tecla clara a franja branca em volta
		# da letra escura engorda o traço e lê como adesivo; a tecla branca
		# autêntica, que já dá 17:1, não tem por que carregar halo nenhum.
		_buttons[i].add_theme_constant_override("outline_size", ColorDistance.text_outline_px_for(bg))
		# Estado "pressed" ganha um stylebox próprio (mesma geometria, fundo
		# deslocado) pra dar feedback visual de toque -- sem isso, apertar
		# uma tecla não mudava nada visualmente (normal/hover/pressed
		# compartilhavam o mesmo StyleBoxFlat).
		#
		# O deslocamento AFASTA o fundo da tinta em vez de escurecer sempre: a
		# tinta é decidida uma vez, sobre a cor de REPOUSO, e escurecer uma tecla
		# de tinta escura aproximava as duas -- o Ré caía a 4,15:1 justamente com
		# o dedo em cima. A regra mora em ColorDistance.pressed_shade_for().
		var pressed_sb := StyleBoxFlat.new()
		pressed_sb.corner_radius_bottom_left = CORNER_RADIUS
		pressed_sb.corner_radius_bottom_right = CORNER_RADIUS
		pressed_sb.bg_color = ColorDistance.pressed_shade_for(sb.bg_color)
		_buttons[i].add_theme_stylebox_override("normal", sb)
		_buttons[i].add_theme_stylebox_override("hover", sb)
		_buttons[i].add_theme_stylebox_override("pressed", pressed_sb)
		# Rede, não recurso: nada desabilita uma tecla hoje. Sem o override, uma
		# que fosse desabilitada cairia na caixa cinza escura do tema padrão do
		# Godot com a tinta calculada pra cor da NOTA -- 1,00:1.
		_buttons[i].add_theme_stylebox_override("disabled", sb)
		# Anel de foco DESENHADO AQUI, e não herdado. Estas 12 teclas são irmãs do
		# GameHUD na CanvasLayer, logo não veem blindtuner_theme.tres, e sem override
		# caíam no `focus` do tema padrão do Godot -- uma borda #CCCCCC de 2px,
		# feita pra skin escura. Medido: 1,28:1 sobre a tecla branca autêntica
		# (#EBE6D9) e 1,37:1 sobre o Mi #FFF200 do Pedagógico, contra um piso de
		# 3:1 de elemento gráfico. Nas 12 teclas x 3 esquemas o anel novo fica em
		# 3,87:1 no pior caso (o Lá# armado do Clássico).
		#
		# A versão anterior deste comentário dizia que NÃO sobrescrever era a
		# escolha certa ("deixa o padrão desenhar o indicador"). Era o defeito: o
		# padrão desenha, só que numa cor que ninguém enxerga sobre estas teclas.
		#
		# E o foco não é transitório num aparelho de toque: com
		# emulate_mouse_from_touch (ligado por padrão) tocar uma tecla dá foco a ela
		# e o foco FICA até outro controle tomá-lo. É o indicador de "você está
		# aqui", em estado de repouso.
		#
		# A cor sai da MESMA decisão que tinge o glifo, tomada contra a tecla em que
		# o anel cai -- o tema faz isso nos botões do HUD com uma cor fixa porque lá
		# o botão é sempre #FFFDF5; aqui o fundo muda por nota, por esquema e por
		# estado armado.
		var anel := StyleBoxFlat.new()
		# Miolo transparente: quem pinta o fundo continua sendo a stylebox do
		# estado, e o anel só acrescenta a borda -- é o que garante que ele não
		# tape o glifo nem o nome, que moram no centro da tecla.
		anel.draw_center = false
		anel.set_border_width_all(FOCUS_RING_PX)
		anel.border_color = ink
		anel.corner_radius_bottom_left = CORNER_RADIUS
		anel.corner_radius_bottom_right = CORNER_RADIUS
		_buttons[i].add_theme_stylebox_override("focus", anel)

## Cor da tecla com a ação ARMADA -- clareada, mas dentro do gamut.
##
## O clamp não é zelo: sem ele o Si autêntico (branco 0,92/0,90/0,85) armado ia a
## (1,47 / 1,44 / 1,36). A tela pinta 1,0, e icon_tint_for / text_outline_px_for /
## pressed_shade_for / contrast_ratio calculavam sobre 1,47 -- a régua e o pixel
## sobre cores DIFERENTES. Medido nesse caso: 39,2:1 na conta contra 17,4:1 no
## que o olho vê.
##
## Espelha SpecialActionPanel.armed_shade(): as duas superfícies armam as mesmas
## duas notas (correr/pular) e têm que clarear igual.
static func armed_shade(base: Color) -> Color:
	return Color(minf(base.r * ARMED_BRIGHTNESS, 1.0),
		minf(base.g * ARMED_BRIGHTNESS, 1.0),
		minf(base.b * ARMED_BRIGHTNESS, 1.0), base.a)

## Um piano de verdade não tem tecla de cor especial: as 4 notas de ação
## (Sol#-Si) recebem branco ou preto pela própria posição cromática, como
## qualquer outra. O que distingue uma ação é o ícone, não a cor da tecla.
func _key_base_color(chromatic_index: int, _note_key: String) -> Color:
	return BLACK_KEY_COLOR if is_black_key(chromatic_index) else WHITE_KEY_COLOR

## As4=correr (índice 2) e B4=pular (índice 3) espelham a convenção de índice
## já usada em SpecialActionPanel._armed. Demais notas não são armáveis (-1).
func _armed_index_for(note_key: String) -> int:
	match note_key:
		"As4": return 2
		"B4": return 3
		_: return -1

## Conectado pelo Playground ao sinal armed_state_changed do Character quando
## este modo está ativo (mesmo contrato de SpecialActionPanel.on_armed_state_changed).
func on_armed_state_changed(running: bool, jumping: bool) -> void:
	_armed[2] = running
	_armed[3] = jumping
	_apply_cue()
