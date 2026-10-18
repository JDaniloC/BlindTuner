extends GutTest

const CharacterScene := preload("res://scenes/Character.tscn")
const PlaygroundScene := preload("res://scenes/Playground.tscn")
const TactileRippleScript := preload("res://scripts/TactileRipple.gd")
const AcousticFocusGuideScript := preload("res://scripts/AcousticFocusGuide.gd")

func test_character_tatear_emits_tactile_pulse_requested():
	var c = CharacterScene.instantiate()
	c.grid_position = Vector2i(4, 4)
	add_child_autofree(c)
	watch_signals(c)
	c.tatear()
	assert_signal_emitted(c, "tactile_pulse_requested")
	assert_signal_emitted(c, "action_performed")

func test_character_escutar_emits_listening_focus_requested():
	var c = CharacterScene.instantiate()
	c.grid_position = Vector2i(4, 4)
	add_child_autofree(c)
	watch_signals(c)
	c.escutar()
	assert_signal_emitted(c, "listening_focus_requested")
	assert_signal_emitted(c, "action_performed")

func test_handle_action_gs4_triggers_tactile_pulse():
	var c = CharacterScene.instantiate()
	c.grid_position = Vector2i(3, 3)
	add_child_autofree(c)
	watch_signals(c)
	c.handle_action("Gs4")
	assert_signal_emitted(c, "tactile_pulse_requested")

func test_handle_action_a4_triggers_listening_focus():
	var c = CharacterScene.instantiate()
	c.grid_position = Vector2i(3, 3)
	add_child_autofree(c)
	watch_signals(c)
	c.handle_action("A4")
	assert_signal_emitted(c, "listening_focus_requested")

func test_tactile_ripple_lifecycle():
	var ripple = TactileRippleScript.new()
	add_child_autofree(ripple)
	assert_not_null(ripple)
	assert_gt(ripple.MAX_RADIUS_X, 0.0)
	assert_gt(ripple.MAX_RADIUS_Y, 0.0)
	assert_almost_eq(ripple.MAX_RADIUS_X / ripple.MAX_RADIUS_Y, 2.0, 0.01, "proporção isométrica 2:1")

func test_acoustic_focus_guide_setup():
	var guide = AcousticFocusGuideScript.new()
	add_child_autofree(guide)
	var origin := Vector2(100, 100)
	var target := Vector2(300, 200)
	guide.setup(origin, target)
	assert_eq(guide.from_pos, origin)
	assert_eq(guide.to_pos, target)

func test_playground_tactile_pulse_spawns_ripple():
	var pg = PlaygroundScene.instantiate()
	add_child_autofree(pg)
	var char_node = pg.get_node("Character")
	var initial_child_count := pg.get_child_count()
	char_node.tatear()
	# TactileRipple deve ter sido adicionado como filho do playground
	var found_ripple := false
	for child in pg.get_children():
		if child is TactileRippleScript:
			found_ripple = true
			break
	assert_true(found_ripple, "TactileRipple deve ser instanciado no Playground ao tatear")

func test_playground_listening_focus_triggers_beacon_and_guide():
	var pg = PlaygroundScene.instantiate()
	add_child_autofree(pg)
	var char_node = pg.get_node("Character")
	var beacon = pg._goal_beacon
	if beacon != null:
		watch_signals(beacon)
	char_node.escutar()
	if beacon != null:
		assert_signal_emitted(beacon, "pulsed", "Beacon deve emitir pulso imediatamente ao focar escuta")
	var found_guide := false
	for child in pg.get_children():
		if child is AcousticFocusGuideScript:
			found_guide = true
			break
	assert_true(found_guide, "AcousticFocusGuide deve ser instanciado no Playground ao escutar")

func test_playground_instantiates_ambient_atmosphere_2d():
	var pg = PlaygroundScene.instantiate()
	add_child_autofree(pg)
	var floor_node = pg.get_node("Floor")
	var atmo = floor_node.get_node_or_null("AmbientAtmosphere2D")
	assert_not_null(atmo, "AmbientAtmosphere2D deve ser instanciado no Floor do Playground")
	assert_gt(atmo._particles.size(), 0, "AmbientAtmosphere2D deve gerar partículas pixel-art 2D")

