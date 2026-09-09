extends GutTest

const ModeScript := preload("res://scripts/InputModeSettings.gd")

func _fresh() -> Node:
	var m: Node = ModeScript.new()
	add_child_autofree(m)
	return m

func test_default_mode_is_joystick():
	var m = _fresh()
	assert_eq(m.mode, m.Mode.JOYSTICK)

func test_set_mode_changes_mode():
	var m = _fresh()
	m.set_mode(m.Mode.PIANO)
	assert_eq(m.mode, m.Mode.PIANO)

func test_signal_emitted_on_change():
	var m = _fresh()
	watch_signals(m)
	m.set_mode(m.Mode.PITCH_SCROLL)
	assert_signal_emitted_with_parameters(m, "mode_changed", [m.Mode.PITCH_SCROLL])

func test_signal_not_emitted_when_same():
	var m = _fresh()
	watch_signals(m)
	m.set_mode(m.Mode.JOYSTICK)  # já é o padrão
	assert_signal_not_emitted(m, "mode_changed")

func test_set_mode_clamps_out_of_range_high_value():
	# Regressão: set_mode() não clampava m, ao contrário de CueSettings.set_level()
	# (que serve de padrão documentado). Um valor fora do range faria
	# Playground._apply_input_mode() esconder os 3 grupos de input -- pior que
	# o soft-lock do achado #1 (nenhum jeito de interagir).
	var m = _fresh()
	m.set_mode(99)
	assert_eq(m.mode, m.Mode.PITCH_SCROLL, "valor fora do range deveria ser clampado pro máximo válido")

func test_set_mode_clamps_out_of_range_negative_value():
	var m = _fresh()
	m.set_mode(m.Mode.PIANO)  # sai do default antes de testar o clamp pro mínimo
	m.set_mode(-5)
	assert_eq(m.mode, m.Mode.JOYSTICK, "valor negativo deveria ser clampado pro mínimo válido")

func test_all_three_modes_distinct():
	var m = _fresh()
	var values = [m.Mode.JOYSTICK, m.Mode.PIANO, m.Mode.PITCH_SCROLL]
	var seen := {}
	for v in values:
		assert_false(seen.has(v), "valor de enum duplicado: %d" % v)
		seen[v] = true
