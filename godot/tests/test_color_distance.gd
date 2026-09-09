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

func test_aged_lens_factor_is_strong_enough_to_matter():
	# A versão anterior deste teste passava com QUALQUER fator < 1.0, inclusive
	# 0.999 -- ou seja, a correção de catarata podia ser neutralizada sem que
	# nenhum teste percebesse. O fator precisa ser forte o bastante para mudar
	# decisões de conflito de verdade.
	assert_lte(CD.AGED_BLUE_FACTOR, 0.7,
		"um corte fraco de azul não modela catarata senil")
	assert_gt(CD.AGED_BLUE_FACTOR, 0.0, "mas não pode zerar o canal")

func test_aged_lens_compresses_the_blue_channel_proportionally():
	# O que a função de fato garante: o canal azul encolhe pelo mesmo fator, e a
	# distância ENTRE dois azuis nesse canal diminui.
	#
	# Cuidado ao ler isto como "azuis ficam mais parecidos": em CIELAB a
	# distância entre dois azuis pode até CRESCER depois do filtro, porque
	# escurecer um azul saturado mexe bastante no L*. Medido: #0000FF vs #3333CC
	# vai de ΔE 41,6 para 47,3. O filtro modela a absorção de luz azul pelo
	# cristalino amarelado, não uma garantia de convergência perceptual.
	var a = Color("#0000FF")
	var b = Color("#3333CC")
	assert_almost_eq(CD.aged_lens(a).b, a.b * CD.AGED_BLUE_FACTOR, 0.001)
	assert_lt(absf(CD.aged_lens(a).b - CD.aged_lens(b).b), absf(a.b - b.b),
		"a diferença no canal azul precisa encolher")

func test_aged_lens_leaves_red_and_green_untouched():
	var c = Color("#8040C0")
	assert_almost_eq(CD.aged_lens(c).r, c.r, 0.001)
	assert_almost_eq(CD.aged_lens(c).g, c.g, 0.001)

func test_conflicts_are_ordered_nearest_first():
	# A ordenação é prometida na documentação da função (o modal nomeia as notas
	# na ordem em que ela devolve) e não era asseverada.
	var palette: Array[Color] = []
	for i in range(12):
		palette.append(Color.BLACK)
	var alvo = Color("#FF9800")
	palette[2] = Color("#FF9A02")   # praticamente idêntica
	palette[5] = Color("#F08A10")   # parecida, porém menos
	var conflitos = CD.conflicts_for(alvo, palette, 9)
	assert_true(conflitos.size() >= 2, "as duas deveriam conflitar")
	assert_eq(conflitos[0], 2, "a mais próxima vem primeiro")
	assert_eq(conflitos[1], 5)
