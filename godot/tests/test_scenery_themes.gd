extends GutTest

func test_three_themes_exist():
    assert_eq(SceneryThemes.ALL.size(), 3)

func test_all_themes_have_unique_ids():
    var seen := {}
    for t in SceneryThemes.ALL:
        assert_false(seen.has(t.id), "id duplicado: %s" % t.id)
        seen[t.id] = true

func test_known_theme_ids():
    var ids := []
    for t in SceneryThemes.ALL:
        ids.append(t.id)
    assert_eq(ids, ["quarto", "banheiro", "sala"])

func test_all_themes_have_complete_palette():
    for t in SceneryThemes.ALL:
        assert_ne(t.floor_a, Color(0, 0, 0, 0), "%s.floor_a vazio" % t.id)
        assert_ne(t.floor_b, Color(0, 0, 0, 0), "%s.floor_b vazio" % t.id)
        assert_ne(t.wall_top, Color(0, 0, 0, 0), "%s.wall_top vazio" % t.id)
        assert_ne(t.wall_front, Color(0, 0, 0, 0), "%s.wall_front vazio" % t.id)
        assert_ne(t.wall_outline, Color(0, 0, 0, 0), "%s.wall_outline vazio" % t.id)
        assert_ne(t.goal_marker_color, Color(0, 0, 0, 0), "%s.goal_marker_color vazio" % t.id)

func test_by_id_returns_theme_or_null():
    assert_eq(SceneryThemes.by_id("quarto").id, "quarto")
    assert_null(SceneryThemes.by_id("inexistente"))
