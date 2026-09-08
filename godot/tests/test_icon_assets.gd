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
		# 96px não é decoração: os SVGs originais do Material Symbols vêm a 24px
		# e, rasterizados nesse tamanho, ficam borrados na tecla do modo Piano
		# (que desenha o glifo a ~33px). A escala mora no width/height do .svg,
		# então regravar um ícone a partir do original degrada em silêncio se
		# ninguém trancar o valor aqui.
		assert_eq(tex.get_width(), 96,
			"%s precisa rasterizar a 96px -- confira width/height no .svg" % path)
