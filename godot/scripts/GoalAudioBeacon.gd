extends Node2D
class_name GoalAudioBeacon
## Farol sonoro espacial 2D do objetivo da fase.
## Emite pulsos sonoros posicionados no goal_grid e renderiza um halo luminoso 2D
## isométrico com anéis harmônicos e partículas 2D em cada pulso,
## permitindo ao jogador orientar-se auditiva e visualmente.

signal pulsed

@export var beacon_type: String = "radio"
@export var pulse_interval: float = 2.5
@export var is_active: bool = true
@export var max_distance: float = 800.0
@export var attenuation: float = 1.6
@export var visual_enabled: bool = true

var _player: AudioStreamPlayer2D
var _timer: Timer
var _base_volume_db: float = 0.0
var _time: float = 0.0
var _pulse_waves: Array[Dictionary] = []
var _motes: Array[Dictionary] = []

func _ready() -> void:
	_setup_nodes()
	if is_active:
		start()

func _setup_nodes() -> void:
	if _player == null:
		_player = AudioStreamPlayer2D.new()
		_player.bus = AudioManager.BEACON_BUS_NAME
		_player.max_distance = max_distance
		_player.attenuation = attenuation
		_player.panning_strength = 1.0
		add_child(_player)

	if _timer == null:
		_timer = Timer.new()
		_timer.wait_time = pulse_interval
		_timer.one_shot = false
		_timer.timeout.connect(pulse_now)
		add_child(_timer)

## Configura o tipo de som e o intervalo de pulso do farol.
func setup(sound_type: String, interval: float = 2.5) -> void:
	beacon_type = sound_type
	pulse_interval = interval
	if _timer != null:
		_timer.wait_time = pulse_interval
	if _player != null:
		_player.stream = AudioManager.get_beacon_stream(beacon_type)
	queue_redraw()

## Inicia a emissão periódica de pulsos sonoros.
func start() -> void:
	is_active = true
	_setup_nodes()
	_player.stream = AudioManager.get_beacon_stream(beacon_type)
	if _timer.is_stopped():
		_timer.start()
	# Dispara o primeiro pulso imediatamente para orientar o jogador desde o início
	pulse_now()

## Interrompe a emissão do farol sonoro.
func stop() -> void:
	is_active = false
	if _timer != null:
		_timer.stop()
	if _player != null and _player.playing:
		_player.stop()
	queue_redraw()

## Dispara um pulso sonoro imediatamente.
func pulse_now() -> void:
	if not is_active or _player == null:
		return
	if _player.stream == null:
		_player.stream = AudioManager.get_beacon_stream(beacon_type)
	_player.play()
	_spawn_visual_pulse()
	pulsed.emit()

## Aplica atenuação suave (ducking) quando notas didáticas ou falas estão tocando.
func set_ducking(ducked: bool) -> void:
	if _player == null:
		return
	_player.volume_db = _base_volume_db - 10.0 if ducked else _base_volume_db

func set_visual_enabled(enabled: bool) -> void:
	visual_enabled = enabled
	queue_redraw()

func _beacon_palette() -> Color:
	match beacon_type:
		"drip", "fountain_birds", "ocean_waves", "watering_can":
			return Color(0.45, 0.88, 1.0)
		"window_wind", "wind_chimes", "church_bell":
			return Color(0.98, 0.92, 0.68)
		"cat_bell", "tea_cup", "keys_jingle", "shop_bell":
			return Color(1.0, 0.84, 0.42)
		_:
			return Color(1.0, 0.78, 0.36)

func _spawn_visual_pulse() -> void:
	_pulse_waves.append({ "age": 0.0, "duration": 1.35 })
	for i in range(3):
		var angle := (float(i) - 1.0) * 0.65 + sin(_time * 3.1 + float(i)) * 0.2
		_motes.append({
			"pos": Vector2(sin(angle) * 10.0, -6.0 - float(i) * 3.0),
			"vel": Vector2(sin(angle) * 6.0, -22.0 - float(i) * 4.0),
			"age": 0.0,
			"duration": 1.1 + float(i) * 0.15,
			"size": 3.0 if i == 1 else 2.0,
		})
	queue_redraw()

func _process(delta: float) -> void:
	if not is_active and _pulse_waves.is_empty() and _motes.is_empty():
		return
	_time += delta
	for i in range(_pulse_waves.size() - 1, -1, -1):
		_pulse_waves[i]["age"] = float(_pulse_waves[i]["age"]) + delta
		if float(_pulse_waves[i]["age"]) >= float(_pulse_waves[i]["duration"]):
			_pulse_waves.remove_at(i)
	for i in range(_motes.size() - 1, -1, -1):
		var m: Dictionary = _motes[i]
		m["age"] = float(m["age"]) + delta
		m["pos"] = (m["pos"] as Vector2) + (m["vel"] as Vector2) * delta
		if float(m["age"]) >= float(m["duration"]):
			_motes.remove_at(i)
	if visual_enabled:
		queue_redraw()

func _draw() -> void:
	if not visual_enabled or not is_active:
		return
	var base_col := _beacon_palette()
	var breath := 0.5 + 0.5 * sin(_time * 2.6)

	# 1. Halo luminoso 2D concêntrico no piso isométrico (proporção 2:1)
	var glow_layers := 3
	for layer_idx in range(glow_layers):
		var ratio := float(glow_layers - layer_idx) / float(glow_layers)
		var rx := (22.0 + 6.0 * breath) * ratio
		var ry := rx * 0.5
		var alpha := (0.10 + 0.06 * breath) * (1.1 - ratio * 0.5)
		_draw_iso_ellipse_filled(Vector2.ZERO, rx, ry, Color(base_col.r, base_col.g, base_col.b, alpha))

	# 2. Anéis harmônicos 2D em expansão a cada pulso do farol
	for w in _pulse_waves:
		var t := clampf(float(w["age"]) / float(w["duration"]), 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - t, 2.2)
		var rx := lerpf(10.0, 54.0, eased)
		var ry := rx * 0.5
		var a := (1.0 - t) * 0.72
		_draw_iso_ellipse_Fast(Vector2.ZERO, rx, ry, Color(base_col.r, base_col.g, base_col.b, a), 2.0)
		if t < 0.75:
			var rx_inner := lerpf(6.0, 36.0, eased)
			_draw_iso_ellipse_Fast(Vector2.ZERO, rx_inner, rx_inner * 0.5, Color(1.0, 0.97, 0.88, a * 0.55), 1.2)

	# 3. Pequenos losangos luminosos 2D (partículas acústicas) subindo do farol
	for m in _motes:
		var t := clampf(float(m["age"]) / float(m["duration"]), 0.0, 1.0)
		var a := sin(t * PI) * 0.85
		var p: Vector2 = m["pos"]
		var s: float = float(m["size"])
		var pts := PackedVector2Array([
			p + Vector2(0, -s),
			p + Vector2(s, 0),
			p + Vector2(0, s),
			p + Vector2(-s, 0),
		])
		draw_colored_polygon(pts, Color(1.0, 0.96, 0.84, a))

func _draw_iso_ellipse_filled(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var a := float(i) * TAU / float(steps)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)

func _draw_iso_ellipse_Fast(center: Vector2, rx: float, ry: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var steps := 28
	for i in range(steps + 1):
		var a := float(i) * TAU / float(steps)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, width, true)
