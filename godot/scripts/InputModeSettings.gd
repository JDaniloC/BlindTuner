extends Node
## Autoload — modo de input ativo (joystick ou um dos 3 modos alternativos). Pura apresentação/roteamento.

signal mode_changed(mode: int)

enum Mode { JOYSTICK, BLIND_TOUCH, PIANO, PITCH_SCROLL }

var mode: int = Mode.JOYSTICK

func set_mode(m: int) -> void:
	if m == mode:
		return
	mode = m
	mode_changed.emit(mode)
