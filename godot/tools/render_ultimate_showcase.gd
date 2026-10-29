extends SceneTree
## Ferramenta de Renderização e Comparativo do Ápice Visual:
## Painel A: Paper-Cutout no Ápice (Storybook Handcrafted em Alta Resolução)
## Painel B: Dead Cells / Pixelpipe 2.0 (Pixel Art 2.5D com Normal-Lighting, Hue-Shift & Dynamic Sel-Out)
## Painel C: Zoom Macro de Detalhes Lado a Lado (Rosto/Óculos, Peito/Colete/Broche, Violoncelo/Arco)

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")

var _frames := 0
var _vp: SubViewport
var _paper_vps: Array[SubViewport] = []
var _pixel_vps: Array[SubViewport] = []
var _pixel_rects: Array[TextureRect] = []
var _zoom_rects: Array[TextureRect] = []
var _processed := false

# =========================================================================
# PALETA HARMÔNICA EXPANDIDA DE 32 CORES (COM HUE-SHIFTING PROFISSIONAL)
# =========================================================================
const MASTER_PALETTE: Array[Color] = [
	# Casaco Terracota (Luz quente âmbar -> Sombra profunda vinho/carmim)
	Color("#f0856d"), # 0. Terracota Realce (Key Light)
	Color("#c2593f"), # 1. Terracota Base (Luthier Cello)
	Color("#8f3929"), # 2. Terracota Sombra Média
	Color("#5e2019"), # 3. Terracota Sombra Profunda
	Color("#3a1210"), # 4. Terracota Vinho Noturno (Contorno / Sel-Out)

	# Nogueira Escura / Lapela / Costeletas
	Color("#7d4625"), # 5. Nogueira Claro
	Color("#4e2813"), # 6. Nogueira Médio
	Color("#2d1408"), # 7. Nogueira Escuro

	# Pele Sr. Arthur (Pêssego dourado -> Sépia quente)
	Color("#ffebd4"), # 8. Pele Realce
	Color("#f2c49b"), # 9. Pele Base
	Color("#c9936b"), # 10. Pele Sombra
	Color("#8f5b38"), # 11. Pele Sombra Profunda

	# Cabelo e Bigode Grisalho (Prata -> Azul ardósia frio)
	Color("#ffffff"), # 12. Brilho Cabelo / Especular
	Color("#d5e0eb"), # 13. Prata Iluminado
	Color("#96a8bc"), # 14. Grisalho Médio
	Color("#5c7087"), # 15. Ardósia Sombra Fria
	Color("#2c3b4d"), # 16. Ardósia Escuro

	# Cachecol & Colete Azul Chambray / Petróleo
	Color("#8cb5de"), # 17. Chambray Realce
	Color("#4e7ea8"), # 18. Chambray Base
	Color("#2a4e70"), # 19. Petróleo Sombra
	Color("#162c42"), # 20. Marinho Profundo

	# Latão / Diapasão / Corrente Albert / Botões
	Color("#fff4b8"), # 21. Ouro Especular
	Color("#f2be38"), # 22. Ouro / Latão Base
	Color("#ad7e13"), # 23. Bronze Sombra
	Color("#573d05"), # 24. Bronze Escuro

	# Violoncelo Tampo em Abeto Dourado & Verniz
	Color("#e08e43"), # 25. Cello Âmbar Claro
	Color("#a65421"), # 26. Cello Verniz Terracota
	Color("#692e0e"), # 27. Cello Sombra Nogueira

	# Sapatos Oxford / Bengala Vermelha / Ébano
	Color("#d63c33"), # 28. Vermelho Bengala
	Color("#4a2618"), # 29. Couro Oxford Café
	Color("#24140b"), # 30. Couro Sola
	Color("#141018"), # 31. Ébano / Óculos Obsidian / Sel-Out Escuro
]

# Matriz Bayer 2x2 para dither ordenado suave
const BAYER_2X2 := [
	[-0.025,  0.025],
	[ 0.040, -0.010]
]


func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1600, 1220)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1600, 1220)
	bg.color = Color("#111016")
	_vp.add_child(bg)

	_build_header()

	# Configuração das 6 Poses
	var poses: Array[Dictionary] = [
		{"label": "1. Frente (Sul)",        "dir": Vector2i(1, 1),   "walk": false, "holding": "cane"},
		{"label": "2. 3/4 Frente (Sudeste)", "dir": Vector2i(1, 0),   "walk": false, "holding": "cane"},
		{"label": "3. Perfil (Leste)",       "dir": Vector2i(1, -1),  "walk": false, "holding": "cane"},
		{"label": "4. Costas (Norte)",       "dir": Vector2i(-1, -1), "walk": false, "holding": "cane"},
		{"label": "5. Caminhando",          "dir": Vector2i(0, 1),   "walk": true,  "holding": "cane"},
		{"label": "6. Mestre no Cello",     "dir": Vector2i(1, 1),   "walk": false, "holding": "cello"},
	]

	# =========================================================================
	# LINHA 1: PAPER-CUTOUT NO SEU ÁPICE (Alta Resolução com Sombras e Bevel)
	# =========================================================================
	_add_section_banner(
		65.0,
		"PARADIGMA A — 'PAPER-CUTOUT' NO ÁPICE (Storybook Handcrafted)",
		"Geometria 2.5D com chanfros de luz de corte, dupla sombra de cartolina, colete de alfaiataria, relógio Albert, óculos Ray Charles e Violoncelo de concerto.",
		Color("#e8985e")
	)

	for col in range(poses.size()):
		var cx := 140.0 + float(col) * 245.0
		var cy := 240.0
		var p_info: Dictionary = poses[col]

		var p_card := _make_card_backdrop(Vector2(cx - 105.0, cy - 125.0), Vector2(220, 240), Color("#1b1822"), Color("#2d2738"))
		_vp.add_child(p_card)

		var p_sub := SubViewport.new()
		p_sub.size = Vector2i(200, 220)
		p_sub.transparent_bg = true
		p_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_vp.add_child(p_sub)

		var ch := ProceduralArthurScript.new()
		ch.position = Vector2(100.0, 176.0)
		ch.scale = Vector2(3.3, 3.3)
		ch.set_meta("custom_assembly", "paper_cutout")
		ch.set_meta("custom_eyewear", "dark_shades")
		ch.set_meta("custom_headwear", "none")
		ch.set_meta("custom_holding_item", p_info["holding"])
		ch.set_direction(p_info["dir"], true)
		if p_info["walk"]:
			ch.anim_state = "walk"
			ch.walk_phase = 1.35
		p_sub.add_child(ch)
		_paper_vps.append(p_sub)

		var trect := TextureRect.new()
		trect.texture = p_sub.get_texture()
		trect.size = Vector2(200, 220)
		trect.position = Vector2(cx - 100.0, cy - 120.0)
		_vp.add_child(trect)

		var lbl := _make_label(p_info["label"], Vector2(cx - 95.0, cy + 92.0), 13, Color("#f2e8dc"))
		_vp.add_child(lbl)

	# =========================================================================
	# LINHA 2: DEAD CELLS / PIXELPIPE 2.0 (Pixel Art 2.5D de Alta Fidelidade)
	# =========================================================================
	_add_section_banner(
		415.0,
		"PARADIGMA B — 'DEAD CELLS / PIXELPIPE 2.0' (Pixel Art 2.5D com Normal-Lighting)",
		"Render Stroke-less 64x64 -> Key Light direcional + Rim Light de silhueta + Paleta 32 cores Hue-Shifted + Dynamic Sel-Out sem L-Corners.",
		Color("#6bb8e6")
	)

	for col in range(poses.size()):
		var cx := 140.0 + float(col) * 245.0
		var cy := 590.0
		var p_info: Dictionary = poses[col]

		var p_card := _make_card_backdrop(Vector2(cx - 105.0, cy - 125.0), Vector2(220, 240), Color("#161a22"), Color("#242f3d"))
		_vp.add_child(p_card)

		# SubViewport de 64x64 para pixel art nativo de 64px de altura
		var pix_sub := SubViewport.new()
		pix_sub.size = Vector2i(64, 64)
		pix_sub.transparent_bg = true
		pix_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_vp.add_child(pix_sub)

		var ch := ProceduralArthurScript.new()
		ch.position = Vector2(32.0, 52.0)
		ch.scale = Vector2(1.22, 1.22)
		ch.set_meta("custom_assembly", "flat_geometric") # Stroke-less para o Pixelpipe!
		ch.set_meta("custom_eyewear", "dark_shades")
		ch.set_meta("custom_headwear", "none")
		ch.set_meta("custom_holding_item", p_info["holding"])
		ch.set_direction(p_info["dir"], true)
		if p_info["walk"]:
			ch.anim_state = "walk"
			ch.walk_phase = 1.35
		pix_sub.add_child(ch)
		_pixel_vps.append(pix_sub)

		var trect := TextureRect.new()
		trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.size = Vector2(192, 192) # 3x ampliado
		trect.position = Vector2(cx - 96.0, cy - 115.0)
		_vp.add_child(trect)
		_pixel_rects.append(trect)

		var lbl := _make_label(p_info["label"] + " [64x64 @ 3x]", Vector2(cx - 95.0, cy + 92.0), 13, Color("#d9eaf5"))
		_vp.add_child(lbl)

	# =========================================================================
	# LINHA 3: ZOOM MACRO DE DETALHES 3.5X (Comparativo Lado a Lado)
	# =========================================================================
	_add_section_banner(
		765.0,
		"PARADIGMA C — ZOOM MACRO DE DETALHES LADO A LADO (3.5x Magnification)",
		"Comparação direta da expressão facial (óculos de jazz e bigode), alfaiataria (colete, lapela e broche) e corpo acústico do Violoncelo.",
		Color("#c48ae6")
	)

	var macro_pairs: Array[Dictionary] = [
		{"title": "1. Expressão Facial & Óculos Ray Charles", "crop_x": 0.40, "crop_y": 0.08, "crop_w": 0.28, "crop_h": 0.35},
		{"title": "2. Alfaiataria (Colete, Lapela & Albert)",  "crop_x": 0.38, "crop_y": 0.28, "crop_w": 0.32, "crop_h": 0.40},
		{"title": "3. O Violoncelo & Arco de Concerto",        "crop_x": 0.32, "crop_y": 0.38, "crop_w": 0.40, "crop_h": 0.55},
	]

	for i in range(macro_pairs.size()):
		var info: Dictionary = macro_pairs[i]
		var pair_cx := 270.0 + float(i) * 530.0
		var pair_cy := 970.0

		var m_box := _make_card_backdrop(Vector2(pair_cx - 240.0, pair_cy - 145.0), Vector2(490, 275), Color("#181620"), Color("#342b45"))
		_vp.add_child(m_box)

		var mlbl := _make_label(info["title"], Vector2(pair_cx - 225.0, pair_cy - 138.0), 14, Color("#f0e6ff"))
		_vp.add_child(mlbl)

		# Sub-painel Esquerdo: Paper-Cutout Macro
		var p_lbl := _make_label("Paper-Cutout (Vetor)", Vector2(pair_cx - 215.0, pair_cy - 112.0), 12, Color("#e8985e"))
		_vp.add_child(p_lbl)
		var p_rect := TextureRect.new()
		p_rect.size = Vector2(210, 210)
		p_rect.position = Vector2(pair_cx - 220.0, pair_cy - 90.0)
		p_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_vp.add_child(p_rect)
		_zoom_rects.append(p_rect)

		# Sub-painel Direito: Dead Cells Pixelpipe Macro
		var d_lbl := _make_label("Dead Cells 2.0 (Pixel)", Vector2(pair_cx + 25.0, pair_cy - 112.0), 12, Color("#6bb8e6"))
		_vp.add_child(d_lbl)
		var d_rect := TextureRect.new()
		d_rect.size = Vector2(210, 210)
		d_rect.position = Vector2(pair_cx + 20.0, pair_cy - 90.0)
		d_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		d_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		d_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_vp.add_child(d_rect)
		_zoom_rects.append(d_rect)


func _build_header() -> void:
	var h_panel := ColorRect.new()
	h_panel.size = Vector2(1600, 60)
	h_panel.color = Color("#181622")
	_vp.add_child(h_panel)

	var title := Label.new()
	title.text = "BlindTuner — O Ápice dos Paradigmas Visuais: 'Paper-Cutout' vs 'Dead Cells 2.0'"
	title.position = Vector2(40.0, 10.0)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#fff6e8"))
	_vp.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Comparativo de alta fidelidade técnica: Vetor Artesanal com Camadas & Bevels vs Pixel Art 2.5D com Normal-Lighting & Dynamic Sel-Out"
	subtitle.position = Vector2(40.0, 35.0)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#a5a0b8"))
	_vp.add_child(subtitle)


func _add_section_banner(y: float, title_txt: String, desc_txt: String, bar_color: Color) -> void:
	var bar := ColorRect.new()
	bar.size = Vector2(8, 38)
	bar.position = Vector2(40.0, y)
	bar.color = bar_color
	_vp.add_child(bar)

	var title := Label.new()
	title.text = title_txt
	title.position = Vector2(58.0, y)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	_vp.add_child(title)

	var desc := Label.new()
	desc.text = desc_txt
	desc.position = Vector2(58.0, y + 22.0)
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color("#a8a4b5"))
	_vp.add_child(desc)


func _make_card_backdrop(pos: Vector2, sz: Vector2, fill_col: Color, border_col: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.position = pos
	pc.size = sz
	var style := StyleBoxFlat.new()
	style.bg_color = fill_col
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = border_col
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	pc.add_theme_stylebox_override("panel", style)
	return pc


func _make_label(txt: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l


# =========================================================================
# MOTOR 'PIXELPIPE 2.0': NORMAL-LIGHTING + 32-COLOR HUE-SHIFT + DYNAMIC SEL-OUT
# =========================================================================
func _apply_pixelpipe_2_0(raw_img: Image) -> Image:
	var w := raw_img.get_width()
	var h := raw_img.get_height()
	var lit := Image.create(w, h, false, Image.FORMAT_RGBA8)
	lit.fill(Color(0, 0, 0, 0))

	# Vetor de luz direcional 2.5D vindo de cima-esquerda (Key Light clássica)
	var lx := -0.65
	var ly := -0.75

	# 1. Passe de Normal-Lighting e Quantização de Paleta com Hue-Shifting
	for y in range(h):
		for x in range(w):
			var c := raw_img.get_pixel(x, y)
			if c.a < 0.45:
				continue

			# Recupera cor pura desfeita de pré-multiplicação de alpha
			var base_col := Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0), 1.0)

			# Preserva óculos escuros e ébano sem clarear
			var is_obsidian: bool = base_col.v < 0.22
			var is_skin: bool = base_col.r > 0.8 and base_col.g > 0.6 and base_col.b > 0.5
			var is_specular: bool = base_col.v > 0.96

			if is_specular:
				lit.set_pixel(x, y, Color("#ffffff"))
				continue
			elif is_obsidian:
				lit.set_pixel(x, y, Color("#141018"))
				continue

			# Estimativa de inclinação de superfície 2.5D pelos vizinhos
			var c_up := raw_img.get_pixel(x, maxi(0, y - 1))
			var c_dn := raw_img.get_pixel(x, mini(h - 1, y + 1))
			var c_lf := raw_img.get_pixel(maxi(0, x - 1), y)
			var c_rt := raw_img.get_pixel(mini(w - 1, x + 1), y)

			# Detecção de bordas internas / sombreamento volumétrico
			var grad_x: float = (c_rt.v - c_lf.v) * 1.5
			var grad_y: float = (c_dn.v - c_up.v) * 1.5
			var normal_dot: float = -(grad_x * lx + grad_y * ly)

			# Influência de iluminação direcional suave
			var light_factor: float = clampf(normal_dot, -0.15, 0.12)
			if is_skin:
				light_factor = clampf(normal_dot * 0.4, -0.06, 0.05)

			# Aplicação do dither ordenado Bayer 2x2
			var bayer_ofs: float = BAYER_2X2[y % 2][x % 2] * (0.4 if is_skin else 1.0)

			# Cor modulada
			var target_col := Color(
				clampf(base_col.r + light_factor + bayer_ofs, 0.0, 1.0),
				clampf(base_col.g + light_factor + bayer_ofs, 0.0, 1.0),
				clampf(base_col.b + light_factor * 0.7 + bayer_ofs, 0.0, 1.0),
				1.0
			)

			lit.set_pixel(x, y, _nearest_master_palette(target_col))

	# 2. Remoção de ruído órfão isolado (preservando brilhos intencionais)
	var cleaned: Image = lit.duplicate() as Image
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c: Color = lit.get_pixel(x, y)
			if c.a < 0.5:
				continue
			# Preserva pontos de brilho especular (botões, óculos, reflexos)
			if c == Color("#ffffff") or c == Color("#fff4b8") or c == Color("#ffebd4") or c == Color("#141018"):
				continue
			var n: Color = lit.get_pixel(x, y - 1)
			var s: Color = lit.get_pixel(x, y + 1)
			var e: Color = lit.get_pixel(x + 1, y)
			var w_px: Color = lit.get_pixel(x - 1, y)
			if n.a > 0.5 and n == s and n == e and n == w_px and c != n:
				cleaned.set_pixel(x, y, n)

	# 3. Dynamic Sel-Out (Contorno Seletivo Contextual 1px)
	var out: Image = cleaned.duplicate() as Image
	var is_outline: Dictionary = {}

	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if cleaned.get_pixel(x, y).a >= 0.5:
				continue # Pixel interno

			# Verifica se é vizinho cardinal de pixel opaco
			var n_opaco := false
			var nearest_inner_col := Color.BLACK
			var coords := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
			for ofs in coords:
				var nx: int = x + ofs.x
				var ny: int = y + ofs.y
				var sc: Color = cleaned.get_pixel(nx, ny)
				if sc.a >= 0.5:
					n_opaco = true
					nearest_inner_col = sc
					break

			if n_opaco:
				# Determina a cor seletiva de contorno baseado na luz e material
				var sel_col := Color("#141018") # Padrão escuro
				# Se estiver na parte superior ou esquerda (voltada para a luz), usa contorno quente do material!
				if (y < h * 0.65 and x < w * 0.60):
					# Contorno seletivo suave
					if nearest_inner_col.r > 0.5 and nearest_inner_col.b < 0.35: # Terracota
						sel_col = Color("#3a1210")
					elif nearest_inner_col.b > 0.4: # Cabelo prata / cachecol
						sel_col = Color("#2c3b4d")
					elif nearest_inner_col.r > 0.6 and nearest_inner_col.g > 0.5: # Ouro / Cello
						sel_col = Color("#4e2813")
				out.set_pixel(x, y, sel_col)
				is_outline[Vector2i(x, y)] = true

	# 4. Remoção de L-Corners (degraus duplos 2x2 do contorno externo)
	var final_img: Image = out.duplicate() as Image
	for y in range(1, h - 2):
		for x in range(1, w - 2):
			if is_outline.has(Vector2i(x, y)) and is_outline.has(Vector2i(x + 1, y)) and is_outline.has(Vector2i(x, y + 1)):
				# Se o canto oposto for transparente, remove a quina do L
				if cleaned.get_pixel(x + 1, y + 1).a < 0.5 and out.get_pixel(x + 1, y + 1).a < 0.5:
					final_img.set_pixel(x, y, Color(0, 0, 0, 0))

	return final_img


## Distância perceptiva ponderada para quantização precisa
func _nearest_master_palette(c: Color) -> Color:
	var best_col := MASTER_PALETTE[0]
	var min_dist := 999999.0
	for pal in MASTER_PALETTE:
		var r_mean := (c.r + pal.r) * 0.5
		var dr := (c.r - pal.r) * 255.0
		var dg := (c.g - pal.g) * 255.0
		var db := (c.b - pal.b) * 255.0
		var dist: float = (2.0 + r_mean) * dr * dr + 4.0 * dg * dg + (2.0 + (1.0 - r_mean)) * db * db
		if dist < min_dist:
			min_dist = dist
			best_col = pal
	return best_col


func _process(_delta: float) -> bool:
	_frames += 1
	# No frame 4: processa o Pixelpipe 2.0 e os recortes Macro
	if _frames == 4 and not _processed:
		_processed = true
		_process_pixelpipe_and_macros()

	# No frame 8: captura a tela mestre e salva o PNG
	if _frames >= 8:
		var main_img: Image = _vp.get_texture().get_image()
		var out_path := "C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/ultimate_visual_showcase.png"
		var err := main_img.save_png(out_path)
		if err == OK:
			print("SUCCESS: Ultimate Visual Showcase salvo com sucesso em: ", out_path)
		else:
			print("ERROR: Falha ao salvar showcase: ", err)
		quit()
	return false


func _process_pixelpipe_and_macros() -> void:
	# 1. Processa cada pose através do Pixelpipe 2.0
	var clean_pixel_images: Array[Image] = []
	for i in range(_pixel_vps.size()):
		var raw: Image = _pixel_vps[i].get_texture().get_image()
		var processed: Image = _apply_pixelpipe_2_0(raw)
		clean_pixel_images.append(processed)
		var p_tex := ImageTexture.create_from_image(processed)
		_pixel_rects[i].texture = p_tex

	# 2. Constrói os recortes macro para a Linha 3
	var paper_src_indices := [0, 1, 5]
	var pixel_src_indices := [0, 1, 5]

	# Crops específicos calibrados no espaço de coordenadas
	var crop_rects_paper := [
		Rect2i(55, 60, 90, 90),    # Rosto Frente
		Rect2i(55, 95, 90, 90),    # Colete / Broche 3/4
		Rect2i(45, 95, 110, 110),  # Violoncelo & Arco
	]
	var crop_rects_pixel := [
		Rect2i(18, 6, 28, 28),     # Rosto Frente Pixel
		Rect2i(17, 20, 30, 30),    # Colete / Broche Pixel
		Rect2i(10, 16, 42, 42),    # Violoncelo & Arco Pixel
	]

	for p_idx in range(3):
		# Paper crop
		var p_img: Image = _paper_vps[paper_src_indices[p_idx]].get_texture().get_image()
		var p_crop: Image = p_img.get_region(crop_rects_paper[p_idx])
		_zoom_rects[p_idx * 2].texture = ImageTexture.create_from_image(p_crop)

		# Pixel crop
		var pix_img: Image = clean_pixel_images[pixel_src_indices[p_idx]]
		var pix_crop: Image = pix_img.get_region(crop_rects_pixel[p_idx])
		_zoom_rects[p_idx * 2 + 1].texture = ImageTexture.create_from_image(pix_crop)
