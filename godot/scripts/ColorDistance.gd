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
## Ou seja: acima dos 3:1 do WCAG para elemento gráfico em qualquer estado. É uma
## melhora de uma ordem de grandeza sobre o que havia (1,03:1 a 2,32:1 com o
## rótulo no cinza do tema padrão do Godot) e a alternativa -- escolher a tinta
## por maior razão de contraste em vez de por corte de luminância -- inverteria o
## glifo para escuro em placas de meio-tom, o que ninguém pediu e nenhuma medição
## sustentou como mais legível.
##
## Duas coisas mudaram depois destes números, e as duas estão logo abaixo:
## icon_tint_for() ganhou um PISO (o corte de luminância sozinho não garantia os
## 3:1 em saturados) e o NOME da nota deixou de depender desta escolha, porque
## ganhou contorno na tinta oposta -- é o que leva o texto aos 4,5:1 nos
## meio-tons, onde nenhuma das duas tintas chegava.
const ICON_DARK := Color(0.10, 0.10, 0.12)
const ICON_LIGHT := Color.WHITE
const ICON_LUMA_THRESHOLD := 0.5
## Piso do WCAG 2.1 para elemento gráfico (1.4.11). Mora aqui porque é o número
## que a regra de tinta abaixo precisa respeitar, e a régua dos testes lê daqui
## em vez de redigitá-lo.
const GRAPHIC_MIN := 3.0

## O corte de luminância acerta o caso comum, mas não é uma garantia: ele é sobre
## get_luminance() (canais como estão) e o contraste é sobre canais
## LINEARIZADOS, e as duas contas divergem justamente nos saturados. Medido
## varrendo o cubo de cor: com o corte sozinho, #FF33FF fica em 2,93:1 e #FF6600
## em 2,94:1 -- abaixo dos 3:1, com a tinta OPOSTA em 5,9:1 nos dois.
##
## Então: o corte decide; se a decisão dele não alcançar o piso e a outra tinta
## alcançar, troca. Nas 12 notas x 3 esquemas embarcados isso NÃO inverte
## nenhuma placa (o corte já passava em todas), e por construção o resultado
## nunca fica abaixo de 4,17:1 -- que é o pior valor possível de
## max(clara, escura), no fundo cuja luminância WCAG é 0,2016.
##
## É diferente de "escolher sempre por maior razão de contraste", que foi
## considerado e recusado numa rodada anterior: aquilo inverteria o glifo para
## escuro em placas de meio-tom que hoje leem bem, o que ninguém pediu e nenhuma
## medição sustentou.
static func icon_tint_for(background: Color) -> Color:
	var escolhida := ICON_DARK if background.get_luminance() > ICON_LUMA_THRESHOLD else ICON_LIGHT
	var oposta := ICON_LIGHT if escolhida == ICON_DARK else ICON_DARK
	if contrast_ratio(escolhida, background) < GRAPHIC_MIN \
			and contrast_ratio(oposta, background) >= GRAPHIC_MIN:
		return oposta
	return escolhida

## Contorno do NOME da nota sobre placa colorida: a tinta oposta à do glifo.
##
## Por que o nome precisa de contorno e o glifo não: o piso do glifo é 3:1 e a
## regra acima garante 4,17:1, mas o de TEXTO é 4,5:1 -- e 4,17 é o pior caso
## possível, então existe cor de nota em que nenhuma das duas tintas alcança o
## piso de texto. Medido nas paletas embarcadas: 4,10:1 no #009218 do Pedagógico
## e 4,12:1 no #388E3C do Clássico.
##
## A cor da nota não pode ceder -- ela existe para DISTINGUIR uma nota das outras
## 11, não para contrastar com a tinta. Duas exigências sobre a mesma cor é a
## causa estrutural; o contorno separa as duas, porque o que fica encostado na
## letra passa a ser o halo e não a placa. Fica em 17,4:1 contra a tinta, para
## qualquer cor de placa, em qualquer estado -- inclusive no pressed, que mexe no
## fundo. É a mesma saída que o DirectionJoystick já usava para cair sobre
## cenário de cor imprevisível.
static func outline_tint_for(background: Color) -> Color:
	return ICON_LIGHT if icon_tint_for(background) == ICON_DARK else ICON_DARK

## Espessura do contorno, em px. Fração da fonte de 16px dos rótulos de placa na
## mesma proporção que o joystick já usa (6px numa fonte de 31px).
const TEXT_OUTLINE_PX := 3

## Piso do WCAG 2.1 para texto normal (1.4.3). Vive aqui pelo mesmo motivo que
## GRAPHIC_MIN: é o número que a regra abaixo precisa respeitar.
const TEXT_MIN := 4.5

## Espessura do contorno do nome PARA ESTE FUNDO -- 0 quando a tinta já se vira
## sozinha.
##
## O halo resolveu um problema real (existe meio-tom em que nenhuma das duas
## tintas alcança 4,5:1), mas aplicá-lo sempre custava caro no caso comum: numa
## placa clara e saturada ele desenha uma franja BRANCA em volta de letra escura,
## que engorda o traço e lê como adesivo. Foi exatamente o que o usuário apontou
## nas placas de ação.
##
## Então o halo vira EXCEÇÃO: só entra onde a tinta sozinha não chega ao piso de
## texto. Quem já passa fica com a letra limpa. Medido nas paletas embarcadas,
## só 1 ou 2 das 12 notas de cada esquema precisam dele.
##
## Olha só o fundo de REPOUSO, e isso é suficiente -- não é descuido com o estado
## apertado. pressed_shade_for() desloca o fundo PARA LONGE da tinta, então o
## apertado nunca lê pior que o solto; o invariante está afirmado em
## test_pressing_never_lowers_the_contrast_of_the_ink, varrendo o cubo de cor.
##
## A primeira versão fazia minf(repouso, apertado) "por segurança". Mutação
## provou que era peso morto: trocar o minf pelo repouso sozinho não reprovava
## nada, porque o outro termo nunca é o menor. Código que nenhum teste consegue
## distinguir é código que mente sobre o que protege -- o invariante virou
## asserção e a conta ficou com um termo só.
static func text_outline_px_for(background: Color) -> int:
	var ink := icon_tint_for(background)
	return 0 if contrast_ratio(ink, background) >= TEXT_MIN else TEXT_OUTLINE_PX

## Fundo do estado "pressed" de uma placa/tecla colorida.
##
## Antes era sempre `fundo * 0,85`. Escurecer é o que se espera de um botão
## apertado, mas a TINTA é decidida uma vez, sobre a cor de repouso: quando ela é
## escura, escurecer o fundo aproxima os dois e apertar a tecla PIORA o
## contraste. Medido: Ré em 4,15:1 e a placa Sol# em 4,20:1, ambas piores
## apertadas do que soltas.
##
## A regra vira "afasta o fundo da tinta": escurece quando a tinta é clara,
## clareia quando a tinta é escura. O feedback de toque continua existindo (o
## fundo muda), e agora o estado apertado nunca pode ficar menos legível que o
## solto -- em nenhuma paleta, inclusive na personalizada, que é do jogador.
const PRESSED_SHIFT := 0.15

static func pressed_shade_for(background: Color) -> Color:
	if icon_tint_for(background) == ICON_DARK:
		return Color(
			lerpf(background.r, 1.0, PRESSED_SHIFT),
			lerpf(background.g, 1.0, PRESSED_SHIFT),
			lerpf(background.b, 1.0, PRESSED_SHIFT),
			background.a)
	return Color(
		background.r * (1.0 - PRESSED_SHIFT),
		background.g * (1.0 - PRESSED_SHIFT),
		background.b * (1.0 - PRESSED_SHIFT),
		background.a)

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
