extends SceneTree
## Renderiza comparação lado a lado de paletas e silhuetas refinadas para o Sr. Arthur.

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")

var _frames := 0
var _vp: SubViewport

func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1120, 840)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1120, 840)
	bg.color = Color(0.12, 0.11, 0.14)
	_vp.add_child(bg)

	var palettes = [
		{
			"id": "indigo",
			"name": "Opção 1: Maestro Indigo (Navy Nobre + Ocre Mostarda + Cáqui Tweed)",
			"desc": "Intelectual e sereno — contraste clássico da música de concerto, zero Natal",
			"cardigan": Color(0.18, 0.25, 0.34),     # #2E4057 Navy profundo
			"card_sh":  Color(0.12, 0.17, 0.24),
			"card_hi":  Color(0.24, 0.33, 0.44),
			"trim":     Color(0.58, 0.36, 0.20),     # Couro conhaque
			"bowtie":   Color(0.85, 0.60, 0.18),     # Ocre mostarda dourado
			"pants":    Color(0.44, 0.38, 0.32),     # Cáqui tweed
			"pants_cf": Color(0.52, 0.46, 0.39),
			"shoe":     Color(0.32, 0.18, 0.10),     # Mogno
			"cane_band": Color(0.85, 0.20, 0.20),
		},
		{
			"id": "terracotta",
			"name": "Opção 2: Luthier Terracota (Madeira de Violoncelo + Chambray + Grafite)",
			"desc": "Inspirado no verniz e madeiras nobres do cello e do piano",
			"cardigan": Color(0.56, 0.28, 0.20),     # #8F4733 Terracota cello
			"card_sh":  Color(0.42, 0.20, 0.14),
			"card_hi":  Color(0.66, 0.36, 0.26),
			"trim":     Color(0.32, 0.16, 0.10),     # Nogueira escura
			"bowtie":   Color(0.18, 0.26, 0.36),     # Azul petróleo
			"pants":    Color(0.22, 0.24, 0.28),     # Grafite carvão
			"pants_cf": Color(0.28, 0.30, 0.35),
			"shoe":     Color(0.26, 0.15, 0.08),     # Couro escuro
			"cane_band": Color(0.85, 0.20, 0.20),
		},
		{
			"id": "oatmeal",
			"name": "Opção 3: Lã Crua & Ameixa (Cardigã Areia + Calça Café + Vinho)",
			"desc": "Estilo avô britânico vintage, tricô suave e acolhedor de outono",
			"cardigan": Color(0.84, 0.80, 0.73),     # #D6CCC2 Areia/Lã crua
			"card_sh":  Color(0.70, 0.65, 0.58),
			"card_hi":  Color(0.92, 0.89, 0.84),
			"trim":     Color(0.50, 0.34, 0.22),     # Caramelo
			"bowtie":   Color(0.42, 0.18, 0.26),     # Ameixa nobre
			"pants":    Color(0.24, 0.18, 0.14),     # Marrom café
			"pants_cf": Color(0.32, 0.25, 0.20),
			"shoe":     Color(0.18, 0.12, 0.08),     # Couro café
			"cane_band": Color(0.85, 0.20, 0.20),
		},
		{
			"id": "sage_navy",
			"name": "Opção 4: Sálvia & Navy (Verde-sálvia Suave + Gravata Azul-Marinho)",
			"desc": "Mantém o tom sálvia original, mas substitui o vermelho por marinho",
			"cardigan": Color(0.32, 0.46, 0.36),     # Verde-sálvia suave
			"card_sh":  Color(0.22, 0.33, 0.25),
			"card_hi":  Color(0.40, 0.54, 0.44),
			"trim":     Color(0.55, 0.35, 0.19),
			"bowtie":   Color(0.18, 0.24, 0.35),     # Gravata azul-marinho nobre
			"pants":    Color(0.28, 0.28, 0.32),     # Carvão azulado
			"pants_cf": Color(0.34, 0.34, 0.39),
			"shoe":     Color(0.30, 0.18, 0.10),
			"cane_band": Color(0.85, 0.20, 0.20),
		},
	]

	for row in range(palettes.size()):
		var p = palettes[row]
		var y_top := 20.0 + float(row) * 200.0

		var header := Label.new()
		header.text = p["name"] + "  |  " + p["desc"]
		header.position = Vector2(40.0, y_top)
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90))
		_vp.add_child(header)

		# 5 poses por paleta: Frente (Sul), 3/4 Frente (Sudeste), Lado (Leste), Costas (Norte), Andando
		var dirs := [
			Vector2i(1, 1),   # Frente
			Vector2i(1, 0),   # 3/4 Frente
			Vector2i(1, -1),  # Lado
			Vector2i(-1, -1), # Costas
			Vector2i(0, 1),   # Andando
		]

		for col in range(dirs.size()):
			var arthur := ProceduralArthurScript.new()
			arthur.position = Vector2(120.0 + float(col) * 200.0, y_top + 155.0)
			arthur.scale = Vector2(2.5, 2.5)

			# Aplica as cores da paleta dinamicamente
			arthur.set_meta("custom_cardigan", p["cardigan"])
			arthur.set_meta("custom_card_sh",  p["card_sh"])
			arthur.set_meta("custom_card_hi",  p["card_hi"])
			arthur.set_meta("custom_trim",     p["trim"])
			arthur.set_meta("custom_bowtie",   p["bowtie"])
			arthur.set_meta("custom_pants",    p["pants"])
			arthur.set_meta("custom_pants_cf", p["pants_cf"])
			arthur.set_meta("custom_shoe",     p["shoe"])
			arthur.set_meta("custom_cane_band", p["cane_band"])

			arthur.set_direction(dirs[col], true)
			if col == 4:
				arthur.anim_state = "walk"
				arthur.walk_phase = 1.2
			elif col == 1:
				arthur.set_continuous_tuning_angle(arthur.facing_angle, Color(0.92, 0.75, 0.35, 0.8))

			_vp.add_child(arthur)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= 4:
		var img := _vp.get_texture().get_image()
		if img != null:
			img.save_png("C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/arthur_palette_variants.png")
		quit(0)
		return true
	return false
