extends Control
## Modo de input "Scroll de Afinação": braço fretless de instrumento de corda
## (sem traste -- violino/cello de verdade não têm). Arrasta o dedo
## verticalmente pra ouvir a frequência mudar ao vivo; ao soltar, resolve pra
## nota mais próxima do valor largado.
##
## Fretless não quer dizer liso: com o interruptor de pistas LIGADO, fitinhas
## coloridas marcam onde cada nota mora -- que é literalmente o que professor de
## violino cola no espelho de aluno iniciante. Traste é relevo fixo e não sai
## nunca; fita é material didático que some quando o jogador desliga o
## interruptor, e é essa opcionalidade que reconcilia as duas coisas. A fita é a
## manifestação do interruptor neste modo, como a cor da tecla é no piano.

signal note_triggered(note_key: String)
signal pitch_swept(freq_hz: float)
signal pitch_sweep_ended()

const ColorDistance := preload("res://scripts/ColorDistance.gd")

# O braço ocupa o corredor livre abaixo do NotePanel (medido no viewport de
# projeto 720x1280: y=240 até y=1280). As medidas de SEÇÃO -- cravelhal,
# cravelhas, largura do braço, cordas, dedo -- cresceram pelo fator horizontal
# 150/110 (~1,36); o comprimento extra é todo do braço, que é o que o dedo
# percorre. Ampliar a altura sem ampliar a seção deixaria um espeto fino de
# 780px, difícil de acertar justamente pro público de baixa visão.
#
# AO MUDAR ESTE VALOR, mude junto os offsets do nó PitchScrollInput em
# Playground.tscn. O custom_minimum_size abaixo PERDE para eles quando o
# Control é filho do CanvasLayer (medido: minsize (150,780) e size (110,400) ao
# mesmo tempo). Como _gui_input só recebe evento dentro do rect do nó, o excesso
# de braço vira zona morta e as notas graves ficam inalcançáveis -- sem erro e
# sem warning. test_playground_input_layout.gd vigia isso na cena de verdade.
const BOARD_SIZE := Vector2(150, 780)
const BOARD_MARGIN := Vector2(10, 10)
const HEAD_SIZE := Vector2(79, 106)         # cravelhal no topo
const PEG_SIZE := Vector2(27, 11)
const PEG_ROW_TOP := 33.0                   # y da 1a cravelha de cada lado
const PEG_ROW_SPACING := 27.0               # desnível entre as duas do mesmo lado
const PEG_INSET := 5.0                      # quanto a cravelha entra no cravelhal
const NECK_WIDTH := 84.0
const NECK_TOP := 101.0
# 4 cordas, como violino/cello de verdade. A ativa é a que responde ao dedo.
#
# Simétricas e de espaçamento igual. Os valores antigos (-29, -10, 10, 25) davam
# vãos de 19, 20 e 15px e deixavam o conjunto 2px à esquerda do centro do braço
# -- resto de um redimensionamento por fator horizontal, não uma decisão. Num
# instrumento as cordas são igualmente espaçadas, e a assimetria só ficou
# aparente quando o marcador de dedo foi pro centro.
const STRING_OFFSETS_X: Array[float] = [-30.0, -10.0, 10.0, 30.0]
const ACTIVE_STRING_INDEX := 1
const BOARD_COLOR_TOP := Color(0.227, 0.165, 0.102)     # #3a2a1a
const BOARD_COLOR_BOTTOM := Color(0.141, 0.094, 0.063)  # #241809
const HEAD_COLOR := Color(0.290, 0.200, 0.125)
const PEG_COLOR := Color(0.851, 0.725, 0.541)
const STRING_COLOR := Color(0.910, 0.886, 0.816)        # #e8e2d0
const STRING_ACTIVE_COLOR := Color(1.0, 0.992, 0.949)
const FINGER_FILL := Color(0.949, 0.788, 0.541)         # #f2c98a
const FINGER_BORDER := Color(0.478, 0.290, 0.071)       # #7a4a12
const FINGER_RADIUS := 18.0
# Precisa ser alto o bastante pro passo de cor entre faixas cair abaixo do
# limiar perceptível (~1 unidade de 8 bits). Uma borda visível em Y fixo vira
# um marco de afinação sempre no mesmo lugar -- ou seja, funcionalmente um
# traste, o que quebra a restrição fretless. Não reduza sem refazer essa conta.
# Conta refeita quando o braço cresceu: o canal que mais varia é o R, de 58
# para 36 (22 unidades de 8 bits). 64 faixas dão 0,34 unidade por faixa, bem
# abaixo do limiar -- e mantêm a faixa em ~10px, como era no braço de 400px.
const GRADIENT_STRIPS := 64
## Espessura da fitinha de posição. O semitom mais estreito do braço mede 44,7px
## (lá no agudo, ver test_note_spacing_matches_real_string_geometry), então 12px
## de fita deixam ~33px de madeira entre duas vizinhas: lê como marca e não como
## traste largo, e é grossa o bastante pro público de baixa visão. Não é alvo de
## toque -- quem recebe o dedo é o braço inteiro, em qualquer altura.
##
## Não cresce sem olhar BOARD_MARGIN.y: a fita é desenhada inteira e centrada na
## nota, então as das pontas (Dó e Si) invadem a margem entre o trecho útil e o
## fim do braço -- meia fita precisa caber nela, senão a marca vaza pra fora da
## madeira. test_tapes_stay_on_the_drawn_neck_and_never_bleed_over_the_background
## reprova quando não cabe.
const TAPE_HEIGHT := 12.0
## Moldura clara em volta da fitinha, em pixels de cada lado.
##
## A fita é o único elemento colorido do braço, e a cor da nota SOZINHA não se
## sustenta contra a madeira: medido nos três esquemas, 9 das 36 combinações
## fitinha x esquema ficam abaixo dos 3:1 do WCAG para elemento gráfico -- e as
## piores são as duas primeiras posições, que é o que um professor de violino
## cola PRIMEIRO (Dó 1,58:1 e Dó# 2,74:1 no esquema de fábrica; Dó 1,47:1 e Dó#
## 2,17:1 no Alto Contraste, que existe justamente para baixa visão). É o mesmo
## modo de falha que já mordeu o glifo do botão e o nome da placa.
##
## 2px de cada lado, e não 1: a 720x1280 uma linha de 1px não se acha com baixa
## visão, e a asserção de contraste só conta faixa de 2px pra cima -- com moldura
## de 1px as mesmas 9 combinações reprovam, mesmo a moldura estando em 14:1.
##
## Moldura, e não fita mais clara: mexer na COR quebraria o código de cores que o
## piano e o joystick usam para a MESMA nota, que é o sistema didático inteiro do
## jogo. A tinta da moldura sai de ColorDistance.icon_tint_for(), a mesma regra
## das outras duas correções -- então se a madeira clarear um dia, a moldura vira
## escura sozinha em vez de reabrir o buraco em silêncio.
##
## 2px de cada lado deixam 8px de miolo colorido: a corda, desenhada por cima,
## continua visível contra o miolo em vez de sumir dentro de uma faixa clara
## sólida. O tamanho EXTERNO da fita não muda, então a folga de madeira entre
## duas vizinhas continua sendo os ~33px de sempre.
const TAPE_EDGE := 2.0

var _dragging := false
var _finger_y := 0.0
var _drag_samples: Array[Dictionary] = []
var _level_cues_allowed: bool = true

func _ready() -> void:
	custom_minimum_size = BOARD_SIZE
	mouse_filter = MOUSE_FILTER_STOP
	_finger_y = NECK_TOP + BOARD_MARGIN.y
	# Repinta ao trocar de paleta e ao virar o interruptor de pistas, sem
	# reiniciar a fase. Aqui o braço é _draw() e não StyleBox, então o handler
	# chama queue_redraw() em vez de remontar estilo.
	#
	# NÃO escuta o nível de pista de propósito: aquele governa o que o HUD conta
	# sobre a nota TOCADA (é a dificuldade), enquanto a fita é material didático
	# permanente sobre o controle. No "só som", com o interruptor ligado, as fitas
	# continuam no braço.
	ColorSchemeSettings.scheme_changed.connect(_on_scheme_changed)
	ColorSchemeSettings.control_cues_changed.connect(_on_control_cues_changed)

func set_level_cues_allowed(allowed: bool) -> void:
	if _level_cues_allowed == allowed:
		return
	_level_cues_allowed = allowed
	queue_redraw()

func _effective_show_cues() -> bool:
	return ColorSchemeSettings.shows_control_cues() and _level_cues_allowed

func _on_scheme_changed(_id: String) -> void:
	queue_redraw()

func _on_control_cues_changed(_enabled: bool) -> void:
	queue_redraw()

func _draw() -> void:
	var cx := BOARD_SIZE.x * 0.5
	# Cravelhal (topo) + recesso esculpido + 4 cravelhas, 2 de cada lado
	var head_pos := Vector2(cx - HEAD_SIZE.x * 0.5, 0.0)
	draw_rect(Rect2(head_pos, HEAD_SIZE), HEAD_COLOR)
	draw_rect(Rect2(head_pos + Vector2(12.0, 14.0), HEAD_SIZE - Vector2(24.0, 24.0)), Color(0.16, 0.10, 0.06))
	draw_rect(Rect2(head_pos, HEAD_SIZE), Color(0.14, 0.09, 0.05), false, 2.0)
	for i in range(4):
		var on_left := i < 2
		var py := PEG_ROW_TOP + float(i % 2) * PEG_ROW_SPACING
		var shaft_y := py + PEG_SIZE.y * 0.5
		draw_line(Vector2(head_pos.x + 10.0, shaft_y), Vector2(head_pos.x + HEAD_SIZE.x - 10.0, shaft_y), Color(0.55, 0.42, 0.26), 3.0)
		var px := head_pos.x - PEG_SIZE.x + PEG_INSET if on_left else head_pos.x + HEAD_SIZE.x - PEG_INSET
		var peg_rect := Rect2(Vector2(px, py), PEG_SIZE)
		draw_rect(peg_rect, PEG_COLOR)
		draw_rect(peg_rect, Color(0.28, 0.18, 0.09), false, 1.5)

	# Braço, com gradiente simulado por faixas (sem asset de imagem)
	var strip_h := _strip_height()
	for i in range(GRADIENT_STRIPS):
		draw_rect(Rect2(Vector2(cx - NECK_WIDTH * 0.5, NECK_TOP + strip_h * i), Vector2(NECK_WIDTH, strip_h + 1.0)), _wood_color_at_strip(i))

	# Pestana de ébano no topo do braço (acima da 1ª fita em y=105) e chanfros laterais
	draw_rect(Rect2(Vector2(cx - NECK_WIDTH * 0.5, NECK_TOP), Vector2(NECK_WIDTH, 4.0)), Color(0.10, 0.08, 0.07))
	draw_line(Vector2(cx - NECK_WIDTH * 0.5, NECK_TOP), Vector2(cx - NECK_WIDTH * 0.5, BOARD_SIZE.y), Color(0.12, 0.08, 0.05, 0.85), 2.0)
	draw_line(Vector2(cx + NECK_WIDTH * 0.5, NECK_TOP), Vector2(cx + NECK_WIDTH * 0.5, BOARD_SIZE.y), Color(0.12, 0.08, 0.05, 0.85), 2.0)

	# Fitinhas de posição. A ordem de chamada dentro de _draw() é o único
	# z-index que existe aqui: elas entram DEPOIS do braço e ANTES das cordas e
	# do dedo, que é onde a fita fica num instrumento de verdade.
	#
	# O laço é CEGO ao significado das camadas -- ele pinta o que _tapes() listar,
	# na ordem em que listar. É de propósito: enquanto _draw() sabia que a camada
	# de baixo era "a moldura", dava pra apagar essa linha e a medição continuava
	# vendo uma moldura que a tela não tinha mais.
	for tape in _tapes():
		for layer in tape["layers"]:
			draw_rect(layer["rect"], layer["color"])

	# 4 cordas -- a ativa mais grossa e mais clara, e desenhadas por cima das
	# fitinhas. Vão de ponta a ponta do trecho que o dedo alcança: a corda que
	# se vê é exatamente a corda que se pode tocar.
	var top := _neck_usable_top()
	var bottom := _neck_usable_bottom()
	for i in range(STRING_OFFSETS_X.size()):
		var sx: float = cx + STRING_OFFSETS_X[i]
		var is_active := i == ACTIVE_STRING_INDEX
		var col := STRING_ACTIVE_COLOR if is_active else STRING_COLOR
		var w := 3.0 if is_active else 2.0
		draw_line(Vector2(sx + 1.5, top), Vector2(sx + 1.5, bottom), Color(0.08, 0.05, 0.03, 0.45), w, true)
		if is_active and _dragging and _finger_y > top + 8.0:
			draw_line(Vector2(sx - 2.0, top), Vector2(sx - 2.0, _finger_y), Color(1.0, 0.88, 0.45, 0.45), 2.0, true)
			draw_line(Vector2(sx + 2.0, top), Vector2(sx + 2.0, _finger_y), Color(1.0, 0.88, 0.45, 0.45), 2.0, true)
		draw_line(Vector2(sx, top), Vector2(sx, bottom), col, w, true)

	# Marcador de dedo, centrado no braço.
	#
	# Antes ficava colado na corda ativa (offset -10), o que contava a história
	# certa -- "o dedo está NESTA corda" -- mas deixava a bolinha fora do eixo do
	# controle, e o que o olho procura num controle vertical é o eixo. Com raio 18
	# ela cobre as duas cordas de dentro, então a leitura de "dedo sobre a corda"
	# sobrevive; o que muda é que o marcador passa a indicar ALTURA, que é a única
	# coisa que o arrasto de fato controla (a corda nunca troca -- ver
	# test_audio_manager: arrastar muda o comprimento que vibra, não a corda).
	var fx := cx
	var finger_pos := Vector2(fx, _finger_y)
	draw_circle(finger_pos + Vector2(0.0, 2.0), FINGER_RADIUS + 1.0, Color(0.08, 0.05, 0.03, 0.40))
	draw_circle(finger_pos, FINGER_RADIUS, FINGER_FILL)
	draw_arc(finger_pos, FINGER_RADIUS, 0, TAU, 24, FINGER_BORDER, 2.5, true)
	draw_arc(finger_pos, FINGER_RADIUS * 0.58, 0, TAU, 20, Color(FINGER_BORDER.r, FINGER_BORDER.g, FINGER_BORDER.b, 0.55), 1.5, true)
	draw_line(finger_pos + Vector2(-8.0, 0.0), finger_pos + Vector2(8.0, 0.0), FINGER_BORDER, 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_dragging = true
			_move_finger_to(event.position.y)
			accept_event()
		else:
			if _dragging:
				_dragging = false
				_on_drag_ended()
			accept_event()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging:
			_move_finger_to(event.position.y)
			accept_event()

func _move_finger_to(local_y: float) -> void:
	_finger_y = clampf(local_y, _neck_usable_top(), _neck_usable_bottom())
	var now := Time.get_ticks_msec()
	_drag_samples.append({ "y": _finger_y, "time": now })
	while _drag_samples.size() > 12 or (not _drag_samples.is_empty() and now - _drag_samples[0]["time"] > 180):
		_drag_samples.pop_front()
	queue_redraw()
	var current_freq := _frequency_for_finger_y()
	AudioManager.play_continuous_pitch(current_freq)
	pitch_swept.emit(current_freq)

## Extremos do trecho de braço que o dedo percorre: do topo (logo abaixo do
## cravelhal, onde ficaria a pestana) até a base (perto do cavalete).
func _neck_usable_top() -> float:
	return NECK_TOP + BOARD_MARGIN.y

func _neck_usable_bottom() -> float:
	return BOARD_SIZE.y - BOARD_MARGIN.y

## Numa corda, a frequência é inversamente proporcional ao comprimento que
## vibra: com o dedo a uma distância x da pestana, numa corda de comprimento L,
## f = f_grave * L / (L - x). Duas consequências, e as duas valem aqui:
##
## 1. SENTIDO -- o topo do braço útil é a pestana, então a corda solta ali é a
##    nota mais GRAVE. Descer o dedo encurta o trecho que vibra e SOBE a nota,
##    como num violino. (A versão anterior punha a mais aguda no topo.)
## 2. ESPAÇAMENTO -- os semitons se apertam conforme se desce, porque o mesmo
##    salto de frequência custa cada vez menos comprimento. Um mapeamento linear
##    em frequência produz o espelho exato disso: grave espremido, agudo largo.
##
## `x` é normalizado pelo x da nota mais aguda pra oitava inteira ocupar
## exatamente o braço útil.
func _frequency_for_y(y: float) -> float:
	var t := (y - _neck_usable_top()) / (_neck_usable_bottom() - _neck_usable_top())
	var low := _lowest_frequency()
	return low / (1.0 - t * _neck_span_ratio())

func _frequency_for_finger_y() -> float:
	return _frequency_for_y(_finger_y)

## Onde no braço mora uma frequência -- a inversa exata de
## _frequency_for_finger_y(). Fonte única da posição de cada nota: quem precisar
## desenhar ou testar posição chama daqui, senão a fórmula duplica e as duas
## versões divergem em silêncio.
func _y_for_frequency(freq: float) -> float:
	var low := _lowest_frequency()
	var t := (1.0 - low / freq) / _neck_span_ratio()
	return _neck_usable_top() + t * (_neck_usable_bottom() - _neck_usable_top())

## As fitinhas a desenhar AGORA: uma por nota. Devolve os dados em vez de
## desenhar direto pra posição e a tinta de cada fita serem verificáveis sem
## passe de render -- e pra que o teste vigie o que o _draw() realmente pinta, e
## não uma segunda régua paralela.
##
## Lista VAZIA com o interruptor de pistas desligado: aí sobra o braço liso.
##
## Cada fita vem com a madeira que está por baixo ("wood") e as CAMADAS que ela
## pinta ("layers"), na ordem de desenho -- cada camada cobre a anterior, como no
## _draw(). Hoje são duas: a moldura clara ocupando o retângulo inteiro e o miolo
## colorido por cima, recuado de TAPE_EDGE.
##
## A lista de camadas existe pra que "a fita é achável contra a madeira" seja
## medível sobre a tinta que sobra VISÍVEL: com "moldura" e "miolo" como campos
## separados, apagar o desenho da moldura deixava o campo intacto e o teste de
## contraste seguia verde medindo uma moldura que ninguém mais via.
##
## A madeira sai daqui e não de uma conta refeita no teste pelo mesmo motivo da
## posição: o contraste tem que ser medido contra o fundo que o _draw() REALMENTE
## pinta, senão a régua duplica.
func _tapes() -> Array[Dictionary]:
	var tapes: Array[Dictionary] = []
	if not _effective_show_cues():
		return tapes
	# Largura do BRAÇO (84px, de x=33 a x=117), não a do board (150px): este nó
	# não tem clip_contents, então uma fita da largura do board pintaria 33px de
	# cor de cada lado, por fora da madeira e sobre fundo transparente.
	var x := BOARD_SIZE.x * 0.5 - NECK_WIDTH * 0.5
	for key in NoteMapping.NOTES:
		var cy := _y_for_frequency(float(NoteMapping.NOTES[key]["freq"]))
		# Fita INTEIRA e centrada na nota, sempre -- inclusive nos extremos.
		#
		# Cabe porque a faixa em que a fita pode ser pintada é o braço DESENHADO
		# (NECK_TOP..BOARD_SIZE.y) e não o trecho que o dedo percorre
		# (_neck_usable_top..bottom): sobra BOARD_MARGIN.y = 10px de madeira além de
		# cada ponta, e meia fita são 6px.
		#
		# Antes o retângulo era aparado contra o trecho útil. Como Dó e Si moram
		# exatamente nas bordas dele, as duas fitas que um professor de violino cola
		# PRIMEIRO ficavam com 6px de altura -- 2px de cor contra os 8px das outras
		# dez -- e com o centro 3px fora da nota. A aparação existia pra proteger o
		# centro e era justamente ela que movia o centro, porque metade do retângulo
		# sumia de um lado só.
		#
		# Sem aparação nenhuma aqui, de propósito: um maxf/minf que a geometria de
		# hoje nunca dispara é código que nenhum teste distingue. Quem cobra a
		# premissa é test_tapes_stay_on_the_drawn_neck_and_never_bleed_over_the_background,
		# que reprova se a fita passar do braço -- alto, em vez de aparar baixinho.
		var rect := Rect2(Vector2(x, cy - TAPE_HEIGHT * 0.5), Vector2(NECK_WIDTH, TAPE_HEIGHT))
		var wood := _wood_color_at(cy)
		# Cor da nota no esquema ATIVO: assim as fitas herdam de graça os três
		# esquemas fixos e o editor de paleta livre.
		tapes.append({
			"wood": wood,
			"layers": [
				{"rect": rect, "color": ColorDistance.icon_tint_for(wood)},
				{"rect": rect.grow(-TAPE_EDGE), "color": NoteMapping.color_for(key)},
			],
		})
	return tapes

## Altura de uma faixa do gradiente do braço.
func _strip_height() -> float:
	return (BOARD_SIZE.y - NECK_TOP) / float(GRADIENT_STRIPS)

## Cor da faixa `i` do gradiente. Fonte única da madeira: quem desenha o braço e
## quem precisa saber contra o que a fita está contrastando chamam daqui, senão a
## conta duplica e o teste de contraste passa a medir contra uma madeira que não
## é a desenhada.
func _wood_color_at_strip(i: int) -> Color:
	return BOARD_COLOR_TOP.lerp(BOARD_COLOR_BOTTOM, float(i) / float(GRADIENT_STRIPS - 1))

## Cor da madeira numa altura y qualquer do braço.
func _wood_color_at(y: float) -> Color:
	return _wood_color_at_strip(clampi(int((y - NECK_TOP) / _strip_height()), 0, GRADIENT_STRIPS - 1))

## Fração do comprimento da corda que a oitava consome; é ela que estica a
## conta pra oitava caber justa no braço útil.
func _neck_span_ratio() -> float:
	return 1.0 - _lowest_frequency() / _highest_frequency()

func _lowest_frequency() -> float:
	var lowest := INF
	for key in NoteMapping.NOTES:
		lowest = minf(lowest, float(NoteMapping.NOTES[key]["freq"]))
	return lowest

func _highest_frequency() -> float:
	var highest := 0.0
	for key in NoteMapping.NOTES:
		highest = maxf(highest, float(NoteMapping.NOTES[key]["freq"]))
	return highest

func _on_drag_ended() -> void:
	AudioManager.stop_continuous_pitch()
	pitch_sweep_ended.emit()
	queue_redraw()
	var final_y := _finger_y
	var now := Time.get_ticks_msec()
	# Touch-Up Hysteresis: filtra saltos involuntários nos últimos 50ms de soltura do dedo na tela touch
	if _drag_samples.size() >= 3:
		for s in _drag_samples:
			if now - s["time"] >= 50:
				final_y = s["y"]
				break
	_drag_samples.clear()
	var note := NoteMapping.nearest_note_for_frequency(_frequency_for_y(final_y))
	note_triggered.emit(note)

func _exit_tree() -> void:
	# Sai da árvore (troca de cena, ou removido enquanto o tom ainda soa --
	# ex: arrasto em progresso quando o jogo troca de preset/mapa) sem passar
	# por _on_drag_ended: o tom contínuo não pode ficar tocando indefinidamente.
	AudioManager.stop_continuous_pitch()
