extends SceneTree
## Renderiza vitrine em alta resolução do Paradigma 3 (Paper-Cutout Artesanal Refinado)
## com foco nos detalhes finos, perfil corrigido (haste dos óculos + cabelo anatômico),
## broche de diapasão, pespontos de alfaiataria, franjas e calçado Oxford.

const ProceduralArthurScript := preload("res://scripts/ProceduralArthur25D.gd")

var _frames := 0
var _vp: SubViewport

func _init() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1200, 720)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(1200, 720)
	bg.color = Color(0.12, 0.11, 0.14)
	_vp.add_child(bg)

	# Título principal e subtítulo
	var title := Label.new()
	title.text = "Paradigma 3: Paper-Cutout Artesanal Refinado (Luthier Terracota)"
	title.position = Vector2(40.0, 24.0)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90))
	_vp.add_child(title)

	var desc := Label.new()
	desc.text = "Correção anatômica de perfil (cabelo rente + haste dos óculos na orelha) | Detalhes finos: Broche de Diapasão, Pesponto, Franjas e Oxford"
	desc.position = Vector2(40.0, 52.0)
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.75, 0.73, 0.70))
	_vp.add_child(desc)

	# Linha 1: 5 Poses em Grande Escala (Frente, 3/4 Frente, Perfil Completo, Costas, Caminhando)
	var poses = [
		{"title": "1. Frente (Sul)", "dir": Vector2i(1, 1), "walk": false, "tune": false},
		{"title": "2. 3/4 Frente (Sudeste)", "dir": Vector2i(1, 0), "walk": false, "tune": false},
		{"title": "3. Perfil (Leste / Haste + Orelha)", "dir": Vector2i(1, -1), "walk": false, "tune": false},
		{"title": "4. Costas (Norte / Nuca)", "dir": Vector2i(-1, -1), "walk": false, "tune": false},
		{"title": "5. Em Movimento (Passos + Tecido)", "dir": Vector2i(0, 1), "walk": true, "tune": false},
	]

	for i in range(poses.size()):
		var p = poses[i]
		var col_x := 125.0 + float(i) * 230.0
		var char_y := 270.0

		var lbl := Label.new()
		lbl.text = p["title"]
		lbl.position = Vector2(col_x - 85.0, 92.0)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.80))
		_vp.add_child(lbl)

		var char_node := ProceduralArthurScript.new()
		char_node.position = Vector2(col_x, char_y)
		char_node.scale = Vector2(3.4, 3.4)
		char_node.eyewear_style = "dark_shades"
		char_node.headwear_style = "none"
		char_node.assembly_mode = "paper_cutout"
		char_node.set_direction(p["dir"], true)

		if p["walk"]:
			char_node.anim_state = "walk"
			char_node.walk_phase = 1.35

		_vp.add_child(char_node)

	# Linha 2: Close-ups dos dois perfis (Leste e Oeste) e Varredura com Diapasão
	var detail_header := Label.new()
	detail_header.text = "Visualização de Perfil Rigorosa (Cabelo Rente na Nuca + Haste dos Óculos na Orelha + Bigode Contido):"
	detail_header.position = Vector2(40.0, 395.0)
	detail_header.add_theme_font_size_override("font_size", 14)
	detail_header.add_theme_color_override("font_color", Color(0.92, 0.86, 0.70))
	_vp.add_child(detail_header)

	var sub_poses = [
		{"label": "Perfil Direito (Leste) em Repouso", "dir": Vector2i(1, -1), "walk": false, "tune": false, "scale": 4.2},
		{"label": "Perfil Esquerdo (Oeste) em Repouso", "dir": Vector2i(-1, 1), "walk": false, "tune": false, "scale": 4.2},
		{"label": "Perfil Direito em Caminhada Fluida", "dir": Vector2i(1, -1), "walk": true, "tune": false, "scale": 4.2},
		{"label": "Afinação Harmônica com Diapasão", "dir": Vector2i(1, 0), "walk": false, "tune": true, "scale": 4.2},
	]

	for j in range(sub_poses.size()):
		var sp = sub_poses[j]
		var sub_x := 145.0 + float(j) * 280.0
		var sub_y := 630.0

		var sub_lbl := Label.new()
		sub_lbl.text = sp["label"]
		sub_lbl.position = Vector2(sub_x - 105.0, 428.0)
		sub_lbl.add_theme_font_size_override("font_size", 12)
		sub_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.75))
		_vp.add_child(sub_lbl)

		var char_sub := ProceduralArthurScript.new()
		char_sub.position = Vector2(sub_x, sub_y)
		char_sub.scale = Vector2(sp["scale"], sp["scale"])
		char_sub.eyewear_style = "dark_shades"
		char_sub.headwear_style = "none"
		char_sub.assembly_mode = "paper_cutout"
		char_sub.set_direction(sp["dir"], true)

		if sp["walk"]:
			char_sub.anim_state = "walk"
			char_sub.walk_phase = 1.4
		elif sp["tune"]:
			char_sub.set_continuous_tuning_angle(char_sub.facing_angle, Color(0.95, 0.82, 0.45, 0.85))

		_vp.add_child(char_sub)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= 5:
		var img := _vp.get_texture().get_image()
		if img != null:
			img.save_png("C:/Users/danil/.gemini/antigravity/brain/c5776624-7add-4fcc-999d-1493a7216bd8/paper_cutout_refined_showcase.png")
		quit(0)
		return true
	return false
