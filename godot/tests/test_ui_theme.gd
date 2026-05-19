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

# Frame.mouse_filter = IGNORE: não intercepta _gui_input. Cobertura de
# roteamento de input exigiria teste de integração com display (headless não cobre).
func test_joystick_has_frame_ninepatch():
	var j = preload("res://scenes/DirectionJoystick.tscn").instantiate()
	add_child_autofree(j)
	var f = j.get_node_or_null("Frame")
	assert_not_null(f, "Joystick deve ter um nó Frame")
	assert_true(f is NinePatchRect, "Frame deve ser NinePatchRect")
	assert_eq(f.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Frame não pode capturar input")
