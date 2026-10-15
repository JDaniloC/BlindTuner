extends Resource
class_name LevelData
## Modelo de dados para um nível da campanha do BlindTuner.
## Agrupa mapa, melodia, instrumento, dicas visuais e contexto narrativo.

@export var id: String = ""
@export var chapter: int = 1
@export var level_number: int = 1
@export var title: String = ""
@export_multiline var story_intro: String = ""
@export_multiline var story_outro: String = ""
@export var beacon_sound_id: String = "" # "radio" | "music_box" | "drip" | "clock"
@export var beacon_hint: String = ""     # Ex: "Siga o som do rádio sobre a cômoda."
@export var song_title: String = ""      # Peça em domínio público (ex: "Ode à Alegria")
@export var composer: String = ""        # Compositor e ano (ex: "Ludwig van Beethoven (1824)")

@export var map_id: String = ""
@export var notes: Array = []
@export var instrument: String = "piano" # "piano" | "cello"
@export var default_cue_level: int = 0   # 0: tudo, 1: freq+cor, 2: só cor, 3: só som
@export var default_input_mode: int = 0  # 0: Joystick, 1: Piano, 2: Scroll
@export var allowed_input_modes: Array[int] = [0, 1, 2]

@export var target_time_sec: float = 30.0
@export var max_trips_for_three_stars: int = 0

@export var vision_blur: float = 0.0
@export var vision_vignette: float = 1.0
@export var vision_darkness: float = 0.0
@export var vision_desaturation: float = 0.0

@export var show_floor: bool = true
@export var show_visual_cues: bool = true
@export var show_obstacle_outlines: bool = true

func is_valid() -> bool:
	if id.is_empty() or title.is_empty() or map_id.is_empty():
		return false
	if notes.is_empty():
		return false
	if chapter < 1 or level_number < 1:
		return false
	return true

func total_steps() -> int:
	return notes.size()
