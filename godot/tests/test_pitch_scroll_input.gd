extends GutTest

const PitchScrollScene := preload("res://scenes/PitchScrollInput.tscn")

func _make() -> Node:
	var p = PitchScrollScene.instantiate()
	add_child_autofree(p)
	return p

func after_each():
	AudioManager.stop_continuous_pitch()

func test_slider_range_covers_all_twelve_notes():
	var p = _make()
	assert_eq(p._slider.min_value, 262.0)  # C4
	assert_eq(p._slider.max_value, 494.0)  # B4

func test_value_changed_plays_continuous_pitch():
	var p = _make()
	p._on_value_changed(440.0)
	assert_not_null(AudioManager._pitch_player)

func test_drag_ended_resolves_nearest_note_and_emits():
	var p = _make()
	watch_signals(p)
	p._slider.value = 440.0
	p._on_drag_ended(true)
	assert_signal_emitted_with_parameters(p, "note_triggered", ["A4"])

func test_drag_ended_stops_continuous_pitch():
	var p = _make()
	p._on_value_changed(440.0)
	p._on_drag_ended(true)
	assert_null(AudioManager._pitch_player)

func test_drag_ended_off_note_resolves_to_nearest():
	var p = _make()
	watch_signals(p)
	p._slider.value = 270.0  # entre C4(262) e Cs4(277), mais perto de Cs4
	p._on_drag_ended(true)
	assert_signal_emitted_with_parameters(p, "note_triggered", ["Cs4"])

func test_exit_tree_stops_continuous_pitch():
	# Regressão: o tom contínuo só parava ao soltar o slider (_on_drag_ended).
	# Se o nó sai da árvore com o tom ainda tocando (ex: arrasto em progresso
	# quando o jogo troca de preset/cena), o tom não pode ficar tocando pra
	# sempre. Não usa add_child_autofree aqui de propósito -- precisa liberar
	# manualmente pra observar _exit_tree() rodar de forma síncrona.
	var p = PitchScrollScene.instantiate()
	add_child(p)
	p._on_value_changed(440.0)
	assert_not_null(AudioManager._pitch_player)
	p.free()
	assert_null(AudioManager._pitch_player)
