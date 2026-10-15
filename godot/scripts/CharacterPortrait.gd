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

## Reação de erro na nota ou dúvida.
func on_note_miss() -> void:
	trigger_reaction(State.CONFUSED, 1.0)

## Reação de acerto na nota.
func on_note_hit() -> void:
	trigger_reaction(State.HAPPY, 0.8)

## Reação de conclusão da sequência.
func on_victory() -> void:
	set_state(State.HAPPY)

## Reinicia para o estado neutro (IDLE).
func reset() -> void:
	set_state(State.IDLE)

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
