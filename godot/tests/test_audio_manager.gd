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
