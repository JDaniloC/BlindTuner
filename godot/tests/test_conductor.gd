extends GutTest

const ConductorScript := preload("res://scripts/Conductor.gd")
const Preset := preload("res://scripts/SequencePreset.gd")

func _preset(notes: Array) -> Resource:
	var p = Preset.new()
	p.id = "t"
	p.start_grid = Vector2i(5, 5)
	var typed: Array[String] = []
	for n in notes:
		typed.append(n)
	p.notes = typed
	return p

func _conductor() -> Node:
	var c = ConductorScript.new()
	add_child_autofree(c)  # _ready cria o Timer; tests usam _advance() direto
	return c

func test_starts_idle():
	var c = _conductor()
	assert_eq(c.phase, c.Phase.IDLE)

func test_start_enters_preview():
	var c = _conductor()
	c.load_preset(_preset(["C4", "D4"]))
	c.start()
	assert_eq(c.phase, c.Phase.PREVIEW)

func test_preview_emits_each_note_then_enters_follow():
	var c = _conductor()
	c.load_preset(_preset(["C4", "D4"]))
	watch_signals(c)
	c.start()
	c._advance()  # preview C4 (emissão 0)
	c._advance()  # preview D4 (emissão 1)
	c._advance()  # esgota preview -> FOLLOW (emite beat 0)
	assert_signal_emit_count(c, "preview_note", 2)
	assert_signal_emitted_with_parameters(c, "preview_note", ["C4", 0], 0)
	assert_signal_emitted_with_parameters(c, "preview_note", ["D4", 1], 1)
	assert_eq(c.phase, c.Phase.FOLLOW)
	assert_signal_emitted_with_parameters(c, "beat", ["C4", 0])

func _enter_follow(c, notes: Array) -> void:
	c.load_preset(_preset(notes))
	c.start()
	for i in range(notes.size() + 1):
		c._advance()  # esgota PREVIEW e entra em FOLLOW

func test_hit_advances_index():
	var c = _conductor()
	_enter_follow(c, ["C4", "D4"])
	c.submit_note("C4")
	c._advance()  # resolve índice 0 (hit)
	assert_eq(c._index, 1)

func test_first_try_hit_counts_stat():
	var c = _conductor()
	_enter_follow(c, ["C4"])
	c.submit_note("C4")
	c._advance()
	assert_eq(c._stats.first_try_hits, 1)

func test_miss_does_not_advance_and_counts_trip():
	var c = _conductor()
	_enter_follow(c, ["C4", "D4"])
	c.submit_note("D4")  # errado
	c._advance()
	assert_eq(c._index, 0)
	assert_eq(c._stats.total_trips, 1)

func test_miss_then_hit_does_not_count_first_try():
	var c = _conductor()
	_enter_follow(c, ["C4"])
	c.submit_note("D4")  # erro
	c._advance()
	c.submit_note("C4")  # acerto na 2ª
	c._advance()
	assert_eq(c._stats.first_try_hits, 0)
	assert_eq(c._stats.total_trips, 1)

func test_no_input_is_a_miss():
	var c = _conductor()
	_enter_follow(c, ["C4"])
	c._advance()  # sem submit
	assert_eq(c._index, 0)
	assert_eq(c._stats.total_trips, 1)

func test_completion_emits_sequence_complete_and_done():
	var c = _conductor()
	_enter_follow(c, ["C4", "D4"])
	watch_signals(c)
	c.submit_note("C4")
	c._advance()
	c.submit_note("D4")
	c._advance()
	assert_eq(c.phase, c.Phase.DONE)
	assert_signal_emitted(c, "sequence_complete")
	assert_eq(c._stats.first_try_hits, 2)

func test_submit_ignored_outside_follow():
	var c = _conductor()
	c.load_preset(_preset(["C4"]))
	c.start()  # PREVIEW
	c.submit_note("C4")
	assert_eq(c._input_buffer, "")

func test_beat_re_emitted_same_index_on_miss():
	var c = _conductor()
	_enter_follow(c, ["C4"])
	watch_signals(c)
	c._advance()  # miss no índice 0
	assert_signal_emitted_with_parameters(c, "beat", ["C4", 0])
	assert_eq(c._index, 0)

func test_empty_preset_completes_immediately():
	var c = _conductor()
	c.load_preset(_preset([]))
	watch_signals(c)
	c.start()       # PREVIEW
	c._advance()    # preview vazio -> _begin_follow -> vazio -> _finish -> DONE
	assert_eq(c.phase, c.Phase.DONE)
	assert_signal_emitted(c, "sequence_complete")

func test_load_preset_midflight_resets():
	var c = _conductor()
	_enter_follow(c, ["C4", "D4"])
	c.submit_note("C4")
	c._advance()      # _index vira 1
	c.load_preset(_preset(["F4"]))
	assert_eq(c.phase, c.Phase.IDLE)
	assert_eq(c._index, 0)
	assert_eq(c._stats.total_trips, 0)
