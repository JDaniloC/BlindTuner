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
	ColorSchemeSettings.reset_to_defaults()
	# CueSettings é autoload e não se reseta sozinho: sem isto, um teste que sobe
	# o nível de pista vaza para os seguintes (deste arquivo e dos próximos).
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

func test_slice_color_uses_note_color_when_cue_shows_color():
	CueSettings.set_level(0)
	var j = _make_joystick()
	assert_eq(j.slice_display_color("C4"), NoteMapping.color_for("C4"))
	CueSettings.set_level(0)

func test_slice_color_neutral_at_level_three():
	CueSettings.set_level(3)
	var j = _make_joystick()
	assert_eq(j.slice_display_color("C4"), j.NEUTRAL_SLICE)
	CueSettings.set_level(0)

func test_slices_recolor_on_cue_level_changed():
	CueSettings.set_level(0)
	var j = _make_joystick()
	CueSettings.set_level(3)  # sinal dispara com joystick já vivo
	assert_eq(Color(j._slice_polygons[0].color.r, j._slice_polygons[0].color.g, j._slice_polygons[0].color.b), j.NEUTRAL_SLICE)
	CueSettings.set_level(0)

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

func test_labels_show_note_names_at_cue_level_zero():
	CueSettings.set_level(0)
	var j = _make_joystick()
	for i in range(j._slice_labels.size()):
		assert_eq(j._slice_labels[i].text, NoteMapping.label_for(j._slice_note_keys[i]))

func test_labels_are_empty_when_cue_hides_names():
	CueSettings.set_level(0)
	var j = _make_joystick()
	CueSettings.set_level(3)  # sinal dispara com o joystick já vivo
	for lbl in j._slice_labels:
		assert_eq(lbl.text, "", "o nome é identidade e some nos níveis avançados")

func test_labels_are_empty_when_built_with_names_already_hidden():
	# Complemento do teste acima: lá o nível muda com o joystick vivo (caminho do
	# sinal); aqui ele já está alto quando o joystick nasce (caminho do _ready).
	CueSettings.set_level(3)
	var j = _make_joystick()
	for lbl in j._slice_labels:
		assert_eq(lbl.text, "")

func test_icons_stay_visible_even_when_names_are_hidden():
	# Ícone é afordância, não identidade: a seta diz a mesma coisa que a
	# posição da fatia já dizia, então não revela nada e fica sempre.
	CueSettings.set_level(3)
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

func test_labels_stay_inside_the_joystick_disc():
	# Fora do disco o nome fica sobre o cenário e some. Mede a borda externa do
	# rótulo no sentido radial, que é onde o disco realmente corta.
	var j = _make_joystick()
	for i in range(8):
		var lbl: Label = j._slice_labels[i]
		var raio := (lbl.position + lbl.size * 0.5).length()
		assert_lte(raio + lbl.size.y * 0.5, j.RADIUS + j.BACKDROP_OVERHANG,
			"o nome da fatia %d vaza do disco do joystick" % i)

func test_labels_do_not_bleed_into_the_neighbouring_slice():
	# A fatia é uma cunha: quanto mais longe do centro, mais larga. O rótulo
	# precisa caber na largura da cunha no raio em que foi plantado, senão o
	# nome de uma direção invade a fatia da direção vizinha.
	var j = _make_joystick()
	for i in range(8):
		var lbl: Label = j._slice_labels[i]
		var raio := (lbl.position + lbl.size * 0.5).length()
		var meia_largura_da_fatia: float = raio * tan(deg_to_rad(j.SLICE_ANGLE_DEG * 0.5))
		assert_lte(lbl.size.x * 0.5, meia_largura_da_fatia,
			"o nome da fatia %d encosta na fatia vizinha" % i)

func test_labels_repaint_when_scheme_changes():
	# O texto some/volta pelo mesmo caminho que repinta as fatias; trocar o
	# esquema não pode zerar o nome de tabela.
	CueSettings.set_level(0)
	var j = _make_joystick()
	ColorSchemeSettings.set_scheme("alto_contraste")
	for i in range(j._slice_labels.size()):
		assert_eq(j._slice_labels[i].text, NoteMapping.label_for(j._slice_note_keys[i]))

func test_derived_constants_track_the_radius():
	# Regressão: com DEAD_ZONE fixa, crescer o raio encolhe a zona morta em
	# proporção e um micro-arrasto passa a disparar direção -- justo o que o
	# público de baixa visão não aguenta.
	var J = load("res://scripts/DirectionJoystick.gd")
	assert_almost_eq(J.BACKDROP_OVERHANG / J.RADIUS, 0.15, 0.01)
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
	CueSettings.set_level(0)
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
