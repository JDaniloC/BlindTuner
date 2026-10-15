extends Node
## Autoload: Sistema de retorno auditivo e acessibilidade não-visual (earcons + TTS).
## Opera em um bus de áudio isolado ("UI"), garantindo que anúncios e cliques de navegação
## nunca interrompam nem sejam interrompidos pelo AudioManager (notas de gameplay, beacon).

const UI_BUS_NAME := "UI"
const MIX_RATE := 44100.0

var tts_enabled := false
var _voice := ""
var _ui_player: AudioStreamPlayer
var _earcon_cache: Dictionary = {}
var _last_announced_text := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_ui_bus()
	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = UI_BUS_NAME
	add_child(_ui_player)
	_init_tts()
	tts_enabled = SaveManager.get_preference("talkback_enabled", false)

func set_tts_enabled(enabled: bool) -> void:
	tts_enabled = enabled
	SaveManager.set_preference("talkback_enabled", enabled)
	if not enabled:
		stop_speech()
	else:
		speak("Voz do narrador ativada.")

func is_tts_enabled() -> bool:
	return tts_enabled

func _ensure_ui_bus() -> void:
	if AudioServer.get_bus_index(UI_BUS_NAME) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, UI_BUS_NAME)
	AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, 0.0)

func _init_tts() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var pt_voices := DisplayServer.tts_get_voices_for_language("pt")
	if not pt_voices.is_empty():
		_voice = pt_voices[0]
	else:
		var all_voices := DisplayServer.tts_get_voices()
		if not all_voices.is_empty():
			var first = all_voices[0]
			if first is Dictionary and first.has("id"):
				_voice = str(first["id"])
			elif first is String:
				_voice = str(first)

## Toca earcon e fala o texto acessível.
func announce(earcon: String, text: String, interrupt: bool = true) -> void:
	if not earcon.is_empty():
		play_earcon(earcon)
	if not text.is_empty():
		speak(text, interrupt)

## Toca um dos earcons sintéticos cacheados.
func play_earcon(earcon_type: String) -> void:
	var stream: AudioStreamWAV = _get_or_create_earcon(earcon_type)
	if stream != null and _ui_player != null:
		_ui_player.stream = stream
		_ui_player.play()

## Envia fala para o subsistema de TTS do sistema.
func speak(text: String, interrupt: bool = true) -> void:
	_last_announced_text = text
	if not tts_enabled or _voice.is_empty():
		return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	if interrupt:
		DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, _voice, 85, 1.0, 1.0, 0, interrupt)

func stop_speech() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()

func _get_or_create_earcon(type: String) -> AudioStreamWAV:
	if _earcon_cache.has(type):
		return _earcon_cache[type]
	
	var stream: AudioStreamWAV = null
	match type:
		"focus":
			stream = _gen_tick(750.0, 0.025, 60.0)
		"boundary":
			stream = _gen_thump(130.0, 0.05, 35.0)
		"locked":
			stream = _gen_tick(320.0, 0.035, 45.0)
		"confirm":
			stream = _gen_sweep(440.0, 880.0, 0.06)
		"cancel":
			stream = _gen_sweep(650.0, 300.0, 0.06)
		"toggle_on":
			stream = _gen_double_click(550.0, 900.0, 0.05)
		"toggle_off":
			stream = _gen_double_click(800.0, 480.0, 0.05)
		"pause":
			stream = _gen_sweep(520.0, 180.0, 0.12)
		"countdown_tick":
			stream = _gen_tick(880.0, 0.03, 50.0)
		"countdown_go":
			stream = _gen_sweep(520.0, 1040.0, 0.1)
		"error":
			stream = _gen_double_click(220.0, 180.0, 0.08)
		_:
			stream = _gen_tick(750.0, 0.025, 60.0)
	
	_earcon_cache[type] = stream
	return stream

func _create_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var total := samples.size()
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	for i in range(total):
		var pcm: int = clampi(int(clampf(samples[i], -1.0, 1.0) * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, pcm)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(MIX_RATE)
	stream.stereo = false
	stream.data = bytes
	return stream

func _gen_tick(freq: float, duration: float, decay_rate: float) -> AudioStreamWAV:
	var total := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var phase := 0.0
	var inc := freq / MIX_RATE
	for i in range(total):
		var t := float(i) / MIX_RATE
		var env := exp(-t * decay_rate)
		var noise := randf_range(-0.15, 0.15)
		samples[i] = (sin(phase * TAU) * 0.7 + noise) * env * 0.5
		phase = fposmod(phase + inc, 1.0)
	return _create_wav(samples)

func _gen_thump(freq: float, duration: float, decay_rate: float) -> AudioStreamWAV:
	var total := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var phase := 0.0
	var inc := freq / MIX_RATE
	for i in range(total):
		var t := float(i) / MIX_RATE
		var env := exp(-t * decay_rate)
		samples[i] = sin(phase * TAU) * env * 0.6
		phase = fposmod(phase + inc, 1.0)
	return _create_wav(samples)

func _gen_sweep(start_f: float, end_f: float, duration: float) -> AudioStreamWAV:
	var total := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var phase := 0.0
	for i in range(total):
		var progress := float(i) / float(total)
		var cur_freq := lerpf(start_f, end_f, progress)
		var t := float(i) / MIX_RATE
		var env := sin(progress * PI)
		samples[i] = sin(phase * TAU) * env * 0.45
		phase = fposmod(phase + cur_freq / MIX_RATE, 1.0)
	return _create_wav(samples)

func _gen_double_click(f1: float, f2: float, duration: float) -> AudioStreamWAV:
	var total := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var split := int(total * 0.45)
	var phase := 0.0
	for i in range(total):
		var t := float(i) / MIX_RATE
		var is_first := i < split
		var freq := f1 if is_first else f2
		var env := exp(-(float(i if is_first else (i - split)) / MIX_RATE) * 70.0)
		samples[i] = sin(phase * TAU) * env * 0.45
		phase = fposmod(phase + freq / MIX_RATE, 1.0)
	return _create_wav(samples)
