extends GutTest

const StoryIntroModalScript := preload("res://scripts/StoryIntroModal.gd")
const STORY_INTRO_MODAL_SCENE := preload("res://scenes/StoryIntroModal.tscn")
const LevelDataScript := preload("res://scripts/LevelData.gd")

var _modal: Control = null

func before_each():
	_modal = STORY_INTRO_MODAL_SCENE.instantiate()
	add_child_autofree(_modal)

func test_modal_instantiates_ui_elements():
	assert_not_null(_modal)
	assert_not_null(_modal._title_lbl, "Título deve existir")
	assert_not_null(_modal._story_lbl, "Texto de história deve existir")
	assert_not_null(_modal._beacon_lbl, "Label do farol sonoro deve existir")
	assert_not_null(_modal._start_btn, "Botão de início deve existir")

func test_setup_populates_data_from_level_data():
	var lvl = LevelDataScript.new()
	lvl.id = "test_lvl"
	lvl.chapter = 1
	lvl.level_number = 2
	lvl.title = "A Canção de Ninar"
	lvl.story_intro = "Caminho no escuro em direção à cama."
	lvl.beacon_hint = "Siga o som da caixinha de música."
	lvl.default_cue_level = 1
	lvl.default_input_mode = 0

	_modal.setup(lvl)

	assert_eq(_modal._title_lbl.text, "A Canção de Ninar")
	assert_eq(_modal._story_lbl.text, "Caminho no escuro em direção à cama.")
	assert_true(_modal._beacon_lbl.text.contains("Siga o som da caixinha de música"))
	assert_true(_modal._chapter_tag_lbl.text.contains("1.2"))

func test_clicking_start_button_emits_started_signal():
	watch_signals(_modal)
	_modal._on_start_pressed()
	assert_signal_emitted(_modal, "started")

func test_key_press_ui_accept_triggers_start():
	watch_signals(_modal)
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	_modal._unhandled_input(ev)
	assert_signal_emitted(_modal, "started")
