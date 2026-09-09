extends GutTest

const THEME_PATH := "res://assets/ui/blindtuner_theme.tres"

var t: Theme

func before_all() -> void:
	t = load(THEME_PATH)

func test_theme_resource_loads():
	assert_not_null(t, "theme deve carregar")
	assert_true(t is Theme, "deve ser um Theme")

func test_theme_has_button_styleboxes():
	for s in ["normal", "hover", "pressed", "disabled"]:
		assert_true(t.has_stylebox(s, "Button"), "Button/%s" % s)
		var sb := t.get_stylebox(s, "Button") as StyleBoxTexture
		assert_not_null(sb, "Button/%s deve ser StyleBoxTexture" % s)
		assert_not_null(sb.texture, "Button/%s texture" % s)

func test_theme_has_optionbutton_styleboxes_and_arrow():
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		assert_true(t.has_stylebox(s, "OptionButton"), "OptionButton/%s" % s)
	assert_true(t.has_icon("arrow", "OptionButton"), "OptionButton/arrow")

func test_theme_has_panelcontainer_stylebox():
	assert_true(t.has_stylebox("panel", "PanelContainer"), "PanelContainer/panel")
	var sb := t.get_stylebox("panel", "PanelContainer") as StyleBoxTexture
	assert_not_null(sb, "PanelContainer/panel deve ser StyleBoxTexture")
	assert_not_null(sb.texture, "PanelContainer/panel texture")

func test_gamehud_has_theme_applied():
	var h = preload("res://scenes/GameHUD.tscn").instantiate()
	add_child_autofree(h)
	assert_eq(h.theme, load(THEME_PATH), "GameHUD.theme deve ser o blindtuner_theme")

func test_notepanel_has_theme_applied():
	var p = preload("res://scenes/NotePanel.tscn").instantiate()
	add_child_autofree(p)
	assert_eq(p.theme, load(THEME_PATH), "NotePanel.theme deve ser o blindtuner_theme")

# O fundo do joystick é procedural (disco + anel) em $Slices, atrás das fatias.
func test_joystick_has_procedural_backdrop():
	var j = preload("res://scenes/DirectionJoystick.tscn").instantiate()
	add_child_autofree(j)
	assert_null(j.get_node_or_null("Frame"), "Frame removido")
	assert_not_null(j._backdrop_disc, "backdrop disc não-nulo")
	assert_true(j._backdrop_disc is Polygon2D, "disc é Polygon2D")
	assert_not_null(j._backdrop_ring, "backdrop ring não-nulo")
	assert_true(j._backdrop_ring is Line2D, "ring é Line2D")
	var slices = j.get_node("Slices")
	assert_eq(slices.get_child(0), j._backdrop_disc, "disc desenha primeiro (índice 0)")
	assert_eq(slices.get_child(1), j._backdrop_ring, "ring índice 1")
	assert_eq(j._slice_polygons.size(), 8, "_slice_polygons só as 8 fatias de movimento (backdrop fora)")

func test_theme_font_color_is_dark():
	for ty in ["Button", "OptionButton", "Label"]:
		assert_true(t.has_color("font_color", ty), "%s/font_color definido" % ty)
		var c: Color = t.get_color("font_color", ty)
		assert_true(c.get_luminance() < 0.5, "%s/font_color deve ser escuro" % ty)
		assert_eq(c, Color(0.16, 0.13, 0.10), "%s/font_color valor exato" % ty)

func test_gamehud_layout_uses_containers():
	var h = preload("res://scenes/GameHUD.tscn").instantiate()
	add_child_autofree(h)
	assert_eq(h.anchor_right, 1.0, "GameHUD root anchor_right=1.0 (preenche viewport)")
	assert_eq(h.anchor_bottom, 1.0, "GameHUD root anchor_bottom=1.0 (preenche viewport)")
	assert_true(h._stats_panel.get_parent() is CenterContainer,
		"_stats_panel deve estar sob CenterContainer")
	# _progress divide a SEGUNDA linha com o botão "Cores" -- na primeira, os 5
	# controles deixavam 7px de folga em 720px de largura.
	assert_true(h._progress.get_parent() is HBoxContainer,
		"_progress deve estar sob a HBox da segunda linha")
	assert_true(h._progress.get_parent().get_parent() is VBoxContainer,
		"a segunda linha deve estar sob o VBoxContainer do topo")
	assert_true(h._preset_opt.get_parent() is HBoxContainer,
		"_preset_opt deve estar sob HBoxContainer")

func test_gamehud_stats_overlay_does_not_block_input():
	var h = preload("res://scenes/GameHUD.tscn").instantiate()
	add_child_autofree(h)
	var center = h._stats_panel.get_parent()
	assert_eq(center.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"overlay full-rect dos stats não pode capturar input (bloqueava botões/joystick)")
