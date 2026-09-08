extends GutTest

const ICON_DIR := "res://assets/ui/icons/"
const EXPECTED: Array[String] = [
	"back_hand", "directions_run", "keyboard_double_arrow_up", "priority_high",
	"north", "north_east", "east", "south_east", "south", "south_west", "west", "north_west",
]

func test_all_expected_icons_exist_and_load():
	for name in EXPECTED:
		var path := ICON_DIR + name + ".svg"
		assert_true(ResourceLoader.exists(path), "faltando o ícone %s" % path)
		var tex = load(path)
		assert_true(tex is Texture2D, "%s deveria carregar como Texture2D" % path)
		assert_gt(tex.get_width(), 0, "%s tem largura zero" % path)
