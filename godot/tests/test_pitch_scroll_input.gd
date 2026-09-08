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

func test_still_has_no_fret_markers():
	# Regressão: braço fretless é decisão de design (violino/cello não têm
	# traste, e marcar posição entregaria a nota, que é o desafio do jogo).
	var src = FileAccess.get_file_as_string("res://scripts/PitchScrollInput.gd")
	assert_false(src.to_lower().contains("fret_dot"), "não pode ter marcador de traste")
	assert_false(src.to_lower().contains("marker_positions"), "não pode ter marcação de posição")
