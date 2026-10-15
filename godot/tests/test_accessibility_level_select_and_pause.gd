extends GutTest
## Testes de regressão de acessibilidade não visual e baixa visão:
## Diário de Memórias (LevelSelectScreen), Menu de Pausa (PauseModal) e AccessibleAnnouncer.

const LevelSelectScene := preload("res://scenes/LevelSelectScreen.tscn")
const PauseModalScene := preload("res://scenes/PauseModal.tscn")
const PlaygroundScene := preload("res://scenes/Playground.tscn")

var _screen: SubViewport

func before_each() -> void:
	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width", 720)
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height", 1280)
	_screen = SubViewport.new()
	_screen.size = Vector2i(w, h)
	add_child_autofree(_screen)

func test_accessible_announcer_bus_and_earcons():
	var bus_idx := AudioServer.get_bus_index("UI")
	assert_ne(bus_idx, -1, "O bus de áudio 'UI' dedicado deve existir para isolar retorno da gameplay")
	
	# Verifica geração e cache de earcons
	for earcon in ["focus", "boundary", "locked", "confirm", "cancel", "toggle_on", "toggle_off", "pause", "countdown_tick", "countdown_go", "error"]:
		AccessibleAnnouncer.play_earcon(earcon)
		assert_true(AccessibleAnnouncer._earcon_cache.has(earcon), "Earcon '%s' deve ser gerado e cacheado" % earcon)
	
	# Verifica anúncio sem falhas
	AccessibleAnnouncer.announce("focus", "Teste acessível de anúncio")
	assert_eq(AccessibleAnnouncer._last_announced_text, "Teste acessível de anúncio")

func test_level_select_scroll_follow_focus_enabled():
	var screen: Control = LevelSelectScene.instantiate()
	_screen.add_child(screen)
	await wait_frames(2)
	
	assert_not_null(screen._scroll, "ScrollContainer de cards deve existir")
	assert_true(screen._scroll.follow_focus, "ScrollContainer deve ter follow_focus=true para guiar usuários de baixa visão e teclado")

func test_level_select_initial_focus():
	var screen: Control = LevelSelectScene.instantiate()
	_screen.add_child(screen)
	await wait_frames(2)
	
	assert_not_null(screen._first_focusable, "LevelSelectScreen deve identificar primeiro elemento focável")
	assert_true(screen._first_focusable.has_focus(), "O primeiro card desbloqueado deve receber o foco inicial automaticamente")

func test_level_select_accessible_card_buttons():
	var screen: Control = LevelSelectScene.instantiate()
	_screen.add_child(screen)
	await wait_frames(2)
	
	var buttons: Array = []
	for child in screen._cards_container.find_children("*", "Button", true, false):
		buttons.append(child)
	
	assert_gt(buttons.size(), 0, "Devem existir botões de fase no container")
	for btn in buttons:
		var text: String = btn.text
		assert_true(text.begins_with("Reviver Memória") or text.begins_with("🔒 Memória"),
			"Botão de fase deve ter nome acessível explícito identificando a memória, e não rótulo genérico solto: %s" % text)
		assert_eq(btn.focus_mode, Control.FOCUS_ALL, "Todos os cards (inclusive bloqueados) devem ser focáveis para leitura de tela")

func test_pause_modal_initial_focus_and_focus_trap():
	var modal: Control = PauseModalScene.instantiate()
	_screen.add_child(modal)
	await wait_frames(2)
	
	assert_true(modal._resume_btn.has_focus(), "Botão Continuar deve receber o foco inicial")
	
	# Focus trap circular: primeiro aponta pro último, último pro primeiro
	assert_eq(modal._resume_btn.focus_neighbor_top, modal._menu_btn.get_path(),
		"O topo do botão Continuar deve fechar o ciclo no botão Sair para o Diário")
	assert_eq(modal._menu_btn.focus_neighbor_bottom, modal._resume_btn.get_path(),
		"A base do botão Sair deve fechar o ciclo no botão Continuar")
	assert_eq(modal._resume_btn.focus_neighbor_bottom, modal._restart_btn.get_path(),
		"Navegação vertical deve ser encadeada")
	assert_eq(modal._cues_toggle.focus_neighbor_bottom, modal._talkback_toggle.get_path(),
		"Abaixo de pistas deve vir o toggle de narrador/talkback")
	assert_eq(modal._talkback_toggle.focus_neighbor_bottom, modal._colors_btn.get_path(),
		"Abaixo de talkback deve vir cores das notas")

func test_pause_modal_cues_toggle_exposes_state():
	var modal: Control = PauseModalScene.instantiate()
	_screen.add_child(modal)
	await wait_frames(2)
	
	var initial_state: bool = modal._cues_toggle.button_pressed
	var initial_text: String = modal._cues_toggle.text
	if initial_state:
		assert_true(initial_text.contains("Ligadas") and initial_text.contains("✓"),
			"Toggle ligado deve conter 'Ligadas' e glifo de alto contraste [✓]")
	else:
		assert_true(initial_text.contains("Desligadas") and initial_text.contains("✕"),
			"Toggle desligado deve conter 'Desligadas' e glifo [✕]")
	
	# Simula alternância
	modal._cues_toggle.button_pressed = not initial_state
	var toggled_text: String = modal._cues_toggle.text
	if not initial_state:
		assert_true(toggled_text.contains("Ligadas") and toggled_text.contains("✓"))
	else:
		assert_true(toggled_text.contains("Desligadas") and toggled_text.contains("✕"))

func test_pause_modal_talkback_toggle_optional():
	var modal: Control = PauseModalScene.instantiate()
	_screen.add_child(modal)
	await wait_frames(2)
	
	assert_not_null(modal._talkback_toggle, "Botão de alternar voz do narrador/talkback deve existir no menu de pausa")
	var initial: bool = modal._talkback_toggle.button_pressed
	
	# Alterna para o estado inverso
	modal._talkback_toggle.button_pressed = not initial
	assert_eq(AccessibleAnnouncer.is_tts_enabled(), not initial, "AccessibleAnnouncer deve refletir a alternância do talkback")
	var txt: String = modal._talkback_toggle.text
	if not initial:
		assert_true(txt.contains("Ligada") and txt.contains("✓"), "Deve indicar ligado com [✓]")
	else:
		assert_true(txt.contains("Desligada") and txt.contains("✕"), "Deve indicar desligado com [✕]")
	
	# Restaura
	modal._talkback_toggle.button_pressed = initial

func test_pause_modal_submodal_restores_focus():
	var modal: Control = PauseModalScene.instantiate()
	_screen.add_child(modal)
	await wait_frames(2)
	
	modal._on_colors_pressed()
	await wait_frames(2)
	assert_not_null(modal._sub_modal, "Submodal de cores deve ser instanciado")
	
	# Fecha submodal
	modal._close_sub_modal()
	await wait_frames(2)
	assert_null(modal._sub_modal, "Submodal deve ser liberado")
	assert_true(modal._colors_btn.has_focus(), "Foco deve retornar imediatamente para o botão Cores das Notas")
