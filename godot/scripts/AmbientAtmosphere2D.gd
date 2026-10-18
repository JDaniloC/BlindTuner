extends Node2D
class_name AmbientAtmosphere2D
## Atmosfera 2D puramente procedural para os cenários isométricos do BlindTuner.
## Compõe:
##   1. Fundo diorama 2D (z_index = -195) com tom acolhedor por capítulo/ambiente
##   2. Feixes diagonais 2D de luz de janela/abajur sobre o piso (z_index = -96)
##   3. Partículas pixel-art 2D em movimento suave (z_index = 180):
##      - "dust": poeira dourada flutuando sob feixes de sol (quarto, sala, estúdio)
##      - "nocturne": vagalumes/cintilações de luar (quarto_lullaby, estação)
##      - "mist": gotículas/vapor d'água subindo (banheiro, chafariz, praia)
##      - "breeze": folhas/pétalas levadas pela brisa diagonal (jardim, praça, calçada)

const PARTICLE_COUNT := 18

var map_id: String = "quarto"
var room_center: Vector2 = Vector2(0.0, 140.0)
var room_extent: Vector2 = Vector2(360.0, 220.0)
var mode: String = "dust"

var _backdrop_layer: _BackdropDrawer
var _light_layer: _LightShaftDrawer
var _motes_layer: _MotesDrawer
var _particles: Array[Dictionary] = []
var _time: float = 0.0

func _ready() -> void:
	_ensure_layers()
	_rebuild_particles()

func setup(p_map_id: String, p_center: Vector2, p_extent: Vector2) -> void:
	map_id = p_map_id
	room_center = p_center
	room_extent = p_extent
	mode = _classify_mode(map_id)
	_ensure_layers()
	_backdrop_layer.configure(room_center, _backdrop_color_for(map_id))
	_light_layer.configure(room_center, room_extent, _beam_color_for(map_id), mode)
	_rebuild_particles()
	_motes_layer.queue_redraw()

func _ensure_layers() -> void:
	if _backdrop_layer == null:
		_backdrop_layer = _BackdropDrawer.new()
		_backdrop_layer.name = "DioramaBackdrop2D"
		_backdrop_layer.z_index = -195
		add_child(_backdrop_layer)
	if _light_layer == null:
		_light_layer = _LightShaftDrawer.new()
		_light_layer.name = "IsometricLightShafts2D"
		_light_layer.z_index = -96
		add_child(_light_layer)
	if _motes_layer == null:
		_motes_layer = _MotesDrawer.new()
		_motes_layer.name = "PixelMotes2D"
		_motes_layer.z_index = 180
		_motes_layer.owner_atmo = self
		add_child(_motes_layer)

static func _classify_mode(id: String) -> String:
	match id:
		"quarto_lullaby", "estacao_plataforma":
			return "nocturne"
		"banheiro", "praca_chafariz", "praia_mirante":
			return "mist"
		"jardim", "jardim_portao", "padaria_calcada", "largo_matriz", "arcade_s1_vento", "arcade_s4_vento", "arcade_s5_flores":
			return "breeze"
		_:
			return "dust"

static func _backdrop_color_for(id: String) -> Color:
	match id:
		"quarto_lullaby":
			return Color(0.06, 0.08, 0.15, 1.0)
		"banheiro":
			return Color(0.11, 0.15, 0.19, 1.0)
		"jardim", "jardim_portao", "praca_chafariz", "arcade_s5_flores":
			return Color(0.08, 0.13, 0.10, 1.0)
		"praia_mirante", "estacao_plataforma":
			return Color(0.07, 0.11, 0.18, 1.0)
		"estudio_conservatorio", "teatro_palco", "largo_matriz", "arcade_s6_igreja":
			return Color(0.12, 0.08, 0.09, 1.0)
		_:
			return Color(0.11, 0.08, 0.06, 1.0)

static func _beam_color_for(id: String) -> Color:
	match id:
		"quarto_lullaby", "estacao_plataforma":
			return Color(0.55, 0.72, 1.0, 0.08)
		"banheiro", "praca_chafariz", "praia_mirante":
			return Color(0.65, 0.92, 1.0, 0.07)
		_:
			return Color(1.0, 0.88, 0.58, 0.09)

func _rebuild_particles() -> void:
	_particles.clear()
	var rx := maxf(room_extent.x, 160.0)
	var ry := maxf(room_extent.y, 110.0)
	for i in range(PARTICLE_COUNT):
		var seed_a := float(i) * 1.6180339
		var px := room_center.x + sin(seed_a * 4.3) * rx * 0.75
		var py := room_center.y + cos(seed_a * 2.9) * ry * 0.65
		var vel := Vector2(4.0, -5.0)
		var col := Color(1.0, 0.90, 0.60)
		var sz := 2.0 if (i % 3 != 0) else 3.0
		match mode:
			"nocturne":
				vel = Vector2(sin(seed_a) * 5.0, -4.0 - float(i % 3) * 1.5)
				col = Color(0.72, 0.86, 1.0) if (i % 2 == 0) else Color(1.0, 0.88, 0.52)
			"mist":
				vel = Vector2(sin(seed_a) * 3.5, -10.0 - float(i % 4) * 2.0)
				col = Color(0.75, 0.95, 1.0)
			"breeze":
				vel = Vector2(18.0 + float(i % 4) * 3.0, 7.0 + sin(seed_a) * 3.0)
				col = Color(0.96, 0.76, 0.42) if (i % 2 == 0) else Color(0.68, 0.88, 0.58)
				sz = 3.0
			_:
				vel = Vector2(3.5 + sin(seed_a) * 2.0, -4.5 - float(i % 3))
				col = Color(1.0, 0.90, 0.62)
		_particles.append({
			"pos": Vector2(px, py),
			"vel": vel,
			"phase": seed_a * TAU,
			"size": sz,
			"color": col,
		})

func _process(delta: float) -> void:
	_time += delta
	var rx := maxf(room_extent.x, 160.0) * 0.82
	var ry := maxf(room_extent.y, 110.0) * 0.72
	for p in _particles:
		var pos: Vector2 = p["pos"]
		var vel: Vector2 = p["vel"]
		var phase: float = float(p["phase"])
		pos += (vel + Vector2(sin(_time * 1.4 + phase) * 3.0, cos(_time * 1.1 + phase) * 1.5)) * delta
		if pos.x < room_center.x - rx:
			pos.x = room_center.x + rx
		elif pos.x > room_center.x + rx:
			pos.x = room_center.x - rx
		if pos.y < room_center.y - ry:
			pos.y = room_center.y + ry
		elif pos.y > room_center.y + ry:
			pos.y = room_center.y - ry
		p["pos"] = pos
	if _motes_layer != null:
		_motes_layer.queue_redraw()


class _BackdropDrawer extends Node2D:
	var center: Vector2 = Vector2.ZERO
	var bg_color: Color = Color(0.11, 0.08, 0.06, 1.0)

	func configure(p_center: Vector2, p_col: Color) -> void:
		center = p_center
		bg_color = p_col
		queue_redraw()

	func _draw() -> void:
		# Retângulo amplo 2D cobrindo todo o campo da câmera isométrica
		draw_rect(Rect2(center - Vector2(1200, 1200), Vector2(2400, 2400)), bg_color, true)
		# Halo suave radial 2D sob o diorama da sala para destacá-lo do fundo escuro
		var glow_col := bg_color.lightened(0.12)
		glow_col.a = 0.45
		var pts := PackedVector2Array()
		for i in range(28):
			var a := float(i) * TAU / 28.0
			pts.append(center + Vector2(cos(a) * 340.0, sin(a) * 185.0))
		draw_colored_polygon(pts, glow_col)


class _LightShaftDrawer extends Node2D:
	var center: Vector2 = Vector2.ZERO
	var extent: Vector2 = Vector2(320, 200)
	var beam_color: Color = Color(1.0, 0.88, 0.58, 0.09)
	var atmo_mode: String = "dust"

	func configure(p_center: Vector2, p_extent: Vector2, p_col: Color, p_mode: String) -> void:
		center = p_center
		extent = p_extent
		beam_color = p_col
		atmo_mode = p_mode
		queue_redraw()

	func _draw() -> void:
		# Dois feixes diagonais 2D alinhados à luz Noroeste -> Sudeste sobre o piso
		for idx in range(2):
			var offset_x := -55.0 + float(idx) * 95.0
			var offset_y := -25.0 + float(idx) * 35.0
			var origin := center + Vector2(offset_x - 70.0, offset_y - 55.0)
			var poly := PackedVector2Array([
				origin + Vector2(-24.0, 12.0),
				origin + Vector2(18.0, -9.0),
				origin + Vector2(140.0, 62.0),
				origin + Vector2(84.0, 90.0),
			])
			draw_colored_polygon(poly, beam_color)


class _MotesDrawer extends Node2D:
	var owner_atmo: AmbientAtmosphere2D = null

	func _draw() -> void:
		if owner_atmo == null:
			return
		var t := owner_atmo._time
		for p in owner_atmo._particles:
			var pos: Vector2 = (p["pos"] as Vector2).round()
			var phase: float = float(p["phase"])
			var sz: float = float(p["size"])
			var base_c: Color = p["color"]
			var alpha := (0.35 + 0.45 * (0.5 + 0.5 * sin(t * 2.2 + phase)))
			var c := Color(base_c.r, base_c.g, base_c.b, alpha)
			# Pixel-art 2D: quadradinhos alinhados ao grid de pixels
			draw_rect(Rect2(pos, Vector2(sz, sz)), c, true)
