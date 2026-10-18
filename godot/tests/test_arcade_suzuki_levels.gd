extends GutTest
## Testes de validação dos níveis do Modo Arcade (Repertório Suzuki Volumes 1 e 2)
## Valida capítulos, metadados, faróis procedurais, mobs (Canário, Gato, Cão) e caminhos livres de colisão.

const CanaryMobScript := preload("res://scripts/mobs/CanaryMob.gd")
const BaseMobScript := preload("res://scripts/mobs/BaseMob.gd")

func test_suzuki_chapters_in_catalog():
	var ch101 = LevelCatalog.get_chapter_info(101)
	assert_eq(ch101.get("status"), "available")
	assert_true(str(ch101.get("title")).contains("Vol. 1"))
	
	var ch102 = LevelCatalog.get_chapter_info(102)
	assert_eq(ch102.get("status"), "available")
	assert_true(str(ch102.get("title")).contains("Vol. 2"))

func test_suzuki_volume_1_levels():
	var s1_levels = LevelCatalog.by_chapter(101)
	assert_eq(s1_levels.size(), 4, "Volume 1 deve conter 4 fases (S1.1 a S1.4)")
	
	var s1_1 = LevelCatalog.by_id("arcade_suzuki_1_1")
	assert_not_null(s1_1)
	assert_eq(s1_1.title, "A Janela Batendo no Vento")
	assert_eq(s1_1.beacon_sound_id, "window_wind")
	assert_eq(s1_1.song_title, "Canção do Vento (Song of the Wind)")
	assert_eq(s1_1.instrument, "piano")
	
	var s1_2 = LevelCatalog.by_id("arcade_suzuki_1_2")
	assert_not_null(s1_2)
	assert_eq(s1_2.title, "Cadê os Meus Óculos?")
	assert_eq(s1_2.beacon_sound_id, "wrist_watch")
	assert_eq(s1_2.song_title, "Gavotte")
	
	var s1_3 = LevelCatalog.by_id("arcade_suzuki_1_3")
	assert_not_null(s1_3)
	assert_eq(s1_3.title, "A Samambaia da Sala")
	assert_eq(s1_3.beacon_sound_id, "watering_can")
	assert_eq(s1_3.song_title, "O Fazendeiro Alegre (The Happy Farmer)")
	
	var s1_4 = LevelCatalog.by_id("arcade_suzuki_1_4")
	assert_not_null(s1_4)
	assert_eq(s1_4.title, "O Pão da Tarde e a Louça de Domingo")
	assert_eq(s1_4.beacon_sound_id, "tea_cup")
	assert_eq(s1_4.song_title, "Minueto nº 1 (BWV Anh. 114)")

func test_suzuki_volume_2_levels():
	var s2_levels = LevelCatalog.by_chapter(102)
	assert_eq(s2_levels.size(), 4, "Volume 2 deve conter 4 fases (S2.1 a S2.4)")
	
	var s2_1 = LevelCatalog.by_id("arcade_suzuki_2_1")
	assert_not_null(s2_1)
	assert_eq(s2_1.title, "A Fuga do Gato Mimi")
	assert_eq(s2_1.beacon_sound_id, "cat_bell")
	assert_eq(s2_1.song_title, "Coro dos Caçadores (Der Freischütz)")
	
	var s2_2 = LevelCatalog.by_id("arcade_suzuki_2_2")
	assert_not_null(s2_2)
	assert_eq(s2_2.title, "A Valsa da Vassoura")
	assert_eq(s2_2.beacon_sound_id, "broom_sweep")
	assert_eq(s2_2.song_title, "Valsa Op. 39 nº 15")
	
	var s2_3 = LevelCatalog.by_id("arcade_suzuki_2_3")
	assert_not_null(s2_3)
	assert_eq(s2_3.title, "O Molho de Chaves Antigo")
	assert_eq(s2_3.beacon_sound_id, "keys_jingle")
	assert_eq(s2_3.song_title, "Minueto em Sol Maior")

	var s2_4 = LevelCatalog.by_id("arcade_suzuki_2_4")
	assert_not_null(s2_4)
	assert_eq(s2_4.title, "O Pêndulo da Meia-Noite")
	assert_eq(s2_4.beacon_sound_id, "clock")
	assert_eq(s2_4.song_title, "Gavotte")

func test_suzuki_audio_beacons():
	var beacons := [
		"window_wind", "wrist_watch", "watering_can", "tea_cup",
		"cat_bell", "broom_sweep", "keys_jingle"
	]
	for b in beacons:
		var stream = AudioManager.get_beacon_stream(b)
		assert_not_null(stream, "Stream do farol %s não deve ser nulo" % b)
		assert_true(stream is AudioStreamWAV)
		assert_eq(stream.mix_rate, 44100)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
		assert_gt(stream.data.size(), 0, "Dados de áudio para %s não podem ser vazios" % b)

func test_suzuki_mobs_placement():
	var s1_2 = LevelCatalog.by_id("arcade_suzuki_1_2")
	assert_eq(s1_2.mobs_data.size(), 1)
	assert_eq(s1_2.mobs_data[0].get("type"), "cat")
	assert_eq(s1_2.mobs_data[0].get("grid"), Vector2i(6, 4))
	
	var s1_3 = LevelCatalog.by_id("arcade_suzuki_1_3")
	assert_eq(s1_3.mobs_data.size(), 1)
	assert_eq(s1_3.mobs_data[0].get("type"), "canary")
	assert_eq(s1_3.mobs_data[0].get("grid"), Vector2i(5, 3))
	
	var s2_1 = LevelCatalog.by_id("arcade_suzuki_2_1")
	assert_eq(s2_1.mobs_data.size(), 1)
	assert_eq(s2_1.mobs_data[0].get("type"), "cat")
	assert_eq(s2_1.mobs_data[0].get("grid"), Vector2i(6, 4))
	
	var s2_3 = LevelCatalog.by_id("arcade_suzuki_2_3")
	assert_eq(s2_3.mobs_data.size(), 1)
	assert_eq(s2_3.mobs_data[0].get("type"), "dog")
	assert_eq(s2_3.mobs_data[0].get("grid"), Vector2i(7, 3))

func test_canary_mob_properties_and_reactions():
	var canary = CanaryMobScript.new()
	add_child_autofree(canary)
	canary.setup(Vector2i(5, 3), "Piu-Piu")
	
	assert_eq(canary.grid_position, Vector2i(5, 3))
	assert_eq(canary.mob_name, "Piu-Piu")
	assert_eq(canary.idle_sound_id, "canary_sing")
	assert_eq(canary.alert_sound_id, "canary_flap")
	assert_true(canary.is_passable)
	assert_not_null(canary._sprite.texture, "Textura do canário deve carregar")
	
	watch_signals(canary)
	# Pulso distante (> 2 tiles)
	canary.on_tactile_pulse(Vector2.ZERO, Vector2i(1, 1))
	assert_signal_not_emitted(canary, "alerted")
	
	# Pulso próximo (distância <= 2 tiles)
	canary.on_tactile_pulse(Vector2.ZERO, Vector2i(5, 4))
	assert_signal_emitted(canary, "alerted")
	
	# Pisar no canário
	canary.on_player_moved(Vector2i(5, 3))
	assert_signal_emitted(canary, "stepped_on")

func test_canary_audio_streams():
	for s in ["canary_sing", "canary_flap"]:
		var stream = AudioManager.get_mob_stream(s)
		assert_not_null(stream, "Stream %s não deve ser nulo" % s)
		assert_gt(stream.data.size(), 0, "Stream %s deve conter amostras" % s)
		assert_eq(stream.mix_rate, int(AudioManager.MIX_RATE))

func test_suzuki_initial_unlocked_levels():
	assert_true(SaveManager.is_level_unlocked("arcade_suzuki_1_1"), "S1.1 deve estar desbloqueada inicialmente para estudo livre")
	assert_true(SaveManager.is_level_unlocked("arcade_suzuki_2_1"), "S2.1 deve estar desbloqueada inicialmente para estudo livre")
