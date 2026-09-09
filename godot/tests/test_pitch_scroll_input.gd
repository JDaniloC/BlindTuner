extends GutTest

const PitchScrollScene := preload("res://scenes/PitchScrollInput.tscn")

func _make() -> Node:
	var p = PitchScrollScene.instantiate()
	add_child_autofree(p)
	return p

func after_each():
	AudioManager.stop_continuous_pitch()

func test_lowest_and_highest_frequency_cover_all_twelve_notes():
	var p = _make()
	assert_eq(p._lowest_frequency(), 262.0)  # C4
	assert_eq(p._highest_frequency(), 494.0)  # B4

func test_move_finger_to_top_plays_highest_frequency():
	var p = _make()
	p._move_finger_to(p.NECK_TOP + p.BOARD_MARGIN.y)
	assert_eq(AudioManager._pitch_freq, p._highest_frequency())

func test_move_finger_to_bottom_plays_lowest_frequency():
	var p = _make()
	p._move_finger_to(p.BOARD_SIZE.y - p.BOARD_MARGIN.y)
	assert_eq(AudioManager._pitch_freq, p._lowest_frequency())

func test_move_finger_plays_continuous_pitch():
	var p = _make()
	p._move_finger_to(100.0)
	assert_not_null(AudioManager._pitch_player)

func test_drag_ended_resolves_nearest_note_and_emits():
	var p = _make()
	watch_signals(p)
	var usable_height = (p.BOARD_SIZE.y - p.BOARD_MARGIN.y) - (p.NECK_TOP + p.BOARD_MARGIN.y)
	var t = (p._highest_frequency() - 440.0) / (p._highest_frequency() - p._lowest_frequency())
	p._move_finger_to(p.NECK_TOP + p.BOARD_MARGIN.y + t * usable_height)
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

func test_lowest_note_is_reachable_at_the_bottom_of_the_touch_area():
	# O ponto mais baixo que o dedo consegue tocar tem que dar a nota mais grave:
	# se a área de toque acabasse antes do fim do braço desenhado, o jogador
	# nunca alcançaria o grave.
	var p = _make()
	await wait_frames(1)
	p._move_finger_to(p.size.y)
	assert_almost_eq(AudioManager._pitch_freq, p._lowest_frequency(), 0.5)

func test_board_fits_the_free_corridor_below_the_note_panel():
	# Corredor medido no viewport de projeto: o NotePanel termina em y=240 e a
	# tela em y=1280, ou seja 1040px. O braço tem que caber lá com folga.
	var p = _make()
	var altura_tela: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	assert_lte(p.BOARD_SIZE.y, float(altura_tela) - 240.0,
		"o braço não cabe no corredor livre abaixo do NotePanel")

func test_still_has_no_fret_markers():
	# Regressão: braço fretless é decisão de design (violino/cello não têm
	# traste, e marcar posição entregaria a nota, que é o desafio do jogo).
	var src = FileAccess.get_file_as_string("res://scripts/PitchScrollInput.gd")
	assert_false(src.to_lower().contains("fret_dot"), "não pode ter marcador de traste")
	assert_false(src.to_lower().contains("marker_positions"), "não pode ter marcação de posição")
