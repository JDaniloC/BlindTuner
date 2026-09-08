extends GutTest

const ActionIconScript := preload("res://scripts/ActionIcon.gd")

func test_action_notes_map_to_chosen_icons():
	assert_eq(ActionIconScript.icon_name_for_note("Gs4"), "priority_high")
	assert_eq(ActionIconScript.icon_name_for_note("A4"), "back_hand")
	assert_eq(ActionIconScript.icon_name_for_note("As4"), "directions_run")
	assert_eq(ActionIconScript.icon_name_for_note("B4"), "keyboard_double_arrow_up")

func test_movement_notes_map_to_directional_icons():
	# direção vem de NoteMapping.NOTES[key]["direction"]
	assert_eq(ActionIconScript.icon_name_for_note("Cs4"), "north")       # (0,-1)
	assert_eq(ActionIconScript.icon_name_for_note("D4"), "north_east")   # (1,-1)
	assert_eq(ActionIconScript.icon_name_for_note("Ds4"), "east")        # (1,0)
	assert_eq(ActionIconScript.icon_name_for_note("E4"), "south_east")   # (1,1)
	assert_eq(ActionIconScript.icon_name_for_note("F4"), "south")        # (0,1)
	assert_eq(ActionIconScript.icon_name_for_note("Fs4"), "south_west")  # (-1,1)
	assert_eq(ActionIconScript.icon_name_for_note("G4"), "west")         # (-1,0)
	assert_eq(ActionIconScript.icon_name_for_note("C4"), "north_west")   # (-1,-1)

func test_every_note_has_an_icon():
	for key in NoteMapping.NOTES.keys():
		assert_ne(ActionIconScript.icon_name_for_note(key), "", "nota %s ficou sem ícone" % key)

func test_set_note_loads_texture_for_movement_note():
	var icon = ActionIconScript.new()
	add_child_autofree(icon)
	icon.set_note("Cs4")
	assert_not_null(icon._texture, "deveria ter carregado a textura da seta norte")
	assert_true(icon._texture is Texture2D)

func test_set_note_loads_texture_for_action_note():
	var icon = ActionIconScript.new()
	add_child_autofree(icon)
	icon.set_note("A4")
	assert_not_null(icon._texture)

func test_set_action_still_works_for_backwards_compatibility():
	var icon = ActionIconScript.new()
	add_child_autofree(icon)
	icon.set_action("pular")
	assert_not_null(icon._texture)

func test_unknown_action_leaves_texture_null_without_crashing():
	var icon = ActionIconScript.new()
	add_child_autofree(icon)
	icon.set_action("inexistente")
	assert_null(icon._texture)
