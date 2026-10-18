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
		"status": "available",
		"teasers": [
			{ "num": "3.1", "title": "O Sussurro da Maré", "beacon": "Ondas na areia", "icon": "🌊", "story": "O mar vem e vai, apagando minhas pegadas e afinando meus passos." },
			{ "num": "3.2", "title": "A Neblina da Estação", "beacon": "Vapor de locomotiva", "icon": "🚂", "story": "Na névoa branca que tomou meus olhos, o apito do trem desenha a saída." },
			{ "num": "3.3", "title": "A Melodia Guardada", "beacon": "Violoncelo solo", "icon": "🎻", "story": "As cordas de aço não envelhecem. O som de um ré continua límpido." },
			{ "num": "3.4", "title": "O Recital no Vazio", "beacon": "Sinos de vento", "icon": "✨", "story": "Não preciso mais enxergar a sala. Aprendi a ver com os ouvidos." }
		]
	},
	101: {
		"title": "Caderno Suzuki: Vol. 1 — Primeiros Passos",
		"subtitle": "Pequenas canções para encontrar objetos queridos e arrumar a casa.",
		"description": "Estudos melódicos do Livro 1 do Método Suzuki contextualizados na rotina do lar. Pistas auditivas de vento, relógios e regadores.",
		"status": "available"
	},
	102: {
		"title": "Caderno Suzuki: Vol. 2 — A Casa em Movimento",
		"subtitle": "O ritmo da valsa e os passos ligeiros acompanhando nossos companheiros.",
		"description": "Estudos melódicos do Livro 2 com dinâmicas mais vivas, o gato brincalhão e o roçar cadenciado da vassoura.",
		"status": "available"
	},
	103: {
		"title": "Caderno Suzuki: Vol. 3 — Destreza e Encontros",
		"subtitle": "A bicicleta do carteiro e o calor reconfortante do chá na cozinha.",
		"description": "Estudos melódicos do Livro 3 do Método Suzuki. Ritmo sincopado gracioso e a calma do violoncelo em travessias cotidianas.",
		"status": "available"
	},
	104: {
		"title": "Caderno Suzuki: Vol. 4 — O Concerto e a Memória",
		"subtitle": "Partituras ao vento e a comunhão de dois violinos afinados.",
		"description": "Estudos do Livro 4 com semi-colcheias ligeiras e duetos barrocos. Desafios de agilidade auditiva e orientação espacial viva.",
		"status": "available"
	},
	105: {
		"title": "Caderno Suzuki: Vol. 5 — Danças e Romarias",
		"subtitle": "O aroma das flores frescas da feira e o cantar dos pássaros.",
		"description": "Estudos do Livro 5 em danças campestres. Pistas de borrifadores de água, transeuntes e desvios de caixotes.",
		"status": "available"
	},
	106: {
		"title": "Caderno Suzuki: Vol. 6 — Ecos e Catedrais",
		"subtitle": "A acústica sagrada da abóbada e os passos firmes sobre as lajes de pedra.",
		"description": "Estudos do Livro 6 com variações solenes de La Folia de Corelli. Ecolocalização em ambiente de alta reverberação.",
		"status": "available"
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
			[
				{"type": "dog", "grid": Vector2i(7, 2), "name": "Thor"},
				{"type": "postman", "grid": Vector2i(3, 4), "name": "Tiago o Carteiro"}
			]
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
			"W.A. Mozart (1781)",
			[
				{"type": "pedestrian", "grid": Vector2i(5, 3), "name": "Dona Rosa"},
				{"type": "baker", "grid": Vector2i(7, 3), "name": "Seu Alberto"}
			]
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

		# --- CAPÍTULO 3: AS ÚLTIMAS PAISAGENS (A ESCUTA PLENA) ---
		# 3.1 Praia do Mirante: O Sussurro da Maré
		_make(
			"ch3_praia_mare",
			3, 1,
			"O Sussurro da Maré",
			"O murmúrio das ondas vem e vai, apagando minhas pegadas na areia molhada. Sigo o sussurro da espuma até encontrar o banco do mirante.",
			"Sento-me na madeira salgada do banco. O mar continua cantando a mesma canção que ouvi pela primeira vez há sessenta anos.",
			"praia_mirante",
			["D4", "D4", "Ds4", "D4", "D4", "D4", "D4"],
			"cello", # Violoncelo solo
			3, # Pista 3: só som
			0, # Joystick
			35.0,
			"ocean_waves",
			"Siga o murmúrio cadenciado das ondas quebrando na praia.",
			0.0, 0.5, 0.85, 0.9,
			false, false, true, # Chão invisível, pistas invisíveis, contornos no pulso da bengala
			"Prélude da Suíte para Cello nº 1 (BWV 1007)",
			"J.S. Bach (1720)"
		),

		# 3.2 Plataforma da Estação: A Neblina da Estação
		_make(
			"ch3_estacao_neblina",
			3, 2,
			"A Neblina da Estação",
			"A névoa branca tomou a plataforma de embarque. Não vejo os trilhos nem as vigas de ferro, mas o apito grave da locomotiva desenha a saída na minha memória.",
			"O calor da caldeira e o cheiro de carvão me alcançam. Encontrei o estribo do vagão sem vacilar um só passo.",
			"estacao_plataforma",
			["C4", "C4", "C4", "C4", "C4", "C4", "C4"],
			"cello",
			3,
			0,
			35.0,
			"train_whistle",
			"Siga o apito grave e o vapor da locomotiva ao final do cais.",
			0.0, 0.45, 0.9, 0.95,
			false, false, true,
			"O Cisne (Le Cygne)",
			"Camille Saint-Saëns (1886)"
		),

		# 3.3 Estúdio do Conservatório: A Melodia Guardada
		_make(
			"ch3_estudio_violoncelo",
			3, 3,
			"A Melodia Guardada",
			"As cordas de aço não envelhecem. Mesmo no silêncio da sala escura, a vibração do espigão de metal no assoalho guia meus dedos até a estante de partituras.",
			"Minhas mãos tocam a voluta de madeira esculpida. O violoncelo ainda vibra com o calor de todas as sonatas que já tocamos juntos.",
			"estudio_conservatorio",
			["D4", "D4", "Cs4", "D4", "D4", "D4", "D4", "D4"],
			"cello",
			3,
			0,
			40.0,
			"cello_drone",
			"Siga a ressonância profunda da corda solta do violoncelo.",
			0.0, 0.4, 0.95, 1.0,
			false, false, true,
			"Élégie, Op. 24",
			"Gabriel Fauré (1880)",
			[{"type": "cat", "grid": Vector2i(7, 3), "name": "Mimi"}]
		),

		# 3.4 Palco do Grande Teatro: O Recital no Vazio (Epílogo)
		_make(
			"ch3_teatro_recital",
			3, 4,
			"O Recital no Vazio",
			"Não há mais luzes, nem plateia aos olhos, nem linhas no chão. Mas o ar do teatro respira comigo. Caminho até o centro do palco guiado pelos sinos da ribalta.",
			"Pousei o arco sobre as quatro cordas. O teatro inteiro se encheu de luz sonora. Aprendi a ver com os ouvidos, e o mundo nunca foi tão belo.",
			"teatro_palco",
			["Fs4", "Fs4", "G4", "Fs4", "Fs4", "Fs4", "Fs4", "Fs4"],
			"cello",
			3,
			1, # Piano Virtual
			45.0,
			"wind_chimes",
			"Siga os sinos de cristal cintilando no centro do palco vazio.",
			0.0, 0.3, 0.95, 1.0,
			false, false, false, # Escuridão completa: apenas som e o eco da bengala
			"Largo da Sinfonia do Novo Mundo (Going Home)",
			"Antonín Dvořák (1893)",
			[],
			true # remove_control_colors: modo autêntico sem cores nos controles
		),

		# --- MODO ARCADE: CADERNO SUZUKI VOLUME 1 (PRIMEIROS PASSOS) ---
		# S1.1 Canção do Vento: A Janela Batendo no Vento
		_make(
			"arcade_suzuki_1_1",
			101, 1,
			"A Janela Batendo no Vento",
			"O vento da tarde começou a soprar forte e a janela da sala está batendo sem parar. Preciso atravessar o tapete até a parede leste e girar a tranca antes que a chuva comece.",
			"A tranca girou com um estalo firme. A chuva lá fora agora é só um sussurro gostoso contra o vidro.",
			"arcade_s1_vento",
			["D4", "D4", "Ds4", "D4", "Ds4", "D4", "D4"],
			"piano",
			0,
			0,
			25.0,
			"window_wind",
			"Siga o som da veneziana batendo com o vento.",
			0.0, 0.8, 0.0, 0.0,
			true, true, true,
			"Canção do Vento (Song of the Wind)",
			"Folclore Tradicional"
		),

		# S1.2 Gavotte (Gossec): Cadê os Meus Óculos?
		_make(
			"arcade_suzuki_1_2",
			101, 2,
			"Cadê os Meus Óculos?",
			"Tenho certeza de que deixei meus óculos de leitura em cima da escrivaninha. Sem eles, as partituras viram névoa. Sigo o estalo ritmado da gaveta até alcançar o veludo do estojo.",
			"Encontrei! O aro de metal frio se encaixa no rosto. As linhas da pauta voltam a ter contornos nítidos.",
			"arcade_s1_oculos",
			["D4", "D4", "G4", "D4", "D4", "D4", "Ds4"],
			"piano",
			1,
			0,
			25.0,
			"wrist_watch",
			"Siga o tique-taque suave do relógio de pulso junto ao estojo.",
			0.0, 0.85, 0.1, 0.1,
			true, true, true,
			"Gavotte",
			"François-Joseph Gossec (1734–1829)",
			[{"type": "cat", "grid": Vector2i(6, 4), "name": "Mimi"}]
		),

		# S1.3 O Fazendeiro Alegre (Schumann): A Samambaia da Sala
		_make(
			"arcade_suzuki_1_3",
			101, 3,
			"A Samambaia da Sala",
			"A samambaia chorona no canto da sala sente quando o ar fica seco. Com o regador de latão em mãos, sigo o aroma de terra úmida até o vaso suspenso.",
			"As gotas caem frescas sobre a folhagem verde. O ar da sala fica mais leve e perfumado.",
			"arcade_s1_planta",
			["D4", "D4", "Ds4", "D4", "Cs4", "D4", "Cs4"],
			"piano",
			1,
			0,
			25.0,
			"watering_can",
			"Siga o gotejar do regador de bico fino perto da planta.",
			0.0, 0.9, 0.15, 0.2,
			true, true, true,
			"O Fazendeiro Alegre (The Happy Farmer)",
			"Robert Schumann (1848)",
			[{"type": "canary", "grid": Vector2i(5, 3), "name": "Piu-Piu"}]
		),

		# S1.4 Minueto nº 1 (Bach / Petzold): O Pão da Tarde e a Louça de Domingo
		_make(
			"arcade_suzuki_1_4",
			101, 4,
			"O Pão da Tarde e a Louça de Domingo",
			"O aroma de bolo de fubá acabou de sair do forno. Agora é hora de encontrar o açucareiro na bancada alta para adoçar o café das visitas.",
			"A xícara tilinta em harmonia com a colher de prata. Café quente servido com carinho.",
			"arcade_s1_louca",
			["D4", "D4", "D4", "Cs4", "Ds4", "D4"],
			"piano",
			2,
			0,
			25.0,
			"tea_cup",
			"Siga o tilintar suave da colher de prata na xícara de porcelana.",
			0.0, 0.95, 0.2, 0.3,
			true, true, true,
			"Minueto nº 1 (BWV Anh. 114)",
			"J.S. Bach / Christian Petzold (1725)"
		),

		# --- MODO ARCADE: CADERNO SUZUKI VOLUME 2 (A CASA EM MOVIMENTO) ---
		# S2.1 Coro dos Caçadores (Weber): A Fuga do Gato Mimi
		_make(
			"arcade_suzuki_2_1",
			102, 1,
			"A Fuga do Gato Mimi",
			"Mimi pegou meu novelo de linha favorito e saiu correndo pela sala de estar. O sininho na coleira dele me diz exatamente por onde ele passou: embaixo do sofá e atrás da estante!",
			"Peguei o novelo de volta e ainda ganhei um carinho ronronado nos tornozelos.",
			"arcade_s2_gato",
			["D4", "D4", "G4", "D4", "D4", "D4", "Ds4"],
			"piano",
			1,
			0,
			25.0,
			"cat_bell",
			"Siga o tilintar do sininho na coleira travessa do Mimi.",
			0.0, 0.85, 0.1, 0.1,
			true, true, true,
			"Coro dos Caçadores (Der Freischütz)",
			"Carl Maria von Weber (1821)",
			[{"type": "cat", "grid": Vector2i(6, 4), "name": "Mimi"}]
		),

		# S2.2 Valsa Op. 39 nº 15 (Brahms): A Valsa da Vassoura
		_make(
			"arcade_suzuki_2_2",
			102, 2,
			"A Valsa da Vassoura",
			"Varrer o chão no escuro é como dançar: um passo para frente, dois balanços de vassoura. O som da palha recolhendo as folhas secas me diz onde o piso já está limpo.",
			"O chão ficou brilhante e limpo, sem uma única folha para trás. Um passo de valsa perfeito.",
			"arcade_s2_valsa",
			["D4", "D4", "Ds4", "D4", "D4", "Ds4", "D4"],
			"piano",
			2,
			0,
			25.0,
			"broom_sweep",
			"Siga o roçar cadenciado das cerdas da vassoura de palha.",
			0.0, 0.9, 0.2, 0.25,
			true, true, true,
			"Valsa Op. 39 nº 15",
			"Johannes Brahms (1865)"
		),

		# S2.3 Minueto em Sol Maior (Beethoven): O Molho de Chaves Antigo
		_make(
			"arcade_suzuki_2_3",
			102, 3,
			"O Molho de Chaves Antigo",
			"Três chaves de dentes grandes e uma redondinha do guarda-comida. Preciso chegar até o aparador da entrada para pegar o chaveiro antes que o entregador chegue.",
			"O chaveiro de latão tilintou na minha mão. A porta está pronta para ser aberta.",
			"arcade_s2_chaves",
			["D4", "D4", "Cs4", "D4", "D4", "D4"],
			"piano",
			2,
			0,
			25.0,
			"keys_jingle",
			"Siga o tinir metálico das chaves pesadas penduradas no aparador.",
			0.0, 0.95, 0.25, 0.35,
			true, true, true,
			"Minueto em Sol Maior",
			"Ludwig van Beethoven (1796)",
			[{"type": "dog", "grid": Vector2i(7, 3), "name": "Thor"}]
		),

		# S2.4 Gavotte (Lully): O Pêndulo da Meia-Noite
		_make(
			"arcade_suzuki_2_4",
			102, 4,
			"O Pêndulo da Meia-Noite",
			"O tique-taque ritmado do relógio de parede no corredor marca a cadência da casa que adormece. Sigo o compasso das badaladas leves para conferir os trincos antes de deitar.",
			"O pêndulo de latão oscila calmo à minha frente. A casa inteira respira no mesmo compasso sereno.",
			"arcade_s2_pendulo",
			["D4", "Cs4", "D4", "D4", "Ds4", "D4", "Cs4"],
			"piano",
			2,
			0,
			25.0,
			"clock",
			"Siga o tique-taque constante e metálico do grande relógio de pêndulo.",
			0.0, 0.95, 0.25, 0.35,
			true, true, true,
			"Gavotte",
			"Jean-Baptiste Lully (1632–1687)",
			[{"type": "cat", "grid": Vector2i(5, 6), "name": "Mimi"}]
		),

		# --- MODO ARCADE: CADERNO SUZUKI VOLUME 3 (DESTREZA E ENCONTROS) ---
		# S3.1 Humoresque (Dvořák): A Bicicleta do Carteiro
		_make(
			"arcade_suzuki_3_1",
			103, 1,
			"A Bicicleta do Carteiro",
			"A campainha dupla da bicicleta anuncia uma carta com selo distante. O carteiro tem pressa, então conto os passos na calçada de paralelepípedos até a caixa de correio.",
			"A carta de papel encorpado está segura na minha mão. O cheiro de maresia e tinta fresca me lembra velhos amigos.",
			"arcade_s3_carteiro",
			["D4", "D4", "Ds4", "Cs4", "D4", "D4", "Cs4"],
			"piano",
			2,
			0,
			25.0,
			"bike_bell",
			"Siga o trim-trim alegre da campainha da bicicleta encostada no portão.",
			0.0, 0.95, 0.25, 0.35,
			true, true, true,
			"Humoresque (Op. 101 nº 7)",
			"Antonín Dvořák (1894)",
			[
				{"type": "postman", "grid": Vector2i(6, 3), "name": "Tiago o Carteiro"},
				{"type": "pigeon", "grid": Vector2i(4, 5), "name": "Pipo"}
			]
		),

		# S3.2 Bourrée (Bach): O Chá na Cozinha Tarde da Noite
		_make(
			"arcade_suzuki_3_2",
			103, 2,
			"O Chá na Cozinha Tarde da Noite",
			"Duas da manhã e o sono não vem. Caminho descalço pela cozinha fria até a bancada do bule, sentindo a mudança de temperatura nos azulejos.",
			"A caneca esmaltada aquece minhas mãos. O aroma de camomila e mel traz a calma de que a noite precisava.",
			"arcade_s3_cha",
			["D4", "Cs4", "D4", "Ds4", "D4", "D4"],
			"cello",
			2,
			0,
			25.0,
			"tea_cup",
			"Siga o vapor quente e o tilintar da colher de chá na caneca esmaltada.",
			0.0, 0.95, 0.25, 0.35,
			true, true, true,
			"Bourrée (Suíte para Cello nº 3)",
			"J. S. Bach (1720)",
			[{"type": "cat", "grid": Vector2i(5, 5), "name": "Mimi"}]
		),

		# S3.3 Gavotte em Sol Menor (Bach): O Aroma do Café Moído
		_make(
			"arcade_suzuki_3_3",
			103, 3,
			"O Aroma do Café Moído",
			"Na despensa de madeira, o velho moedor manual guarda os grãos torrados da manhã. Pelo ranger ritmado da manivela de ferro e o aroma tostado, encontro o caminho até a bancada rústica.",
			"O pó fino de café perfuma o ar da cozinha. A madeira áspera do balcão me dá as boas-vindas ao novo dia.",
			"arcade_s3_moedor",
			["D4", "D4", "Ds4", "D4", "Cs4", "D4", "D4"],
			"cello",
			2,
			0,
			25.0,
			"coffee_grinder",
			"Siga o ranger cadenciado e seco da manivela do moedor de café na bancada.",
			0.0, 0.95, 0.25, 0.35,
			true, true, true,
			"Gavotte em Sol Menor",
			"J. S. Bach (1685–1750)",
			[{"type": "canary", "grid": Vector2i(4, 4), "name": "Pitoquinho"}]
		),

		# S3.4 Canção Triste (Tchaikovsky): O Apito da Chaleira
		_make(
			"arcade_suzuki_3_4",
			103, 4,
			"O Apito da Chaleira",
			"A água ferveu sobre o fogão de lenha. O apito fino e constante da chaleira corta a penumbra da cozinha com um calor amigo.",
			"Retirei a chaleira da chama com a luva acolchoada. O chiado cessa devagar, deixando apenas a fumaça acolhedora.",
			"arcade_s3_chaleira",
			["D4", "Cs4", "D4", "Ds4", "D4", "Cs4", "D4"],
			"cello",
			2,
			0,
			25.0,
			"kettle_whistle",
			"Siga o apito contínuo e aveludado do vapor subindo da chaleira.",
			0.0, 0.95, 0.25, 0.35,
			true, true, true,
			"Canção Triste Op. 40 nº 2",
			"P. I. Tchaikovsky (1840–1893)",
			[{"type": "cat", "grid": Vector2i(4, 7), "name": "Mimi"}]
		),

		# --- MODO ARCADE: CADERNO SUZUKI VOLUME 4 (O CONCERTO E A MEMÓRIA) ---
		# S4.1 Concerto em Lá Menor (Vivaldi): O Vento Espalhou as Partituras
		_make(
			"arcade_suzuki_4_1",
			104, 1,
			"O Vento Espalhou as Partituras",
			"A rajada de vento abriu a porta da varanda e espalhou todas as folhas da minha sonata no chão! Preciso recolher cada página seguindo o sussurro do papel.",
			"Todas as folhas recolhidas e arrumadas em ordem sobre o piano. Nenhuma nota se perdeu na ventania.",
			"arcade_s4_vento",
			["D4", "Ds4", "D4", "Cs4", "D4", "D4", "Cs4"],
			"cello",
			2,
			0,
			30.0,
			"paper_rustle",
			"Siga o farfalhar suave das folhas de partitura deslizando pelo assoalho.",
			0.0, 0.95, 0.30, 0.40,
			true, true, true,
			"Concerto em Lá Menor: Allegro",
			"Antonio Vivaldi (1711)",
			[{"type": "canary", "grid": Vector2i(3, 4), "name": "Pitoquinho"}]
		),

		# S4.2 Concerto para Dois Violinos (Bach): O Concerto para Dois Amigos
		_make(
			"arcade_suzuki_4_2",
			104, 2,
			"O Concerto para Dois Amigos",
			"Meu velho parceiro de orquestra afinou o violino no outro canto da sala. Quando ele ataca a primeira frase, meu arco responde quase por instinto na mesma pulsação.",
			"O acorde final ressoa em perfeita harmonia. Dois instrumentos, um único coração afinado pelo tempo.",
			"arcade_s4_duo",
			["D4", "D4", "D4", "Ds4", "D4", "D4", "Ds4"],
			"cello",
			2,
			0,
			30.0,
			"cello_drone",
			"Siga a harmonia contínua do violino afinando no centro do salão.",
			0.0, 0.95, 0.30, 0.40,
			true, true, true,
			"Concerto para Dois Violinos em Ré Menor",
			"J. S. Bach (1730)",
			[{"type": "cat", "grid": Vector2i(6, 4), "name": "Mimi"}]
		),

		# S4.3 Concerto em Sol Maior (Telemann): O Pátio das Sebes e Laranjeiras
		_make(
			"arcade_suzuki_4_3",
			104, 3,
			"O Pátio das Sebes e Laranjeiras",
			"O vento da tarde agita as folhas das laranjeiras no jardim interno. Sigo o tilintar dos pequenos sinos de latão pendurados na pérgola enquanto desvio dos vasos de cerâmica.",
			"O perfume cítrico das folhas machucadas pelo vento me envolve. O jardim se desenha como uma partitura aberta.",
			"arcade_s4_patio",
			["D4", "D4", "Ds4", "D4", "D4", "Cs4", "D4"],
			"cello",
			2,
			0,
			30.0,
			"wind_chimes",
			"Siga o retinir cristalino e aleatório dos sinos de vento na pérgola.",
			0.0, 0.95, 0.30, 0.40,
			true, true, true,
			"Concerto em Sol Maior: Allegro",
			"Georg Philipp Telemann (1681–1767)",
			[{"type": "dog", "grid": Vector2i(5, 7), "name": "Thor"}]
		),

		# S4.4 Movimento Perpétuo (Bohm): O Tear da Tecelã
		_make(
			"arcade_suzuki_4_4",
			104, 4,
			"O Tear da Tecelã",
			"O vaivém perpétuo da lançadeira no tear de madeira dita uma cadência hipnótica. Passo a passo, o som de linha esticada e batida de pente me guia pelo ateliê de tecidos.",
			"Toquei a trama macia do linho recém-tecido no tear. O ritmo incessante descansou sob minhas mãos.",
			"arcade_s4_tear",
			["D4", "Ds4", "D4", "D4", "Cs4", "D4", "Ds4"],
			"cello",
			2,
			0,
			30.0,
			"loom_shuttle",
			"Siga o estalo ritmado da lançadeira de madeira cruzando a urdidura do tear.",
			0.0, 0.95, 0.30, 0.40,
			true, true, true,
			"Movimento Perpétuo (Perpetual Motion)",
			"Carl Bohm (1844–1920)",
			[{"type": "canary", "grid": Vector2i(6, 6), "name": "Pitoquinho"}]
		),

		# --- MODO ARCADE: CADERNO SUZUKI VOLUME 5 (DANÇAS E ROMARIAS) ---
		# S5.1 Dança Campestre (Weber): A Barraca de Flores da Feira
		_make(
			"arcade_suzuki_5_1",
			105, 1,
			"A Barraca de Flores da Feira",
			"O sábado de feira é uma festa de aromas. Sigo o perfume de eucalipto e terra molhada até a barraca de flores para escolher um ramo de margaridas.",
			"O ramo de flores frescas repousa em meus braços. As folhas úmidas tocam meu rosto como uma brisa suave.",
			"arcade_s5_flores",
			["D4", "Cs4", "D4", "D4", "Ds4", "D4", "Cs4"],
			"piano",
			2,
			0,
			30.0,
			"fountain_birds",
			"Siga o borrifador de água e o cantar dos passarinhos perto das flores.",
			0.0, 0.95, 0.30, 0.40,
			true, true, true,
			"Dança Campestre (Country Dance)",
			"Carl Maria von Weber",
			[{"type": "pigeon", "grid": Vector2i(4, 4), "name": "Pipo"}, {"type": "dog", "grid": Vector2i(6, 6), "name": "Thor"}]
		),

		# S5.2 Dança Alemã (Dittersdorf): O Fole da Sanfona na Taberna
		_make(
			"arcade_suzuki_5_2",
			105, 2,
			"O Fole da Sanfona na Taberna",
			"Perto da pracinha, os acordes alegres de um acordeão ecoam pela porta aberta da estalagem. O ar cheira a madeira encerada e pão fresco.",
			"O acorde final da dança foi celebrado com risos e palmas. A música de rua é a melhor bússola do viajante.",
			"arcade_s5_sanfona",
			["D4", "D4", "Cs4", "D4", "Ds4", "D4", "Cs4"],
			"piano",
			2,
			0,
			30.0,
			"accordion_drone",
			"Siga a respiração viva do fole e o acorde estridente do acordeão.",
			0.0, 0.95, 0.30, 0.40,
			true, true, true,
			"Dança Alemã (German Dance)",
			"Carl Ditters von Dittersdorf (1739–1799)",
			[{"type": "dog", "grid": Vector2i(6, 6), "name": "Thor"}]
		),

		# S5.3 Gavotte en Rondeau (Bach): O Baile das Castanholas
		_make(
			"arcade_suzuki_5_3",
			105, 3,
			"O Baile das Castanholas",
			"O compasso vivo de uma gavotte salta entre as arcadas do pátio de paralelepípedos. O estalar seco de castanholas de madeira me chama ao centro do círculo de dança.",
			"O último estalido ecoou sob as vigas de carvalho. Meus pés encontraram o centro exato da festa.",
			"arcade_s5_castanholas",
			["D4", "Ds4", "D4", "Cs4", "D4", "D4", "Cs4"],
			"piano",
			2,
			0,
			30.0,
			"castanets_click",
			"Siga o estalar brilhante e rápido das castanholas de jacarandá.",
			0.0, 0.95, 0.30, 0.40,
			true, true, true,
			"Gavotte en Rondeau (Partita nº 3)",
			"J. S. Bach (1685–1750)",
			[{"type": "pigeon", "grid": Vector2i(5, 6), "name": "Pipo"}]
		),

		# S5.4 Giga em Ré Maior (Bach): O Ancoradouro dos Veleiros
		_make(
			"arcade_suzuki_5_4",
			105, 4,
			"O Ancoradouro dos Veleiros",
			"O sino de bronze do píer avisa quando a balsa atraca. As tábuas de pinho estalam sob os passos enquanto o marulho bate calmo contra os mourões de amarra.",
			"O cabo de amarração foi laçado no cabeço de ferro. O vento salgado sopra com a promessa de novas travessias.",
			"arcade_s5_ancoradouro",
			["D4", "D4", "Ds4", "D4", "Cs4", "D4", "D4"],
			"piano",
			2,
			0,
			30.0,
			"dock_bell",
			"Siga as batidas solenes do sino de bronze e o rumor da maré contra o cais.",
			0.0, 0.95, 0.30, 0.40,
			true, true, true,
			"Giga da Suíte em Ré Maior",
			"J. S. Bach (1723)",
			[{"type": "canary", "grid": Vector2i(5, 4), "name": "Pitoquinho"}]
		),

		# --- MODO ARCADE: CADERNO SUZUKI VOLUME 6 (ECOS E CATEDRAIS) ---
		# S6.1 La Folia (Corelli): O Eco na Igreja Matriz
		_make(
			"arcade_suzuki_6_1",
			106, 1,
			"O Eco na Igreja Matriz",
			"A nave da igreja tem uma acústica sagrada. Cada estalo da bengala ressoa nas abóbadas de pedra, desenhando o tamanho do salão nos meus ouvidos.",
			"Cheguei ao altar de pedra sob o eco solene da abóbada. A arquitetura inteira vive dentro da minha escuta.",
			"arcade_s6_igreja",
			["D4", "D4", "Cs4", "D4", "Ds4", "D4"],
			"cello",
			3,
			0,
			35.0,
			"church_bell",
			"Siga a ressonância profunda do sino e o eco na pedra fria.",
			0.0, 0.95, 0.35, 0.50,
			true, true, true,
			"La Folia",
			"Arcangelo Corelli (1700)",
			[{"type": "pigeon", "grid": Vector2i(5, 5), "name": "Pipo"}]
		),

		# S6.2 Sonata em Sol Menor (Eccles): O Som dos Tubos de Órgão
		_make(
			"arcade_suzuki_6_2",
			106, 2,
			"O Som dos Tubos de Órgão",
			"O organista aquece os foles na galeria superior. As notas graves dos tubos de chumbo fazem o piso de mármore vibrar diretamente na sola dos meus sapatos.",
			"O pedal grave do órgão sustentou o silêncio que se seguiu. A igreja inteira vibrou como uma imensa caixa acústica.",
			"arcade_s6_orgao",
			["D4", "Cs4", "D4", "D4", "Ds4", "D4", "Cs4"],
			"cello",
			3,
			0,
			35.0,
			"organ_pipe",
			"Siga a vibração telúrica e grave dos tubos do órgão de foles.",
			0.0, 0.95, 0.35, 0.50,
			true, true, true,
			"Sonata em Sol Menor: Grave",
			"Henry Eccles (1670–1742)",
			[{"type": "pigeon", "grid": Vector2i(5, 6), "name": "Pipo"}]
		),

		# S6.3 Tambourin (Rameau): O Ritmo do Tamborim da Festa
		_make(
			"arcade_suzuki_6_3",
			106, 3,
			"O Ritmo do Tamborim da Festa",
			"O som saltitante do tamborim com guizos conduz os dançarinos pelo claustro do mosteiro. O eco alegre salta de arco em arco sobre as lajes seculares.",
			"O rufar dos guizos pousou suave. A alegria antiga da melodia ficou gravada em cada laje.",
			"arcade_s6_tamborim",
			["D4", "D4", "Ds4", "D4", "Cs4", "D4", "D4"],
			"cello",
			3,
			0,
			35.0,
			"tambourine_shake",
			"Siga o chacoalhar vivo dos guizos de latão do tamborim.",
			0.0, 0.95, 0.35, 0.50,
			true, true, true,
			"Tambourin",
			"Jean-Philippe Rameau (1683–1764)",
			[{"type": "cat", "grid": Vector2i(4, 4), "name": "Mimi"}]
		),

		# S6.4 Chaconne em Sol Menor (Vitali): A Chaconne da Catedral Secular
		_make(
			"arcade_suzuki_6_4",
			106, 4,
			"A Chaconne da Catedral Secular",
			"No ápice da catedral, a acústica transforma cada fricção da corda num monumento invisível. Sigo a reverberação de dez segundos pelas colunas majestosas até o coro alto.",
			"O último acorde da Chaconne ressoou pelo infinito da nave de pedra. Ver com os ouvidos é a suprema afinidade com o mundo.",
			"arcade_s6_catedral",
			["D4", "Ds4", "D4", "Cs4", "D4", "D4", "Cs4"],
			"cello",
			3,
			0,
			35.0,
			"cathedral_echo",
			"Siga o eco imponente e a longa reverberação ressoando pelo topo da abóbada.",
			0.0, 0.95, 0.35, 0.50,
			true, true, true,
			"Chaconne em Sol Menor",
			"Tomaso Antonio Vitali (1663–1745)",
			[{"type": "canary", "grid": Vector2i(4, 4), "name": "Pitoquinho"}, {"type": "pigeon", "grid": Vector2i(6, 6), "name": "Pipo"}]
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
	p_mobs: Array = [],
	p_remove_control_colors: bool = false
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
	lvl.remove_control_colors = p_remove_control_colors
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
				var curr_lvl = ALL[i]
				var next_lvl = ALL[i + 1]
				# O fim do Capítulo 3 (Campanha da História) encerra a narrativa principal
				if curr_lvl.chapter <= 3 and next_lvl.chapter > 3:
					return null
				return next_lvl
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

