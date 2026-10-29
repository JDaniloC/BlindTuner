extends SceneTree
## Ferramenta de Renderização de Cenários Comparativos do BlindTuner:
## Cenário A: 'Paper-Cutout' (Vetor Artesanal Handcrafted com Camadas, Bevels e Sombras de Cartolina)
## Cenário B: 'Pixel Art 2.5D Hi-End' (Dead Cells / Sea of Stars / Eastward Style em Resolução Nativa)
##
## Representa o ambiente principal do jogo:
## - "Conservatório & Oficina de Lutherie Acústica"
## - Piso de Parquet em Carvalho Nobre, Boiserie, Janela de Arco com Feixe de Luz (God Ray)
## - Piano de Cauda Ébano, Estante de Partitura Dourada, Relógio de Pêndulo, Poltrona de Veludo, Tapete
## - Sr. Arthur tocando seu Violoncelo de Concerto em Mel Dourado com alta separação visual!

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")

var _frames := 0
var _vp: SubViewport
var _paper_sub: SubViewport
var _pixel_sub: SubViewport
var _pixel_main_rect: TextureRect
var _zoom_paper_rect: TextureRect
var _zoom_pixel_rect: TextureRect
var _processed := false

# =========================================================================
# PALETA HARMÔNICA DE CENÁRIO (MADEIRAS, LATÃO, VELUDO E ÉBANO)
# =========================================================================
const SCENE_PALETTE: Array[Color] = [
	# Madeira do Piso de Parquet (Carvalho Dourado -> Sombra)
	Color("#b07a4a"), # 0. Carvalho Realce Luz
	Color("#875630"), # 1. Carvalho Médio
	Color("#5e371a"), # 2. Carvalho Sombra / Encaixe
	Color("#3b200d"), # 3. Carvalho Vinco Profundo

	# Parede Boiserie / Painel Acústico de Luthier
	Color("#d9cbba"), # 4. Reboco Creme Iluminado
	Color("#b8a692"), # 5. Reboco Meia-Luz
	Color("#8c7662"), # 6. Boiserie Sombra
	Color("#544335"), # 7. Moldura Boiserie Escura

	# Piano de Cauda em Ébano Polido
	Color("#383242"), # 8. Reflexo da Laca do Piano
	Color("#1a1722"), # 9. Corpo Ébano Piano
	Color("#0d0b12"), # 10. Sombra Profunda Tampo
	Color("#f4ede1"), # 11. Teclas de Marfim / Partitura

	# Veludo Verde-Sálvia da Poltrona
	Color("#76997b"), # 12. Veludo Realce
	Color("#4e6e53"), # 13. Veludo Médio
	Color("#2d4531"), # 14. Veludo Sombra

	# Latão Dourado / Estante / Pêndulo
	Color("#fff2a3"), # 15. Latão Especular
	Color("#e0b034"), # 16. Latão Dourado Base
	Color("#966e13"), # 17. Bronze Sombra

	# Tapete Acústico Carmim / Borgonha
	Color("#a33e38"), # 18. Tapete Carmim Base
	Color("#6e221d"), # 19. Tapete Carmim Sombra
	Color("#42110e"), # 20. Tapete Borda Escura

	# Luz Solar (God Ray) & Vidro
	Color("#fff8d6"), # 21. Luz Solar Pura
	Color("#d1e6f5"), # 22. Vidro da Janela

	# Casaco Terracota do Sr. Arthur
	Color("#f0856d"), # 23. Terracota Realce
	Color("#c2593f"), # 24. Terracota Base
	Color("#8f3929"), # 25. Terracota Sombra
	Color("#4a1714"), # 26. Terracota Vinho Noturno

	# Violoncelo Mel Dourado & Madeira de Bordo
	Color("#f5b857"), # 27. Cello Realce Mel
	Color("#e09438"), # 28. Cello Tampo Dourado
	Color("#a15b1c"), # 29. Cello Bordo Médio
	Color("#54250a"), # 30. Cello Sombra Nogueira / Borda Ébano

	# Pele, Cabelo & Bigode Prateado
	Color("#ffebd4"), # 31. Pele Realce
	Color("#f2c49b"), # 32. Pele Base
	Color("#c9936b"), # 33. Pele Sombra
	Color("#ffffff"), # 34. Bigode / Cabelo Prata Brilhante
	Color("#96a8bc"), # 35. Cabelo Grisalho Sombra
	Color("#141018"), # 36. Óculos Obsidian / Contorno
]

const BAYER_2X2 := [
	[-0.025,  0.025],
	[ 0.040, -0.010]
]


func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1600, 960)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1600, 960)
	bg.color = Color("#0f0e14")
	_vp.add_child(bg)

	_build_master_header()

	# =========================================================================
	# LADO ESQUERDO: CENÁRIO A — PAPER-CUTOUT (VETOR ARTESANAL HANDCRAFTED)
	# =========================================================================
	_add_scenery_column_header(
		Vector2(40.0, 75.0),
		"CENÁRIO A — 'PAPER-CUTOUT' NO ÁPICE (Storybook Handcrafted)",
		"Geometria 2.5D com textura de cartolina, sombras suaves de papel, chanfros de corte iluminados e feixes solares translúcidos.",
		Color("#e8985e")
	)

	var paper_card := _make_card_backdrop(Vector2(40.0, 130.0), Vector2(740, 560), Color("#17151e"), Color("#2c2438"))
	_vp.add_child(paper_card)

	_paper_sub = SubViewport.new()
	_paper_sub.size = Vector2i(720, 540)
	_paper_sub.transparent_bg = true
	_paper_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.add_child(_paper_sub)

	var paper_room := _build_room_node("paper_cutout", false)
	_paper_sub.add_child(paper_room)

	var paper_trect := TextureRect.new()
	paper_trect.texture = _paper_sub.get_texture()
	paper_trect.size = Vector2(720, 540)
	paper_trect.position = Vector2(50.0, 140.0)
	_vp.add_child(paper_trect)

	# Inset Zoom 2x Paper-Cutout (Arthur & Cello)
	var p_zoom_card := _make_card_backdrop(Vector2(40.0, 705.0), Vector2(740, 230), Color("#15131b"), Color("#272033"))
	_vp.add_child(p_zoom_card)

	var p_zlbl := _make_label("Zoom 2.2x: Legibilidade do Sr. Arthur, Bigode Prateado & Violoncelo Mel no Cenário", Vector2(55.0, 715.0), 13, Color("#f0e0d0"))
	_vp.add_child(p_zlbl)

	_zoom_paper_rect = TextureRect.new()
	_zoom_paper_rect.size = Vector2(710, 185)
	_zoom_paper_rect.position = Vector2(55.0, 740.0)
	_zoom_paper_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_zoom_paper_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_vp.add_child(_zoom_paper_rect)

	# =========================================================================
	# LADO DIREITO: CENÁRIO B — PIXEL ART 2.5D (DEAD CELLS / SEA OF STARS STYLE)
	# =========================================================================
	_add_scenery_column_header(
		Vector2(820.0, 75.0),
		"CENÁRIO B — 'DEAD CELLS / PIXELPIPE 2.0' (Pixel Art 2.5D Hi-End)",
		"O mesmo cômodo em resolução nativa 360x270 (ampliado 2x) -> Iluminação direcional, Bayer dither no parquet e contornos seletivos.",
		Color("#6bb8e6")
	)

	var pixel_card := _make_card_backdrop(Vector2(820.0, 130.0), Vector2(740, 560), Color("#141822"), Color("#222d3d"))
	_vp.add_child(pixel_card)

	# SubViewport de resolução nativa 360x270 (proporção clássica retro 4:3 expandida)
	_pixel_sub = SubViewport.new()
	_pixel_sub.size = Vector2i(360, 270)
	_pixel_sub.transparent_bg = true
	_pixel_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.add_child(_pixel_sub)

	var pixel_room := _build_room_node("flat_geometric", true)
	_pixel_sub.add_child(pixel_room)

	_pixel_main_rect = TextureRect.new()
	_pixel_main_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pixel_main_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pixel_main_rect.size = Vector2(720, 540) # 2x ampliado perfeito pixel-art
	_pixel_main_rect.position = Vector2(830.0, 140.0)
	_vp.add_child(_pixel_main_rect)

	# Inset Zoom 2x Pixel Art
	var d_zoom_card := _make_card_backdrop(Vector2(820.0, 705.0), Vector2(740, 230), Color("#121620"), Color("#1f2938"))
	_vp.add_child(d_zoom_card)

	var d_zlbl := _make_label("Zoom 2.2x: Separação Nítida de Píxeis (Bigode vs Pele e Violoncelo vs Sobretudo)", Vector2(835.0, 715.0), 13, Color("#d6e6f5"))
	_vp.add_child(d_zlbl)

	_zoom_pixel_rect = TextureRect.new()
	_zoom_pixel_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_zoom_pixel_rect.size = Vector2(710, 185)
	_zoom_pixel_rect.position = Vector2(835.0, 740.0)
	_zoom_pixel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_zoom_pixel_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_vp.add_child(_zoom_pixel_rect)


func _build_master_header() -> void:
	var h_panel := ColorRect.new()
	h_panel.size = Vector2(1600, 68)
	h_panel.color = Color("#171520")
	_vp.add_child(h_panel)

	var title := Label.new()
	title.text = "BlindTuner — Como o Cenário Fica em Ambos os Estilos (Conservatório & Oficina de Lutherie)"
	title.position = Vector2(40.0, 12.0)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#fff6e8"))
	_vp.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Comparativo completo in-situ: Piso de Parquet, Boiserie, Janela Colonial com God Ray, Piano de Cauda, Estante, Relógio e Sr. Arthur com Violoncelo"
	subtitle.position = Vector2(40.0, 39.0)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#a8a2bc"))
	_vp.add_child(subtitle)


func _add_scenery_column_header(pos: Vector2, title_txt: String, desc_txt: String, bar_color: Color) -> void:
	var bar := ColorRect.new()
	bar.size = Vector2(6, 38)
	bar.position = pos
	bar.color = bar_color
	_vp.add_child(bar)

	var title := Label.new()
	title.text = title_txt
	title.position = pos + Vector2(16.0, 0.0)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	_vp.add_child(title)

	var desc := Label.new()
	desc.text = desc_txt
	desc.position = pos + Vector2(16.0, 21.0)
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color("#a5a1b3"))
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
# CONSTRUTOR PROCEDURAL DA SALA ACÚSTICA (CENÁRIO 2.5D)
# =========================================================================
func _build_room_node(assembly_mode: String, is_low_res: bool) -> Node2D:
	var room := Node2D.new()
	var scale_factor: float = 0.50 if is_low_res else 1.0
	room.scale = Vector2(scale_factor, scale_factor)

	# Ponto focal central da câmera isométrica no SubViewport
	var center_x: float = 360.0 if not is_low_res else 180.0
	var center_y: float = 310.0 if not is_low_res else 155.0
	room.position = Vector2(center_x, center_y)

	# 1. Camada de Fundo (Paredes, Boiserie, Piso, Piano, Relógio, Poltrona, Tapete)
	var bg_drawer := CustomRoomDrawer.new()
	bg_drawer.setup(assembly_mode, is_low_res, "bg")
	room.add_child(bg_drawer)

	# 2. O Mestre Arthur sentado no centro acústico tocando violoncelo
	var arthur := ProceduralArthurScript.new()
	arthur.position = Vector2(0.0, 20.0) # Centro do tapete acústico
	arthur.scale = Vector2(2.1, 2.1)
	arthur.set_meta("custom_assembly", assembly_mode)
	arthur.set_meta("custom_eyewear", "dark_shades")
	arthur.set_meta("custom_headwear", "none")
	arthur.set_meta("custom_holding_item", "cello")
	arthur.set_direction(Vector2i(1, 1), true) # Frente para a câmera
	room.add_child(arthur)

	# 3. Camada de Frente (Estante de Partitura em frente ao Arthur e Feixe de Luz)
	var fg_drawer := CustomRoomDrawer.new()
	fg_drawer.setup(assembly_mode, is_low_res, "fg")
	room.add_child(fg_drawer)

	return room


# =========================================================================
# MOTOR 'PIXELPIPE 2.0' COM DISTÂNCIA PERCEPTIVA E DINÂMICA SEL-OUT
# =========================================================================
func _apply_pixelpipe_to_scene(raw_img: Image) -> Image:
	var w := raw_img.get_width()
	var h := raw_img.get_height()
	var lit := Image.create(w, h, false, Image.FORMAT_RGBA8)
	lit.fill(Color(0, 0, 0, 0))

	var lx := -0.65
	var ly := -0.75

	for y in range(h):
		for x in range(w):
			var c := raw_img.get_pixel(x, y)
			if c.a < 0.40:
				continue

			var base_col := Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0), 1.0)

			# Preserva tons absolutos (óculos preto, luz solar máxima e branco puro)
			if base_col.v < 0.16:
				lit.set_pixel(x, y, Color("#141018"))
				continue
			elif base_col == Color("#ffffff") or (base_col.r > 0.95 and base_col.g > 0.95 and base_col.b > 0.98):
				lit.set_pixel(x, y, Color("#ffffff"))
				continue

			# Estimativa de inclinação de superfície 2.5D
			var c_up := raw_img.get_pixel(x, maxi(0, y - 1))
			var c_dn := raw_img.get_pixel(x, mini(h - 1, y + 1))
			var c_lf := raw_img.get_pixel(maxi(0, x - 1), y)
			var c_rt := raw_img.get_pixel(mini(w - 1, x + 1), y)

			var grad_x: float = (c_rt.v - c_lf.v) * 1.4
			var grad_y: float = (c_dn.v - c_up.v) * 1.4
			var normal_dot: float = -(grad_x * lx + grad_y * ly)

			var is_skin: bool = base_col.r > 0.8 and base_col.g > 0.6 and base_col.b > 0.5
			var light_factor: float = clampf(normal_dot, -0.14, 0.12)
			if is_skin:
				light_factor = clampf(normal_dot * 0.4, -0.06, 0.05)

			var bayer_ofs: float = BAYER_2X2[y % 2][x % 2] * (0.4 if is_skin else 0.85)

			var target_col := Color(
				clampf(base_col.r + light_factor + bayer_ofs, 0.0, 1.0),
				clampf(base_col.g + light_factor + bayer_ofs, 0.0, 1.0),
				clampf(base_col.b + light_factor * 0.7 + bayer_ofs, 0.0, 1.0),
				1.0
			)

			lit.set_pixel(x, y, _nearest_scene_palette(target_col))

	# Dynamic Sel-Out 1px suave
	var out: Image = lit.duplicate() as Image
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if lit.get_pixel(x, y).a >= 0.5:
				continue
			var n_opaco := false
			var nearest_inner_col := Color.BLACK
			for ofs in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var sc: Color = lit.get_pixel(x + ofs.x, y + ofs.y)
				if sc.a >= 0.5:
					n_opaco = true
					nearest_inner_col = sc
					break
			if n_opaco:
				var sel_col := Color("#141018")
				if y < h * 0.60 and x < w * 0.60:
					if nearest_inner_col.r > 0.6 and nearest_inner_col.g > 0.4:
						sel_col = Color("#54250a") # Madeira / Ouro
					elif nearest_inner_col.r > 0.5:
						sel_col = Color("#4a1714") # Terracota
				out.set_pixel(x, y, sel_col)

	return out


func _nearest_scene_palette(c: Color) -> Color:
	var best_col := SCENE_PALETTE[0]
	var min_dist := 999999.0
	for pal in SCENE_PALETTE:
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
	# No frame 4: processa o Pixelpipe 2.0 e os recortes de zoom
	if _frames == 4 and not _processed:
		_processed = true
		_process_pixelpipe_and_crops()

	# No frame 8: captura a tela mestre e salva o PNG
	if _frames >= 8:
		var main_img: Image = _vp.get_texture().get_image()
		var out_path := "C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/cenario_paper_cutout_vs_pixelart.png"
		var err := main_img.save_png(out_path)
		if err == OK:
			print("SUCCESS: Cenário comparativo salvo com sucesso em: ", out_path)
		else:
			print("ERROR: Falha ao salvar cenário: ", err)
		quit()
	return false


func _process_pixelpipe_and_crops() -> void:
	# 1. Pega imagem bruta do Cenário B (Pixel Art) e aplica Pixelpipe 2.0
	var raw_pix: Image = _pixel_sub.get_texture().get_image()
	var clean_pix: Image = _apply_pixelpipe_to_scene(raw_pix)
	_pixel_main_rect.texture = ImageTexture.create_from_image(clean_pix)

	# 2. Crops de zoom 2.2x focados no Sr. Arthur com o Violoncelo e a estante
	# No Paper (720x540): Arthur está em (360, 330)
	var paper_crop_rect := Rect2i(210, 240, 300, 180)
	var p_img: Image = _paper_sub.get_texture().get_image()
	var p_crop: Image = p_img.get_region(paper_crop_rect)
	_zoom_paper_rect.texture = ImageTexture.create_from_image(p_crop)

	# No Pixel (360x270): Arthur está em (180, 165)
	var pixel_crop_rect := Rect2i(105, 120, 150, 90)
	var pix_crop: Image = clean_pix.get_region(pixel_crop_rect)
	_zoom_pixel_rect.texture = ImageTexture.create_from_image(pix_crop)


# =========================================================================
# CLASSE DE DESENHO PROCEDURAL DA SALA (PISO, PAREDES E MÓVEIS 2.5D)
# =========================================================================
class CustomRoomDrawer extends Node2D:
	var mode: String = "paper_cutout"
	var is_pixel: bool = false
	var layer: String = "bg"

	func setup(p_mode: String, p_is_pixel: bool, p_layer: String = "bg") -> void:
		mode = p_mode
		is_pixel = p_pixel_or_not(p_is_pixel)
		layer = p_layer

	func p_pixel_or_not(val: bool) -> bool:
		return val

	# Converte coordenadas do grid isométrico 2:1 para a tela
	func iso(gx: float, gy: float, gz: float) -> Vector2:
		var tile_w := 64.0
		var tile_h := 32.0
		return Vector2((gx - gy) * (tile_w * 0.5), (gx + gy) * (tile_h * 0.5) - gz * 1.5)

	func _draw() -> void:
		var out_col := Color(0.18, 0.12, 0.08, 0.28) if mode == "paper_cutout" else Color(0, 0, 0, 0)

		if layer == "bg":
			# 1. Parede de Fundo e Parede Lateral (Boiserie Acústica)
			_draw_walls(out_col)

			# 2. Piso de Madeira Nobre (Tábua Corrida de Carvalho com Parquet)
			_draw_parquet_floor(out_col)

			# 3. Tapete Acústico Clássico Carmim (sob o músico)
			_draw_acoustic_carpet(out_col)

			# 4. Móveis Acústicos & Marcos do Cenário (Fundo)
			_draw_grandfather_clock(out_col)
			_draw_luthier_shelf(out_col)
			_draw_grand_piano(out_col)
			_draw_cozy_armchair(out_col)
		else:
			# 5. Estante de Partitura Dourada (em frente e à esquerda do Arthur)
			_draw_music_stand(out_col)

			# 6. Feixe de Luz Solar da Janela Colonial (God Ray)
			_draw_sunbeam_godray()


	func _draw_walls(out_col: Color) -> void:
		# Parede de Fundo (-Y / Norte-Leste)
		var p_w_top_l := iso(-5.0, -4.0, 110.0)
		var p_w_top_c := iso(0.0, -4.0, 110.0)
		var p_w_top_r := iso(5.0, -4.0, 110.0)
		var p_w_bot_l := iso(-5.0, -4.0, 0.0)
		var p_w_bot_c := iso(0.0, -4.0, 0.0)
		var p_w_bot_r := iso(5.0, -4.0, 0.0)

		# Parede Lateral (-X / Norte-Oeste)
		var p_wl_top_l := iso(-5.0, 4.0, 110.0)
		var p_wl_bot_l := iso(-5.0, 4.0, 0.0)

		# Painel de Reboco Creme Acolhedor
		draw_colored_polygon(PackedVector2Array([p_wl_top_l, p_w_top_l, p_w_bot_l, p_wl_bot_l]), Color("#b0a18f"))
		draw_colored_polygon(PackedVector2Array([p_w_top_l, p_w_top_r, p_w_bot_r, p_w_bot_l]), Color("#c7b8a5"))

		# Boiserie Acústica de Carvalho (Rodapé alto e painéis de madeira até 45px de altura)
		var p_boi_l := iso(-5.0, 4.0, 42.0)
		var p_boi_c := iso(-5.0, -4.0, 42.0)
		var p_boi_r := iso(5.0, -4.0, 42.0)
		draw_colored_polygon(PackedVector2Array([p_boi_l, p_boi_c, p_w_bot_l, p_wl_bot_l]), Color("#54361e"))
		draw_colored_polygon(PackedVector2Array([p_boi_c, p_boi_r, p_w_bot_r, p_w_bot_l]), Color("#6e4728"))

		# Friso de madeira no topo do boiserie
		draw_line(p_boi_l, p_boi_c, Color("#8c5a35"), 2.2, true)
		draw_line(p_boi_c, p_boi_r, Color("#8c5a35"), 2.2, true)

		# Janela Alta de Arco Colonial na parede esquerda (-X)
		var j_c := iso(-5.0, 0.0, 75.0)
		var j_w := 24.0
		var j_h := 38.0
		var j_pts := PackedVector2Array([
			j_c + Vector2(-j_w, j_h * 0.4),
			j_c + Vector2(-j_w, -j_h * 0.3),
			j_c + Vector2(0.0, -j_h * 0.65),
			j_c + Vector2(j_w, -j_h * 0.3),
			j_c + Vector2(j_w, j_h * 0.4),
		])
		if mode == "paper_cutout":
			var sh_j := PackedVector2Array()
			for pt in j_pts:
				sh_j.append(pt + Vector2(2.0, 3.0))
			draw_colored_polygon(sh_j, Color(0.05, 0.03, 0.07, 0.25))

		# Vidro iluminado da janela
		draw_colored_polygon(j_pts, Color("#d5ecfc"))
		draw_polyline(j_pts, Color("#3d2817"), 3.2, true)
		# Caixilho em cruz colonial
		draw_line(j_c + Vector2(0.0, -j_h * 0.65), j_c + Vector2(0.0, j_h * 0.4), Color("#3d2817"), 1.8)
		draw_line(j_c + Vector2(-j_w, 0.0), j_c + Vector2(j_w, 0.0), Color("#3d2817"), 1.8)


	func _draw_parquet_floor(out_col: Color) -> void:
		# Grid de piso 10x8 tiles isométricos
		for gy in range(-4, 4):
			for gx in range(-5, 5):
				var p0 := iso(float(gx), float(gy), 0.0)
				var p1 := iso(float(gx + 1), float(gy), 0.0)
				var p2 := iso(float(gx + 1), float(gy + 1), 0.0)
				var p3 := iso(float(gx), float(gy + 1), 0.0)

				# Alternância sutil de tábuas de carvalho nobre (herringbone)
				var is_alt := (gx + gy) % 2 == 0
				var tile_col := Color("#875630") if is_alt else Color("#7a4b27")

				draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), tile_col)

				# Linhas finas de encaixe das tábuas
				draw_line(p0, p1, Color("#523016"), 1.0)
				draw_line(p3, p2, Color("#523016"), 1.0)
				draw_line(p0.lerp(p3, 0.5), p1.lerp(p2, 0.5), Color("#693e1e"), 1.0)


	func _draw_acoustic_carpet(out_col: Color) -> void:
		# Tapete clássico carmim sob o violoncelista (gx: -1.8 a 2.2, gy: -1.5 a 2.5)
		var c0 := iso(-1.8, -1.5, 1.0)
		var c1 := iso(2.2, -1.5, 1.0)
		var c2 := iso(2.2, 2.5, 1.0)
		var c3 := iso(-1.8, 2.5, 1.0)
		var poly := PackedVector2Array([c0, c1, c2, c3])

		if mode == "paper_cutout":
			var sh := PackedVector2Array()
			for pt in poly:
				sh.append(pt + Vector2(1.8, 2.5))
			draw_colored_polygon(sh, Color(0.05, 0.03, 0.07, 0.22))

		draw_colored_polygon(poly, Color("#9e3832")) # Carmim acolhedor
		# Borda dourada do tapete
		var inner_poly := PackedVector2Array([
			c0.lerp(c2, 0.08),
			c1.lerp(c3, 0.08),
			c2.lerp(c0, 0.08),
			c3.lerp(c1, 0.08),
		])
		draw_polyline(inner_poly, Color("#e6ba4c"), 1.5, true)
		# Franjas de linho bege nas extremidades
		draw_line(c0, c1, Color("#e8deb8"), 1.8)
		draw_line(c3, c2, Color("#e8deb8"), 1.8)


	func _draw_grandfather_clock(out_col: Color) -> void:
		# Relógio de pêndulo antigo no canto da sala (gx: -4.4, gy: -3.5)
		var base_p := iso(-4.4, -3.5, 0.0)
		var top_p := iso(-4.4, -3.5, 78.0)
		var w := 14.0

		if mode == "paper_cutout":
			draw_circle(base_p + Vector2(1.5, 2.0), 10.0, Color(0.05, 0.03, 0.07, 0.25))

		# Caixa de nogueira escura
		var box_pts := PackedVector2Array([
			base_p + Vector2(-w * 0.5, 0.0),
			base_p + Vector2(w * 0.5, 0.0),
			top_p + Vector2(w * 0.5, 0.0),
			top_p + Vector2(0.0, -6.0), # Frontão em arco
			top_p + Vector2(-w * 0.5, 0.0),
		])
		draw_colored_polygon(box_pts, Color("#422413"))
		draw_polyline(box_pts, Color("#26140a"), 1.4, true)

		# Mostrador dourado com aro de latão
		var dial_p := top_p + Vector2(0.0, 14.0)
		draw_circle(dial_p, 5.5, Color("#e6c047"))
		draw_circle(dial_p, 4.2, Color("#fff8e0"))
		draw_circle(dial_p, 0.8, Color("#1a1008"))
		draw_line(dial_p, dial_p + Vector2(0.0, -3.0), Color("#1a1008"), 1.0)
		draw_line(dial_p, dial_p + Vector2(2.0, 0.0), Color("#1a1008"), 1.0)

		# Vidro do pêndulo e lente de latão
		var glass_p := base_p.lerp(top_p, 0.45)
		draw_rect(Rect2(glass_p - Vector2(3.5, 12.0), Vector2(7.0, 24.0)), Color("#18141e"), true)
		draw_line(glass_p + Vector2(0.0, -10.0), glass_p + Vector2(1.5, 6.0), Color("#e6c047"), 1.4)
		draw_circle(glass_p + Vector2(1.5, 7.0), 3.0, Color("#ffd44d"))


	func _draw_luthier_shelf(out_col: Color) -> void:
		# Prateleira de lutherie na parede de fundo (-Y) com frascos de verniz e volutas
		var sp0 := iso(-1.5, -3.8, 62.0)
		var sp1 := iso(2.5, -3.8, 62.0)
		draw_line(sp0, sp1, Color("#5e371a"), 3.4, true)
		draw_line(sp0 + Vector2(0, 1), sp1 + Vector2(0, 1), Color("#2d180a"), 1.4)

		# 3 Frascos de verniz âmbar / óleo de linhaça
		var colors := [Color("#e8942e"), Color("#b8481d"), Color("#ffd24d")]
		for i in range(3):
			var fp := sp0.lerp(sp1, 0.25 + float(i) * 0.25) + Vector2(0.0, -5.0)
			draw_circle(fp, 3.2, colors[i])
			draw_rect(Rect2(fp - Vector2(1.2, 5.0), Vector2(2.4, 2.5)), Color("#d9cfb8"), true)


	func _draw_grand_piano(out_col: Color) -> void:
		# Piano de cauda clássico em ébano no canto norte-leste (gx: 2.2 a 4.5, gy: -3.8 a -1.2)
		var p_kb0 := iso(2.2, -1.2, 28.0)
		var p_kb1 := iso(3.4, -1.2, 28.0)
		var p_tail := iso(4.6, -3.6, 28.0)
		var p_rim0 := iso(2.2, -3.6, 28.0)

		# Sombra do corpo do piano no piso
		var sh_pts := PackedVector2Array([
			iso(2.2, -1.2, 0.0),
			iso(3.4, -1.2, 0.0),
			iso(4.6, -3.6, 0.0),
			iso(2.2, -3.6, 0.0),
		])
		draw_colored_polygon(sh_pts, Color(0.05, 0.03, 0.07, 0.28))

		# 3 Pernas entalhadas em ébano
		for leg_pos in [iso(2.3, -1.3, 0.0), iso(3.3, -1.3, 0.0), iso(4.5, -3.5, 0.0)]:
			draw_line(leg_pos, leg_pos + Vector2(0.0, -28.0), Color("#120f18"), 2.8, true)
			draw_circle(leg_pos, 1.4, Color("#d9a838")) # Rodízio de latão

		# Caixa acústica do piano de cauda
		var body_poly := PackedVector2Array([
			p_kb0,
			p_kb1,
			p_kb1.lerp(p_tail, 0.5) + Vector2(4.0, -8.0), # Curva clássica da cauda
			p_tail,
			p_rim0,
		])
		draw_colored_polygon(body_poly, Color("#1a1622"))
		draw_polyline(body_poly, Color("#0d0b12"), 1.6, true)

		# Teclado de marfim iluminado
		draw_line(p_kb0, p_kb1, Color("#f7f2e4"), 4.0, true)
		draw_line(p_kb0, p_kb1, Color("#18141e"), 1.2, true)

		# Tampa aberta em 45° apoiada na vara de suporte de latão
		var lid_pts := PackedVector2Array([
			p_rim0,
			p_tail,
			p_tail + Vector2(2.0, -22.0),
			p_rim0 + Vector2(0.0, -24.0),
		])
		draw_colored_polygon(lid_pts, Color("#2c2438"))
		draw_polyline(lid_pts, Color("#120f18"), 1.4, true)
		# Vara de suporte de latão
		draw_line(p_kb1.lerp(p_tail, 0.4), p_rim0.lerp(p_tail, 0.4) + Vector2(1.0, -23.0), Color("#e6c047"), 1.5)


	func _draw_cozy_armchair(out_col: Color) -> void:
		# Poltrona de veludo aconchegante verde-sálvia (gx: -3.6, gy: 2.2)
		var p_base := iso(-3.6, 2.2, 0.0)
		var p_seat := iso(-3.6, 2.2, 14.0)

		# Sombra no piso
		draw_circle(p_base + Vector2(1.0, 1.5), 16.0, Color(0.05, 0.03, 0.07, 0.22))

		# Almofada e braços
		var seat_poly := PackedVector2Array([
			p_seat + Vector2(-12.0, 0.0),
			p_seat + Vector2(0.0, 6.0),
			p_seat + Vector2(12.0, 0.0),
			p_seat + Vector2(0.0, -6.0),
		])
		draw_colored_polygon(seat_poly, Color("#4e6e53")) # Veludo verde-sálvia
		# Espaldar alto
		var back_poly := PackedVector2Array([
			p_seat + Vector2(-12.0, 0.0),
			p_seat + Vector2(-12.0, -22.0),
			p_seat + Vector2(0.0, -26.0),
			p_seat + Vector2(0.0, -6.0),
		])
		draw_colored_polygon(back_poly, Color("#5e8264"))
		draw_polyline(back_poly, Color("#2b3d2e"), 1.4, true)


	func _draw_music_stand(out_col: Color) -> void:
		# Estante de partitura em latão dourado posicionada à esquerda e em frente ao Sr. Arthur
		var p_base := Vector2(-38.0, 48.0)
		var p_top  := Vector2(-38.0, 5.0)

		# Sombra do tripé
		draw_circle(p_base + Vector2(1.0, 1.5), 7.0, Color(0.05, 0.03, 0.07, 0.22))

		# Tripé de latão e haste telescópica
		draw_line(p_base, p_base + Vector2(-8.0, 4.0), Color("#a67c1e"), 1.8)
		draw_line(p_base, p_base + Vector2(7.0, 4.5), Color("#a67c1e"), 1.8)
		draw_line(p_base, p_base + Vector2(0.0, -5.0), Color("#805e12"), 1.6)
		draw_line(p_base, p_top, Color("#e0b034"), 2.2, true)

		# Prancha da partitura em ângulo
		var desk_pts := PackedVector2Array([
			p_top + Vector2(-15.0, 2.0),
			p_top + Vector2(15.0, 2.0),
			p_top + Vector2(13.0, -16.0),
			p_top + Vector2(-13.0, -16.0),
		])
		if mode == "paper_cutout":
			var sh_d := PackedVector2Array()
			for pt in desk_pts:
				sh_d.append(pt + Vector2(1.2, 1.6))
			draw_colored_polygon(sh_d, Color(0.05, 0.03, 0.07, 0.20))

		draw_colored_polygon(desk_pts, Color("#c49829"))
		draw_polyline(desk_pts, Color("#573d05"), 1.2, true)

		# Duas folhas de partitura branca aberta com pautas musicais
		var sheet_l := Rect2(p_top + Vector2(-12.0, -15.0), Vector2(11.0, 15.0))
		var sheet_r := Rect2(p_top + Vector2(1.0, -15.0), Vector2(11.0, 15.0))
		draw_rect(sheet_l, Color("#fcfbf7"), true)
		draw_rect(sheet_r, Color("#fcfbf7"), true)
		# Linhas de pauta musical
		for li in range(3):
			var ly := -12.0 + float(li) * 4.0
			draw_line(p_top + Vector2(-10.0, ly), p_top + Vector2(-3.0, ly), Color("#241e17"), 0.9)
			draw_line(p_top + Vector2(3.0, ly), p_top + Vector2(10.0, ly), Color("#241e17"), 0.9)


	func _draw_sunbeam_godray() -> void:
		# Feixe de luz solar entrando pela janela colonial esquerda e tocando o piso
		var j_c := iso(-5.0, 0.0, 75.0)
		var p_floor_l := iso(-3.0, -1.0, 0.0)
		var p_floor_r := iso(2.0, 1.5, 0.0)

		var ray_poly := PackedVector2Array([
			j_c + Vector2(-18.0, -10.0),
			j_c + Vector2(18.0, 10.0),
			p_floor_r + Vector2(25.0, 12.0),
			p_floor_l + Vector2(-15.0, -12.0),
		])
		# Luz solar dourada matinal translúcida
		draw_colored_polygon(ray_poly, Color(1.0, 0.95, 0.72, 0.14))
