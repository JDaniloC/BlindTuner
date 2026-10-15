extends GutTest

const CharacterPortraitScript := preload("res://scripts/CharacterPortrait.gd")
const PORTRAIT_SCENE := preload("res://scenes/CharacterPortrait.tscn")

var _portrait: CharacterPortraitScript

func before_each() -> void:
	_portrait = PORTRAIT_SCENE.instantiate()
	add_child_autofree(_portrait)

func test_initial_state_is_idle() -> void:
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.IDLE)
	assert_not_null(_portrait._texture_rect.texture)

func test_set_state_updates_current_and_persistent() -> void:
	_portrait.set_state(CharacterPortraitScript.State.HAPPY)
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.HAPPY)
	assert_eq(_portrait.persistent_state, CharacterPortraitScript.State.HAPPY)
	assert_eq(_portrait._texture_rect.texture, CharacterPortraitScript.TEXTURES[CharacterPortraitScript.State.HAPPY])

func test_set_listening_updates_persistent_and_current_when_idle() -> void:
	_portrait.set_listening(true)
	assert_eq(_portrait.persistent_state, CharacterPortraitScript.State.LISTENING)
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.LISTENING)
	_portrait.set_listening(false)
	assert_eq(_portrait.persistent_state, CharacterPortraitScript.State.IDLE)
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.IDLE)

func test_trigger_reaction_returns_to_persistent_state() -> void:
	_portrait.set_state(CharacterPortraitScript.State.IDLE)
	_portrait.trigger_reaction(CharacterPortraitScript.State.BUMP, 0.05)
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.BUMP)
	await get_tree().create_timer(0.08).timeout
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.IDLE)

func test_on_wall_bump_triggers_bump_reaction() -> void:
	_portrait.on_wall_bump()
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.BUMP)

func test_on_note_miss_triggers_confused_reaction() -> void:
	_portrait.on_note_miss()
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.CONFUSED)

func test_on_note_hit_triggers_happy_reaction() -> void:
	_portrait.on_note_hit()
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.HAPPY)

func test_on_victory_sets_happy_permanently() -> void:
	_portrait.on_victory()
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.HAPPY)
	assert_eq(_portrait.persistent_state, CharacterPortraitScript.State.HAPPY)

func test_reset_restores_idle() -> void:
	_portrait.on_victory()
	_portrait.reset()
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.IDLE)
	assert_eq(_portrait.persistent_state, CharacterPortraitScript.State.IDLE)

func test_on_note_hit_protects_happy_against_immediate_listening() -> void:
	_portrait.on_note_hit()
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.HAPPY)
	# Um novo CALL que chegue imediatamente (< 450ms) não deve cortar o sorriso de acerto
	_portrait.trigger_reaction(CharacterPortraitScript.State.LISTENING, 0.8)
	assert_eq(_portrait.current_state, CharacterPortraitScript.State.HAPPY, "o alívio/sorriso deve ser protegido")

