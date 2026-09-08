extends Control
## Modo de input "Scroll de Afinação": desliza um controle vertical cobrindo a
## faixa de frequência das 12 notas, ouvindo o pitch mudar ao vivo; ao soltar,
## resolve pra nota mais próxima do valor largado.

signal note_triggered(note_key: String)

var _slider: VSlider

func _ready() -> void:
	_slider = VSlider.new()
	_slider.custom_minimum_size = Vector2(48, 300)
	_slider.min_value = _lowest_frequency()
	_slider.max_value = _highest_frequency()
	_slider.step = 1.0
	_slider.value = _slider.min_value
	_slider.value_changed.connect(_on_value_changed)
	_slider.drag_ended.connect(_on_drag_ended)
	add_child(_slider)

func _lowest_frequency() -> float:
	var lowest := INF
	for key in NoteMapping.NOTES:
		lowest = minf(lowest, float(NoteMapping.NOTES[key]["freq"]))
	return lowest

func _highest_frequency() -> float:
	var highest := 0.0
	for key in NoteMapping.NOTES:
		highest = maxf(highest, float(NoteMapping.NOTES[key]["freq"]))
	return highest

func _on_value_changed(value: float) -> void:
	AudioManager.play_continuous_pitch(value)

func _on_drag_ended(_value_changed: bool) -> void:
	AudioManager.stop_continuous_pitch()
	var note := NoteMapping.nearest_note_for_frequency(_slider.value)
	note_triggered.emit(note)
