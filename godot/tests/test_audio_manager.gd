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

## O guia de onda soando com o arco correndo, que é o único jeito de ele soar --
## e, ao contrário da versão excitada por ruído, é DETERMINÍSTICO: a mesa de arco
## não sorteia nada, então a mesma nota dá exatamente o mesmo buffer em toda
## rodada da suíte.
##
## A versão anterior deste helper media a resposta ao IMPULSO (uma amostra de
## ruído e depois silêncio) justamente pra fugir do randf_range() por amostra. O
## preço escondido era medir o laço de atraso SOZINHO, sem a excitação -- e foi
## por isso que o teste de afinação daqui de baixo passava com folga enquanto o
## som que o jogador ouvia passeava dezenas de cents.
func _waveguide_ring(freq: float, warm: int, n: int) -> PackedFloat32Array:
    AudioManager._reset_waveguide(freq)
    AudioManager._pitch_lfo_phase = 0.0  # tremolo constante: só escala, não desloca período
    for i in range(warm):
        AudioManager._waveguide_step(freq)
    var buf := PackedFloat32Array()
    buf.resize(n)
    for i in range(n):
        buf[i] = AudioManager._waveguide_step(freq)
    return buf

## Fase da componente de f0 num bloco de `m` amostras a partir de `start`, contra
## um oscilador de referência ancorado na amostra 0 do buffer.
func _phase_at(buf: PackedFloat32Array, start: int, m: int, f0: float) -> float:
    var re := 0.0
    var im := 0.0
    for i in range(start, start + m):
        var a: float = TAU * f0 * float(i) / AudioManager.MIX_RATE
        re += buf[i] * cos(a)
        im -= buf[i] * sin(a)
    return atan2(im, re)

## Erro de afinação em cents, pelo ARRASTO DE FASE da fundamental entre dois
## blocos distantes: se o tom sai 1 cent alto, a fase dele adianta 1 cent de
## período por período, e em ~0,8s isso vira um ângulo grande e fácil de medir.
##
## A versão anterior media o período por autocorrelação com refino parabólico
## numa janela de +-4 lags. Duas armadilhas, as duas medidas:
##   - a janela SATURA. Todo timbre e todo parâmetro davam o mesmo intervalo
##     [+1,4; +2,8] cents, que é exatamente a borda da janela -- não era o sinal,
##     era o teto do medidor.
##   - o refino parabólico enviesa quando a onda tem quina (dente-de-serra), que
##     é justamente o que uma corda friccionada produz.
## Este medidor lê -0,02 cent no timbre aditivo, cuja frequência é exata por
## construção -- que é a calibração que o outro não tinha.
func _cents_off(buf: PackedFloat32Array, f0: float, m: int, near: int) -> float:
    var far := buf.size() - m
    var p0 := _phase_at(buf, 0, m, f0)
    # O bloco próximo só existe pra desambiguar as voltas inteiras de fase que o
    # bloco distante acumula -- sozinho ele é preciso mas ambíguo.
    var coarse: float = fposmod(_phase_at(buf, near, m, f0) - p0 + PI, TAU) - PI
    var df: float = coarse * AudioManager.MIX_RATE / (TAU * float(near))
    var raw: float = _phase_at(buf, far, m, f0) - p0
    var turns: float = round((TAU * df * float(far) / AudioManager.MIX_RATE - raw) / TAU)
    var measured: float = f0 + (raw + turns * TAU) * AudioManager.MIX_RATE / (TAU * float(far))
    return 1200.0 * log(measured / f0) / log(2.0)

func test_the_bow_table_sticks_near_zero_and_slips_past_the_threshold():
    # A mesa de fricção é a não-linearidade inteira do modelo. Com a corda
    # acompanhando o arco (diferença de velocidade perto de zero) ela GRUDA: o
    # atrito satura em 1 e a corda é arrastada junto. Passando do limiar
    # (0,25/inclinação) ela ESCORREGA e o atrito despenca.
    var limiar: float = 0.25 / AudioManager.WG_BOW_TABLE_SLOPE
    assert_eq(AudioManager._bow_friction(0.0), 1.0, "parado em relação ao arco, a corda gruda")
    assert_eq(AudioManager._bow_friction(limiar * 0.99), 1.0, "dentro do limiar ainda é grude")
    assert_lt(AudioManager._bow_friction(limiar * 2.0), 0.5, "passando do limiar, escorrega")
    assert_lt(AudioManager._bow_friction(limiar * 8.0), 0.02, "e escorrega cada vez mais")
    assert_almost_eq(AudioManager._bow_friction(-0.3), AudioManager._bow_friction(0.3), 1e-9,
        "o atrito não sabe pra que lado a corda está indo")

func test_the_bow_table_force_falls_after_its_peak():
    # É ESTE trecho de inclinação NEGATIVA -- puxar mais forte transmitindo menos
    # força -- que faz a corda oscilar em vez de só ser arrastada. Uma mesa
    # monótona (força sempre crescendo com a diferença de velocidade) é o que uma
    # implementação "simplificada" produziria, e ela não tem stick-slip nenhum:
    # a corda grudaria no arco e ficaria lá.
    var pico := 0.0
    var pico_em := 0.0
    for i in range(1, 400):
        var dv: float = float(i) * 0.005
        var forca: float = AudioManager._bow_friction(dv) * dv
        if forca > pico:
            pico = forca
            pico_em = dv
    assert_gt(pico, 0.0)
    assert_lt(pico_em, 1.9, "o pico de força tem que ficar dentro da faixa varrida")
    assert_lt(AudioManager._bow_friction(pico_em * 3.0) * pico_em * 3.0, pico * 0.6,
        "longe do pico a força tem que CAIR -- sem isso não existe escorregada")

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
    # Sem descontar o atraso que WG_LOSS_DELAY_COMP mede, o tom sai BAIXO -- de
    # 16 cents na nota mais grave a 31 na mais aguda. É inaudível como bug de
    # código e fatal num jogo cuja mecânica inteira é reconhecer qual nota soou.
    #
    # E o que é medido é o SOM COM O ARCO CORRENDO, não a resposta ao impulso. A
    # versão anterior media o impulso (por causa do randf do arco a ruído) e
    # passava com 0,5 cent enquanto o tom que saía pelo alto-falante passeava de
    # -6 a +17 cents entre as notas: o laço de atraso estava certo, o que não
    # tinha período estável era a excitação. Medido agora: -0,14 a +0,32 cent.
    for key in NoteMapping.NOTES:
        var freq := float(NoteMapping.NOTES[key]["freq"])
        var buf := _waveguide_ring(freq, int(AudioManager.MIX_RATE * 0.5), int(AudioManager.MIX_RATE))
        var cents := _cents_off(buf, freq, 8192, 4000)
        assert_lt(absf(cents), 1.0,
            "%s deveria soar a %.0fHz e sai %+.2f cents fora" % [key, freq, cents])

func test_waveguide_stays_well_below_the_clamp_with_the_bow_running():
    # Ressoador de Q alto excitado continuamente: a energia se acumula ao longo
    # de segundos, então o pico não aparece nas primeiras amostras. Se a saída
    # encostasse em +-1 o clampf() salvaria a asserção e esconderia a distorção,
    # como já tinha acontecido no teste do timbre aditivo -- por isso a margem
    # aqui é bem abaixo do clamp, não igual a ele.
    #
    # AS 12 NOTAS, e não uma só: desde que WG_OUTPUT_GAIN passou a ser calibrado
    # por RMS, o pico virou a restrição que limita o ganho. Pico é estatística de
    # extremo: uma nota só, medida uma vez, é um sorteio, e é exatamente assim
    # que uma margem some sem ninguém ver.
    #
    # O teto é 0,6 e não 0,9 porque a mesa de arco devolveu a folga que a
    # excitação a ruído tinha comido: o pico medido nas 12 notas é 0,417 (contra
    # 0,648 do ruído), quase o mesmo 0,402 do aditivo, e o que sobra ainda tem
    # que sobreviver ao +2,5dB do EQ do bus Strings.
    AudioManager.set_pitch_timbre(AudioManager.Timbre.WAVEGUIDE)
    var peak := 0.0
    for key in NoteMapping.NOTES:
        var freq := float(NoteMapping.NOTES[key]["freq"])
        AudioManager.play_continuous_pitch(freq)
        for i in range(int(AudioManager.MIX_RATE * 1.5)):
            peak = maxf(peak, absf(AudioManager._pitch_step(freq)))
    assert_lt(peak, 0.6, "pico do guia de onda com arco contínuo nas 12 notas: %.3f" % peak)
    assert_gt(peak, 0.02, "e não pode estar mudo -- pico medido: %.3f" % peak)

## Um trecho do timbre dado, começando com a síntese ZERADA -- que é como um
## arrasto de verdade começa (play_continuous_pitch reseta fase e corda).
func _timbre_buffer(timbre: int, freq: float, n: int) -> PackedFloat32Array:
    AudioManager.set_pitch_timbre(timbre)
    AudioManager._timbre_fade = 0.0
    AudioManager._pitch_phase = 0.0
    AudioManager._pitch_lfo_phase = 0.0
    AudioManager._reset_waveguide(freq)
    var buf := PackedFloat32Array()
    buf.resize(n)
    for i in range(n):
        buf[i] = AudioManager._pitch_step(freq)
    return buf

## RMS de uma janela do timbre dado. `skip` descarta as amostras iniciais pra
## medir um trecho mais adiante.
func _timbre_rms(timbre: int, freq: float, skip: int, n: int) -> float:
    var buf := _timbre_buffer(timbre, freq, skip + n)
    var acc := 0.0
    for i in range(skip, skip + n):
        acc += buf[i] * buf[i]
    return sqrt(acc / float(n))

## Média do RMS de uma janela sobre as 12 notas, com SEMENTE FIXA.
##
## O guia de onda não sorteia mais nada (a mesa de arco é determinística), mas o
## ADITIVO ainda soma ruído de arco por cima -- BOW_NOISE_GAIN --, então a
## semente continua valendo pro lado que ela sempre defendeu: troca "distribuição
## que eu espero" por "número que eu medi". randomize() no fim devolve o RNG
## global pros testes seguintes (é global de verdade: randf_range() do
## AudioManager bebe dele).
func _mean_rms_over_the_octave(timbre: int, skip_sec: float, win_sec: float) -> float:
    seed(20260909)
    var total := 0.0
    for key in NoteMapping.NOTES:
        total += _timbre_rms(timbre, float(NoteMapping.NOTES[key]["freq"]),
            int(AudioManager.MIX_RATE * skip_sec), int(AudioManager.MIX_RATE * win_sec))
    randomize()
    return total / float(NoteMapping.NOTES.size())

func test_the_two_timbres_come_out_at_the_same_volume_in_the_first_200ms():
    # O interruptor de timbre existe só pra comparar os dois de ouvido, e uma
    # comparação em que um lado é mais alto sai enviesada pra ele -- é o que
    # WG_OUTPUT_GAIN promete impedir. Casar os PICOS (a primeira calibração) mede
    # a grandeza errada: sonoridade segue RMS.
    #
    # A janela é curta de propósito: num arrasto curto (desliza e solta) é nos
    # primeiros 200ms que o jogador precisa reconhecer a altura. O teste de pico
    # que já existia passa com o sinal 14dB abaixo, então não pega nada disto.
    #
    # A faixa era -6 a +2dB e o teste se chamava "não afoga", porque com a
    # excitação a ruído era em -4dB que a coisa REALMENTE estava: fator de crista
    # 3,8 contra 1,8 do aditivo não deixava subir o ganho sem clipar. A mesa de
    # arco tem crista 1,80 -- a mesma do aditivo --, então agora casa: medido,
    # -0,3dB. 1,5dB é folga de 5x sobre isso e ainda reprova o defeito antigo.
    var add := _mean_rms_over_the_octave(AudioManager.Timbre.ADDITIVE, 0.0, 0.2)
    var wg := _mean_rms_over_the_octave(AudioManager.Timbre.WAVEGUIDE, 0.0, 0.2)
    var db: float = 20.0 * log(wg / add) / log(10.0)
    assert_between(db, -1.5, 1.5,
        "guia de onda %+.1fdB do aditivo nos primeiros 200ms (RMS %.4f contra %.4f)" % [db, wg, add])

func test_the_two_timbres_have_the_same_crest_factor():
    # É a crista que decide se dá pra casar o volume dos dois sem clipar, e foi
    # ela que a excitação a ruído estragava: 3,80 contra 1,80 do aditivo, ou seja
    # o guia de onda gastava o dobro de margem de pico pra entregar o mesmo RMS,
    # e sobravam 4dB de diferença de volume que nenhuma calibração fechava.
    #
    # Uma onda periódica tipo dente-de-serra -- que é o que o movimento de
    # Helmholtz produz -- tem crista perto de 1,7; uma envoltória de ruído não
    # tem crista nenhuma, tem sorteio. Este teste é o que separa "a mesa de arco
    # está funcionando" de "voltei a raspar ruído na corda".
    seed(20260909)
    var crests := {}
    for timbre in [AudioManager.Timbre.ADDITIVE, AudioManager.Timbre.WAVEGUIDE]:
        var total := 0.0
        for key in NoteMapping.NOTES:
            var freq := float(NoteMapping.NOTES[key]["freq"])
            var buf := _timbre_buffer(timbre, freq, int(AudioManager.MIX_RATE * 1.5))
            var peak := 0.0
            var acc := 0.0
            for s in buf:
                peak = maxf(peak, absf(s))
                acc += s * s
            total += peak / sqrt(acc / float(buf.size()))
        crests[timbre] = total / float(NoteMapping.NOTES.size())
    randomize()
    var add: float = crests[AudioManager.Timbre.ADDITIVE]
    var wg: float = crests[AudioManager.Timbre.WAVEGUIDE]
    assert_almost_eq(wg, add, 0.35,
        "crista do guia de onda %.2f contra %.2f do aditivo" % [wg, add])

func test_the_bowed_string_reaches_its_own_volume_inside_the_first_200ms():
    # Este é sobre a SUBIDA, não sobre o nível: num arrasto curto (desliza e
    # solta) o jogador ouve quase só os primeiros 200ms, e uma corda que ainda
    # está subindo nesse trecho entrega a nota fraca justamente na hora de
    # reconhecê-la.
    #
    # A medição é direta -- RMS dos primeiros 200ms contra o do regime -- porque
    # agora ela PODE ser: a mesa de arco não sorteia nada, então o número é
    # reprodutível. Enquanto o arco era ruído isso não dava: a razão passeava
    # tanto entre rodadas (-0,7 contra -2,2dB no MESMO build) que a asserção
    # reprovava build bom, e o teste tinha que medir o decaimento de um impulso
    # como proxy.
    #
    # O que este teste NÃO pega mais: WG_REFLECTION_GAIN. Com o arco a ruído era
    # o ganho do laço que governava a subida (0,998 punha os primeiros 200ms
    # 2,8dB abaixo); com a mesa de arco, medido, 0,98 e 0,998 dão os mesmos
    # -0,5dB -- quem manda no ataque agora é o arco, e não o quanto o laço
    # guarda. Ele continua pegando o que estraga a subida DE VERDADE: inclinação
    # ou velocidade de arco fora da faixa (uma inclinação de 8 põe a razão em
    # -6,5dB e o passeio de envoltória em 16dB).
    for key in ["C4", "E4", "B4"]:
        var freq := float(NoteMapping.NOTES[key]["freq"])
        var buf := _timbre_buffer(AudioManager.Timbre.WAVEGUIDE, freq,
            int(AudioManager.MIX_RATE * 1.5))
        var ataque := _window_rms(buf, 0.0, 0.2)
        var regime := _window_rms(buf, 0.5, 1.5)
        var db: float = 20.0 * log(ataque / regime) / log(10.0)
        assert_gt(db, -1.5,
            "%s: os primeiros 200ms saem %+.2fdB do regime -- a corda ainda está subindo" % [key, db])

## RMS de um trecho do buffer, delimitado em SEGUNDOS.
func _window_rms(buf: PackedFloat32Array, de_sec: float, ate_sec: float) -> float:
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
    # comprimento da linha de delay foi medido -- numa varredura Dó4->Si4 o pulo
    # máximo amostra-a-amostra salta de 0,154 (o mesmo tom parado) para 0,238,
    # que é o estalo. Com o slew de WG_DELAY_SLEW por amostra fica em 0,163.
    AudioManager._reset_waveguide(262.0)
    var start = AudioManager._wg_delay
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
    #
    # A referência é o pulo natural do MAIS ÍNGREME dos dois timbres, e não o do
    # aditivo como antes: o guia de onda com mesa de arco tem quina de
    # dente-de-serra e pula 0,156 por amostra sozinho, contra 0,071 do aditivo --
    # é a forma de onda dele, não um estalo. Medir a troca contra o timbre liso
    # reprovaria o guia de onda por existir.
    AudioManager.play_continuous_pitch(440.0)
    var steady_add := _max_sample_jump(2000, 440.0)
    AudioManager.set_pitch_timbre(AudioManager.Timbre.WAVEGUIDE)
    var into_waveguide := _max_sample_jump(2000, 440.0)
    for i in range(20000):
        AudioManager._pitch_step(440.0)  # deixa a corda com energia de verdade
    var steady_wg := _max_sample_jump(2000, 440.0)
    var teto: float = maxf(steady_add, steady_wg) * 1.5
    assert_lt(into_waveguide, teto,
        "entrar no guia de onda pulou %.4f, contra %.4f/%.4f dos tons estáveis" % [
            into_waveguide, steady_add, steady_wg])
    AudioManager.set_pitch_timbre(AudioManager.Timbre.ADDITIVE)
    var back_to_additive := _max_sample_jump(2000, 440.0)
    assert_lt(back_to_additive, teto,
        "voltar pro aditivo pulou %.4f, contra %.4f/%.4f dos tons estáveis" % [
            back_to_additive, steady_add, steady_wg])

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
