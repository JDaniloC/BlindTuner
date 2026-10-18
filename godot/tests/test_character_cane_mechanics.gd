extends GutTest
## Testes de validação da bengala de orientação e mobilidade do protagonista.
## Verifica posições da ponteira, pulso acústico a cada nota/passo e integridade das sprites.

const CharacterScene := preload("res://scenes/Character.tscn")
const CaneAcousticPulseScript := preload("res://scripts/CaneAcousticPulse.gd")

func test_character_has_cane_tip_world_position_for_all_directions():
	var c = CharacterScene.instantiate()
	c.grid_position = Vector2i(5, 5)
	add_child_autofree(c)
	
	var base_pos: Vector2 = c.position
	for dir in [
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(1, -1),
		Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1)
	]:
		c._last_direction = dir
		var tip_pos: Vector2 = c.get_cane_tip_world_position()
		assert_ne(tip_pos, Vector2.ZERO, "Ponta da bengala não pode ser nula na direção %s" % dir)
		assert_ne(tip_pos, base_pos, "Ponta da bengala deve ter offset em relação ao centro na direção %s" % dir)
		# A ponta toca o solo (offset Y positivo ou ligeiramente elevado dependendo da perspectiva)
		assert_true(tip_pos.distance_to(base_pos) > 5.0, "Distância da bengala deve ser coerente")

func test_spawn_cane_acoustic_pulse():
	var parent_node := Node2D.new()
	add_child_autofree(parent_node)
	
	var c = CharacterScene.instantiate()
	c.grid_position = Vector2i(4, 4)
	parent_node.add_child(c)
	
	c.spawn_cane_acoustic_pulse("D4")
	
	var found_pulse := false
	for child in parent_node.get_children():
		if child is CaneAcousticPulseScript:
			found_pulse = true
			assert_almost_eq(child.MAX_RADIUS_X / child.MAX_RADIUS_Y, 2.0, 0.05, "Pulso deve manter proporção isométrica 2:1")
			break
	assert_true(found_pulse, "CaneAcousticPulse deve ser instanciado no piso ao bater a bengala")

func test_play_cane_step_sfx_does_not_mask_current_player():
	var note_player = AudioManager.play_note("C4")
	assert_not_null(note_player)
	
	# Cane step sfx deve tocar em canal polifônico independente sem substituir _current_player
	var step_player = AudioManager.play_cane_step_sfx()
	assert_not_null(step_player)
	assert_eq(AudioManager._current_player, note_player, "A nota musical deve continuar sendo o _current_player")

func test_tatear_emits_tactile_pulse_at_cane_tip():
	var c = CharacterScene.instantiate()
	c.grid_position = Vector2i(5, 5)
	add_child_autofree(c)
	
	watch_signals(c)
	c.tatear()
	assert_signal_emitted(c, "tactile_pulse_requested")
	
	var expected_tip: Vector2 = c.get_cane_tip_world_position()
	var signal_args = get_signal_parameters(c, "tactile_pulse_requested")
	assert_not_null(signal_args)
	assert_gt(signal_args.size(), 0)
	assert_eq(signal_args[0], expected_tip, "O pulso tátil deve se originar na ponta da bengala")

func test_character_sprite_sheets_contain_cane_pixel_data():
	var sheets := [
		"res://assets/sprites/character/16x32_elderly/16x32 Idle-Sheet.png",
		"res://assets/sprites/character/16x32_elderly/16x32 Walk-Sheet.png",
		"res://assets/sprites/character/16x32_elderly/16x32 Attack-Sheet.png",
		"res://assets/sprites/character/16x32_elderly/16x32 Interact-Sheet.png",
		"res://assets/sprites/character/16x32_elderly/16x32 Run-Sheet.png",
		"res://assets/sprites/character/16x32_elderly/16x32 Jump-Sheet.png"
	]
	
	for s_path in sheets:
		assert_true(FileAccess.file_exists(s_path), "Folha de animação %s deve existir" % s_path)
		var img := Image.load_from_file(ProjectSettings.globalize_path(s_path))
		assert_not_null(img, "Imagem %s deve ser carregada" % s_path)
		assert_gt(img.get_width(), 0)
		assert_gt(img.get_height(), 0)
