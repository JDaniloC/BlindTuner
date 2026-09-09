extends GutTest

const SettingsScript := preload("res://scripts/ColorSchemeSettings.gd")

func _make():
	var s = SettingsScript.new()
	add_child_autofree(s)
	return s

func test_default_scheme_is_pedagogico():
	var s = _make()
	assert_eq(s.scheme_id, "pedagogico")

func test_set_scheme_emits_signal():
	var s = _make()
	watch_signals(s)
	s.set_scheme("alto_contraste")
	assert_signal_emitted_with_parameters(s, "scheme_changed", ["alto_contraste"])

func test_set_unknown_scheme_is_ignored():
	var s = _make()
	s.set_scheme("inexistente")
	assert_eq(s.scheme_id, "pedagogico")

func test_color_for_returns_scheme_color():
	var s = _make()
	s.set_scheme("alto_contraste")
	assert_eq(s.color_for("C4"), Color("#0D4A74"))

func test_custom_scheme_uses_edited_colors():
	var s = _make()
	s.set_scheme("personalizado")
	s.set_custom_color(0, Color("#123456"))
	assert_eq(s.color_for("C4"), Color("#123456"))

func test_custom_starts_as_a_copy_of_the_previous_scheme():
	# Entrar no editor não pode começar do zero/preto -- parte do que já estava.
	var s = _make()
	s.set_scheme("alto_contraste")
	s.set_scheme("personalizado")
	assert_eq(s.color_for("C4"), Color("#0D4A74"))

func test_set_custom_color_out_of_range_is_ignored():
	var s = _make()
	s.set_scheme("personalizado")
	s.set_custom_color(99, Color.RED)
	s.set_custom_color(-1, Color.RED)
	assert_eq(s.custom_colors().size(), 12)

func test_reset_to_defaults_restores_scheme_and_custom_colors():
	var s = _make()
	s.set_scheme("personalizado")
	s.set_custom_color(0, Color("#123456"))
	s.reset_to_defaults()
	assert_eq(s.scheme_id, "pedagogico")
	s.set_scheme("personalizado")
	assert_ne(s.color_for("C4"), Color("#123456"), "cores personalizadas deveriam ter sido zeradas")

func test_save_and_load_round_trip():
	var s = _make()
	s.set_scheme("personalizado")
	s.set_custom_color(0, Color("#123456"))
	s.save_to_disk()

	var outro = _make()
	assert_true(outro.load_from_disk())
	assert_eq(outro.scheme_id, "personalizado")
	assert_eq(outro.color_for("C4"), Color("#123456"))

	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.CONFIG_PATH))

func test_load_missing_file_returns_false_and_keeps_defaults():
	var s = _make()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.CONFIG_PATH))
	assert_false(s.load_from_disk(), "arquivo ausente não é erro, só não carrega")
	assert_eq(s.scheme_id, "pedagogico")

func test_load_invalid_palette_does_not_apply_half_of_it():
	# Meia paleta salva (corrupção/versão antiga) não pode virar estado ativo.
	var s = _make()
	var cfg = ConfigFile.new()
	cfg.set_value("cor", "scheme_id", "personalizado")
	cfg.set_value("cor", "custom", [Color.RED, Color.BLUE])  # só 2 de 12
	cfg.save(s.CONFIG_PATH)
	assert_false(s.load_from_disk())
	assert_eq(s.scheme_id, "pedagogico")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.CONFIG_PATH))
