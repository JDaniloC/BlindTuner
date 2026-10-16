extends GutTest

const BaseMobScript := preload("res://scripts/mobs/BaseMob.gd")
const CatMobScript := preload("res://scripts/mobs/CatMob.gd")
const DogMobScript := preload("res://scripts/mobs/DogMob.gd")
const PigeonMobScript := preload("res://scripts/mobs/PigeonMob.gd")

func test_base_mob_instantiation():
	var mob = BaseMobScript.new()
	add_child_autofree(mob)
	mob.setup(Vector2i(3, 4), "Teste")
	assert_eq(mob.grid_position, Vector2i(3, 4))
	assert_eq(mob.mob_name, "Teste")
	assert_not_null(mob._audio_player)
	assert_not_null(mob._idle_timer)
	assert_not_null(mob._sprite)

func test_cat_mob_properties():
	var cat = CatMobScript.new()
	add_child_autofree(cat)
	assert_eq(cat.mob_name, "Mimi")
	assert_eq(cat.idle_sound_id, "cat_purr")
	assert_eq(cat.alert_sound_id, "cat_meow")
	assert_true(cat.is_passable)
	assert_not_null(cat._sprite.texture)

func test_dog_mob_properties():
	var dog = DogMobScript.new()
	add_child_autofree(dog)
	assert_eq(dog.mob_name, "Thor")
	assert_eq(dog.idle_sound_id, "dog_pant")
	assert_eq(dog.alert_sound_id, "dog_bark")
	assert_true(dog.is_passable)
	assert_not_null(dog._sprite.texture)

func test_pigeon_mob_properties():
	var pigeon = PigeonMobScript.new()
	add_child_autofree(pigeon)
	assert_eq(pigeon.mob_name, "Pombo da Praça")
	assert_eq(pigeon.idle_sound_id, "pigeon_coo")
	assert_eq(pigeon.alert_sound_id, "pigeon_flutter")
	assert_true(pigeon.is_passable)
	assert_not_null(pigeon._sprite.texture)

func test_audio_manager_mob_streams():
	var sounds := ["cat_purr", "cat_meow", "dog_pant", "dog_bark", "pigeon_coo", "pigeon_flutter"]
	for s in sounds:
		var stream = AudioManager.get_mob_stream(s)
		assert_not_null(stream, "Stream para %s não deve ser nulo" % s)
		assert_gt(stream.data.size(), 0, "Stream para %s deve conter dados de áudio" % s)
		assert_eq(stream.mix_rate, int(AudioManager.MIX_RATE))

func test_audio_manager_chapter_2_beacons():
	var beacons := ["gate_latch", "shop_bell", "fountain_birds", "church_bell"]
	for b in beacons:
		var stream = AudioManager.get_beacon_stream(b)
		assert_not_null(stream, "Farol sonoro %s não deve ser nulo" % b)
		assert_gt(stream.data.size(), 0, "Farol sonoro %s deve conter dados" % b)

func test_tactile_pulse_alerts_nearby_mob():
	var cat = CatMobScript.new()
	add_child_autofree(cat)
	cat.setup(Vector2i(5, 5), "Mimi")
	watch_signals(cat)
	
	# Pulso distante (> 2 tiles) não deve alertar
	cat.on_tactile_pulse(Vector2.ZERO, Vector2i(1, 1))
	assert_signal_not_emitted(cat, "alerted")
	
	# Pulso próximo (distância <= 2 tiles) deve emitir sinal alerted
	cat.on_tactile_pulse(Vector2.ZERO, Vector2i(4, 5))
	assert_signal_emitted(cat, "alerted")

func test_stepping_on_mob_triggers_signals():
	var dog = DogMobScript.new()
	add_child_autofree(dog)
	dog.setup(Vector2i(3, 3), "Thor")
	watch_signals(dog)
	
	dog.on_player_moved(Vector2i(3, 3))
	assert_signal_emitted(dog, "stepped_on")
	assert_signal_emitted(dog, "alerted")

func test_catalog_levels_contain_mobs():
	var lvl_1_2 = LevelCatalog.by_id("ch1_lullaby_dormir")
	assert_not_null(lvl_1_2)
	assert_gt(lvl_1_2.mobs_data.size(), 0, "1.2 deve ter o gato Mimi")
	assert_eq(lvl_1_2.mobs_data[0].get("type"), "cat")
	
	var lvl_2_1 = LevelCatalog.by_id("ch2_portao_ferro")
	assert_not_null(lvl_2_1)
	assert_gt(lvl_2_1.mobs_data.size(), 0, "2.1 deve ter o cão Thor")
	assert_eq(lvl_2_1.mobs_data[0].get("type"), "dog")
	
	var lvl_2_3 = LevelCatalog.by_id("ch2_praca_chafariz")
	assert_not_null(lvl_2_3)
	assert_gt(lvl_2_3.mobs_data.size(), 0, "2.3 deve ter pombos")
	assert_eq(lvl_2_3.mobs_data[0].get("type"), "pigeon")
