extends GutTest

const GoalAudioBeaconScript := preload("res://scripts/GoalAudioBeacon.gd")
const GOAL_AUDIO_BEACON_SCENE := preload("res://scenes/GoalAudioBeacon.tscn")

var _beacon = null

func before_each():
	_beacon = GOAL_AUDIO_BEACON_SCENE.instantiate()
	add_child_autofree(_beacon)

func after_each():
	if _beacon != null and is_instance_valid(_beacon):
		_beacon.stop()

func test_beacon_instantiates_nodes():
	assert_not_null(_beacon)
	assert_not_null(_beacon._player, "Player de áudio deve existir")
	assert_not_null(_beacon._timer, "Timer de pulso deve existir")
	assert_eq(_beacon._player.bus, "Beacon", "O bus configurado deve ser Beacon")

func test_audio_manager_generates_all_four_beacon_streams():
	for btype in ["radio", "music_box", "drip", "clock"]:
		var stream = AudioManager.get_beacon_stream(btype)
		assert_not_null(stream, "Stream para %s não pode ser nulo" % btype)
		assert_true(stream is AudioStreamWAV, "Stream para %s deve ser AudioStreamWAV" % btype)
		assert_eq(stream.mix_rate, 44100, "Taxa de amostragem deve ser 44100")
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "Formato deve ser 16 bits")
		assert_gt(stream.data.size(), 0, "Dados de áudio não podem ser vazios")

func test_setup_configures_beacon_type_and_interval():
	_beacon.setup("music_box", 3.0)
	assert_eq(_beacon.beacon_type, "music_box")
	assert_eq(_beacon.pulse_interval, 3.0)
	assert_eq(_beacon._timer.wait_time, 3.0)

func test_start_and_stop():
	_beacon.setup("drip", 2.0)
	_beacon.start()
	assert_true(_beacon.is_active)
	assert_false(_beacon._timer.is_stopped())

	_beacon.stop()
	assert_false(_beacon.is_active)
	assert_true(_beacon._timer.is_stopped())

func test_pulse_now_emits_pulsed_signal():
	watch_signals(_beacon)
	_beacon.setup("clock", 2.0)
	_beacon.pulse_now()
	assert_signal_emitted(_beacon, "pulsed")

func test_ducking_attenuates_volume():
	_beacon.setup("radio", 2.0)
	var initial_vol = _beacon._player.volume_db
	_beacon.set_ducking(true)
	assert_lt(_beacon._player.volume_db, initial_vol, "Volume deve ser menor com ducking ativado")
	_beacon.set_ducking(false)
	assert_eq(_beacon._player.volume_db, initial_vol, "Volume deve ser restaurado sem ducking")

func test_pulse_spawns_2d_harmonic_waves_and_motes():
	_beacon.setup("music_box", 2.5)
	_beacon.pulse_now()
	assert_gt(_beacon._pulse_waves.size(), 0, "Pulso deve gerar anéis harmônicos 2D")
	assert_gt(_beacon._motes.size(), 0, "Pulso deve gerar partículas acústicas 2D")

