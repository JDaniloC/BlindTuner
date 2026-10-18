extends GutTest

func test_all_maps_exist():
    assert_eq(MapPresets.ALL.size(), 36)

func test_all_maps_have_unique_ids():
    var seen := {}
    for m in MapPresets.ALL:
        assert_false(seen.has(m.id), "id duplicado: %s" % m.id)
        seen[m.id] = true

func test_known_map_ids():
    var ids := []
    for m in MapPresets.ALL:
        ids.append(m.id)
    assert_eq(ids, [
        "quarto", "banheiro", "sala", "quarto_lullaby", "jardim_portao", "padaria_calcada", "praca_chafariz", "largo_matriz",
        "arcade_s1_vento", "arcade_s1_oculos", "arcade_s1_planta", "arcade_s1_louca",
        "arcade_s2_gato", "arcade_s2_valsa", "arcade_s2_chaves", "arcade_s2_pendulo",
        "arcade_s3_carteiro", "arcade_s3_cha", "arcade_s3_moedor", "arcade_s3_chaleira",
        "arcade_s4_vento", "arcade_s4_duo", "arcade_s4_patio", "arcade_s4_tear",
        "arcade_s5_flores", "arcade_s5_sanfona", "arcade_s5_castanholas", "arcade_s5_ancoradouro",
        "arcade_s6_igreja", "arcade_s6_orgao", "arcade_s6_tamborim", "arcade_s6_catedral",
        "praia_mirante", "estacao_plataforma", "estudio_conservatorio", "teatro_palco"
    ])

func test_all_map_themes_resolve():
    for m in MapPresets.ALL:
        assert_not_null(SceneryThemes.by_id(m.theme_id),
            "map %s referencia tema %s inexistente" % [m.id, m.theme_id])

func test_start_is_inside_size():
    for m in MapPresets.ALL:
        assert_true(m.start_grid.x >= 0 and m.start_grid.x < m.size.x,
            "%s: start.x fora de size" % m.id)
        assert_true(m.start_grid.y >= 0 and m.start_grid.y < m.size.y,
            "%s: start.y fora de size" % m.id)

func test_goal_is_inside_size():
    for m in MapPresets.ALL:
        assert_true(m.goal_grid.x >= 0 and m.goal_grid.x < m.size.x,
            "%s: goal.x fora de size" % m.id)
        assert_true(m.goal_grid.y >= 0 and m.goal_grid.y < m.size.y,
            "%s: goal.y fora de size" % m.id)

func test_start_not_on_wall():
    for m in MapPresets.ALL:
        for w in m.walls:
            assert_ne(m.start_grid, w, "%s: start (%s) coincide com parede" % [m.id, m.start_grid])

func test_goal_not_on_wall():
    for m in MapPresets.ALL:
        for w in m.walls:
            assert_ne(m.goal_grid, w, "%s: goal (%s) coincide com parede" % [m.id, m.goal_grid])

func test_walls_inside_interior():
    for m in MapPresets.ALL:
        for w in m.walls:
            assert_true(w.x > 0 and w.x < m.size.x - 1 and w.y > 0 and w.y < m.size.y - 1,
                "%s: parede %s na borda (deve ser só interna)" % [m.id, w])

func test_by_id_returns_map_or_null():
    assert_eq(MapPresets.by_id("banheiro").id, "banheiro")
    assert_null(MapPresets.by_id("inexistente"))
