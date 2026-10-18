class_name CharacterPortrait
extends PanelContainer

## Retrato reativo do protagonista no HUD (estilo Doom status bar).
## Reage a ações, pistas auditivas, colisões e resolução de notas.

enum State {
	IDLE,
	LISTENING,
	BUMP,
	CONFUSED,
	HAPPY,
}

const TEXTURES: Dictionary = {
	State.IDLE: preload("res://assets/sprites/ui/portrait/portrait_idle.png"),
	State.LISTENING: preload("res://assets/sprites/ui/portrait/portrait_listening.png"),
	State.BUMP: preload("res://assets/sprites/ui/portrait/portrait_bump.png"),
	State.CONFUSED: preload("res://assets/sprites/ui/portrait/portrait_confused.png"),
	State.HAPPY: preload("res://assets/sprites/ui/portrait/portrait_happy.png"),
}

const SHAKE_OFFSET := 3.0
const SHAKE_DURATION := 0.2

var current_state: State = State.IDLE
var persistent_state: State = State.IDLE

var _reaction_timer_id: int = 0
var _shake_tween: Tween
var _acoustic_tween: Tween
var _border_tween: Tween
var _happy_priority_until_ms: int = 0

@onready var _texture_rect: TextureRect = $Margin/TextureRect

func _ready() -> void:
	_apply_state(current_state)

## Define o estado de forma direta. Cancela reações temporárias ativas.
func set_state(state: State) -> void:
	_reaction_timer_id += 1
	persistent_state = state
	_apply_state(state)

## Dispara uma reação transitória que retorna ao estado persistente após duration segundos.
func trigger_reaction(state: State, duration: float = 0.8) -> void:
	var now := Time.get_ticks_msec()
	# Prioridade: não corta o sorriso de alívio imediatamente se um novo CALL chegar logo em seguida
	if now < _happy_priority_until_ms and state == State.LISTENING:
		return
	_apply_state(state)
	_reaction_timer_id += 1
	var current_id := _reaction_timer_id
	get_tree().create_timer(duration).timeout.connect(func():
		if _reaction_timer_id == current_id:
			_apply_state(persistent_state)
	)

## Define se o personagem está escutando ativamente a nota guia.
func set_listening(listening: bool) -> void:
	persistent_state = State.LISTENING if listening else State.IDLE
	_apply_state(persistent_state)

## Reação de colisão com a parede (Doom ouch face + micro tremor).
func on_wall_bump() -> void:
	trigger_reaction(State.BUMP, 0.9)
	_shudder()
	AccessibleAnnouncer.play_earcon("boundary")

## Reação de erro na nota ou dúvida.
func on_note_miss() -> void:
	trigger_reaction(State.CONFUSED, 1.0)
	AccessibleAnnouncer.play_earcon("error")

## Reação de acerto na nota.
func on_note_hit() -> void:
	_happy_priority_until_ms = Time.get_ticks_msec() + 450
	trigger_reaction(State.HAPPY, 0.8)
	_pop_happy()
	AccessibleAnnouncer.play_earcon("confirm")

## Reação de conclusão da sequência.
func on_victory() -> void:
	set_state(State.HAPPY)

## Reinicia para o estado neutro (IDLE).
func reset() -> void:
	set_state(State.IDLE)

## Reação acústica sutil sincronizada com o impacto da bengala no solo.
## Dispara uma microvibração tátil no retrato e pulso luminoso harmônico na moldura.
func on_cane_tap(pulse_color: Color = Color(0.92, 0.85, 0.65, 1.0)) -> void:
	if current_state == State.BUMP:
		return
	_vibrate_acoustic(pulse_color)

func _vibrate_acoustic(pulse_color: Color) -> void:
	if _texture_rect == null or not is_inside_tree():
		return
	_texture_rect.pivot_offset = _texture_rect.size * 0.5
	if _acoustic_tween:
		_acoustic_tween.kill()
	_acoustic_tween = create_tween()
	_acoustic_tween.tween_property(_texture_rect, "position:y", -1.5, 0.04).set_trans(Tween.TRANS_SINE)
	_acoustic_tween.parallel().tween_property(_texture_rect, "scale", Vector2(1.025, 1.025), 0.04)
	_acoustic_tween.tween_property(_texture_rect, "position:y", 0.0, 0.07).set_trans(Tween.TRANS_SINE)
	_acoustic_tween.parallel().tween_property(_texture_rect, "scale", Vector2.ONE, 0.07)

	var current_sb: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	if current_sb != null:
		var target_border := _get_target_border_color(current_state)
		if _border_tween:
			_border_tween.kill()
		_border_tween = create_tween()
		current_sb.border_color = pulse_color
		_border_tween.tween_property(current_sb, "border_color", target_border, 0.2).set_trans(Tween.TRANS_SINE)

func _pop_happy() -> void:
	if _texture_rect == null or not is_inside_tree():
		return
	_texture_rect.pivot_offset = _texture_rect.size * 0.5
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.tween_property(_texture_rect, "scale", Vector2(1.06, 1.06), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(_texture_rect, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE)

func _shudder() -> void:
	if _texture_rect == null:
		return
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	var orig_pos := Vector2.ZERO
	_shake_tween.tween_property(_texture_rect, "position", orig_pos + Vector2(-SHAKE_OFFSET, 1.0), SHAKE_DURATION * 0.25)
	_shake_tween.tween_property(_texture_rect, "position", orig_pos + Vector2(SHAKE_OFFSET, -1.0), SHAKE_DURATION * 0.25)
	_shake_tween.tween_property(_texture_rect, "position", orig_pos + Vector2(-SHAKE_OFFSET * 0.5, 0.0), SHAKE_DURATION * 0.25)
	_shake_tween.tween_property(_texture_rect, "position", orig_pos, SHAKE_DURATION * 0.25)

func _apply_state(state: State) -> void:
	current_state = state
	if _texture_rect and TEXTURES.has(state):
		_texture_rect.texture = TEXTURES[state]
	_update_frame_style(state)

func _update_frame_style(state: State) -> void:
	var sb := StyleBoxFlat.new()
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	match state:
		State.LISTENING:
			sb.bg_color = Color(0.90, 0.94, 0.97, 1.0)
		State.HAPPY:
			sb.bg_color = Color(0.91, 0.96, 0.89, 1.0)
		State.BUMP:
			sb.bg_color = Color(0.96, 0.89, 0.86, 1.0)
		State.CONFUSED:
			sb.bg_color = Color(0.95, 0.91, 0.84, 1.0)
		_:
			sb.bg_color = Color(0.933, 0.902, 0.843, 1.0)
	sb.border_color = _get_target_border_color(state)
	add_theme_stylebox_override("panel", sb)

func _get_target_border_color(state: State) -> Color:
	match state:
		State.LISTENING:
			return Color(0.12, 0.38, 0.58, 1.0)
		State.HAPPY:
			return Color(0.16, 0.46, 0.22, 1.0)
		State.BUMP:
			return Color(0.58, 0.18, 0.12, 1.0)
		State.CONFUSED:
			return Color(0.54, 0.32, 0.08, 1.0)
		_:
			return Color(0.24, 0.176, 0.125, 1.0)
