extends SceneTree
## Renderiza vitrine comparativa de 4 variantes de design de personagens
## (diferentes tratamentos de rosto, óculos escuros, boina tweed e arquétipos).

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")

var _frames := 0
var _vp: SubViewport

func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1140, 860)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1140, 860)
	bg.color = Color(0.12, 0.11, 0.14)
	_vp.add_child(bg)

	var variants = [
		{
			"title": "Variante 1: Maestro com Óculos Escuros Retrô (Estilo Ray Charles)",
			"desc": "Óculos escuros pretos obsidian com reflexo sutil — dignidade máxima de virtuoso cego, zero aros de mergulho",
			"eyewear": "dark_shades",
			"headwear": "none",
			"archetype": "arthur",
		},
		{
			"title": "Variante 2: Mestre Luthier com Boina Tweed & Olhos Fechados de Escuta",
			"desc": "Sem óculos! Olhos fechados serenos e boina de lã clássica com aba que indica claramente a direção isométrica",
			"eyewear": "closed_eyes",
			"headwear": "flat_cap",
			"archetype": "arthur",
		},
		{
			"title": "Variante 3: Virtuoso Vintage (Boina Tweed + Óculos Redondos Escuros)",
			"desc": "Boina de luthier combinada com óculos redondos escuros e aro fino de bronze — visual icônico de jogo indie",
			"eyewear": "round_dark",
			"headwear": "flat_cap",
			"archetype": "arthur",
		},
		{
			"title": "Variante 4: Clara — A Jovem Aprendiz / Afinadora de Pianos",
			"desc": "Arquétipo alternativo: jovem afinadora talentosa com sobretudo terracota, franja castanha e semblante concentrado",
			"eyewear": "closed_eyes",
			"headwear": "none",
			"archetype": "apprentice",
		},
	]

	for row in range(variants.size()):
		var v = variants[row]
		var y_top := 25.0 + float(row) * 205.0

		var header := Label.new()
		header.text = v["title"]
		header.position = Vector2(40.0, y_top)
		header.add_theme_font_size_override("font_size", 15)
		header.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90))
		_vp.add_child(header)

		var sub := Label.new()
		sub.text = v["desc"]
		sub.position = Vector2(40.0, y_top + 22.0)
		sub.add_theme_font_size_override("font_size", 12)
		sub.add_theme_color_override("font_color", Color(0.74, 0.72, 0.70))
		_vp.add_child(sub)

		# 5 poses por variante: Frente (Sul), 3/4 Frente (Sudeste), Lado (Leste), Costas (Norte), Andando
		var dirs := [
			Vector2i(1, 1),   # Frente
			Vector2i(1, 0),   # 3/4 Frente
			Vector2i(1, -1),  # Lado
			Vector2i(-1, -1), # Costas
			Vector2i(0, 1),   # Andando
		]

		for col in range(dirs.size()):
			var char_node := ProceduralArthurScript.new()
			char_node.position = Vector2(130.0 + float(col) * 200.0, y_top + 160.0)
			char_node.scale = Vector2(2.5, 2.5)

			# Configura o estilo da variante
			char_node.set_meta("custom_eyewear", v["eyewear"])
			char_node.set_meta("custom_headwear", v["headwear"])
			char_node.set_meta("custom_archetype", v["archetype"])

			char_node.set_direction(dirs[col], true)
			if col == 4:
				char_node.anim_state = "walk"
				char_node.walk_phase = 1.2
			elif col == 1:
				char_node.set_continuous_tuning_angle(char_node.facing_angle, Color(0.92, 0.75, 0.35, 0.8))

			_vp.add_child(char_node)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= 4:
		var img := _vp.get_texture().get_image()
		if img != null:
			img.save_png("C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/character_design_variants.png")
		quit(0)
		return true
	return false
