class_name ProceduralFurniture25D
extends Node2D
## Renderizador Procedural 2.5D de Móveis e Marcos Acústicos Isométricos (2:1).
##
## Constrói os móveis do jogo diretamente por primitivas geométricas 3D→2D (Iso25DCanvas)
## com micro-animações vivas (pêndulo de relógio oscilando, halo de luz de abajur, dial de
## rádio brilhando, gota d'água caindo na pia) e resposta sinestésica ao som.

const Iso25D := preload("res://scripts/Iso25DCanvas.gd")

const COL_OUTLINE       := Color(0.157, 0.102, 0.078, 0.95)
const COL_OAK_BASE      := Color(0.620, 0.415, 0.235)
const COL_OAK_DARK      := Color(0.455, 0.285, 0.145)
const COL_WALNUT        := Color(0.380, 0.230, 0.130)
const COL_CREAM         := Color(0.975, 0.950, 0.895)
const COL_QUILT_MUSTARD := Color(0.865, 0.655, 0.245)
const COL_QUILT_SAGE    := Color(0.420, 0.595, 0.465)
const COL_PORCELAIN     := Color(0.955, 0.970, 0.985)
const COL_CHROME        := Color(0.760, 0.815, 0.865)
const COL_BRASS_GOLD    := Color(0.885, 0.725, 0.310)
const COL_AMBER_GLOW    := Color(1.000, 0.780, 0.320)

@export var prop_type: String = "radio"
var _time: float = 0.0
var _harmonic_glow_color: Color = Color(1.0, 0.9, 0.5, 0.0)
var _harmonic_glow_intensity: float = 0.0


func setup(p_type: String) -> ProceduralFurniture25D:
	prop_type = p_type
	queue_redraw()
	return self


## Dispara um brilho sinestésico temporário no móvel quando uma nota ou pulso tátil o atinge.
func trigger_harmonic_glow(note_color: Color) -> void:
	_harmonic_glow_color = note_color
	_harmonic_glow_intensity = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _harmonic_glow_intensity > 0.0:
		_harmonic_glow_intensity = maxf(0.0, _harmonic_glow_intensity - delta * 2.2)
	queue_redraw()


func _draw() -> void:
	if _harmonic_glow_intensity > 0.01:
		var glow_col := _harmonic_glow_color
		glow_col.a = 0.28 * _harmonic_glow_intensity
		Iso25D.draw_contact_shadow(self, Vector3.ZERO, 28.0, 14.0, 0.0)
		draw_circle(Vector2(0.0, -10.0), 26.0, glow_col)

	match prop_type:
		"radio":
			_draw_vintage_radio()
		"nightstand", "music_box":
			_draw_nightstand_lamp()
		"bed":
			_draw_cozy_bed()
		"clock":
			_draw_grandfather_clock()
		"sink", "drip":
			_draw_bathroom_sink()
		"toilet":
			_draw_toilet()
		"bathtub":
			_draw_bathtub()
		"armchair":
			_draw_armchair()
		"coffee_table":
			_draw_coffee_table()
		"dresser":
			_draw_dresser()
		_:
			_draw_vintage_radio()


func _draw_vintage_radio() -> void:
	# Mesa de apoio + Rádio valvulado retrô em nogueira com dial iluminado
	Iso25D.draw_iso_box(self, Vector3(-11, -9, 0), Vector3(22, 18, 12), COL_OAK_BASE, COL_OUTLINE)
	# Caixa do rádio em nogueira
	Iso25D.draw_iso_box(self, Vector3(-8, -6, 12), Vector3(16, 12, 13), COL_WALNUT, COL_OUTLINE)
	# Visor âmbar iluminado na face frontal-esquerda (+y)
	var dial_pulse := 0.82 + 0.18 * sin(_time * 4.5)
	var dial_col := COL_AMBER_GLOW.lightened(0.15 * dial_pulse)
	var p_d1 := Iso25D.project(Vector3(-5, 6.2, 22))
	var p_d2 := Iso25D.project(Vector3(2, 6.2, 22))
	var p_d3 := Iso25D.project(Vector3(2, 6.2, 18))
	var p_d4 := Iso25D.project(Vector3(-5, 6.2, 18))
	draw_colored_polygon(PackedVector2Array([p_d1, p_d2, p_d3, p_d4]), dial_col)

	# Grelha do alto-falante e 2 botões giratórios dourados
	var p_k1 := Iso25D.project(Vector3(4.5, 6.3, 20.5))
	var p_k2 := Iso25D.project(Vector3(4.5, 6.3, 16.5))
	draw_circle(p_k1, 1.7, COL_BRASS_GOLD)
	draw_circle(p_k2, 1.7, COL_BRASS_GOLD)

	# Ondas sonoras sutis flutuando acima do rádio
	var wave_t := fposmod(_time * 0.9, 1.0)
	var wave_r := 6.0 + wave_t * 14.0
	var wave_a := (1.0 - wave_t) * 0.45
	draw_arc(Iso25D.project(Vector3(0, 0, 27)), wave_r, -PI * 0.85, -PI * 0.15, 16, Color(1.0, 0.86, 0.42, wave_a), 1.5, true)


func _draw_nightstand_lamp() -> void:
	# Criado-mudo de carvalho com gaveta
	Iso25D.draw_iso_box(self, Vector3(-11, -11, 0), Vector3(22, 22, 18), COL_OAK_BASE, COL_OUTLINE)
	# Puxador dourado na gaveta frontal
	var p_knob := Iso25D.project(Vector3(0, 11.2, 11))
	draw_circle(p_knob, 1.8, COL_BRASS_GOLD)

	# Base de porcelana do abajur + Cúpula creme iluminada
	Iso25D.draw_iso_cylinder(self, Vector3(0, 0, 18), 4.5, 6.0, COL_PORCELAIN, COL_OUTLINE)
	Iso25D.draw_iso_cylinder(self, Vector3(0, 0, 23), 8.2, 8.5, COL_CREAM, COL_OUTLINE)

	# Halo aconchegante de luz quente respirando suavemente
	var glow_a := 0.16 + 0.04 * sin(_time * 2.8)
	var p_lamp := Iso25D.project(Vector3(0, 0, 27))
	draw_circle(p_lamp, 22.0, Color(1.0, 0.88, 0.48, glow_a))


func _draw_cozy_bed() -> void:
	# Estrutura de madeira de carvalho da cama isométrica 2:1
	Iso25D.draw_iso_box(self, Vector3(-24, -16, 0), Vector3(48, 32, 10), COL_OAK_DARK, COL_OUTLINE)
	# Cabeceira alta acolhedora no fundo (-x)
	Iso25D.draw_iso_box(self, Vector3(-24, -16, 10), Vector3(6, 32, 18), COL_OAK_BASE, COL_OUTLINE)
	# Colchão creme macio
	Iso25D.draw_iso_box(self, Vector3(-18, -14, 10), Vector3(40, 28, 6), COL_CREAM, COL_OUTLINE)
	# Colcha mostarda/sálvia cobrindo os 2/3 frontais da cama
	Iso25D.draw_iso_box(self, Vector3(-4, -14.5, 10.5), Vector3(26.5, 29, 6.2), COL_QUILT_MUSTARD, COL_OUTLINE)
	# Travesseiro fofo junto à cabeceira
	Iso25D.draw_iso_box(self, Vector3(-16, -10, 16), Vector3(9, 20, 4.5), Color(0.99, 0.98, 1.0), COL_OUTLINE)


func _draw_grandfather_clock() -> void:
	# Base do relógio de pêndulo em mogno/nogueira
	Iso25D.draw_iso_box(self, Vector3(-9, -9, 0), Vector3(18, 18, 10), COL_WALNUT, COL_OUTLINE)
	# Corpo central com vitrine do pêndulo
	Iso25D.draw_iso_box(self, Vector3(-7.5, -7.5, 10), Vector3(15, 15, 26), COL_OAK_DARK, COL_OUTLINE)

	# Pêndulo dourado oscilando matematicamente em tempo real!
	var pend_swing := sin(_time * PI * 1.5) * 3.2
	var p_top := Iso25D.project(Vector3(7.8, 0.0, 32.0))
	var p_bob := Iso25D.project(Vector3(7.8, pend_swing, 16.0))
	draw_line(p_top, p_bob, COL_BRASS_GOLD, 1.6, true)
	draw_circle(p_bob, 3.0, COL_OUTLINE)
	draw_circle(p_bob, 2.2, COL_BRASS_GOLD)

	# Cabeça superior do relógio + mostrador marfim
	Iso25D.draw_iso_box(self, Vector3(-9, -9, 36), Vector3(18, 18, 16), COL_WALNUT, COL_OUTLINE)
	var p_dial := Iso25D.project(Vector3(9.2, 0.0, 44.0))
	draw_circle(p_dial, 5.2, COL_OUTLINE)
	draw_circle(p_dial, 4.2, COL_CREAM)
	# Ponteiros do relógio
	draw_line(p_dial, p_dial + Vector2(0.0, -3.0), COL_OUTLINE, 1.4, true)
	draw_line(p_dial, p_dial + Vector2(2.4, 0.8), COL_OUTLINE, 1.2, true)


func _draw_bathroom_sink() -> void:
	# Gabinete de banheiro + Cuba de porcelana branca + Espelho e torneira
	Iso25D.draw_iso_box(self, Vector3(-11, -10, 0), Vector3(22, 20, 16), COL_OAK_BASE, COL_OUTLINE)
	Iso25D.draw_iso_box(self, Vector3(-12, -11, 16), Vector3(24, 22, 5), COL_PORCELAIN, COL_OUTLINE)
	# Espelho vertical iluminado ao fundo
	Iso25D.draw_iso_box(self, Vector3(-11, -9, 22), Vector3(3, 18, 22), Color(0.78, 0.91, 0.98), COL_OUTLINE)
	# Torneira cromada
	var p_tap_base := Iso25D.project(Vector3(-6, 0, 21))
	var p_tap_top := Iso25D.project(Vector3(-2, 0, 26))
	draw_line(p_tap_base, p_tap_top, COL_CHROME, 2.4, true)

	# Gota d'água animada ("drip") caindo periodicamente na cuba
	var drip_cycle := fposmod(_time * 1.2, 1.0)
	if drip_cycle < 0.45:
		var drop_z := lerpf(25.0, 20.5, drip_cycle / 0.45)
		var p_drop := Iso25D.project(Vector3(-1, 0, drop_z))
		draw_circle(p_drop, 1.8, Color(0.55, 0.85, 1.0, 0.9))
	else:
		var rip_t := (drip_cycle - 0.45) / 0.55
		var p_basin := Iso25D.project(Vector3(0, 0, 21))
		draw_arc(p_basin, 2.0 + rip_t * 6.0, 0.0, TAU, 14, Color(0.55, 0.85, 1.0, (1.0 - rip_t) * 0.6), 1.2, true)


func _draw_toilet() -> void:
	Iso25D.draw_iso_box(self, Vector3(-9, -7, 0), Vector3(12, 14, 11), COL_PORCELAIN.darkened(0.05), COL_OUTLINE)
	Iso25D.draw_iso_cylinder(self, Vector3(2, 0, 0), 7.5, 12.0, COL_PORCELAIN, COL_OUTLINE)
	Iso25D.draw_iso_box(self, Vector3(-10, -8, 11), Vector3(7, 16, 15), COL_PORCELAIN, COL_OUTLINE)


func _draw_bathtub() -> void:
	Iso25D.draw_iso_box(self, Vector3(-22, -13, 0), Vector3(44, 26, 15), COL_PORCELAIN, COL_OUTLINE)
	Iso25D.draw_iso_box(self, Vector3(-18, -10, 14), Vector3(36, 20, 2), Color(0.68, 0.88, 0.96), COL_OUTLINE, false)


func _draw_armchair() -> void:
	# Poltrona estofada verde-sálvia aconchegante
	Iso25D.draw_iso_box(self, Vector3(-13, -13, 0), Vector3(26, 26, 10), COL_QUILT_SAGE, COL_OUTLINE)
	# Encosto alto macio
	Iso25D.draw_iso_box(self, Vector3(-13, -13, 10), Vector3(7, 26, 14), COL_QUILT_SAGE.lightened(0.06), COL_OUTLINE)
	# Braços laterais
	Iso25D.draw_iso_box(self, Vector3(-6, -13, 10), Vector3(19, 5, 7), COL_QUILT_SAGE.darkened(0.06), COL_OUTLINE)
	Iso25D.draw_iso_box(self, Vector3(-6, 8, 10), Vector3(19, 5, 7), COL_QUILT_SAGE.darkened(0.06), COL_OUTLINE)


func _draw_coffee_table() -> void:
	# Mesa de centro em carvalho com livro e xícara de chá fumegante
	Iso25D.draw_iso_box(self, Vector3(-15, -11, 0), Vector3(30, 22, 10), COL_OAK_BASE, COL_OUTLINE)
	# Livro de capa bordô sobre a mesa
	Iso25D.draw_iso_box(self, Vector3(-8, -4, 10), Vector3(9, 7, 2.2), Color(0.75, 0.22, 0.25), COL_OUTLINE)
	# Xícara de porcelana com vapor suave subindo
	Iso25D.draw_iso_cylinder(self, Vector3(5, 2, 10), 3.0, 3.8, COL_PORCELAIN, COL_OUTLINE)
	var steam_y := sin(_time * 3.0) * 1.5
	var p_cup := Iso25D.project(Vector3(5, 2, 15))
	draw_line(p_cup, p_cup + Vector2(steam_y, -6.0), Color(1.0, 1.0, 1.0, 0.45), 1.4, true)


func _draw_dresser() -> void:
	# Cômoda clássica de madeira com 3 gavetões e puxadores de latão
	Iso25D.draw_iso_box(self, Vector3(-18, -11, 0), Vector3(36, 22, 22), COL_OAK_BASE, COL_OUTLINE)
	Iso25D.draw_iso_box(self, Vector3(-19, -12, 22), Vector3(38, 24, 3), COL_WALNUT, COL_OUTLINE)
	for z_off in [6.0, 12.0, 18.0]:
		var p_handle := Iso25D.project(Vector3(0.0, 11.2, z_off))
		draw_circle(p_handle, 1.6, COL_BRASS_GOLD)
