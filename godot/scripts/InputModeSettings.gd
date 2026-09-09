extends Node
## Autoload — modo de input ativo (joystick ou um dos 2 modos alternativos). Pura apresentação/roteamento.

signal mode_changed(mode: int)

enum Mode { JOYSTICK, PIANO, PITCH_SCROLL }

var mode: int = Mode.JOYSTICK

func set_mode(m: int) -> void:
	m = clampi(m, Mode.JOYSTICK, Mode.PITCH_SCROLL)
	if m == mode:
		return
	mode = m
	mode_changed.emit(mode)
