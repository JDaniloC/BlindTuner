extends GutTest

const JoystickScene := preload("res://scenes/DirectionJoystick.tscn")

func _make_joystick():
	var j = JoystickScene.instantiate()
	add_child_autofree(j)
	return j

func before_each():
	ColorSchemeSettings.reset_to_defaults()
	CueSettings.set_level(0)

func after_each():
	# reset_to_defaults() religa o interruptor de pistas junto com a paleta: é o
	# contrato que impede um teste de contaminar o próximo.
	ColorSchemeSettings.reset_to_defaults()
	# CueSettings é autoload e não se reseta sozinho: sem isto, um teste que sobe
	# o nível de pista vaza para os seguintes (deste arquivo e dos próximos). O
	# joystick não consulta mais o nível, mas há teste aqui que o sobe justamente
	# para provar que ele deixou de mandar nas fatias.
	CueSettings.set_level(0)

func test_vector_to_note_snaps_to_north():
	# No Godot 2D, Y aponta pra baixo. "Norte" no joystick = thumb pra cima = y negativo.
	var note = _make_joystick().vector_to_note(Vector2(0, -50))
	assert_eq(note, "C4")

func test_vector_to_note_snaps_to_east():
	# East (90°) = D4 no novo mapeamento contíguo
	var note = _make_joystick().vector_to_note(Vector2(50, 0))
	assert_eq(note, "D4")

func test_vector_to_note_snaps_to_south():
	# South (180°) = E4 no novo mapeamento contíguo
	var note = _make_joystick().vector_to_note(Vector2(0, 50))
	assert_eq(note, "E4")

func test_vector_to_note_snaps_to_west():
	# West (270°) = Fs4 no novo mapeamento contíguo
	var note = _make_joystick().vector_to_note(Vector2(-50, 0))
	assert_eq(note, "Fs4")

func test_zero_vector_returns_empty():
	assert_eq(_make_joystick().vector_to_note(Vector2.ZERO), "")

func test_slice_index_for_angle_zero():
	assert_eq(_make_joystick().slice_index_for_angle(0.0), 0)

func test_slice_index_for_angle_30():
	# 30° → Cs4 (índice 1) no novo mapeamento
	assert_eq(_make_joystick().slice_index_for_angle(30.0), 1)

func test_slice_index_for_angle_180():
	# 180° = E4 (cardinal sul no novo mapeamento). Índice da fatia = 4.
	assert_eq(_make_joystick().slice_index_for_angle(180.0), 4)

func test_slice_index_for_angle_wraps_360():
	assert_eq(_make_joystick().slice_index_for_angle(360.0), 0)

func test_slice_index_for_angle_negative_wraps():
	# -30° = 330°: mais próximo de G4 (315°, 15° away) que C4 (360°, 30° away). G4 = índice 7.
	assert_eq(_make_joystick().slice_index_for_angle(-30.0), 7)

func test_slice_color_uses_note_color_when_control_cues_are_on():
	var j = _make_joystick()
	assert_eq(j.slice_display_color("C4"), NoteMapping.color_for("C4"))

func test_slice_color_is_neutral_when_control_cues_are_off():
	ColorSchemeSettings.set_control_cues(false)
	var j = _make_joystick()
	assert_eq(j.slice_display_color("C4"), j.NEUTRAL_SLICE)

func test_slices_recolor_when_the_control_cues_switch_flips():
	# Vira o interruptor com o joystick JÁ VIVO: é o caminho do sinal, e o único
	# que pega a conexão de control_cues_changed estar faltando.
	var j = _make_joystick()
	ColorSchemeSettings.set_control_cues(false)
	assert_eq(Color(j._slice_polygons[0].color.r, j._slice_polygons[0].color.g, j._slice_polygons[0].color.b), j.NEUTRAL_SLICE)

func test_the_cue_level_no_longer_touches_the_slices():
	# A inversão: o nível de pista governa só o que o HUD conta sobre a nota
	# TOCADA. No "só som" as fatias continuam coloridas e nomeadas -- parece bug,
	# é o ponto da mudança.
	var j = _make_joystick()
	var i: int = j._slice_note_keys.find("C4")
	CueSettings.set_level(3)
	var pintada: Color = j._slice_polygons[i].color
	var esperada: Color = NoteMapping.color_for("C4")
	assert_eq(Color(pintada.r, pintada.g, pintada.b), Color(esperada.r, esperada.g, esperada.b),
		"no 'só som' a fatia continua com a cor da nota")
	assert_eq(j._slice_labels[i].text, NoteMapping.label_for("C4"),
		"no 'só som' a fatia continua nomeada")

func test_only_eight_slices_built():
	var j = _make_joystick()
	assert_eq(j._slice_polygons.size(), 8, "4 fatias mortas (ações) saem do círculo")

func test_slice_note_keys_are_movement_only():
	var j = _make_joystick()
	for k in j._slice_note_keys:
		assert_true(NoteMapping.is_movement_note(k), "%s deveria ser movement" % k)
		assert_false(NoteMapping.is_action_note(k), "%s não é ação" % k)

func test_vector_to_note_at_30deg_snaps_to_cs4():
	# 30° no layout direcional: Cs4 (45°, 15° away) vence C4 (0°, 30° away).
	var j = _make_joystick()
	var rad := deg_to_rad(30.0)
	var v := Vector2(sin(rad), -cos(rad)) * 50.0
	assert_eq(j.vector_to_note(v), "Cs4")

func test_vector_to_note_at_120deg_snaps_to_ds4():
	# 120° → Ds4 (135°, 15° away) vence D4 (90°, 30° away).
	var j = _make_joystick()
	var rad := deg_to_rad(120.0)
	var v := Vector2(sin(rad), -cos(rad)) * 50.0
	assert_eq(j.vector_to_note(v), "Ds4")

func test_slice_index_for_angle_is_fatia_index_0_to_7():
	# Layout direcional: 8 fatias a 45°. slice_index_for_angle retorna 0..7
	# usando o mesmo snap que vector_to_note (consistência highlight ↔ emit).
	var j = _make_joystick()
	var expected = [0, 1, 2, 3, 4, 5, 6, 7]
	for i in range(8):
		assert_eq(j.slice_index_for_angle(float(i * 45)), expected[i],
			"ângulo %d deveria mapear para fatia %d" % [i*45, expected[i]])

func test_eight_slices_cover_full_circle():
	# Nenhuma das 8 fatias é "gap" — todas representam direções.
	var j = _make_joystick()
	assert_eq(j._slice_polygons.size(), 8)
	for i in range(8):
		assert_true(NoteMapping.is_movement_note(j._slice_note_keys[i]))
	assert_eq(j._slice_note_keys, ["C4","Cs4","D4","Ds4","E4","F4","Fs4","G4"])

func test_each_slice_has_a_direction_icon():
	var j = _make_joystick()
	assert_eq(j._slice_icons.size(), 8, "uma seta por fatia de movimento")
	for icon in j._slice_icons:
		assert_not_null(icon._texture, "fatia sem textura de seta")

func test_slice_icons_point_to_correct_screen_direction():
	# Regressão: direction em NoteMapping é vetor de GRID isométrico, não
	# bússola de tela -- ver comentário em ActionIcon.ICON_FOR_DIRECTION.
	# C4 fica na fatia norte do joystick (índice 0) e deve exibir a seta
	# "north" (reto pra cima na tela); E4 é a fatia oposta (índice 4, sul)
	# e deve exibir "south".
	var j = _make_joystick()
	var c4_index: int = j._slice_note_keys.find("C4")
	var e4_index: int = j._slice_note_keys.find("E4")
	assert_eq(j._slice_icons[c4_index]._texture.resource_path, "res://assets/ui/icons/north.svg",
		"fatia da C4 (norte do joystick) deveria exibir a seta north")
	assert_eq(j._slice_icons[e4_index]._texture.resource_path, "res://assets/ui/icons/south.svg",
		"fatia da E4 (sul do joystick, oposta à C4) deveria exibir a seta south")

func test_each_slice_has_a_note_label():
	var j = _make_joystick()
	assert_eq(j._slice_labels.size(), 8, "um rótulo por fatia de movimento")

func test_labels_show_note_names_when_control_cues_are_on():
	var j = _make_joystick()
	for i in range(j._slice_labels.size()):
		assert_eq(j._slice_labels[i].text, NoteMapping.label_for(j._slice_note_keys[i]))

func test_labels_are_empty_when_the_control_cues_switch_is_flipped_off():
	var j = _make_joystick()
	ColorSchemeSettings.set_control_cues(false)  # sinal dispara com o joystick já vivo
	for lbl in j._slice_labels:
		assert_eq(lbl.text, "", "o nome é pista e some com o interruptor")

func test_labels_are_empty_when_built_with_the_control_cues_already_off():
	# Complemento do teste acima: lá o interruptor vira com o joystick vivo
	# (caminho do sinal); aqui ele já está desligado quando o joystick nasce
	# (caminho do _ready).
	ColorSchemeSettings.set_control_cues(false)
	var j = _make_joystick()
	for lbl in j._slice_labels:
		assert_eq(lbl.text, "")

func test_icons_stay_visible_even_when_the_control_cues_are_off():
	# Ícone é afordância, não pista: a seta diz a mesma coisa que a posição da
	# fatia já dizia, então não revela nada e fica sempre.
	ColorSchemeSettings.set_control_cues(false)
	var j = _make_joystick()
	for icon in j._slice_icons:
		assert_not_null(icon._texture)

func test_labels_do_not_steal_the_drag():
	var j = _make_joystick()
	for lbl in j._slice_labels:
		assert_eq(lbl.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_labels_draw_on_top_of_the_icons():
	# Em Node2D a ordem de filho é a ordem de desenho: o rótulo precisa entrar
	# depois do ícone, senão a seta cobre o nome.
	var j = _make_joystick()
	for i in range(8):
		assert_gt(j._slice_labels[i].get_index(), j._slice_icons[i].get_index(),
			"rótulo da fatia %d desenha antes do ícone" % i)

func test_label_sits_outside_the_icon_box():
	# Regressão de leitura: plantado no mesmo raio do ícone, o nome sairia por
	# cima da seta. O rótulo mora num anel mais externo que a caixa do ícone.
	var j = _make_joystick()
	for i in range(8):
		var lbl: Label = j._slice_labels[i]
		var icon: Control = j._slice_icons[i]
		var raio_do_rotulo := (lbl.position + lbl.size * 0.5).length()
		var raio_do_icone := (icon.position + icon.size * 0.5).length()
		assert_gt(raio_do_rotulo, raio_do_icone + icon.size.y * 0.5,
			"o nome da fatia %d cai dentro da caixa da seta" % i)

## Os 4 cantos da caixa do rótulo, em coordenadas de _slices_root (centro = 0,0).
## Medir o centro, ou a aresta radial, é medir onde o rótulo NÃO corta primeiro:
## numa caixa de 60x37 plantada a 45°, o canto chega 24px mais longe que a aresta
## que os testes antigos olhavam.
func _cantos_do_rotulo(lbl: Label) -> Array[Vector2]:
	return [
		lbl.position,
		lbl.position + Vector2(lbl.size.x, 0.0),
		lbl.position + Vector2(0.0, lbl.size.y),
		lbl.position + lbl.size,
	]

func test_labels_are_centred_on_their_slice_anchor():
	# A caixa DECLARADA é 60x36, mas o Label é clampado no mínimo combinado
	# (linha de fonte + contorno) e mede 60x37: centrar por LABEL_SIZE_FRAC em vez
	# de pelo tamanho real deixava o rótulo meio pixel fora de centro, e o desvio
	# cresce em (size - box)/2 a cada aumento de RADIUS, de LABEL_FONT_FRAC ou da
	# fonte do sistema por acessibilidade.
	var j = _make_joystick()
	for i in range(8):
		var lbl: Label = j._slice_labels[i]
		var centro: Vector2 = lbl.position + lbl.size * 0.5
		var ancora: Vector2 = j._slice_anchor(i, j.LABEL_RADIUS_FRAC)
		assert_almost_eq((centro - ancora).length(), 0.0, 0.001,
			"o nome da fatia %d nasce %.2fpx fora do centro da âncora" % [i, (centro - ancora).length()])

func test_labels_stay_inside_the_joystick_disc():
	# Fora do disco o nome fica sobre o cenário e some. Mede os 4 CANTOS: a versão
	# anterior comparava `raio + altura/2` (114) contra o disco (138) enquanto o
	# canto real chegava a 130,9 -- 24px de folga fantasma. Com LABEL_RADIUS_FRAC
	# em 0,87 o canto sai do disco e aquele teste continuava verde.
	var j = _make_joystick()
	var limite: float = j.RADIUS + j.BACKDROP_OVERHANG
	for i in range(8):
		for canto in _cantos_do_rotulo(j._slice_labels[i]):
			assert_lte(canto.length(), limite,
				"o canto %s do nome da fatia %d cai a %.1fpx do centro, fora do disco de %.1f" % [
					canto, i, canto.length(), limite])

func test_labels_do_not_bleed_into_the_neighbouring_slice():
	# A fatia é uma cunha de 45° e a caixa do rótulo é alinhada à TELA, não à
	# cunha: nas 4 fatias diagonais ela entra torta, e quem encosta na fronteira é
	# um canto, não a meia-largura no raio do centro (o que a versão anterior
	# media, concedendo folga fantasma pelo mesmo motivo do teste acima).
	var j = _make_joystick()
	var meia_cunha: float = j.SLICE_ANGLE_DEG * 0.5
	for i in range(8):
		var ang_do_centro: float = i * j.SLICE_ANGLE_DEG
		for canto in _cantos_do_rotulo(j._slice_labels[i]):
			# Mesma convenção de _slice_anchor: 0° = Norte da tela (-y).
			var ang: float = rad_to_deg(atan2(canto.x, -canto.y))
			var desvio: float = absf(wrapf(ang - ang_do_centro, -180.0, 180.0))
			assert_lte(desvio, meia_cunha,
				"o canto %s do nome da fatia %d está a %.1f° do eixo, fora da cunha de ±%.1f°" % [
					canto, i, desvio, meia_cunha])

func test_labels_repaint_when_scheme_changes():
	# O texto some/volta pelo mesmo caminho que repinta as fatias; trocar o
	# esquema não pode zerar o nome de tabela.
	var j = _make_joystick()
	ColorSchemeSettings.set_scheme("alto_contraste")
	for i in range(j._slice_labels.size()):
		assert_eq(j._slice_labels[i].text, NoteMapping.label_for(j._slice_note_keys[i]))

func test_derived_constants_track_the_radius():
	# Regressão: com DEAD_ZONE fixa, crescer o raio encolhe a zona morta em
	# proporção e um micro-arrasto passa a disparar direção -- justo o que o
	# público de baixa visão não aguenta.
	var J = load("res://scripts/DirectionJoystick.gd")
	assert_almost_eq(J.BACKDROP_OVERHANG / J.RADIUS, 0.24, 0.01)
	assert_almost_eq(J.DEAD_ZONE / J.RADIUS, 0.1875, 0.01)
	assert_almost_eq(J.THUMB_RADIUS / J.RADIUS, 0.35, 0.01)

func test_minimum_size_covers_the_drawn_reach():
	# O alcance desenhado é RADIUS+THUMB_RADIUS (o thumb é clampado no raio e
	# desenha o próprio raio além disso), não RADIUS+BACKDROP_OVERHANG.
	var j = _make_joystick()
	var alcance: float = (j.RADIUS + j.THUMB_RADIUS) * 2.0
	assert_gte(j.custom_minimum_size.x, alcance)
	assert_gte(j.custom_minimum_size.y, alcance)

func test_slices_root_is_centered_on_the_actual_size():
	# A geometria de toque usa size/2 e a de desenho usava uma posição fixa no
	# .tscn; coincidiam por acidente. Agora ambas saem da mesma fonte.
	var j = _make_joystick()
	assert_eq(j._slices_root.position, j.size / 2.0)
	assert_eq(j._thumb.position, j.size / 2.0)

func test_geometry_follows_a_resize_from_the_layout_pass():
	# Como filho do CanvasLayer, o tamanho real vem dos offsets do Playground.tscn
	# e só chega DEPOIS do _ready(). Centro congelado no valor do _ready deixaria
	# o desenho fora do alvo de toque.
	var j = _make_joystick()
	j.size = Vector2(400, 400)
	assert_eq(j._slices_root.position, Vector2(200, 200))
	assert_eq(j._thumb.position, Vector2(200, 200))

func test_icons_scale_with_the_radius():
	var j = _make_joystick()
	for icon in j._slice_icons:
		assert_gt(icon.size.x, 30.0, "ícone de tamanho fixo não acompanha o joystick maior")
		assert_gt(icon.size.y, 30.0)

func test_slices_repaint_when_scheme_changes():
	# A versão anterior lia slice_display_color(), que é função PURA (consulta o
	# esquema ativo na hora): passava mesmo com a conexão de scheme_changed
	# apagada, ou seja, com o defeito que ela deveria cobrir presente. Agora lê a
	# cor do polígono DESENHADO.
	var j = _make_joystick()
	var i: int = j._slice_note_keys.find("C4")
	assert_gte(i, 0, "pré-condição: o Dó ocupa uma fatia do joystick")
	var antes: Color = j._slice_polygons[i].color
	ColorSchemeSettings.set_scheme("alto_contraste")
	var depois: Color = j._slice_polygons[i].color
	# O alfa é gerido por _refresh_slice_alphas (fatia ativa/inativa); só o RGB
	# vem do esquema de cor.
	var esperado: Color = ColorSchemes.colors_for("alto_contraste")[0]
	assert_ne(Color(antes.r, antes.g, antes.b), Color(depois.r, depois.g, depois.b),
		"a fatia desenhada precisa mudar de cor com o esquema")
	assert_almost_eq(depois.r, esperado.r, 0.001)
	assert_almost_eq(depois.g, esperado.g, 0.001)
	assert_almost_eq(depois.b, esperado.b, 0.001)
