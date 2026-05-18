extends GutTest

const CueScript := preload("res://scripts/CueSettings.gd")

func _fresh() -> Node:
	var c: Node = CueScript.new()
	add_child_autofree(c)
	return c

func test_default_level_zero_shows_all():
	var c = _fresh()
	assert_eq(c.cue_level, 0)
	assert_true(c.shows_name())
	assert_true(c.shows_freq())
	assert_true(c.shows_color())

func test_level_one_hides_name():
	var c = _fresh()
	c.set_level(1)
	assert_false(c.shows_name())
	assert_true(c.shows_freq())
	assert_true(c.shows_color())

func test_level_two_only_color():
	var c = _fresh()
	c.set_level(2)
	assert_false(c.shows_name())
	assert_false(c.shows_freq())
	assert_true(c.shows_color())

func test_level_three_nothing():
	var c = _fresh()
	c.set_level(3)
	assert_false(c.shows_name())
	assert_false(c.shows_freq())
	assert_false(c.shows_color())

func test_set_level_clamps():
	var c := _fresh()
	c.set_level(99)
	assert_eq(c.cue_level, 3)
	var c2 := _fresh()
	c2.set_level(-5)
	assert_eq(c2.cue_level, 0)

func test_signal_emitted_on_change():
	var c = _fresh()
	watch_signals(c)
	c.set_level(2)
	assert_signal_emitted_with_parameters(c, "cue_level_changed", [2])

func test_signal_not_emitted_when_same():
	var c = _fresh()
	watch_signals(c)
	c.set_level(0)  # já é 0
	assert_signal_not_emitted(c, "cue_level_changed")

func test_signal_not_emitted_when_clamped_to_current():
	var c := _fresh()
	c.set_level(3)            # vai a 3 (emite uma vez)
	watch_signals(c)
	c.set_level(99)           # clampa a 3 == atual -> NÃO deve emitir
	assert_signal_not_emitted(c, "cue_level_changed")
