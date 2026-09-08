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
	m.set_mode(m.Mode.BLIND_TOUCH)
	assert_signal_emitted_with_parameters(m, "mode_changed", [m.Mode.BLIND_TOUCH])

func test_signal_not_emitted_when_same():
	var m = _fresh()
	watch_signals(m)
	m.set_mode(m.Mode.JOYSTICK)  # já é o padrão
	assert_signal_not_emitted(m, "mode_changed")

func test_all_four_modes_distinct():
	var m = _fresh()
	var values = [m.Mode.JOYSTICK, m.Mode.BLIND_TOUCH, m.Mode.PIANO, m.Mode.PITCH_SCROLL]
	var seen := {}
	for v in values:
		assert_false(seen.has(v), "valor de enum duplicado: %d" % v)
		seen[v] = true
