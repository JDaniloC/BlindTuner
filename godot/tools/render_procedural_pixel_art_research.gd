extends SceneTree
## Demonstração prática das técnicas pesquisadas de Pixel Art Procedural via Código:
## Compara:
## 1. Downscale Ingênuo (com anti-aliasing, contornos esmagados e L-corners)
## 2. Pipeline "Dead Cells / Pixelpipe" (Geometria 2.5D Stroke-less + Quantização de Paleta + 1px Sel-Out sem L-Corners)
## 3. "Pixel Art as Code" Puro (Estilo Gamezxz/pixel-art-studio & crsolver/claude-pxl com Bayer Dithering)

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")

var _frames := 0
var _vp: SubViewport
var _naive_vps: Array[SubViewport] = []
var _clean_vps: Array[SubViewport] = []
var _clean_rects: Array[TextureRect] = []
var _processed := false

# Paleta restrita de 18 cores com Hue-Shifting para o Luthier Terracota
const LUTHIER_PALETTE: Array[Color] = [
	Color("#c2593f"), # Terracota iluminado (Casaco base)
	Color("#8f3929"), # Terracota sombra (Hue-shifted para vinho/carmim)
	Color("#63221c"), # Lapela / Nogueira escuro
	Color("#f5deb8"), # Pele iluminada
	Color("#d9b08c"), # Pele sombra quente
	Color("#fff6e0"), # Brilho máximo / Cabelo branco / Bengala
	Color("#bfc7d1"), # Cabelo grisalho prateado (frio)
	Color("#7d8796"), # Cabelo sombra aço
	Color("#5e7894"), # Cachecol Azul Chambray
	Color("#3c5069"), # Cachecol sombra índigo
	Color("#f2c94c"), # Latão / Broche Diapasão / Botões
	Color("#b88628"), # Latão sombra
	Color("#1a1621"), # Óculos Obsidian / Sola
	Color("#332d3d"), # Reflexo fumê óculos
	Color("#4d2b1a"), # Sapatos Oxford couro
	Color("#d6453d"), # Ponteira vermelha da bengala
]

const COL_SEL_OUT_DARK := Color("#16111a")  # Contorno seletivo escuro (sombra)
const COL_SEL_OUT_WARM := Color("#361c1e")  # Contorno seletivo quente (topo/luz)

# Matriz de Bayer 2x2 normalizada para dithering ordenado
const BAYER_2X2 := [
	[-0.03,  0.03],
	[ 0.05, -0.01]
]


func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1200, 880)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1200, 880)
	bg.color = Color(0.10, 0.09, 0.12)
	_vp.add_child(bg)

	var main_title := Label.new()
	main_title.text = "Pesquisa de Pixel Art Procedural via Código — Comparativo de Pipelines"
	main_title.position = Vector2(40.0, 20.0)
	main_title.add_theme_font_size_override("font_size", 18)
	main_title.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90))
	_vp.add_child(main_title)

	var dirs := [
		Vector2i(1, 1),   # Frente
		Vector2i(1, 0),   # 3/4 Frente
		Vector2i(1, -1),  # Perfil Leste
		Vector2i(-1, -1), # Costas
		Vector2i(0, 1),   # Caminhando
	]

	# =========================================================================
	# LINHA 1: ABORDAGEM INGÊNUA (Downscale simples de vetor com contornos)
	# =========================================================================
	_add_section_header(
		60.0,
		"1. Downscale Ingênuo (Apenas SubViewport 52x52 com filtro Nearest)",
		"Problema: Contornos internos esmagados viram manchas escuras, bordas semitransparentes (halos) e degraus duplos (L-corners)."
	)

	for col in range(dirs.size()):
		var cx := 130.0 + float(col) * 215.0
		var cy := 235.0

		var n_vp := SubViewport.new()
		n_vp.size = Vector2i(52, 52)
		n_vp.transparent_bg = true
		n_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_vp.add_child(n_vp)

		var ch := ProceduralArthurScript.new()
		ch.position = Vector2(26.0, 43.0)
		ch.scale = Vector2(1.0, 1.0)
		ch.set_meta("custom_assembly", "overcoat_indie")
		ch.set_direction(dirs[col], true)
		if col == 4:
			ch.anim_state = "walk"
			ch.walk_phase = 1.35
		n_vp.add_child(ch)
		_naive_vps.append(n_vp)

		var trect := TextureRect.new()
		trect.texture = n_vp.get_texture()
		trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		trect.size = Vector2(156, 156)
		trect.position = Vector2(cx - 78.0, cy - 120.0)
		_vp.add_child(trect)

	# =========================================================================
	# LINHA 2: PIPELINE "DEAD CELLS / PIXELPIPE" (2.5D Stroke-less + Limpeza Algorítmica)
	# =========================================================================
	_add_section_header(
		330.0,
		"2. Pipeline 'Dead Cells + Pixelpipe' (Geometria 2.5D Sem Contorno + Pós-Processamento Algorítmico)",
		"Solução: Renderiza planos puros (stroke-less) -> Endurece Alpha -> Quantiza Paleta com Bayer Dithering -> Gera Contorno Seletivo de 1px sem L-Corners!"
	)

	for col in range(dirs.size()):
		var cx := 130.0 + float(col) * 215.0
		var cy := 515.0

		var c_vp := SubViewport.new()
		c_vp.size = Vector2i(56, 56)
		c_vp.transparent_bg = true
		c_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_vp.add_child(c_vp)

		var ch := ProceduralArthurScript.new()
		ch.position = Vector2(28.0, 46.0)
		ch.scale = Vector2(1.05, 1.05)
		# Segredo: renderiza sem contornos pretos internos para não borrar os pixels!
		ch.set_meta("custom_assembly", "flat_geometric")
		ch.set_direction(dirs[col], true)
		if col == 4:
			ch.anim_state = "walk"
			ch.walk_phase = 1.35
		c_vp.add_child(ch)
		_clean_vps.append(c_vp)

		var trect := TextureRect.new()
		trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.size = Vector2(168, 168)
		trect.position = Vector2(cx - 84.0, cy - 130.0)
		_vp.add_child(trect)
		_clean_rects.append(trect)

	# =========================================================================
	# LINHA 3: "PIXEL ART AS CODE" PURO (DSL / Matriz Determinística estilo claude-pxl & pixelstudio.py)
	# =========================================================================
	_add_section_header(
		610.0,
		"3. 'Pixel Art as Code' Puro (Matriz DSL Determinística — Estilo Gamezxz/pixel-art-studio & claude-pxl)",
		"Construção pixel a pixel via código com espelhamento seletivo, Bayer Dithering, Hue-Shifting e controle absoluto de cada pixel."
	)

	var dsl_items := [
		{"label": "Arthur 32x32 (Frente DSL)", "type": "arthur_front"},
		{"label": "Arthur 32x32 (Perfil DSL)", "type": "arthur_side"},
		{"label": "Violoncelo Luthier 32x32", "type": "cello_prop"},
		{"label": "Diapasão de Concerto 32x32", "type": "tuning_fork"},
		{"label": "Poltrona Acústica 32x32", "type": "armchair"},
	]

	for col in range(dsl_items.size()):
		var cx := 130.0 + float(col) * 215.0
		var cy := 760.0
		var item = dsl_items[col]

		var img := _build_dsl_sprite(item["type"])
		var tex := ImageTexture.create_from_image(img)

		var trect := TextureRect.new()
		trect.texture = tex
		trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.size = Vector2(144, 144)
		trect.position = Vector2(cx - 72.0, cy - 105.0)
		_vp.add_child(trect)

		var ilbl := Label.new()
		ilbl.text = item["label"]
		ilbl.position = Vector2(cx - 75.0, cy + 45.0)
		ilbl.add_theme_font_size_override("font_size", 12)
		ilbl.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76))
		_vp.add_child(ilbl)


func _add_section_header(y_top: float, title_txt: String, desc_txt: String) -> void:
	var header := Label.new()
	header.text = title_txt
	header.position = Vector2(40.0, y_top)
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
	_vp.add_child(header)

	var sub := Label.new()
	sub.text = desc_txt
	sub.position = Vector2(40.0, y_top + 22.0)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.74, 0.72, 0.70))
	_vp.add_child(sub)


## Algoritmo "Pixelpipe" inspirado em Gamezxz/pixel-art-studio:
## 1. Endurece o canal Alpha (elimina semitransparências / mixels)
## 2. Quantiza cores para a paleta oficial com Bayer Dithering 2x2 sutil
## 3. Remove pixels órfãos isolados de ruído
## 4. Aplica Contorno Seletivo (Sel-Out) de 1px exato ao redor da silhueta
## 5. Remove L-Corners (degraus duplos) do contorno externo
func _apply_pixelpipe_algorithm(raw_img: Image) -> Image:
	var w := raw_img.get_width()
	var h := raw_img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	# Passo 1 & 2: Alpha Hardening + Palette Quantization com Bayer Dithering
	for y in range(h):
		for x in range(w):
			var c := raw_img.get_pixel(x, y)
			if c.a >= 0.42:
				# Recupera a cor pura sem escurecimento de pré-multiplicação de alpha
				var pure := Color(
					clampf(c.r, 0.0, 1.0),
					clampf(c.g, 0.0, 1.0),
					clampf(c.b, 0.0, 1.0),
					1.0
				)
				var bayer_ofs: float = BAYER_2X2[y % 2][x % 2]
				var dithered := Color(
					clampf(pure.r + bayer_ofs, 0.0, 1.0),
					clampf(pure.g + bayer_ofs, 0.0, 1.0),
					clampf(pure.b + bayer_ofs, 0.0, 1.0),
					1.0
				)
				out.set_pixel(x, y, _nearest_palette_color(dithered))

	# Passo 3: Remoção de ruído órfão interno (preservando brilhos claros e dourados)
	var cleaned: Image = out.duplicate() as Image
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c: Color = out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			# Preserva detalhes de brilho intencional (óculos, botões, diapasão)
			if c == Color("#fff6e0") or c == Color("#f2c94c") or c == Color("#1a1621"):
				continue
			var n: Color = out.get_pixel(x, y - 1)
			var s: Color = out.get_pixel(x, y + 1)
			var e: Color = out.get_pixel(x + 1, y)
			var w_px: Color = out.get_pixel(x - 1, y)
			if n.a > 0.5 and n == s and n == e and n == w_px and c != n:
				cleaned.set_pixel(x, y, n)

	# Passo 4: Geração de Contorno Seletivo 1px (Sel-Out) por Vizinhança Cardinal
	var with_outline: Image = cleaned.duplicate() as Image
	var is_outline_mask: Dictionary = {}
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c: Color = cleaned.get_pixel(x, y)
			if c.a < 0.5:
				var has_n: bool = cleaned.get_pixel(x, y - 1).a > 0.5
				var has_s: bool = cleaned.get_pixel(x, y + 1).a > 0.5
				var has_e: bool = cleaned.get_pixel(x + 1, y).a > 0.5
				var has_w: bool = cleaned.get_pixel(x - 1, y).a > 0.5
				if has_n or has_s or has_e or has_w:
					# Selective Outlining: Mais quente no topo iluminado, mais escuro na base
					var sel_col := COL_SEL_OUT_WARM if (y < h * 0.45 and has_s and not has_n) else COL_SEL_OUT_DARK
					with_outline.set_pixel(x, y, sel_col)
					is_outline_mask[Vector2i(x, y)] = true

	# Passo 5: Eliminação de L-Corners nos contornos externos para diagonais de 1px perfeitas
	var final_img: Image = with_outline.duplicate() as Image
	for pos: Vector2i in is_outline_mask.keys():
		var x := pos.x
		var y := pos.y
		# Se um pixel de contorno forma um canto em L redundante na parte externa da diagonal, remove-o
		var out_n := is_outline_mask.has(Vector2i(x, y - 1))
		var out_s := is_outline_mask.has(Vector2i(x, y + 1))
		var out_e := is_outline_mask.has(Vector2i(x + 1, y))
		var out_w := is_outline_mask.has(Vector2i(x - 1, y))

		if (out_n and out_e and not is_outline_mask.has(Vector2i(x - 1, y + 1)) and cleaned.get_pixel(x - 1, y + 1).a > 0.5):
			final_img.set_pixel(x, y, Color(0, 0, 0, 0))
		elif (out_n and out_w and not is_outline_mask.has(Vector2i(x + 1, y + 1)) and cleaned.get_pixel(x + 1, y + 1).a > 0.5):
			final_img.set_pixel(x, y, Color(0, 0, 0, 0))

	return final_img


func _nearest_palette_color(c: Color) -> Color:
	var best_col := LUTHIER_PALETTE[0]
	var best_dist := 999999.0
	for pal_c in LUTHIER_PALETTE:
		var dr := (c.r - pal_c.r) * 1.1
		var dg := (c.g - pal_c.g) * 1.2
		var db := (c.b - pal_c.b) * 0.9
		var dist := dr * dr + dg * dg + db * db
		if dist < best_dist:
			best_dist = dist
			best_col = pal_c
	return best_col


## Constrói um sprite 32x32 usando a filosofia "Pixel Art as Code" (DSL determinística estilo claude-pxl)
func _build_dsl_sprite(sprite_type: String) -> Image:
	var pal := {
		".": Color(0, 0, 0, 0),
		"k": Color("#16111a"), # Contorno escuro
		"w": Color("#361c1e"), # Contorno quente seletivo
		"s": Color("#f5deb8"), # Pele luz
		"S": Color("#d9b08c"), # Pele sombra
		"h": Color("#fff6e0"), # Cabelo branco / Brilho
		"H": Color("#bfc7d1"), # Cabelo prata
		"g": Color("#1a1621"), # Óculos obsidian
		"G": Color("#332d3d"), # Óculos reflexo
		"c": Color("#5e7894"), # Cachecol chambray
		"C": Color("#3c5069"), # Cachecol sombra
		"t": Color("#c2593f"), # Sobretudo terracota luz
		"T": Color("#8f3929"), # Sobretudo terracota sombra
		"l": Color("#63221c"), # Lapela / Madeira escura
		"y": Color("#f2c94c"), # Ouro / Latão / Diapasão
		"o": Color("#4d2b1a"), # Couro sapato / Violoncelo
		"r": Color("#d6453d"), # Vermelho bengala
	}

	var rows: Array[String] = []
	match sprite_type:
		"arthur_front":
			rows = [
				"................................",
				"...........wwwwwwwwww...........",
				".........wwssssssssssww.........",
				"........wHssssssssssssHw........",
				".......wHHssssssssssssHHw.......",
				".......kHHssssssssssssHHk.......",
				"......ksHggggggssggggggHSK......",
				"......ksgggghgggggghggggSK......",
				"......ksggggggggggggggggSK......",
				".......kssssssshSsssssssk.......",
				".......ksssHHHHHHHHHHsssk.......",
				"........ksHHHhhhhhhHHHsk........",
				".........kSSSSSSSSSSSSk.........",
				"........kcccccccccccccck........",
				".......kccccccCCCccccccck.......",
				"......kttlllcccCCccclllttk......",
				".....ktttlllcccyyccclllTTTk.....",
				".....ktttllltccccccTlllTTTk.....",
				"....kttttllltccCCccTlllTTTTk....",
				"....ktttttttttytttyTTTTTTTtk....",
				"....kssstttttttttttTTTTTTTTk....",
				"....kSSktttttttyttyTTTTTkSSk....",
				".....kk.kttttttttttTTTTk.kkh....",
				"........kttttttttttTTTTk...h....",
				".......ktttttttttttTTTTTk..h....",
				".......ktttttttttttTTTTTk..h....",
				"......kttttttttttttTTTTTTk.h....",
				"......kkkkkkkkkkkkkkkkkkkk.r....",
				".........koook....koook....r....",
				"........koooook..koooook...h....",
				"........kkkkkkk..kkkkkkk...k....",
				"................................",
			]
		"arthur_side":
			rows = [
				"................................",
				"...........wwwwwwww.............",
				".........wwssssssssww...........",
				"........wHHssssssssssw..........",
				".......wHHHsssssssssssw.........",
				".......kHHHHssssssgggggk........",
				".......kHHHsssksggggghgk........",
				".......kHHHssSksgggggggk........",
				".......kHHHsssSssssssssssw......",
				"........kHHsssssHHHHHHHkk.......",
				"........kHHssssHHHHHHHHHk.......",
				".........kSSSSSSSHHHHHkk........",
				"........kcccccccccccck..........",
				".......kcccccccccccccCk.........",
				"......ktttttttlllccccCCk........",
				"......ktttttttlllyyccCCk........",
				".....kttttttttlllTTcccck........",
				".....ktttttttttllTTTccCk........",
				".....kttttssttttTTTTTTk.........",
				"....ktttttssstttTTTTTTk.........",
				"....ktttttkkktttTTTTTTkh........",
				"....ktttttttttttTTTTTTk.h.......",
				"...kttttttttttttTTTTTTk..h......",
				"...kttttttttttttTTTTTTk...h.....",
				"...ktttttttttttttTTTTTk....h....",
				"..kttttttttttttttTTTTTTk....r...",
				"..kkkkkkkkkkkkkkkkkkkkkk....r...",
				".......kooooook..kooooook....h..",
				".......koooooook.koooooook...k..",
				".......kkkkkkkkk.kkkkkkkkk......",
				"................................",
				"................................",
			]
		"cello_prop":
			rows = [
				"...............kk...............",
				"..............kyyk..............",
				".............kylllk.............",
				"..............klkk..............",
				"..............kllk..............",
				"..............kllk..............",
				"..............kllk..............",
				"..............kllk..............",
				"............kkllllkk............",
				"..........kkttllllTTkk..........",
				".........kttttllllTTTTk.........",
				"........khttttllllTTTTTk........",
				"........khttttllllTTTTTk........",
				".........kttttllllTTTTk.........",
				"..........ktttllllTTTk..........",
				"..........kttkyyyykTTk..........",
				".........ktttkllllkTTTk.........",
				".......kkttttkllllkTTTTkk.......",
				"......khtttttkllllkTTTTTTk......",
				".....khttttttkllllkTTTTTTTk.....",
				".....khttttttkllllkTTTTTTTk.....",
				".....kttttttttkkkkTTTTTTTTk.....",
				".....kttttttttsoosTTTTTTTTk.....",
				"......ktttttttsoosTTTTTTTk......",
				".......kktttttkllkTTTTTkk.......",
				".........kkkkkkllkkkkkk.........",
				"...............khk..............",
				"...............khk..............",
				"...............khk..............",
				"...............kkk..............",
				"................................",
				"................................",
			]
		"tuning_fork":
			rows = [
				"................................",
				"..........kkk......kkk..........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				".........khyyk....kyyhk.........",
				"..........kyyykkkkyyyk..........",
				"...........kyyyyyyyyk...........",
				"............kkkkkkk.............",
				"..............kyyk..............",
				"..............kyyk..............",
				"..............kyyk..............",
				"..............kyyk..............",
				"..............kyyk..............",
				"..............kyyk..............",
				"..............kyyk..............",
				".............kyyyyk.............",
				"............kyhyyyyk............",
				"............kyyyyyyk............",
				".............kkkkkk.............",
				"................................",
				"................................",
				"................................",
				"................................",
			]
		_: # armchair
			rows = [
				"................................",
				"................................",
				"........kkkkkkkkkkkkkkkk........",
				"......kkcccccccccccccccckk......",
				".....kccchhhhhhhhhhhhhhccCk.....",
				"....kcccchccccccccccccchccCk....",
				"....kccccccccccccccccccccCCk....",
				"....kccccccccccccccccccccCCk....",
				"....kccccccckcccccckcccccCCk....",
				"....kccccccccccccccccccccCCk....",
				"...kkccccccccccccccccccccCCkk...",
				"..kcccccccCCCCCCCCCCCCCCccccCk..",
				".kchccccccCCCCCCCCCCCCCCccccCCk.",
				".kccccccccccccccccccccccccccCCk.",
				".kcccCCCccccccccccccccccCCCCcCk.",
				"..kccCCCssssssssssssssssCCCCck..",
				"..kccCCCssssssssssssssssCCCCck..",
				"..kccCCCCCCCCCCCCCCCCCCCCCCCck..",
				"..kcccccccccccccccccccccccccCk..",
				"..kkkkkkkkkkkkkkkkkkkkkkkkkkkk..",
				"....kllk................kllk....",
				"....kllk................kllk....",
				"....kllk................kllk....",
				"....kyyk................kyyk....",
				"....kkkk................kkkk....",
				"................................",
				"................................",
				"................................",
				"................................",
				"................................",
				"................................",
				"................................",
			]

	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(mini(32, rows.size())):
		var line: String = rows[y]
		for x in range(mini(32, line.length())):
			var ch := line.substr(x, 1)
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
	return img


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 4 and not _processed:
		_processed = true
		for i in range(_clean_vps.size()):
			var raw_img := _clean_vps[i].get_texture().get_image()
			var clean_img := _apply_pixelpipe_algorithm(raw_img)
			_clean_rects[i].texture = ImageTexture.create_from_image(clean_img)

	if _frames >= 7:
		var img := _vp.get_texture().get_image()
		if img != null:
			img.save_png("C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/procedural_pixel_art_research.png")
		quit(0)
		return true
	return false
