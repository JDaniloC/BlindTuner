extends SceneTree
## Demonstração Visual das Fases Jogáveis no Estilo Paper-Cutout:
## Renderiza os 3 ambientes icônicos da campanha do BlindTuner:
## 1. Quarto do Mestre (Fase 1.1 — Canção de Ninar do Rádio)
## 2. Banheiro dos Ecos (Fase 1.2 — A Gota d'Água Acústica)
## 3. Salão dos Dois Violinos (Fase 1.3 — A Sala de Concerto & Violoncelo)

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")

var _frames := 0
var _vp: SubViewport
var _room_vps: Array[SubViewport] = []
var _zoom_rects: Array[TextureRect] = []
var _processed := false

func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1800, 1140)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1800, 1140)
	bg.color = Color("#0f0e15")
	_vp.add_child(bg)

	_build_master_header()

	# Configurações das 3 Salas Jogáveis
	var rooms_data: Array[Dictionary] = [
		{
			"type": "quarto",
			"title": "1. QUARTO DO MESTRE (Fase 1.1 — Canção de Ninar)",
			"subtitle": "Carvalho acolhedor, cama macia, abajur quente e rádio em Sol Maior.",
			"bar_col": Color("#e8985e"),
			"desc_box": "• Farol Sonoro: Rádio vintage com melodia em Sol Maior\n• Mecânica: Caminhada com bengala e ecolocalização suave\n• Obstáculos: Chinelos aos pés da cama e criado-mudo",
		},
		{
			"type": "banheiro",
			"title": "2. BANHEIRO DOS ECOS (Fase 1.2 — A Gota d'Água)",
			"subtitle": "Azulejos claros, banheira clássica e pia com gota acústica ritmada.",
			"bar_col": Color("#58b2d8"),
			"desc_box": "• Farol Sonoro: Gota d'água pingando com ondas concêntricas de eco\n• Mecânica: Escuta atenta para identificar a direção do gotejar\n• Obstáculos: Tapete antiderrapante e banheira clássica",
		},
		{
			"type": "sala",
			"title": "3. SALÃO DOS DOIS VIOLINOS (Fase 1.3 — Concerto)",
			"subtitle": "Parquet nobre, piano de cauda em ébano, relógio e Arthur ao violoncelo mel.",
			"bar_col": Color("#d4a84b"),
			"desc_box": "• Farol Sonoro: Ressonância da corda solta Dó/Sol do violoncelo\n• Mecânica: Scroll de afinação contínua 360° com arco de concerto\n• Mobiliário: Piano de cauda aberto e poltrona verde-sálvia",
		},
	]

	# Renderiza os 3 Cards de Salas
	for i in range(rooms_data.size()):
		var r_data: Dictionary = rooms_data[i]
		var col_x := 40.0 + float(i) * 585.0

		# Cabeçalho da Coluna
		_add_room_column_header(Vector2(col_x, 78.0), r_data["title"], r_data["subtitle"], r_data["bar_col"])

		# Card de Visualização do Cenário (550x580)
		var card := _make_card_backdrop(Vector2(col_x, 138.0), Vector2(550, 590), Color("#15131c"), Color("#272033"))
		_vp.add_child(card)

		# SubViewport da Sala em Alta Resolução (530x570)
		var sub := SubViewport.new()
		sub.size = Vector2i(530, 570)
		sub.transparent_bg = true
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_vp.add_child(sub)
		_room_vps.append(sub)

		var room_node := _build_room_scene(r_data["type"])
		sub.add_child(room_node)

		var trect := TextureRect.new()
		trect.texture = sub.get_texture()
		trect.size = Vector2(530, 570)
		trect.position = Vector2(col_x + 10.0, 148.0)
		_vp.add_child(trect)

		# Card Inferior de Ficha Técnica & Mecânica (550x330)
		var b_card := _make_card_backdrop(Vector2(col_x, 745.0), Vector2(550, 360), Color("#13111a"), Color("#221c2e"))
		_vp.add_child(b_card)

		var b_lbl := _make_label("Ficha Técnica & Interações Acústicas", Vector2(col_x + 20.0, 758.0), 14, r_data["bar_col"])
		_vp.add_child(b_lbl)

		var b_desc := Label.new()
		b_desc.text = r_data["desc_box"]
		b_desc.position = Vector2(col_x + 20.0, 785.0)
		b_desc.add_theme_font_size_override("font_size", 12)
		b_desc.add_theme_color_override("font_color", Color("#c7c2d6"))
		_vp.add_child(b_desc)

		# Recorte Macro de Zoom (Arthur & Interação em destaque)
		var z_lbl := _make_label("Destaque In-Game (Zoom de Interação 2.0x):", Vector2(col_x + 20.0, 855.0), 12, Color("#e6dfed"))
		_vp.add_child(z_lbl)

		var z_rect := TextureRect.new()
		z_rect.size = Vector2(510, 180)
		z_rect.position = Vector2(col_x + 20.0, 880.0)
		z_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		z_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_vp.add_child(z_rect)
		_zoom_rects.append(z_rect)


func _build_master_header() -> void:
	var h_panel := ColorRect.new()
	h_panel.size = Vector2(1800, 70)
	h_panel.color = Color("#161420")
	_vp.add_child(h_panel)

	var title := Label.new()
	title.text = "BlindTuner — O Estilo 'Paper-Cutout' Integrado às Fases Jogáveis da Campanha"
	title.position = Vector2(40.0, 12.0)
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("#fff6e8"))
	_vp.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Visualização das 3 salas completas: Quarto do Mestre, Banheiro dos Ecos e Salão de Concerto com móveis de cartolina 300g/m² e faróis acústicos vivos"
	subtitle.position = Vector2(40.0, 41.0)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#aba4c0"))
	_vp.add_child(subtitle)


func _add_room_column_header(pos: Vector2, title_txt: String, desc_txt: String, bar_color: Color) -> void:
	var bar := ColorRect.new()
	bar.size = Vector2(5, 38)
	bar.position = pos
	bar.color = bar_color
	_vp.add_child(bar)

	var title := Label.new()
	title.text = title_txt
	title.position = pos + Vector2(14.0, 0.0)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	_vp.add_child(title)

	var desc := Label.new()
	desc.text = desc_txt
	desc.position = pos + Vector2(14.0, 20.0)
	desc.size = Vector2(530, 24)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color("#a5a0b3"))
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
# CONSTRUÇÃO DE CADA SALA PROCEDURAL (2.5D PAPER-CUTOUT)
# =========================================================================
func _build_room_scene(room_type: String) -> Node2D:
	var root_node := Node2D.new()
	root_node.position = Vector2(265.0, 320.0)

	var drawer := PlayableRoomDrawer.new()
	drawer.setup(room_type)
	root_node.add_child(drawer)

	# Adiciona o Sr. Arthur em pose contextual para cada fase
	var arthur := ProceduralArthurScript.new()
	arthur.set_meta("custom_assembly", "paper_cutout")
	arthur.set_meta("custom_eyewear", "dark_shades")
	arthur.set_meta("custom_headwear", "none")
	arthur.scale = Vector2(1.9, 1.9)

	match room_type:
		"quarto":
			# Arthur caminhando com a bengala tátil em direção à cama
			arthur.position = Vector2(30.0, 25.0)
			arthur.anim_state = "walk"
			arthur.walk_phase = 1.35
			arthur.set_meta("custom_holding_item", "cane")
			arthur.set_direction(Vector2i(-1, 1), true)
		"banheiro":
			# Arthur caminhando com escuta atenta à gota d'água
			arthur.position = Vector2(20.0, 20.0)
			arthur.anim_state = "walk"
			arthur.walk_phase = 0.65
			arthur.set_meta("custom_holding_item", "cane")
			arthur.set_direction(Vector2i(-1, -1), true)
		"sala":
			# Arthur sentado no tapete carmim tocando violoncelo
			arthur.position = Vector2(5.0, 15.0)
			arthur.set_meta("custom_holding_item", "cello")
			arthur.set_direction(Vector2i(1, 1), true)

	root_node.add_child(arthur)

	# Adiciona elementos da frente (foreground: estante, ondas e feixes de luz)
	var fg_drawer := PlayableRoomFgDrawer.new()
	fg_drawer.setup(room_type)
	root_node.add_child(fg_drawer)

	return root_node


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 4:
		# Recortes de zoom 2.0x calibrados para cada sala
		var crop_rects := [
			Rect2i(130, 210, 280, 170), # Quarto: Arthur com a bengala e o rádio
			Rect2i(130, 200, 280, 170), # Banheiro: Arthur e a pia com a gota d'água
			Rect2i(120, 215, 280, 170), # Sala: Arthur tocando violoncelo no tapete
		]

		for i in range(3):
			var img: Image = _room_vps[i].get_texture().get_image()
			var crop: Image = img.get_region(crop_rects[i])
			_zoom_rects[i].texture = ImageTexture.create_from_image(crop)

	elif _frames >= 8:
		var main_img: Image = _vp.get_texture().get_image()
		var out_path := "C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/fases_paper_cutout_showcase.png"
		var err := main_img.save_png(out_path)
		if err == OK:
			print("SUCCESS: Showcase das fases em Paper-Cutout salvo com sucesso em: ", out_path)
		else:
			print("ERROR: Falha ao salvar showcase das fases: ", err)
		quit()

	return false


# =========================================================================
# DESENHO PROCEDURAL DAS 3 SALAS (BACKGROUND & MÓVEIS)
# =========================================================================
class PlayableRoomDrawer extends Node2D:
	var room_type: String = "quarto"

	func setup(p_type: String) -> void:
		room_type = p_type

	func iso(gx: float, gy: float, gz: float) -> Vector2:
		var tile_w := 56.0
		var tile_h := 28.0
		return Vector2((gx - gy) * (tile_w * 0.5), (gx + gy) * (tile_h * 0.5) - gz * 1.4)

	func _draw() -> void:
		match room_type:
			"quarto":
				_draw_quarto_room()
			"banheiro":
				_draw_banheiro_room()
			"sala":
				_draw_sala_room()


	# ---------------------------------------------------------------------
	# 1. QUARTO DO MESTRE (CAMA, CRIADO-MUDO, CÔMODA & RÁDIO)
	# ---------------------------------------------------------------------
	func _draw_quarto_room() -> void:
		# Paredes de madeira acolhedora no fundo (-X e -Y)
		var p_w_top_l := iso(-4.0, -3.5, 95.0)
		var p_w_top_r := iso(4.0, -3.5, 95.0)
		var p_w_bot_l := iso(-4.0, -3.5, 0.0)
		var p_w_bot_r := iso(4.0, -3.5, 0.0)
		var p_wl_top := iso(-4.0, 3.5, 95.0)
		var p_wl_bot := iso(-4.0, 3.5, 0.0)

		# Paredes creme de gesso com lambril de carvalho
		draw_colored_polygon(PackedVector2Array([p_wl_top, p_w_top_l, p_w_bot_l, p_wl_bot]), Color("#b8a692"))
		draw_colored_polygon(PackedVector2Array([p_w_top_l, p_w_top_r, p_w_bot_r, p_w_bot_l]), Color("#c7b8a5"))
		# Lambril de carvalho na base (até z=35)
		draw_colored_polygon(PackedVector2Array([iso(-4.0, 3.5, 35.0), iso(-4.0, -3.5, 35.0), p_w_bot_l, p_wl_bot]), Color("#5c3a20"))
		draw_colored_polygon(PackedVector2Array([iso(-4.0, -3.5, 35.0), iso(4.0, -3.5, 35.0), p_w_bot_r, p_w_bot_l]), Color("#6e4728"))

		# Janela com cortina de linho mostarda na parede esquerda (-X)
		var j_c := iso(-4.0, 0.0, 68.0)
		draw_rect(Rect2(j_c - Vector2(18.0, 22.0), Vector2(36.0, 44.0)), Color("#d4ebfc"), true)
		draw_rect(Rect2(j_c - Vector2(18.0, 22.0), Vector2(36.0, 44.0)), Color("#3b2210"), false, 2.0)
		# Cortinas dobradas em papel
		draw_colored_polygon(PackedVector2Array([j_c + Vector2(-22.0, -22.0), j_c + Vector2(-12.0, -22.0), j_c + Vector2(-14.0, 24.0), j_c + Vector2(-24.0, 24.0)]), Color("#e0a838"))
		draw_colored_polygon(PackedVector2Array([j_c + Vector2(12.0, -22.0), j_c + Vector2(22.0, -22.0), j_c + Vector2(24.0, 24.0), j_c + Vector2(14.0, 24.0)]), Color("#e0a838"))

		# Piso de Parquet em Carvalho
		for gy in range(-3, 4):
			for gx in range(-4, 4):
				var p0 := iso(float(gx), float(gy), 0.0)
				var p1 := iso(float(gx + 1), float(gy), 0.0)
				var p2 := iso(float(gx + 1), float(gy + 1), 0.0)
				var p3 := iso(float(gx), float(gy + 1), 0.0)
				var tile_col := Color("#875630") if (gx + gy) % 2 == 0 else Color("#784b26")
				draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), tile_col)
				draw_line(p0, p1, Color("#523014"), 0.8)
				draw_line(p3, p2, Color("#523014"), 0.8)

		# Cama de casal acolhedora em carvalho (gx: -3.0 a -1.0, gy: -2.5 a 0.5)
		var bed_base := iso(-2.0, -1.0, 0.0)
		# Sombra da cama
		draw_colored_polygon(PackedVector2Array([iso(-3.2, -2.7, 0.0), iso(-0.8, -2.7, 0.0), iso(-0.8, 0.7, 0.0), iso(-3.2, 0.7, 0.0)]), Color(0.05, 0.03, 0.07, 0.28))
		# Cabeceira de carvalho nobre
		draw_colored_polygon(PackedVector2Array([iso(-3.2, -2.5, 0.0), iso(-0.8, -2.5, 0.0), iso(-0.8, -2.5, 34.0), iso(-3.2, -2.5, 34.0)]), Color("#4a2b15"))
		# Colchão e colcha acolchoada mostarda
		draw_colored_polygon(PackedVector2Array([iso(-3.0, -2.4, 12.0), iso(-1.0, -2.4, 12.0), iso(-1.0, 0.5, 12.0), iso(-3.0, 0.5, 12.0)]), Color("#e8deb8"))
		draw_colored_polygon(PackedVector2Array([iso(-3.0, -1.2, 13.0), iso(-1.0, -1.2, 13.0), iso(-1.0, 0.5, 13.0), iso(-3.0, 0.5, 13.0)]), Color("#d99b26"))
		# Travesseiro branco macio
		draw_colored_polygon(PackedVector2Array([iso(-2.8, -2.3, 14.0), iso(-1.2, -2.3, 14.0), iso(-1.2, -1.5, 14.0), iso(-2.8, -1.5, 14.0)]), Color("#ffffff"))

		# Criado-mudo de carvalho ao lado da cama (gx: -0.5, gy: -2.8) com abajur
		var ns_p := iso(-0.4, -2.8, 0.0)
		draw_colored_polygon(PackedVector2Array([iso(-0.8, -3.2, 0.0), iso(0.0, -3.2, 0.0), iso(0.0, -2.4, 0.0), iso(-0.8, -2.4, 0.0)]), Color(0.05, 0.03, 0.07, 0.22))
		draw_colored_polygon(PackedVector2Array([iso(-0.8, -3.2, 16.0), iso(0.0, -3.2, 16.0), iso(0.0, -2.4, 16.0), iso(-0.8, -2.4, 16.0)]), Color("#6e4728"))
		# Abajur aceso com cúpula creme
		var lamp_top := iso(-0.4, -2.8, 28.0)
		draw_colored_polygon(PackedVector2Array([lamp_top + Vector2(-6.0, 6.0), lamp_top + Vector2(6.0, 6.0), lamp_top + Vector2(4.0, -6.0), lamp_top + Vector2(-4.0, -6.0)]), Color("#fff4cc"))
		draw_circle(lamp_top, 22.0, Color(1.0, 0.90, 0.50, 0.16)) # Halo de luz

		# Cômoda com rádio antigo no canto leste (gx: 2.2, gy: -3.0)
		var dress_p := iso(2.2, -2.8, 0.0)
		draw_colored_polygon(PackedVector2Array([iso(1.5, -3.2, 22.0), iso(2.9, -3.2, 22.0), iso(2.9, -2.4, 22.0), iso(1.5, -2.4, 22.0)]), Color("#5e371a"))
		# Rádio valvulado com dial âmbar (Farol Sonoro)
		var radio_p := iso(2.2, -2.8, 24.0)
		draw_rect(Rect2(radio_p - Vector2(10.0, 8.0), Vector2(20.0, 16.0)), Color("#3b200d"), true)
		draw_rect(Rect2(radio_p - Vector2(7.0, 5.0), Vector2(8.0, 10.0)), Color("#f0a824"), true) # Dial âmbar
		draw_circle(radio_p + Vector2(4.0, -1.0), 1.8, Color("#d9a838")) # Botões dourados

		# Chinelos de feltro marrom aos pés da cama
		var slipper_p := iso(-2.0, 1.2, 0.0)
		draw_colored_polygon(PackedVector2Array([slipper_p + Vector2(-4.0, 0.0), slipper_p + Vector2(0.0, 2.0), slipper_p + Vector2(4.0, 0.0), slipper_p + Vector2(0.0, -2.0)]), Color("#4d2b1a"))


	# ---------------------------------------------------------------------
	# 2. BANHEIRO DOS ECOS (AZULEJOS, BANHEIRA, CUBA COM GOTA D'ÁGUA)
	# ---------------------------------------------------------------------
	func _draw_banheiro_room() -> void:
		# Paredes com meia-parede de azulejos brancos e pintura ardósia acima
		var p_w_top_l := iso(-4.0, -3.5, 95.0)
		var p_w_top_r := iso(4.0, -3.5, 95.0)
		var p_w_bot_l := iso(-4.0, -3.5, 0.0)
		var p_w_bot_r := iso(4.0, -3.5, 0.0)
		var p_wl_top := iso(-4.0, 3.5, 95.0)
		var p_wl_bot := iso(-4.0, 3.5, 0.0)

		draw_colored_polygon(PackedVector2Array([p_wl_top, p_w_top_l, p_w_bot_l, p_wl_bot]), Color("#8aa0b5"))
		draw_colored_polygon(PackedVector2Array([p_w_top_l, p_w_top_r, p_w_bot_r, p_w_bot_l]), Color("#9bb4cc"))
		# Meia-parede de azulejos claros
		draw_colored_polygon(PackedVector2Array([iso(-4.0, 3.5, 45.0), iso(-4.0, -3.5, 45.0), p_w_bot_l, p_wl_bot]), Color("#d9e4ec"))
		draw_colored_polygon(PackedVector2Array([iso(-4.0, -3.5, 45.0), iso(4.0, -3.5, 45.0), p_w_bot_r, p_w_bot_l]), Color("#e8f0f6"))
		draw_line(iso(-4.0, 3.5, 45.0), iso(-4.0, -3.5, 45.0), Color("#4d667c"), 1.8)
		draw_line(iso(-4.0, -3.5, 45.0), iso(4.0, -3.5, 45.0), Color("#4d667c"), 1.8)

		# Piso de Azulejos Geométricos Claros
		for gy in range(-3, 4):
			for gx in range(-4, 4):
				var p0 := iso(float(gx), float(gy), 0.0)
				var p1 := iso(float(gx + 1), float(gy), 0.0)
				var p2 := iso(float(gx + 1), float(gy + 1), 0.0)
				var p3 := iso(float(gx), float(gy + 1), 0.0)
				var tile_col := Color("#d6e2eb") if (gx + gy) % 2 == 0 else Color("#e2edf5")
				draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), tile_col)
				draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), Color("#9fb4c4"), 0.8)

		# Banheira clássica vintage branca com pés de leão (gx: -3.2 a -1.2, gy: -2.5 a 0.0)
		var tub_pts := PackedVector2Array([
			iso(-3.2, -2.5, 14.0),
			iso(-1.2, -2.5, 14.0),
			iso(-1.2, 0.0, 14.0),
			iso(-3.2, 0.0, 14.0),
		])
		draw_colored_polygon(PackedVector2Array([iso(-3.2, -2.5, 0.0), iso(-1.2, -2.5, 0.0), iso(-1.2, 0.0, 0.0), iso(-3.2, 0.0, 0.0)]), Color(0.05, 0.03, 0.07, 0.24))
		draw_colored_polygon(tub_pts, Color("#ffffff"))
		draw_polyline(tub_pts, Color("#90a6b8"), 1.4, true)
		# Interior da banheira com água azul translúcida
		draw_colored_polygon(PackedVector2Array([iso(-3.0, -2.3, 12.0), iso(-1.4, -2.3, 12.0), iso(-1.4, -0.2, 12.0), iso(-3.0, -0.2, 12.0)]), Color("#88c8e8"))

		# Gabinete de Banheiro + Cuba de Porcelana + Espelho (gx: 1.5, gy: -3.2)
		var sink_base := iso(1.5, -3.2, 0.0)
		draw_colored_polygon(PackedVector2Array([iso(0.8, -3.5, 16.0), iso(2.2, -3.5, 16.0), iso(2.2, -2.5, 16.0), iso(0.8, -2.5, 16.0)]), Color("#ffffff"))
		# Cuba de porcelana com interior côncavo
		var basin_c := iso(1.5, -3.0, 16.0)
		draw_circle(basin_c, 5.5, Color("#d6e4ed"))
		draw_circle(basin_c, 4.0, Color("#a8c8dc")) # Água no fundo da cuba
		# Torneira cromada
		draw_line(basin_c + Vector2(0.0, -4.0), basin_c + Vector2(0.0, -8.0), Color("#7b8c99"), 2.0, true)
		# Espelho oval na parede
		var mirror_c := iso(1.5, -3.4, 38.0)
		draw_circle(mirror_c, 8.5, Color("#c8e6f7"))
		draw_arc(mirror_c, 8.5, 0.0, TAU, 20, Color("#5e7991"), 1.4)

		# Vaso Sanitário Retrô no canto leste (gx: 3.2, gy: -2.5)
		var toilet_p := iso(3.2, -2.5, 0.0)
		draw_colored_polygon(PackedVector2Array([iso(2.8, -2.8, 12.0), iso(3.6, -2.8, 12.0), iso(3.6, -2.0, 12.0), iso(2.8, -2.0, 12.0)]), Color("#f5f9fc"))
		# Caixa acoplada alta
		draw_rect(Rect2(iso(3.2, -2.8, 22.0) - Vector2(6.0, 8.0), Vector2(12.0, 16.0)), Color("#f0f5fa"), true)

		# Tapete felpudo antiderrapante sálvia/verde-água (gx: -0.5, gy: 0.5)
		var mat_poly := PackedVector2Array([iso(-1.2, 0.2, 1.0), iso(0.2, 0.2, 1.0), iso(0.2, 1.2, 1.0), iso(-1.2, 1.2, 1.0)])
		draw_colored_polygon(mat_poly, Color("#6ea389"))
		draw_polyline(mat_poly, Color("#4d7561"), 1.2, true)


	# ---------------------------------------------------------------------
	# 3. SALÃO DE CONCERTO (PARQUET NOBRE, PIANO DE CAUDA, RELÓGIO & TAPETE)
	# ---------------------------------------------------------------------
	func _draw_sala_room() -> void:
		# Paredes com Boiserie Clássica de Lutherie
		var p_w_top_l := iso(-4.0, -3.5, 95.0)
		var p_w_top_r := iso(4.0, -3.5, 95.0)
		var p_w_bot_l := iso(-4.0, -3.5, 0.0)
		var p_w_bot_r := iso(4.0, -3.5, 0.0)
		var p_wl_top := iso(-4.0, 3.5, 95.0)
		var p_wl_bot := iso(-4.0, 3.5, 0.0)

		draw_colored_polygon(PackedVector2Array([p_wl_top, p_w_top_l, p_w_bot_l, p_wl_bot]), Color("#8c725c"))
		draw_colored_polygon(PackedVector2Array([p_w_top_l, p_w_top_r, p_w_bot_r, p_w_bot_l]), Color("#a1866f"))
		# Boiserie nogueira escura
		draw_colored_polygon(PackedVector2Array([iso(-4.0, 3.5, 38.0), iso(-4.0, -3.5, 38.0), p_w_bot_l, p_wl_bot]), Color("#4a2b15"))
		draw_colored_polygon(PackedVector2Array([iso(-4.0, -3.5, 38.0), iso(4.0, -3.5, 38.0), p_w_bot_r, p_w_bot_l]), Color("#5e371a"))

		# Piso de Parquet em Espinha de Peixe (Herringbone)
		for gy in range(-3, 4):
			for gx in range(-4, 4):
				var p0 := iso(float(gx), float(gy), 0.0)
				var p1 := iso(float(gx + 1), float(gy), 0.0)
				var p2 := iso(float(gx + 1), float(gy + 1), 0.0)
				var p3 := iso(float(gx), float(gy + 1), 0.0)
				var tile_col := Color("#7d4b26") if (gx + gy) % 2 == 0 else Color("#6b3f1e")
				draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), tile_col)
				draw_line(p0, p1, Color("#472810"), 0.8)
				draw_line(p3, p2, Color("#472810"), 0.8)

		# Tapete Carmim Persa no centro sob o violoncelista
		var c0 := iso(-1.5, -1.2, 1.0)
		var c1 := iso(1.5, -1.2, 1.0)
		var c2 := iso(1.5, 1.8, 1.0)
		var c3 := iso(-1.5, 1.8, 1.0)
		var rug_poly := PackedVector2Array([c0, c1, c2, c3])
		draw_colored_polygon(rug_poly, Color("#8c2b26"))
		var inner_rug := PackedVector2Array([c0.lerp(c2, 0.08), c1.lerp(c3, 0.08), c2.lerp(c0, 0.08), c3.lerp(c1, 0.08)])
		draw_polyline(inner_rug, Color("#e6c047"), 1.4, true)

		# Piano de cauda em ébano no canto norte-leste (gx: 2.0 a 3.8, gy: -3.2 a -1.2)
		var kb0 := iso(2.0, -1.2, 24.0)
		var kb1 := iso(3.0, -1.2, 24.0)
		var tail := iso(3.8, -3.2, 24.0)
		var rim0 := iso(2.0, -3.2, 24.0)
		draw_colored_polygon(PackedVector2Array([iso(2.0, -1.2, 0.0), iso(3.0, -1.2, 0.0), iso(3.8, -3.2, 0.0), iso(2.0, -3.2, 0.0)]), Color(0.05, 0.03, 0.07, 0.28))
		draw_colored_polygon(PackedVector2Array([kb0, kb1, kb1.lerp(tail, 0.5) + Vector2(3.0, -6.0), tail, rim0]), Color("#1a1622"))
		draw_line(kb0, kb1, Color("#fcf8ee"), 3.5, true) # Teclado

		# Relógio de pêndulo no canto noroeste (gx: -3.5, gy: -2.8)
		var clk_b := iso(-3.5, -2.8, 0.0)
		var clk_t := iso(-3.5, -2.8, 70.0)
		draw_colored_polygon(PackedVector2Array([clk_b + Vector2(-6.0, 0.0), clk_b + Vector2(6.0, 0.0), clk_t + Vector2(6.0, 0.0), clk_t + Vector2(-6.0, 0.0)]), Color("#422413"))
		draw_circle(clk_t + Vector2(0.0, 10.0), 4.5, Color("#fff6d6")) # Mostrador

		# Poltrona aconchegante verde-sálvia no canto sudoeste (gx: -3.0, gy: 1.8)
		var arm_base := iso(-3.0, 1.8, 0.0)
		draw_colored_polygon(PackedVector2Array([iso(-3.5, 1.2, 10.0), iso(-2.5, 1.2, 10.0), iso(-2.5, 2.2, 10.0), iso(-3.5, 2.2, 10.0)]), Color("#4e6e53"))
		draw_colored_polygon(PackedVector2Array([iso(-3.5, 1.2, 10.0), iso(-3.5, 1.2, 26.0), iso(-2.5, 1.2, 26.0), iso(-2.5, 1.2, 10.0)]), Color("#5e8264"))


# =========================================================================
# ELEMENTOS EM FOREGROUND (ESTANTE, EFEITOS SONOROS E FARÓIS ACÚSTICOS)
# =========================================================================
class PlayableRoomFgDrawer extends Node2D:
	var room_type: String = "quarto"

	func setup(p_type: String) -> void:
		room_type = p_type

	func iso(gx: float, gy: float, gz: float) -> Vector2:
		var tile_w := 56.0
		var tile_h := 28.0
		return Vector2((gx - gy) * (tile_w * 0.5), (gx + gy) * (tile_h * 0.5) - gz * 1.4)

	func _draw() -> void:
		match room_type:
			"quarto":
				# 1. Pulso tátil concêntrico da bengala do Sr. Arthur no piso
				var cane_tap_pos := Vector2(25.0, 32.0)
				draw_arc(cane_tap_pos, 16.0, 0.0, TAU, 24, Color(0.40, 0.85, 1.0, 0.45), 1.6)
				draw_arc(cane_tap_pos, 28.0, 0.0, TAU, 28, Color(0.95, 0.82, 0.45, 0.25), 1.2)

				# 2. Notas musicais coloridas (Farol Sonoro) saindo do rádio
				var r_pos := iso(2.2, -2.8, 28.0)
				var note_cols := [Color("#e85d43"), Color("#f2ba38"), Color("#48a8e0")]
				for ni in range(3):
					var np := r_pos + Vector2(sin(float(ni) * 1.4) * 10.0 - float(ni) * 6.0, -12.0 - float(ni) * 12.0)
					draw_circle(np, 2.6, note_cols[ni])
					draw_line(np, np + Vector2(0.0, -7.0), note_cols[ni], 1.2)
					draw_line(np + Vector2(0.0, -7.0), np + Vector2(3.0, -5.0), note_cols[ni], 1.2)

			"banheiro":
				# 1. Gota d'água pingando da torneira e anéis acústicos concêntricos de eco
				var basin_pos := iso(1.5, -3.0, 16.0)
				draw_circle(basin_pos + Vector2(0.0, -2.0), 1.6, Color(0.45, 0.85, 1.0, 0.95))
				# Anéis acústicos de reverberação na cerâmica
				draw_arc(basin_pos, 8.0, 0.0, TAU, 20, Color(0.45, 0.85, 1.0, 0.65), 1.4)
				draw_arc(basin_pos, 18.0, 0.0, TAU, 24, Color(0.45, 0.85, 1.0, 0.35), 1.2)
				draw_arc(basin_pos, 32.0, 0.0, TAU, 28, Color(0.45, 0.85, 1.0, 0.15), 1.0)

			"sala":
				# 1. Estante de partitura dourada em frente e à esquerda do Sr. Arthur
				var p_base := Vector2(-28.0, 38.0)
				var p_top  := Vector2(-28.0, 2.0)
				draw_line(p_base, p_top, Color("#e0b034"), 2.0, true)
				draw_colored_polygon(PackedVector2Array([p_top + Vector2(-14.0, 2.0), p_top + Vector2(14.0, 2.0), p_top + Vector2(12.0, -14.0), p_top + Vector2(-12.0, -14.0)]), Color("#c49829"))
				draw_rect(Rect2(p_top + Vector2(-11.0, -13.0), Vector2(10.0, 13.0)), Color("#fcfbf7"), true)
				draw_rect(Rect2(p_top + Vector2(1.0, -13.0), Vector2(10.0, 13.0)), Color("#fcfbf7"), true)

				# 2. Onda harmônica dourada de afinação emanando do Violoncelo
				var cello_pos := Vector2(5.0, 18.0)
				draw_arc(cello_pos, 22.0, 0.0, TAU, 24, Color(0.96, 0.84, 0.42, 0.40), 1.6)
				draw_arc(cello_pos, 38.0, 0.0, TAU, 28, Color(0.96, 0.84, 0.42, 0.20), 1.2)
