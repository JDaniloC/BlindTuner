extends SceneTree
## Renderiza vitrine comparativa dos 4 paradigmas estruturais de montagem do personagem:
## 1. Vetorial Ilustrado (Clean Indie - Variante 1)
## 2. Pixel Art Procedural (16-bit Modern via Quantização)
## 3. Paper-Cutout / Colagem Artesanal (Layered Storybook)
## 4. Minimalista Flat Geométrico (Estilo Monument / Gris)

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")

var _frames := 0
var _vp: SubViewport

func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1180, 900)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1180, 900)
	bg.color = Color(0.11, 0.10, 0.13)
	_vp.add_child(bg)

	var paradigms = [
		{
			"id": "vector_indie",
			"title": "Paradigma 1: Vetorial Ilustrado (Clean Indie — Variante 1 Escolhida)",
			"desc": "Polígonos vetoriais contínuos com contornos pretos limpos e sombreamento volumétrico. Alta legibilidade e elegância contemporânea.",
			"assembly": "overcoat_indie",
			"is_pixel": false,
		},
		{
			"id": "pixel_art",
			"title": "Paradigma 2: Pixel Art Procedural (16-bit Retro Moderno)",
			"desc": "Renderização da geometria viva em grade quantizada (resolução nativa 52x52 upscaled com filtro Nearest). Charme retrô com fluidez 60fps.",
			"assembly": "overcoat_indie",
			"is_pixel": true,
		},
		{
			"id": "paper_cutout",
			"title": "Paradigma 3: Paper-Cutout / Colagem Artesanal (Layered Storybook)",
			"desc": "Camadas sobrepostas com sombras de contato (drop shadows) e bordas suaves. Sensação tátil de livro infantil ou stop-motion de papel.",
			"assembly": "paper_cutout",
			"is_pixel": false,
		},
		{
			"id": "flat_geometric",
			"title": "Paradigma 4: Minimalista Flat Geométrico (Estilo Monument Valley / Gris)",
			"desc": "Silhueta geométrica pura sem contornos (stroke-less), baseada em planos de luz e contraste tonal. Estética madura, limpa e contemplativa.",
			"assembly": "flat_geometric",
			"is_pixel": false,
		},
	]

	# 5 poses por paradigma: Frente (Sul), 3/4 Frente (Sudeste), Lado (Leste), Costas (Norte), Andando
	var dirs := [
		Vector2i(1, 1),   # Frente
		Vector2i(1, 0),   # 3/4 Frente
		Vector2i(1, -1),  # Lado
		Vector2i(-1, -1), # Costas
		Vector2i(0, 1),   # Andando
	]

	for row in range(paradigms.size()):
		var p = paradigms[row]
		var y_top := 22.0 + float(row) * 218.0

		var header := Label.new()
		header.text = p["title"]
		header.position = Vector2(40.0, y_top)
		header.add_theme_font_size_override("font_size", 15)
		header.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90))
		_vp.add_child(header)

		var sub := Label.new()
		sub.text = p["desc"]
		sub.position = Vector2(40.0, y_top + 22.0)
		sub.add_theme_font_size_override("font_size", 12)
		sub.add_theme_color_override("font_color", Color(0.72, 0.70, 0.68))
		_vp.add_child(sub)

		for col in range(dirs.size()):
			var center_x := 130.0 + float(col) * 205.0
			var center_y := y_top + 165.0

			if p["is_pixel"]:
				# Renderiza o personagem dentro de um SubViewport de baixa resolução (52x52)
				var pix_vp := SubViewport.new()
				pix_vp.size = Vector2i(52, 52)
				pix_vp.transparent_bg = true
				pix_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
				_vp.add_child(pix_vp)

				var char_node := ProceduralArthurScript.new()
				char_node.position = Vector2(26.0, 42.0)
				char_node.scale = Vector2(1.0, 1.0)
				char_node.set_meta("custom_eyewear", "dark_shades")
				char_node.set_meta("custom_headwear", "none")
				char_node.set_meta("custom_assembly", "overcoat_indie")
				char_node.set_direction(dirs[col], true)

				if col == 4:
					char_node.anim_state = "walk"
					char_node.walk_phase = 1.3
				elif col == 1:
					char_node.set_continuous_tuning_angle(char_node.facing_angle, Color(0.92, 0.75, 0.35, 0.8))

				pix_vp.add_child(char_node)

				# TextureRect com filtro NEAREST para gerar os pixels nítidos do pixel art
				var trect := TextureRect.new()
				trect.texture = pix_vp.get_texture()
				trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				trect.size = Vector2(130, 130)
				trect.position = Vector2(center_x - 65.0, center_y - 105.0)
				_vp.add_child(trect)
			else:
				var char_node := ProceduralArthurScript.new()
				char_node.position = Vector2(center_x, center_y)
				char_node.scale = Vector2(2.5, 2.5)

				# Configura o paradigma (Variante 1 base com o assembly mode específico)
				char_node.set_meta("custom_eyewear", "dark_shades")
				char_node.set_meta("custom_headwear", "none")
				char_node.set_meta("custom_assembly", p["assembly"])
				char_node.set_direction(dirs[col], true)

				if col == 4:
					char_node.anim_state = "walk"
					char_node.walk_phase = 1.3
				elif col == 1:
					char_node.set_continuous_tuning_angle(char_node.facing_angle, Color(0.92, 0.75, 0.35, 0.8))

				_vp.add_child(char_node)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= 5:
		var img := _vp.get_texture().get_image()
		if img != null:
			img.save_png("C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/character_assembly_paradigms.png")
		quit(0)
		return true
	return false
