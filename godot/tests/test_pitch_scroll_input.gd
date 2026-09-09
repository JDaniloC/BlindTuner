extends GutTest

const PitchScrollScene := preload("res://scenes/PitchScrollInput.tscn")
const ColorDistance := preload("res://scripts/ColorDistance.gd")

func _make() -> Node:
	var p = PitchScrollScene.instantiate()
	add_child_autofree(p)
	return p

func before_each():
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	AudioManager.stop_continuous_pitch()
	# O braço não consulta o nível de pista, mas há teste aqui que o sobe
	# justamente para provar isso -- e CueSettings é autoload, não se reseta
	# sozinho. reset_to_defaults() religa o interruptor de pistas junto.
	CueSettings.set_level(0)
	ColorSchemeSettings.reset_to_defaults()

func test_lowest_and_highest_frequency_cover_all_twelve_notes():
	var p = _make()
	assert_eq(p._lowest_frequency(), 262.0)  # C4
	assert_eq(p._highest_frequency(), 494.0)  # B4

func test_move_finger_to_top_plays_lowest_frequency():
	# Sentido de instrumento de verdade: a pestana fica no topo e a corda solta
	# ali é a nota mais GRAVE. Descer o dedo em direção ao cavalete encurta o
	# trecho que vibra e SOBE a nota.
	var p = _make()
	p._move_finger_to(p.NECK_TOP + p.BOARD_MARGIN.y)
	assert_eq(AudioManager._pitch_freq, p._lowest_frequency())

func test_move_finger_to_bottom_plays_highest_frequency():
	var p = _make()
	p._move_finger_to(p.BOARD_SIZE.y - p.BOARD_MARGIN.y)
	assert_eq(AudioManager._pitch_freq, p._highest_frequency())

func test_move_finger_plays_continuous_pitch():
	var p = _make()
	p._move_finger_to(100.0)
	assert_not_null(AudioManager._pitch_player)

func test_drag_ended_resolves_nearest_note_and_emits():
	# Usa a inversa de produção de propósito: se o teste refizesse a conta à mão,
	# a fórmula ficaria duplicada e ele deixaria de vigiar a de verdade.
	var p = _make()
	watch_signals(p)
	p._move_finger_to(p._y_for_frequency(440.0))
	p._on_drag_ended()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["A4"])

func test_drag_ended_stops_continuous_pitch():
	var p = _make()
	p._move_finger_to(100.0)
	p._on_drag_ended()
	assert_null(AudioManager._pitch_player)

func test_finger_y_clamped_within_board_margins():
	var p = _make()
	p._move_finger_to(-50.0)
	assert_eq(p._finger_y, p.NECK_TOP + p.BOARD_MARGIN.y)
	p._move_finger_to(9999.0)
	assert_eq(p._finger_y, p.BOARD_SIZE.y - p.BOARD_MARGIN.y)

## Distância em pixels entre cada par de notas vizinhas, do grave pro agudo.
func _semitone_gaps(p) -> Array:
	var ys: Array = []
	for key in NoteMapping.NOTES:
		ys.append(p._y_for_frequency(float(NoteMapping.NOTES[key]["freq"])))
	ys.sort()
	var gaps: Array = []
	for i in range(ys.size() - 1):
		gaps.append(ys[i + 1] - ys[i])
	return gaps

func test_note_spacing_shrinks_from_the_nut_to_the_bridge():
	# Geometria de corda: a frequência é inversamente proporcional ao comprimento
	# que vibra, então os semitons vão se apertando conforme o dedo desce. O
	# mapeamento linear em frequência que existia antes fazia o oposto exato.
	# A tolerância de 1px existe porque as frequências do NoteMapping são inteiros
	# arredondados, não temperamento igual exato: Dó->Dó# vale 15Hz e Dó#->Ré vale
	# 17Hz, o que deixa esse único par 0,8px fora da ordem.
	var p = _make()
	var gaps := _semitone_gaps(p)
	assert_eq(gaps.size(), 11, "12 notas dão 11 intervalos")
	assert_gt(gaps[0], gaps[gaps.size() - 1], "o grave tem que ser mais largo que o agudo")
	for i in range(gaps.size() - 1):
		assert_gt(gaps[i] + 1.0, gaps[i + 1],
			"intervalo %d (%.1fpx) devia ser >= o %d (%.1fpx)" % [i, gaps[i], i + 1, gaps[i + 1]])

func test_note_spacing_matches_real_string_geometry():
	# Números da conta x = L * (1 - f_grave/f) normalizada no braço útil de 659px.
	var p = _make()
	var gaps := _semitone_gaps(p)
	var largest: float = gaps.max()
	var smallest: float = gaps.min()
	assert_almost_eq(largest, 76.7, 0.5, "semitom mais largo, lá no grave")
	assert_almost_eq(smallest, 44.7, 0.5, "semitom mais estreito, lá no agudo")
	assert_almost_eq(largest / smallest, 1.716, 0.02, "razão grave/agudo de uma corda de verdade")

func test_narrowest_semitone_is_still_a_touchable_target():
	# A única objeção real contra a geometria autêntica era acessibilidade: se o
	# semitom mais estreito ficasse abaixo do alvo mínimo de toque, o público de
	# baixa visão não acertaria o agudo. Ele não fica.
	var p = _make()
	var gaps := _semitone_gaps(p)
	assert_gte(gaps.min(), 44.0, "semitom mais estreito abaixo do alvo mínimo de toque")

func test_every_note_round_trips_from_its_own_y():
	# y -> frequência -> nota tem que fechar nas 12: é o que garante que a fitinha
	# (Task 3) vai marcar o lugar onde a nota realmente soa.
	var p = _make()
	for key in NoteMapping.NOTES:
		var freq := float(NoteMapping.NOTES[key]["freq"])
		p._move_finger_to(p._y_for_frequency(freq))
		assert_almost_eq(p._frequency_for_finger_y(), freq, 0.01, key)
		assert_eq(NoteMapping.nearest_note_for_frequency(p._frequency_for_finger_y()), key, key)

func test_y_for_frequency_is_the_exact_inverse_of_the_finger_mapping():
	var p = _make()
	for y in [111.0, 200.0, 435.5, 600.0, 770.0]:
		p._move_finger_to(y)
		assert_almost_eq(p._y_for_frequency(p._frequency_for_finger_y()), y, 0.001,
			"round-trip do y %.1f" % y)

func test_exit_tree_stops_continuous_pitch():
	# Regressão: o tom contínuo só parava ao soltar o dedo (_on_drag_ended).
	# Se o nó sai da árvore com o tom ainda tocando (ex: arrasto em progresso
	# quando o jogo troca de preset/cena), o tom não pode ficar tocando pra
	# sempre. Não usa add_child_autofree aqui de propósito -- precisa liberar
	# manualmente pra observar _exit_tree() rodar de forma síncrona.
	var p = PitchScrollScene.instantiate()
	add_child(p)
	p._move_finger_to(100.0)
	assert_not_null(AudioManager._pitch_player)
	p.free()
	assert_null(AudioManager._pitch_player)

func test_board_has_four_strings_with_one_active():
	var p = _make()
	assert_eq(p.STRING_OFFSETS_X.size(), 4, "violino/cello tem 4 cordas")
	assert_true(p.ACTIVE_STRING_INDEX >= 0 and p.ACTIVE_STRING_INDEX < 4)

func test_touch_area_matches_the_drawn_board():
	# Regressão: o braço é desenhado de 0 até BOARD_SIZE em coordenadas locais,
	# mas _gui_input só recebe evento dentro do rect do nó. Se o rect não cobrir
	# o desenho inteiro, a parte de baixo do braço vira zona morta ao toque.
	# O await é obrigatório: custom_minimum_size só vira size no passe de layout
	# do frame seguinte -- sem ele, size ainda é (0,0).
	var p = _make()
	await wait_frames(1)
	assert_eq(p.size, p.BOARD_SIZE, "área de toque precisa cobrir o braço inteiro")

func test_highest_note_is_reachable_at_the_bottom_of_the_touch_area():
	# O ponto mais baixo que o dedo consegue tocar tem que dar a nota mais aguda:
	# se a área de toque acabasse antes do fim do braço desenhado, o jogador
	# nunca alcançaria o agudo.
	var p = _make()
	await wait_frames(1)
	p._move_finger_to(p.size.y)
	assert_almost_eq(AudioManager._pitch_freq, p._highest_frequency(), 0.5)

func test_board_fits_the_free_corridor_below_the_note_panel():
	# Corredor medido no viewport de projeto: o NotePanel termina em y=240 e a
	# tela em y=1280, ou seja 1040px. O braço tem que caber lá com folga.
	var p = _make()
	var altura_tela: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	assert_lte(p.BOARD_SIZE.y, float(altura_tela) - 240.0,
		"o braço não cabe no corredor livre abaixo do NotePanel")

func test_still_has_no_fret_markers():
	# Regressão: braço fretless é decisão de design (violino/cello não têm
	# traste). As fitinhas NÃO são traste: um traste é relevo fixo, sempre lá; a
	# fita é material didático opcional que some com o interruptor de pistas --
	# ver test_tapes_vanish_when_control_cues_are_off, que é o teste que sustenta
	# a diferença.
	var src = FileAccess.get_file_as_string("res://scripts/PitchScrollInput.gd")
	assert_false(src.to_lower().contains("fret_dot"), "não pode ter marcador de traste")
	assert_false(src.to_lower().contains("marker_positions"), "não pode ter marcação de posição")

## A fitinha de uma nota. _tapes() devolve na ordem cromática de NoteMapping.
func _tape_for(p, note_key: String) -> Dictionary:
	var tapes: Array = p._tapes()
	var idx: int = NoteMapping.NOTES.keys().find(note_key)
	return tapes[idx]

func test_one_tape_per_note_marks_where_the_note_sounds():
	# A fita só serve se marcar o lugar onde a nota REALMENTE soa: tem que sair da
	# mesma conta do braço (_y_for_frequency), não de uma segunda régua.
	var p = _make()
	assert_eq(p._tapes().size(), 12, "uma fitinha por nota")
	for key in NoteMapping.NOTES:
		var r: Rect2 = _tape_for(p, key)["rect"]
		var y: float = p._y_for_frequency(float(NoteMapping.NOTES[key]["freq"]))
		assert_between(y, r.position.y, r.end.y, "a fita de %s tem que conter o y da nota" % key)

func test_tape_center_is_the_note_position():
	var p = _make()
	for key in ["Cs4", "E4", "G4", "As4"]:
		var r: Rect2 = _tape_for(p, key)["rect"]
		var y: float = p._y_for_frequency(float(NoteMapping.NOTES[key]["freq"]))
		assert_almost_eq(r.size.y, p.TAPE_HEIGHT, 0.001, key)
		assert_almost_eq(r.get_center().y, y, 0.001, key)

func test_extreme_tapes_are_trimmed_instead_of_pushed_inwards():
	# Dó e Si caem EXATAMENTE nas bordas da faixa alcançável, então metade de cada
	# fita extrema cairia fora do braço útil. Aparar o retângulo mantém o centro
	# verdadeiro e perde só desenho; recuar a fita pra dentro a faria mentir sobre
	# onde a nota está, que é pior.
	var p = _make()
	var grave: Rect2 = _tape_for(p, "C4")["rect"]
	var agudo: Rect2 = _tape_for(p, "B4")["rect"]
	assert_almost_eq(grave.position.y, p._neck_usable_top(), 0.001,
		"a fita mais grave não pode passar do topo do braço útil")
	assert_almost_eq(grave.end.y, p._y_for_frequency(p._lowest_frequency()) + p.TAPE_HEIGHT * 0.5, 0.001,
		"só a metade de cima é aparada -- a de baixo fica onde estava")
	assert_almost_eq(agudo.end.y, p._neck_usable_bottom(), 0.001,
		"a fita mais aguda não pode passar da base do braço útil")
	assert_almost_eq(agudo.position.y, p._y_for_frequency(p._highest_frequency()) - p.TAPE_HEIGHT * 0.5, 0.001,
		"só a metade de baixo é aparada")

func test_tapes_span_the_neck_and_never_bleed_over_the_background():
	# O nó não tem clip_contents: usar a largura do board (150px) em vez da do
	# braço (84px) pintaria 33px de cor de cada lado, sobre fundo transparente.
	var p = _make()
	var esquerda: float = p.BOARD_SIZE.x * 0.5 - p.NECK_WIDTH * 0.5
	for t in p._tapes():
		var r: Rect2 = t["rect"]
		assert_almost_eq(r.position.x, esquerda, 0.001, "a fita começa na borda esquerda do braço")
		assert_almost_eq(r.size.x, p.NECK_WIDTH, 0.001, "a fita tem a largura do braço, não a do board")

func test_tapes_vanish_when_control_cues_are_off():
	# É a opcionalidade que reconcilia a fita com o braço fretless: desligado o
	# interruptor, sobra o instrumento autêntico e liso.
	ColorSchemeSettings.set_control_cues(false)
	var p = _make()
	assert_eq(p._tapes().size(), 0, "sem pistas nos controles, sem fitinha")

func test_toggling_control_cues_repaints_without_restarting():
	# Aqui o desenho é _draw(), não StyleBox: "repintar na hora" significa o nó
	# escutar o interruptor e agendar o redraw. Sem esta conexão as fitas só
	# sumiriam na próxima vez que algo repintasse o braço -- na prática, ao
	# reiniciar a fase.
	var p = _make()
	assert_true(ColorSchemeSettings.control_cues_changed.is_connected(p._on_control_cues_changed),
		"o braço tem que escutar o interruptor de pistas")
	assert_eq(p._tapes().size(), 12)
	ColorSchemeSettings.set_control_cues(false)
	assert_eq(p._tapes().size(), 0, "virar o interruptor tem que tirar as fitas na hora")

func test_tape_color_follows_the_active_scheme():
	# A fita usa a cor da nota no esquema ativo, e por isso herda de graça os três
	# esquemas fixos e o editor de paleta livre.
	var p = _make()
	assert_true(ColorSchemeSettings.scheme_changed.is_connected(p._on_scheme_changed),
		"o braço tem que escutar a troca de esquema")
	var antes: Color = _tape_for(p, "C4")["color"]
	ColorSchemeSettings.set_scheme("alto_contraste")
	var depois: Color = _tape_for(p, "C4")["color"]
	assert_eq(depois, NoteMapping.color_for("C4"), "a fita usa a cor da nota no esquema ativo")
	assert_ne(depois, antes, "trocar de esquema tem que repintar as fitas")

func test_the_wood_colour_comes_from_the_same_gradient_the_neck_draws():
	# A fita é medida contra a madeira, então a madeira precisa vir da MESMA conta
	# que o _draw() usa pra pintar as faixas -- senão o teste de contraste abaixo
	# mede contra um braço imaginário.
	var p = _make()
	assert_eq(p._wood_color_at(p.NECK_TOP), p.BOARD_COLOR_TOP,
		"no topo do braço a madeira é a cor de cima do gradiente")
	assert_eq(p._wood_color_at(p.BOARD_SIZE.y - 1.0), p.BOARD_COLOR_BOTTOM,
		"na base é a de baixo")
	assert_eq(p._wood_color_at(p.NECK_TOP - 999.0), p.BOARD_COLOR_TOP,
		"acima do braço o índice satura em vez de estourar o array")

func test_every_tape_stands_out_from_the_wood_in_every_scheme():
	# Terceira ocorrência do mesmo modo de falha (as duas primeiras foram o glifo
	# do botão e o nome da placa): elemento colorido do esquema pintado direto
	# sobre fundo escuro, sem ninguém medir o contraste.
	#
	# Medido ANTES da moldura, com a fita chapada na cor da nota: 9 das 36
	# combinações fitinha x esquema abaixo dos 3:1 do WCAG pra elemento gráfico --
	# Dó 1,59:1 e Dó# 2,74:1 no esquema de FÁBRICA (as duas primeiras posições, as
	# que um professor de violino cola primeiro), Dó 1,48:1 / Dó# 2,17:1 / Ré
	# 2,26:1 no Alto Contraste (que existe justamente pra baixa visão), e Dó#
	# 1,81:1 / Fá 1,91:1 / Lá# 2,20:1 / Sol 2,49:1 no Clássico. E as piores caem no
	# TOPO do braço, onde a madeira é mais clara.
	#
	# A asserção é sobre a fita inteira (moldura OU miolo), não só sobre a
	# moldura: é assim que ela continua reprovando se alguém tirar a moldura, e é
	# a pergunta que importa -- "dá pra achar esta fita no braço?".
	var p = _make()
	var keys: Array = NoteMapping.NOTES.keys()
	for esquema in ColorSchemes.SCHEME_IDS:
		ColorSchemeSettings.set_scheme(esquema)
		var tapes: Array = p._tapes()
		assert_eq(tapes.size(), 12, esquema)
		for i in range(tapes.size()):
			var madeira: Color = tapes[i]["wood"]
			var miolo: float = ColorDistance.contrast_ratio(tapes[i]["color"], madeira)
			var moldura: float = ColorDistance.contrast_ratio(tapes[i]["edge"], madeira)
			assert_gte(maxf(miolo, moldura), 3.0,
				"a fita de %s no esquema %s dá %.2f:1 contra a madeira (miolo %.2f:1)"
					% [keys[i], esquema, maxf(miolo, moldura), miolo])

func test_the_tape_edge_ink_is_picked_by_the_wood_under_it():
	# Mesma regra do glifo do piano e do nome da placa, e pela mesma razão: a
	# tinta sai da LUMINÂNCIA do fundo, não de uma constante escrita à mão. Se a
	# madeira do braço clarear um dia, a moldura vira escura sozinha em vez de
	# reabrir o buraco em silêncio.
	var p = _make()
	for t in p._tapes():
		assert_eq(t["edge"], ColorDistance.icon_tint_for(t["wood"]),
			"a moldura tem que sair da regra compartilhada de tinta")

func test_the_tape_core_keeps_the_note_colour_centred_inside_the_edge():
	# A moldura não pode mover nem estreitar a marca: o miolo colorido continua
	# centrado no mesmo y, e o retângulo externo (que é o que os outros testes
	# medem) continua sendo a fita inteira.
	var p = _make()
	var keys: Array = NoteMapping.NOTES.keys()
	var tapes: Array = p._tapes()
	for i in range(tapes.size()):
		var fora: Rect2 = tapes[i]["rect"]
		var miolo: Rect2 = tapes[i]["core"]
		assert_true(fora.encloses(miolo), "o miolo de %s tem que caber na moldura" % keys[i])
		assert_almost_eq(miolo.get_center().y, fora.get_center().y, 0.001, keys[i])
		assert_gt(miolo.size.y, 0.0, "o miolo de %s não pode sumir" % keys[i])
		assert_almost_eq(miolo.size.x, p.NECK_WIDTH - p.TAPE_EDGE * 2.0, 0.001, keys[i])

func test_the_cue_level_does_not_touch_the_tapes():
	# A mesma consequência deliberada do piano e do joystick: no nível "só som",
	# com o interruptor ligado, as fitas CONTINUAM lá. O desafio é reconhecer a
	# nota tocada de ouvido, não adivinhar onde ela mora no braço.
	CueSettings.set_level(3)
	var p = _make()
	assert_eq(p._tapes().size(), 12, "o nível de pista governa a nota tocada, não o controle")
