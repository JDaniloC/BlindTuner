extends Control
## Modo de input "Piano Virtual": teclado real de uma oitava (C4-B4), teclas
## brancas/pretas na posição de um piano de verdade. Emite o mesmo sinal
## note_triggered que DirectionJoystick/SpecialActionPanel/BlindTouchInput.

signal note_triggered(note_key: String)

const WHITE_KEY_WIDTH := 54.0
const WHITE_KEY_HEIGHT := 160.0
const BLACK_KEY_WIDTH := 34.0
const BLACK_KEY_HEIGHT := 100.0
const BLACK_KEY_INDICES := [1, 3, 6, 8, 10]
const WHITE_INDEX_FOR_CHROMATIC := {0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6}
const LEFT_WHITE_FOR_BLACK := {1: 0, 3: 1, 6: 3, 8: 4, 10: 5}
const CORNER_RADIUS := 6
const ARMED_BRIGHTNESS := 1.6  # espelha SpecialActionPanel.ARMED_BRIGHTNESS
const WHITE_KEY_COLOR := Color(0.92, 0.90, 0.85)
const BLACK_KEY_COLOR := Color(0.12, 0.12, 0.14)
const ACTION_KEY_COLOR := Color(0.55, 0.38, 0.16)  # âmbar escuro -- as 4 teclas de ação (G#-B) se distinguem mesmo sem pista de cor

var _buttons: Array[Button] = []
var _button_notes: Array[String] = []
var _key_icons: Array = []
# Paralelo às notas armáveis (correr/pular); atualizado por on_armed_state_changed.
var _armed: Array[bool] = [false, false, false, false]

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
		btn.pressed.connect(_emit_note.bind(note_key))
		add_child(btn)
		var icon: Control = load("res://scripts/ActionIcon.gd").new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.size = Vector2(24, 24)
		# Rodapé da tecla -- não colide com o rótulo de texto, que fica no centro.
		icon.position = Vector2((btn.size.x - 24) * 0.5, btn.size.y - 34)
		btn.add_child(icon)
		icon.set_note(note_key)
		_key_icons.append(icon)
		_buttons.append(btn)
		_button_notes.append(note_key)
	# Reordena os FILHOS (não os arrays _buttons/_button_notes, que ficam na
	# ordem cromática de NoteMapping) pra que as teclas pretas desenhem por
	# cima das brancas -- igual a um piano de verdade.
	for i in range(keys.size()):
		if is_black_key(i):
			move_child(_buttons[i], -1)

	CueSettings.cue_level_changed.connect(_on_cue_changed)
	_apply_cue()

func _emit_note(note_key: String) -> void:
	note_triggered.emit(note_key)

func _on_cue_changed(_level: int) -> void:
	_apply_cue()

func _apply_cue() -> void:
	var show_name := CueSettings.shows_name()
	var show_color := CueSettings.shows_color()
	for i in range(_buttons.size()):
		var note_key := _button_notes[i]
		_buttons[i].text = NoteMapping.label_for(note_key) if show_name else ""
		var armed_idx := _armed_index_for(note_key)
		var is_armed := armed_idx >= 0 and _armed[armed_idx]
		var sb := StyleBoxFlat.new()
		sb.corner_radius_bottom_left = CORNER_RADIUS
		sb.corner_radius_bottom_right = CORNER_RADIUS
		if show_color:
			# Nível de pista máximo: prioriza a cor distintiva por nota (igual
			# aos outros 3 modos de input) sobre o realismo do teclado -- a cor
			# vai direto no fundo da tecla (bg_color). modulate fica neutro
			# (Color.WHITE): modulate multiplica o BOTÃO INTEIRO (fundo E o
			# texto do label), então usá-lo pra tingir deixava o texto quase
			# da mesma cor do fundo (contraste ~1.12, ilegível).
			sb.bg_color = NoteMapping.color_for(note_key)
			if is_armed:
				sb.bg_color = Color(sb.bg_color.r * ARMED_BRIGHTNESS, sb.bg_color.g * ARMED_BRIGHTNESS, sb.bg_color.b * ARMED_BRIGHTNESS, sb.bg_color.a)
			_buttons[i].modulate = Color.WHITE
		else:
			# Níveis de prática: teclado autêntico (branco/preto/âmbar), sem tint.
			sb.bg_color = _key_base_color(i, note_key)
			if is_armed:
				sb.bg_color = Color(sb.bg_color.r * ARMED_BRIGHTNESS, sb.bg_color.g * ARMED_BRIGHTNESS, sb.bg_color.b * ARMED_BRIGHTNESS, sb.bg_color.a)
			_buttons[i].modulate = Color.WHITE
		# Estado "pressed" ganha um stylebox próprio (mesma geometria, fundo
		# escurecido) pra dar feedback visual de toque -- sem isso, apertar
		# uma tecla não mudava nada visualmente (normal/hover/pressed
		# compartilhavam o mesmo StyleBoxFlat).
		var pressed_sb := StyleBoxFlat.new()
		pressed_sb.corner_radius_bottom_left = CORNER_RADIUS
		pressed_sb.corner_radius_bottom_right = CORNER_RADIUS
		var base_color := sb.bg_color
		pressed_sb.bg_color = Color(base_color.r * 0.85, base_color.g * 0.85, base_color.b * 0.85, base_color.a)
		_buttons[i].add_theme_stylebox_override("normal", sb)
		_buttons[i].add_theme_stylebox_override("hover", sb)
		_buttons[i].add_theme_stylebox_override("pressed", pressed_sb)
		# "focus" não é sobrescrito de propósito: deixa o tema padrão do Godot
		# desenhar o indicador de foco (navegação por teclado/acessibilidade).
		# Sobrescrever com uma stylebox sem borda estava removendo esse indicador.

func _key_base_color(chromatic_index: int, note_key: String) -> Color:
	if NoteMapping.is_action_note(note_key):
		return ACTION_KEY_COLOR
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
