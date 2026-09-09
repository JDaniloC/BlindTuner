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

func after_each():
    # _stop_current() para tanto o player discreto (play_note) quanto o
    # contínuo (play_continuous_pitch) -- stop_continuous_pitch() sozinho
    # deixava um player discreto órfão de testes anteriores (ex: play_note()),
    # causando "ObjectDB leaked at exit" ao rodar este arquivo isolado.
    AudioManager._stop_current()

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

func test_the_continuous_tone_samples_before_it_advances_the_phase():
    # A amostra tem que ser a da fase de AGORA, e o avanço vir depois: invertida
    # a ordem, o tom sai adiantado de uma amostra e -- o que importa de verdade --
    # a primeira amostra de todo arrasto deixa de ser a da fase zerada por
    # play_continuous_pitch, que é o que garante que o arrasto comece do mesmo
    # ponto do ciclo em vez de um degrau.
    AudioManager._pitch_phase = 0.11
    AudioManager._pitch_lfo_phase = 0.0
    var got = AudioManager._pitch_step(440.0)
    # _pitch_step atualiza o ruído de arco ANTES de amostrar, então o valor que
    # ficou em _noise_lp é exatamente o que entrou nesta amostra.
    var expected = AudioManager._continuous_pitch_sample(0.11, 0.0, AudioManager._noise_lp)
    assert_almost_eq(got, expected, 1e-6,
        "a amostra do tom contínuo é _continuous_pitch_sample na fase anterior ao avanço")
    assert_almost_eq(AudioManager._pitch_phase, 0.11 + 440.0 / AudioManager.MIX_RATE, 1e-6,
        "e a fase tem que ter avançado uma amostra da frequência pedida")

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

# --- Envoltória dos sons discretos ----------------------------------------------

## Degrau máximo tolerado entre duas amostras vizinhas da envoltória. O maior
## degrau LEGÍTIMO é a rampa de ataque -- 1/ataque por amostra --, e o ataque mais
## curto dos três sons é o dos SFX de 0,2s: 191 amostras depois da compressão.
## Medido: 0,00227 na nota de 0,6s, 0,00524 nos SFX de 0,2s e 0,00525 lendo o PCM
## da colisão (o meio LSB do arredondamento pra 16 bits). O teto é ~4x o pior
## deles -- folga pra quem mexer nos tempos da envoltória -- e reprova por 15x o
## degrau de 0,3005 (12dB numa amostra) que o sustain negativo produzia.
const MAX_ENVELOPE_STEP := 0.02

## O PCM que _make_stream escreve quando a envoltória vale 1: a onda vai a +-1 e o
## laço multiplica por 0,5 antes de escalar pra 16 bits. Dividir por ele devolve a
## envoltória, em unidades comparáveis a MAX_ENVELOPE_STEP.
const PCM_AT_FULL_ENVELOPE := 0.5 * 32767.0

## Os três sons discretos que o jogo toca, com a duração de cada um. É a lista
## inteira: só play_note, play_collision_sfx e play_note_miss_sfx chamam
## _play_synth.
func _sons_do_jogo() -> Array:
    return [
        ["nota", AudioManager.NOTE_DURATION_SEC],
        ["colisão com parede", AudioManager.COLLISION_DURATION_SEC],
        ["erro de nota", AudioManager.NOTE_MISS_DURATION_SEC],
    ]

## Maior degrau entre amostras vizinhas de `valores`, ancorado em SILÊNCIO nas
## duas pontas: antes da primeira amostra e depois da última o alto-falante está
## parado em zero, então esses dois também são degraus de verdade -- e é no do fim
## que aparece a correção "óbvia" de cortar o release em vez de comprimir a
## envoltória (o som terminaria em 0,3929 e o corte seco viraria o mesmo click, só
## que no fim). Devolve [pior degrau, índice, maior valor].
##
## Float64 e não Float32 de propósito: um degrau medido aqui é a diferença de dois
## números quase iguais, e é justamente aí que os 1e-5 do float32 aparecem.
func _pior_degrau(valores: PackedFloat64Array) -> Array:
    var pior := 0.0
    var pior_idx := 0
    var pico := 0.0
    var anterior := 0.0
    for idx in range(valores.size() + 1):
        var atual: float = 0.0 if idx == valores.size() else valores[idx]
        var degrau: float = absf(atual - anterior)
        if degrau > pior:
            pior = degrau
            pior_idx = idx
        pico = maxf(pico, atual)
        anterior = atual
    return [pior, pior_idx, pico]

func test_the_envelope_has_no_step_between_neighbouring_samples():
    # O click do SFX de erro e do de colisão era ISTO: com 0,2s de duração o
    # sustain saía -11466 amostras, o release começava já em t=0,867 da própria
    # curva, e a envoltória caía de 0,4001 (amostra 7055) pra 0,0995 (7056) --
    # 12dB num passo, no feedback de erro de que o público-alvo depende.
    #
    # O teste que existia antes (fades_near_silence_by_last_sample) olhava só a
    # ÚLTIMA amostra e passou por cima do degrau; este varre o buffer inteiro, nas
    # três durações que o jogo realmente toca.
    for som in _sons_do_jogo():
        var nome: String = som[0]
        var seg := AudioManager._envelope_segments(som[1])
        var total: int = seg[0] + seg[1] + seg[2] + seg[3]
        var env := PackedFloat64Array()
        env.resize(total)
        for idx in range(total):
            env[idx] = AudioManager._envelope_at(idx, seg[0], seg[1], seg[2], seg[3])
        var medido := _pior_degrau(env)
        assert_lt(medido[0], MAX_ENVELOPE_STEP,
            "%s (%s s, %d amostras): degrau de %.4f na amostra %d" % [
                nome, som[1], total, medido[0], medido[1]])
        assert_almost_eq(float(medido[2]), 1.0, 0.01,
            "%s: pré-condição -- a envoltória chega a 1 no fim do ataque. Sem isso os degraus seriam pequenos por o som estar baixo, não por ser contínuo" % nome)

func test_the_envelope_never_asks_for_a_negative_sustain():
    # A causa, e não o sintoma. Com os quatro trechos em tamanho fixo, uma duração
    # menor que ataque+decay+release (0,46s -- e dois dos três sons duram 0,2s)
    # deixava o sustain negativo; sustain negativo não encurta a envoltória, ele
    # ADIANTA o release. Em _envelope_at o ramo do sustain nunca fica verdadeiro
    # e o release entra pelo meio da curva.
    for som in _sons_do_jogo():
        var nome: String = som[0]
        var seg := AudioManager._envelope_segments(som[1])
        assert_gte(seg[2], 0, "%s: sustain de %d amostras" % [nome, seg[2]])
        for i in [0, 1, 3]:
            assert_gt(seg[i], 0,
                "%s: o trecho %d tem %d amostras, e _envelope_at divide por ele" % [nome, i, seg[i]])
        assert_eq(seg[0] + seg[1] + seg[2] + seg[3], int(AudioManager.MIX_RATE * som[1]),
            "%s: os quatro trechos têm que somar o buffer inteiro -- sobrando release fora dele, o som é cortado antes de esmaecer" % nome)

func test_the_collision_sfx_the_player_hears_has_no_step_in_it():
    # A onda da colisão é QUADRADA: |amostra| é exatamente 1 em todo ponto, então
    # o módulo do PCM que _make_stream escreve É a envoltória. Isso deixa medir o
    # caminho de produção INTEIRO -- _envelope_segments, _envelope_at e o laço que
    # escreve os bytes -- em vez de só a conta da envoltória isolada, que é onde
    # os dois testes acima param.
    var stream: AudioStreamWAV = AudioManager._make_stream(
        AudioManager.COLLISION_FREQ, true, AudioManager.COLLISION_DURATION_SEC)
    var total: int = stream.data.size() / 2
    assert_eq(total, int(AudioManager.MIX_RATE * AudioManager.COLLISION_DURATION_SEC),
        "o SFX tem que continuar durando o que a constante diz: esticar o buffer até caber ataque+decay+release trocaria o click por uma colisão de 0,46s")
    var env := PackedFloat64Array()
    env.resize(total)
    for idx in range(total):
        env[idx] = absf(float(stream.data.decode_s16(idx * 2))) / PCM_AT_FULL_ENVELOPE
    var medido := _pior_degrau(env)
    assert_lt(medido[0], MAX_ENVELOPE_STEP,
        "PCM da colisão: degrau de %.4f na amostra %d de %d" % [medido[0], medido[1], total])
    assert_almost_eq(float(medido[2]), 1.0, 0.01,
        "pré-condição: o PCM chega ao pico da envoltória (senão os degraus seriam pequenos por o som estar baixo)")
