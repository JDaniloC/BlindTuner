class_name Iso25DCanvas
extends RefCounted
## Motor Geométrico 2.5D Isométrico (Projeção Matemática 2:1 + Iluminação Cel-Shaded).
##
## Resolve definitivamente os problemas de geração de assets isométricos (como desalinhamento
## de losangos, efeito escadinha, paredes invertidas e móveis flutuando):
## - Todo objeto é descrito em coordenadas locais 3D (x = Sul-Leste, y = Sul-Oeste, z = Altura).
## - A projeção 2:1 (screen_x = x - y, screen_y = (x + y)*0.5 - z) garante encaixe matemático
##   perfeito no grid 64x32 do jogo em qualquer escala ou rotação.

## Converte uma coordenada 3D local (x, y, z) para o espaço de tela 2D isométrico 2:1.
## +x avança para baixo-direita (SE), +y avança para baixo-esquerda (SW), +z sobe (-Y na tela).
static func project(p: Vector3) -> Vector2:
	return Vector2(p.x - p.y, (p.x + p.y) * 0.5 - p.z)


## Retorna a chave de profundidade (depth sort) de um ponto 3D para ordenação Painter's Algorithm.
## Quanto maior (x + y) e maior z, mais à frente da câmera isométrica o elemento está.
static func depth_of(p: Vector3) -> float:
	return (p.x + p.y) + p.z * 0.15


## Rotaciona um ponto (x, y, z) em torno do eixo vertical Z por um ângulo em radianos.
static func rotate_z(p: Vector3, angle_rad: float) -> Vector3:
	var c := cos(angle_rad)
	var s := sin(angle_rad)
	return Vector3(
		p.x * c - p.y * s,
		p.x * s + p.y * c,
		p.z
	)


## Desenha uma sombra de contato elíptica 2:1 perfeitamente ancorada no chão (z = 0).
static func draw_contact_shadow(canvas: CanvasItem, center3d: Vector3, radius_x: float, radius_y: float = -1.0, alpha: float = 0.26) -> void:
	var ry := radius_x * 0.5 if radius_y < 0.0 else radius_y
	var c2d := project(Vector3(center3d.x, center3d.y, 0.0))
	var pts := PackedVector2Array()
	var steps := 20
	for i in range(steps):
		var a := TAU * float(i) / float(steps)
		pts.append(c2d + Vector2(cos(a) * radius_x, sin(a) * ry))
	canvas.draw_colored_polygon(pts, Color(0.05, 0.03, 0.02, alpha))


## Desenha um bloco 3D alinhado aos eixos isométricos (origin3d = canto traseiro-inferior min_x, min_y, min_z).
## Aplica iluminação direcional Cozy automaticamente:
## - Topo (+Z): +14% mais claro (luz solar quente de cima)
## - Face Sul-Oeste (+X frontal-esquerda): cor base iluminada
## - Face Sul-Leste (+Y frontal-direita): -18% em sombra suave
## - Contorno externo escuro nítido de 1px + brilho de quina superior (crest highlight).
static func draw_iso_box(
	canvas: CanvasItem,
	origin3d: Vector3,
	size3d: Vector3,
	base_color: Color,
	outline_color: Color = Color(0.16, 0.10, 0.08, 0.95),
	crest_highlight: bool = true
) -> void:
	var x0 := origin3d.x
	var y0 := origin3d.y
	var z0 := origin3d.z
	var x1 := x0 + size3d.x
	var y1 := y0 + size3d.y
	var z1 := z0 + size3d.z

	# Vértices projetados
	var p_top_back := project(Vector3(x0, y0, z1))
	var p_top_right := project(Vector3(x1, y0, z1))
	var p_top_front := project(Vector3(x1, y1, z1))
	var p_top_left := project(Vector3(x0, y1, z1))

	var p_bot_right := project(Vector3(x1, y0, z0))
	var p_bot_front := project(Vector3(x1, y1, z0))
	var p_bot_left := project(Vector3(x0, y1, z0))

	var col_top := base_color.lightened(0.14)
	var col_left := base_color
	var col_right := base_color.darkened(0.18)

	# 1. Face Esquerda (Sul-Oeste: y = y1)
	if size3d.z > 0.01 and size3d.x > 0.01:
		canvas.draw_colored_polygon(
			PackedVector2Array([p_top_left, p_top_front, p_bot_front, p_bot_left]),
			col_left
		)

	# 2. Face Direita (Sul-Leste: x = x1)
	if size3d.z > 0.01 and size3d.y > 0.01:
		canvas.draw_colored_polygon(
			PackedVector2Array([p_top_front, p_top_right, p_bot_right, p_bot_front]),
			col_right
		)

	# 3. Face Superior (Topo: z = z1)
	if size3d.x > 0.01 and size3d.y > 0.01:
		canvas.draw_colored_polygon(
			PackedVector2Array([p_top_back, p_top_right, p_top_front, p_top_left]),
			col_top
		)

	# 4. Brilho interno da quina frontal (Crest Highlight)
	if crest_highlight and size3d.x > 1.0 and size3d.y > 1.0:
		var crest_col := base_color.lightened(0.28)
		crest_col.a = 0.75
		canvas.draw_polyline(
			PackedVector2Array([p_top_left, p_top_front, p_top_right]),
			crest_col,
			1.0
		)
		if size3d.z > 1.0:
			canvas.draw_line(p_top_front, p_bot_front, base_color.darkened(0.08), 1.0)

	# 5. Contorno externo de silhueta 1px (Clean Cozy Outline)
	if outline_color.a > 0.01:
		var silhouette := PackedVector2Array([
			p_top_back,
			p_top_right,
			p_bot_right,
			p_bot_front,
			p_bot_left,
			p_top_left,
			p_top_back
		])
		canvas.draw_polyline(silhouette, outline_color, 1.2)


## Desenha um cilindro vertical 2.5D (ex: abajur, xícara, tronco, coluna, chapéu)
## com sombreamento em degraus (stepped cel-shading) e tampo elíptico 2:1.
static func draw_iso_cylinder(
	canvas: CanvasItem,
	base_center3d: Vector3,
	radius: float,
	height: float,
	base_color: Color,
	outline_color: Color = Color(0.16, 0.10, 0.08, 0.95)
) -> void:
	var c_bot := project(base_center3d)
	var c_top := project(base_center3d + Vector3(0.0, 0.0, height))
	var rx := radius
	var ry := radius * 0.5

	# Corpo lateral com 2 faixas de luz (esquerda iluminada, direita em sombra)
	var body_left := PackedVector2Array([
		c_top + Vector2(-rx, 0.0),
		c_top + Vector2(0.0, ry),
		c_bot + Vector2(0.0, ry),
		c_bot + Vector2(-rx, 0.0),
	])
	var body_right := PackedVector2Array([
		c_top + Vector2(0.0, ry),
		c_top + Vector2(rx, 0.0),
		c_bot + Vector2(rx, 0.0),
		c_bot + Vector2(0.0, ry),
	])
	canvas.draw_colored_polygon(body_left, base_color)
	canvas.draw_colored_polygon(body_right, base_color.darkened(0.16))

	# Base inferior arredondada
	var steps := 16
	var bot_cap := PackedVector2Array()
	for i in range(steps + 1):
		var a := PI * float(i) / float(steps) # arco frontal inferior (0..PI)
		bot_cap.append(c_bot + Vector2(cos(a) * rx, sin(a) * ry))
	bot_cap.append(c_top + Vector2(-rx, 0.0))
	bot_cap.append(c_top + Vector2(rx, 0.0))
	canvas.draw_colored_polygon(bot_cap, base_color.darkened(0.08))

	# Tampo elíptico superior
	var top_pts := PackedVector2Array()
	for i in range(steps * 2):
		var a := TAU * float(i) / float(steps * 2)
		top_pts.append(c_top + Vector2(cos(a) * rx, sin(a) * ry))
	canvas.draw_colored_polygon(top_pts, base_color.lightened(0.15))

	# Contorno
	if outline_color.a > 0.01:
		var top_closed := PackedVector2Array(top_pts)
		top_closed.append(top_pts[0])
		canvas.draw_polyline(top_closed, outline_color, 1.1)
		canvas.draw_line(c_top + Vector2(-rx, 0.0), c_bot + Vector2(-rx, 0.0), outline_color, 1.2)
		canvas.draw_line(c_top + Vector2(rx, 0.0), c_bot + Vector2(rx, 0.0), outline_color, 1.2)
		var bot_arc := PackedVector2Array()
		for i in range(steps + 1):
			var a := PI * float(i) / float(steps)
			bot_arc.append(c_bot + Vector2(cos(a) * rx, sin(a) * ry))
		canvas.draw_polyline(bot_arc, outline_color, 1.2)


## Desenha uma esfera/elipsoide estilizada 2.5D com volume cel-shaded (sombra em crescente,
## luz base e brilho especular superior) e contorno 1px. Ideal para cabeça, mãos, almofadas.
static func draw_iso_sphere(
	canvas: CanvasItem,
	center3d: Vector3,
	radius_xy: float,
	radius_z: float,
	base_color: Color,
	outline_color: Color = Color(0.16, 0.10, 0.08, 0.95),
	highlight_strength: float = 0.16
) -> void:
	var c2d := project(center3d)
	var steps := 20

	# 1. Silhueta externa de contorno (1.2px maior)
	if outline_color.a > 0.01:
		var out_pts := PackedVector2Array()
		for i in range(steps):
			var a := TAU * float(i) / float(steps)
			out_pts.append(c2d + Vector2(cos(a) * (radius_xy + 1.2), sin(a) * (radius_z + 1.2)))
		canvas.draw_colored_polygon(out_pts, outline_color)

	# 2. Camada de sombra base (crescente inferior-direito)
	var shadow_pts := PackedVector2Array()
	for i in range(steps):
		var a := TAU * float(i) / float(steps)
		shadow_pts.append(c2d + Vector2(cos(a) * radius_xy, sin(a) * radius_z))
	canvas.draw_colored_polygon(shadow_pts, base_color.darkened(0.14))

	# 3. Camada principal iluminada (deslocada levemente para cima-esquerda em direção à luz)
	var lit_pts := PackedVector2Array()
	var lit_offset := Vector2(-radius_xy * 0.08, -radius_z * 0.10)
	for i in range(steps):
		var a := TAU * float(i) / float(steps)
		lit_pts.append(c2d + lit_offset + Vector2(cos(a) * (radius_xy * 0.90), sin(a) * (radius_z * 0.88)))
	canvas.draw_colored_polygon(lit_pts, base_color)

	# 4. Brilho especular suave no topo-esquerdo
	if highlight_strength > 0.01:
		var hi_pts := PackedVector2Array()
		var hi_center := c2d + Vector2(-radius_xy * 0.28, -radius_z * 0.34)
		for i in range(12):
			var a := TAU * float(i) / 12.0
			hi_pts.append(hi_center + Vector2(cos(a) * (radius_xy * 0.34), sin(a) * (radius_z * 0.28)))
		canvas.draw_colored_polygon(hi_pts, base_color.lightened(highlight_strength))
