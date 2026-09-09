extends GutTest

const PanelScene := preload("res://scenes/NotePanel.tscn")

func _panel() -> Node:
	var p = PanelScene.instantiate()
	add_child_autofree(p)
	return p

func before_each():
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	CueSettings.set_level(0)
	ColorSchemeSettings.reset_to_defaults()

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

func test_chip_repaints_when_scheme_changes():
	# O defeito que motivou a correção e ficou sem teste: o chip guardava a cor do
	# esquema antigo enquanto o controle de input já mostrava a nova -- a MESMA
	# nota em duas cores ao mesmo tempo, num jogo cuja pista É a cor.
	CueSettings.set_level(0)
	var p = _panel()
	p.display_note("C4")
	var antes = p._color_chip.color
	ColorSchemeSettings.set_scheme("alto_contraste")
	assert_ne(p._color_chip.color, antes, "o chip precisa repintar sem reiniciar a fase")
	assert_eq(p._color_chip.color, Color("#0D4A74"), "e com a cor do esquema novo")

func test_chip_stays_put_when_the_scheme_changes_before_any_note():
	# Sem nota exibida não há o que repintar; repintar assim mesmo mostraria a cor
	# de uma nota que o jogador não recebeu.
	CueSettings.set_level(0)
	var p = _panel()
	var antes = p._color_chip.color
	ColorSchemeSettings.set_scheme("alto_contraste")
	assert_eq(p._color_chip.color, antes)

func test_reacts_to_cue_level_changed_after_instantiation():
	CueSettings.set_level(0)
	var p = _panel()
	p.display_note("C4")
	assert_true(p._label.visible)
	CueSettings.set_level(2)  # sinal dispara com painel já vivo
	assert_false(p._label.visible)
	assert_false(p._freq.visible)
	assert_true(p._color_chip.visible)
