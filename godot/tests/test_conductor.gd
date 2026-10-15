extends GutTest

const ConductorScript := preload("res://scripts/Conductor.gd")
const Preset := preload("res://scripts/SequencePreset.gd")

func _preset(notes: Array) -> Resource:
	var p = Preset.new()
	p.id = "t"
	p.map_id = "quarto"
	var typed: Array[String] = []
	for n in notes:
		typed.append(n)
	p.notes = typed
	return p

func _conductor() -> Node:
	var c = ConductorScript.new()
	add_child_autofree(c)  # _ready cria o Timer; testes chamam _advance()/submit_note direto
	return c

# Entra em CALL: esgota PREVIEW (N emissões) + 1 advance que transiciona.
func _enter_call(c, notes: Array[String]) -> void:
	c.load_preset(_preset(notes))
	c.start()
	for i in range(notes.size() + 1):
		c._advance()

func test_starts_idle():
	var c = _conductor()
	assert_eq(c.phase, c.Phase.IDLE)

func test_start_enters_preview():
	var c = _conductor()
	c.load_preset(_preset(["C4", "D4"]))
	c.start()
	assert_eq(c.phase, c.Phase.PREVIEW)

func test_preview_emits_each_note_then_enters_call():
	var c = _conductor()
	c.load_preset(_preset(["C4", "D4"]))
	watch_signals(c)
	c.start()
	c._advance()  # preview C4 (emissão 0)
	c._advance()  # preview D4 (emissão 1)
	c._advance()  # esgota preview -> CALL (emite call_cue 0)
	assert_signal_emit_count(c, "preview_note", 2)
	assert_signal_emitted_with_parameters(c, "preview_note", ["C4", 0], 0)
	assert_signal_emitted_with_parameters(c, "preview_note", ["D4", 1], 1)
	assert_eq(c.phase, c.Phase.CALL)
	assert_signal_emitted_with_parameters(c, "call_cue", ["C4", 0])

func test_submit_ignored_outside_call():
	var c = _conductor()
	c.load_preset(_preset(["C4"]))
	c.start()  # PREVIEW
	c.submit_note("C4")
	assert_eq(c._index, 0)
	assert_eq(c.phase, c.Phase.PREVIEW)

func test_call_does_not_auto_advance_on_tick():
	# Regressão: CALL não é pautado por tick (bug do range(6) da Sub-spec A não pode voltar).
	var c = _conductor()
	_enter_call(c, ["C4", "D4"])
	c._advance()  # tick durante CALL = no-op
	c._advance()
	assert_eq(c._index, 0)
	assert_eq(c._stats.total_trips, 0)
	assert_eq(c.phase, c.Phase.CALL)

func test_hit_advances_index_immediately():
	var c = _conductor()
	_enter_call(c, ["C4", "D4"])
	c.submit_note("C4")  # resolve na hora, sem _advance
	assert_eq(c._index, 1)

func test_first_try_hit_counts_stat():
	var c = _conductor()
	_enter_call(c, ["C4"])
	c.submit_note("C4")
	assert_eq(c._stats.first_try_hits, 1)

func test_miss_does_not_advance_and_counts_trip():
	var c = _conductor()
	_enter_call(c, ["C4", "D4"])
	c.submit_note("D4")  # errado (alvo C4)
	assert_eq(c._index, 0)
	assert_eq(c._stats.total_trips, 1)

func test_miss_then_hit_does_not_count_first_try():
	var c = _conductor()
	_enter_call(c, ["C4"])
	c.submit_note("D4")  # erro
	c.submit_note("C4")  # acerto na 2ª
	assert_eq(c._stats.first_try_hits, 0)
	assert_eq(c._stats.total_trips, 1)

func test_call_cue_re_emitted_same_index_on_miss():
	var c = _conductor()
	c.load_preset(_preset(["C4"]))
	c.start()
	watch_signals(c)
	c._advance()  # preview C4
	c._advance()  # -> CALL, call_cue idx0 (emissão 0)
	c.submit_note("D4")  # erro -> note_resolved(false), agenda call_cue idx0 de novo
	# call_cue após submit_note é agendado (CUE_GAP_AFTER_USER_SEC); aguarda o timer
	await get_tree().create_timer(c.CUE_GAP_AFTER_USER_SEC + 0.05).timeout
	assert_signal_emit_count(c, "call_cue", 2)
	assert_signal_emitted_with_parameters(c, "call_cue", ["C4", 0], 1)
	assert_signal_emitted_with_parameters(c, "note_resolved", [false, 0])
	assert_eq(c._index, 0)

func test_replay_current_cue_does_not_penalize_player():
	var c = _conductor()
	_enter_call(c, ["C4"])
	watch_signals(c)
	c.replay_current_cue()
	assert_signal_emitted_with_parameters(c, "call_cue", ["C4", 0])
	assert_eq(c._stats.total_trips, 0, "replay_current_cue não deve incrementar tropeços")
	assert_false(c._attempted_current, "replay_current_cue não deve marcar erro de tentativa")
	# Se acertar em seguida, ainda ganha first_try_hits!
	c.submit_note("C4")
	assert_eq(c._stats.first_try_hits, 1, "acerto após replay_current_cue continua sendo de 1ª tentativa")

func test_completion_enters_replay():
	var c = _conductor()
	_enter_call(c, ["C4", "D4"])
	c.submit_note("C4")
	c.submit_note("D4")  # última -> REPLAY
	assert_eq(c.phase, c.Phase.REPLAY)

func test_replay_emits_each_note_then_done():
	var c = _conductor()
	_enter_call(c, ["C4", "D4"])
	watch_signals(c)
	c.submit_note("C4")
	c.submit_note("D4")  # -> REPLAY
	c._advance()  # replay C4 (emissão 0)
	c._advance()  # replay D4 (emissão 1)
	c._advance()  # esgota replay -> DONE
	assert_signal_emit_count(c, "replay_note", 2)
	assert_signal_emitted_with_parameters(c, "replay_note", ["C4", 0], 0)
	assert_signal_emitted_with_parameters(c, "replay_note", ["D4", 1], 1)
	assert_eq(c.phase, c.Phase.DONE)
	assert_signal_emitted(c, "sequence_complete")
	assert_eq(c._stats.first_try_hits, 2)
	assert_true(c._stats.elapsed_sec >= 0.0)  # mede só o CALL; >=0 é o invariante testável

func test_empty_preset_completes_immediately():
	var c = _conductor()
	c.load_preset(_preset([]))
	watch_signals(c)
	c.start()  # vazio -> DONE direto
	assert_eq(c.phase, c.Phase.DONE)
	assert_signal_emitted(c, "sequence_complete")

func test_load_preset_midflight_resets():
	var c = _conductor()
	_enter_call(c, ["C4", "D4"])
	c.submit_note("C4")  # _index vira 1
	c.load_preset(_preset(["F4"]))
	assert_eq(c.phase, c.Phase.IDLE)
	assert_eq(c._index, 0)
	assert_eq(c._stats.total_trips, 0)

func test_restart_mid_game_resets():
	var c = _conductor()
	_enter_call(c, ["C4", "D4"])
	c.start()
	assert_eq(c.phase, c.Phase.PREVIEW)
	assert_eq(c._index, 0)

func test_submit_note_schedules_next_cue_with_delay():
	# Garante que call_cue para a 2ª nota NÃO é emitido sincronicamente após o acerto.
	var c = _conductor()
	_enter_call(c, ["C4", "D4"])
	watch_signals(c)
	# Emissão 0 já foi em _begin_call (antes do watch); zera o contador que importa.
	c.submit_note("C4")  # acerto na 1ª nota
	# call_cue para D4 (idx 1) ainda não deve ter disparado
	assert_signal_emit_count(c, "call_cue", 0)
	# Aguarda o timer disparar
	await get_tree().create_timer(c.CUE_GAP_AFTER_USER_SEC + 0.05).timeout
	assert_signal_emit_count(c, "call_cue", 1)
	assert_signal_emitted_with_parameters(c, "call_cue", ["D4", 1])

func test_pending_cue_cancelled_by_new_submit():
	# Garante que uma segunda submit_note cancela o cue agendado pelo primeiro acerto.
	var c = _conductor()
	_enter_call(c, ["C4", "D4", "F4"])
	# Acerta C4 (schedula cue para D4 idx1)
	c.submit_note("C4")
	# Antes do timer: erra D4 (deve cancelar o cue de D4 e agendar novo para D4)
	c.submit_note("F4")  # errado — alvo ainda é D4
	watch_signals(c)
	# Aguarda ambos os possíveis timers
	await get_tree().create_timer(c.CUE_GAP_AFTER_USER_SEC + 0.05).timeout
	# Apenas UM call_cue deve ter disparado (o do segundo submit, não o do primeiro)
	assert_signal_emit_count(c, "call_cue", 1)
	assert_signal_emitted_with_parameters(c, "call_cue", ["D4", 1])
