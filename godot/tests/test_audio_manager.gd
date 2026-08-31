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

func test_play_continuous_pitch_is_stub():
    # API existe para uso futuro (modo cello). MVP: retornar null é OK.
    var result = AudioManager.play_continuous_pitch(440.0)
    assert_null(result)
