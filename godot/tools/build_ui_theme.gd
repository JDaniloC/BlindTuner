extends SceneTree
## Gera res://assets/ui/blindtuner_theme.tres a partir dos sprites flat.
## Rodar: godot --headless --path godot --script res://tools/build_ui_theme.gd

## Tinta do texto. O tema só definia `font_color` -- os outros CINCO estados
## caíam no tema padrão do Godot, que foi desenhado para skin ESCURA e por isso
## usa tinta quase branca (#F2F2F2, #FFFFFF, #DFDFDF). Como as texturas do pack
## flat são quase brancas (#FFFDF5 no miolo das quatro), o resultado era branco
## sobre branco: 1,02:1 a 1,14:1 em 29 botões e dropdowns.
##
## Uma entrada em "Button" alcança OptionButton, CheckButton e CheckBox pela
## cadeia de tipos do Godot -- por isso a correção mora aqui e não em override
## por nó. test_ui_contrast_sweep.gd mede isso na UI real, estado por estado.
const DARK := Color(0.16, 0.13, 0.10)
## Desabilitado: escurece menos, mas continua legível. O padrão do Godot
## (#DFDFDF com alfa 0,50) dava 1,14:1. Este valor mede 8,96:1 sobre #FFFDF5 e
## torna redundante o override pontual que ColorSchemeScreen carregava.
const DARK_MUTED := Color(0.30, 0.28, 0.26)
## Superfície clara do pack (miolo de UI_Flat_InputField01a / Button01a).
const SURFACE := Color(1.0, 0.992, 0.961)

## A lista do OptionButton é uma Window separada: não herda o tema pela árvore e
## por isso abria no escuro padrão do Godot. Ela FICA escura de propósito -- o
## normal já media 7,82:1 e clarear o painel apagaria os ícones de rádio/check do
## tema padrão, que são claros e não temos substituto pra eles. O que se conserta
## aqui são os dois estados que reprovavam: hover (4,31:1) e disabled (1,61:1).
const POPUP_PANEL := Color(0.118, 0.102, 0.082)
## Ajustado para Color(0.35, 0.29, 0.22): contraste 8,38:1 com SURFACE (#FFFDF5),
## superando o piso WCAG AAA (>= 7,0:1). O tom anterior (0.478, 0.400, 0.314) media 5,36:1.
const POPUP_HOVER := Color(0.35, 0.29, 0.22)
const POPUP_MUTED := Color(0.604, 0.569, 0.518)

func _init() -> void:
	var base := "res://assets/ui/flat/"
	var theme := Theme.new()

	var btn := {
		"normal": "UI_Flat_Button01a_1.png",
		"hover": "UI_Flat_Button01a_2.png",
		"pressed": "UI_Flat_Button01a_3.png",
		"disabled": "UI_Flat_Button01a_4.png",
	}
	for state in btn:
		var sb := StyleBoxTexture.new()
		sb.texture = load(base + btn[state])
		sb.set_texture_margin_all(8.0)
		theme.set_stylebox(state, "Button", sb)
	# Os cinco estados que faltavam, mais o de repouso.
	for item in ["font_color", "font_hover_color", "font_pressed_color",
			"font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(item, "Button", DARK)
	theme.set_color("font_disabled_color", "Button", DARK_MUTED)
	# Ícone do botão (a seta de Play do "Começar"). O padrão do Godot para o
	# estado desabilitado é alfa 0,40, que sobre #FFFDF5 lava o glifo até 2,84:1
	# -- abaixo dos 3:1 de elemento gráfico.
	for item in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
			"icon_hover_pressed_color", "icon_focus_color"]:
		theme.set_color(item, "Button", Color.WHITE)
	theme.set_color("icon_disabled_color", "Button", Color(1, 1, 1, 0.8))
	# Contorno de foco. Com emulate_mouse_from_touch, tocar um botão dá foco a
	# ele e o foco FICA -- é estado de repouso, não transitório. O `focus` padrão
	# do Godot é uma borda quase branca (skin escura), invisível sobre #FFFDF5:
	# o jogador não tinha como saber qual botão estava focado.
	theme.set_stylebox("focus", "Button", _focus_ring())

	var opt_sb := StyleBoxTexture.new()
	opt_sb.texture = load(base + "UI_Flat_InputField01a.png")
	opt_sb.texture_margin_left = 12.0
	opt_sb.texture_margin_right = 12.0
	opt_sb.texture_margin_top = 8.0
	opt_sb.texture_margin_bottom = 8.0
	for state in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state, "OptionButton", opt_sb)
	# `focus` é desenhada POR CIMA da normal, não no lugar dela: repetir ali a
	# textura opaca do campo apagava qualquer sinal de foco.
	theme.set_stylebox("focus", "OptionButton", _focus_ring())
	theme.set_icon("arrow", "OptionButton", load(base + "UI_Flat_IconArrow01a.png"))
	theme.set_color("font_color", "OptionButton", DARK)

	var panel_sb := StyleBoxTexture.new()
	panel_sb.texture = load(base + "UI_Flat_Frame01a.png")
	panel_sb.set_texture_margin_all(16.0)
	theme.set_stylebox("panel", "PanelContainer", panel_sb)

	theme.set_color("font_color", "Label", DARK)

	_build_popup(theme)

	var err := ResourceSaver.save(theme, "res://assets/ui/blindtuner_theme.tres")
	if err != OK:
		push_error("theme save falhou: %d" % err)
		quit(1)
		return
	print("THEME_BUILD_OK")
	quit(0)

## Anel de foco: só borda, miolo transparente -- o fundo do estado normal
## continua aparecendo, que é como o Godot desenha `focus`.
func _focus_ring() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(3)
	sb.border_color = DARK
	sb.set_corner_radius_all(4)
	return sb

func _build_popup(theme: Theme) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = POPUP_PANEL
	panel.set_corner_radius_all(4)
	for lado in ["content_margin_left", "content_margin_top", "content_margin_right", "content_margin_bottom"]:
		panel.set(lado, 8)
	theme.set_stylebox("panel", "PopupMenu", panel)

	var hover := StyleBoxFlat.new()
	hover.bg_color = POPUP_HOVER
	hover.set_corner_radius_all(3)
	theme.set_stylebox("hover", "PopupMenu", hover)

	theme.set_color("font_color", "PopupMenu", SURFACE)
	theme.set_color("font_hover_color", "PopupMenu", SURFACE)
	theme.set_color("font_disabled_color", "PopupMenu", POPUP_MUTED)
	theme.set_color("font_separator_color", "PopupMenu", POPUP_MUTED)
	theme.set_color("font_accelerator_color", "PopupMenu", POPUP_MUTED)
