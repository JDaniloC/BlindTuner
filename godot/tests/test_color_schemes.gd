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

func test_display_name_for_every_scheme():
	for id in ColorSchemes.SCHEME_IDS:
		var nome = ColorSchemes.display_name(id)
		assert_ne(nome, "", "esquema %s sem nome de exibição" % id)
		assert_ne(nome, id, "o nome de exibição deve ser legível, não o id cru")

func test_display_name_falls_back_to_the_id():
	assert_eq(ColorSchemes.display_name("inexistente"), "inexistente")

const CD := preload("res://scripts/ColorDistance.gd")

## Índice cromático -> índice da letra (C,D,E,F,G,A,B). Natural e sustenido da
## mesma letra compartilham o valor.
const LETRA_DE := [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6]

## Piso de ΔE exigido das paletas DESENHADAS (Pedagógico e Alto Contraste).
## Fica abaixo do CD.MIN_DELTA_E (20.0) que o editor usa para avisar o jogador,
## e a diferença é deliberada: medindo, o par de verdes Fá#/Sol do Pedagógico
## fica em 18,3. Em vez de mexer numa paleta já validada com o usuário só para
## satisfazer um número, o jogo assume a folga -- e é também por isso que o
## aviso do editor só dispara DEPOIS que o jogador altera uma cor, nunca na
## abertura, para não acusá-lo de um conflito que veio de fábrica.
const PISO_EMBARCADO := 18.0

func _pior_par(cores: Array, ignorar_mesma_letra: bool) -> Array:
	var pior := 999.0
	var par := [-1, -1]
	for i in range(12):
		for j in range(i + 1, 12):
			if ignorar_mesma_letra and LETRA_DE[i] == LETRA_DE[j]:
				continue
			var d: float = CD.delta_e(CD.aged_lens(cores[i]), CD.aged_lens(cores[j]))
			if d < pior:
				pior = d
				par = [i, j]
	return [pior, par[0], par[1]]

func test_designed_palettes_stay_above_the_shipped_floor():
	# O jogo cobrava do jogador um limiar de ΔE ao qual as próprias paletas
	# embarcadas nunca tinham sido submetidas.
	#
	# Pares de MESMA letra (Dó/Dó#) ficam de fora de propósito: no Alto
	# Contraste o sustenido é a natural com L* +10, ou seja, são parecidos POR
	# DESIGN -- é justamente o que torna o esquema memorizável.
	for id in ["pedagogico", "alto_contraste"]:
		var r = _pior_par(ColorSchemes.colors_for(id), true)
		assert_gte(r[0], PISO_EMBARCADO,
			"%s: notas %d e %d a ΔE %.1f, abaixo do piso %.1f" % [id, r[1], r[2], r[0], PISO_EMBARCADO])

func test_classico_is_the_known_bad_palette_that_motivated_the_others():
	# O Clássico é preservado como estava, defeitos e tudo, para quem já se
	# acostumou com ele -- não é uma paleta "corrigida" e não deve ser cobrada
	# como tal. Este teste registra o defeito em vez de escondê-lo: as duas
	# laranjas quase idênticas (Ré #FF9800 e Lá #FB8C00) foram exatamente o que
	# motivou a criação dos outros dois esquemas.
	var r = _pior_par(ColorSchemes.colors_for("classico"), true)
	assert_lt(r[0], PISO_EMBARCADO,
		"se o Clássico passou a cumprir o piso, este teste virou obsoleto")
	assert_eq(r[1], 2, "o pior par do Clássico é o Ré...")
	assert_eq(r[2], 9, "...com o Lá")

func test_designed_palettes_are_much_better_than_the_legacy_one():
	var legado = _pior_par(ColorSchemes.colors_for("classico"), true)[0]
	for id in ["pedagogico", "alto_contraste"]:
		var novo = _pior_par(ColorSchemes.colors_for(id), true)[0]
		assert_gt(novo, legado * 2.0,
			"%s deveria separar as notas bem melhor que o Clássico" % id)

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
