extends Node
## Autoload — nível de pista visual (0=tudo … 3=só som). Pura apresentação.

signal cue_level_changed(level: int)

var cue_level: int = 0

func set_level(level: int) -> void:
	var c := clampi(level, 0, 3)
	if c == cue_level:
		return
	cue_level = c
	cue_level_changed.emit(cue_level)

func shows_name() -> bool:
	return cue_level <= 0

func shows_freq() -> bool:
	return cue_level <= 1

func shows_color() -> bool:
	return cue_level <= 2
