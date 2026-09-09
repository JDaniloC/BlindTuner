extends RefCounted
## Matemática de cor para o editor de paleta. Sem estado, tudo estático --
## testável sem instanciar nada e sem tocar em nó nenhum.

## ΔE abaixo do qual duas notas são "parecidas demais". O JND é ~2.3; aqui o
## alvo é reconhecer de relance, de memória, com baixa visão -- por isso uma
## ordem de grandeza acima.
const MIN_DELTA_E := 20.0

## Fator de absorção do azul por cristalino amarelado (catarata senil), aplicado
## antes de comparar duas cores.
##
## Modela a LUZ que chega à retina do público-alvo, não uma garantia de que
## azuis fiquem perceptualmente mais próximos: em CIELAB a distância entre dois
## azuis pode inclusive crescer depois do filtro, porque escurecer um azul
## saturado mexe bastante no L* (medido em test_color_distance.gd).
const AGED_BLUE_FACTOR := 0.55

static func to_lab(c: Color) -> Vector3:
	var r := _linearize(c.r)
	var g := _linearize(c.g)
	var b := _linearize(c.b)
	# sRGB -> XYZ (D65)
	var x := (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
	var y := (r * 0.2126 + g * 0.7152 + b * 0.0722)
	var z := (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
	var fx := _f(x)
	var fy := _f(y)
	var fz := _f(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))

static func _linearize(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)

static func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else (7.787 * t + 16.0 / 116.0)

## Distância perceptual CIE76. CIEDE2000 é mais fiel, mas custa ~40 linhas a
## mais e não muda nenhuma decisão na faixa de ΔE > 20 que interessa aqui.
static func delta_e(a: Color, b: Color) -> float:
	return (to_lab(a) - to_lab(b)).length()

static func aged_lens(c: Color) -> Color:
	return Color(c.r, c.g, c.b * AGED_BLUE_FACTOR, c.a)

## Razão de contraste WCAG 2.x entre duas cores opacas (1:1 a 21:1). Mora aqui
## porque é a mesma matemática de luminância do resto do módulo, e porque o jogo
## precisa cobrar contraste de texto sobre fundo em teste -- não basta conferir
## que existe um override de cor, o que importa é o número.
static func contrast_ratio(a: Color, b: Color) -> float:
	var la := relative_luminance(a)
	var lb := relative_luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

static func relative_luminance(c: Color) -> float:
	return 0.2126 * _linearize(c.r) + 0.7152 * _linearize(c.g) + 0.0722 * _linearize(c.b)

## Tinta escura sobre fundo claro e vice-versa. A regra vivia inline no
## PianoInput; virou função compartilhada quando o painel de ações passou a
## precisar da mesma decisão.
##
## Vale para o GLIFO e para o NOME DA NOTA na mesma placa: são a mesma decisão, e
## duas tintas diferentes no mesmo botão leriam como dois elementos distintos.
##
## O limiar é sobre Color.get_luminance() -- a média Rec. 709 dos canais como
## estão, SEM linearizar. Não é a mesma conta de relative_luminance() acima (que
## é a do WCAG, sobre canais linearizados) e é de propósito: é um corte binário
## "claro ou escuro", não uma razão.
##
## Contraste WCAG resultante, medido (não estimado) sobre TODAS as placas que os
## dois painéis conseguem exibir -- 12 notas x 3 esquemas, mais o cinza da pista
## 3 e as teclas autênticas do piano:
##   - placas em repouso: 4,10:1 no pior caso (o verde #009218 do Pedagógico,
##     seguido do #388e3c do Clássico com 4,12) -- os dois são meio-tom, onde a
##     tinta branca vence por pouco. As 4 placas do SpecialActionPanel, que são
##     as únicas que exibem nome em TODOS os esquemas, ficam em 4,52:1 ou mais.
##   - placa ARMADA (bg x1.6, só correr/pular, e só enquanto a ação está armada):
##     3,70:1 no pior caso (o azul #3949ab do Clássico clareado).
## Ou seja: acima dos 3:1 do WCAG para elemento gráfico em qualquer estado, e
## acima dos 4,5:1 para texto em tudo menos o estado armado transitório. É uma
## melhora de uma ordem de grandeza sobre o que havia (1,03:1 a 2,32:1 com o
## rótulo no cinza do tema padrão do Godot) e a alternativa -- escolher a tinta
## por maior razão de contraste em vez de por corte de luminância -- inverteria o
## glifo para escuro em placas de meio-tom, o que ninguém pediu e nenhuma medição
## sustentou como mais legível.
const ICON_DARK := Color(0.10, 0.10, 0.12)
const ICON_LIGHT := Color.WHITE
const ICON_LUMA_THRESHOLD := 0.5

static func icon_tint_for(background: Color) -> Color:
	return ICON_DARK if background.get_luminance() > ICON_LUMA_THRESHOLD else ICON_LIGHT

## Mapa índice cromático -> ΔE, só dos que ficam perto demais de `candidate`.
## `skip_index` é a nota sendo editada. Existe separado de conflicts_for porque
## o editor precisa comparar a GRAVIDADE de um conflito com a de antes: um
## conflito que já vinha da paleta de fábrica não é culpa do jogador.
static func conflict_distances(candidate: Color, palette: Array, skip_index: int) -> Dictionary:
	var out := {}
	for i in range(palette.size()):
		if i == skip_index:
			continue
		var d := delta_e(aged_lens(candidate), aged_lens(palette[i]))
		if d < MIN_DELTA_E:
			out[i] = d
	return out

## Índices cromáticos cuja cor fica perto demais de `candidate`, do mais
## próximo pro mais distante. `skip_index` é a nota sendo editada.
static func conflicts_for(candidate: Color, palette: Array, skip_index: int) -> Array[int]:
	var dist := conflict_distances(candidate, palette, skip_index)
	var idxs := dist.keys()
	idxs.sort_custom(func(a, b): return dist[a] < dist[b])
	var out: Array[int] = []
	for i in idxs:
		out.append(i)
	return out

## "Ajustar automaticamente": gira SÓ o matiz (preserva saturação e valor, logo
## preserva a regra altura<->luminosidade) em passos de 5° nos dois sentidos, e
## devolve a menor rotação que zera os conflitos. Se 72 passos não resolverem,
## devolve o candidato intacto -- o aviso é não-bloqueante, nunca impede a escolha.
static func suggest_adjustment(candidate: Color, palette: Array, skip_index: int) -> Color:
	if conflicts_for(candidate, palette, skip_index).is_empty():
		return candidate
	for passo in range(1, 37):
		for sinal in [1.0, -1.0]:
			var h := fposmod(candidate.h + sinal * passo * (5.0 / 360.0), 1.0)
			var tentativa := Color.from_hsv(h, candidate.s, candidate.v, candidate.a)
			if conflicts_for(tentativa, palette, skip_index).is_empty():
				return tentativa
	return candidate
