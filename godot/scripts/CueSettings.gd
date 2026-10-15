extends Node
## Autoload — nível de pista visual (0=tudo … 3=só som). Pura apresentação.

signal cue_level_changed(level: int)
signal vision_effects_changed(enabled: bool)

var cue_level: int = 0
var vision_effects_enabled: bool = true

func set_level(level: int) -> void:
	var c := clampi(level, 0, 3)
	if c == cue_level:
		return
	cue_level = c
	cue_level_changed.emit(cue_level)

func set_vision_effects_enabled(enabled: bool) -> void:
	if vision_effects_enabled == enabled:
		return
	vision_effects_enabled = enabled
	vision_effects_changed.emit(vision_effects_enabled)

func shows_name() -> bool:
	return cue_level <= 0

func shows_freq() -> bool:
	return cue_level <= 1

func shows_color() -> bool:
	return cue_level <= 2
