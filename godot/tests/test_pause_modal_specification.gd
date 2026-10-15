extends GutTest
## Teste de especificação e conformidade técnica do PauseModal.tscn conforme handoff.

const PauseModalScene := preload("res://scenes/PauseModal.tscn")
const UI_THEME := preload("res://assets/ui/blindtuner_theme.tres")

var _screen: SubViewport
var _modal: Control

func before_each():
	_screen = SubViewport.new()
	_screen.size = Vector2i(720, 1280)
	add_child_autofree(_screen)
	_modal = PauseModalScene.instantiate()
	_screen.add_child(_modal)
	await wait_frames(2)

## -------------------------------------------------------------------------
## Cenário 1: Hierarquia de Nós e Estrutura da Cena
## -------------------------------------------------------------------------
func test_modal_hierarchy_and_node_types():
	assert_eq(_modal.process_mode, Node.PROCESS_MODE_ALWAYS, "O modal deve processar mesmo com a cena pausada")
	assert_eq(_modal.mouse_filter, Control.MOUSE_FILTER_STOP, "O modal deve absorver todos os cliques do mouse")
	
	# Verifica existência dos 6 botões canônicos
	assert_not_null(_modal._resume_btn, "Botão Retomar os Passos deve existir")
	assert_not_null(_modal._restart_btn, "Botão Recomeçar a Memória deve existir")
	assert_not_null(_modal._cues_toggle, "Toggle Pistas nos Controles deve existir")
	assert_not_null(_modal._talkback_toggle, "Toggle Voz do Narrador deve existir")
	assert_not_null(_modal._colors_btn, "Botão Cores e Contrastes deve existir")
	assert_not_null(_modal._menu_btn, "Botão Guardar Diário e Sair deve existir")

## -------------------------------------------------------------------------
## Cenário 2: Focus Trap Circular e Foco Inicial
## -------------------------------------------------------------------------
func test_focus_trap_completes_full_cycle():
	assert_true(_modal._resume_btn.has_focus(), "O foco inicial deve ser em Retomar os Passos")
	
	# Topo fecha no Menu
	assert_eq(_modal._resume_btn.focus_neighbor_top, _modal._menu_btn.get_path(),
		"O topo do botão Retomar deve apontar para o botão Sair")
	
	# Base fecha no Retomar
	assert_eq(_modal._menu_btn.focus_neighbor_bottom, _modal._resume_btn.get_path(),
		"A base do botão Sair deve apontar para o botão Retomar")
	
	# Encadeamento vertical ordenado
	assert_eq(_modal._resume_btn.focus_neighbor_bottom, _modal._restart_btn.get_path())
	assert_eq(_modal._restart_btn.focus_neighbor_bottom, _modal._cues_toggle.get_path())
	assert_eq(_modal._cues_toggle.focus_neighbor_bottom, _modal._talkback_toggle.get_path())
	assert_eq(_modal._talkback_toggle.focus_neighbor_bottom, _modal._colors_btn.get_path())
	assert_eq(_modal._colors_btn.focus_neighbor_bottom, _modal._menu_btn.get_path())

## -------------------------------------------------------------------------
## Cenário 3: Confirmação Não-Destrutiva com Foco de Segurança
## -------------------------------------------------------------------------
func test_destructive_actions_require_confirmation_with_safe_focus():
	# 1. Teste no Recomeçar
	_modal._on_restart_pressed()
	await wait_frames(2)
	assert_not_null(_modal._confirm_dialog, "Diálogo de confirmação deve ser aberto ao pedir restart")
	
	var cancel_btn: Button = _modal._confirm_dialog.find_child("CancelBtn", true, false)
	assert_not_null(cancel_btn, "Botão cancelar deve existir no diálogo")
	assert_true(cancel_btn.has_focus(), "O foco de segurança DEVE estar no botão Cancelar/Continuar")
	
	# Cancela e verifica retorno
	_modal._close_confirm_dialog()
	await wait_frames(2)
	assert_null(_modal._confirm_dialog, "Diálogo deve ser liberado após cancelar")
	assert_true(_modal._resume_btn.has_focus(), "Foco deve retornar para o botão Retomar")

## -------------------------------------------------------------------------
## Cenário 4: Submodal de Cores Restaura o Foco de Origem
## -------------------------------------------------------------------------
func test_submodal_colors_preserves_focus_origin():
	_modal._on_colors_pressed()
	await wait_frames(2)
	assert_not_null(_modal._sub_modal, "Submodal de cores deve ser montado")
	
	_modal._close_sub_modal()
	await wait_frames(2)
	assert_null(_modal._sub_modal, "Submodal de cores deve ser destruído ao fechar")
	assert_true(_modal._colors_btn.has_focus(), "O foco DEVE retornar ao botão Cores e Contrastes")

## -------------------------------------------------------------------------
## Cenário 5: Tamanho do Alvo de Toque e Acessibilidade (Touch Target Size)
## -------------------------------------------------------------------------
func test_buttons_satisfy_touch_target_minimums():
	var buttons = [
		_modal._resume_btn, _modal._restart_btn, _modal._cues_toggle,
		_modal._talkback_toggle, _modal._colors_btn, _modal._menu_btn
	]
	for btn in buttons:
		assert_gte(btn.custom_minimum_size.y, 48.0,
			"Botão %s possui altura de %.1fpx, abaixo dos 48px recomendados" % [btn.text, btn.custom_minimum_size.y])
