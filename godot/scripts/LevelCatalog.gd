extends Node
## Autoload / Catálogo oficial de níveis do BlindTuner.
## Agrupa todos os níveis da campanha narrativa e didática.

const LevelDataScript := preload("res://scripts/LevelData.gd")

const CHAPTER_INFO := {
	1: {
		"title": "Capítulo 1: A Casa Conhecida",
		"subtitle": "Onde cada quina é gravada na ponta dos dedos e o silêncio tem voz.",
		"description": "O refúgio seguro da residência. Pistas visuais altas, instrumentos familiares e a segurança dos objetos cotidianos.",
		"status": "available"
	},
	2: {
		"title": "Capítulo 2: O Bairro e o Cotidiano",
		"subtitle": "O mundo além do portão: ruídos que se cruzam e passos que exigem coragem.",
		"description": "A travessia para o exterior. Calçadas, sons do comércio, praças e a transição para a percepção auditiva refinada.",
		"status": "available"
	},
	3: {
		"title": "Capítulo 3: As Últimas Paisagens",
		"subtitle": "Quando os olhos descansam, a música se torna a única luz.",
		"description": "A escuta plena. O mundo se transforma em pura paisagem sonora com ecolocalização e violoncelo.",
		"status": "coming_soon",
		"teasers": [
			{ "num": "3.1", "title": "O Sussurro da Maré", "beacon": "Ondas na areia", "icon": "🌊", "story": "O mar vem e vai, apagando minhas pegadas e afinando meus passos." },
			{ "num": "3.2", "title": "A Neblina da Estação", "beacon": "Vapor de locomotiva", "icon": "🚂", "story": "Na névoa branca que tomou meus olhos, o apito do trem desenha a saída." },
			{ "num": "3.3", "title": "A Melodia Guardada", "beacon": "Violoncelo solo", "icon": "🎻", "story": "As cordas de aço não envelhecem. O som de um ré continua límpido." },
			{ "num": "3.4", "title": "O Recital no Vazio", "beacon": "Sinos de vento", "icon": "✨", "story": "Não preciso mais enxergar a sala. Aprendi a ver com os ouvidos." }
		]
	}
}

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
			0, # Pista 0: tudo visível (nome, Hz e cor)
			0, # Joystick
			25.0,
			"radio",
			"Siga o som do rádio sobre a cômoda.",
			0.0, 1.2, 0.0, 0.0,
			true, true, true,
			"Ode à Alegria",
			"Ludwig van Beethoven (1824)"
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
			0.0, 0.95, 0.25, 0.35,
			true, true, true,
			"Canção de Ninar (Wiegenlied)",
			"Johannes Brahms (1868)",
			[{"type": "cat", "grid": Vector2i(4, 8), "name": "Mimi"}]
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
			2, # Pista 2: só cor (nomes e Hz somem)
			0, # Joystick
			35.0,
			"drip",
			"Siga o som da torneira pingando na pia.",
			0.0, 0.70, 0.55, 0.75,
			true, false, false, # Pistas visuais e contornos neon retirados
			"Au Clair de la Lune",
			"Folclore Francês (séc. XVIII)"
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
			3, # Pista 3: só som (sem pistas visuais no HUD)
			1, # Piano Virtual
			45.0,
			"clock",
			"Siga o tique-taque ritmado do relógio de pêndulo.",
			0.0, 0.40, 0.95, 1.0,
			false, false, false, # Sem chão e sem pistas visuais (pura percepção auditiva)
			"Minueto em Sol Maior (BWV Anh. 114)",
			"J.S. Bach / C. Petzold (1725)",
			[{"type": "cat", "grid": Vector2i(4, 5), "name": "Mimi"}]
		),

		# --- CAPÍTULO 2: O Bairro e o Cotidiano ---
		# 2.1 Jardim e Portão: A travessia para o mundo exterior
		_make(
			"ch2_portao_ferro",
			2, 1,
			"O Portão de Ferro",
			"A maçaneta fria é a fronteira entre o que conheço e o que aprendo a ouvir. O cão Thor vigia o jardim da frente.",
			"O estalo metálico do trinco abriu o caminho para a rua. Com passo firme e ouvido atento, nada me intimida.",
			"jardim_portao",
			["D4", "D4", "D4", "Ds4", "D4", "D4", "D4"],
			"piano",
			1, # Pista 1: freq + cor
			0, # Joystick
			30.0,
			"gate_latch",
			"Siga o estalo metálico do trinco do portão.",
			0.0, 1.0, 0.15, 0.3,
			true, true, true,
			"Musette em Ré Maior (BWV Anh. 126)",
			"J.S. Bach (1725)",
			[{"type": "dog", "grid": Vector2i(7, 2), "name": "Thor"}]
		),

		# 2.2 Calçada da Padaria: Aromas e o tilintar da porta
		_make(
			"ch2_pao_esquina",
			2, 2,
			"O Pão da Esquina",
			"O sino tilinta ao abrir da porta: cheiro de fermento, pão fresco e conversa baixa na padaria.",
			"A sacola de papel pardo e o calor do pão francês recém-saído do forno aquecem a minha manhã.",
			"padaria_calcada",
			["D4", "D4", "G4", "D4", "D4", "Cs4", "D4", "Ds4"],
			"piano",
			2, # Pista 2: só cor
			0, # Joystick
			35.0,
			"shop_bell",
			"Siga o tinir alegre do sino na porta da padaria.",
			0.0, 0.85, 0.35, 0.5,
			true, true, true,
			"Ah! vous dirai-je, maman (K. 265)",
			"W.A. Mozart (1781)"
		),

		# 2.3 Praça Central: O chafariz de pedra e o arrulho dos pombos
		_make(
			"ch2_praca_chafariz",
			2, 3,
			"O Banco da Praça",
			"O vento balança as copas dos jacarandás; sigo o borbulhar do chafariz e os pombos na praça.",
			"Sentei-me no banco de madeira polida. As asas dos pombos e o frescor da água lavam o cansaço.",
			"praca_chafariz",
			["D4", "D4", "D4", "Ds4", "D4", "D4", "D4"],
			"piano",
			2, # Pista 2: só cor
			0, # Joystick
			35.0,
			"fountain_birds",
			"Siga o borbulhar da água do chafariz e o canto dos pássaros.",
			0.0, 0.65, 0.6, 0.75,
			true, false, false, # Sem pistas visuais nem contornos de obstáculo
			"Primavera: Allegro (Op. 8 nº 1)",
			"Antonio Vivaldi (1725)",
			[
				{"type": "pigeon", "grid": Vector2i(7, 4), "name": "Pombos da Praça"},
				{"type": "pigeon", "grid": Vector2i(8, 3), "name": "Pombos da Praça"}
			]
		),

		# 2.4 Matriz: O eco sagrado do grande sino de bronze
		_make(
			"ch2_igreja_carrilhao",
			2, 4,
			"O Carrilhão da Matriz",
			"As doze badaladas solenes vibram no meu peito. Sigo o eco profundo do bronze até a escadaria da Matriz.",
			"Alcancei o patamar da grande igreja. O som sagrado do sino dissipa qualquer escuridão dos olhos.",
			"largo_matriz",
			["C4", "C4", "Cs4", "G4", "C4", "C4", "Cs4", "G4", "C4", "C4"],
			"cello", # Violoncelo solo
			3, # Pista 3: só som
			1, # Piano Virtual
			45.0,
			"church_bell",
			"Siga as solenes badaladas do sino da torre da Matriz.",
			0.0, 0.35, 0.95, 1.0,
			false, false, false, # Chão invisível, percepção puramente auditiva
			"See, the Conquering Hero Comes (Judas Macabeu)",
			"G.F. Händel (1746)"
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
	p_vision_desat: float = 0.0,
	p_show_floor: bool = true,
	p_show_visual_cues: bool = true,
	p_show_obstacle_outlines: bool = true,
	p_song_title: String = "",
	p_composer: String = "",
	p_mobs: Array = []
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
	lvl.show_floor = p_show_floor
	lvl.show_visual_cues = p_show_visual_cues
	lvl.show_obstacle_outlines = p_show_obstacle_outlines
	lvl.song_title = p_song_title
	lvl.composer = p_composer
	lvl.mobs_data = p_mobs
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

func get_chapter_info(chapter_num: int) -> Dictionary:
	return CHAPTER_INFO.get(chapter_num, {
		"title": "Capítulo %d" % chapter_num,
		"subtitle": "",
		"description": "",
		"status": "unknown",
		"teasers": []
	})

