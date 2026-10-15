extends Node2D
class_name GoalAudioBeacon
## Farol sonoro espacial 2D do objetivo da fase.
## Emite pulsos sonoros posicionados no goal_grid,
## permitindo ao jogador orientar-se auditivamente via panning estéreo e atenuação por distância.

signal pulsed

@export var beacon_type: String = "radio"
@export var pulse_interval: float = 2.5
@export var is_active: bool = true
@export var max_distance: float = 800.0
@export var attenuation: float = 1.6

var _player: AudioStreamPlayer2D
var _timer: Timer
var _base_volume_db: float = 0.0

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

## Dispara um pulso sonoro imediatamente.
func pulse_now() -> void:
	if not is_active or _player == null:
		return
	if _player.stream == null:
		_player.stream = AudioManager.get_beacon_stream(beacon_type)
	_player.play()
	pulsed.emit()

## Aplica atenuação suave (ducking) quando notas didáticas ou falas estão tocando.
func set_ducking(ducked: bool) -> void:
	if _player == null:
		return
	_player.volume_db = _base_volume_db - 10.0 if ducked else _base_volume_db
