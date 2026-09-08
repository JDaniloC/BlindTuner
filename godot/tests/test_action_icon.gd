extends GutTest

const ActionIconScript := preload("res://scripts/ActionIcon.gd")

func test_action_notes_map_to_chosen_icons():
	assert_eq(ActionIconScript.icon_name_for_note("Gs4"), "priority_high")
	assert_eq(ActionIconScript.icon_name_for_note("A4"), "back_hand")
	assert_eq(ActionIconScript.icon_name_for_note("As4"), "directions_run")
	assert_eq(ActionIconScript.icon_name_for_note("B4"), "keyboard_double_arrow_up")

func test_movement_notes_map_to_directional_icons():
	# direction é vetor de GRID isométrico; a direção de TELA vem de
	# Character.grid_to_world (x-y, x+y). C4 (-1,-1) vira (0,-32) = reto
	# pra cima na tela, não noroeste -- ver comentário em ActionIcon.gd.
	assert_eq(ActionIconScript.icon_name_for_note("C4"), "north")        # grid (-1,-1) -> tela cima
	assert_eq(ActionIconScript.icon_name_for_note("Cs4"), "north_east")  # grid (0,-1)
	assert_eq(ActionIconScript.icon_name_for_note("D4"), "east")         # grid (1,-1)
	assert_eq(ActionIconScript.icon_name_for_note("Ds4"), "south_east")  # grid (1,0)
	assert_eq(ActionIconScript.icon_name_for_note("E4"), "south")        # grid (1,1) -> tela baixo
	assert_eq(ActionIconScript.icon_name_for_note("F4"), "south_west")   # grid (0,1)
	assert_eq(ActionIconScript.icon_name_for_note("Fs4"), "west")        # grid (-1,1)
	assert_eq(ActionIconScript.icon_name_for_note("G4"), "north_west")   # grid (-1,0)

func test_every_note_has_an_icon():
	for key in NoteMapping.NOTES.keys():
		assert_ne(ActionIconScript.icon_name_for_note(key), "", "nota %s ficou sem ícone" % key)

func test_set_note_loads_texture_for_movement_note():
	var icon = ActionIconScript.new()
	add_child_autofree(icon)
	icon.set_note("Cs4")
	assert_not_null(icon._texture, "deveria ter carregado a textura da seta nordeste")
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
