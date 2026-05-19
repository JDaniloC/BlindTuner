extends SceneTree
## Gera res://assets/ui/blindtuner_theme.tres a partir dos sprites flat.
## Rodar: godot --headless --path godot --script res://tools/build_ui_theme.gd

func _init() -> void:
	var base := "res://assets/ui/flat/"
	var dark := Color(0.16, 0.13, 0.10)
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
	theme.set_color("font_color", "Button", dark)

	var opt_sb := StyleBoxTexture.new()
	opt_sb.texture = load(base + "UI_Flat_InputField01a.png")
	opt_sb.texture_margin_left = 12.0
	opt_sb.texture_margin_right = 12.0
	opt_sb.texture_margin_top = 8.0
	opt_sb.texture_margin_bottom = 8.0
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		theme.set_stylebox(state, "OptionButton", opt_sb)
	theme.set_icon("arrow", "OptionButton", load(base + "UI_Flat_IconArrow01a.png"))
	theme.set_color("font_color", "OptionButton", dark)

	var panel_sb := StyleBoxTexture.new()
	panel_sb.texture = load(base + "UI_Flat_Frame01a.png")
	panel_sb.set_texture_margin_all(16.0)
	theme.set_stylebox("panel", "PanelContainer", panel_sb)

	theme.set_color("font_color", "Label", dark)

	var err := ResourceSaver.save(theme, "res://assets/ui/blindtuner_theme.tres")
	if err != OK:
		push_error("theme save falhou: %d" % err)
		quit(1)
		return
	print("THEME_BUILD_OK")
	quit(0)
