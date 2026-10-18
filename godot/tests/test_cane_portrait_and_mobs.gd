extends GutTest
## Testes para validação da reação acústica do Retrato (Ponto 2)
## e reações dos pets, pedestres e veículos lentos ao ritmo dos passos da bengala (Ponto 3).

const CharacterPortraitScene := preload("res://scenes/CharacterPortrait.tscn")
const CharacterScene := preload("res://scenes/Character.tscn")
const CatMobScript := preload("res://scripts/mobs/CatMob.gd")
const DogMobScript := preload("res://scripts/mobs/DogMob.gd")
const CanaryMobScript := preload("res://scripts/mobs/CanaryMob.gd")
const PigeonMobScript := preload("res://scripts/mobs/PigeonMob.gd")
const PedestrianMobScript := preload("res://scripts/mobs/PedestrianMob.gd")
const PostmanMobScript := preload("res://scripts/mobs/PostmanMob.gd")
const BakerMobScript := preload("res://scripts/mobs/BakerMob.gd")
const BaseMobScript := preload("res://scripts/mobs/BaseMob.gd")

# ==============================================================================
# PONTO 2: REAÇÃO DO RETRATO DE PERSONAGEM
# ==============================================================================

func test_portrait_on_cane_tap_executes_and_preserves_state():
	var portrait: Control = CharacterPortraitScene.instantiate()
	add_child_autofree(portrait)
	
	portrait.set_state(portrait.State.IDLE)
	assert_eq(portrait.current_state, portrait.State.IDLE)
	
	portrait.on_cane_tap(Color(0.2, 0.6, 1.0))
	assert_eq(portrait.current_state, portrait.State.IDLE, "O estado persistente deve ser mantido durante o pulso da bengala")

func test_portrait_on_cane_tap_does_not_override_bump():
	var portrait: Control = CharacterPortraitScene.instantiate()
	add_child_autofree(portrait)
	
	portrait.set_state(portrait.State.BUMP)
	portrait.on_cane_tap(Color(1.0, 1.0, 0.0))
	assert_eq(portrait.current_state, portrait.State.BUMP, "A dor do tropeço/colisão não deve ser cancelada pela batida da bengala")

func test_character_emits_cane_tapped_signal_on_pulse():
	var character: Node2D = CharacterScene.instantiate()
	var parent_node := Node2D.new()
	add_child_autofree(parent_node)
	parent_node.add_child(character)
	
	watch_signals(character)
	character.spawn_cane_acoustic_pulse("E4")
	assert_signal_emitted(character, "cane_tapped")
	
	var params = get_signal_parameters(character, "cane_tapped")
	assert_not_null(params)
	assert_eq(params.size(), 2)
	assert_eq(params[1], "E4", "A nota informada deve ser propagada no sinal cane_tapped")

# ==============================================================================
# PONTO 3: REAÇÕES SONORAS E RÍTMICAS DOS MOBS / PETS / PEDESTRES À BENGALA
# ==============================================================================

func test_base_mob_cadence_detection():
	var mob: Node2D = BaseMobScript.new()
	add_child_autofree(mob)
	
	assert_false(mob.is_rhythmic_cadence(), "Sem histórico de toques, não há cadência")
	
	var t0: int = Time.get_ticks_msec()
	mob.set_cane_tap_history([t0 - 600, t0 - 300, t0])
	assert_true(mob.is_rhythmic_cadence(), "Intervalos regulares de 300ms devem ser identificados como cadência de passos")
	
	mob.set_cane_tap_history([t0 - 1800, t0 - 200])
	assert_false(mob.is_rhythmic_cadence(), "Intervalos distantes (> 1400ms) não são passos contínuos")

func test_mobs_emit_cane_heard_when_in_range():
	var cat: Node2D = CatMobScript.new()
	cat.grid_position = Vector2i(4, 4)
	add_child_autofree(cat)
	
	watch_signals(cat)
	var cane_pos: Vector2 = cat.position + Vector2(20.0, 10.0)
	cat.on_cane_tap(cane_pos, "C4")
	assert_signal_emitted(cat, "cane_heard")

func test_dog_mob_reactions():
	var dog: Node2D = DogMobScript.new()
	dog.grid_position = Vector2i(5, 5)
	add_child_autofree(dog)
	
	watch_signals(dog)
	dog.set_cane_tap_history([Time.get_ticks_msec() - 300, Time.get_ticks_msec()])
	var cane_pos: Vector2 = dog.position + Vector2(15.0, 15.0)
	dog.on_cane_tap(cane_pos, "D4")
	assert_signal_emitted(dog, "cane_heard")

func test_canary_mob_reactions():
	var canary: Node2D = CanaryMobScript.new()
	canary.grid_position = Vector2i(3, 3)
	add_child_autofree(canary)
	
	watch_signals(canary)
	var cane_pos: Vector2 = canary.position + Vector2(30.0, 20.0)
	canary.on_cane_tap(cane_pos, "G4")
	assert_signal_emitted(canary, "cane_heard")

func test_pigeon_mob_reactions():
	var pigeon: Node2D = PigeonMobScript.new()
	pigeon.grid_position = Vector2i(6, 6)
	add_child_autofree(pigeon)
	
	watch_signals(pigeon)
	var cane_pos: Vector2 = pigeon.position + Vector2(60.0, 40.0)
	pigeon.on_cane_tap(cane_pos, "A4")
	assert_signal_emitted(pigeon, "cane_heard")

func test_pedestrian_mob_dona_rosa():
	var rosa: Node2D = PedestrianMobScript.new()
	rosa.grid_position = Vector2i(5, 3)
	add_child_autofree(rosa)
	
	assert_eq(rosa.mob_name, "Dona Rosa")
	assert_eq(rosa.alert_sound_id, "pedestrian_greeting")
	assert_false(rosa.is_stepping_aside())
	
	watch_signals(rosa)
	var cane_pos: Vector2 = rosa.position + Vector2(10.0, 10.0)
	rosa.on_cane_tap(cane_pos, "D4")
	assert_signal_emitted(rosa, "cane_heard")
	assert_true(rosa.is_stepping_aside(), "Dona Rosa deve dar um passo cortês para liberar a calçada")

func test_postman_mob_tiago_bike():
	var postman: Node2D = PostmanMobScript.new()
	postman.grid_position = Vector2i(3, 4)
	add_child_autofree(postman)
	
	assert_eq(postman.mob_name, "Tiago o Carteiro")
	assert_eq(postman.idle_sound_id, "postman_bell")
	assert_false(postman.is_stepping_aside())
	
	watch_signals(postman)
	var cane_pos: Vector2 = postman.position + Vector2(15.0, 10.0)
	postman.on_cane_tap(cane_pos, "D4")
	assert_signal_emitted(postman, "cane_heard")
	assert_true(postman.is_stepping_aside(), "O carteiro deve encostar a bicicleta cortês para abrir passagem")

func test_baker_mob_seu_alberto():
	var baker: Node2D = BakerMobScript.new()
	baker.grid_position = Vector2i(7, 3)
	add_child_autofree(baker)
	
	assert_eq(baker.mob_name, "Seu Alberto o Padeiro")
	assert_eq(baker.alert_sound_id, "baker_greeting")
	assert_false(baker.is_stepping_aside())
	
	watch_signals(baker)
	var cane_pos: Vector2 = baker.position + Vector2(12.0, 8.0)
	baker.on_cane_tap(cane_pos, "E4")
	assert_signal_emitted(baker, "cane_heard")
	assert_true(baker.is_stepping_aside(), "O padeiro deve recuar cortês com a tábua de pães")

func test_audio_manager_new_mob_streams():
	var stream_ped = AudioManager.get_mob_stream("pedestrian_greeting")
	assert_not_null(stream_ped)
	assert_true(stream_ped is AudioStreamWAV)
	assert_gt(stream_ped.data.size(), 0)

	var stream_bell = AudioManager.get_mob_stream("postman_bell")
	assert_not_null(stream_bell)
	assert_true(stream_bell is AudioStreamWAV)
	assert_gt(stream_bell.data.size(), 0)

	var stream_baker = AudioManager.get_mob_stream("baker_greeting")
	assert_not_null(stream_baker)
	assert_true(stream_baker is AudioStreamWAV)
	assert_gt(stream_baker.data.size(), 0)

func test_level_catalog_neighborhood_mobs_registered():
	var lvl_2_1: Resource = LevelCatalog.by_id("ch2_portao_ferro")
	assert_not_null(lvl_2_1)
	assert_gte(lvl_2_1.mobs_data.size(), 2)
	assert_eq(lvl_2_1.mobs_data[0].get("type"), "dog")
	assert_eq(lvl_2_1.mobs_data[1].get("type"), "postman")

	var lvl_2_2: Resource = LevelCatalog.by_id("ch2_pao_esquina")
	assert_not_null(lvl_2_2)
	assert_gte(lvl_2_2.mobs_data.size(), 2)
	assert_eq(lvl_2_2.mobs_data[0].get("type"), "pedestrian")
	assert_eq(lvl_2_2.mobs_data[1].get("type"), "baker")

	var lvl_s3_1: Resource = LevelCatalog.by_id("arcade_suzuki_3_1")
	assert_not_null(lvl_s3_1)
	assert_gte(lvl_s3_1.mobs_data.size(), 2)
	assert_eq(lvl_s3_1.mobs_data[0].get("type"), "postman")
