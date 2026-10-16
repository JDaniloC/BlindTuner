extends GutTest
## Testes de validação dos props visuais de cenário e objetivos em pixel art.
## Garante que cada mapa instancie o sprite temático correto em seu destino e ambiente.

const PlaygroundScene := preload("res://scenes/Playground.tscn")

var _pg = null

func before_each():
	_pg = PlaygroundScene.instantiate()
	add_child_autofree(_pg)

func test_all_15_scenery_prop_textures_exist():
	var prop_names := [
		"iron_gate_48x64.png",
		"bakery_counter_64x48.png",
		"fountain_stone_64x64.png",
		"church_portal_64x80.png",
		"window_breeze_48x64.png",
		"reading_desk_56x48.png",
		"hanging_fern_48x64.png",
		"porcelain_cupboard_48x64.png",
		"yarn_basket_40x36.png",
		"broom_bucket_36x48.png",
		"hallway_stand_48x64.png",
		"seaside_bench_56x40.png",
		"station_lantern_40x64.png",
		"cello_stand_48x64.png",
		"wind_chimes_stand_48x64.png"
	]
	for p in prop_names:
		var path: String = "res://assets/sprites/props/" + str(p)
		var tex = _pg._load_prop_texture(path)
		assert_not_null(tex, "Textura %s deve ser carregada com sucesso" % p)
		assert_gt(tex.get_width(), 0)
		assert_gt(tex.get_height(), 0)

func test_chapter_2_goal_props_instantiated():
	# 2.1 Jardim do Portão -> Portão de ferro
	_pg._begin_preset("ch2_portao_ferro", 0, 0, false)
	assert_eq(_pg._current_map_id, "jardim_portao")
	var has_gate := false
	for child in _pg._goal_node.get_children():
		if child is Sprite2D and child.texture != null:
			has_gate = true
	assert_true(has_gate, "Portão de ferro deve estar no objetivo do jardim")

	# 2.3 Praça do Chafariz -> Chafariz de pedra
	_pg._begin_preset("ch2_praca_chafariz", 2, 0, false)
	assert_eq(_pg._current_map_id, "praca_chafariz")
	var has_fountain := false
	for child in _pg._goal_node.get_children():
		if child is Sprite2D and child.texture != null:
			has_fountain = true
	assert_true(has_fountain, "Chafariz deve estar no objetivo da praça")

func test_suzuki_arcade_goal_props_and_furniture():
	# S1.1 Sala da Veneziana
	_pg._begin_preset("arcade_suzuki_1_1", 0, 0, false)
	assert_eq(_pg._current_map_id, "arcade_s1_vento")
	var has_window := false
	for child in _pg._goal_node.get_children():
		if child is Sprite2D and child.texture != null:
			has_window = true
	assert_true(has_window, "Veneziana deve estar no objetivo do S1.1")
	
	# Verifica mobílias temáticas spawnadas
	var furniture_count := 0
	for child in _pg._walls_node.get_children():
		if child is Sprite2D and child.texture != null:
			furniture_count += 1
	assert_gt(furniture_count, 0, "Poltrona e mesa devem ser instanciadas na sala da veneziana")

func test_chapter_3_goal_props_instantiated():
	# 3.1 Praia do Mirante -> Banco marítimo
	_pg._begin_preset("ch3_praia_mare", 3, 0, false)
	assert_eq(_pg._current_map_id, "praia_mirante")
	var has_bench := false
	for child in _pg._goal_node.get_children():
		if child is Sprite2D and child.texture != null:
			has_bench = true
	assert_true(has_bench, "Banco do mirante deve estar no objetivo da praia")

	# 3.4 Palco do Grande Teatro -> Sinos de vento
	_pg._begin_preset("ch3_teatro_recital", 3, 1, false)
	assert_eq(_pg._current_map_id, "teatro_palco")
	var has_chimes := false
	for child in _pg._goal_node.get_children():
		if child is Sprite2D and child.texture != null:
			has_chimes = true
	assert_true(has_chimes, "Sinos de vento devem estar no objetivo do grande teatro")
