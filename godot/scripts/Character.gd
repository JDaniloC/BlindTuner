extends Node2D
## Personagem isométrico do MVP. Move 1 tile por nota de movimento; bloqueado por paredes; ignora reservadas.

signal moved(new_grid_position: Vector2i)
signal blocked(direction: Vector2i, reason: int)
signal action_performed(action_id: String, grid_position: Vector2i, facing: Vector2i)
## Notifica mudança de _run_next / _jump_next para UI espelhar (botão armado brilha).
signal armed_state_changed(running: bool, jumping: bool)
## Dispara quando o idoso tateia com a bengala, revelando obstáculos e quinas.
signal tactile_pulse_requested(world_pos: Vector2, grid_pos: Vector2i, facing: Vector2i)
## Dispara quando o idoso para para escutar atentamente o farol sonoro.
signal listening_focus_requested(world_pos: Vector2)
## Dispara ao entrar (true) e sair (false) do estado de tropeço para guiar UI e feedback.
signal trip_state_changed(is_tripping: bool)
## Dispara a cada toque da bengala no solo (durante passos ou tatear) com a posição da ponta e a nota emitida.
signal cane_tapped(world_pos: Vector2, note_key: String)

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MOVE_DURATION := 0.18
const RUN_MOVE_DURATION := 0.11  # ~MOVE_DURATION * 0.6
const DOUBLE_TAP_WINDOW_MS := 400
const TRIP_DURATION_SEC := 0.6
const INTERACT_DURATION_SEC := 0.4   # 4 frames / 10 fps
const ATTACK_DURATION_SEC := 0.667   # 8 frames / 12 fps
const JUMP_ARC_HEIGHT_PX := 18.0     # elevação Y do sprite no pico do arco
const DUST_PUFF_COUNT := 4
const DUST_PUFF_LIFETIME := 0.5
const DUST_PUFF_COLOR := Color(0.85, 0.78, 0.6, 0.7)
const CaneAcousticPulseScript := preload("res://scripts/CaneAcousticPulse.gd")

enum State { IDLE, WALK, RUN, TRIP }
## Distingue por que o personagem tropeçou: colisão física de verdade (WALL)
## vs erro de conhecimento durante o CALL (NOTE_MISS). Usado por Playground
## para diferenciar o feedback de tela/áudio sem mudar a anim de tropeço.
enum TripReason { WALL, NOTE_MISS }

@export var grid_position: Vector2i = Vector2i(5, 5)
## Dicionário { Vector2i -> bool } populado pela cena pai (Playground) com tiles bloqueados.
var blocked_tiles: Dictionary = {}
var _tween: Tween
var _arc_tween: Tween
var _sprite_base_y: float = 0.0  # capturado em _ready; offset do AnimatedSprite na cena

var state: State = State.IDLE
var _last_direction: Vector2i = Vector2i(0, 1)
var _last_note_key: String = ""
var _last_note_time_ms: int = 0
var _run_next: bool = false   # armado por handle_action(As4); consumido pelo próximo handle_note de movimento
var _jump_next: bool = false  # armado por handle_action(B4); idem, mas pula 1 tile com anim jump

const SHEET_BASE := "res://assets/sprites/character/16x32_elderly/"
const SHEETS := {
	"idle":   { "file": "16x32 Idle-Sheet.png",   "cols": 4, "frame_w": 32, "frame_h": 32, "loop": true,  "fps": 6 },
	"walk":   { "file": "16x32 Walk-Sheet.png",   "cols": 4, "frame_w": 32, "frame_h": 32, "loop": true,  "fps": 10 },
	"run":    { "file": "16x32 Run-Sheet.png",    "cols": 6, "frame_w": 32, "frame_h": 32, "loop": true,  "fps": 14 },
	"rotate":   { "file": "16x32 Rotate-Sheet.png",   "cols": 4, "frame_w": 32, "frame_h": 32, "loop": false, "fps": 10 },
	"jump":     { "file": "16x32 Jump-Sheet.png",     "cols": 5, "frame_w": 32, "frame_h": 32, "loop": false, "fps": 10 },
	"interact": { "file": "16x32 Interact-Sheet.png", "cols": 4, "frame_w": 32, "frame_h": 32, "loop": false, "fps": 10 },
	"attack":   { "file": "16x32 Attack-Sheet.png",   "cols": 7, "frame_w": 32, "frame_h": 32, "loop": false, "fps": 12 },
}
const DIRECTION_ROWS := ["s", "se", "e", "ne", "n"]
## O vetor de direção vem da grade isométrica (NoteMapping.direction_for),
## onde grid_to_world projeta (x - y, x + y):
## (-1,-1)=N (↑), (0,-1)=NE (↗), (1,-1)=E (→), (1,0)=SE (↘),
## (1,1)=S (↓), (0,1)=SW (↙), (-1,1)=W (←), (-1,0)=NW (↖).
const DIRECTION_TO_KEY := {
	Vector2i( 1,  1): { "key": "s",  "flip": false },
	Vector2i( 1,  0): { "key": "se", "flip": false },
	Vector2i( 1, -1): { "key": "e",  "flip": false },
	Vector2i( 0, -1): { "key": "ne", "flip": false },
	Vector2i(-1, -1): { "key": "n",  "flip": false },
	Vector2i(-1,  0): { "key": "ne", "flip": true },
	Vector2i(-1,  1): { "key": "e",  "flip": true },
	Vector2i( 0,  1): { "key": "se", "flip": true },
}

var _shadow: Polygon2D = null
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _animation_for(state_name: String, direction: Vector2i) -> Dictionary:
	var entry = DIRECTION_TO_KEY.get(direction, { "key": "s", "flip": false })
	return { "anim": "%s_%s" % [state_name, entry.key], "flip": entry.flip }

func _build_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")
	for state_name in SHEETS:
		var info = SHEETS[state_name]
		var texture: Texture2D = load(SHEET_BASE + info.file)
		for row in range(DIRECTION_ROWS.size()):
			var dir_key = DIRECTION_ROWS[row]
			var anim_name = "%s_%s" % [state_name, dir_key]
			sprite_frames.add_animation(anim_name)
			sprite_frames.set_animation_loop(anim_name, info.loop)
			sprite_frames.set_animation_speed(anim_name, info.fps)
			for col in range(info.cols):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(col * info.frame_w, row * info.frame_h, info.frame_w, info.frame_h)
				sprite_frames.add_frame(anim_name, atlas)
	return sprite_frames

func _play_animation(state_name: String, direction: Vector2i) -> void:
	var info = _animation_for(state_name, direction)
	_animated_sprite.flip_h = info.flip
	_animated_sprite.play(info.anim)

func _ready() -> void:
	position = grid_to_world(grid_position)
	z_index = int(position.y) + 1
	_ensure_contact_shadow()
	_animated_sprite.sprite_frames = _build_sprite_frames()
	_sprite_base_y = _animated_sprite.position.y
	_play_animation("idle", _last_direction)
	_ensure_audio_listener()

func _ensure_contact_shadow() -> void:
	if _shadow != null:
		return
	_shadow = Polygon2D.new()
	_shadow.name = "ContactShadow"
	var pts: Array[Vector2] = []
	for i in range(24):
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a) * 15.0, sin(a) * 7.5))
	_shadow.polygon = PackedVector2Array(pts)
	_shadow.color = Color(0.05, 0.03, 0.02, 0.36)
	_shadow.position = Vector2(0.0, 2.0)
	add_child(_shadow)
	move_child(_shadow, 0)

func _ensure_audio_listener() -> void:
	var listener := AudioListener2D.new()
	add_child(listener)
	listener.make_current()

func _process(_delta: float) -> void:
	z_index = int(position.y) + 1
	if _shadow != null and _animated_sprite != null:
		var lift := clampf((_sprite_base_y - _animated_sprite.position.y) / JUMP_ARC_HEIGHT_PX, 0.0, 1.0)
		var sc := lerpf(1.0, 0.62, lift)
		_shadow.scale = Vector2(sc, sc)
		_shadow.color.a = lerpf(0.36, 0.18, lift)

## Reseta o estado do personagem para início ou repetição de fase.
func reset() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _arc_tween != null and _arc_tween.is_valid():
		_arc_tween.kill()
	if _animated_sprite != null:
		_animated_sprite.position.y = _sprite_base_y
	_set_jump_loop(false)
	_run_next = false
	_jump_next = false
	state = State.IDLE
	_last_note_key = ""
	_last_note_time_ms = 0
	_play_animation("idle", _last_direction)
	armed_state_changed.emit(false, false)

## Recebe a nota disparada pelo joystick. Trata movimento, ação ou ignora se for reservada.
func handle_note(note_key: String) -> void:
	if state == State.TRIP:
		AudioManager.play_trip_blocked_sfx()
		return
	if NoteMapping.is_action_note(note_key):
		handle_action(note_key)
		return
	if not NoteMapping.is_movement_note(note_key):
		return
	var dir := NoteMapping.direction_for(note_key)
	var now := Time.get_ticks_msec()
	var is_double_tap := (note_key == _last_note_key
						  and now - _last_note_time_ms < DOUBLE_TAP_WINDOW_MS)
	var was_armed := _run_next or _jump_next
	if _run_next and _jump_next:
		_run_next = false
		_jump_next = false
		_set_jump_loop(false)
		_try_run_then_jump(dir)
	elif _run_next:
		_run_next = false
		_try_run(dir)
	elif _jump_next:
		_jump_next = false
		_set_jump_loop(false)
		_try_jump(dir)
	elif is_double_tap:
		_try_run(dir)
	else:
		_try_walk(dir)
	if was_armed:
		armed_state_changed.emit(_run_next, _jump_next)
	_last_note_key = note_key
	_last_note_time_ms = now

func _try_walk(dir: Vector2i) -> void:
	var target := grid_position + dir
	if blocked_tiles.get(target, false):
		_enter_trip(dir)
		return
	_last_direction = dir
	state = State.WALK
	grid_position = target
	moved.emit(grid_position)
	_play_animation("walk", dir)
	spawn_cane_acoustic_pulse(_last_note_key)
	AudioManager.play_cane_step_sfx()
	_tween_to(grid_to_world(target), MOVE_DURATION)

func _try_run(dir: Vector2i) -> void:
	var target := grid_position + dir
	if blocked_tiles.get(target, false):
		_enter_trip(dir)
		return
	_last_direction = dir
	state = State.RUN
	grid_position = target
	moved.emit(grid_position)
	_play_animation("run", dir)
	_spawn_dust_puffs()
	spawn_cane_acoustic_pulse(_last_note_key)
	AudioManager.play_cane_step_sfx()
	_tween_to(grid_to_world(target), RUN_MOVE_DURATION)

## Retorna a posição no mundo onde a ponta da bengala toca o solo.
func get_cane_tip_world_position() -> Vector2:
	var offset: Vector2
	match _last_direction:
		Vector2i( 1,  1): offset = Vector2(10.0, 4.0)   # s  (baixo ↓)
		Vector2i( 1,  0): offset = Vector2(12.0, 2.0)   # se (baixo-direita ↘)
		Vector2i( 1, -1): offset = Vector2(14.0, -1.0)  # e  (direita →)
		Vector2i( 0, -1): offset = Vector2(10.0, -5.0)  # ne (cima-direita ↗)
		Vector2i(-1, -1): offset = Vector2(8.0, -7.0)   # n  (cima ↑)
		Vector2i(-1,  0): offset = Vector2(-10.0, -5.0) # nw (cima-esquerda ↖)
		Vector2i(-1,  1): offset = Vector2(-14.0, -1.0) # w  (esquerda ←)
		Vector2i( 0,  1): offset = Vector2(-12.0, 2.0)  # sw (baixo-esquerda ↙)
		_:                offset = Vector2(10.0, 4.0)
	return position + offset

## Emite um pulso acústico no solo na posição da ponta da bengala.
func spawn_cane_acoustic_pulse(note_key: String = "") -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	var pulse := CaneAcousticPulseScript.new()
	var col := Color(0.75, 0.94, 1.0)
	if not note_key.is_empty() and NoteMapping.NOTES.has(note_key):
		col = NoteMapping.color_for(note_key)
	var tip_pos := get_cane_tip_world_position()
	pulse.setup(tip_pos, col)
	get_parent().add_child(pulse)
	cane_tapped.emit(tip_pos, note_key)

## Salto: 2 tiles com anim jump (mesma distância do combo run+jump, só que com
## anim 'jump' nos dois segmentos). 1º tile bloqueado = trip;
## 2º tile bloqueado = anda só 1 com anim jump. Arco visual em cada segmento.
func _try_jump(dir: Vector2i) -> void:
	var target1 := grid_position + dir
	if blocked_tiles.get(target1, false):
		_enter_trip(dir)
		return
	var target2 := target1 + dir
	_last_direction = dir
	state = State.RUN  # reusa RUN state para que _on_tween_finished volte a idle
	_play_animation("jump", dir)
	if blocked_tiles.get(target2, false):
		grid_position = target1
		moved.emit(grid_position)
		_tween_to(grid_to_world(target1), RUN_MOVE_DURATION)
		_start_jump_arc(1, RUN_MOVE_DURATION)
	else:
		grid_position = target2
		moved.emit(grid_position)
		_tween_chain([grid_to_world(target1), grid_to_world(target2)], RUN_MOVE_DURATION)
		_start_jump_arc(2, RUN_MOVE_DURATION)

## Combo correr+pular: 2 tiles totais. 1º tile com anim 'run', troca pra 'jump' antes
## do 2º tile. tween_callback faz a transição entre os dois segmentos.
func _try_run_then_jump(dir: Vector2i) -> void:
	var target1 := grid_position + dir
	if blocked_tiles.get(target1, false):
		_enter_trip(dir)
		return
	var target2 := target1 + dir
	_last_direction = dir
	state = State.RUN
	_play_animation("run", dir)
	_spawn_dust_puffs()
	if blocked_tiles.get(target2, false):
		# 2º bloqueado: anda só 1 tile com anim run, sem trocar pra jump
		grid_position = target1
		moved.emit(grid_position)
		_tween_to(grid_to_world(target1), RUN_MOVE_DURATION)
	else:
		grid_position = target2
		moved.emit(grid_position)
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(self, "position", grid_to_world(target1), RUN_MOVE_DURATION)
		_tween.tween_callback(_play_animation.bind("jump", dir))
		_tween.tween_callback(_start_jump_arc.bind(1, RUN_MOVE_DURATION))
		_tween.tween_property(self, "position", grid_to_world(target2), RUN_MOVE_DURATION)
		_tween.finished.connect(_on_tween_finished)

func _tween_to(target_world: Vector2, duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", target_world, duration)
	_tween.finished.connect(_on_tween_finished)

func _tween_chain(waypoints: Array, segment_duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	for wp in waypoints:
		_tween.tween_property(self, "position", wp, segment_duration)
	_tween.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
	if state == State.TRIP:
		return
	state = State.IDLE
	_play_animation("idle", _last_direction)

func _enter_trip(dir: Vector2i, reason: int = TripReason.WALL) -> void:
	var was_armed := _run_next or _jump_next
	_run_next = false   # tropeçar cancela qualquer corrida/salto armado
	_jump_next = false
	_set_jump_loop(false)  # garante que o trip não loope (jump anim é one-shot pra trip)
	_reset_sprite_arc()    # cancela qualquer arco em andamento e devolve sprite ao base
	if was_armed:
		armed_state_changed.emit(false, false)
	state = State.TRIP
	_last_direction = dir
	_play_animation("jump", dir)
	blocked.emit(dir, reason)
	trip_state_changed.emit(true)
	get_tree().create_timer(TRIP_DURATION_SEC).timeout.connect(_exit_trip)

func _exit_trip() -> void:
	if not is_instance_valid(self):
		return  # Character foi liberado antes do timer disparar
	if state != State.TRIP:
		return
	state = State.IDLE
	_play_animation("idle", _last_direction)
	trip_state_changed.emit(false)

func is_tripping() -> bool:
	return state == State.TRIP

## Conversão grade → coordenadas de mundo (projeção isométrica padrão 2:1).
func grid_to_world(g: Vector2i) -> Vector2:
	var wx := float(g.x - g.y) * TILE_WIDTH * 0.5
	var wy := float(g.x + g.y) * TILE_HEIGHT * 0.5
	return Vector2(wx, wy)

## Executa uma ação especial (não-movimento). No-op se state==TRIP ou se a nota não é ação.
func handle_action(note_key: String) -> void:
	if state == State.TRIP:
		return
	if not NoteMapping.is_action_note(note_key):
		return
	var aid := NoteMapping.action_id_for(note_key)
	match aid:
		"pegar":    _do_pegar()
		"interagir": _do_interagir()
		"correr":  _do_correr()
		"pular":   _do_pular()
		_:         push_warning("handle_action: action_id desconhecido '%s'" % aid)
	action_performed.emit(aid, grid_position, _last_direction)

func _do_pegar() -> void:
	# Anim de "abaixar e pegar" via sprite Interact (5 dirs, 4 frames @ 10fps).
	_play_animation("interact", _last_direction)
	listening_focus_requested.emit(position)
	get_tree().create_timer(INTERACT_DURATION_SEC).timeout.connect(_return_to_idle_if_static)

func _do_interagir() -> void:
	# Anim de "varredura com a bengala" via sprite Attack (5 dirs, 7 frames @ 12fps).
	_play_animation("attack", _last_direction)
	tactile_pulse_requested.emit(get_cane_tip_world_position(), grid_position, _last_direction)
	get_tree().create_timer(ATTACK_DURATION_SEC).timeout.connect(_return_to_idle_if_static)

func _do_tatear() -> void:
	_do_interagir()

func _do_escutar() -> void:
	_do_pegar()

func tatear() -> void:
	_do_interagir()
	action_performed.emit("interagir", grid_position, _last_direction)

func escutar() -> void:
	_do_pegar()
	action_performed.emit("pegar", grid_position, _last_direction)

func _do_correr() -> void:
	if _run_next:
		_run_next = false
		_play_animation("idle", _last_direction)
		armed_state_changed.emit(_run_next, _jump_next)
		AccessibleAnnouncer.announce("cancel", "Corrida desarmada.")
		return
	# Arma correr: anim 'run' loopa no lugar até consumo. Próximo handle_note vira _try_run.
	_run_next = true
	_play_animation("run", _last_direction)
	armed_state_changed.emit(_run_next, _jump_next)
	AccessibleAnnouncer.announce("confirm", "Corrida armada.")

func _do_pular() -> void:
	if _jump_next:
		_jump_next = false
		_set_jump_loop(false)
		_play_animation("idle", _last_direction)
		armed_state_changed.emit(_run_next, _jump_next)
		AccessibleAnnouncer.announce("cancel", "Salto desarmado.")
		return
	# Arma pular: jump anim LOOPA enquanto armado (vira "saltando no lugar").
	# Loop é desligado em handle_note ao consumir, ou em _enter_trip.
	_jump_next = true
	_set_jump_loop(true)
	_play_animation("jump", _last_direction)
	armed_state_changed.emit(_run_next, _jump_next)
	AccessibleAnnouncer.announce("confirm", "Salto armado.")

func _return_to_idle_if_static() -> void:
	if not is_instance_valid(self):
		return
	# Só volta a idle se o personagem não iniciou movimento durante a anim.
	if state == State.IDLE:
		_play_animation("idle", _last_direction)

## Habilita ou desabilita o loop nas 5 variantes de 'jump_*' do SpriteFrames.
## Usado para fazer a anim de jump loopar enquanto _jump_next está armado
## (sem isso, a anim congela no último frame e o personagem fica "no ar").
func _set_jump_loop(loop: bool) -> void:
	var sf := _animated_sprite.sprite_frames
	if sf == null:
		return
	for row in DIRECTION_ROWS:
		var anim_name = "jump_" + row
		if sf.has_animation(anim_name):
			sf.set_animation_loop(anim_name, loop)

## Anima o sprite numa parábola (sobe e desce) durante N segmentos de duração igual.
## Cada segmento sobe metade do tempo e desce a outra metade; runs em paralelo
## com o tween de posição. Sprite y retorna ao _sprite_base_y no fim de cada segmento.
func _start_jump_arc(segments: int, segment_duration: float) -> void:
	if _arc_tween:
		_arc_tween.kill()
	_animated_sprite.position.y = _sprite_base_y
	_arc_tween = create_tween()
	for i in range(segments):
		_arc_tween.tween_property(_animated_sprite, "position:y",
			_sprite_base_y - JUMP_ARC_HEIGHT_PX, segment_duration * 0.5)
		_arc_tween.tween_property(_animated_sprite, "position:y",
			_sprite_base_y, segment_duration * 0.5)

## Cancela qualquer arco em andamento e devolve o sprite ao Y base.
func _reset_sprite_arc() -> void:
	if _arc_tween:
		_arc_tween.kill()
		_arc_tween = null
	_animated_sprite.position.y = _sprite_base_y

## Spawna N polígonos de poeira na posição atual; cada um sobe, desvanece e se
## autodestroi. top_level=true mantém-os fixos no mundo (não seguem o personagem).
func _spawn_dust_puffs() -> void:
	for i in range(DUST_PUFF_COUNT):
		var puff := Polygon2D.new()
		var s: float = randf_range(2.0, 4.0)
		puff.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
		])
		puff.color = DUST_PUFF_COLOR
		puff.top_level = true
		puff.position = position + Vector2(randf_range(-12.0, 12.0), randf_range(0.0, 8.0))
		add_child(puff)
		var lifetime: float = DUST_PUFF_LIFETIME * randf_range(0.7, 1.0)
		var drift := Vector2(randf_range(-10.0, 10.0), -randf_range(8.0, 14.0))
		var t := puff.create_tween()
		t.set_parallel(true)
		t.tween_property(puff, "modulate:a", 0.0, lifetime)
		t.tween_property(puff, "position", puff.position + drift, lifetime)
		t.chain().tween_callback(puff.queue_free)
