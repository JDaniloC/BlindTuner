extends GutTest
## Testes de validação da tela de vitória (VictoryModal).
## Valida o sistema de 3 estrelas categóricas (DEC-0005):
##   - Memória Resgatada
##   - Ouvido Fino
##   - Passo Firme
## Valida emissão de sinais, acessibilidade e navegabilidade por foco.

const VICTORY_MODAL_SCENE := preload("res://scenes/VictoryModal.tscn")

var _modal = null

func before_each():
	_modal = VICTORY_MODAL_SCENE.instantiate()
	add_child_autofree(_modal)

func test_modal_hierarchy_and_initial_nodes():
	assert_not_null(_modal._title_lbl, "Título deve existir")
	assert_not_null(_modal._song_lbl, "Label da música deve existir")
	assert_not_null(_modal._stars_lbl, "Label de estrelas deve existir")
	assert_not_null(_modal._badges_container, "Contêiner de badges deve existir")
	assert_not_null(_modal._story_panel, "Painel de poesia deve existir")
	assert_not_null(_modal._story_lbl, "Label da história deve existir")
	assert_not_null(_modal._stats_lbl, "Label de estatísticas deve existir")
	assert_not_null(_modal._next_btn, "Botão próximo deve existir")
	assert_not_null(_modal._retry_btn, "Botão repetir deve existir")
	assert_not_null(_modal._menu_btn, "Botão diário deve existir")

func test_display_result_three_stars_all_conquered():
	var lvl = LevelCatalog.by_id("ch1_quarto_radio")
	assert_not_null(lvl)
	
	var summary := {
		"level_id": "ch1_quarto_radio",
		"stars": 3,
		"is_new_high_score": true,
		"elapsed_sec": 14.5,
		"trips": 0,
		"wall_bumps": 0,
		"pitch_misses": 0,
		"first_try_hits": lvl.total_steps(),
		"has_next_level": true,
		"next_level_id": "ch1_lullaby_dormir"
	}
	
	_modal.display_result(lvl, summary)
	
	assert_true(_modal._title_lbl.text.contains("Afinada com Afeto"), "Título deve celebrar 3 estrelas afinadas")
	assert_eq(_modal._stars_lbl.text, "★★★", "Estrelas devem exibir 3 de 3")
	assert_true(_modal._song_lbl.visible, "Obra musical deve ser exibida")
	assert_true(_modal._song_lbl.text.contains(lvl.song_title), "Nome da obra musical deve estar presente: %s" % lvl.song_title)
	
	# Verifica 3 cartões de selos
	var badges = _modal._badges_container.get_children()
	assert_eq(badges.size(), 3, "Devem existir 3 cartões de selos categóricos")
	
	# Cada cartão deve conter o indicador de conquistada
	for b in badges:
		var txt: String = _get_card_full_text(b)
		assert_true(txt.contains("✓ Conquistada"), "Selo deve estar conquistado: %s" % txt)
	
	assert_true(_modal._next_btn.visible, "Botão próximo deve estar visível quando há próximo nível")

func test_display_result_two_stars_with_bumps():
	var lvl = LevelCatalog.by_id("ch1_quarto_radio")
	assert_not_null(lvl)
	
	# Jogador acertou todas as notas de primeira (Ouvido Fino), mas esbarrou 2 vezes (sem Passo Firme)
	var summary := {
		"level_id": "ch1_quarto_radio",
		"stars": 2,
		"is_new_high_score": false,
		"elapsed_sec": 22.0,
		"trips": 2,
		"wall_bumps": 2,
		"pitch_misses": 0,
		"first_try_hits": lvl.total_steps(),
		"has_next_level": true,
		"next_level_id": "ch1_lullaby_dormir"
	}
	
	_modal.display_result(lvl, summary)
	
	assert_eq(_modal._stars_lbl.text, "★★☆", "Estrelas devem exibir 2 de 3")
	var badges = _modal._badges_container.get_children()
	assert_eq(badges.size(), 3)
	
	# Selo 1: Memória Resgatada -> Conquistada
	assert_true(_get_card_full_text(badges[0]).contains("✓ Conquistada"))
	# Selo 2: Ouvido Fino -> Conquistada
	assert_true(_get_card_full_text(badges[1]).contains("✓ Conquistada"))
	# Selo 3: Passo Firme -> Não conquistada com detalhe de tropeços
	var step_text: String = _get_card_full_text(badges[2])
	assert_true(step_text.contains("✗ 2 tropeço(s)"), "Passo Firme deve apontar 2 tropeços: %s" % step_text)

func test_display_result_one_star_only_completion():
	var lvl = LevelCatalog.by_id("ch1_quarto_radio")
	assert_not_null(lvl)
	
	# Jogador completou, mas desafinou notas e esbarrou na parede
	var summary := {
		"level_id": "ch1_quarto_radio",
		"stars": 1,
		"is_new_high_score": false,
		"elapsed_sec": 30.0,
		"trips": 3,
		"wall_bumps": 3,
		"pitch_misses": 2,
		"first_try_hits": 1,
		"has_next_level": true,
		"next_level_id": "ch1_lullaby_dormir"
	}
	
	_modal.display_result(lvl, summary)
	
	assert_eq(_modal._stars_lbl.text, "★☆☆", "Estrelas devem exibir 1 de 3")
	var badges = _modal._badges_container.get_children()
	assert_eq(badges.size(), 3)
	
	# Selo 1: Memória Resgatada -> Conquistada
	assert_true(_get_card_full_text(badges[0]).contains("✓ Conquistada"))
	# Selo 2: Ouvido Fino -> Não conquistada
	var ear_text: String = _get_card_full_text(badges[1])
	assert_true(ear_text.contains("✗ 2 nota(s) desafinada(s)"), "Ouvido Fino deve acusar 2 desafinações: %s" % ear_text)
	# Selo 3: Passo Firme -> Não conquistada
	var step_text: String = _get_card_full_text(badges[2])
	assert_true(step_text.contains("✗ 3 tropeço(s)"), "Passo Firme deve acusar 3 tropeços: %s" % step_text)

func test_finale_level_has_no_next_button():
	var lvl = LevelCatalog.by_id("ch3_teatro_recital")
	assert_not_null(lvl)
	
	var summary := {
		"level_id": "ch3_teatro_recital",
		"stars": 3,
		"elapsed_sec": 45.0,
		"trips": 0,
		"wall_bumps": 0,
		"pitch_misses": 0,
		"first_try_hits": lvl.total_steps(),
		"has_next_level": false,
		"next_level_id": ""
	}
	
	_modal.display_result(lvl, summary)
	
	assert_false(_modal._next_btn.visible, "Botão de próximo deve ficar oculto no encerramento da campanha")

func test_buttons_emit_signals():
	watch_signals(_modal)
	
	_modal._next_btn.pressed.emit()
	assert_signal_emitted(_modal, "next_level_requested")
	
	_modal._retry_btn.pressed.emit()
	assert_signal_emitted(_modal, "restart_requested")
	
	_modal._menu_btn.pressed.emit()
	assert_signal_emitted(_modal, "level_select_requested")

func test_unhandled_input_cancel_emits_level_select():
	watch_signals(_modal)
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	_modal._unhandled_input(ev)
	assert_signal_emitted(_modal, "level_select_requested")

func _get_card_full_text(panel: PanelContainer) -> String:
	var out: String = ""
	for child in panel.find_children("", "Label", true, false):
		if child is Label:
			out += child.text + " "
	return out
