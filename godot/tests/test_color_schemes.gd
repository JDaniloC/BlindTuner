extends GutTest

func test_three_schemes_exist():
	assert_eq(ColorSchemes.SCHEME_IDS, ["classico", "pedagogico", "alto_contraste"])

func test_every_scheme_has_twelve_opaque_colors():
	for id in ColorSchemes.SCHEME_IDS:
		var cores = ColorSchemes.colors_for(id)
		assert_eq(cores.size(), 12, "esquema %s deveria ter 12 cores" % id)
		for c in cores:
			assert_eq(c.a, 1.0, "esquema %s tem cor translúcida" % id)

func test_classico_matches_note_mapping_factory_colors():
	var cores = ColorSchemes.colors_for("classico")
	var keys = NoteMapping.NOTES.keys()
	for i in range(keys.size()):
		assert_eq(cores[i], NoteMapping.default_color_for(keys[i]),
			"classico deveria espelhar a cor de fábrica de %s" % keys[i])

func test_pedagogico_first_and_last_are_the_agreed_values():
	var cores = ColorSchemes.colors_for("pedagogico")
	assert_eq(cores[0], Color("#9C000A"))
	assert_eq(cores[11], Color("#FFADFB"))

const ColorDistance := preload("res://scripts/ColorDistance.gd")

func test_alto_contraste_luminance_is_non_decreasing():
	# Estrutura do esquema: 7 matizes por letra, sustenido = letra com L* +10.
	# A consequência é que a claridade nunca cai ao subir de semitom -- a regra
	# empírica altura<->luminosidade aplicada de verdade.
	#
	# A medida é L* (CIELAB), que é onde a paleta foi desenhada, e NÃO
	# Color.get_luminance() (soma ponderada dos canais já gamma-encodados):
	# entre um sustenido e a natural seguinte o L* empata de propósito, e nesses
	# empates as duas métricas discordam no terceiro decimal.
	var cores = ColorSchemes.colors_for("alto_contraste")
	for i in range(1, cores.size()):
		var anterior: float = ColorDistance.to_lab(cores[i - 1]).x
		var atual: float = ColorDistance.to_lab(cores[i]).x
		assert_true(atual >= anterior - 0.5,
			"L* caiu do índice %d (%.1f) pro %d (%.1f)" % [i - 1, anterior, i, atual])

func test_unknown_scheme_returns_empty():
	assert_eq(ColorSchemes.colors_for("inexistente").size(), 0)

func test_is_valid_palette_rejects_wrong_size_and_transparency():
	assert_false(ColorSchemes.is_valid_palette([]))
	var onze: Array[Color] = []
	for i in range(11):
		onze.append(Color.RED)
	assert_false(ColorSchemes.is_valid_palette(onze))
	var doze: Array[Color] = []
	for i in range(12):
		doze.append(Color(1, 0, 0, 0.5))
	assert_false(ColorSchemes.is_valid_palette(doze))
