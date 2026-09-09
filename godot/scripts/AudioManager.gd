extends Node
## Autoload singleton — gera e toca tons sintetizados representando cada nota.
## Serializa o playback: um único player ativo por vez. Cada chamada de
## play_note/play_collision_sfx cancela o anterior, garantindo:
##   - notas repetidas sempre tocam (sem silent-fail por overlap)
##   - nunca 2 sons simultâneos (clareza pedagógica)

const MIX_RATE := 44100.0
const NOTE_DURATION_SEC := 0.6
const COLLISION_DURATION_SEC := 0.2
const ATTACK_SEC := 0.01
const DECAY_SEC := 0.15
const SUSTAIN_LEVEL := 0.4
const RELEASE_SEC := 0.3
const COLLISION_FREQ := 80.0
# AudioStreamGeneratorPlayback arredonda o buffer pra cima na proxima potencia
# de 2 (nearest_shift(mix_rate * buffer_length)). Com 44100Hz, 0.04 (1764
# frames) vira 2048 frames (~46ms) -- ainda folgado o bastante acima do
# consumo por frame a 60fps (~735 frames/frame) pra nao dar underrun, mas bem
# mais responsivo que um buffer "cheio" de ~186ms (o que 0.1 geraria: 4410 ->
# 8192 frames). Esse latencia eh o atraso entre mudar _pitch_freq e o som
# realmente mudar, pois o buffer fica sempre cheio de amostras ja geradas.
const PITCH_BUFFER_LEN_SEC := 0.04
const NOTE_MISS_FREQ := 220.0
# Precisa ser > ATTACK_SEC+DECAY_SEC (0.16s), senão o buffer termina no meio do
# decay (nunca alcança release) e corta com um click audível em vez de esmaecer.
const NOTE_MISS_DURATION_SEC := 0.2
# Esmaece o volume antes de parar o tom contínuo, senão .stop() corta a onda
# senoidal num ponto arbitrário do ciclo -- click audível em toda soltada do
# slider no modo Scroll de Afinação. Curto o bastante pra não atrasar
# perceptivelmente a resposta, longo o bastante pra evitar a descontinuidade.
const PITCH_STOP_FADE_SEC := 0.012
const VIBRATO_RATE_HZ := 6.0
const VIBRATO_DEPTH_CENTS := 18.0
const TREMOLO_DEPTH := 0.12
# Deslocamento de fase do tremolo (amplitude) em relação ao vibrato (pitch) --
# num instrumento real, pressão/velocidade do arco e afinação não oscilam em
# lockstep perfeito. Com a mesma fase, pitch e volume sobem/descem juntos de
# forma perfeitamente correlacionada -- efeito de tremor sincronizado (mais
# "trilha de terror" que corda de verdade). 0.27 (~27% do ciclo) desacopla.
const TREMOLO_PHASE_OFFSET := 0.27
const BOW_NOISE_GAIN := 0.03
# Coeficiente do filtro passa-baixa de 1 polo do ruído de arco (lerp por
# amostra). 0.1 (corte ~740Hz) deixa agudo demais passar -- soa como estática
# em vez de sopro. ~0.035 baixa o corte pra ~200-300Hz, mais quente/orgânico.
const NOISE_LOWPASS_COEFF := 0.035
# Amplitudes decrescentes dos harmônicos (fundamental + 4 acima) -- é
# fisicamente o que a fricção do arco contra a corda produz (onda rica em
# harmônicos, tipo dente-de-serra), diferente da senoide pura anterior.
const HARMONIC_GAINS := [1.0, 0.5, 0.3, 0.2, 0.1]
# Soma pré-computada de HARMONIC_GAINS -- evita recalcular a soma toda vez que
# _string_harmonics() roda (por AMOSTRA de áudio, milhares de vezes/segundo).
const HARMONIC_GAIN_TOTAL := 2.1
# LFO de vibrato é 6Hz -- recalcular o multiplicador a cada amostra (44100/s)
# é desnecessário e inaudível a essa taxa de mudança. Recalcula só a cada N
# amostras (ver _fill_pitch_buffer/_vibrato_sample_counter).
const VIBRATO_CONTROL_RATE_SAMPLES := 32

## Os dois algoritmos de síntese do tom contínuo do Scroll, alternáveis AO VIVO
## (no meio do arrasto) para o jogador comparar os dois de ouvido:
##   ADDITIVE  -- soma de 5 harmônicos senoidais, o timbre que o jogo já tinha.
##   WAVEGUIDE -- guia de onda: corda friccionada físico-modelada, com o
##                movimento de fricção que a soma de senos não tem.
## Qual dos dois vira o padrão é decisão do jogador DEPOIS de ouvir os dois --
## por isso o padrão continua sendo o timbre antigo.
enum Timbre { ADDITIVE, WAVEGUIDE }

# --- Guia de onda ------------------------------------------------------------
# Duas linhas de delay (a onda que vai até o cavalete e a que volta até a
# pestana) com reflexão INVERSORA nas duas pontas. Um laço ÚNICO de
# Karplus-Strong, que é a leitura óbvia da receita, foi implementado e medido:
# NÃO oscila -- converge para uma constante (DC 0,2786), porque o filtro de
# perdas tem ganho 1 em DC e nada no laço troca o sinal do que volta. Com as
# duas reflexões inversoras a componente contínua das duas linhas se cancela na
# leitura do cavalete e o que sobra é a ressonância da corda.
#
# O que EXCITA essa corda é o arco, e ele é o modelo de fricção do STK
# (Cook/Scavone): a cada amostra, a diferença entre a velocidade do arco e a da
# corda no ponto de contato passa por uma curva de atrito não-linear (a "mesa de
# arco", _bow_friction) e volta injetada nas duas linhas. Dessa não-linearidade
# EMERGE o movimento de Helmholtz -- o canto que viaja pela corda e produz a
# onda tipo dente-de-serra --, e é por isso que este modelo soa como corda
# friccionada e não como um ressoador chiando.
#
# A versão anterior excitava a corda com RUÍDO ALEATÓRIO, que é o atalho óbvio
# (e o que o Karplus-Strong faz). Foi implementada, ouvida e reprovada -- "bem
# bizarro", "pior que o normal". Medido, ruído contra mesa de arco (o segundo
# número é o do modelo como ele está hoje, com o arco onde WG_BOW_POSITION diz):
#   fator de crista       3,75  ->  2,03  (o do aditivo é 1,80: dente-de-serra
#                                          contra envoltória de ruído)
#   passeio de janelas de
#   100ms depois do ataque 7,9dB -> 0,10dB (o "instável" que se ouvia)
#   afinação real das 12
#   notas                 -28,6 a +6,1 cents  ->  -0,28 a +0,29 cent
# A afinação é a diferença que mais importa num jogo cuja mecânica é reconhecer
# qual nota soou: o laço de atraso sempre esteve afinado, mas ruído não é
# periódico, então o que saía não tinha período estável -- o teste de afinação
# media a resposta ao IMPULSO (o laço linear, correto) e por isso passava.

# Onde o arco toca a corda, como fração do laço (0 = no cavalete, 0,5 = no meio).
# É ele que divide o laço nos dois segmentos abaixo. 0,125 é a posição de um
# violino de verdade, perto do cavalete -- e é o betaRatio padrão do Bowed do
# STK (0,127), de onde este modelo veio.
#
# MUDAR A POSIÇÃO DESAFINA. A soma dos dois segmentos é o laço inteiro, então a
# dedução diz que não deveria; a mesa de arco encurta o laço de um jeito que
# depende de ONDE ela está, e a dedução não vê isso. Medido: trocar 0,25 por
# 0,125 sem mexer em mais nada põe as 12 notas 1,1 a 2,5 cents BAIXAS, e o erro
# é proporcional à frequência (ou seja, é atraso fixo -- 0,12 amostra a mais no
# laço). Quem paga é WG_LOSS_DELAY_COMP, que é re-medido a cada mexida aqui.
#
# E muda MUITO o timbre. Medido, espectro do Lá4 (harmônicos 1 a 7, normalizados
# pelo fundamental), com todo o resto igual:
#   0,5    1,00 0,03 0,07 0,00 0,05 0,01 0,00  -- o arco no meio da corda não
#          consegue excitar modo nenhum de ordem par: sai quase uma senoide, e
#          fator de crista 1,57. Timbre de flauta, não de corda.
#   0,25   1,00 0,52 0,39 0,15 0,15 0,14 0,13  -- a cauda NÃO decai: do 4º ao 7º
#          harmônico fica tudo em 0,13-0,15. É essa fileira de parciais agudos do
#          mesmo tamanho que soa áspera.
#   0,125  1,00 0,49 0,31 0,22 0,16 0,11 0,03  -- quase a série do aditivo
#          (1 / 0,5 / 0,3 / 0,2 / 0,1), decrescente até o fim, e sem o 4º
#          harmônico quase zerado que 0,25 paga por bater numa fração inteira.
# O comentário anterior descartava 0,125 dizendo que ali o 2º harmônico sai 2,6x
# MAIOR que o fundamental ("nasalado, altura ambígua"). Não reproduz: medido nas
# 12 notas, o maior parcial acima do fundamental é 0,50x -- a fundamental é a
# parcial mais forte em todas elas. O que derruba a fundamental de verdade é
# ganho de laço baixo ou arco pesado demais (ver WG_REFLECTION_GAIN), e disso o
# jogo agora tem teste.
#
# Aspereza, que era a reclamação de ouvido. Comparando o som de antes (arco a
# 0,25, reflexão 0,98) com o de agora, medido nas 12 notas: energia acima de 2kHz
# cai de 4,76% pra 3,59%, acima de 4kHz de 0,70% pra 0,38%, e o brilho -- RMS da
# diferença entre amostras vizinhas convertido em Hz, que é a frequência RMS do
# espectro -- cai de 942Hz pra 826Hz (o aditivo dá 598Hz). Só a posição, com a
# reflexão igual dos dois lados, vai de 987Hz (0,25) pra 826Hz (0,125).
# Um centroide espectral ponderado por AMPLITUDE anda pro outro lado (2007 ->
# 2249Hz) porque conta cada parcialzinha aguda com o mesmo peso da fundamental, e
# a 0,125 há mais delas; as medidas que pesam ENERGIA, que é o que o ouvido faz,
# dizem mais escuro.
#
# O preço é o ATAQUE. Perto do cavalete o movimento de Helmholtz precisa de mais
# voltas pra se formar: os primeiros 200ms saem a -2,73dB do regime no Dó4
# (contra -0,49dB a 0,25) e a corda só alcança o volume dela lá pelos 150ms, em
# vez de 40ms. As posições intermediárias andam suave entre os dois extremos
# (com a reflexão de agora -- 0,15: brilho 875Hz e ataque -1,35dB; 0,2: 940Hz e
# -0,67dB) -- se o ataque lento incomodar mais que a aspereza, é pra lá que se
# anda, re-medindo WG_LOSS_DELAY_COMP no caminho.
const WG_BOW_POSITION := 0.125
# Comprimento de cada segmento em múltiplos de _wg_delay (que é MEIO laço).
const WG_BRIDGE_SEGMENT := 2.0 * WG_BOW_POSITION
const WG_NUT_SEGMENT := 2.0 * (1.0 - WG_BOW_POSITION)
# Velocidade do arco e inclinação da mesa de fricção. Só o PRODUTO dos dois
# importa pro timbre (a mesa só enxerga velocidade x inclinação; o resto vira
# ganho, que WG_OUTPUT_GAIN reabsorve): medido, 0,15x2,0, 0,1x3,0 e 0,3x1,0 dão
# espectro, brilho, crista e afinação IDÊNTICOS até a 3ª casa decimal.
#
# O produto 0,4 fica onde estava; o que muda é o que ele custa com o arco na
# posição nova (brilho = frequência RMS do espectro, média das 12 notas; o
# aditivo dá 598Hz):
#   0,3  -- brilho 913Hz, crista 2,08, ataque -1,25dB (o mais rápido dos três)
#   0,4  -- brilho 826Hz, crista 2,03, ataque -2,73dB
#   0,5  -- brilho 766Hz, crista 2,01, ataque -5,52dB (a corda demora demais)
# Os três desafinam entre si -- o peso do arco encurta o laço --, então mexer
# aqui obriga a re-medir WG_LOSS_DELAY_COMP: com o produto em 0,3 e a
# compensação de agora, as 12 notas sobem pra +0,40 a +1,34 cent.
#
# O comentário anterior afirmava que "nenhuma destas três é mais áspera que o que
# já estava lá". O apoio era um brilho medido na versão excitada a RUÍDO, que
# sorteava a excitação e nem é mais o algoritmo daqui -- não dava pra concluir
# isso de um sorteio, e a frase saiu.
const WG_BOW_VELOCITY := 0.2
const WG_BOW_TABLE_SLOPE := 2.0
# 256 amostras por linha cobrem com folga a oitava do jogo e o tamanho NUNCA
# muda. Redimensionar as linhas a cada frequência nova é a alternativa óbvia e
# joga fora toda a energia já guardada nelas -- a corda recomeçaria do zero a
# cada evento de arrasto, que é o oposto do glissando.
const WG_LINE_SAMPLES := 256
# O arco divide a corda em dois segmentos (ver WG_BOW_POSITION), e o segmento
# do lado da pestana é o mais longo dos dois: é ELE que tem que caber na linha,
# não a metade do laço. Daí o teto ser o comprimento da linha dividido pelo
# segmento maior, e não a linha inteira. Com o arco a 0,125 o segmento da pestana
# é 7/8 do laço, e sobram 145,1 amostras de meio-laço -- corda afinável até
# ~151Hz. A nota mais grave do jogo (262Hz) pede 83,4.
const WG_MAX_HALF_DELAY := (WG_LINE_SAMPLES - 2) / (2.0 * (1.0 - WG_BOW_POSITION))
# Filtro de perdas de 1 polo no cavalete: é ele que faz os harmônicos agudos
# morrerem antes do fundamental, como numa corda de verdade.
const WG_LOSS_COEFF := 0.3774
# Ganho de cada reflexão. Ao quadrado (são duas por volta) dá o decaimento da
# corda; longe demais de 1 e o arco não chega a pôr a corda pra oscilar. A ponta
# de cima -- corda que decai devagar demais -- não é problema AQUI porque nada
# neste modo deixa a corda soando sozinha: o tom para junto com o arrasto, e o
# arrasto seguinte reseta as duas linhas (ver _reset_waveguide).
#
# Com o arco a 0,25 esta constante quase não fazia diferença medível (0,98 e
# 0,998 davam o mesmo ataque, -0,49 contra -0,50dB) e ficou sem teste que a
# segurasse. Com o arco a 0,125 ela volta a mandar em duas coisas, e as duas
# agora têm teste:
#   ATAQUE -- RMS dos primeiros 200ms contra o do regime, pior das 12 notas:
#     0,98 -5,89dB | 0,99 -4,19 | 0,995 -3,13 | 0,998 -2,73 | 1,0 -2,53.
#     Perto do cavalete o movimento de Helmholtz precisa de mais voltas pra se
#     formar, e um laço que guarda mais energia por volta chega lá antes -- o
#     oposto da intuição de que laço mais surdo "acorda" mais rápido. 0,998 é o
#     joelho da curva: 1,0 ganha só 0,2dB e tira toda a margem contra um laço que
#     não perde nada em ponta nenhuma.
#   QUE NOTA SOA -- abaixo de 0,98 a fundamental COLAPSA e a corda trava na
#     oitava: a 0,95 o 2º harmônico chega a ~1000x o fundamental e o RMS cai pela
#     metade. É o "arco leve demais toca o harmônico" de um violino de verdade, e
#     num jogo cuja mecânica é reconhecer qual nota soou, é fatal.
# Custa brilho: 0,98 dá 780Hz e 0,998 dá 826Hz (frequência RMS do espectro, média
# das 12 notas) -- 46Hz mais claro em troca de 3,2dB de ataque. E custa afinação:
# trocar 0,98 por 0,998 sobe as 12 notas ~0,4 cent, o que WG_LOSS_DELAY_COMP
# reabsorve (é medido com esta constante no valor de agora).
const WG_REFLECTION_GAIN := 0.998
# O laço fecha mais curto do que a soma das linhas de delay diz, por três motivos
# que não dá pra separar por dedução: o atraso de fase do filtro de perdas, o da
# interpolação linear das leituras fracionárias, e o encurtamento que a própria
# mesa de arco causa (durante a GRUDADA a corda é praticamente presa no ponto do
# arco, e uma corda presa é uma corda mais curta). Sem descontar nada o tom sai
# BAIXO: 15 a 23 cents nas notas em que o medidor de fase ainda não perde a volta.
#
# Por isso o valor é MEDIDO e não derivado -- e re-medido a cada mexida em
# WG_BOW_POSITION, WG_REFLECTION_GAIN ou no peso do arco, porque a parcela que a
# mesa de arco encurta depende dos três. O erro é linear nesta constante e some
# junto nas 12 notas (é atraso FIXO, e atraso fixo vira sempre a mesma proporção
# do período). Medido nas 12 notas com o arco a 0,125 e reflexão 0,998, afinação
# real (deriva de fase da fundamental em 0,8s):
#   1,355 -- -2,45 a -1,13 cent (o valor calibrado pra o arco a 0,25)
#   1,472 -- -0,37 a +0,22
#   1,478 -- -0,28 a +0,29  (o minimax: aqui o erro pra baixo iguala o pra cima)
#   1,483 -- -0,21 a +0,35
#   1,510 -- +0,03 a +0,56
const WG_LOSS_DELAY_COMP := 1.478
# O dedo é amostrado por FRAME e o áudio por AMOSTRA, então a frequência nova
# chega como degrau. Aplicar o degrau direto no comprimento da linha estala:
# numa varredura Dó4->Si4 com a frequência mudando uma vez por frame, o pulo
# máximo amostra-a-amostra vai a 0,282, contra 0,132 do mesmo tom parado. Com
# este slew fica em 0,139 -- 5% acima do tom parado --, e ainda assim rápido o
# bastante pra a corda alcançar o comprimento novo (resíduo de 0,4 amostra meio
# segundo depois de um salto de oitava inteira).
const WG_DELAY_SLEW := 0.02
# Bloqueio de DC na SAÍDA (não dentro do laço: lá dentro ele adianta a fase de
# 3,4 amostras nas notas do jogo e desafinaria tudo o que WG_LOSS_DELAY_COMP
# acabou de acertar). O arco puxa a corda sempre no MESMO sentido, então a força
# que ele injeta tem componente contínua: sem este bloqueio, a onda sai montada
# num degrau que não é som e só come margem antes do clipping.
const WG_DC_BLOCK_COEFF := 0.995
# Trocar de timbre não pode virar uma mudança de VOLUME, senão a comparação de
# ouvido -- que é a razão de o interruptor existir -- sai enviesada pelo mais
# alto dos dois. Calibrado por RMS, e não por pico: sonoridade segue RMS.
#
# Com a excitação a ruído esta calibração não fechava. O ruído dava fator de
# crista 3,75 contra 1,80 do aditivo, então casar o RMS jogava o pico em ~1,19 e
# o clampf() aqui embaixo esconderia a distorção; o gasto ficava em ganho 25, com
# o guia de onda ainda ~4dB abaixo do aditivo. A mesa de arco fechou esses 4dB.
#
# Com o arco a 0,125 não existe UM ganho que case as duas janelas, porque a corda
# leva ~150ms pra alcançar o volume dela (ver WG_BOW_POSITION): casar os
# primeiros 200ms deixa o resto do arrasto alto, casar o regime deixa o ataque
# fraco. 0,55 é o minimax das três janelas medidas nas 12 notas, contra o
# aditivo (RMS 0,2221 nas três):
#   200ms  0,2022  -0,82dB
#   500ms  0,2293  +0,27dB   <- o arrasto típico, praticamente casado
#   1,5s   0,2403  +0,68dB
# O pico das 12 notas fica em 0,540 (o aditivo dá 0,402): a crista subiu pra 2,03
# com o arco perto do cavalete, então o mesmo RMS custa mais margem de pico que
# antes. Ainda sobra: com o +2,5dB do EQ do bus Strings por cima, o pior caso vai
# a 0,720, longe do clampf() aqui embaixo -- que, se fosse alcançado, esconderia
# a distorção em vez de denunciá-la.
const WG_OUTPUT_GAIN := 0.55

# Trocar de algoritmo no meio de um arrasto pula a amostra do valor de uma
# síntese pro da outra num único frame de áudio -- estalo garantido, e bem na
# hora em que o jogador está prestando atenção na diferença. 20ms de crossfade
# custam só as amostras da transição (fora dela roda um algoritmo só).
const TIMBRE_CROSSFADE_SEC := 0.02
const TIMBRE_FADE_PER_SAMPLE := 1.0 / (MIX_RATE * TIMBRE_CROSSFADE_SEC)

const STRINGS_BUS_NAME := "Strings"
# Reduzido de 6.0: nas notas do jogo (262-494Hz), as bandas de 250/500Hz
# reforçadas caem quase exatamente sobre a fundamental e o 2º harmônico da
# nota tocada (não sobre formantes "genéricos" de corpo de violino) -- +6dB
# ali deixava o timbre nasal/ressonante e empurrava o sinal perto do clipping
# antes do chorus processar.
const STRINGS_EQ_BOOST_DB := 2.5
# Frequências-alvo pra reforçar (~formantes graves/médios/agudos de um corpo
# de violino/cello) -- mapeadas pra banda mais próxima do AudioEffectEQ10 em
# _eq10_band_index_for. Um único EQ10 evita o problema de encadear vários
# AudioEffectBandPassFilter em série (cada um restringe mais o sinal que o
# anterior -- 3 seguidos quase silenciariam o tom).
const STRINGS_EQ_BOOST_TARGETS_HZ := [300.0, 700.0, 2500.0]
const EQ10_BAND_FREQS := [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0]

var _current_player: AudioStreamPlayer = null
var _pitch_player: AudioStreamPlayer = null
var _pitch_playback: AudioStreamGeneratorPlayback = null
var _pitch_phase := 0.0
var _pitch_freq := 0.0
var _pitch_lfo_phase := 0.0
var _noise_lp := 0.0
var _vibrato_sample_counter := 0

## Qual síntese está soando AGORA. Mora aqui, no autoload de áudio, e não em
## ColorSchemeSettings: aquele guarda paleta e pistas visuais, e enfiar uma
## escolha de som lá só porque ele já tem ConfigFile pronto misturaria dois
## domínios que nada mais compartilha.
##
## Deliberadamente NÃO persiste em disco, ao contrário do interruptor de pistas.
## Este é um comparador: existe para o jogador ouvir os dois lado a lado e
## decidir qual vira o padrão do jogo -- e essa decisão vira uma linha de código,
## não uma preferência gravada por sessão.
var pitch_timbre: int = Timbre.ADDITIVE

# Corda do guia de onda: as duas linhas de delay, o cursor de escrita, o
# comprimento atual (fracionário, escorregando em direção ao alvo), o estado do
# filtro de perdas e o do bloqueio de DC.
var _wg_right := PackedFloat32Array()
var _wg_left := PackedFloat32Array()
var _wg_write := 0
var _wg_delay := 0.0
var _wg_loss := 0.0
var _wg_dc_in := 0.0
var _wg_dc_out := 0.0

# Crossfade de troca de timbre: quanto ainda resta do timbre ANTERIOR (1 = só
# ele, 0 = crossfade terminado e só o novo roda).
var _timbre_fade := 0.0
var _timbre_fade_from: int = Timbre.ADDITIVE

func _ready() -> void:
    _ensure_strings_bus()
    # Só pra as duas linhas de delay existirem antes de qualquer coisa poder
    # chamar _waveguide_step(): sem isso o primeiro passo indexaria um array
    # vazio. A frequência aqui não significa nada -- play_continuous_pitch()
    # reafina a corda no começo de cada arrasto.
    _reset_waveguide(NOTE_MISS_FREQ)

## Cria (se ainda não existir) o bus "Strings" com EQ + chorus, só pro tom
## contínuo do Scroll de Afinação -- fica separado do bus Master, onde tocam
## as notas normais e os SFX de colisão/erro, pra não colori-los também.
func _ensure_strings_bus() -> void:
    if AudioServer.get_bus_index(STRINGS_BUS_NAME) != -1:
        return
    var idx := AudioServer.bus_count
    AudioServer.add_bus(idx)
    AudioServer.set_bus_name(idx, STRINGS_BUS_NAME)
    AudioServer.set_bus_send(idx, "Master")
    var eq := AudioEffectEQ10.new()
    for target_hz in STRINGS_EQ_BOOST_TARGETS_HZ:
        eq.set_band_gain_db(_eq10_band_index_for(target_hz), STRINGS_EQ_BOOST_DB)
    AudioServer.add_bus_effect(idx, eq)
    AudioServer.add_bus_effect(idx, _make_strings_chorus())

## Uma única voz, profundidade/nível baixos -- o padrão (2 vozes, profundidade
## maior) soa metálico/tipo flanger aplicado em cima de só 5 harmônicos
## senoidais discretos e estáticos: sem ruído/dispersão real entre as cópias
## (como haveria numa amostra real), a modulação de delay desloca a fase de
## cada harmônico de um jeito que gera cancelamento/reforço periódico.
func _make_strings_chorus() -> AudioEffectChorus:
    var chorus := AudioEffectChorus.new()
    chorus.voice_count = 1
    chorus.set_voice_depth_ms(0, 1.5)
    chorus.set_voice_level_db(0, -6.0)
    return chorus

## AudioEffectEQ10 tem 10 bandas fixas (31..16000Hz, índices 0-9). Mapeia uma
## frequência-alvo pra o índice da banda mais próxima.
func _eq10_band_index_for(target_hz: float) -> int:
    var best_idx := 0
    var best_diff := INF
    for i in range(EQ10_BAND_FREQS.size()):
        var diff: float = absf(EQ10_BAND_FREQS[i] - target_hz)
        if diff < best_diff:
            best_diff = diff
            best_idx = i
    return best_idx

## Toca a nota pela chave (ex: "A4"). Cancela qualquer player ativo antes.
func play_note(note_key: String) -> AudioStreamPlayer:
    var freq := float(NoteMapping.frequency_for(note_key))
    return _play_synth(freq, false, NOTE_DURATION_SEC)

## Toca SFX de colisão (tom grave e curto). Cancela qualquer player ativo antes.
func play_collision_sfx() -> AudioStreamPlayer:
    return _play_synth(COLLISION_FREQ, true, COLLISION_DURATION_SEC)

## Toca SFX de erro de conhecimento no CALL (curto, não-harsh). Distinto do SFX de colisão física.
func play_note_miss_sfx() -> AudioStreamPlayer:
    return _play_synth(NOTE_MISS_FREQ, false, NOTE_MISS_DURATION_SEC)

## Toca (ou, já tocando, apenas atualiza) um tom contínuo na frequência dada --
## diferente de play_note, NÃO reinicia o player a cada chamada (permite glissando
## suave). Usado pelo modo de input "Scroll de Afinação".
func play_continuous_pitch(freq_hz: float) -> AudioStreamPlayer:
    _pitch_freq = freq_hz
    if _pitch_player == null or not is_instance_valid(_pitch_player):
        _stop_current()
        _pitch_player = AudioStreamPlayer.new()
        var gen := AudioStreamGenerator.new()
        gen.mix_rate = MIX_RATE
        gen.buffer_length = PITCH_BUFFER_LEN_SEC
        _pitch_player.stream = gen
        _pitch_player.bus = STRINGS_BUS_NAME
        add_child(_pitch_player)
        _pitch_player.play()
        _pitch_playback = _pitch_player.get_stream_playback()
        _pitch_phase = 0.0
        # Corda nova a cada arrasto novo, pelo mesmo motivo de _pitch_phase: sem
        # isso o toque começaria com o rabo de ressonância do arrasto anterior, e
        # o comprimento da linha ainda estaria escorregando da nota antiga pra
        # esta -- um glissando fantasma de meio segundo que ninguém pediu.
        _reset_waveguide(freq_hz)
        # E o crossfade de timbre morre aqui pelo mesmo motivo dos dois acima.
        # _timbre_fade só decai dentro de _pitch_step(), que só roda enquanto há
        # tom no ar: apertar o interruptor de timbre SEM nada tocando -- que é o
        # fluxo mais provável do recurso, aperta e só então arrasta -- deixa o
        # fade armado em 1,0 indefinidamente. Sem esta linha os primeiros 20ms do
        # arrasto seguinte sairiam com 100% do timbre ANTERIOR por cima do novo:
        # medido, RMS 0,142 na primeira janela de 20ms contra 0,093 na seguinte,
        # um transiente estranho decaindo bem no ataque da nota.
        _timbre_fade = 0.0
    return _pitch_player

## Escolhe qual síntese sai pelo alto-falante, com crossfade. Aplica NA HORA,
## inclusive no meio de um arrasto: o pedido era ouvir os dois enquanto o dedo
## desliza, e um controle que só valesse no próximo "Começar" (como os dropdowns
## de pista e de modo) não responderia a isso.
func set_pitch_timbre(timbre: int) -> void:
    if timbre != Timbre.ADDITIVE and timbre != Timbre.WAVEGUIDE:
        return
    # Sem esta guarda, reafirmar o timbre atual abriria um crossfade do timbre
    # CONSIGO MESMO -- e aí _pitch_step() chamaria o mesmo passo duas vezes por
    # amostra, avançando a fase em dobro e tocando uma oitava acima.
    if timbre == pitch_timbre:
        return
    _timbre_fade_from = pitch_timbre
    _timbre_fade = 1.0
    pitch_timbre = timbre

## Para o tom contínuo (ex: ao soltar o slider, trocar de modo de input, ou tocar
## uma nota/SFX discreto -- ver _stop_current). As referências (_pitch_player/
## _pitch_playback) somem já-já (síncrono, testável); o player em si esmaece o
## volume por PITCH_STOP_FADE_SEC antes de parar de fato, pra não cortar a
## onda senoidal no meio do ciclo (click audível).
func stop_continuous_pitch() -> void:
    if _pitch_player and is_instance_valid(_pitch_player):
        _fade_out_and_free(_pitch_player)
    _pitch_player = null
    _pitch_playback = null

func _fade_out_and_free(player: AudioStreamPlayer) -> void:
    var tw := create_tween()
    tw.tween_property(player, "volume_db", -80.0, PITCH_STOP_FADE_SEC)
    tw.tween_callback(func():
        if is_instance_valid(player):
            player.stop()
            player.queue_free()
    )

func _process(_delta: float) -> void:
    if _pitch_playback != null:
        _fill_pitch_buffer()

func _fill_pitch_buffer() -> void:
    var lfo_inc := VIBRATO_RATE_HZ / MIX_RATE
    var frames := _pitch_playback.get_frames_available()
    var vibrato_mult := _vibrato_multiplier(_pitch_lfo_phase)
    for i in range(frames):
        # O LFO de vibrato é 6Hz -- recalcular a cada amostra (44100/s) é
        # desnecessário e inaudível a essa taxa de mudança. Recalcula só a
        # cada VIBRATO_CONTROL_RATE_SAMPLES amostras; o valor fica válido
        # (reaproveitado) pras amostras entre atualizações. A taxa continua
        # segura no guia de onda, onde o mesmo multiplicador vira modulação do
        # COMPRIMENTO da corda: o degrau de comprimento a cada 32 amostras é
        # ordens de grandeza menor que o que o slew abaixo já absorve sem
        # estalar.
        if _vibrato_sample_counter == 0:
            vibrato_mult = _vibrato_multiplier(_pitch_lfo_phase)
        _vibrato_sample_counter = (_vibrato_sample_counter + 1) % VIBRATO_CONTROL_RATE_SAMPLES
        var sample := _pitch_step(_pitch_freq * vibrato_mult)
        _pitch_playback.push_frame(Vector2(sample, sample))
        _pitch_lfo_phase = fposmod(_pitch_lfo_phase + lfo_inc, 1.0)

## Uma amostra do tom contínuo: dada a frequência AGORA, devolve o valor e
## avança o estado da síntese.
##
## É aqui que os dois timbres são despachados, e não em _continuous_pitch_sample:
## aquela é uma função pura que recebe a fase de fora, e o guia de onda não tem
## "a fase" nenhuma -- o estado dele são duas linhas de delay que precisam
## avançar exatamente uma vez por amostra. Emendar o segundo algoritmo lá dentro
## obrigaria a espalhar o avanço de estado pelo laço de _fill_pitch_buffer().
func _pitch_step(freq_hz: float) -> float:
    _noise_lp = lerpf(_noise_lp, randf_range(-1.0, 1.0), NOISE_LOWPASS_COEFF)
    var sample := _timbre_step(pitch_timbre, freq_hz)
    if _timbre_fade > 0.0:
        # Os dois passos avançam estados DIFERENTES (set_pitch_timbre garante que
        # os timbres não são o mesmo), então cada um roda uma vez por amostra.
        sample = lerpf(sample, _timbre_step(_timbre_fade_from, freq_hz), _timbre_fade)
        _timbre_fade = maxf(0.0, _timbre_fade - TIMBRE_FADE_PER_SAMPLE)
    return sample

func _timbre_step(timbre: int, freq_hz: float) -> float:
    if timbre == Timbre.WAVEGUIDE:
        return _waveguide_step(freq_hz)
    return _additive_step(freq_hz)

## Timbre aditivo: a amostra é função pura da fase, e só o avanço da fase mora
## aqui.
func _additive_step(freq_hz: float) -> float:
    var sample := _continuous_pitch_sample(_pitch_phase, _pitch_lfo_phase, _noise_lp)
    _pitch_phase = fposmod(_pitch_phase + freq_hz / MIX_RATE, 1.0)
    return sample

## Meio comprimento do laço, já descontado o atraso que WG_LOSS_DELAY_COMP mede.
## Os dois segmentos do arco saem daqui multiplicados por WG_BRIDGE_SEGMENT e
## WG_NUT_SEGMENT, que somam 2 -- então o laço fecha no período da nota
## independentemente de onde o arco esteja. Clampado porque play_continuous_pitch
## aceita qualquer frequência: um valor absurdo não pode ler fora do array.
func _wg_target_delay(freq_hz: float) -> float:
    var round_trip := MIX_RATE / maxf(freq_hz, 1.0) - WG_LOSS_DELAY_COMP
    return clampf(round_trip * 0.5, 2.0, WG_MAX_HALF_DELAY)

func _reset_waveguide(freq_hz: float) -> void:
    _wg_right.resize(WG_LINE_SAMPLES)
    _wg_left.resize(WG_LINE_SAMPLES)
    _wg_right.fill(0.0)
    _wg_left.fill(0.0)
    _wg_write = 0
    _wg_loss = 0.0
    _wg_dc_in = 0.0
    _wg_dc_out = 0.0
    # Direto no alvo, sem passar pelo slew: só a MUDANÇA de nota durante um
    # arrasto precisa ser suave. Começar do comprimento anterior faria toda nota
    # nova entrar deslizando a partir da última.
    _wg_delay = _wg_target_delay(freq_hz)

## Mesa de arco: dada a velocidade RELATIVA entre arco e corda, quanto da força
## do arco a corda leva. É a não-linearidade inteira do modelo, e é dela que sai
## o movimento de Helmholtz.
##
## Com a corda quase acompanhando o arco (diferença perto de zero) o resultado
## satura em 1: a corda GRUDA no arco e é arrastada junto, e a força injetada é a
## diferença inteira. Passando de |diferença| = 0,25/inclinação a curva despenca
## (cai com a 4ª potência) -- a corda ESCORREGA, quase nada é transmitido, e ela
## volta livre até a onda refletida trazê-la para perto da velocidade do arco de
## novo. Esse ciclo gruda/escorrega uma vez por período é o que faz a onda tipo
## dente-de-serra; nenhuma parte dela está escrita aqui.
##
## A curva (|x|+0,75)^-4 e o expoente são os do BowTable do STK (Cook/Scavone).
## O 0,75 é o que põe o topo da curva acima de 1 (0,75^-4 = 3,16) e portanto no
## clamp: é a LARGURA da região de grude, e sem ele não existe grude nenhum.
func _bow_friction(delta_v: float) -> float:
    var x := absf(delta_v) * WG_BOW_TABLE_SLOPE + 0.75
    var x2 := x * x
    return minf(1.0, 1.0 / (x2 * x2))

## Timbre de guia de onda, um passo. A onda percorre a linha da direita até o
## cavalete, reflete invertida e filtrada para a linha da esquerda, volta até a
## pestana e reflete invertida de novo. A saída é o que chega ao cavalete, que é
## também o que num instrumento de verdade empurra o corpo e vira som.
##
## O arco fica no ponto que separa os dois segmentos: a velocidade da corda ali é
## a SOMA das duas ondas que chegam a ele, e a força que a mesa devolve entra nas
## DUAS linhas (é uma junção, não uma ponta -- por isso soma nas duas e não
## reflete). Injetar nas duas também é o que impede a componente contínua do arco
## de crescer dentro do laço: as duas reflexões inversoras a cancelam.
func _waveguide_step(freq_hz: float) -> float:
    _wg_delay += clampf(_wg_target_delay(freq_hz) - _wg_delay, -WG_DELAY_SLEW, WG_DELAY_SLEW)
    var at_bridge := _wg_read(_wg_right, _wg_delay * WG_BRIDGE_SEGMENT)
    var at_nut := _wg_read(_wg_left, _wg_delay * WG_NUT_SEGMENT)
    _wg_loss += WG_LOSS_COEFF * (at_bridge - _wg_loss)
    # Os dois sinais de menos são as reflexões inversoras, e são o que faz esta
    # estrutura soar onde o laço único converge para DC.
    var from_bridge := -_wg_loss * WG_REFLECTION_GAIN
    var from_nut := -at_nut * WG_REFLECTION_GAIN
    var delta_v := WG_BOW_VELOCITY - (from_bridge + from_nut)
    var injected := _bow_friction(delta_v) * delta_v
    _wg_right[_wg_write] = from_nut + injected
    _wg_left[_wg_write] = from_bridge + injected
    _wg_write = (_wg_write + 1) % WG_LINE_SAMPLES
    _wg_dc_out = at_bridge - _wg_dc_in + WG_DC_BLOCK_COEFF * _wg_dc_out
    _wg_dc_in = at_bridge
    # Mesmo tremolo do timbre aditivo: a pressão do arco varia nos dois, e sem
    # ele a diferença entre os timbres viria misturada com uma diferença de
    # articulação que não é do algoritmo.
    var tremolo := 1.0 + TREMOLO_DEPTH * sin((_pitch_lfo_phase + TREMOLO_PHASE_OFFSET) * TAU)
    return clampf(_wg_dc_out * WG_OUTPUT_GAIN * tremolo, -1.0, 1.0)

## Leitura FRACIONÁRIA da linha de delay (interpolação linear entre as duas
## amostras vizinhas). Arredondar o comprimento para inteiro é o atalho óbvio e
## foi medido: numa varredura Dó4->Si4 o pulo máximo amostra-a-amostra quase
## DOBRA, de 0,139 para 0,255, enquanto o do tom parado quase não muda
## (0,132 -> 0,136).
## É a corda dando um pulinho de comprimento toda vez que cruza a fronteira de
## uma amostra -- uma aspereza que só aparece enquanto o dedo desliza, que é
## justamente quando este modo de input está em uso.
func _wg_read(line: PackedFloat32Array, delay: float) -> float:
    var pos := float(_wg_write) - delay
    if pos < 0.0:
        pos += float(WG_LINE_SAMPLES)
    var i0 := int(pos)
    var frac := pos - float(i0)
    i0 = i0 % WG_LINE_SAMPLES
    var i1 := (i0 + 1) % WG_LINE_SAMPLES
    return lerpf(line[i0], line[i1], frac)

## Multiplicador de frequência do vibrato (LFO senoidal, ~6Hz, +-18 cents).
## Cents pra multiplicador de frequência: mult = 2^(cents/1200).
## Nota: GDScript 4.6 não tem uma função global exp2() (só existe em shaders) --
## tentar usá-la aqui quebra o parse do script (autoload falha ao carregar).
## pow(2.0, x) é o jeito correto de calcular isso em GDScript puro.
func _vibrato_multiplier(lfo_phase: float) -> float:
    return pow(2.0, (VIBRATO_DEPTH_CENTS / 1200.0) * sin(lfo_phase * TAU))

## Amostra completa do tom contínuo no timbre ADITIVO: harmônicos tipo corda +
## tremolo (LFO de amplitude) + ruído de arco filtrado. Função pura (não toca
## _pitch_playback nem estado nenhum) -- testável direto por amostra, sem
## precisar de um player real tocando. Quem avança a fase é _additive_step().
func _continuous_pitch_sample(phase: float, lfo_phase: float, noise_lp: float) -> float:
    var tone := _string_harmonics(phase)
    var tremolo := 1.0 + TREMOLO_DEPTH * sin((lfo_phase + TREMOLO_PHASE_OFFSET) * TAU)
    return clampf((tone * tremolo * 0.5) + (noise_lp * BOW_NOISE_GAIN), -1.0, 1.0)

## Soma aditiva dos harmônicos (fundamental + 4 acima), normalizada pela soma
## dos ganhos (HARMONIC_GAIN_TOTAL, pré-computada) -- garante |resultado| <= 1
## antes do envelope de amplitude. Roda por AMOSTRA de áudio, então a soma dos
## ganhos fica pré-computada em vez de recalculada a cada chamada.
func _string_harmonics(phase: float) -> float:
    var sum := 0.0
    for h in range(HARMONIC_GAINS.size()):
        var harmonic_num := h + 1
        sum += HARMONIC_GAINS[h] * sin(phase * TAU * harmonic_num)
    return sum / HARMONIC_GAIN_TOTAL

func _play_synth(freq: float, harsh: bool, duration: float) -> AudioStreamPlayer:
    _stop_current()
    var player := AudioStreamPlayer.new()
    player.stream = _make_stream(freq, harsh, duration)
    add_child(player)
    _current_player = player
    player.finished.connect(_on_player_finished.bind(player))
    player.play()
    return player

func _stop_current() -> void:
    if _current_player and is_instance_valid(_current_player):
        _current_player.stop()
        _current_player.queue_free()
    _current_player = null
    stop_continuous_pitch()

func _on_player_finished(player: AudioStreamPlayer) -> void:
    if not is_instance_valid(player):
        return
    if _current_player == player:
        _current_player = null
    player.queue_free()

func _make_stream(freq: float, harsh: bool, duration: float) -> AudioStreamWAV:
    var total_samples := int(MIX_RATE * duration)
    var attack_samples := int(MIX_RATE * ATTACK_SEC)
    var decay_samples := int(MIX_RATE * DECAY_SEC)
    var release_samples := int(MIX_RATE * RELEASE_SEC)
    var sustain_samples := total_samples - attack_samples - decay_samples - release_samples

    # PCM16 mono (2 bytes por sample). Mono é suficiente — Godot duplica no bus.
    var bytes := PackedByteArray()
    bytes.resize(total_samples * 2)
    var phase := 0.0
    var phase_inc := freq / float(MIX_RATE)
    for idx in range(total_samples):
        var sample := _sample_value(phase, harsh)
        var amplitude := _envelope_at(idx, attack_samples, decay_samples, sustain_samples, release_samples)
        var value := sample * amplitude * 0.5
        var pcm: int = clampi(int(value * 32767.0), -32768, 32767)
        bytes.encode_s16(idx * 2, pcm)
        phase = fposmod(phase + phase_inc, 1.0)

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = int(MIX_RATE)
    stream.stereo = false
    stream.data = bytes
    return stream

func _sample_value(phase: float, harsh: bool) -> float:
    if harsh:
        # square wave para colisão
        return 1.0 if phase < 0.5 else -1.0
    # Piano-like: fundamental + harmônicos pares e ímpares para corpo.
    # Soma máxima teórica ~1.45; com amplitude 0.5 no _make_stream → ~0.72, sem clip.
    var fundamental := sin(phase * TAU)
    var h2 := 0.3 * sin(phase * TAU * 2.0)
    var h3 := 0.12 * sin(phase * TAU * 3.0)
    var h5 := 0.06 * sin(phase * TAU * 5.0)
    return fundamental + h2 + h3 + h5

func _envelope_at(idx: int, a: int, d: int, s: int, r: int) -> float:
    if idx < a:
        return float(idx) / float(a)
    if idx < a + d:
        var t := float(idx - a) / float(d)
        return lerpf(1.0, SUSTAIN_LEVEL, t)
    if idx < a + d + s:
        return SUSTAIN_LEVEL
    # Release com curva exponencial (t²) — mais musical que linear.
    var t := float(idx - a - d - s) / float(r)
    return lerpf(SUSTAIN_LEVEL, 0.0, t * t)
