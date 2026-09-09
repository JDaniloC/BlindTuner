extends GutTest

const SettingsScript := preload("res://scripts/ColorSchemeSettings.gd")

## NUNCA usar ColorSchemeSettings.CONFIG_PATH aqui: a suíte gravava e apagava o
## user://color_scheme.cfg REAL, então rodar os testes destruía a paleta de quem
## joga na mesma máquina. Cada teste aponta para este arquivo próprio.
const TEST_PATH := "user://test_color_scheme.cfg"

func _make():
	var s = SettingsScript.new()
	add_child_autofree(s)
	s.config_path = TEST_PATH
	return s

func _limpar():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

func before_each():
	_limpar()

func after_each():
	_limpar()

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

func test_saving_does_not_seed_the_custom_palette():
	# Regressão: custom_colors() semeava _custom como efeito colateral e
	# save_to_disk() o chamava. Como a tela salva a cada troca de esquema, a
	# semente do "Personalizado" congelava no PRIMEIRO esquema salvo, e o editor
	# passava a abrir de um esquema que o jogador nem estava vendo.
	var s = _make()
	s.set_scheme("alto_contraste")
	s.save_to_disk()
	s.set_scheme("classico")
	s.save_to_disk()
	s.set_scheme("personalizado")
	assert_eq(s.color_for("C4"), NoteMapping.default_color_for("C4"),
		"o editor deve partir do Clássico, que era o esquema ativo na hora")

func test_custom_colors_is_a_pure_getter():
	var s = _make()
	assert_eq(s.custom_colors().size(), 0, "sem personalização, não inventa paleta")
	var copia = s.custom_colors()
	copia.append(Color.RED)
	assert_eq(s.custom_colors().size(), 0, "mutar a cópia não pode afetar o estado interno")

func test_active_palette_reflects_the_current_scheme():
	var s = _make()
	s.set_scheme("alto_contraste")
	var p = s.active_palette()
	assert_eq(p.size(), 12)
	assert_eq(p[0], Color("#0D4A74"))

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
	assert_true(s.save_to_disk(), "salvar deveria reportar sucesso")

	var outro = _make()
	assert_true(outro.load_from_disk())
	assert_eq(outro.scheme_id, "personalizado")
	assert_eq(outro.color_for("C4"), Color("#123456"))

func test_custom_palette_survives_when_saved_under_a_fixed_scheme():
	# Regressão do pior defeito da leva: save_to_disk() sempre gravava a paleta
	# personalizada, mas load_from_disk() só a restaurava se o esquema salvo
	# fosse "personalizado". Quem editasse as 12 cores e desse uma espiada em
	# outro esquema antes de fechar o jogo perdia tudo no próximo boot -- com as
	# cores intactas no arquivo.
	var s = _make()
	s.set_scheme("personalizado")
	s.set_custom_color(0, Color("#123456"))
	s.set_scheme("alto_contraste")  # só olhando outro esquema
	s.save_to_disk()

	var outro = _make()
	assert_true(outro.load_from_disk())
	assert_eq(outro.scheme_id, "alto_contraste", "o esquema ativo salvo é respeitado")
	outro.set_scheme("personalizado")
	assert_eq(outro.color_for("C4"), Color("#123456"),
		"a paleta personalizada tem que voltar, não ser re-semeada do esquema fixo")

func test_load_missing_file_returns_false_and_keeps_defaults():
	var s = _make()
	assert_false(s.load_from_disk(), "arquivo ausente não é erro, só não carrega")
	assert_eq(s.scheme_id, "pedagogico")

func test_load_invalid_palette_does_not_apply_half_of_it():
	# Meia paleta salva (corrupção/versão antiga) não pode virar estado ativo.
	var s = _make()
	var cfg = ConfigFile.new()
	cfg.set_value("cor", "scheme_id", "personalizado")
	cfg.set_value("cor", "custom", [Color.RED, Color.BLUE])  # só 2 de 12
	cfg.save(TEST_PATH)
	assert_false(s.load_from_disk())
	assert_eq(s.scheme_id, "pedagogico")

func test_load_corrupted_types_returns_false_instead_of_crashing():
	# Arquivo parseável mas com tipos errados derrubava o boot com erro de
	# atribuição de tipo em vez de degradar para o padrão.
	var s = _make()
	var cfg = ConfigFile.new()
	cfg.set_value("cor", "scheme_id", 42)          # número onde se espera texto
	cfg.set_value("cor", "custom", "não é array")  # texto onde se espera array
	cfg.save(TEST_PATH)
	assert_false(s.load_from_disk())
	assert_eq(s.scheme_id, "pedagogico")

func test_load_unknown_scheme_id_returns_false():
	var s = _make()
	var cfg = ConfigFile.new()
	cfg.set_value("cor", "scheme_id", "esquema_de_outra_versao")
	cfg.save(TEST_PATH)
	assert_false(s.load_from_disk())
	assert_eq(s.scheme_id, "pedagogico")

func test_autoload_points_at_the_real_config_path():
	# Prova que a redireção usada pelos testes não vazou para o jogo: o autoload
	# de verdade continua lendo e gravando o arquivo do jogador.
	assert_eq(ColorSchemeSettings.config_path, ColorSchemeSettings.CONFIG_PATH)
