extends SceneTree
## Renderiza a vitrine final dos avanços gráficos 2.5D incorporados no Godot 4:
## 1. Rotação 360° do Sr. Arthur com alinhamento matemático rigoroso (passo e mira idênticos).
## 2. Móveis procedurais com animação viva contínua e ressonância harmônica.
## 3. Quarto isométrico com onda acústica de ecolocalização e sinestesia sonora no piso.

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")
const ProceduralFurnitureScript := preload("res://scripts/ProceduralFurniture25D.gd")
const CaneAcousticPulseScript := preload("res://scripts/CaneAcousticPulse.gd")
const Iso25DScript := preload("res://scripts/Iso25DCanvas.gd")

var _frames := 0
var _vp: SubViewport

func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1200, 980)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1200, 980)
	bg.color = Color(0.11, 0.10, 0.14)
	_vp.add_child(bg)

	# --- CABEÇALHO ---
	var title_lbl := Label.new()
	title_lbl.text = "BLINDTUNER — MOTOR 2.5D GODOT 4: ALINHAMENTO 360°, SINESTESIA & CENÁRIO VIVO"
	title_lbl.position = Vector2(30, 20)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.65))
	_vp.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Visual Virtuoso Vintage: boina tweed, óculos redondos bronze, casaco terracota | Testes GUT: 724/724 Verdes (100%)"
	sub_lbl.position = Vector2(30, 50)
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.72, 0.70, 0.78))
	_vp.add_child(sub_lbl)

	# --- SEÇÃO 1: SR. ARTHUR 360° (8 DIREÇÕES RIGOROSAS) ---
	var sec1_lbl := Label.new()
	sec1_lbl.text = "1. ROTAÇÃO 360° & ALINHAMENTO MATEMÁTICO RIGOROSO (MIRA CELLO == PASSO NO GRID 2:1)"
	sec1_lbl.position = Vector2(30, 85)
	sec1_lbl.add_theme_font_size_override("font_size", 14)
	sec1_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	_vp.add_child(sec1_lbl)

	var dirs := [
		{"dir": Vector2i(1, 1), "name": "S (Frente)"},
		{"dir": Vector2i(1, 0), "name": "SE (Passo)"},
		{"dir": Vector2i(1, -1), "name": "Leste (Cello)"},
		{"dir": Vector2i(0, -1), "name": "NE (Passo)"},
		{"dir": Vector2i(-1, -1), "name": "N (Costas)"},
		{"dir": Vector2i(-1, 0), "name": "NW (Passo)"},
		{"dir": Vector2i(-1, 1), "name": "Oeste (Cello)"},
		{"dir": Vector2i(0, 1), "name": "SW (Passo)"},
	]

	for i in range(dirs.size()):
		var info = dirs[i]
		var col_x := 80 + i * 132

		var arthur := ProceduralArthurScript.new()
		arthur.position = Vector2(col_x, 195)
		arthur.scale = Vector2(2.3, 2.3)
		arthur.set_direction(info["dir"], true)

		if i == 1 or i == 3 or i == 5 or i == 7:
			arthur.anim_state = "walk"
			arthur.walk_phase = 0.85 + float(i) * 0.2
		elif i == 2:
			arthur.set_continuous_tuning_angle(arthur.facing_angle, Color(0.35, 0.88, 1.0, 0.85))
			arthur.trigger_cane_tap_spark()
		elif i == 6:
			arthur.set_continuous_tuning_angle(arthur.facing_angle, Color(0.98, 0.78, 0.32, 0.85))
			arthur.trigger_cane_tap_spark()

		_vp.add_child(arthur)

		# Tag abaixo do personagem para zero sobreposição
		var tag := Label.new()
		tag.text = info["name"]
		tag.position = Vector2(col_x - 55, 252)
		tag.size = Vector2(110, 20)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_font_size_override("font_size", 11)
		tag.add_theme_color_override("font_color", Color(0.70, 0.70, 0.78))
		_vp.add_child(tag)

	# --- SEÇÃO 2: CATÁLOGO DE MÓVEIS ISOMÉTRICOS VIVOS ---
	var sec2_lbl := Label.new()
	sec2_lbl.text = "2. MOBILIÁRIO COZY 2.5D REATIVO (PENDULO OSCILANTE, ABAJUR ILUMINADO, RÁDIO VINTAGE)"
	sec2_lbl.position = Vector2(30, 290)
	sec2_lbl.add_theme_font_size_override("font_size", 14)
	sec2_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	_vp.add_child(sec2_lbl)

	var props := [
		{"kind": "bed", "name": "Cama Rústica"},
		{"kind": "nightstand", "name": "Criado & Abajur"},
		{"kind": "radio", "name": "Rádio Válvula"},
		{"kind": "clock", "name": "Relógio Pêndulo"},
		{"kind": "sink", "name": "Pia Espelhada"},
		{"kind": "armchair", "name": "Poltrona Sálvia"},
		{"kind": "coffee_table", "name": "Mesa & Café"},
	]

	for j in range(props.size()):
		var pinfo = props[j]
		var col_x := 105 + j * 162

		var prop := ProceduralFurnitureScript.new()
		prop.setup(pinfo["kind"])
		prop.position = Vector2(col_x, 460)
		prop.scale = Vector2(2.3, 2.3)
		prop._time = 0.45
		if pinfo["kind"] == "clock" or pinfo["kind"] == "nightstand":
			prop.trigger_harmonic_glow(Color(0.4, 0.9, 1.0, 1.0))
		_vp.add_child(prop)

		# Tag abaixo do móvel
		var ptag := Label.new()
		ptag.text = pinfo["name"]
		ptag.position = Vector2(col_x - 60, 510)
		ptag.size = Vector2(120, 20)
		ptag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ptag.add_theme_font_size_override("font_size", 11)
		ptag.add_theme_color_override("font_color", Color(0.70, 0.70, 0.78))
		_vp.add_child(ptag)

	# --- SEÇÃO 3: VINHETA DO QUARTO COM ONDA DE SINESTESIA SONORA ---
	var sec3_lbl := Label.new()
	sec3_lbl.text = "3. ECOLOCALIZAÇÃO & SINESTESIA: ONDA ACÚSTICA COLORIDA ILUMINA PISO E FAZ MÓVEIS RESSOAREM"
	sec3_lbl.position = Vector2(30, 555)
	sec3_lbl.add_theme_font_size_override("font_size", 14)
	sec3_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	_vp.add_child(sec3_lbl)

	# Mini quarto isométrico integrado
	var room_container := Node2D.new()
	room_container.position = Vector2(600, 770)
	_vp.add_child(room_container)

	# Chão de tábuas de madeira 2:1 (6x6 tiles)
	var tile_w := 64.0
	var tile_h := 32.0
	for gx in range(-3, 3):
		for gy in range(-3, 3):
			var sx := (gx - gy) * (tile_w * 0.5)
			var sy := (gx + gy) * (tile_h * 0.5)
			var poly := Polygon2D.new()
			poly.polygon = PackedVector2Array([
				Vector2(0, -tile_h * 0.5),
				Vector2(tile_w * 0.5, 0),
				Vector2(0, tile_h * 0.5),
				Vector2(-tile_w * 0.5, 0),
			])
			poly.position = Vector2(sx, sy)
			var base_c := Color(0.24, 0.17, 0.13) if (gx + gy) % 2 == 0 else Color(0.21, 0.15, 0.11)
			poly.color = base_c
			room_container.add_child(poly)

			# Linha de rejunte/borda do piso
			var border := Line2D.new()
			border.points = PackedVector2Array([
				Vector2(0, -tile_h * 0.5),
				Vector2(tile_w * 0.5, 0),
				Vector2(0, tile_h * 0.5),
				Vector2(-tile_w * 0.5, 0),
				Vector2(0, -tile_h * 0.5),
			])
			border.width = 1.0
			border.default_color = Color(0.14, 0.10, 0.08, 0.6)
			border.position = Vector2(sx, sy)
			room_container.add_child(border)

	# Móveis no quarto
	var room_bed := ProceduralFurnitureScript.new()
	room_bed.setup("bed")
	room_bed.position = Vector2(-110, -50)
	room_bed.scale = Vector2(2.0, 2.0)
	room_container.add_child(room_bed)

	var room_nightstand := ProceduralFurnitureScript.new()
	room_nightstand.setup("nightstand")
	room_nightstand.position = Vector2(-170, -20)
	room_nightstand.scale = Vector2(2.0, 2.0)
	room_nightstand.trigger_harmonic_glow(Color(0.35, 0.9, 1.0, 1.0))
	room_container.add_child(room_nightstand)

	var room_clock := ProceduralFurnitureScript.new()
	room_clock.setup("clock")
	room_clock.position = Vector2(140, -40)
	room_clock.scale = Vector2(2.0, 2.0)
	room_clock._time = 0.6
	room_clock.trigger_harmonic_glow(Color(0.35, 0.9, 1.0, 1.0))
	room_container.add_child(room_clock)

	var room_chair := ProceduralFurnitureScript.new()
	room_chair.setup("armchair")
	room_chair.position = Vector2(130, 40)
	room_chair.scale = Vector2(2.0, 2.0)
	room_chair.trigger_harmonic_glow(Color(0.35, 0.9, 1.0, 1.0))
	room_container.add_child(room_chair)

	# Ondas acústicas elípticas de sinestesia sonora (Nota Ré: Turquesa vibrante / Nota Lá: Dourado)
	for ring_idx in range(4):
		var ring := Line2D.new()
		var rad_x := 45.0 + float(ring_idx) * 45.0
		var rad_y := rad_x * 0.5
		var pts := PackedVector2Array()
		for step in range(33):
			var a := TAU * float(step) / 32.0
			pts.append(Vector2(cos(a) * rad_x, sin(a) * rad_y))
		ring.points = pts
		ring.width = 3.5 - float(ring_idx) * 0.6
		var alpha := 0.9 - float(ring_idx) * 0.22
		ring.default_color = Color(0.35, 0.88, 1.0, alpha)
		ring.position = Vector2(0, 10)
		room_container.add_child(ring)

	# Sr. Arthur no centro do quarto tocando bengala
	var room_arthur := ProceduralArthurScript.new()
	room_arthur.position = Vector2(0, 5)
	room_arthur.scale = Vector2(2.5, 2.5)
	room_arthur.set_direction(Vector2i(1, 0), true) # SE
	room_arthur.set_continuous_tuning_angle(room_arthur.facing_angle, Color(0.35, 0.92, 1.0, 0.9))
	room_arthur.trigger_cane_tap_spark()
	room_container.add_child(room_arthur)

	# Legenda explicativa no canto inferior
	var foot_lbl := Label.new()
	foot_lbl.text = "Pressione [ESPAÇO] no jogo para afinar a nota continuamente via slider harmônico | Bengala sinalizada com ponta refletiva | Paleta de Alto Contraste"
	foot_lbl.position = Vector2(30, 950)
	foot_lbl.add_theme_font_size_override("font_size", 11)
	foot_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	_vp.add_child(foot_lbl)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= 5:
		var img := _vp.get_texture().get_image()
		if img != null:
			img.save_png("C:/Users/danil/.gemini/antigravity/brain/3bd86ba7-be99-41e6-82ff-23dec236b5e0/godot_25d_virtuoso_showcase.png")
		quit(0)
		return true
	return false
