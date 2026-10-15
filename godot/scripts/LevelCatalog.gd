extends Node
## Autoload / Catálogo oficial de níveis do BlindTuner.
## Agrupa todos os níveis da campanha narrativa e didática.

const LevelDataScript := preload("res://scripts/LevelData.gd")

# Array[LevelData] omitido de propósito: GUT requer compatibilidade com preload sem class_name.
var ALL: Array = []

func _ready() -> void:
	if ALL.is_empty():
		ALL = _build_all()

func _build_all() -> Array:
	return [
		# --- CAPÍTULO 1: O Refúgio Conhecido (A Casa) ---
		# 1.1 Quarto: Introdução ao movimento 8 direções até o rádio vintage
		_make(
			"ch1_quarto_radio",
			1, 1,
			"O Despertar do Rádio",
			"O som do rádio sobre a cômoda me orienta no quarto escuro.",
			"Pelo som do rádio eu sei onde fica a porta e onde começa o dia.",
			"quarto",
			["Cs4", "D4", "D4", "D4", "Ds4", "D4"],
			"piano",
			0, # Pista 0: tudo visível
			0, # Joystick
			25.0,
			"radio",
			"Siga o som do rádio sobre a cômoda.",
			0.0, 1.2, 0.0, 0.0
		),

		# 1.2 Quarto (Noite): A Canção de Ninar para ir dormir entre os obstáculos
		_make(
			"ch1_lullaby_dormir",
			1, 2,
			"A Canção de Ninar",
			"Ao chegar em casa à noite, caminho no escuro em direção à cama, guiado por uma suave canção de ninar.",
			"Mesmo sem enxergar as quinas dos móveis, a melodia de ninar me conduziu em segurança ao descanso.",
			"quarto_lullaby",
			["E4", "E4", "G4", "E4", "E4", "G4", "E4", "G4", "C4"],
			"piano",
			1, # Pista 1: freq + cor (nomes das notas somem)
			0, # Joystick
			30.0,
			"music_box",
			"Siga a suave canção de ninar perto da cama.",
			0.8, 0.75, 0.35, 0.2
		),

		# 1.3 Banheiro: Passos com cautela e desvios
		_make(
			"ch1_banheiro_cautela",
			1, 3,
			"O Fio da Água",
			"O gotejar na pia me ajuda a contar os passos até o banheiro.",
			"A água pingando sempre esteve lá, mas agora eu realmente a escuto.",
			"banheiro",
			["C4", "Cs4", "C4", "Cs4", "C4", "Cs4", "G4", "Cs4", "G4"],
			"piano",
			1, # Pista 1: freq + cor
			0, # Joystick
			35.0,
			"drip",
			"Siga o som da torneira pingando na pia.",
			1.6, 0.60, 0.50, 0.4
		),

		# 1.4 Sala de Estar: Caminho mais longo até a poltrona
		_make(
			"ch1_sala_poltrona",
			1, 4,
			"O Pêndulo da Sala",
			"O tique-taque ritmado do relógio guia meus passos pela sala de estar.",
			"Cada compasso do relógio marca a certeza de um passo firme.",
			"sala",
			["C4", "Cs4", "C4", "G4", "Cs4", "C4", "Cs4", "C4", "G4", "Cs4", "Cs4", "G4", "G4", "G4"],
			"piano",
			2, # Pista 2: só cor (nomes e Hz somem)
			1, # Piano Virtual
			45.0,
			"clock",
			"Siga o tique-taque ritmado do relógio de pêndulo.",
			2.4, 0.45, 0.65, 0.7
		),
	]

func _make(
	p_id: String,
	p_chapter: int,
	p_level_num: int,
	p_title: String,
	p_intro: String,
	p_outro: String,
	p_map_id: String,
	p_notes: Array,
	p_instrument: String = "piano",
	p_cue_lvl: int = 0,
	p_input_mode: int = 0,
	p_target_time: float = 30.0,
	p_beacon_sound_id: String = "",
	p_beacon_hint: String = "",
	p_vision_blur: float = 0.0,
	p_vision_vignette: float = 1.2,
	p_vision_darkness: float = 0.0,
	p_vision_desat: float = 0.0
) -> Resource:
	var lvl = LevelDataScript.new()
	lvl.id = p_id
	lvl.chapter = p_chapter
	lvl.level_number = p_level_num
	lvl.title = p_title
	lvl.story_intro = p_intro
	lvl.story_outro = p_outro
	lvl.map_id = p_map_id
	var typed_notes: Array[String] = []
	for n in p_notes:
		typed_notes.append(str(n))
	lvl.notes = typed_notes
	lvl.instrument = p_instrument
	lvl.default_cue_level = p_cue_lvl
	lvl.default_input_mode = p_input_mode
	lvl.target_time_sec = p_target_time
	lvl.max_trips_for_three_stars = 0
	lvl.beacon_sound_id = p_beacon_sound_id
	lvl.beacon_hint = p_beacon_hint
	lvl.vision_blur = p_vision_blur
	lvl.vision_vignette = p_vision_vignette
	lvl.vision_darkness = p_vision_darkness
	lvl.vision_desaturation = p_vision_desat
	return lvl

func by_id(p_id: String) -> Resource:
	for lvl in ALL:
		if lvl.id == p_id:
			return lvl
	return null

func by_chapter(chapter_num: int) -> Array:
	var res: Array = []
	for lvl in ALL:
		if lvl.chapter == chapter_num:
			res.append(lvl)
	return res

func get_first_level() -> Resource:
	return ALL[0] if not ALL.is_empty() else null

func get_next_level(current_id: String) -> Resource:
	for i in range(ALL.size()):
		if ALL[i].id == current_id:
			if i + 1 < ALL.size():
				return ALL[i + 1]
			return null
	return null
