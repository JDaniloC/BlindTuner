extends Node2D
## Cena raiz. Chão/paredes procedurais + loop de jogo (Conductor + GameHUD).

const COLOR_SCREEN_SCENE := preload("res://scenes/ColorSchemeScreen.tscn")
const PAUSE_MODAL_SCENE := preload("res://scenes/PauseModal.tscn")
const VICTORY_MODAL_SCENE := preload("res://scenes/VictoryModal.tscn")
const STORY_INTRO_MODAL_SCENE := preload("res://scenes/StoryIntroModal.tscn")
const GOAL_AUDIO_BEACON_SCENE := preload("res://scenes/GoalAudioBeacon.tscn")
const VISION_OVERLAY_SCENE := preload("res://scenes/VisionImpairmentOverlay.tscn")
const TactileRippleScript := preload("res://scripts/TactileRipple.gd")
const AcousticFocusGuideScript := preload("res://scripts/AcousticFocusGuide.gd")
const CharacterPortraitScript := preload("res://scripts/CharacterPortrait.gd")
const FLOOR_WOOD_OAK_A := preload("res://assets/sprites/tilemap/floor_wood_oak_a.png")
const FLOOR_WOOD_OAK_B := preload("res://assets/sprites/tilemap/floor_wood_oak_b.png")
const WALL_WOOD_QUARTO := preload("res://assets/sprites/tilemap/wall_wood_quarto.png")
const RADIO_PROP := preload("res://assets/sprites/props/radio_vintage_48x48.png")
const BED_PROP := preload("res://assets/sprites/furniture/bed_elderly_96x80.png")
const NIGHTSTAND_PROP := preload("res://assets/sprites/furniture/nightstand_lamp_48x64.png")
const SLIPPERS_PROP := preload("res://assets/sprites/obstacles/slippers_floor_36x32.png")
const SINK_PROP := preload("res://assets/sprites/furniture/sink_bathroom_48x48.png")
const TOILET_PROP := preload("res://assets/sprites/furniture/toilet_retro_32x48.png")
const BATHTUB_PROP := preload("res://assets/sprites/furniture/bathtub_retro_80x64.png")
const BATH_MAT_PROP := preload("res://assets/sprites/obstacles/bath_mat_48x32.png")
const CLOCK_PROP := preload("res://assets/sprites/furniture/clock_grandfather_32x80.png")
const COFFEE_TABLE_PROP := preload("res://assets/sprites/furniture/coffee_table_64x48.png")
const ARMCHAIR_PROP := preload("res://assets/sprites/furniture/armchair_cozy_64x64.png")
const DRESSER_PROP := preload("res://assets/sprites/furniture/dresser_wood_96x80.png")
const RUG_FOLDED_PROP := preload("res://assets/sprites/obstacles/rug_folded_80x44.png")

var _color_screen: Control = null
var _pause_modal: Control = null
var _victory_modal: Control = null
var _story_intro_modal: Control = null
var _goal_beacon: Node2D = null
var _goal_diamond_marker: Polygon2D = null
var _vision_overlay: CanvasLayer = null

@onready var _character: Node2D = $Character
@onready var _joystick: Control = $UI/DirectionJoystick
@onready var _character_portrait: Control = $UI/CharacterPortrait
@onready var _note_panel: PanelContainer = $UI/NotePanel
@onready var _floor_node: Node2D = $Floor
@onready var _walls_node: Node2D = $Walls
@onready var _camera: Camera2D = $Camera2D
@onready var _screen_flash: ColorRect = $UI/ScreenFlash
@onready var _conductor: Node = $Conductor
@onready var _hud: Control = $UI/GameHUD
@onready var _special_actions: Control = $UI/SpecialActionPanel
@onready var _piano_input: Control = $UI/PianoInput
@onready var _pitch_scroll_input: Control = $UI/PitchScrollInput
@onready var _goal_node: Node2D = $Goal
var _current_map_id: String = ""
var _last_triggered_note: String = ""
var _joystick_default_filter: int
var _special_actions_default_filter: int
var _piano_input_default_filter: int
var _pitch_scroll_input_default_filter: int

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const WALL_HEIGHT := 32

const SHAKE_INTENSITY := 8.0
const SHAKE_DURATION := 0.25
const FLASH_PEAK_ALPHA := 0.45
const FLASH_DURATION := 0.18
# Atrasa o SFX de colisão para não mascarar a nota tocada pelo jogador.
# A nota dura NOTE_DURATION_SEC=0.6s; 0.5s deixa o pitch ser percebido antes do "erro".
const COLLISION_SFX_DELAY := 0.5

## Deslocamento vertical da câmera para centralizar a visão do personagem na janela
## útil da sala isométrica (entre a barra superior Y=252 e os controles da base Y=889).
## Em zoom 1.6x, 42px no mundo correspondem a ~67px na tela (640 - 67 = 573px,
## o centro exato da janela desobstruída).
const CAMERA_VIEWPORT_OFFSET_Y := 42.0

var _wall_tiles: Dictionary = {}
var _shake_remaining := 0.0
var _flash_tween: Tween

func _ready() -> void:
	_joystick_default_filter = _joystick.mouse_filter
	_special_actions_default_filter = _special_actions.mouse_filter
	_piano_input_default_filter = _piano_input.mouse_filter
	_pitch_scroll_input_default_filter = _pitch_scroll_input.mouse_filter
	# Sala inicial = primeiro mapa (quarto). Será re-buildada se o usuário
	# selecionar outro preset com map_id diferente.
	var first_map = MapPresets.ALL[0]
	_current_map_id = first_map.id
	_build_room()
	_character.grid_position = first_map.start_grid
	_character.blocked_tiles = _wall_tiles
	_character.position = _character.grid_to_world(first_map.start_grid)
	_camera.position = _character.position + Vector2(0.0, CAMERA_VIEWPORT_OFFSET_Y)
	_character.blocked.connect(_on_character_blocked)
	_character.trip_state_changed.connect(_on_character_trip_state_changed)
	_character.armed_state_changed.connect(_special_actions.on_armed_state_changed)
	_character.armed_state_changed.connect(_piano_input.on_armed_state_changed)
	_character.tactile_pulse_requested.connect(_on_tactile_pulse_requested)
	_character.listening_focus_requested.connect(_on_listening_focus_requested)
	_joystick.note_triggered.connect(_on_note_triggered)
	_special_actions.note_triggered.connect(_on_note_triggered)
	_piano_input.note_triggered.connect(_on_note_triggered)
	_pitch_scroll_input.note_triggered.connect(_on_note_triggered)
	_conductor.preview_note.connect(_on_preview_note)
	_conductor.call_cue.connect(_on_call_cue)
	_conductor.replay_note.connect(_on_replay_note)
	_conductor.note_resolved.connect(_on_note_resolved)
	_conductor.phase_changed.connect(_on_phase_changed)
	_conductor.sequence_complete.connect(_on_sequence_complete)
	_hud.start_requested.connect(_on_start_requested)
	_hud.restart_requested.connect(_on_restart_requested)
	_hud.color_settings_requested.connect(_on_color_settings_requested)
	_hud.pause_requested.connect(_on_pause_requested)
	_note_panel.replay_cue_requested.connect(_on_replay_cue_requested)
	# O NotePanel estava fixado em offset_top=140 no .tscn, e a barra do topo
	# passou de ~134 para 150px quando "Cores" ganhou uma segunda linha: o painel
	# opaco do HUD (irmão posterior na CanvasLayer) passou a desenhar 10px por
	# cima do chip de pista. Posicionar pela altura MEDIDA da barra também
	# sobrevive a um aumento de fonte por acessibilidade.
	_hud.top_bar_resized.connect(_place_note_panel_below_hud)
	_place_note_panel_below_hud()
	# Garante a invariante de _apply_input_mode() (só um grupo visível+clicável)
	# desde o frame zero, em vez de depender "por coincidência" dos defaults do
	# .tscn até a 1ª chamada de _begin_preset().
	_apply_input_mode()

	_vision_overlay = VISION_OVERLAY_SCENE.instantiate()
	add_child(_vision_overlay)

	# Se for nível da campanha, inicia automaticamente com HUD limpo e dificuldade do nível!
	if not LevelManager.is_sandbox:
		var lvl = LevelManager.get_current_level()
		if lvl != null:
			_hud.set_campaign_mode(lvl.title)
			_vision_overlay.setup_from_level_data(lvl)
			_begin_preset(lvl.id, lvl.default_cue_level, lvl.default_input_mode, false)
			_show_story_intro_modal(lvl)
	else:
		_hud.set_sandbox_mode()
		_vision_overlay.set_parameters(0.0, 1.2, 0.0, 0.0)

func _show_story_intro_modal(lvl_data) -> void:
	if _story_intro_modal != null and is_instance_valid(_story_intro_modal):
		_story_intro_modal.queue_free()
	_story_intro_modal = STORY_INTRO_MODAL_SCENE.instantiate()
	$UI.add_child(_story_intro_modal)
	_story_intro_modal.setup(lvl_data)
	_story_intro_modal.started.connect(func():
		_story_intro_modal = null
		if _conductor != null:
			_conductor.start()
	)

## Folga entre a barra do topo e o NotePanel. Preserva a altura autorada no
## .tscn, só desloca o painel para baixo do HUD.
const NOTE_PANEL_GAP := 8.0

func _place_note_panel_below_hud() -> void:
	var top_y: float = _hud.top_bar_height() + NOTE_PANEL_GAP
	var altura := _note_panel.offset_bottom - _note_panel.offset_top
	_note_panel.offset_top = top_y
	_note_panel.offset_bottom = top_y + altura
	if _character_portrait != null:
		var port_altura := _character_portrait.offset_bottom - _character_portrait.offset_top
		_character_portrait.offset_top = top_y
		_character_portrait.offset_bottom = top_y + port_altura

func _on_start_requested(preset_id: String, cue_level: int, input_mode: int) -> void:
	_begin_preset(preset_id, cue_level, input_mode)

## Abre a tela de paleta por cima do jogo. Uma instância por vez -- abrir duas
## deixaria dois seletores disputando o mesmo esquema ativo.
func _on_color_settings_requested() -> void:
	if _color_screen != null and is_instance_valid(_color_screen):
		return
	_color_screen = COLOR_SCREEN_SCENE.instantiate()
	$UI.add_child(_color_screen)

func _on_restart_requested() -> void:
	if _conductor._preset != null:
		_begin_preset(_conductor._preset.id, CueSettings.cue_level, InputModeSettings.mode)

func _begin_preset(preset_id: String, cue_level: int, input_mode: int = InputModeSettings.Mode.JOYSTICK, start_conductor: bool = true) -> void:
	var preset = LevelCatalog.by_id(preset_id)
	if preset == null:
		preset = SequencePresets.by_id(preset_id)
	if preset == null:
		return
	if _vision_overlay != null:
		_vision_overlay.setup_from_level_data(preset)
	var map = MapPresets.by_id(preset.map_id)
	CueSettings.set_level(cue_level)
	InputModeSettings.set_mode(input_mode)
	_apply_input_mode()
	_hud.hide_stats()
	if _character_portrait != null:
		_character_portrait.reset()
	_note_panel.clear_guide()
	_conductor.load_preset(preset)
	if _current_map_id != map.id:
		_current_map_id = map.id
		_build_room()
	elif _goal_beacon != null and is_instance_valid(_goal_beacon):
		var beacon_s = str(preset.get("beacon_sound_id"))
		if not beacon_s.is_empty():
			_goal_beacon.setup(beacon_s)
			_goal_beacon.start()
	_apply_level_visual_cues(preset)
	_character.reset()
	_character.grid_position = map.start_grid
	_character.blocked_tiles = _wall_tiles
	_character.position = _character.grid_to_world(map.start_grid)
	_camera.position = _character.position + Vector2(0.0, CAMERA_VIEWPORT_OFFSET_Y)
	if start_conductor:
		_conductor.start()
	_hud.set_progress(0, preset.notes.size())

func _apply_level_visual_cues(preset: Resource) -> void:
	if preset == null:
		return
	var show_fl: bool = bool(preset.get("show_floor")) if preset.get("show_floor") != null else true
	_floor_node.visible = show_fl

	var show_cues: bool = bool(preset.get("show_visual_cues")) if preset.get("show_visual_cues") != null else true
	if _goal_diamond_marker != null and is_instance_valid(_goal_diamond_marker):
		_goal_diamond_marker.visible = show_cues

func _apply_input_mode() -> void:
	var joystick_active := InputModeSettings.mode == InputModeSettings.Mode.JOYSTICK
	_joystick.visible = joystick_active
	_joystick.mouse_filter = _joystick_default_filter if joystick_active else Control.MOUSE_FILTER_IGNORE
	_special_actions.visible = joystick_active
	_special_actions.mouse_filter = _special_actions_default_filter if joystick_active else Control.MOUSE_FILTER_IGNORE

	var piano_active := InputModeSettings.mode == InputModeSettings.Mode.PIANO
	_piano_input.visible = piano_active
	_piano_input.mouse_filter = _piano_input_default_filter if piano_active else Control.MOUSE_FILTER_IGNORE

	var pitch_scroll_active := InputModeSettings.mode == InputModeSettings.Mode.PITCH_SCROLL
	_pitch_scroll_input.visible = pitch_scroll_active
	_pitch_scroll_input.mouse_filter = _pitch_scroll_input_default_filter if pitch_scroll_active else Control.MOUSE_FILTER_IGNORE
	if not pitch_scroll_active:
		# Sair do modo Scroll de Afinação com o tom ainda soando (dedo levantado
		# fora do slider, ou troca de modo via HUD a meio-arrasto) não deve deixar
		# o tom contínuo tocando pra sempre. stop_continuous_pitch() já é no-op
		# seguro se nada estiver tocando.
		AudioManager.stop_continuous_pitch()

func _on_preview_note(note_key: String, _index: int) -> void:
	# PREVIEW: só ouvir, personagem não se move.
	AudioManager.play_note(note_key)
	_note_panel.display_note(note_key)
	if _character_portrait != null:
		_character_portrait.trigger_reaction(CharacterPortraitScript.State.LISTENING, 0.7)

func _on_call_cue(note_key: String, index: int) -> void:
	# Toca o alvo + mostra a pista (conforme CueSettings, via NotePanel).
	AudioManager.play_note(note_key)
	_note_panel.display_note(note_key)
	_hud.set_progress(index, _conductor._preset.notes.size())
	if _character_portrait != null:
		_character_portrait.trigger_reaction(CharacterPortraitScript.State.LISTENING, 0.8)

func _on_replay_note(note_key: String, index: int) -> void:
	# REPLAY: o personagem "toca" e (se movement) anda o caminho canônico do preset.
	AudioManager.play_note(note_key)
	if NoteMapping.is_action_note(note_key):
		_character.handle_action(note_key)
	else:
		_character._try_walk(NoteMapping.direction_for(note_key))
	_hud.set_progress(index, _conductor._preset.notes.size())

func _on_phase_changed(phase: int) -> void:
	if _goal_beacon != null and is_instance_valid(_goal_beacon):
		var is_ducked: bool = (phase == _conductor.Phase.PREVIEW or phase == _conductor.Phase.CALL)
		_goal_beacon.set_ducking(is_ducked)
	# Ao entrar no REPLAY, reposiciona o personagem no início do preset.
	if phase == _conductor.Phase.REPLAY:
		var preset = _conductor._preset
		var sg: Vector2i = MapPresets.by_id(preset.map_id).start_grid
		_character.grid_position = sg
		_character.position = _character.grid_to_world(sg)
	# Modulação visual dos controles por fase (dim em PREVIEW/REPLAY)
	if phase == _conductor.Phase.PREVIEW or phase == _conductor.Phase.REPLAY:
		_set_controls_alpha(0.65)
	elif phase == _conductor.Phase.CALL or phase == _conductor.Phase.IDLE:
		_set_controls_alpha(1.0)
	if _hud != null:
		_hud.set_phase(phase)

func _on_character_trip_state_changed(is_tripping: bool) -> void:
	var alpha: float = 0.55 if is_tripping else 1.0
	_set_controls_alpha(alpha)

func _set_controls_alpha(alpha: float) -> void:
	if _joystick != null:
		_joystick.modulate.a = alpha
	if _special_actions != null:
		_special_actions.modulate.a = alpha
	if _piano_input != null:
		_piano_input.modulate.a = alpha
	if _pitch_scroll_input != null:
		_pitch_scroll_input.modulate.a = alpha

func _on_note_triggered(note_key: String) -> void:
	if _character != null and _character.is_tripping():
		AudioManager.play_trip_blocked_sfx()
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(25)
		return
	_last_triggered_note = note_key
	match _conductor.phase:
		_conductor.Phase.IDLE:
			# Modo livre: anda de verdade (Character.handle_note trata
			# nota de movimento, double-tap e colisão de parede) + toca a nota.
			AudioManager.play_note(note_key)
			_note_panel.display_note(note_key)
			_character.handle_note(note_key)
		_conductor.Phase.CALL:
			AudioManager.play_note(note_key)
			_note_panel.display_note(note_key)
			_conductor.submit_note(note_key)
		_:
			# PREVIEW/REPLAY/DONE: feedback sonoro imediato sem dead click silencioso
			AudioManager.play_trip_blocked_sfx()

func _on_replay_cue_requested() -> void:
	if _conductor != null and _conductor.phase == _conductor.Phase.CALL:
		_conductor.replay_current_cue()

func _on_note_resolved(hit: bool, index: int) -> void:
	if _character_portrait != null:
		if hit:
			_character_portrait.on_note_hit()
		else:
			_character_portrait.on_note_miss()
	var note_key: String = _conductor._preset.notes[index]
	if hit:
		_note_panel.clear_guide()
	else:
		_note_panel.display_miss(_last_triggered_note, note_key)
	if NoteMapping.is_action_note(note_key):
		# Acerto numa ação: dispara a ação; erro: tropeço com a última direção.
		if hit:
			_character.handle_action(note_key)
		else:
			_character._enter_trip(_character._last_direction, _character.TripReason.NOTE_MISS)
		return
	var dir: Vector2i = NoteMapping.direction_for(note_key)
	if hit:
		# Preset validado contra _wall_tiles; _try_walk não deveria tropeçar.
		# Se tropeçar (preset com bug), Conductor já avançou _index — dessincronia visual.
		_character._try_walk(dir)
	else:
		# Erro de conhecimento: tropeço no lugar (cosmético, sem dano).
		_character._enter_trip(dir, _character.TripReason.NOTE_MISS)

func _goal_reached() -> bool:
	var map = MapPresets.by_id(_current_map_id)
	return _character.grid_position == map.goal_grid

func _on_sequence_complete(stats: Dictionary) -> void:
	if _goal_beacon != null and is_instance_valid(_goal_beacon):
		_goal_beacon.stop()
	if _character_portrait != null:
		_character_portrait.on_victory()
	if not _goal_reached():
		push_warning("BlindTuner: sequence completed at %s but goal is %s (map=%s)" % [_character.grid_position, MapPresets.by_id(_current_map_id).goal_grid, _current_map_id])
	_hud.show_stats(stats)
	
	var current_lvl = LevelManager.get_current_level()
	if current_lvl != null:
		var summary = LevelManager.complete_level(stats)
		_show_victory_modal(current_lvl, summary)

func _show_victory_modal(lvl_data, summary: Dictionary) -> void:
	if _victory_modal != null and is_instance_valid(_victory_modal):
		_victory_modal.queue_free()
	_victory_modal = VICTORY_MODAL_SCENE.instantiate()
	$UI.add_child(_victory_modal)
	_victory_modal.display_result(lvl_data, summary)
	_victory_modal.next_level_requested.connect(func():
		var next_id: String = str(summary.get("next_level_id", ""))
		if not next_id.is_empty():
			SceneManager.start_level(next_id)
		else:
			SceneManager.go_to_level_select()
	)
	_victory_modal.restart_requested.connect(func():
		_victory_modal.queue_free()
		_victory_modal = null
		_on_restart_requested()
	)
	_victory_modal.level_select_requested.connect(func():
		SceneManager.go_to_level_select()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if _pause_modal == null or not is_instance_valid(_pause_modal):
			get_viewport().set_input_as_handled()
			_on_pause_requested()

func _on_pause_requested() -> void:
	if _pause_modal != null and is_instance_valid(_pause_modal):
		return
	if _goal_beacon != null and is_instance_valid(_goal_beacon):
		_goal_beacon.stop()
	if _conductor != null and _conductor._timer != null:
		_conductor._timer.paused = true
	_pause_modal = PAUSE_MODAL_SCENE.instantiate()
	$UI.add_child(_pause_modal)
	_pause_modal.resume_requested.connect(_on_resume_from_pause)
	_pause_modal.restart_requested.connect(_on_restart_from_pause)
	_pause_modal.level_select_requested.connect(_on_level_select_from_pause)

func _on_resume_from_pause() -> void:
	if _pause_modal != null:
		_pause_modal.queue_free()
		_pause_modal = null
	if _goal_beacon != null and is_instance_valid(_goal_beacon):
		_goal_beacon.start()
	AccessibleAnnouncer.announce("countdown_tick", "Retomando.")
	if _conductor != null and _conductor._timer != null:
		var tw := create_tween()
		tw.tween_interval(0.3)
		tw.tween_callback(func(): AccessibleAnnouncer.play_earcon("countdown_tick"))
		tw.tween_interval(0.3)
		tw.tween_callback(func(): AccessibleAnnouncer.play_earcon("countdown_go"))
		tw.tween_interval(0.2)
		tw.tween_callback(func():
			if _conductor != null and _conductor._timer != null:
				_conductor._timer.paused = false
		)

func _on_restart_from_pause() -> void:
	if _pause_modal != null:
		_pause_modal.queue_free()
		_pause_modal = null
	_on_restart_requested()

func _on_level_select_from_pause() -> void:
	if _pause_modal != null:
		_pause_modal.queue_free()
		_pause_modal = null
	SceneManager.go_to_level_select()

func _build_room() -> void:
	_clear_room()
	var map = MapPresets.by_id(_current_map_id)
	var theme = SceneryThemes.by_id(map.theme_id)
	for x in range(map.size.x):
		for y in range(map.size.y):
			_spawn_floor_tile(Vector2i(x, y), theme)
	var all_walls: Array[Vector2i] = _border_walls(map.size)
	# Manual append em vez de `+` concat porque GDScript 4 perde Array[Vector2i] no concat.
	for w in map.walls:
		all_walls.append(w)
	for tile in all_walls:
		_wall_tiles[tile] = true
		_spawn_wall_visual(tile, theme)
	_spawn_goal_marker(map.goal_grid, theme)
	if _current_map_id == "quarto" or _current_map_id == "quarto_lullaby":
		_spawn_quarto_furniture()
	elif _current_map_id == "banheiro":
		_spawn_banheiro_furniture()
	elif _current_map_id == "sala":
		_spawn_sala_furniture()
	if _conductor._preset != null:
		_apply_level_visual_cues(_conductor._preset)

func _clear_room() -> void:
	_goal_diamond_marker = null
	for n in [_floor_node, _walls_node, _goal_node]:
		for c in n.get_children():
			c.queue_free()
	_wall_tiles.clear()

func _border_walls(s: Vector2i) -> Array[Vector2i]:
	var arr: Array[Vector2i] = []
	for x in range(s.x):
		arr.append(Vector2i(x, 0))
		arr.append(Vector2i(x, s.y - 1))
	for y in range(s.y):
		arr.append(Vector2i(0, y))
		arr.append(Vector2i(s.x - 1, y))
	return arr

func _spawn_floor_tile(tile: Vector2i, theme) -> void:
	var center: Vector2 = _character.grid_to_world(tile)
	var checker := (tile.x + tile.y) % 2 == 0
	if _current_map_id == "quarto" or _current_map_id == "quarto_lullaby":
		var sprite := Sprite2D.new()
		sprite.texture = FLOOR_WOOD_OAK_A if checker else FLOOR_WOOD_OAK_B
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = center
		sprite.z_index = -100
		_floor_node.add_child(sprite)
	else:
		var poly := Polygon2D.new()
		poly.polygon = _diamond_polygon(TILE_WIDTH, TILE_HEIGHT)
		poly.color = theme.floor_a if checker else theme.floor_b
		poly.position = center
		poly.z_index = -100
		_floor_node.add_child(poly)

func _spawn_quarto_furniture() -> void:
	if _current_map_id == "quarto_lullaby":
		# Cama no destino (2, 7) e (3, 7)
		var bed := Sprite2D.new()
		bed.texture = BED_PROP
		bed.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var bed_center: Vector2 = (_character.grid_to_world(Vector2i(2, 7)) + _character.grid_to_world(Vector2i(3, 7))) * 0.5
		bed.position = bed_center + Vector2(0, -12)
		bed.z_index = int(_character.grid_to_world(Vector2i(3, 7)).y)
		_walls_node.add_child(bed)

		# Criado-mudo com abajur em (2, 6)
		var ns := Sprite2D.new()
		ns.texture = NIGHTSTAND_PROP
		ns.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ns.position = _character.grid_to_world(Vector2i(2, 6)) + Vector2(0, -16)
		ns.z_index = int(_character.grid_to_world(Vector2i(2, 6)).y)
		_walls_node.add_child(ns)

		# Chinelos aos pés da cama em (3, 6)
		var slippers := Sprite2D.new()
		slippers.texture = SLIPPERS_PROP
		slippers.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slippers.scale = Vector2(0.55, 0.55)
		slippers.position = _character.grid_to_world(Vector2i(3, 6)) + Vector2(6, -6)
		slippers.z_index = int(_character.grid_to_world(Vector2i(3, 6)).y) - 2
		_floor_node.add_child(slippers)
		return

	# Cama de solteiro do velhinho na área 2x3 (1,1)..(2,3)
	var bed := Sprite2D.new()
	bed.texture = BED_PROP
	bed.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var bed_center: Vector2 = (_character.grid_to_world(Vector2i(1, 1)) + _character.grid_to_world(Vector2i(2, 3))) * 0.5
	bed.position = bed_center + Vector2(0, -12)
	# Profundidade isométrica: base inferior da cama está no tile (2, 3)
	bed.z_index = int(_character.grid_to_world(Vector2i(2, 3)).y)
	_walls_node.add_child(bed)

	# Criado-mudo com abajur em (3,2)
	var ns := Sprite2D.new()
	ns.texture = NIGHTSTAND_PROP
	ns.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ns.position = _character.grid_to_world(Vector2i(3, 2)) + Vector2(0, -16)
	ns.z_index = int(_character.grid_to_world(Vector2i(3, 2)).y)
	_walls_node.add_child(ns)

	# Chinelos aos pés da cama em (2, 4) com escala proporcional aos pés do velhinho
	var slippers := Sprite2D.new()
	slippers.texture = SLIPPERS_PROP
	slippers.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slippers.scale = Vector2(0.55, 0.55)
	slippers.position = _character.grid_to_world(Vector2i(2, 4)) + Vector2(6, -6)
	slippers.z_index = int(_character.grid_to_world(Vector2i(2, 4)).y) - 2
	_floor_node.add_child(slippers)

func _spawn_banheiro_furniture() -> void:
	# Vaso Sanitário em (7, 1)
	var toilet := Sprite2D.new()
	toilet.texture = TOILET_PROP
	toilet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	toilet.position = _character.grid_to_world(Vector2i(7, 1)) + Vector2(0, -10)
	toilet.z_index = int(_character.grid_to_world(Vector2i(7, 1)).y)
	_walls_node.add_child(toilet)

	# Banheira clássica ocupando área (1, 1)..(2, 2)
	var tub := Sprite2D.new()
	tub.texture = BATHTUB_PROP
	tub.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tub_center: Vector2 = (_character.grid_to_world(Vector2i(1, 1)) + _character.grid_to_world(Vector2i(2, 2))) * 0.5
	tub.position = tub_center + Vector2(0, -10)
	tub.z_index = int(_character.grid_to_world(Vector2i(2, 2)).y)
	_walls_node.add_child(tub)

	# Tapete antiderrapante em (6, 4)
	var mat := Sprite2D.new()
	mat.texture = BATH_MAT_PROP
	mat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mat.position = _character.grid_to_world(Vector2i(6, 4))
	mat.z_index = int(_character.grid_to_world(Vector2i(6, 4)).y) - 2
	_floor_node.add_child(mat)

func _spawn_sala_furniture() -> void:
	# Poltrona aconchegante em (1, 4)
	var chair := Sprite2D.new()
	chair.texture = ARMCHAIR_PROP
	chair.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chair.position = _character.grid_to_world(Vector2i(1, 4)) + Vector2(0, -12)
	chair.z_index = int(_character.grid_to_world(Vector2i(1, 4)).y)
	_walls_node.add_child(chair)

	# Mesa de centro com livro e chá em (4, 6)
	var table := Sprite2D.new()
	table.texture = COFFEE_TABLE_PROP
	table.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	table.position = _character.grid_to_world(Vector2i(4, 6)) + Vector2(0, -8)
	table.z_index = int(_character.grid_to_world(Vector2i(4, 6)).y)
	_walls_node.add_child(table)

	# Estante / cômoda em (10, 3)
	var dresser := Sprite2D.new()
	dresser.texture = DRESSER_PROP
	dresser.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dresser.position = _character.grid_to_world(Vector2i(10, 3)) + Vector2(0, -16)
	dresser.z_index = int(_character.grid_to_world(Vector2i(10, 3)).y)
	_walls_node.add_child(dresser)

	# Tapete com ponta dobrada (obstáculo de tropeço) em (5, 7)
	var rug := Sprite2D.new()
	rug.texture = RUG_FOLDED_PROP
	rug.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rug.position = _character.grid_to_world(Vector2i(5, 7))
	rug.z_index = int(_character.grid_to_world(Vector2i(5, 7)).y) - 2
	_floor_node.add_child(rug)

func _spawn_wall_visual(tile: Vector2i, theme) -> void:
	if _current_map_id == "quarto_lullaby":
		if tile in [Vector2i(2, 7), Vector2i(3, 7), Vector2i(2, 6)]:
			return
		var center: Vector2 = _character.grid_to_world(tile)
		var wall_sprite := Sprite2D.new()
		wall_sprite.texture = WALL_WOOD_QUARTO
		wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall_sprite.position = center + Vector2(0, -20)
		wall_sprite.z_index = int(center.y)
		_walls_node.add_child(wall_sprite)
		return
	if _current_map_id == "quarto":
		# Cama e criado-mudo são desenhados com seus sprites em _spawn_quarto_furniture
		if tile in [Vector2i(1,1), Vector2i(2,1), Vector2i(1,2), Vector2i(2,2), Vector2i(1,3), Vector2i(2,3), Vector2i(3,1), Vector2i(3,2)]:
			return
		var center: Vector2 = _character.grid_to_world(tile)
		var wall_sprite := Sprite2D.new()
		wall_sprite.texture = WALL_WOOD_QUARTO
		wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall_sprite.position = center + Vector2(0, -20)
		wall_sprite.z_index = int(center.y)
		_walls_node.add_child(wall_sprite)
		return
	if _current_map_id == "banheiro":
		if tile in [Vector2i(1,1), Vector2i(2,1), Vector2i(1,2), Vector2i(7,1), Vector2i(7,2), Vector2i(8,1), Vector2i(3,1)]:
			return
	if _current_map_id == "sala":
		if tile in [Vector2i(1,1), Vector2i(1,4), Vector2i(4,6), Vector2i(10,2), Vector2i(10,3), Vector2i(10,4), Vector2i(10,5), Vector2i(3,8), Vector2i(4,8), Vector2i(5,8)]:
			return
	var center: Vector2 = _character.grid_to_world(tile)
	var node := Node2D.new()
	node.position = center
	node.z_index = int(center.y)
	var front := Polygon2D.new()
	var hw := TILE_WIDTH * 0.5
	front.polygon = PackedVector2Array([
		Vector2(-hw,  0),
		Vector2( hw,  0),
		Vector2( hw, -WALL_HEIGHT),
		Vector2(-hw, -WALL_HEIGHT),
	])
	front.color = theme.wall_front
	node.add_child(front)
	var top := Polygon2D.new()
	top.polygon = _diamond_polygon(TILE_WIDTH, TILE_HEIGHT)
	top.color = theme.wall_top
	top.position = Vector2(0, -WALL_HEIGHT)
	node.add_child(top)
	var outline := Line2D.new()
	var pts := _diamond_polygon(TILE_WIDTH, TILE_HEIGHT)
	var pts_closed: Array[Vector2] = []
	for p in pts:
		pts_closed.append(p)
	pts_closed.append(pts[0])
	outline.points = PackedVector2Array(pts_closed)
	outline.width = 1.0
	outline.default_color = theme.wall_outline
	outline.position = Vector2(0, -WALL_HEIGHT)
	node.add_child(outline)
	_walls_node.add_child(node)

func _spawn_goal_marker(tile: Vector2i, theme) -> void:
	var center: Vector2 = _character.grid_to_world(tile)
	var poly := Polygon2D.new()
	poly.polygon = _diamond_polygon(TILE_WIDTH, TILE_HEIGHT)
	poly.color = theme.goal_marker_color
	poly.position = center
	poly.z_index = int(center.y) - 2
	_goal_node.add_child(poly)
	_goal_diamond_marker = poly
	var tw := poly.create_tween().set_loops()
	tw.tween_property(poly, "modulate:a", 0.5, 1.0)
	tw.tween_property(poly, "modulate:a", 1.0, 1.0)
	if _current_map_id == "quarto":
		var radio := Sprite2D.new()
		radio.texture = RADIO_PROP
		radio.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		radio.position = center + Vector2(0, -12)
		radio.z_index = int(center.y)
		_goal_node.add_child(radio)
	elif _current_map_id == "banheiro":
		var sink := Sprite2D.new()
		sink.texture = SINK_PROP
		sink.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sink.position = center + Vector2(0, -14)
		sink.z_index = int(center.y)
		_goal_node.add_child(sink)
	elif _current_map_id == "sala":
		var clock := Sprite2D.new()
		clock.texture = CLOCK_PROP
		clock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		clock.position = center + Vector2(0, -28)
		clock.z_index = int(center.y)
		_goal_node.add_child(clock)
	_spawn_goal_audio_beacon(center)

func _spawn_goal_audio_beacon(pos: Vector2) -> void:
	if _goal_beacon != null and is_instance_valid(_goal_beacon):
		_goal_beacon.queue_free()
		_goal_beacon = null
	_goal_beacon = GOAL_AUDIO_BEACON_SCENE.instantiate()
	_goal_beacon.position = pos
	var sound_id := "radio"
	var lvl = _conductor._preset if _conductor != null and _conductor._preset != null else null
	if lvl == null and not LevelManager.is_sandbox:
		lvl = LevelManager.get_current_level()
	if lvl != null and not str(lvl.get("beacon_sound_id")).is_empty():
		sound_id = str(lvl.get("beacon_sound_id"))
	elif _current_map_id == "quarto_lullaby":
		sound_id = "music_box"
	elif _current_map_id == "banheiro":
		sound_id = "drip"
	elif _current_map_id == "sala":
		sound_id = "clock"
	_goal_beacon.setup(sound_id)
	_goal_node.add_child(_goal_beacon)

func _diamond_polygon(w: int, h: int) -> PackedVector2Array:
	var hw := w * 0.5
	var hh := h * 0.5
	return PackedVector2Array([
		Vector2(0, -hh),
		Vector2(hw,  0),
		Vector2(0,  hh),
		Vector2(-hw, 0),
	])

func _process(delta: float) -> void:
	var alpha := 1.0 - pow(0.9, delta * 60.0)
	var target_cam_pos := _character.position + Vector2(0.0, CAMERA_VIEWPORT_OFFSET_Y)
	_camera.position = _camera.position.lerp(target_cam_pos, alpha)
	if _vision_overlay != null and is_instance_valid(_vision_overlay):
		var screen_pos: Vector2 = _character.get_global_transform_with_canvas().origin
		var vp_size: Vector2 = get_viewport_rect().size
		_vision_overlay.update_character_screen_position(screen_pos, vp_size)
	if _shake_remaining > 0.0:
		_shake_remaining = max(0.0, _shake_remaining - delta)
		var t := _shake_remaining / SHAKE_DURATION
		var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * SHAKE_INTENSITY * t
		_camera.offset = offset
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO

func _on_character_blocked(_dir: Vector2i, reason: int) -> void:
	if _character_portrait != null:
		if reason == _character.TripReason.NOTE_MISS:
			_character_portrait.on_note_miss()
		else:
			_character_portrait.on_wall_bump()
	if reason == _character.TripReason.WALL:
		if _conductor != null:
			_conductor.record_wall_bump()
	if reason == _character.TripReason.NOTE_MISS:
		# Erro de conhecimento no CALL: só o SFX suave, sem shake/flash de colisão.
		# Mesmo delay do WALL abaixo: a nota errada que o jogador tocou (play_note,
		# 0.6s) precisa ser ouvida antes do SFX de erro, senão ele a mascara quase
		# instantaneamente (AudioManager serializa playback a um único player ativo).
		get_tree().create_timer(COLLISION_SFX_DELAY).timeout.connect(AudioManager.play_note_miss_sfx)
		return
	_shake_remaining = SHAKE_DURATION
	_flash_screen()
	# Delay no SFX para a nota do jogador ser ouvida antes (pista auditiva de cima/baixo).
	get_tree().create_timer(COLLISION_SFX_DELAY).timeout.connect(AudioManager.play_collision_sfx)

func _flash_screen() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_screen_flash, "color:a", FLASH_PEAK_ALPHA, FLASH_DURATION * 0.3)
	_flash_tween.tween_property(_screen_flash, "color:a", 0.0, FLASH_DURATION * 0.7)

func _on_tactile_pulse_requested(world_pos: Vector2, grid_pos: Vector2i, _facing: Vector2i) -> void:
	AudioManager.play_cane_tap_sfx()
	var ripple = TactileRippleScript.new()
	ripple.position = world_pos
	add_child(ripple)
	var show_outlines: bool = true
	if _conductor != null and _conductor._preset != null and _conductor._preset.get("show_obstacle_outlines") != null:
		show_outlines = bool(_conductor._preset.get("show_obstacle_outlines"))
	if show_outlines:
		_highlight_nearby_obstacles(grid_pos, 3)

func _highlight_nearby_obstacles(center_grid: Vector2i, radius: int) -> void:
	for tile in _wall_tiles.keys():
		if abs(tile.x - center_grid.x) <= radius and abs(tile.y - center_grid.y) <= radius:
			_spawn_obstacle_highlight(tile)

func _spawn_obstacle_highlight(tile: Vector2i) -> void:
	var center: Vector2 = _character.grid_to_world(tile)
	var outline := Line2D.new()
	var pts := _diamond_polygon(TILE_WIDTH, TILE_HEIGHT)
	var pts_closed: Array[Vector2] = []
	for p in pts:
		pts_closed.append(p)
	pts_closed.append(pts[0])
	outline.points = PackedVector2Array(pts_closed)
	outline.width = 2.5
	outline.default_color = Color(0.3, 0.9, 1.0, 0.9)
	outline.position = center
	outline.z_index = int(center.y) + 50
	add_child(outline)
	var tw := outline.create_tween()
	tw.tween_property(outline, "modulate:a", 0.0, 2.5)
	tw.tween_callback(outline.queue_free)

func _on_listening_focus_requested(world_pos: Vector2) -> void:
	if _character_portrait != null:
		_character_portrait.trigger_reaction(CharacterPortraitScript.State.LISTENING, 2.5)
	if _goal_beacon != null and is_instance_valid(_goal_beacon):
		_goal_beacon.pulse_now()
	var map = MapPresets.by_id(_current_map_id)
	var goal_world: Vector2 = _character.grid_to_world(map.goal_grid) if map != null else (_goal_beacon.position if _goal_beacon != null else world_pos)
	var show_cues: bool = true
	if _conductor != null and _conductor._preset != null and _conductor._preset.get("show_visual_cues") != null:
		show_cues = bool(_conductor._preset.get("show_visual_cues"))
	if show_cues:
		var guide = AcousticFocusGuideScript.new()
		guide.setup(goal_world, world_pos)
		add_child(guide)
	if _conductor != null and _conductor._timer != null and not _conductor._timer.is_stopped() and not _conductor._timer.paused:
		_conductor._timer.paused = true
		get_tree().create_timer(2.5).timeout.connect(func():
			if _conductor != null and _conductor._timer != null and is_instance_valid(_conductor._timer):
				_conductor._timer.paused = false
		)
