extends GutTest

func test_play_note_returns_a_player_node():
    var player = AudioManager.play_note("A4")
    assert_not_null(player)
    assert_true(player is AudioStreamPlayer)

func test_play_note_for_all_12_notes_does_not_crash():
    for key in NoteMapping.NOTES.keys():
        var player = AudioManager.play_note(key)
        assert_not_null(player, "play_note('%s') retornou null" % key)

func test_play_collision_sfx_returns_a_player_node():
    var player = AudioManager.play_collision_sfx()
    assert_not_null(player)
    assert_true(player is AudioStreamPlayer)

func test_play_note_miss_sfx_returns_a_player_node():
    var player = AudioManager.play_note_miss_sfx()
    assert_not_null(player)
    assert_true(player is AudioStreamPlayer)

func test_note_miss_envelope_fades_near_silence_by_last_sample():
    # NOTE_MISS_DURATION_SEC precisa ser maior que ATTACK_SEC+DECAY_SEC, senão o
    # buffer termina no meio do decay (nunca alcança release) e corta com um
    # click audível em vez de esmaecer a 0, como play_note e play_collision_sfx fazem.
    var duration = AudioManager.NOTE_MISS_DURATION_SEC
    var total_samples := int(AudioManager.MIX_RATE * duration)
    var attack_samples := int(AudioManager.MIX_RATE * AudioManager.ATTACK_SEC)
    var decay_samples := int(AudioManager.MIX_RATE * AudioManager.DECAY_SEC)
    var release_samples := int(AudioManager.MIX_RATE * AudioManager.RELEASE_SEC)
    var sustain_samples := total_samples - attack_samples - decay_samples - release_samples
    var last_envelope = AudioManager._envelope_at(total_samples - 1, attack_samples,
        decay_samples, sustain_samples, release_samples)
    assert_lt(last_envelope, 0.05,
        "envelope deveria esmaecer perto de 0 no último sample, não cortar no meio do decay")

func after_each():
    # _stop_current() para tanto o player discreto (play_note) quanto o
    # contínuo (play_continuous_pitch) -- stop_continuous_pitch() sozinho
    # deixava um player discreto órfão de testes anteriores (ex: play_note()),
    # causando "ObjectDB leaked at exit" ao rodar este arquivo isolado.
    AudioManager._stop_current()
    # O timbre é estado GLOBAL de um autoload: sem devolver ao padrão, um teste
    # que troca de timbre faz o próximo (e o test_game_hud, que lê o mesmo campo
    # pra montar o interruptor) enxergar a escolha do anterior.
    AudioManager.set_pitch_timbre(AudioManager.Timbre.ADDITIVE)
    AudioManager._timbre_fade = 0.0

func test_play_continuous_pitch_returns_a_player_node():
    var player = AudioManager.play_continuous_pitch(440.0)
    assert_not_null(player)
    assert_true(player is AudioStreamPlayer)

func test_play_continuous_pitch_reuses_same_player_on_frequency_change():
    var p1 = AudioManager.play_continuous_pitch(440.0)
    var p2 = AudioManager.play_continuous_pitch(494.0)
    assert_eq(p1, p2, "mudar de frequência não deve recriar o player (glissando contínuo)")

func test_play_continuous_pitch_preserves_phase_across_frequency_change():
    # Pinning test: a característica que distingue a implementação real (fase
    # contínua, sem clique/salto) do fallback "resample e reinicia" que a spec
    # rejeitou explicitamente. Uma mutação de uma linha (mover _pitch_phase = 0.0
    # pra fora do ramo "cria novo player") reintroduziria o salto sem quebrar
    # nenhum outro teste -- este pina o comportamento certo.
    AudioManager.play_continuous_pitch(440.0)
    AudioManager._pitch_phase = 0.37
    AudioManager.play_continuous_pitch(494.0)
    assert_eq(AudioManager._pitch_phase, 0.37,
        "trocar de frequência não deve resetar a fase (senão o glissando salta/estala)")
    assert_eq(AudioManager._pitch_freq, 494.0, "a frequência precisa atualizar mesmo sem resetar a fase")

func test_play_continuous_pitch_stops_regular_note_playback():
    var before = AudioManager.play_note("A4")
    AudioManager.play_continuous_pitch(440.0)
    assert_false(before.playing, "nota discreta anterior deve parar")

func test_play_note_stops_continuous_pitch():
    AudioManager.play_continuous_pitch(440.0)
    AudioManager.play_note("A4")
    assert_null(AudioManager._pitch_player, "pitch contínuo deve parar quando uma nota discreta toca")

func test_stop_continuous_pitch_clears_player():
    AudioManager.play_continuous_pitch(440.0)
    AudioManager.stop_continuous_pitch()
    assert_null(AudioManager._pitch_player)

func test_string_harmonics_zero_at_phase_zero():
    var v = AudioManager._string_harmonics(0.0)
    assert_true(absf(v) < 0.0001, "fase 0 -- todos os harmônicos (senos) partem de 0")

func test_string_harmonics_does_not_exceed_unity():
    for i in range(100):
        var phase = i / 100.0
        var v = AudioManager._string_harmonics(phase)
        assert_true(absf(v) <= 1.0001, "soma normalizada de harmônicos não deve estourar +-1")

func test_vibrato_multiplier_is_one_at_lfo_phase_zero():
    var m = AudioManager._vibrato_multiplier(0.0)
    assert_true(absf(m - 1.0) < 0.0001, "vibrato multiplier deveria ser 1.0 em lfo_phase=0")

func test_vibrato_multiplier_stays_within_expected_cents_range():
    var max_mult = pow(2.0, AudioManager.VIBRATO_DEPTH_CENTS / 1200.0)
    for i in range(20):
        var lfo = i / 20.0
        var m = AudioManager._vibrato_multiplier(lfo)
        assert_true(m <= max_mult + 0.0001 and m >= (1.0 / max_mult) - 0.0001,
            "vibrato multiplier fora do range esperado em lfo_phase=%f" % lfo)

func test_continuous_pitch_sample_never_clips():
    # Antes testava absf(v) <= 1.0, mas _continuous_pitch_sample() sempre
    # termina com clampf(..., -1.0, 1.0) -- essa asserção não podia falhar,
    # só testava o clamp. O pico real pré-clamp medido é ~0.4227; asserção
    # bem mais apertada (< 0.9) que falharia de verdade se a amplitude subisse
    # sem controle, sem depender do clamp pra "salvar" o teste.
    for i in range(50):
        var phase = i / 50.0
        var lfo = fmod(i * 0.13, 1.0)
        var v = AudioManager._continuous_pitch_sample(phase, lfo, 1.0)  # noise_lp no pior caso
        assert_true(absf(v) < 0.9, "amostra do tom contínuo deveria ficar bem abaixo do clamp mesmo no pior caso de ruído")

func test_fill_pitch_buffer_still_preserves_phase_across_frequency_change():
    # Regressão: a síntese enriquecida não pode quebrar a garantia de fase
    # contínua (glissando sem clique/salto) já pinada pelo teste homônimo sem
    # "fill_pitch_buffer" no nome -- este exercita o caminho real (_process
    # via _fill_pitch_buffer), não só a atribuição direta de _pitch_freq.
    AudioManager.play_continuous_pitch(440.0)
    AudioManager._pitch_phase = 0.37
    AudioManager._fill_pitch_buffer()
    AudioManager.play_continuous_pitch(494.0)
    assert_true(AudioManager._pitch_phase != 0.0,
        "_fill_pitch_buffer não deveria resetar _pitch_phase a cada chamada")

func test_strings_bus_created_on_ready():
    assert_true(AudioServer.get_bus_index(AudioManager.STRINGS_BUS_NAME) != -1,
        "bus Strings deveria existir (criado no _ready() do AudioManager)")

func test_strings_bus_has_eq_and_chorus_effects():
    var idx = AudioServer.get_bus_index(AudioManager.STRINGS_BUS_NAME)
    assert_eq(AudioServer.get_bus_effect_count(idx), 2)
    assert_true(AudioServer.get_bus_effect(idx, 0) is AudioEffectEQ10)
    assert_true(AudioServer.get_bus_effect(idx, 1) is AudioEffectChorus)

func test_continuous_pitch_player_routes_to_strings_bus():
    var player = AudioManager.play_continuous_pitch(440.0)
    assert_eq(player.bus, AudioManager.STRINGS_BUS_NAME)

func test_ensure_strings_bus_is_idempotent():
    var count_before = AudioServer.bus_count
    AudioManager._ensure_strings_bus()
    assert_eq(AudioServer.bus_count, count_before, "chamar de novo não deveria duplicar o bus")

func test_eq10_band_index_for_maps_to_nearest_band():
    assert_eq(AudioManager._eq10_band_index_for(300.0), 3)   # banda de 250Hz
    assert_eq(AudioManager._eq10_band_index_for(700.0), 4)   # banda de 500Hz
    assert_eq(AudioManager._eq10_band_index_for(2500.0), 6)  # banda de 2000Hz

# --- Timbre alternativo do Scroll: guia de onda ---------------------------------

## Resposta ao impulso do guia de onda, DETERMINÍSTICA: uma única amostra de
## excitação de arco e depois silêncio absoluto, pra a corda soar sozinha. O
## ruído de arco de verdade é randf_range() por amostra -- medir afinação em
## cima dele daria um número diferente a cada rodada da suíte.
func _waveguide_ring(freq: float, warm: int, n: int) -> PackedFloat32Array:
    AudioManager._reset_waveguide(freq)
    AudioManager._pitch_lfo_phase = 0.0  # tremolo constante: só escala, não desloca período
    AudioManager._noise_lp = 1.0
    AudioManager._waveguide_step(freq)
    AudioManager._noise_lp = 0.0
    for i in range(warm):
        AudioManager._waveguide_step(freq)
    var buf := PackedFloat32Array()
    buf.resize(n)
    for i in range(n):
        buf[i] = AudioManager._waveguide_step(freq)
    return buf

## Período dominante do sinal, em amostras, por autocorrelação NORMALIZADA com
## refino parabólico.
##
## Normalizada (divide pela energia das duas janelas) e não crua: a corda decai,
## e a correlação crua puxa o pico pros lags menores porque o começo da janela
## pesa mais -- viés medido de vários cents, o bastante pra o teste reprovar uma
## afinação correta.
##
## Só 9 lags em volta do período esperado, e não uma varredura larga: é 20x mais
## barato e ainda cobre +-4 amostras, que no agudo são +-78 cents. A falha que
## este teste existe pra pegar (não compensar o atraso do filtro de perdas) vale
## 17 a 31 cents -- cai bem dentro da janela.
func _dominant_period(buf: PackedFloat32Array, expected: float) -> float:
    var center := int(round(expected))
    var span := buf.size() - center - 5
    var mean := 0.0
    for v in buf:
        mean += v
    mean /= float(buf.size())
    var correlations := {}
    var best_lag := center
    var best := -INF
    for lag in range(center - 4, center + 5):
        var num := 0.0
        var energy_a := 0.0
        var energy_b := 0.0
        for i in range(span):
            var a := buf[i] - mean
            var b := buf[i + lag] - mean
            num += a * b
            energy_a += a * a
            energy_b += b * b
        var r: float = num / sqrt(maxf(energy_a * energy_b, 1e-30))
        correlations[lag] = r
        if r > best:
            best = r
            best_lag = lag
    if not correlations.has(best_lag - 1) or not correlations.has(best_lag + 1):
        return float(best_lag)
    var y0: float = correlations[best_lag - 1]
    var y1: float = correlations[best_lag]
    var y2: float = correlations[best_lag + 1]
    var denom := y0 - 2.0 * y1 + y2
    if absf(denom) < 1e-12:
        return float(best_lag)
    return float(best_lag) + 0.5 * (y0 - y2) / denom

func test_pitch_timbre_defaults_to_the_sound_the_game_already_had():
    # O timbre alternativo existe pra ser COMPARADO. Qual dos dois vira o padrão
    # é decisão do jogador depois de ouvir os dois -- até lá, quem abre o jogo
    # ouve exatamente o que ouvia antes.
    assert_eq(AudioManager.pitch_timbre, AudioManager.Timbre.ADDITIVE)

func test_waveguide_oscillates_instead_of_converging_to_dc():
    # A armadilha central deste algoritmo: um laço ÚNICO de Karplus-Strong foi
    # medido e não oscila -- converge para uma constante (DC 0,2786), porque o
    # filtro de perdas tem ganho 1 em DC e o que volta ao laço nunca troca de
    # sinal. Só a estrutura de guia de onda (duas linhas de delay, reflexão
    # inversora nas duas pontas) produz som. Um sinal preso em DC passaria por
    # "sem estouro de amplitude" e por "não estoura o clamp" sem tossir: este é
    # o teste que separa som de silêncio.
    var buf := _waveguide_ring(440.0, 2205, 2048)
    var lo := INF
    var hi := -INF
    var mean := 0.0
    for v in buf:
        lo = minf(lo, v)
        hi = maxf(hi, v)
        mean += v
    mean /= float(buf.size())
    var swing: float = hi - lo
    assert_gt(swing, 0.01,
        "a corda tem que continuar balançando 2048 amostras depois do impulso, não parar num valor fixo")
    assert_lt(absf(mean), swing * 0.2,
        "o sinal oscila EM VOLTA de zero -- média perto do pico é sinal de que virou DC")

func test_waveguide_is_in_tune_within_one_cent_for_all_12_notes():
    # Sem compensar o atraso do filtro de perdas (WG_LOSS_DELAY_COMP) o tom sai
    # BAIXO -- zerando a constante, este teste mede de 16 cents na nota mais
    # grave a 31 na mais aguda. É inaudível como bug de código e fatal num jogo
    # cuja mecânica inteira é reconhecer qual nota soou.
    for key in NoteMapping.NOTES:
        var freq := float(NoteMapping.NOTES[key]["freq"])
        var buf := _waveguide_ring(freq, 2205, 4096)
        var period := _dominant_period(buf, AudioManager.MIX_RATE / freq)
        var measured: float = AudioManager.MIX_RATE / period
        var cents: float = 1200.0 * log(measured / freq) / log(2.0)
        assert_lt(absf(cents), 1.0,
            "%s deveria soar a %.0fHz e soa a %.1fHz (%+.2f cents)" % [key, freq, measured, cents])

func test_waveguide_stays_well_below_the_clamp_with_the_bow_running():
    # Ressoador de Q alto excitado continuamente: a energia se acumula ao longo
    # de segundos, então o pico não aparece nas primeiras amostras. Se a saída
    # encostasse em +-1 o clampf() salvaria a asserção e esconderia a distorção,
    # como já tinha acontecido no teste do timbre aditivo -- por isso a margem
    # aqui é bem abaixo do clamp, não igual a ele.
    #
    # AS 12 NOTAS, e não uma só: desde que WG_OUTPUT_GAIN passou a ser calibrado
    # por RMS, o pico deixou de ser folgado (0,25 antes, 0,71 agora -- ver o
    # comentário da constante) e virou a restrição que limita o ganho. Pico é
    # estatística de extremo: uma nota só, medida uma vez, é um sorteio, e é
    # exatamente assim que uma margem some sem ninguém ver.
    AudioManager.set_pitch_timbre(AudioManager.Timbre.WAVEGUIDE)
    var peak := 0.0
    for key in NoteMapping.NOTES:
        var freq := float(NoteMapping.NOTES[key]["freq"])
        AudioManager.play_continuous_pitch(freq)
        for i in range(int(AudioManager.MIX_RATE * 1.5)):
            peak = maxf(peak, absf(AudioManager._pitch_step(freq)))
    assert_lt(peak, 0.9, "pico do guia de onda com arco contínuo nas 12 notas: %.3f" % peak)
    assert_gt(peak, 0.02, "e não pode estar mudo -- pico medido: %.3f" % peak)

## RMS de uma janela do timbre dado, começando com a síntese ZERADA -- que é como
## um arrasto de verdade começa (play_continuous_pitch reseta fase e corda).
## `skip` descarta as amostras iniciais pra medir um trecho mais adiante.
func _timbre_rms(timbre: int, freq: float, skip: int, n: int) -> float:
    AudioManager.set_pitch_timbre(timbre)
    AudioManager._timbre_fade = 0.0
    AudioManager._pitch_phase = 0.0
    AudioManager._pitch_lfo_phase = 0.0
    AudioManager._reset_waveguide(freq)
    for i in range(skip):
        AudioManager._pitch_step(freq)
    var acc := 0.0
    for i in range(n):
        var s: float = AudioManager._pitch_step(freq)
        acc += s * s
    return sqrt(acc / float(n))

## Média do RMS de uma janela sobre as 12 notas, com SEMENTE FIXA.
##
## A média, e não nota a nota: 200ms de um ressoador excitado por RUÍDO tem RMS
## genuinamente variável (medido: 0,038 a 0,073 entre as notas, ou +-3dB em volta
## da média), então uma asserção por nota reprovaria por sorte do dado.
##
## E a semente é fixa porque a média das 12 ainda passeia ~0,6dB entre rodadas.
## Aqui a separação é enorme (-4dB contra -13dB do defeito), então a semente é
## higiene e não necessidade -- mas troca "distribuição que eu espero" por "número
## que eu medi", que é o que uma asserção consegue defender, e é de graça.
## randomize() no fim devolve o RNG global pros testes seguintes (é global de
## verdade: randf_range() do AudioManager bebe dele).
func _mean_rms_over_the_octave(timbre: int, skip_sec: float, win_sec: float) -> float:
    seed(20260909)
    var total := 0.0
    for key in NoteMapping.NOTES:
        total += _timbre_rms(timbre, float(NoteMapping.NOTES[key]["freq"]),
            int(AudioManager.MIX_RATE * skip_sec), int(AudioManager.MIX_RATE * win_sec))
    randomize()
    return total / float(NoteMapping.NOTES.size())

func test_the_additive_does_not_drown_out_the_waveguide_in_the_first_200ms():
    # O interruptor de timbre existe só pra comparar os dois de ouvido, e uma
    # comparação em que um lado é mais alto sai enviesada pra ele -- é o que
    # WG_OUTPUT_GAIN promete impedir. Casar os PICOS (a primeira calibração) mede
    # a grandeza errada: o pico do aditivo é o estado permanente de uma onda
    # periódica e o do guia de onda é uma excursão rara de uma envoltória de
    # ruído, e sonoridade segue RMS.
    #
    # A janela é curta de propósito: num arrasto curto (desliza e solta) é nos
    # primeiros 200ms que o jogador precisa reconhecer a altura, e era ali que o
    # guia de onda estava 9,7dB abaixo. O teste de pico que já existia passa com
    # o sinal 14dB abaixo, então não pega nada disto.
    #
    # A faixa é larga e assimétrica, e o teste se chama "não afoga" e não "mesmo
    # volume", porque -4dB é onde a coisa REALMENTE está: a margem de clipping não
    # deixa subir mais (ver WG_OUTPUT_GAIN -- ruído tem fator de crista 4,7 contra
    # 1,8 de uma onda periódica, então casar o RMS poria o pico em ~1,19). Prometer
    # paridade no nome enquanto a medição diz -4 seria o mesmo tipo de mentira que
    # a calibração por pico era. -6dB dá 1,5dB de folga sobre o pior valor medido
    # em quatro rodadas (-4,5) e ainda reprova o defeito com 7dB de sobra; +2dB
    # porque MAIS ALTO que o aditivo é o mesmo viés na direção contrária, e aí não
    # há margem de clipping que justifique.
    var add := _mean_rms_over_the_octave(AudioManager.Timbre.ADDITIVE, 0.0, 0.2)
    var wg := _mean_rms_over_the_octave(AudioManager.Timbre.WAVEGUIDE, 0.0, 0.2)
    var db: float = 20.0 * log(wg / add) / log(10.0)
    assert_between(db, -6.0, 2.0,
        "guia de onda %+.1fdB do aditivo nos primeiros 200ms (RMS %.4f contra %.4f)" % [db, wg, add])

func test_the_bowed_string_reaches_its_own_volume_inside_the_first_200ms():
    # Este é sobre a SUBIDA, não sobre o nível: WG_REFLECTION_GAIN governa quanto
    # tempo a corda leva pra alcançar o volume dela com o arco correndo, e a
    # 0,998 ela ainda estava subindo depois de o jogador ter soltado o dedo
    # (medido nas 12 notas: os primeiros 200ms saíam 2,8dB abaixo do resto do
    # arrasto, 0,0728 contra 0,1009).
    #
    # Mas a medição é pelo DECAIMENTO depois de um impulso, e não por essa razão.
    # A constante de tempo é a mesma -- é o ganho do laço que manda nas duas --
    # e a diferença é que o arco é RUÍDO: a primeira versão deste teste comparava
    # o RMS dos primeiros 200ms com o do resto e não separava as configurações. Os
    # números: -0,7dB com a corda certa contra -2,6dB com a antiga, e uma rodada
    # do build CERTO (só o ganho de saída mutado, que nem entra nesta razão)
    # medindo -2,2 -- ou seja, a asserção teria reprovado um build bom. A resposta
    # ao impulso não tem randf() nenhum: mesma física, número reprodutível.
    #
    # Medido nas duas configurações, sem sobreposição: 0,98 dá tau de 38ms no Si a
    # 73ms no Dó, e 0,998 dá de 123 a 245ms. O limiar de 100ms fica no meio, com
    # ~30% de folga pros dois lados.
    for key in ["C4", "E4", "B4"]:
        var freq := float(NoteMapping.NOTES[key]["freq"])
        var buf := _waveguide_ring(freq, 0, int(AudioManager.MIX_RATE * 0.2))
        var cedo := _ring_rms(buf, 0.05, 0.1)
        var tarde := _ring_rms(buf, 0.15, 0.2)
        var tau: float = -0.1 / log(tarde / cedo)
        assert_lt(tau, 0.1,
            "%s: a corda leva %.0fms pra assentar, e um arrasto curto acaba antes disso" % [key, tau * 1000.0])

## RMS de um trecho da resposta ao impulso, delimitado em SEGUNDOS.
func _ring_rms(buf: PackedFloat32Array, de_sec: float, ate_sec: float) -> float:
    var de := int(AudioManager.MIX_RATE * de_sec)
    var ate := int(AudioManager.MIX_RATE * ate_sec)
    var acc := 0.0
    for i in range(de, ate):
        acc += buf[i] * buf[i]
    return sqrt(acc / float(ate - de))

func test_switching_timbre_with_no_tone_playing_does_not_arm_the_crossfade():
    # _timbre_fade só decai dentro de _pitch_step(), que só roda enquanto há tom
    # no ar. Apertar o interruptor SEM nada tocando -- o fluxo mais provável do
    # recurso: aperta e só então arrasta -- deixava o fade armado em 1,0, e os
    # primeiros 20ms do arrasto seguinte saíam com 100% do timbre ANTERIOR por
    # cima do novo (medido: RMS 0,142 na primeira janela de 20ms contra 0,093 na
    # seguinte). test_switching_timbre_mid_note_crossfades_instead_of_jumping não
    # pega isto porque só troca DURANTE um tom já tocando.
    AudioManager.stop_continuous_pitch()
    AudioManager.set_pitch_timbre(AudioManager.Timbre.WAVEGUIDE)
    assert_eq(AudioManager._timbre_fade, 1.0,
        "trocar de timbre arma o crossfade -- é o passo anterior ao que este teste vigia")
    AudioManager.play_continuous_pitch(330.0)
    assert_eq(AudioManager._timbre_fade, 0.0,
        "começar um arrasto tem que zerar o crossfade pendente, como já zera fase e corda")

func test_waveguide_keeps_the_string_ringing_across_a_frequency_change():
    # A mesma garantia de glissando que o timbre aditivo já tinha, no timbre
    # novo: arrastar o dedo muda o comprimento da corda, não troca de corda.
    # Zerar as linhas de delay a cada frequência nova mataria a energia
    # acumulada e o glissando viraria uma sequência de ataques.
    AudioManager.set_pitch_timbre(AudioManager.Timbre.WAVEGUIDE)
    var p1 = AudioManager.play_continuous_pitch(440.0)
    for i in range(500):
        AudioManager._pitch_step(440.0)
    var delay_before = AudioManager._wg_delay
    var p2 = AudioManager.play_continuous_pitch(494.0)
    assert_eq(p1, p2, "mudar de frequência não deve recriar o player")
    assert_eq(AudioManager._wg_delay, delay_before,
        "trocar de frequência não pode ressetar a corda (senão o glissando vira ataque)")

func test_waveguide_delay_slews_instead_of_jumping_to_the_new_length():
    # O dedo é amostrado por FRAME e o áudio por AMOSTRA: entre dois eventos de
    # arrasto a frequência chega como um degrau. Aplicar o degrau direto no
    # comprimento da linha de delay foi medido -- o pulo máximo amostra-a-amostra
    # salta de 0,030 (o mesmo tom parado) para 0,239, que é o estalo. Com o slew
    # de WG_DELAY_SLEW por amostra fica em 0,030, indistinguível do tom parado.
    AudioManager._reset_waveguide(262.0)
    var start = AudioManager._wg_delay
    AudioManager._noise_lp = 0.0
    AudioManager._waveguide_step(494.0)
    assert_almost_eq(AudioManager._wg_delay, start - AudioManager.WG_DELAY_SLEW, 1e-6,
        "uma amostra só pode andar WG_DELAY_SLEW em direção ao novo comprimento")
    var target = AudioManager._wg_target_delay(494.0)
    for i in range(4000):
        AudioManager._waveguide_step(494.0)
    assert_almost_eq(AudioManager._wg_delay, target, 1e-4,
        "e o slew tem que CHEGAR: um arrasto inteiro não pode terminar desafinado")

func test_switching_timbre_mid_note_crossfades_instead_of_jumping():
    # Trocar de timbre no meio de um arrasto é o ponto do interruptor. Sem
    # crossfade, a amostra pula do valor de uma síntese pro da outra num único
    # frame de áudio -- estalo garantido, e justamente na hora em que o jogador
    # está prestando atenção na diferença entre os dois sons.
    AudioManager.play_continuous_pitch(440.0)
    var steady := _max_sample_jump(2000, 440.0)
    AudioManager.set_pitch_timbre(AudioManager.Timbre.WAVEGUIDE)
    var into_waveguide := _max_sample_jump(2000, 440.0)
    assert_lt(into_waveguide, steady * 1.5,
        "entrar no guia de onda pulou %.4f, contra %.4f do tom estável" % [into_waveguide, steady])
    for i in range(20000):
        AudioManager._pitch_step(440.0)  # deixa a corda com energia de verdade
    AudioManager.set_pitch_timbre(AudioManager.Timbre.ADDITIVE)
    var back_to_additive := _max_sample_jump(2000, 440.0)
    assert_lt(back_to_additive, steady * 1.5,
        "voltar pro aditivo pulou %.4f, contra %.4f do tom estável" % [back_to_additive, steady])

func _max_sample_jump(n: int, freq: float) -> float:
    var prev: float = AudioManager._pitch_step(freq)
    var worst := 0.0
    for i in range(n):
        var s: float = AudioManager._pitch_step(freq)
        worst = maxf(worst, absf(s - prev))
        prev = s
    return worst

func test_set_pitch_timbre_ignores_a_value_that_is_not_a_timbre():
    AudioManager.set_pitch_timbre(99)
    assert_eq(AudioManager.pitch_timbre, AudioManager.Timbre.ADDITIVE)

func test_setting_the_timbre_it_already_has_does_not_start_a_crossfade():
    # Sem essa guarda, tocar no interruptor sem mudar nada (ou qualquer código
    # que reafirme o timbre atual) faria o crossfade misturar o timbre CONSIGO
    # MESMO -- e as duas chamadas por amostra avançariam a fase duas vezes,
    # dobrando a frequência que sai.
    AudioManager.set_pitch_timbre(AudioManager.Timbre.ADDITIVE)
    assert_eq(AudioManager._timbre_fade, 0.0)

func test_continuous_pitch_still_uses_the_additive_synthesis_by_default():
    # Pinning: o despacho por timbre não pode ter trocado o caminho padrão. Uma
    # amostra do caminho default tem que bater com _continuous_pitch_sample(),
    # que é a síntese aditiva de sempre.
    AudioManager._pitch_phase = 0.11
    AudioManager._pitch_lfo_phase = 0.0
    AudioManager._noise_lp = 0.0
    var expected = AudioManager._continuous_pitch_sample(0.11, 0.0, 0.0)
    var got = AudioManager._additive_step(440.0)
    assert_almost_eq(got, expected, 1e-6)
