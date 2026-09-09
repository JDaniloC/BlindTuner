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
# 256 amostras por linha cobrem com folga a oitava do jogo (a nota mais grave,
# 262Hz, pede 83,5 e a mais aguda 44,0) e o tamanho NUNCA muda. Redimensionar as
# linhas a cada frequência nova é a alternativa óbvia e joga fora toda a energia
# já guardada nelas -- a corda recomeçaria do zero a cada evento de arrasto, que
# é o oposto do glissando.
const WG_LINE_SAMPLES := 256
# Filtro de perdas de 1 polo no cavalete: é ele que faz os harmônicos agudos
# morrerem antes do fundamental, como numa corda de verdade.
const WG_LOSS_COEFF := 0.3774
# Ganho de cada reflexão. Ao quadrado (são duas por volta) dá o decaimento da
# corda; perto demais de 1 a corda vira um sino que nunca cala, longe demais e
# o ruído do arco não chega a virar nota.
#
# Com o arco correndo, esta constante também governa quanto tempo a corda leva
# pra ALCANÇAR o volume dela, e é por isso que ela não é 0,998 (o valor "sino",
# tentado primeiro). A 0,998 o ganho por volta é 0,996 e a constante de tempo de
# subida vira ~250 voltas -- 0,95s no Dó, 0,5s no Si: a corda ainda está subindo
# quando o jogador já soltou o dedo. Medido nas 12 notas x 1,5s, com o mesmo
# procedimento nas duas configurações:
#   0,998 -- RMS dos primeiros 200ms 0,0728 contra 0,1009 do resto (-2,8dB: a
#            corda entra fraca), e as janelas de 100ms de todas as notas variando
#            de 0,0348 a 0,2279, ou seja 16,3dB de passeio de envoltória.
#   0,98  -- RMS dos primeiros 200ms 0,1314 contra 0,1432 (-0,7dB: já nasce no
#            volume dela), passeio de 100ms em 9,3dB.
# O passeio que sobra é o que uma corda excitada por RUÍDO tem de nascença; o que
# a mudança tirou foi a subida lenta por cima dele.
#
# 0,98 são 0,9604 por volta, constante de tempo de 94ms no Dó e 50ms no Si. A
# afinação não depende disto: o erro nas 12 notas fica em 0,62 cent, contra 0,55
# a 0,998.
const WG_REFLECTION_GAIN := 0.98
# O filtro de perdas ATRASA o sinal, e esse atraso entra no comprimento do laço
# tanto quanto as linhas de delay. Sem descontá-lo o tom sai BAIXO: zerando esta
# constante, a suíte mede de 16 cents na nota mais grave a 31 na mais aguda --
# inaudível como bug de código e fatal num jogo cuja mecânica inteira é
# reconhecer qual nota soou. 1,65 é o atraso de fase do filtro de 1 polo acima
# (que é (1-a)/a amostras); com ele o erro nas 12 notas cai para 0,5 cent.
const WG_LOSS_DELAY_COMP := 1.65
# O dedo é amostrado por FRAME e o áudio por AMOSTRA, então a frequência nova
# chega como degrau. Aplicar o degrau direto no comprimento da linha estala:
# pulo máximo amostra-a-amostra medido em 0,239, contra 0,030 do mesmo tom
# parado. Com este slew, 0,030 -- indistinguível do tom parado, e ainda assim
# rápido o bastante pra a corda alcançar o comprimento novo (resíduo de 0,4
# amostra meio segundo depois de um salto de oitava inteira).
const WG_DELAY_SLEW := 0.02
# Ruído de arco -- aqui ele é a EXCITAÇÃO da corda (entra na linha de delay),
# não uma camada somada por cima como no timbre aditivo. Nada do ruído cru
# chega à saída: tudo passa pela corda antes.
const WG_BOW_DRIVE := 0.03
# Bloqueio de DC na SAÍDA (não dentro do laço: lá dentro ele adianta a fase de
# 3,4 amostras nas notas do jogo e desafinaria tudo o que WG_LOSS_DELAY_COMP
# acabou de acertar). O arco é ruído aleatório, então a corda acumula um
# deslocamento lento que não é som -- só come margem antes do clipping.
const WG_DC_BLOCK_COEFF := 0.995
# Trocar de timbre não pode virar uma mudança de VOLUME, senão a comparação de
# ouvido -- que é a razão de o interruptor existir -- sai enviesada pelo mais
# alto dos dois. Calibrado por RMS, e não por pico como na primeira versão: o
# pico do aditivo é o estado permanente de uma onda periódica e o do guia de onda
# é uma excursão rara de uma envoltória de ruído, e sonoridade segue RMS. Com os
# dois PICOS casados (ganho 9, pico 0,438) o guia de onda saía 9,7dB abaixo no
# RMS dos primeiros 200ms e 6,9dB no resto -- ou seja, a calibração antiga
# entregava exatamente o viés que este comentário promete impedir.
#
# Quanto dá pra subir quem decide é a MARGEM DE CLIPPING, e ela é apertada porque
# a corda é excitada por RUÍDO: medido nas 12 notas x 1,5s, o fator de crista do
# guia de onda é ~4,7 contra 1,8 do aditivo, que é uma onda periódica (RMS 0,222,
# pico 0,40). Casar o RMS exatamente pediria ganho ~40 e poria o pico em ~1,19 --
# clipping, e o clampf() aqui embaixo esconderia a distorção em vez de deixá-la
# aparecer, que é o modo de falha que o teste de pico existe pra evitar.
#
# 25 é onde as duas restrições se encontram, medido em quatro rodadas: RMS médio
# dos primeiros 200ms entre 0,131 e 0,142 (-3,9 a -4,5dB do aditivo, contra os
# -9,7dB de antes) com pico entre 0,62 e 0,74, que ainda precisa sobreviver ao
# +2,5dB do EQ do bus Strings. Os ~4dB que sobram NÃO fecham por calibração:
# fechá-los pede trocar a excitação de ruído por um dente-de-serra de stick-slip
# (que é o que um arco faz de verdade, e tem crista de onda periódica). É
# redesenho de síntese, e faz sentido depois de o jogador dizer se quer este
# timbre -- que é a pergunta que o interruptor existe pra responder.
const WG_OUTPUT_GAIN := 25.0

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

## Meio comprimento do laço (o que cabe em CADA uma das duas linhas), já
## descontado o atraso do filtro de perdas. Clampado porque play_continuous_pitch
## aceita qualquer frequência: um valor absurdo não pode ler fora do array.
func _wg_target_delay(freq_hz: float) -> float:
    var round_trip := MIX_RATE / maxf(freq_hz, 1.0) - WG_LOSS_DELAY_COMP
    return clampf(round_trip * 0.5, 2.0, float(WG_LINE_SAMPLES - 2))

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

## Timbre de guia de onda, um passo. A onda percorre a linha da direita até o
## cavalete, reflete invertida e filtrada para a linha da esquerda, volta até a
## pestana e reflete invertida de novo. A saída é o que chega ao cavalete, que é
## também o que num instrumento de verdade empurra o corpo e vira som.
func _waveguide_step(freq_hz: float) -> float:
    _wg_delay += clampf(_wg_target_delay(freq_hz) - _wg_delay, -WG_DELAY_SLEW, WG_DELAY_SLEW)
    var at_bridge := _wg_read(_wg_right, _wg_delay)
    var at_nut := _wg_read(_wg_left, _wg_delay)
    _wg_loss += WG_LOSS_COEFF * (at_bridge - _wg_loss)
    # Os dois sinais de menos são as reflexões inversoras, e são o que faz esta
    # estrutura soar onde o laço único converge para DC. O arco entra na pestana.
    _wg_right[_wg_write] = -at_nut * WG_REFLECTION_GAIN + _noise_lp * WG_BOW_DRIVE
    _wg_left[_wg_write] = -_wg_loss * WG_REFLECTION_GAIN
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
## foi medido: o pulo máximo amostra-a-amostra sobe de 0,030 para 0,040 durante
## um arrasto, porque a corda dá um pulinho de comprimento toda vez que cruza a
## fronteira de uma amostra -- uma aspereza contínua enquanto o dedo desliza,
## que é justamente quando este modo de input está em uso.
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
