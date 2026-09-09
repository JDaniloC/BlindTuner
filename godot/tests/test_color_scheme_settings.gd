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

func test_peeking_at_custom_does_not_freeze_the_palette():
	# Regressão: bastava SELECIONAR "Personalizado" no dropdown uma vez para as 12
	# cores serem semeadas, e a partir daí a semente nunca mais mudava -- não havia
	# como começar uma paleta personalizada a partir de outro esquema sem
	# "Restaurar tudo ao padrão".
	var s = _make()
	s.set_scheme("personalizado")   # só espiando, sem editar nada
	s.set_scheme("alto_contraste")
	s.set_scheme("personalizado")
	assert_eq(s.color_for("C4"), Color("#0D4A74"),
		"sem edição nenhuma, o editor tem que partir do esquema que estava ativo")

func test_peeking_at_custom_does_not_freeze_the_palette_across_boots():
	# O mesmo beco sem saída, agora atravessando o disco: a espiada era gravada.
	var s = _make()
	s.set_scheme("personalizado")   # espiou
	s.set_scheme("alto_contraste")
	assert_true(s.save_to_disk())

	var outro = _make()
	assert_true(outro.load_from_disk())
	outro.set_scheme("personalizado")
	assert_eq(outro.color_for("C4"), Color("#0D4A74"),
		"a espiada gravada em disco não pode congelar a semente para sempre")

func test_edited_colors_are_never_reseeded_by_visiting_another_scheme():
	# O outro lado da moeda: quem editou de verdade não perde nada ao dar uma
	# olhada em outro esquema e voltar.
	var s = _make()
	s.set_scheme("personalizado")
	s.set_custom_color(0, Color("#123456"))
	s.set_scheme("classico")
	s.set_scheme("personalizado")
	assert_eq(s.color_for("C4"), Color("#123456"),
		"cor editada pelo jogador não pode ser sobrescrita pela semente")

func test_legacy_file_without_the_flag_keeps_a_hand_made_palette():
	# Arquivos gravados antes de "custom_editada" existir não dizem se as cores
	# foram editadas. Uma paleta que NÃO bate com nenhum esquema de fábrica só
	# pode ter saído da mão do jogador.
	var cores: Array[Color] = ColorSchemes.colors_for("pedagogico")
	cores[0] = Color("#123456")
	var cfg = ConfigFile.new()
	cfg.set_value("cor", "scheme_id", "alto_contraste")
	cfg.set_value("cor", "custom", cores)
	cfg.save(TEST_PATH)

	var s = _make()
	assert_true(s.load_from_disk())
	s.set_scheme("personalizado")
	assert_eq(s.color_for("C4"), Color("#123456"), "paleta feita à mão não pode ser descartada")

func test_legacy_file_with_a_stock_palette_counts_as_never_edited():
	# Mesma situação, paleta idêntica ao Pedagógico de fábrica: é a assinatura da
	# espiada, não de trabalho manual.
	var cfg = ConfigFile.new()
	cfg.set_value("cor", "scheme_id", "alto_contraste")
	cfg.set_value("cor", "custom", ColorSchemes.colors_for("pedagogico"))
	cfg.save(TEST_PATH)

	var s = _make()
	assert_true(s.load_from_disk())
	s.set_scheme("personalizado")
	assert_eq(s.color_for("C4"), Color("#0D4A74"),
		"paleta igualzinha a um esquema de fábrica não é trabalho do jogador")

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

# --- Pistas nos controles: escolha própria, não efeito do nível de pista ------

func test_control_cues_default_to_on():
	var s = _make()
	assert_true(s.shows_control_cues(),
		"sem escolha do jogador, o material didático dos controles fica ligado")

func test_set_control_cues_emits_its_own_signal():
	# Sinal próprio, não scheme_changed: um teste existente assere os parâmetros
	# daquele sinal, e "mudou a paleta" não é "mudaram as pistas".
	var s = _make()
	watch_signals(s)
	s.set_control_cues(false)
	assert_signal_emitted_with_parameters(s, "control_cues_changed", [false])

func test_set_control_cues_is_silent_when_nothing_changes():
	var s = _make()
	watch_signals(s)
	s.set_control_cues(true)  # já era true
	assert_signal_not_emitted(s, "control_cues_changed")

func test_control_cues_preference_survives_a_round_trip():
	var s = _make()
	s.set_control_cues(false)
	assert_true(s.save_to_disk())

	var outro = _make()
	assert_true(outro.load_from_disk())
	assert_false(outro.shows_control_cues(), "a escolha é ajuste de acessibilidade: tem que persistir")

func test_the_disk_key_is_still_pinta_piano():
	# A preferência foi generalizada de "pinta o piano" para "pistas em todos os
	# controles", mas a CHAVE em disco não pode mudar: renomeá-la faria todo
	# arquivo já gravado cair no default e o jogador perderia a escolha em
	# silêncio, no próximo boot.
	var s = _make()
	s.set_control_cues(false)
	assert_true(s.save_to_disk())

	var cfg = ConfigFile.new()
	assert_eq(cfg.load(TEST_PATH), OK)
	assert_eq(cfg.get_value("cor", "pinta_piano", true), false,
		"a chave herdada é load-bearing para quem já jogou")

func test_missing_cues_key_keeps_the_default_without_discarding_the_palette():
	# Chave ausente é o caso NORMAL: todo arquivo gravado antes desta versão não a
	# tem. Abortar a carga por causa dela apagaria a paleta personalizada do
	# jogador -- exatamente a classe de bug que já custou caro aqui.
	var s = _make()
	var cfg = ConfigFile.new()
	cfg.set_value("cor", "scheme_id", "personalizado")
	cfg.set_value("cor", "custom", ColorSchemes.colors_for("pedagogico"))
	cfg.save(TEST_PATH)

	assert_true(s.load_from_disk(), "chave ausente não pode invalidar o arquivo")
	assert_true(s.shows_control_cues())
	assert_eq(s.scheme_id, "personalizado")

func test_corrupted_cues_key_falls_back_to_the_default_without_failing_the_load():
	# Tipo errado também só cai no default -- nunca `return false`, que
	# descartaria a paleta personalizada junto.
	var s = _make()
	var cfg = ConfigFile.new()
	cfg.set_value("cor", "scheme_id", "alto_contraste")
	cfg.set_value("cor", "pinta_piano", "talvez")
	cfg.save(TEST_PATH)

	assert_true(s.load_from_disk())
	assert_true(s.shows_control_cues())
	assert_eq(s.scheme_id, "alto_contraste")

func test_reset_to_defaults_restores_the_control_cues_preference():
	# Contrato de "estado global zerado" de que a suíte inteira depende: quem
	# desliga as pistas num teste não pode contaminar o próximo.
	var s = _make()
	s.set_control_cues(false)
	watch_signals(s)
	s.reset_to_defaults()
	assert_true(s.shows_control_cues())
	assert_signal_emitted_with_parameters(s, "control_cues_changed", [true])

func test_autoload_points_at_the_real_config_path():
	# Prova que a redireção usada pelos testes não vazou para o jogo: o autoload
	# de verdade continua lendo e gravando o arquivo do jogador.
	assert_eq(ColorSchemeSettings.config_path, ColorSchemeSettings.CONFIG_PATH)

func test_autoload_is_registered_under_the_node_path_the_boot_guard_expects():
	# _ready() só chama load_from_disk() quando get_path() bate com este caminho
	# exato -- é o que impede as instâncias de teste de lerem o arquivo do
	# jogador. Renomear o autoload em project.godot faria o jogo abrir sempre no
	# Pedagógico, em silêncio, com a suíte verde.
	assert_eq(ColorSchemeSettings.get_path(), ^"/root/ColorSchemeSettings",
		"o nome do autoload em project.godot é load-bearing para a carga no boot")
