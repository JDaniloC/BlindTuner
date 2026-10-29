extends SceneTree
## Ferramenta de Demonstração da Solução de Pixel Art Procedural via Código
## Apresenta o personagem Arthur, o violoncelo mel e os cenários completos
## no estilo Pixel Art nítido e autêntico, corrigindo todos os problemas anteriores
## e comparando os pipelines de geração investigados.

var _frames := 0
var _vp: SubViewport

const FLOOR_A := preload("res://assets/sprites/tilemap/floor_wood_oak_a.png")
const FLOOR_B := preload("res://assets/sprites/tilemap/floor_wood_oak_b.png")
const BED_PROP := preload("res://assets/sprites/furniture/bed_elderly_96x80.png")
const NIGHTSTAND_PROP := preload("res://assets/sprites/furniture/nightstand_lamp_48x64.png")
const SLIPPERS_PROP := preload("res://assets/sprites/obstacles/slippers_floor_36x32.png")
const RADIO_PROP := preload("res://assets/sprites/props/radio_vintage_48x48.png")
const ARMCHAIR_PROP := preload("res://assets/sprites/furniture/armchair_cozy_64x64.png")
const CLOCK_PROP := preload("res://assets/sprites/furniture/clock_grandfather_32x80.png")
const TABLE_PROP := preload("res://assets/sprites/furniture/coffee_table_64x48.png")

# Paleta Mestre Luthier em Pixel Art
const PALETTE := {
	".": Color(0, 0, 0, 0),
	"k": Color("#141018"), # Preto Obsidian / Contorno base
	"w": Color("#381d22"), # Contorno marrom-quente (sel-out)
	"s": Color("#f5deb8"), # Pele luz
	"S": Color("#d9b08c"), # Pele sombra
	"h": Color("#ffffff"), # Cabelo / Bigode branco puro brilhante
	"H": Color("#bfc7d1"), # Cabelo prata sombra
	"g": Color("#181420"), # Óculos escuros obsidian
	"G": Color("#352f40"), # Óculos reflexo especular
	"y": Color("#f5cb42"), # Ouro / Haste óculos / Fivela / Latão
	"c": Color("#54708c"), # Cachecol chambray
	"C": Color("#374a5e"), # Cachecol sombra
	"t": Color("#c45b41"), # Sobretudo terracota luz
	"T": Color("#8a3525"), # Sobretudo terracota sombra
	"l": Color("#571d18"), # Lapela terracota escura
	"m": Color("#f5b857"), # Violoncelo Mel Dourado Realce
	"M": Color("#e09438"), # Violoncelo Mel Dourado Base
	"d": Color("#a65f1c"), # Violoncelo Bordo Sombra
	"D": Color("#4d2208"), # Violoncelo Ébano Purfling / Escala
	"r": Color("#db3b3b"), # Vermelho ponta da bengala
	"e": Color("#f0ede6"), # Branco corpo da bengala
	"o": Color("#422518"), # Couro sapatos
	"O": Color("#2b150c"), # Couro sombra
}


func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1600, 1000)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1600, 1000)
	bg.color = Color("#0e0d13")
	_vp.add_child(bg)

	_build_master_header()
	_build_character_panel(Vector2(40.0, 90.0))
	_build_scenery_panel(Vector2(680.0, 90.0))
	_build_architecture_cards(Vector2(40.0, 750.0))


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= 8:
		var main_img: Image = _vp.get_texture().get_image()
		var out_path := "C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/solucao_pixel_art_procedural.png"
		var err := main_img.save_png(out_path)
		if err == OK:
			print("SUCCESS: Solucao de Pixel Art Procedural salva com sucesso em: ", out_path)
		else:
			print("ERROR: Falha ao salvar: ", err)
		quit()
	return false


func _build_master_header() -> void:
	var h_panel := ColorRect.new()
	h_panel.size = Vector2(1600, 72)
	h_panel.color = Color("#171420")
	_vp.add_child(h_panel)

	var title := Label.new()
	title.text = "BlindTuner — Retorno ao Pixel Art: Geração Procedural via Código (MagmaDev & GitHub Skills)"
	title.position = Vector2(40.0, 12.0)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#fff6e8"))
	_vp.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Controle determinístico pixel a pixel: Separação nítida do Bigode vs Rosto, Violoncelo Mel Dourado vs Sobretudo e Cenários Isométricos 16-bit nativos."
	subtitle.position = Vector2(40.0, 40.0)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#aba3bf"))
	_vp.add_child(subtitle)


# =========================================================================
# PAINEL 1: PERSONAGEM & VIOLONCELO EM PIXEL ART NÍTIDO
# =========================================================================
func _build_character_panel(pos: Vector2) -> void:
	var card := _make_card(pos, Vector2(610, 640), Color("#13111b"), Color("#272136"))
	_vp.add_child(card)

	var bar := ColorRect.new()
	bar.size = Vector2(5, 32)
	bar.position = pos + Vector2(16, 16)
	bar.color = Color("#e58c42")
	_vp.add_child(bar)

	var title := Label.new()
	title.text = "1. ARTHUR & VIOLONCELO EM PIXEL ART PURO (32x32 / 48x48)"
	title.position = pos + Vector2(30, 14)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	_vp.add_child(title)

	var desc := Label.new()
	desc.text = "Construído via DSL de Matriz: Óculos Ray-Ban obsidian, bigode branco nítido com vinco e violoncelo mel."
	desc.position = pos + Vector2(30, 36)
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color("#a39cb5"))
	_vp.add_child(desc)

	# Sprites gerados via DSL
	var sprites_data := [
		{"name": "arthur_idle_cane", "label": "Arthur com Bengala\n(Frente 32x32)"},
		{"name": "arthur_side_cane", "label": "Arthur Caminhando\n(Perfil 32x32)"},
		{"name": "arthur_playing_cello", "label": "Arthur & Violoncelo Mel\n(Tuning Pose 40x40)"},
	]

	for i in range(sprites_data.size()):
		var s_data = sprites_data[i]
		var spr_img := _generate_dsl_sprite(s_data["name"])
		var tex := ImageTexture.create_from_image(spr_img)

		var item_x := pos.x + 25.0 + float(i) * 190.0
		var item_y := pos.y + 75.0

		var bg_box := ColorRect.new()
		bg_box.size = Vector2(175, 230)
		bg_box.position = Vector2(item_x, item_y)
		bg_box.color = Color("#181524")
		_vp.add_child(bg_box)

		var trect := TextureRect.new()
		trect.texture = tex
		trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		trect.size = Vector2(140, 140)
		trect.position = Vector2(item_x + 17.5, item_y + 15.0)
		_vp.add_child(trect)

		var lbl := Label.new()
		lbl.text = s_data["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(item_x, item_y + 165.0)
		lbl.size = Vector2(175, 40)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color("#d5cee3"))
		_vp.add_child(lbl)

	# Painel de Zoom Macro 4.0x para inspeção dos pontos críticos que o usuário apontou
	var zoom_box := ColorRect.new()
	zoom_box.size = Vector2(560, 275)
	zoom_box.position = pos + Vector2(25, 335)
	zoom_box.color = Color("#181524")
	_vp.add_child(zoom_box)

	var zoom_title := Label.new()
	zoom_title.text = "INSPEÇÃO DE CONTRASTE & SEPARAÇÃO DE 1-PIXEL (RESOLVENDO DORES ANTERIORES):"
	zoom_title.position = pos + Vector2(40, 345)
	zoom_title.add_theme_font_size_override("font_size", 11)
	zoom_title.add_theme_color_override("font_color", Color("#f5cb42"))
	_vp.add_child(zoom_title)

	# Zoom 1: Rosto e Bigode (mostrando o vinco labial escuro que impede o bigode de se fundir com a pele)
	var face_crop := _generate_dsl_sprite("arthur_idle_cane").get_region(Rect2i(6, 4, 20, 16))
	var face_tex := ImageTexture.create_from_image(face_crop)
	var face_rect := TextureRect.new()
	face_rect.texture = face_tex
	face_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face_rect.size = Vector2(220, 176)
	face_rect.position = pos + Vector2(40, 380)
	_vp.add_child(face_rect)

	var face_lbl := Label.new()
	face_lbl.text = "✓ Bigode vs Rosto:\nVinco labial #381d22 sob o bigode branco #ffffff.\nZero confusão com o queixo ou bochecha."
	face_lbl.position = pos + Vector2(40, 565)
	face_lbl.size = Vector2(230, 40)
	face_lbl.add_theme_font_size_override("font_size", 10)
	face_lbl.add_theme_color_override("font_color", Color("#b0a8c2"))
	_vp.add_child(face_lbl)

	# Zoom 2: Violoncelo Mel vs Sobretudo Terracota
	var cello_crop := _generate_dsl_sprite("arthur_playing_cello").get_region(Rect2i(10, 8, 20, 20))
	var cello_tex := ImageTexture.create_from_image(cello_crop)
	var cello_rect := TextureRect.new()
	cello_rect.texture = cello_tex
	cello_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cello_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cello_rect.size = Vector2(220, 176)
	cello_rect.position = pos + Vector2(310, 380)
	_vp.add_child(cello_rect)

	var cello_lbl := Label.new()
	cello_lbl.text = "✓ Violoncelo vs Casaco:\nMadeira Mel Dourada #f5b857 com friso em ébano #141018.\nContraste máximo contra o casaco terracota #c45b41."
	cello_lbl.position = pos + Vector2(310, 565)
	cello_lbl.size = Vector2(240, 40)
	cello_lbl.add_theme_font_size_override("font_size", 10)
	cello_lbl.add_theme_color_override("font_color", Color("#b0a8c2"))
	_vp.add_child(cello_lbl)


# =========================================================================
# PAINEL 2: CENÁRIO JOGÁVEL EM PIXEL ART ISOMÉTRICO REAL
# =========================================================================
func _build_scenery_panel(pos: Vector2) -> void:
	var card := _make_card(pos, Vector2(880, 640), Color("#13111b"), Color("#272136"))
	_vp.add_child(card)

	var bar := ColorRect.new()
	bar.size = Vector2(5, 32)
	bar.position = pos + Vector2(16, 16)
	bar.color = Color("#58b2d8")
	_vp.add_child(bar)

	var title := Label.new()
	title.text = "2. OS CENÁRIOS JOGÁVEIS EM PIXEL ART NATIVO (16-BIT RETRO)"
	title.position = pos + Vector2(30, 14)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	_vp.add_child(title)

	var desc := Label.new()
	desc.text = "Montado com os sprites nativos do projeto: Tiles de carvalho 64x32, cama 96x80, rádio com notas e Arthur em pixel art."
	desc.position = pos + Vector2(30, 36)
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color("#a39cb5"))
	_vp.add_child(desc)

	# SubViewport de resolução nativa 420x260 pixel art (ampliado 2x pixel-perfect para 840x520)
	var scene_vp := SubViewport.new()
	scene_vp.size = Vector2i(420, 270)
	scene_vp.transparent_bg = true
	scene_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.add_child(scene_vp)

	var scene_node := _build_isometric_pixel_art_scene()
	scene_vp.add_child(scene_node)

	var scene_rect := TextureRect.new()
	scene_rect.texture = scene_vp.get_texture()
	scene_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_rect.size = Vector2(830, 545)
	scene_rect.position = pos + Vector2(25, 75)
	_vp.add_child(scene_rect)


# Constrói o cenário isométrico usando os sprites reais de Pixel Art do BlindTuner
func _build_isometric_pixel_art_scene() -> Node2D:
	var root := Node2D.new()
	var origin := Vector2(210.0, 75.0)

	# Função auxiliar de coordenadas isométricas (tile 64x32)
	var to_iso := func(gx: float, gy: float) -> Vector2:
		return origin + Vector2((gx - gy) * 32.0, (gx + gy) * 16.0)

	# 1. Chão de Madeira Oak 16-bit (Grade 6x6)
	for gy in range(6):
		for gx in range(6):
			var sp := Sprite2D.new()
			sp.texture = FLOOR_A if (gx + gy) % 2 == 0 else FLOOR_B
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.position = to_iso.call(gx, gy)
			root.add_child(sp)

	# 2. Paredes de Fundo (North-West e North-East)
	# Desenhadas com linhas estilizadas de pixel art
	var wall_drawer := PixelWallDrawer.new()
	wall_drawer.origin = origin
	root.add_child(wall_drawer)

	# 3. Móveis de Pixel Art
	# Cama do velhinho (96x80) em (1, 1)
	var bed_sp := Sprite2D.new()
	bed_sp.texture = BED_PROP
	bed_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bed_sp.position = to_iso.call(1.2, 1.2) + Vector2(0, -18)
	bed_sp.z_index = 20
	root.add_child(bed_sp)

	# Criado-mudo com abajur (48x64) em (0, 3)
	var ns_sp := Sprite2D.new()
	ns_sp.texture = NIGHTSTAND_PROP
	ns_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ns_sp.position = to_iso.call(0.2, 3.0) + Vector2(0, -16)
	ns_sp.z_index = 25
	root.add_child(ns_sp)

	# Rádio Vintage (48x48) em (0, 4) - O FAROL SONORO
	var rad_sp := Sprite2D.new()
	rad_sp.texture = RADIO_PROP
	rad_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rad_sp.position = to_iso.call(0.2, 4.2) + Vector2(0, -14)
	rad_sp.z_index = 35
	root.add_child(rad_sp)

	# Chinelos aos pés da cama (36x32) em (2, 3)
	var slip_sp := Sprite2D.new()
	slip_sp.texture = SLIPPERS_PROP
	slip_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slip_sp.scale = Vector2(0.65, 0.65)
	slip_sp.position = to_iso.call(2.0, 3.0) + Vector2(0, -4)
	slip_sp.z_index = 28
	root.add_child(slip_sp)

	# 4. Poltrona de Veludo (64x64) no canto direito em (4, 1)
	var arm_sp := Sprite2D.new()
	arm_sp.texture = ARMCHAIR_PROP
	arm_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arm_sp.position = to_iso.call(4.2, 1.0) + Vector2(0, -12)
	arm_sp.z_index = 25
	root.add_child(arm_sp)

	# 5. O Protagonista Arthur em Pixel Art caminhando no centro da sala (3, 3)
	var arthur_sp := Sprite2D.new()
	var arthur_img := _generate_dsl_sprite("arthur_idle_cane")
	arthur_sp.texture = ImageTexture.create_from_image(arthur_img)
	arthur_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arthur_sp.position = to_iso.call(3.2, 3.2) + Vector2(0, -14)
	arthur_sp.z_index = 40
	root.add_child(arthur_sp)

	# 6. Efeitos Visuais de Farol Acústico em Pixel Art (Ecolocalização & Notas Musicais)
	var fx_drawer := PixelAcousticDrawer.new()
	fx_drawer.radio_pos = to_iso.call(0.2, 4.2) + Vector2(0, -20)
	fx_drawer.arthur_pos = to_iso.call(3.2, 3.2)
	fx_drawer.z_index = 50
	root.add_child(fx_drawer)

	return root


# =========================================================================
# PAINEL 3: OS 3 PIPELINES TÉCNICOS PARA GERAÇÃO DE PIXEL ART
# =========================================================================
func _build_architecture_cards(pos: Vector2) -> void:
	var pipelines := [
		{
			"title": "A) Pixel Art as Code Puro (DSL / Python / claude-pxl)",
			"badge": "Recomendado para Autenticidade",
			"col": Color("#58b2d8"),
			"desc": "Escrevemos o gerador procedural (em Python ou GDScript) que gera as animações do Arthur diretamente em PNG pixel a pixel.\n• Vantagem: Controle 100% absoluto de cada pixel, zero mixels, zero borrão, harmonia perfeita com os móveis existentes.\n• Integração: Alimenta diretamente os arquivos de `assets/sprites/character/16x32_elderly/`."
		},
		{
			"title": "B) Pipeline 2.5D Cel-Shaded para Pixel Art (Dead Cells)",
			"badge": "Recomendado para 360° Suave",
			"col": Color("#e58c42"),
			"desc": "Usa a geometria 2.5D renderizada em resolução nativa baixa (48x48) com shader cel-shading e outline seletivo de 1px.\n• Vantagem: Rotação contínua e perfeita do violoncelo em 360° durante o minigame de afinação.\n• Ajuste Crítico: Eliminar dithering no rosto e usar as novas paletas de alta separação (Terracota + Mel Dourado)."
		},
		{
			"title": "C) Sprite-Stacking Voxel 2.5D (MagicaVoxel / Stacker)",
			"badge": "Voxel Retro Isométrico",
			"col": Color("#8ed558"),
			"desc": "Empilhamento vertical de fatias 2D em pixel art nativo (fatias horizontais de 1px de espessura).\n• Vantagem: Aparência 100% pixelada e volumétrica, rotação 3D sem modelo poligonal complexo.\n• Custo: Exige gerar ~24 a 32 fatias de textura para o corpo do Arthur e do violoncelo."
		}
	]

	for i in range(pipelines.size()):
		var pipe = pipelines[i]
		var c_x := pos.x + float(i) * 515.0
		var c_card := _make_card(Vector2(c_x, pos.y), Vector2(495, 195), Color("#13111b"), Color("#272136"))
		_vp.add_child(c_card)

		var bar := ColorRect.new()
		bar.size = Vector2(4, 24)
		bar.position = Vector2(c_x + 14.0, pos.y + 14.0)
		bar.color = pipe["col"]
		_vp.add_child(bar)

		var t_lbl := Label.new()
		t_lbl.text = pipe["title"]
		t_lbl.position = Vector2(c_x + 24.0, pos.y + 12.0)
		t_lbl.add_theme_font_size_override("font_size", 12)
		t_lbl.add_theme_color_override("font_color", Color("#ffffff"))
		_vp.add_child(t_lbl)

		var b_badge := Label.new()
		b_badge.text = "[" + pipe["badge"] + "]"
		b_badge.position = Vector2(c_x + 24.0, pos.y + 32.0)
		b_badge.add_theme_font_size_override("font_size", 10)
		b_badge.add_theme_color_override("font_color", pipe["col"])
		_vp.add_child(b_badge)

		var d_lbl := Label.new()
		d_lbl.text = pipe["desc"]
		d_lbl.position = Vector2(c_x + 16.0, pos.y + 55.0)
		d_lbl.size = Vector2(465, 130)
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d_lbl.add_theme_font_size_override("font_size", 11)
		d_lbl.add_theme_color_override("font_color", Color("#c0bad1"))
		_vp.add_child(d_lbl)


# =========================================================================
# GERADOR DETERMINÍSTICO VIA MATRIZ DSL DE PIXEL ART (MagmaDev / claude-pxl)
# =========================================================================
func _generate_dsl_sprite(stype: String) -> Image:
	var rows: Array[String] = []

	match stype:
		"arthur_idle_cane": # 32x32
			rows = [
				"................................",
				"...........wwwwwwwwww...........",
				".........wwssssssssssww.........",
				"........wHssssssssssssHw........",
				".......wHHssssssssssssHHw.......",
				".......kHHssssssssssssHHk.......",
				"......ksHggggggyyggggggHSk......",
				"......ksgggghgyyyyghggggSk......",
				"......ksggggggggggggggggSk......",
				".......kssssssshhsssssssk.......",
				".......ksssHhhhhhhhhsssk........",
				"........ksHhhhhhhHhhhsk.........",
				".........kwwwwwwwwwwk...........",
				"........kcccccccccccccck........",
				".......kccccccCCCccccccck.......",
				"......kttlllcccCCccclllttk......",
				".....ktttlllcccyyccclllTTTk.....",
				".....ktttllltccccccTlllTTTk.....",
				"....kttttllltccCCccTlllTTTTk....",
				"....ktttttttttytttyTTTTTTTTk....",
				"....kssstttttttttttTTTTTkssk....",
				"....kSSktttttttyttyTTTTTkSSk....",
				".....kk.kttttttttttTTTTk.kk.....",
				"........kttttttttttTTTTk...e....",
				".......ktttttttttttTTTTTk..e....",
				".......ktttttttttttTTTTTk..e....",
				"......kttttttttttttTTTTTTk.r....",
				"......kkkkkkkkkkkkkkkkkkkk.r....",
				".........koook....koook....e....",
				"........koooook..koooook...k....",
				"........kkkkkkk..kkkkkkk........",
				"................................",
			]
		"arthur_side_cane": # 32x32
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
				"........kHHsssssHhhhhhhkk.......",
				"........kHHssssHhhhhhhhhk.......",
				".........kwwwwwwHhhhhhkk........",
				"........kcccccccccccck..........",
				".......kcccccccccccccCk.........",
				"......ktttttttlllccccCCk........",
				"......ktttttttlllyyccCCk........",
				".....kttttttttlllTTcccck........",
				".....ktttttttttllTTTccCk........",
				".....kttttssttttTTTTTTk.........",
				"....ktttttssstttTTTTTTk.........",
				"....ktttttkkktttTTTTTTke........",
				"....ktttttttttttTTTTTTk.e.......",
				"...kttttttttttttTTTTTTk..e......",
				"...kttttttttttttTTTTTTk...e.....",
				"...ktttttttttttttTTTTTk....r....",
				"..kttttttttttttttTTTTTTk....r...",
				"..kkkkkkkkkkkkkkkkkkkkkk....e...",
				".......kooooook..kooooook....k..",
				".......koooooook.koooooook......",
				".......kkkkkkkkk.kkkkkkkkk......",
				"................................",
				"................................",
			]
		"arthur_playing_cello": # 40x40
			rows = [
				"........................................",
				"...............wwwwwwwwww...............",
				".............wwssssssssssww.............",
				"............wHssssssssssssHw............",
				"...........wHHssssssssssssHHw...........",
				"...........kHHssssssssssssHHk...........",
				"..........ksHggggggyyggggggHSk..........",
				"..........ksgggghgyyyyghggggSk..........",
				"..........ksggggggggggggggggSk..........",
				"...........kssssssshhsssssssk...........",
				"...........ksssHhhhhhhhhsssk............",
				"............ksHhhhhhhHhhhsk.............",
				".............kwwwwwwwwwwk...............",
				"............kcccccccccccccck............",
				"...........kccccccCDDccccccck...........",
				"..........kttlllccCDDcccclllttk.........",
				".........ktttlllcclDDlccclllTTTk........",
				".........ktttlllcclDDlccclllTTTk........",
				"........kttttllltclDDlctclllTTTTk.......",
				".......ktttttMMMkkkDDkkkMMMttTTTTk......",
				"......ktttttMMmmmmkDDkmmmmMMttTTTTk.....",
				".....kssstttMMmmmmkDDkmmmmMMtTTTksssk...",
				".....kSSktttMMmmmmkDDkmmmmMMtTTTkSSk....",
				"......kk.kttMMmmmmkDDkmmmmMMtTTk.kk.....",
				"........ktttMMmmmmkDDkmmmmMMtTTk........",
				".......ktttttMMmmmkDDkmmmMMttTTTk.......",
				"......ktttttttMMmmkyykmmMMttttTTTk......",
				"......ktttttttttMMMmmMMMttttttTTTk......",
				".....ktttttttttttMMMMMMttttttttTTTk.....",
				".....ktttttttttttttDDttttttttttTTTk.....",
				".....ktttttttttttttDDttttttttttTTTk.....",
				".....kkkkkkkkkkktttDDtttkkkkkkkkkkk.....",
				"........koook...kttDDttk...koook........",
				".......koooook..kttDDttk..koooook.......",
				".......kkkkkkk...kMDDmK...kkkkkkk.......",
				"..................kDDk..................",
				"..................krrk..................",
				"..................krrk..................",
				"...................kk...................",
				"........................................",
			]

	var h := rows.size()
	var w := rows[0].length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in range(h):
		var r_str := rows[y]
		for x in range(w):
			var ch := r_str.substr(x, 1)
			if PALETTE.has(ch):
				img.set_pixel(x, y, PALETTE[ch])
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return img


func _make_card(pos: Vector2, sz: Vector2, fill_col: Color, border_col: Color) -> PanelContainer:
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


# =========================================================================
# DESENHO DE ELEMENTOS COMPLEMENTARES DA CENA ISOMÉTRICA (PAREDES & FX)
# =========================================================================
class PixelWallDrawer extends Node2D:
	var origin: Vector2

	func _draw() -> void:
		# Parede Noroeste (x = 0, y de 0 a 5)
		var p_top_nw := origin + Vector2(0, -60)
		var p_bot_nw := origin + Vector2(0, 0)
		var p_end_nw := origin + Vector2(-5 * 32, 5 * 16)
		var p_top_end_nw := p_end_nw + Vector2(0, -60)

		# Parede Nordeste (y = 0, x de 0 a 5)
		var p_end_ne := origin + Vector2(5 * 32, 5 * 16)
		var p_top_end_ne := p_end_ne + Vector2(0, -60)

		# Painel de Madeira Boiserie Noroeste
		var poly_nw := PackedVector2Array([p_top_nw, p_top_end_nw, p_end_nw, p_bot_nw])
		draw_colored_polygon(poly_nw, Color("#5e3d23"))
		draw_polyline(PackedVector2Array([p_top_nw, p_top_end_nw]), Color("#7d522f"), 2.0)
		draw_polyline(PackedVector2Array([p_top_end_nw, p_end_nw]), Color("#3b2414"), 2.0)

		# Painel de Madeira Boiserie Nordeste
		var poly_ne := PackedVector2Array([p_top_nw, p_top_end_ne, p_end_ne, p_bot_nw])
		draw_colored_polygon(poly_ne, Color("#4c301a"))
		draw_polyline(PackedVector2Array([p_top_nw, p_top_end_ne]), Color("#6a4224"), 2.0)
		draw_polyline(PackedVector2Array([p_top_end_ne, p_end_ne]), Color("#3b2414"), 2.0)

		# Moldura de Rodapé 16-bit
		draw_line(p_bot_nw, p_end_nw, Color("#2b190c"), 2.0)
		draw_line(p_bot_nw, p_end_ne, Color("#2b190c"), 2.0)


class PixelAcousticDrawer extends Node2D:
	var radio_pos: Vector2
	var arthur_pos: Vector2

	func _draw() -> void:
		# Notas musicais de pixel art flutuando a partir do rádio
		var note_col := Color("#f5cb42")
		_draw_pixel_note(radio_pos + Vector2(8, -12), note_col)
		_draw_pixel_note(radio_pos + Vector2(20, -22), Color("#ffd866"))

		# Anéis de ecolocalização concêntricos da bengala no chão sob o Arthur
		for r in [12.0, 24.0]:
			var pts := PackedVector2Array()
			for deg in range(0, 360, 20):
				var rad: float = deg_to_rad(float(deg))
				# Isometria: proporção 2:1 no eixo Y
				pts.append(arthur_pos + Vector2(cos(rad) * r, sin(rad) * r * 0.5))
			pts.append(pts[0])
			draw_polyline(pts, Color(0.9, 0.8, 0.5, 0.45), 1.0)

	func _draw_pixel_note(p: Vector2, col: Color) -> void:
		draw_rect(Rect2(p.x, p.y, 4, 3), col)
		draw_rect(Rect2(p.x + 3, p.y - 6, 2, 8), col)
		draw_rect(Rect2(p.x + 4, p.y - 6, 4, 2), col)
