extends GutTest

const PanelScene := preload("res://scenes/NotePanel.tscn")

func _panel() -> Node:
	var p = PanelScene.instantiate()
	add_child_autofree(p)
	return p

func after_each():
	CueSettings.set_level(0)

func test_level_zero_all_visible():
	CueSettings.set_level(0)
	var p = _panel()
	p.display_note("C4")
	assert_true(p.visible)
	assert_true(p._label.visible)
	assert_true(p._freq.visible)
	assert_true(p._color_chip.visible)

func test_level_one_hides_name():
	CueSettings.set_level(1)
	var p = _panel()
	p.display_note("C4")
	assert_false(p._label.visible)
	assert_true(p._freq.visible)
	assert_true(p._color_chip.visible)

func test_level_two_only_chip():
	CueSettings.set_level(2)
	var p = _panel()
	p.display_note("C4")
	assert_false(p._label.visible)
	assert_false(p._freq.visible)
	assert_true(p._color_chip.visible)

func test_level_three_panel_hidden():
	CueSettings.set_level(3)
	var p = _panel()
	p.display_note("C4")
	assert_false(p.visible)

func test_reacts_to_cue_level_changed_after_instantiation():
	CueSettings.set_level(0)
	var p = _panel()
	p.display_note("C4")
	assert_true(p._label.visible)
	CueSettings.set_level(2)  # sinal dispara com painel já vivo
	assert_false(p._label.visible)
	assert_false(p._freq.visible)
	assert_true(p._color_chip.visible)
