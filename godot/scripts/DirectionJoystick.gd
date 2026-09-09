extends Control
## Joystick virtual circular com 8 fatias iguais (4 cardinais + 4 diagonais).
## Cada fatia ocupa 45° e mapeia para uma nota de movimento. As 4 notas de
## ação saíram do círculo (vão pro SpecialActionPanel).

signal note_triggered(note_key: String)

## ColorDistance é RefCounted, não autoload -- precisa de preload pra ser usado.
const ColorDistance := preload("res://scripts/ColorDistance.gd")

## RADIUS é a raiz de toda a geometria. As três constantes abaixo já eram
## frações exatas dele, só que escritas como número fixo -- deixar a zona morta
## em pixels enquanto o raio cresce encolheria ela em proporção e faria um
## micro-arrasto disparar direção, que é o oposto do que o público precisa.
const RADIUS := 140.0
# Subiu de 0.15: é esta fração que cria a margem visual entre o nome da nota e
# a borda da roda. Aumentar só o RADIUS não abriria espaço nenhum -- as
# posições do rótulo também são frações do raio, então a proporção ficaria
# idêntica e o nome continuaria colado no aro, só que tudo maior.
const BACKDROP_OVERHANG := RADIUS * 0.24    # px que o disco/anel ultrapassam o raio das fatias
const DEAD_ZONE := RADIUS * 0.1875
const SLICE_COUNT := 8
const SLICE_ANGLE_DEG := 45.0
const THUMB_RADIUS := RADIUS * 0.35
const SLICE_VERTICES := 16  # vértices ao longo do arco
const BACKDROP_SEGMENTS := 64  # era 32: a 138px de raio, 32 lados leem como polígono
const NEUTRAL_SLICE := Color(0.55, 0.55, 0.58)  # aparência com o interruptor de pistas desligado

## Geometria interna da fatia, toda em fração do raio: seta no anel de dentro,
## nome da nota no anel de fora. Frações em vez de pixels para o conteúdo
## acompanhar o joystick se o raio mudar.
const ICON_RADIUS_FRAC := 0.36      # recuou de novo: o nome precisou vir pra dentro
const ICON_SIDE := RADIUS * 0.37    # era 30 fixo: não acompanhava o raio
const LABEL_RADIUS_FRAC := 0.80     # centro do nome, já fora da caixa da seta
const LABEL_SIZE_FRAC := Vector2(0.50, 0.30)
const LABEL_FONT_FRAC := 0.225      # 27px com RADIUS=120
const LABEL_COLOR := Color.WHITE
## O nome cai sobre fatia colorida translúcida e, mais além, sobre o cenário:
## nenhuma cor chapada contrasta com tudo isso. O contorno escuro resolve sem
## depender de qual esquema de cor está ativo.
const LABEL_OUTLINE_COLOR := Color(0.08, 0.07, 0.06, 0.95)
const LABEL_OUTLINE_SIZE := 6

## Disco de fundo OPACO. Era alfa 0,30, e as setas eram brancas fixas com a
## justificativa de que aqui havia "fundo escuro garantido". Não havia: com o
## disco translúcido, o que fica atrás da seta é o CENÁRIO, e o Banheiro tem chão
## #E8E4D8. Medido, seta branca sobre a fatia inativa por cima daquele chão:
## 2,19:1, abaixo dos 3:1 de elemento gráfico -- e 1,99:1 de disco contra chão,
## ou seja, nem a borda do controle se distinguia do piso.
##
## Opaco, a premissa vira verdadeira e o contraste da seta deixa de depender de
## em que cômodo a fase se passa. Foi a mesma lição que o piano e as placas já
## tinham aprendido, cada um por conta própria: tinta decidida contra um fundo
## SUPOSTO em vez do fundo pintado.
const BACKDROP_DISC := Color(0.12, 0.10, 0.09)
## Alfa da fatia em repouso e sob o dedo. Estavam escritos como números soltos em
## dois lugares; a tinta da seta é recalculada a partir deles, então precisam ter
## nome.
const SLICE_ALPHA_IDLE := 0.35
const SLICE_ALPHA_ACTIVE := 0.85

var _dragging := false
var _thumb_offset := Vector2.ZERO
var _slice_polygons: Array[Polygon2D] = []
var _slice_note_keys: Array[String] = []  # paralelo a _slice_polygons (8 entradas)
var _slice_icons: Array[Control] = []     # paralelo a _slice_note_keys (8 entradas)
var _slice_labels: Array[Label] = []      # paralelo a _slice_note_keys (8 entradas)
var _active_slice_index: int = -1         # 0..7 (índice da fatia em _slice_polygons), ou -1
var _flash_tween: Tween
var _backdrop_disc: Polygon2D
var _backdrop_ring: Line2D

@onready var _slices_root: Node2D = $Slices
@onready var _thumb: Polygon2D = $Thumb

func _ready() -> void:
	# Uma fonte só para desenho e toque. Antes o tamanho vinha do .tscn (200x200)
	# e o centro do desenho de uma posição fixa gravada lá (100,100): coincidiam
	# só porque os números casavam com RADIUS=80. O alcance a cobrir é
	# RADIUS+THUMB_RADIUS, não RADIUS+BACKDROP_OVERHANG -- o thumb é clampado no
	# raio e ainda desenha o próprio raio além disso.
	custom_minimum_size = Vector2.ONE * 2.0 * (RADIUS + THUMB_RADIUS)
	size = custom_minimum_size
	# Como filho do CanvasLayer o tamanho real vem dos offsets da cena e só chega
	# depois daqui; sem reagir ao resize, o desenho ficaria fora do alvo de toque.
	resized.connect(_recenter)
	_recenter()
	_build_backdrop()
	_build_slices()
	_build_thumb()
	_refresh_slice_alphas()
	# Repinta na troca de esquema de cor, sem precisar reiniciar a fase.
	ColorSchemeSettings.scheme_changed.connect(_on_scheme_changed)
	# Quem manda nas pistas DO CONTROLE é o interruptor, não o nível de pista:
	# aquele governa o que o HUD conta sobre a nota tocada (a dificuldade), este
	# aqui é material didático sobre onde cada nota mora.
	ColorSchemeSettings.control_cues_changed.connect(_on_control_cues_changed)
	_apply_cue()

## Centro do desenho colado no centro da caixa de toque, em qualquer tamanho.
func _recenter() -> void:
	var center := size / 2.0
	_slices_root.position = center
	_thumb.position = center + _thumb_offset

## Disco + anel circulares atrás das fatias (substitui o antigo NinePatchRect).
## Adicionados primeiro em _slices_root, logo desenhados atrás das fatias.
func _build_backdrop() -> void:
	var r := RADIUS + BACKDROP_OVERHANG
	var pts: Array[Vector2] = []
	for v in range(BACKDROP_SEGMENTS):
		var a := TAU * float(v) / float(BACKDROP_SEGMENTS)
		pts.append(Vector2(cos(a), sin(a)) * r)
	_backdrop_disc = Polygon2D.new()
	_backdrop_disc.polygon = PackedVector2Array(pts)
	_backdrop_disc.color = BACKDROP_DISC
	_slices_root.add_child(_backdrop_disc)
	var ring_pts: Array[Vector2] = pts.duplicate()
	ring_pts.append(pts[0])
	_backdrop_ring = Line2D.new()
	_backdrop_ring.points = PackedVector2Array(ring_pts)
	_backdrop_ring.width = 2.0
	_backdrop_ring.default_color = Color(0.20, 0.17, 0.14, 0.6)
	_slices_root.add_child(_backdrop_ring)

func _build_slices() -> void:
	_slice_polygons.clear()
	_slice_note_keys.clear()
	# 8 notas de movimento em ordem de inserção do dicionário ocupam
	# 0°, 45°, 90°, ..., 315° (N, NE, E, SE, S, SW, W, NW).
	var idx := 0
	for k in NoteMapping.NOTES.keys():
		var key: String = k
		if NoteMapping.is_action_note(key):
			continue
		var slice := Polygon2D.new()
		slice.polygon = _build_slice_polygon(idx)
		slice.color = slice_display_color(key)
		_slices_root.add_child(slice)
		_slice_polygons.append(slice)
		_slice_note_keys.append(key)
		idx += 1
	_build_slice_icons()
	# Depois dos ícones de propósito: em Node2D a ordem de filho é a ordem de
	# desenho, e o nome precisa ficar por cima da seta se um dia encostarem.
	_build_slice_labels()

## Centro do conteúdo da fatia i, num raio dado em fração do raio do joystick.
## 0° aponta pro Norte da tela (-y), igual a _build_slice_polygon.
func _slice_anchor(slice_index: int, radius_frac: float) -> Vector2:
	var rad := deg_to_rad(slice_index * SLICE_ANGLE_DEG)
	return Vector2(sin(rad), -cos(rad)) * (RADIUS * radius_frac)

## Uma seta por fatia, no anel interno, apontando na direção que a nota daquela
## fatia representa.
func _build_slice_icons() -> void:
	var IconScript := load("res://scripts/ActionIcon.gd")
	_slice_icons.clear()
	for i in range(_slice_note_keys.size()):
		var icon: Control = IconScript.new()
		icon.custom_minimum_size = Vector2(ICON_SIDE, ICON_SIDE)
		icon.size = Vector2(ICON_SIDE, ICON_SIDE)
		icon.position = _slice_anchor(i, ICON_RADIUS_FRAC) - icon.size * 0.5
		_slices_root.add_child(icon)
		icon.set_note(_slice_note_keys[i])
		_slice_icons.append(icon)

## Um rótulo por fatia, no anel externo. O texto em si é preenchido por
## _apply_cue(): é pista da nota, então segue o interruptor de pistas. A seta
## não segue -- ela é afordância e só repete o que a posição da fatia já dizia.
func _build_slice_labels() -> void:
	_slice_labels.clear()
	var box := LABEL_SIZE_FRAC * RADIUS
	for i in range(_slice_note_keys.size()):
		var lbl := Label.new()
		# O padrão de Label já é IGNORE, mas explícito aqui porque um rótulo que
		# capture o ponteiro engole o arrasto do joystick inteiro.
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = box
		lbl.add_theme_font_size_override("font_size", int(RADIUS * LABEL_FONT_FRAC))
		lbl.add_theme_color_override("font_color", LABEL_COLOR)
		lbl.add_theme_color_override("font_outline_color", LABEL_OUTLINE_COLOR)
		lbl.add_theme_constant_override("outline_size", LABEL_OUTLINE_SIZE)
		_slices_root.add_child(lbl)
		_slice_labels.append(lbl)
		_place_label(i)

## Planta o rótulo da fatia centrado na âncora, medindo o tamanho REAL em vez de
## confiar na caixa declarada em LABEL_SIZE_FRAC.
##
## O Label é clampado no mínimo combinado (linha de fonte + contorno): com
## RADIUS=120 a caixa pedida é 60x36 e ele mede 60x37, então centrar por
## `box * 0.5` deixava meio pixel de desvio. Meio pixel é cosmético; o que não é
## cosmético é que o desvio cresce em (size - box)/2 a cada aumento de RADIUS, de
## LABEL_FONT_FRAC ou da fonte do sistema por acessibilidade -- ou seja, a
## invariância de escala que motivou escrever a geometria toda em frações do raio
## não valia justamente para o rótulo.
##
## Chamado também depois de trocar o texto: o texto entra no mínimo do Label, e
## um nome mais largo que a caixa a empurraria para fora do centro de novo.
func _place_label(slice_index: int) -> void:
	var lbl := _slice_labels[slice_index]
	lbl.size = LABEL_SIZE_FRAC * RADIUS  # o setter já sobe pro mínimo combinado
	lbl.position = _slice_anchor(slice_index, LABEL_RADIUS_FRAC) - lbl.size * 0.5

func slice_display_color(note_key: String) -> Color:
	if ColorSchemeSettings.shows_control_cues():
		return NoteMapping.color_for(note_key)
	return NEUTRAL_SLICE

func _on_scheme_changed(_id: String) -> void:
	_apply_cue()

func _on_control_cues_changed(_enabled: bool) -> void:
	_apply_cue()

## Aplica o interruptor de pistas na fatia inteira: cor no polígono, nome no
## rótulo. Cor e nome são a MESMA condição -- o interruptor é único de propósito
## (seis chaves numa tela para quem tem baixa visão custam mais do que a
## granularidade entrega).
func _apply_cue() -> void:
	var show_cues := ColorSchemeSettings.shows_control_cues()
	for i in range(_slice_polygons.size()):
		var c := slice_display_color(_slice_note_keys[i])
		c.a = _slice_polygons[i].color.a  # preserva alpha atual (gerido por _refresh_slice_alphas)
		_slice_polygons[i].color = c
		_slice_labels[i].text = NoteMapping.label_for(_slice_note_keys[i]) if show_cues else ""
		# Depois do texto: ele entra no mínimo do Label e pode mudar o tamanho.
		_place_label(i)
	# A cor da fatia mudou, logo o fundo da seta mudou junto.
	_retint_slice_icons()

func _build_slice_polygon(slice_index: int) -> PackedVector2Array:
	var points: Array[Vector2] = [Vector2.ZERO]
	# ângulo 0° aponta pra Norte (-y); fatia começa metade do passo antes
	# (centro alinhado com a direção da nota).
	var start_deg := slice_index * SLICE_ANGLE_DEG - SLICE_ANGLE_DEG * 0.5
	for v in range(SLICE_VERTICES + 1):
		var t := float(v) / SLICE_VERTICES
		var deg := start_deg + t * SLICE_ANGLE_DEG
		var rad := deg_to_rad(deg)
		# 0°=Norte (sentido horário): x = sin(rad), y = -cos(rad)
		var x := sin(rad) * RADIUS
		var y := -cos(rad) * RADIUS
		points.append(Vector2(x, y))
	return PackedVector2Array(points)

func _build_thumb() -> void:
	var points: Array[Vector2] = []
	for v in range(24):
		var t := float(v) / 24.0
		var rad := t * TAU
		points.append(Vector2(cos(rad), sin(rad)) * THUMB_RADIUS)
	_thumb.polygon = PackedVector2Array(points)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_dragging = true
			_update_thumb(_local_pointer(event))
			accept_event()
		else:
			if _dragging:
				_emit_for_offset(_thumb_offset)
			_dragging = false
			_reset_thumb()
			accept_event()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging:
			_update_thumb(_local_pointer(event))
			accept_event()

func _local_pointer(event: InputEvent) -> Vector2:
	return event.position - size / 2.0

func _update_thumb(offset: Vector2) -> void:
	_thumb_offset = offset.limit_length(RADIUS)
	var center := size / 2.0
	_thumb.position = center + _thumb_offset
	_active_slice_index = slice_index_for_offset(_thumb_offset)
	_refresh_slice_alphas()

func _reset_thumb() -> void:
	_thumb_offset = Vector2.ZERO
	var center := size / 2.0
	_thumb.position = center
	_active_slice_index = -1
	_refresh_slice_alphas()

func _refresh_slice_alphas() -> void:
	for i in range(_slice_polygons.size()):
		var slice := _slice_polygons[i]
		var base := slice.color
		base.a = SLICE_ALPHA_ACTIVE if i == _active_slice_index else SLICE_ALPHA_IDLE
		slice.color = base
	_retint_slice_icons()

## Cor REALMENTE pintada atrás da seta da fatia `i`: a fatia translúcida composta
## sobre o disco opaco.
func _slice_backdrop(i: int) -> Color:
	var slice := _slice_polygons[i].color
	return Color(
		slice.r * slice.a + BACKDROP_DISC.r * (1.0 - slice.a),
		slice.g * slice.a + BACKDROP_DISC.g * (1.0 - slice.a),
		slice.b * slice.a + BACKDROP_DISC.b * (1.0 - slice.a))

## A seta segue a mesma regra do glifo da tecla e da placa. Precisa rodar a cada
## mudança de ALFA, não só de cor: a fatia sob o dedo pula de 0,35 pra 0,85, e aí
## o que está atrás da seta deixa de ser o disco escuro e passa a ser quase a cor
## da nota. Nas notas claras (o Mi do Pedagógico é #FFF200) uma seta branca fixa
## cairia pra 1,6:1 justamente na fatia que o jogador escolheu.
func _retint_slice_icons() -> void:
	for i in range(_slice_icons.size()):
		_slice_icons[i].set_tint(ColorDistance.icon_tint_for(_slice_backdrop(i)))

## A régua de contraste dos testes pergunta aqui o que este controle pinta atrás
## de cada filho: as fatias são IRMÃS das setas e dos nomes num Node2D, então
## nenhuma caminhada por ancestrais acha esse fundo sozinha.
func contrast_backdrop_for(child: Node) -> Variant:
	# Guarda de tipo antes do find(): Array.find() em array TIPADO dispara erro
	# quando recebe um objeto de outra classe, e a régua pergunta por todo filho
	# (o thumb é um Polygon2D).
	if not (child is Control):
		return null
	var i: int = _slice_labels.find(child) if child is Label else _slice_icons.find(child)
	return _slice_backdrop(i) if i >= 0 else null

func _emit_for_offset(offset: Vector2) -> void:
	var note := vector_to_note(offset)
	if note != "":
		_flash_active_slice()
		note_triggered.emit(note)

func _flash_active_slice() -> void:
	if _active_slice_index < 0 or _active_slice_index >= _slice_polygons.size():
		return
	if _flash_tween:
		_flash_tween.kill()
	var slice := _slice_polygons[_active_slice_index]
	var bright := slice.color
	bright.a = 1.0
	var dim := slice.color
	dim.a = SLICE_ALPHA_IDLE
	_flash_tween = create_tween()
	_flash_tween.tween_property(slice, "color", bright, 0.06)
	_flash_tween.tween_property(slice, "color", dim, 0.16)
	# O tween escreve slice.color direto, por fora de _refresh_slice_alphas():
	# sem isto a seta terminava o flash com a tinta calculada pra fatia ACESA.
	_flash_tween.tween_callback(_retint_slice_icons)

## Converte um vetor 2D (relativo ao centro) em uma chave de nota.
## Só retorna notas de movimento (snap em layout direcional 8x45°).
func vector_to_note(v: Vector2) -> String:
	if v.length() < DEAD_ZONE:
		return ""
	var angle_rad := atan2(v.x, -v.y)
	var angle_deg := rad_to_deg(angle_rad)
	return NoteMapping.snap_angle_to_note(angle_deg, true)

## Índice da fatia (0..7) correspondente ao ângulo em graus. 0°=N, 45°=NE, etc.
## Consistente com vector_to_note: usa o mesmo snap para resolver empates exatos.
func slice_index_for_angle(angle_deg: float) -> int:
	var note := NoteMapping.snap_angle_to_note(angle_deg, true)
	return _slice_note_keys.find(note)

func slice_index_for_offset(offset: Vector2) -> int:
	if offset.length() < DEAD_ZONE:
		return -1
	return slice_index_for_angle(rad_to_deg(atan2(offset.x, -offset.y)))
