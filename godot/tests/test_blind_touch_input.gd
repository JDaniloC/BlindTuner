extends GutTest

const BlindTouchScene := preload("res://scenes/BlindTouchInput.tscn")

func _make() -> Node:
	var b = BlindTouchScene.instantiate()
	add_child_autofree(b)
	return b

func test_classify_gesture_drag_above_threshold_returns_direction_note():
	var b = _make()
	assert_eq(b._classify_gesture(true, Vector2(0, -50), 200), "C4")

func test_classify_gesture_drag_east_returns_d4():
	var b = _make()
	assert_eq(b._classify_gesture(true, Vector2(50, 0), 200), "D4")

func test_classify_gesture_short_fast_drag_is_flick_pular():
	var b = _make()
	assert_eq(b._classify_gesture(true, Vector2(10, 0), 80), "B4")

func test_classify_gesture_long_hold_no_drag_is_interagir():
	var b = _make()
	assert_eq(b._classify_gesture(false, Vector2.ZERO, 600), "Gs4")

func test_classify_gesture_plain_tap_returns_empty_ambiguous():
	var b = _make()
	assert_eq(b._classify_gesture(false, Vector2.ZERO, 100), "")

func test_classify_gesture_drag_exactly_at_threshold_is_direction():
	var b = _make()
	assert_eq(b._classify_gesture(true, Vector2(0, -25), 200), "C4")

func test_classify_gesture_short_slow_drag_below_flick_window_is_ambiguous():
	var b = _make()
	assert_eq(b._classify_gesture(true, Vector2(10, 0), 400), "")

func test_classify_gesture_flick_at_exact_ms_boundary_is_not_flick():
	# elapsed_ms == FLICK_MAX_MS não conta como flick (limiar é estrito <).
	var b = _make()
	assert_eq(b._classify_gesture(true, Vector2(10, 0), 150), "")

func test_classify_gesture_long_press_at_exact_boundary_is_interagir():
	var b = _make()
	assert_eq(b._classify_gesture(false, Vector2.ZERO, 500), "Gs4")

func test_double_tap_resolves_to_correr():
	var b = _make()
	watch_signals(b)
	b._had_drag = false
	b._press_pos = Vector2.ZERO
	b._press_time_ms = Time.get_ticks_msec()
	b._resolve_gesture(Vector2.ZERO)  # 1º toque: fica pendente (janela de double-tap)
	b._had_drag = false
	b._press_time_ms = Time.get_ticks_msec()
	b._resolve_gesture(Vector2.ZERO)  # 2º toque dentro da janela: correr
	assert_signal_emitted_with_parameters(b, "note_triggered", ["As4"])

func test_single_tap_without_followup_stays_pending():
	var b = _make()
	watch_signals(b)
	b._had_drag = false
	b._press_pos = Vector2.ZERO
	b._press_time_ms = Time.get_ticks_msec()
	b._resolve_gesture(Vector2.ZERO)
	assert_signal_not_emitted(b, "note_triggered")
	assert_not_null(b._pending_tap_timer)

func test_single_tap_confirms_as_pegar_after_window():
	var b = _make()
	watch_signals(b)
	b._had_drag = false
	b._press_pos = Vector2.ZERO
	b._press_time_ms = Time.get_ticks_msec()
	b._resolve_gesture(Vector2.ZERO)
	await get_tree().create_timer(b.DOUBLE_TAP_WINDOW_MS / 1000.0 + 0.1).timeout
	assert_signal_emitted_with_parameters(b, "note_triggered", ["A4"])

func test_release_without_prior_press_is_ignored():
	# Regressão: um release chegando em _gui_input sem um press correspondente
	# antes (ex: o press começou fora deste Control) deixava _press_time_ms
	# obsoleto/default -- _resolve_gesture calcularia um elapsed_ms enorme,
	# misclassificado (erradamente) como long-press ("Gs4"/interagir).
	var b = _make()
	watch_signals(b)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = Vector2.ZERO
	b._gui_input(ev)
	assert_signal_not_emitted(b, "note_triggered")
