extends GutTest
## Testes de validação das POCs do Caminho A (Godot 4):
## 1. Síntese Acústica por Modelagem Física (Piano de cauda com coro triplo/inarmonicidade,
##    Cello de Helmholtz + Ressonador Modal de Caixa de Madeira, e Violão Karplus-Strong).
## 2. Assets Procedurais 2.5D (Iso25DCanvas 2:1, Boneco Articulado ProceduralArthur25D com
##    giro contínuo em 360° no Scroll de Afinação e Móveis 2.5D ProceduralFurniture25D).

const AcousticSynthScript := preload("res://scripts/AcousticSynth.gd")
const Iso25DScript := preload("res://scripts/Iso25DCanvas.gd")
const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")
const ProceduralFurnitureScript := preload("res://scripts/ProceduralFurniture25D.gd")
const CharacterScene := preload("res://scenes/Character.tscn")
const PlaygroundScene := preload("res://scenes/Playground.tscn")


func after_each() -> void:
	AudioManager.set_instrument("piano")
	AudioManager._stop_current()


func test_audio_manager_supports_piano_cello_and_guitar_instruments() -> void:
	assert_eq(AudioManager.get_instrument(), "piano")

	for inst in ["piano", "cello", "guitar"]:
		AudioManager.set_instrument(inst)
		assert_eq(AudioManager.get_instrument(), inst)
		var player := AudioManager.play_note("A4", 0.35)
		assert_not_null(player, "Instrumento '%s' deve tocar A4 com sucesso" % inst)
		assert_true(player.stream is AudioStreamWAV)
		var wav: AudioStreamWAV = player.stream
		assert_gt(wav.data.size(), 0)


func test_invalid_instrument_is_ignored_and_preserves_current() -> void:
	AudioManager.set_instrument("cello")
	AudioManager.set_instrument("theremin_inexistente")
	assert_eq(AudioManager.get_instrument(), "cello")


func test_cello_body_resonator_bank_produces_warm_non_clipping_output() -> void:
	var body := AcousticSynthScript.BodyResonatorBank.new()
	var peak := 0.0
	var energy := 0.0
	for i in range(2000):
		var phase := fposmod(float(i) * (220.0 / 44100.0), 1.0)
		var raw := AcousticSynthScript.helmholtz_bowed_string(phase)
		var out := body.process(raw)
		assert_false(is_nan(out), "Saída do ressonador modal de madeira não pode ser NaN")
		peak = maxf(peak, absf(out))
		energy += out * out
	assert_gt(energy, 1.0, "Ressonador modal deve transmitir energia acústica real")
	assert_lt(peak, 0.99, "Ressonador modal de madeira nunca deve clipar")


func test_iso_25d_canvas_projects_exact_2_to_1_isometric_ratio() -> void:
	# Deslocamento puro em +X (Sul-Leste): dx = +10, dy = +5 -> razão 2:1
	var p_se := Iso25DScript.project(Vector3(10.0, 0.0, 0.0))
	assert_almost_eq(p_se.x, 10.0, 1e-4)
	assert_almost_eq(p_se.y, 5.0, 1e-4)
	assert_almost_eq(absf(p_se.x / p_se.y), 2.0, 1e-4)

	# Deslocamento puro em +Y (Sul-Oeste): dx = -10, dy = +5 -> razão 2:1
	var p_sw := Iso25DScript.project(Vector3(0.0, 10.0, 0.0))
	assert_almost_eq(p_sw.x, -10.0, 1e-4)
	assert_almost_eq(p_sw.y, 5.0, 1e-4)

	# Elevação vertical pura +Z: sobe na tela (-Y) sem desviar X
	var p_up := Iso25DScript.project(Vector3(0.0, 0.0, 16.0))
	assert_almost_eq(p_up.x, 0.0, 1e-4)
	assert_almost_eq(p_up.y, -16.0, 1e-4)


func test_character_has_procedural_25d_rig_and_rotates_continuously_on_tuning() -> void:
	var c = CharacterScene.instantiate()
	add_child_autofree(c)

	assert_not_null(c._procedural_rig, "Character deve instanciar o boneco ProceduralArthur25D")
	assert_true(c._procedural_rig is ProceduralArthurScript)

	# Simula varredura contínua de frequência no Scroll de Afinação (C4 -> F#4)
	c.set_tuning_sweep_frequency(261.63)
	var angle_c4: float = c._procedural_rig.target_facing_angle
	assert_true(c._procedural_rig.tuning_active)

	c.set_tuning_sweep_frequency(369.99)
	var angle_fs4: float = c._procedural_rig.target_facing_angle
	assert_ne(angle_c4, angle_fs4, "Mudar a frequência contínua no scroll deve girar o ângulo 360° do Sr. Arthur")

	c.clear_tuning_sweep()
	assert_false(c._procedural_rig.tuning_active)


func test_pitch_scroll_sweep_direction_matches_actual_walk_direction_for_all_movement_notes() -> void:
	var c = CharacterScene.instantiate()
	add_child_autofree(c)

	var movement_test_cases := [
		{ "note": "C4",  "freq": 261.63, "name": "Norte (↑)" },
		{ "note": "Cs4", "freq": 277.18, "name": "Nordeste (↗)" },
		{ "note": "D4",  "freq": 293.66, "name": "Leste (→)" },
		{ "note": "Ds4", "freq": 311.13, "name": "Sudeste (↘)" },
		{ "note": "E4",  "freq": 329.63, "name": "Sul (↓)" },
		{ "note": "F4",  "freq": 349.23, "name": "Sudoeste (↙)" },
		{ "note": "Fs4", "freq": 369.99, "name": "Oeste (←)" },
		{ "note": "G4",  "freq": 392.00, "name": "Noroeste (↖)" },
	]

	for tc in movement_test_cases:
		var note: String = tc["note"]
		var freq: float = tc["freq"]
		var dir := NoteMapping.direction_for(note)
		var expected_walk_angle := ProceduralArthurScript.angle_for_grid_direction(dir)

		# Aplica a frequência no rig como o PitchScrollInput faz durante o arraste
		c.set_tuning_sweep_frequency(freq)
		var actual_sweep_angle: float = c._procedural_rig.target_facing_angle
		var ang_diff: float = absf(angle_difference(actual_sweep_angle, expected_walk_angle))

		assert_lt(ang_diff, 0.05,
			"Modo Cello: Na nota %s (%s, %.1fHz), a direção apontada na afinação (%.2f rad) deve corresponder à caminhada (%.2f rad, diff=%.4f)" % [
				note, tc["name"], freq, actual_sweep_angle, expected_walk_angle, ang_diff
			])


func test_playground_attaches_procedural_25d_furniture_to_room_props() -> void:
	var pg = PlaygroundScene.instantiate()
	add_child_autofree(pg)

	var found_procedural_prop := false
	for child in pg._walls_node.get_children():
		for sub in child.get_children():
			if sub is ProceduralFurnitureScript:
				found_procedural_prop = true
				break
	assert_true(found_procedural_prop, "Quarto inicial deve conter móveis renderizados por ProceduralFurniture25D")
