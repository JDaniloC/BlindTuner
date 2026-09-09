extends GutTest

const CD := preload("res://scripts/ColorDistance.gd")

func _palette_black_with(index: int, color: Color) -> Array[Color]:
	var palette: Array[Color] = []
	for i in range(12):
		palette.append(Color.BLACK)
	palette[index] = color
	return palette

func test_identical_colors_have_zero_distance():
	assert_almost_eq(CD.delta_e(Color.RED, Color.RED), 0.0, 0.001)

func test_distance_is_symmetric():
	var a = Color("#9C000A")
	var b = Color("#00A0C1")
	assert_almost_eq(CD.delta_e(a, b), CD.delta_e(b, a), 0.001)

func test_black_and_white_are_far_apart():
	assert_gt(CD.delta_e(Color.BLACK, Color.WHITE), 90.0)

func test_two_near_identical_oranges_conflict():
	# O par que a auditoria encontrou na paleta original do jogo.
	var palette = _palette_black_with(2, Color("#FF9800"))
	var conflitos = CD.conflicts_for(Color("#FB8C00"), palette, 9)
	assert_true(conflitos.has(2), "duas laranjas quase idênticas deveriam conflitar")

func test_distinct_colors_do_not_conflict():
	var palette = _palette_black_with(2, Color("#FF9800"))
	# Só o índice 2 tem cor; os outros 11 são preto, que precisa estar longe
	# do candidato pra este teste medir o que promete.
	var conflitos = CD.conflicts_for(Color("#2FD9F4"), palette, 9)
	assert_false(conflitos.has(2), "ciano claro não deveria conflitar com laranja")

func test_skip_index_is_never_reported_as_conflict():
	var palette: Array[Color] = []
	for i in range(12):
		palette.append(Color("#FF9800"))
	assert_false(CD.conflicts_for(Color("#FF9800"), palette, 4).has(4),
		"a própria nota sendo editada não pode conflitar consigo mesma")

func test_suggest_adjustment_resolves_the_conflict():
	var palette = _palette_black_with(2, Color("#FF9800"))
	var sugerida = CD.suggest_adjustment(Color("#FB8C00"), palette, 9)
	assert_eq(CD.conflicts_for(sugerida, palette, 9).size(), 0,
		"a sugestão deveria zerar os conflitos")

func test_suggest_adjustment_preserves_saturation_and_value():
	# Gira só o matiz: mexer na luminância quebraria a regra altura<->luminosidade.
	var palette = _palette_black_with(2, Color("#FF9800"))
	var original = Color("#FB8C00")
	var sugerida = CD.suggest_adjustment(original, palette, 9)
	assert_almost_eq(sugerida.v, original.v, 0.02)
	assert_almost_eq(sugerida.s, original.s, 0.02)

func test_aged_lens_reduces_blue():
	var azul = Color("#0000FF")
	assert_lt(CD.aged_lens(azul).b, azul.b, "cristalino amarelado corta azul")
