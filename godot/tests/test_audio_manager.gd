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
    for i in range(50):
        var phase = i / 50.0
        var lfo = fmod(i * 0.13, 1.0)
        var v = AudioManager._continuous_pitch_sample(phase, lfo, 1.0)  # noise_lp no pior caso
        assert_true(absf(v) <= 1.0, "amostra do tom contínuo não deve estourar +-1 mesmo no pior caso de ruído")

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
