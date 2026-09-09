extends GutTest

const PianoScene := preload("res://scenes/PianoInput.tscn")
# A regra de tint do ícone saiu do PianoInput e virou compartilhada; ColorDistance
# é RefCounted, não autoload, então precisa de preload.
const ColorDistance := preload("res://scripts/ColorDistance.gd")

func _make() -> Node:
	var p = PianoScene.instantiate()
	add_child_autofree(p)
	return p

func before_each():
	ColorSchemeSettings.reset_to_defaults()

func after_each():
	CueSettings.set_level(0)
	ColorSchemeSettings.reset_to_defaults()

func test_twelve_buttons_created():
	var p = _make()
	assert_eq(p._buttons.size(), 12)

func test_button_notes_match_note_mapping_order():
	var p = _make()
	assert_eq(p._button_notes, NoteMapping.NOTES.keys())

func test_button_press_emits_note_triggered_for_movement_note():
	var p = _make()
	watch_signals(p)
	var idx = p._button_notes.find("D4")
	p._buttons[idx].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["D4"])

func test_button_press_emits_note_triggered_for_action_note():
	var p = _make()
	watch_signals(p)
	var idx = p._button_notes.find("A4")
	p._buttons[idx].pressed.emit()
	assert_signal_emitted_with_parameters(p, "note_triggered", ["A4"])

func test_level_zero_shows_name_and_color():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, NoteMapping.label_for("C4"))
	# A cor da nota vai no bg_color da tecla (fundo), não num tint do nó (que
	# multiplicaria o texto do label também, matando o contraste) -- ver I1.
	# O tint neutro fica em self_modulate, não em modulate: modulate se propaga
	# pros filhos e tingiria o ícone da tecla junto.
	assert_eq(p._buttons[idx].self_modulate, Color.WHITE)
	assert_eq(p._buttons[idx].modulate, Color.WHITE, "modulate tem que ficar neutro: ele se propaga pro ícone filho")
	var sb = p._buttons[idx].get_theme_stylebox("normal")
	assert_eq(sb.bg_color, NoteMapping.color_for("C4"))

func test_keys_are_authentic_when_painting_is_off():
	# Quem manda na pintura das teclas é ColorSchemeSettings, não o nível de
	# pista: antes estes dois testes desligavam a cor subindo pro nível 3, o que
	# amarrava "teclado autêntico" a "esconder o nome da nota".
	CueSettings.set_level(0)
	ColorSchemeSettings.set_paints_piano(false)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].self_modulate, Color.WHITE)
	assert_eq(p._buttons[idx].modulate, Color.WHITE, "modulate tem que ficar neutro: ele se propaga pro ícone filho")
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, p.WHITE_KEY_COLOR)

func test_black_key_is_authentic_when_painting_is_off():
	CueSettings.set_level(0)
	ColorSchemeSettings.set_paints_piano(false)
	var p = _make()
	var idx = p._button_notes.find("Cs4")
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, p.BLACK_KEY_COLOR)

func test_painting_is_independent_of_the_cue_level():
	# Nível de pista máximo com pintura ligada: some o NOME, fica a COR.
	CueSettings.set_level(3)
	ColorSchemeSettings.set_paints_piano(true)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, "", "o nome continua sendo assunto do nível de pista")
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, NoteMapping.color_for("C4"))

func test_names_still_disappear_with_the_cue_level_while_painting_stays_off():
	# O outro cruzamento: pintura desligada não pode ressuscitar o rótulo.
	CueSettings.set_level(3)
	ColorSchemeSettings.set_paints_piano(false)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._buttons[idx].text, "")
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, p.WHITE_KEY_COLOR)

func test_toggling_repaints_without_restarting():
	CueSettings.set_level(0)
	var p = _make()
	var antes = p._buttons[0].get_theme_stylebox("normal").bg_color
	ColorSchemeSettings.set_paints_piano(false)
	assert_ne(p._buttons[0].get_theme_stylebox("normal").bg_color, antes,
		"desligar a pintura tem que repintar na hora, sem reiniciar a fase")

func test_on_armed_state_changed_brightens_correr_button():
	# No nível 0, quem clareia com o armed é o bg_color da tecla (não mais o
	# tint do nó, que agora fica fixo em Color.WHITE -- ver I1).
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("As4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(true, false)
	assert_gt(p._buttons[idx].get_theme_stylebox("normal").bg_color.get_luminance(), base.get_luminance(), "armed brighten")

func test_on_armed_state_changed_brightens_pular_button():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("B4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(false, true)
	assert_gt(p._buttons[idx].get_theme_stylebox("normal").bg_color.get_luminance(), base.get_luminance(), "armed brighten")

func test_disarm_restores_modulate_to_cue_base():
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("As4")
	var base = p._buttons[idx].get_theme_stylebox("normal").bg_color
	p.on_armed_state_changed(true, false)
	p.on_armed_state_changed(false, false)
	assert_eq(p._buttons[idx].get_theme_stylebox("normal").bg_color, base, "bg_color volta ao base após disarm")

func test_pressed_stylebox_is_darker_than_normal():
	# Apertar uma tecla precisa mudar visualmente algo (feedback de toque) --
	# antes, normal/hover/pressed compartilhavam o MESMO StyleBoxFlat. Ver I3.
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("C4")
	var normal_color = p._buttons[idx].get_theme_stylebox("normal").bg_color
	var pressed_color = p._buttons[idx].get_theme_stylebox("pressed").bg_color
	# Luminância, não canal a canal: numa paleta onde a nota tem canal zerado
	# (o Dó do esquema Pedagógico é #9C000A, com G=0), escurecer 0 dá 0 e a
	# asserção por canal quebraria sem nada estar errado no jogo.
	assert_lt(pressed_color.get_luminance(), normal_color.get_luminance(),
		"pressed deve ser mais escuro que normal")

func test_focus_stylebox_override_is_not_set():
	# O indicador de foco (navegação por teclado/acessibilidade) some se a
	# gente sobrescrever "focus" com uma stylebox sem borda -- não sobrescrever
	# deixa o tema padrão do Godot desenhar o indicador. Ver I3.
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_false(p._buttons[idx].has_theme_stylebox_override("focus"),
		"focus não deveria ter override -- deixa o tema padrão desenhar o indicador de foco")

func test_key_positions_match_real_keyboard_layout():
	var p = _make()
	var idx_c4 = p._button_notes.find("C4")
	var idx_d4 = p._button_notes.find("D4")
	var idx_cs4 = p._button_notes.find("Cs4")
	assert_eq(p._buttons[idx_c4].position.x, 0.0)
	assert_eq(p._buttons[idx_d4].position.x, 96.0)
	assert_eq(p._buttons[idx_cs4].position.x, 66.0)

func test_black_keys_drawn_on_top_of_white_keys():
	var p = _make()
	var idx_cs4 = p._button_notes.find("Cs4")
	var black_child_index = p._buttons[idx_cs4].get_index()
	for note in ["C4", "D4"]:
		var white_child_index = p._buttons[p._button_notes.find(note)].get_index()
		assert_gt(black_child_index, white_child_index, "tecla preta deve ser filha posterior (desenhada por cima)")

func test_each_key_has_an_icon():
	var p = _make()
	assert_eq(p._key_icons.size(), 12, "um ícone por tecla")
	for icon in p._key_icons:
		assert_not_null(icon._texture, "tecla sem ícone")

func test_key_icon_scales_with_the_key():
	# 24px fixo foi dimensionado pra tecla antiga de 54x160: numa tecla de
	# 96x280 o glifo ficava com ~17px, pequeno demais pro público-alvo
	# (idoso com baixa visão) -- justo a motivação de ter ícone.
	var p = _make()
	var white = p._key_icons[p._button_notes.find("C4")]
	var black = p._key_icons[p._button_notes.find("Cs4")]
	assert_eq(white.size.x, minf((p.WHITE_KEY_WIDTH - 2.0) * 0.5, p.ICON_MAX_SIDE),
		"ícone da tecla branca deve ser metade da largura da tecla (com teto)")
	assert_eq(black.size.x, p.BLACK_KEY_WIDTH * 0.5,
		"ícone da tecla preta deve ser metade da largura da tecla")
	assert_gt(white.size.x, black.size.x, "tecla maior, ícone maior")

func test_key_icons_fit_inside_their_keys():
	# O Control da tecla não faz clip: ícone que vaza da tecla vaza pra tela.
	var p = _make()
	for i in range(p._buttons.size()):
		var btn = p._buttons[i]
		var icon = p._key_icons[i]
		var note = p._button_notes[i]
		assert_between(icon.position.x, 0.0, btn.size.x - icon.size.x, "ícone de %s vaza em X" % note)
		assert_between(icon.position.y, 0.0, btn.size.y - icon.size.y, "ícone de %s vaza em Y" % note)

func test_key_icon_is_below_the_label():
	# O rótulo de texto do Button fica centrado verticalmente; o ícone mora no
	# rodapé da tecla justamente pra não disputar espaço com ele.
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_gt(p._key_icons[idx].position.y, p._buttons[idx].size.y * 0.5,
		"ícone deve ficar abaixo do centro da tecla, onde mora o rótulo")

func test_icon_tint_is_dark_on_light_key():
	# Ícone branco sobre tecla branca dá contraste ~1.25:1 -- abaixo do mínimo
	# 3:1 do WCAG pra elemento gráfico, ou seja, a redundância visual que o
	# ícone existe pra dar simplesmente não acontecia.
	CueSettings.set_level(0)
	ColorSchemeSettings.set_paints_piano(false)
	var p = _make()
	var idx = p._button_notes.find("C4")
	assert_eq(p._key_icons[idx]._tint, ColorDistance.ICON_DARK, "tecla branca pede ícone escuro")

func test_icon_tint_is_white_on_dark_key():
	CueSettings.set_level(0)
	ColorSchemeSettings.set_paints_piano(false)
	var p = _make()
	var idx = p._button_notes.find("Cs4")
	assert_eq(p._key_icons[idx]._tint, Color.WHITE, "tecla preta pede ícone branco")

func test_icon_tint_follows_note_color_luminance():
	# No nível 0 o fundo é a cor da nota, então o tint tem que variar nota a nota.
	# Os hexadecimais citados aqui eram os do Clássico, mas o esquema padrão é o
	# Pedagógico: as asserções passavam por acaso, documentando cores que o teste
	# não estava usando. O esquema agora é escolhido explicitamente.
	CueSettings.set_level(0)
	ColorSchemeSettings.set_scheme("pedagogico")
	var p = _make()
	assert_eq(NoteMapping.color_for("E4"), Color("#FFF200"), "pré-condição: o Mi é o amarelo claro")
	assert_eq(NoteMapping.color_for("C4"), Color("#9C000A"), "pré-condição: o Dó é o vermelho escuro")
	assert_eq(p._key_icons[p._button_notes.find("E4")]._tint, ColorDistance.ICON_DARK,
		"fundo claro (#FFF200) pede ícone escuro")
	assert_eq(p._key_icons[p._button_notes.find("C4")]._tint, Color.WHITE,
		"fundo escuro (#9C000A) pede ícone branco")

func test_keys_repaint_when_scheme_changes():
	# Trocar de esquema tem que repintar sem reiniciar a fase.
	CueSettings.set_level(0)
	var p = _make()
	var idx = p._button_notes.find("C4")
	# A cor da nota mora no bg_color da stylebox (o modulate fica neutro de
	# propósito, senão tingiria o ícone filho junto -- ver I1 do Plano A).
	var antes = p._buttons[idx].get_theme_stylebox("normal").bg_color
	ColorSchemeSettings.set_scheme("alto_contraste")
	var depois = p._buttons[idx].get_theme_stylebox("normal").bg_color
	assert_ne(depois, antes, "as teclas deveriam repintar ao trocar de esquema")
	assert_eq(depois, Color("#0D4A74"), "deveria pintar com a cor do esquema novo")
