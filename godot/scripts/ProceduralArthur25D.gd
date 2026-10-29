class_name ProceduralArthur25D
extends Node2D
## Boneco Articulado Procedural 2.5D do Protagonista (Sr. Arthur e Variantes).
##
## Renderizado em tempo real a 60+ FPS com projeção esférica 2.5D exata (câmera isométrica 2:1):
## - Sincronização angular exata: a direção para onde o personagem aponta durante o
##   Scroll de Afinação (modo Cello/fretless) corresponde 100% à direção em que ele de fato caminha!
## - Estilo Luthier Terracota (inspirado nas madeiras de violoncelos e pianos clássicos, zero Natal):
##   * Cardigã terracota quente (#8F4733), lapela e cotoveleiras em nogueira nobre;
##   * Camisa azul chambray suave com gravata borboleta azul-petróleo refinada;
##   * Calças de lã grafite tweed com dobra na barra e sapatos Oxford café;
##   * Bengala tátil longa com virola de latão, grip preto e faixa reflexiva sutil;
##   * Suporte a variantes de personagem: óculos escuros estilo jazz/Ray Charles,
##     olhos fechados com expressão zen de escuta atenta, boina tweed de luthier e
##     arquétipo jovem aprendiz (Clara).

const Iso25D := preload("res://scripts/Iso25DCanvas.gd")

# =========================================================================
# PALETA PADRÃO: "LUTHIER TERRACOTA" (Madeiras de Instrumentos Acústicos)
# =========================================================================
const COL_OUTLINE         := Color(0.140, 0.100, 0.080, 0.96) # #241A14 Espresso escuro
const COL_SKIN_BASE       := Color(0.980, 0.847, 0.737)       # #FAD8BC Pêssego suave
const COL_SKIN_SHADOW     := Color(0.878, 0.722, 0.604)       # #E0B89A Sombra quente da pele
const COL_BLUSH           := Color(0.925, 0.588, 0.550, 0.65) # Bochechas rosadas
const COL_HAIR_WHITE      := Color(0.975, 0.980, 1.000)       # Cabelo branco algodão
const COL_HAIR_SILVER     := Color(0.810, 0.845, 0.900)       # Mechas prata sombreadas
const COL_HAIR_BROWN      := Color(0.380, 0.240, 0.160)       # Cabelo castanho (variante jovem)
const COL_HAIR_BROWN_HI   := Color(0.540, 0.360, 0.240)
const COL_GLASSES_GOLD    := Color(0.860, 0.640, 0.220)       # Armação dourada vintage
const COL_GLASSES_LENS    := Color(0.840, 0.940, 1.000, 0.70) # Lente azulada reflexiva
const COL_GLASSES_SHINE   := Color(1.000, 1.000, 1.000, 0.85) # Brilho especular do vidro

# Cardigã Terracota de Cello + Nogueira Escura
const COL_CARDIGAN        := Color(0.560, 0.280, 0.200)       # #8F4733 Terracota quente de violoncelo
const COL_CARD_SHADOW     := Color(0.420, 0.200, 0.140)       # #6B3324 Sombra terracota
const COL_CARD_HIGHLIGHT  := Color(0.660, 0.360, 0.260)       # #A85C42 Nervura
const COL_CARD_TRIM       := Color(0.320, 0.160, 0.100)       # Nogueira escura / couro nobre
const COL_WATCH_CHAIN     := Color(0.920, 0.760, 0.280)       # Corrente dourada de relógio
const COL_SHIRT_CREAM     := Color(0.820, 0.880, 0.940)       # #D1E0F0 Azul chambray suave
const COL_BOWTIE_RED      := Color(0.160, 0.240, 0.340)       # #293D57 Azul petróleo / marinho refinado
const COL_BUTTON_AMBER    := Color(0.880, 0.700, 0.250)       # Botão de latão com brilho
const COL_PANTS           := Color(0.240, 0.255, 0.290)       # #3D414A Grafite carvão tweed
const COL_PANTS_CUFF      := Color(0.300, 0.320, 0.370)       # Dobra da barra
const COL_SHOE_BROWN      := Color(0.260, 0.150, 0.080)       # Couro café escuro
const COL_SHOE_SOLE       := Color(0.120, 0.070, 0.040)       # Sola de borracha escura
const COL_SHOE_SHINE      := Color(0.520, 0.340, 0.200)       # Brilho na biqueira
const COL_CANE_WHITE      := Color(0.965, 0.975, 0.990)       # Haste refletiva perolada
const COL_CANE_RED        := Color(0.850, 0.200, 0.200)       # Faixa vermelha sutil de sinalização
const COL_CANE_GRIP       := Color(0.160, 0.150, 0.170)       # Empunhadura preta
const COL_CANE_BRASS      := Color(0.860, 0.680, 0.240)       # Virola de latão polido
const COL_FLAT_CAP        := Color(0.440, 0.370, 0.310)       # Boina de lã tweed cáqui/taupe
const COL_FLAT_CAP_SH     := Color(0.320, 0.260, 0.210)

## Estilo de rosto / óculos:
## "dark_shades": Óculos escuros refinados estilo Ray Charles / virtuoso cego
## "closed_eyes": Sem óculos, olhos fechados com expressão zen de escuta atenta
## "round_dark": Óculos escuros redondos vintage com aro fino de bronze
## "vintage_gold": Óculos clássicos de leitura
@export var eyewear_style: String = "dark_shades"

## Estilo de cobertura da cabeça:
## "none": Carequinha iluminada no topo com coroa de cabelo nas laterais/nuca
## "flat_cap": Boina de lã tweed de luthier com aba direcional apontando o movimento
@export var headwear_style: String = "none"

## Modo de montagem do boneco:
## "paper_cutout": Estilo artesanal de colagem de papel/cartolina com sombras de contato e detalhes finos
## "overcoat_indie": Silhueta fluida vetorial com contorno nítido
## "flat_geometric": Minimalista sem contornos
## "classic_cardigan": Montagem anterior de cardigã curto
@export var assembly_mode: String = "paper_cutout"

## Tipo de personagem:
## "arthur": O mestre luthier / afinador sênior
## "apprentice": Clara, a jovem aprendiz afinadora
@export var character_archetype: String = "arthur"

## Item segurado pelo personagem:
## "cane": Bengala tátil longa com ponteira rolante
## "cello": Violoncelo luthier apoiado entre os joelhos com arco de concerto
## "none": Mãos livres
@export var holding_item: String = "cane"

## Ângulo em radianos no espaço de tela (PI/2 = Sul/Frente, 0 = Leste/Direita, -PI/2 = Norte/Costas, PI = Oeste/Esquerda).
var facing_angle: float = PI * 0.5
var target_facing_angle: float = PI * 0.5
var anim_state: String = "idle"
var walk_phase: float = 0.0
var breath_phase: float = 0.0
var jump_elevation: float = 0.0
var cane_tap_flash: float = 0.0
var cane_tap_pos: Vector2 = Vector2.ZERO
var tuning_active: bool = false
var tuning_resonance_color: Color = Color(0.95, 0.82, 0.45, 0.0)
var head_tilt_rad: float = 0.0


# Getters com suporte a override via metadados
func get_cardigan_color() -> Color:
	return get_meta("custom_cardigan") if has_meta("custom_cardigan") else COL_CARDIGAN

func get_cardigan_shadow() -> Color:
	return get_meta("custom_card_sh") if has_meta("custom_card_sh") else COL_CARD_SHADOW

func get_cardigan_highlight() -> Color:
	return get_meta("custom_card_hi") if has_meta("custom_card_hi") else COL_CARD_HIGHLIGHT

func get_trim_color() -> Color:
	return get_meta("custom_trim") if has_meta("custom_trim") else COL_CARD_TRIM

func get_bowtie_color() -> Color:
	return get_meta("custom_bowtie") if has_meta("custom_bowtie") else COL_BOWTIE_RED

func get_pants_color() -> Color:
	return get_meta("custom_pants") if has_meta("custom_pants") else COL_PANTS

func get_pants_cuff_color() -> Color:
	return get_meta("custom_pants_cf") if has_meta("custom_pants_cf") else COL_PANTS_CUFF

func get_shoe_color() -> Color:
	return get_meta("custom_shoe") if has_meta("custom_shoe") else COL_SHOE_BROWN

func get_cane_band_color() -> Color:
	return get_meta("custom_cane_band") if has_meta("custom_cane_band") else COL_CANE_RED

func get_eyewear_style() -> String:
	return get_meta("custom_eyewear") if has_meta("custom_eyewear") else eyewear_style

func get_headwear_style() -> String:
	return get_meta("custom_headwear") if has_meta("custom_headwear") else headwear_style

func get_character_archetype() -> String:
	return get_meta("custom_archetype") if has_meta("custom_archetype") else character_archetype

func get_holding_item() -> String:
	return get_meta("custom_holding_item") if has_meta("custom_holding_item") else holding_item

func get_assembly_mode() -> String:
	return get_meta("custom_assembly") if has_meta("custom_assembly") else assembly_mode

func get_outline_color() -> Color:
	if has_meta("custom_outline"):
		return get_meta("custom_outline")
	var mode := get_assembly_mode()
	if mode == "flat_geometric":
		return Color(0.0, 0.0, 0.0, 0.0)
	elif mode == "paper_cutout":
		return Color(0.16, 0.12, 0.15, 0.28)
	return COL_OUTLINE


# =========================================================================
# SISTEMA DE SINCRONIZAÇÃO ANGULAR 360° (ISOMÉTRICO 2:1 RIGOROSO)
# =========================================================================

static func angle_for_grid_direction(dir: Vector2i) -> float:
	if dir == Vector2i.ZERO:
		return PI * 0.5
	var screen_vec := Vector2(float(dir.x - dir.y) * 32.0, float(dir.x + dir.y) * 16.0)
	return atan2(screen_vec.y, screen_vec.x)


static func angle_for_frequency(freq_hz: float) -> float:
	var nodes := [
		{ "freq": 261.63, "angle": angle_for_grid_direction(Vector2i(-1, -1)) }, # C4: Norte (↑, -90°)
		{ "freq": 277.18, "angle": angle_for_grid_direction(Vector2i( 0, -1)) }, # Cs4: Nordeste (↗, -26.565°)
		{ "freq": 293.66, "angle": angle_for_grid_direction(Vector2i( 1, -1)) }, # D4: Leste (→, 0°)
		{ "freq": 311.13, "angle": angle_for_grid_direction(Vector2i( 1,  0)) }, # Ds4: Sudeste (↘, +26.565°)
		{ "freq": 329.63, "angle": angle_for_grid_direction(Vector2i( 1,  1)) }, # E4: Sul (↓, +90°)
		{ "freq": 349.23, "angle": angle_for_grid_direction(Vector2i( 0,  1)) }, # F4: Sudoeste (↙, +153.435°)
		{ "freq": 369.99, "angle": angle_for_grid_direction(Vector2i(-1,  1)) }, # Fs4: Oeste (←, 180°)
		{ "freq": 392.00, "angle": angle_for_grid_direction(Vector2i(-1,  0)) }, # G4: Noroeste (↖, -153.435°)
		{ "freq": 415.30, "angle": -2.4565 },                                     # Gs4: Norte-Noroeste
		{ "freq": 440.00, "angle": -2.2351 },                                     # A4
		{ "freq": 466.16, "angle": -2.0137 },                                     # As4
		{ "freq": 493.88, "angle": -1.7923 },                                     # B4: Quase Norte
		{ "freq": 523.25, "angle": angle_for_grid_direction(Vector2i(-1, -1)) }, # C5: Norte (↑, fecha 360°)
	]

	if freq_hz <= nodes[0]["freq"]:
		return wrapf(nodes[0]["angle"], -PI, PI)
	if freq_hz >= nodes[nodes.size() - 1]["freq"]:
		return wrapf(nodes[nodes.size() - 1]["angle"], -PI, PI)

	for i in range(nodes.size() - 1):
		var f0: float = nodes[i]["freq"]
		var f1: float = nodes[i + 1]["freq"]
		if freq_hz >= f0 and freq_hz <= f1:
			var t := (freq_hz - f0) / (f1 - f0)
			return wrapf(lerp_angle(nodes[i]["angle"], nodes[i + 1]["angle"], t), -PI, PI)

	return wrapf(nodes[0]["angle"], -PI, PI)


func set_direction(dir: Vector2i, immediate: bool = false) -> void:
	target_facing_angle = angle_for_grid_direction(dir)
	if immediate:
		facing_angle = target_facing_angle
	queue_redraw()


func set_continuous_tuning_angle(angle_rad: float, resonance_col: Color = Color(0.95, 0.82, 0.45, 0.6)) -> void:
	tuning_active = true
	target_facing_angle = angle_rad
	tuning_resonance_color = resonance_col
	head_tilt_rad = 0.16
	queue_redraw()


func clear_continuous_tuning() -> void:
	tuning_active = false
	head_tilt_rad = 0.0
	tuning_resonance_color.a = 0.0
	queue_redraw()


func trigger_cane_tap_spark() -> void:
	cane_tap_flash = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	breath_phase = fposmod(breath_phase + delta * 2.2, TAU)
	facing_angle = lerp_angle(facing_angle, target_facing_angle, clampf(delta * 14.0, 0.0, 1.0))

	if cane_tap_flash > 0.0:
		cane_tap_flash = maxf(0.0, cane_tap_flash - delta * 3.5)

	match anim_state:
		"walk":
			walk_phase = fposmod(walk_phase + delta * 11.0, TAU)
		"run":
			walk_phase = fposmod(walk_phase + delta * 17.0, TAU)
		"trip":
			walk_phase = fposmod(walk_phase + delta * 9.0, TAU)
		_:
			walk_phase = lerpf(walk_phase, 0.0, clampf(delta * 10.0, 0.0, 1.0))

	queue_redraw()


func _char_to_screen(forward_ofs: float, right_ofs: float, z_height: float) -> Vector2:
	var dir_f := Vector2(cos(facing_angle), sin(facing_angle))
	var dir_r := Vector2(-sin(facing_angle), cos(facing_angle))
	var horiz := dir_f * forward_ofs + dir_r * right_ofs
	return Vector2(horiz.x, horiz.y - z_height)


func _char_depth(forward_ofs: float, right_ofs: float, z_bias: float = 0.0) -> float:
	var dir_f := Vector2(cos(facing_angle), sin(facing_angle))
	var dir_r := Vector2(-sin(facing_angle), cos(facing_angle))
	var horiz := dir_f * forward_ofs + dir_r * right_ofs
	return horiz.y + z_bias


# =========================================================================
# RENDERIZAÇÃO GRÁFICA DO BONECO
# =========================================================================

func _draw() -> void:
	var is_moving := anim_state == "walk" or anim_state == "run"
	var stride_amp := 5.2 if anim_state == "walk" else (7.6 if anim_state == "run" else 0.0)
	var lift_amp := 3.4 if anim_state == "walk" else (5.4 if anim_state == "run" else 0.0)

	var bob_z := absf(sin(walk_phase)) * 2.2 if is_moving else sin(breath_phase) * 0.6
	if anim_state == "trip":
		bob_z = -2.5 + sin(walk_phase * 2.0) * 1.5
	bob_z += jump_elevation

	# 0. Mandala harmônica sob os pés durante afinação
	if tuning_active and tuning_resonance_color.a > 0.02:
		_draw_tuning_mandala()

	var s_phase := sin(walk_phase) if is_moving else 0.0
	var lift_l := maxf(0.0, sin(walk_phase)) * lift_amp if is_moving else 0.0
	var lift_r := maxf(0.0, -sin(walk_phase)) * lift_amp if is_moving else 0.0

	# Se estiver nos modos de montagem modernos (overcoat_indie, paper_cutout, flat_geometric), renderiza a silhueta fluida
	if get_assembly_mode() != "classic_cardigan":
		_draw_overcoat_indie_assembly(bob_z, is_moving, s_phase, stride_amp, lift_amp)
		return

	var layers: Array[Dictionary] = []

	# --- 1. PERNAS E SAPATOS ---
	var f_l := s_phase * stride_amp
	var f_r := -s_phase * stride_amp
	layers.append({
		"depth": _char_depth(f_l, -4.2, -6.0),
		"fn": func(): _draw_leg(-4.2, f_l, lift_l + jump_elevation, 11.5 + bob_z)
	})
	layers.append({
		"depth": _char_depth(f_r, 4.2, -6.0),
		"fn": func(): _draw_leg(4.2, f_r, lift_r + jump_elevation, 11.5 + bob_z)
	})

	# --- 2. TRONCO ---
	var torso_z := 17.5 + bob_z
	layers.append({
		"depth": _char_depth(0.0, 0.0, 0.0),
		"fn": func(): _draw_torso_cozy(torso_z)
	})

	# --- 3. BRAÇOS E MÃOS ---
	var arm_swing := -s_phase * 4.2 if is_moving else 0.0
	var hand_l_f := 1.8 + arm_swing
	var hand_r_f := 5.4 - arm_swing * 0.4
	layers.append({
		"depth": _char_depth(hand_l_f, -8.6, 1.0),
		"fn": func(): _draw_arm_cozy(-7.8, -8.6, hand_l_f, torso_z + 4.2, torso_z - 3.0)
	})
	layers.append({
		"depth": _char_depth(hand_r_f, 8.6, 1.0),
		"fn": func(): _draw_arm_cozy(7.8, 8.6, hand_r_f, torso_z + 4.2, torso_z - 2.0)
	})

	# --- 4. BENGALA TÁTIL LONGA ---
	var is_apprentice := get_character_archetype() == "apprentice"
	var cane_sweep_phase := sin(walk_phase * 0.5) * 4.0 if is_moving else 0.0
	var cane_lift := maxf(0.0, cos(walk_phase)) * 2.4 if is_moving else 0.0
	var p_hand_r := _char_to_screen(hand_r_f, 8.6, torso_z - 2.0)
	var p_cane_tip := _char_to_screen(16.0, 9.8 + cane_sweep_phase, cane_lift)
	cane_tap_pos = p_cane_tip
	layers.append({
		"depth": _char_depth(11.5, 9.5, 3.0),
		"fn": func(): _draw_cane_cozy(p_hand_r, p_cane_tip, cane_lift)
	})

	# --- 5. CABEÇA 2.5D REFINADA ---
	var head_z := torso_z + 13.8
	layers.append({
		"depth": 100.0,
		"fn": func(): _draw_head_cozy(head_z)
	})

	layers.sort_custom(func(a, b): return a["depth"] < b["depth"])
	for item in layers:
		item["fn"].call()


func _draw_tuning_mandala() -> void:
	var halo_col := tuning_resonance_color
	halo_col.a = 0.28 + 0.10 * sin(breath_phase * 3.0)
	var pts := PackedVector2Array()
	for i in range(32):
		var a := TAU * float(i) / 32.0
		pts.append(Vector2(cos(a) * 22.0, sin(a) * 11.0))
	draw_colored_polygon(pts, halo_col)
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color(halo_col.r, halo_col.g, halo_col.b, 0.70), 1.5, true)
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var r_inner := 12.0
		var r_outer := 20.0
		draw_line(Vector2(cos(a) * r_inner, sin(a) * r_inner * 0.5),
				  Vector2(cos(a) * r_outer, sin(a) * r_outer * 0.5),
				  Color(halo_col.r, halo_col.g, halo_col.b, 0.50), 1.2, true)
	# Seta harmônica direcional que aponta para o alvo exato na afinação:
	var dir_f := Vector2(cos(facing_angle), sin(facing_angle))
	var p_tip := dir_f * 26.0
	draw_line(Vector2.ZERO, p_tip, Color(halo_col.r, halo_col.g, halo_col.b, 0.90), 2.2, true)
	draw_circle(p_tip, 3.2, Color(halo_col.r, halo_col.g, halo_col.b, 1.0))


## Novo paradigma de montagem: Silhueta estilizada de sobretudo longo e cachecol fluido
func _draw_overcoat_indie_assembly(bob_z: float, is_moving: bool, s_phase: float, stride_amp: float, lift_amp: float) -> void:
	var layers: Array[Dictionary] = []

	var torso_z := 17.5 + bob_z
	var f_l := s_phase * stride_amp
	var f_r := -s_phase * stride_amp
	var lift_l := maxf(0.0, sin(walk_phase)) * lift_amp if is_moving else 0.0
	var lift_r := maxf(0.0, -sin(walk_phase)) * lift_amp if is_moving else 0.0

	# 1. Sapatos Oxford elegantes marchando sob o sobretudo
	layers.append({
		"depth": _char_depth(f_l, -3.8, -6.0),
		"fn": func(): _draw_shoe_under_coat(-3.8, f_l, lift_l + jump_elevation)
	})
	layers.append({
		"depth": _char_depth(f_r, 3.8, -6.0),
		"fn": func(): _draw_shoe_under_coat(3.8, f_r, lift_r + jump_elevation)
	})

	# 2. Saia fluida do sobretudo longo (A-line drape com ondulação física)
	layers.append({
		"depth": _char_depth(0.0, 0.0, -2.0),
		"fn": func(): _draw_overcoat_skirt(torso_z, bob_z, is_moving, s_phase)
	})

	# 3. Tronco, lapela e botões do sobretudo
	layers.append({
		"depth": _char_depth(0.0, 0.0, 0.0),
		"fn": func(): _draw_overcoat_torso(torso_z)
	})

	# 4. Cachecol de concerto aconchegante (Concert Scarf)
	layers.append({
		"depth": _char_depth(2.5, 0.0, 1.5),
		"fn": func(): _draw_concert_scarf(torso_z)
	})

	# 5 & 6. Braços e Instrumento (Bengala tátil ou Violoncelo de Concerto)
	var cur_holding := get_holding_item()
	if cur_holding == "cello":
		# Mão esquerda no espelho do violoncelo (fingerboard)
		var hand_l_f := 6.2
		var hand_l_r := -4.8
		var hand_l_z := torso_z + 2.5
		layers.append({
			"depth": _char_depth(hand_l_f, hand_l_r, hand_l_z),
			"fn": func(): _draw_arm_cozy(-7.8, hand_l_r, hand_l_f, torso_z + 4.2, hand_l_z)
		})

		# O Violoncelo entre os joelhos, apoiado no chão pelo espigão e inclinado contra o peito
		layers.append({
			"depth": _char_depth(7.2, -1.2, torso_z - 1.0),
			"fn": func(): _draw_held_cello(torso_z)
		})

		# Mão direita segurando o arco horizontalmente sobre as cordas
		layers.append({
			"depth": _char_depth(8.5, 7.0, torso_z - 1.0),
			"fn": func(): _draw_held_bow_and_arm(torso_z)
		})
	else:
		# Modo Padrão: Bengala Tátil Longa
		var arm_swing := -s_phase * 3.8 if is_moving else 0.0
		var hand_l_f := 1.6 + arm_swing
		var hand_r_f := 5.2 - arm_swing * 0.4
		layers.append({
			"depth": _char_depth(hand_l_f, -8.6, 1.0),
			"fn": func(): _draw_arm_cozy(-7.8, -8.6, hand_l_f, torso_z + 4.2, torso_z - 3.0)
		})
		layers.append({
			"depth": _char_depth(hand_r_f, 8.6, 1.0),
			"fn": func(): _draw_arm_cozy(7.8, 8.6, hand_r_f, torso_z + 4.2, torso_z - 2.0)
		})

		var cane_sweep_phase := sin(walk_phase * 0.5) * 4.0 if is_moving else 0.0
		var cane_lift := maxf(0.0, cos(walk_phase)) * 2.4 if is_moving else 0.0
		var p_hand_r := _char_to_screen(hand_r_f, 8.6, torso_z - 2.0)
		var p_cane_tip := _char_to_screen(16.0, 9.8 + cane_sweep_phase, cane_lift)
		cane_tap_pos = p_cane_tip
		layers.append({
			"depth": _char_depth(11.5, 9.5, 3.0),
			"fn": func(): _draw_cane_cozy(p_hand_r, p_cane_tip, cane_lift)
		})

	# 7. Cabeça estilizada com boina e sem sobrancelhas
	var head_z := torso_z + 13.8
	layers.append({
		"depth": 100.0,
		"fn": func(): _draw_head_cozy(head_z)
	})

	layers.sort_custom(func(a, b): return a["depth"] < b["depth"])
	for item in layers:
		item["fn"].call()


## Desenha os sapatos de couro surgindo sob a barra do sobretudo
func _draw_shoe_under_coat(right_ofs: float, forward_ofs: float, foot_lift: float) -> void:
	var p_ankle := _char_to_screen(forward_ofs, right_ofs, foot_lift + 2.2)
	var p_toe   := _char_to_screen(forward_ofs + 4.2, right_ofs, foot_lift + 0.6)
	var out_col := get_outline_color()

	# Sola escura
	var p_sole0 := p_ankle + Vector2(0.0, 1.4)
	var p_sole1 := p_toe + Vector2(0.0, 1.4)
	if out_col.a > 0.02:
		draw_line(p_sole0, p_sole1, out_col, 6.8, true)
	draw_line(p_sole0, p_sole1, COL_SHOE_SOLE, 4.8, true)
	# Corpo do sapato de couro
	draw_line(p_ankle, p_toe, get_shoe_color(), 4.4, true)
	draw_circle(p_toe + Vector2(-0.4, -0.6), 1.5, COL_SHOE_SHINE)

	# Detalhes finos: Pesponto de biqueira Cap-Toe e cadarço encerado
	var p_cap := p_ankle.lerp(p_toe, 0.65)
	draw_line(p_cap + Vector2(-0.6, -1.0), p_cap + Vector2(0.6, 1.0), COL_SHOE_SOLE.lightened(0.20), 1.0)
	var p_lace := p_ankle.lerp(p_toe, 0.32)
	draw_line(p_lace + Vector2(-1.0, -0.6), p_lace + Vector2(1.0, 0.6), Color(0.20, 0.14, 0.10), 1.4)
	draw_circle(p_lace, 0.6, Color(0.72, 0.54, 0.20))


## Desenha a saia fluida do sobretudo em formato A com balanço dinâmico de tecido
func _draw_overcoat_skirt(torso_z: float, bob_z: float, is_moving: bool, s_phase: float) -> void:
	var y_waist := -(torso_z - 4.5)
	var y_hem   := -(2.6 + bob_z)
	var w_waist := 8.2
	var w_hem   := 13.5

	# Balanço pendular de tecido nas abas inferiores do sobretudo
	var sway := s_phase * 2.8 if is_moving else sin(breath_phase) * 0.5
	var cx := cos(facing_angle) * 4.8

	var p_w_l := Vector2(-w_waist, y_waist)
	var p_w_r := Vector2(w_waist, y_waist)
	var p_h_r := Vector2(w_hem + sway * 0.4, y_hem)
	var p_h_c := Vector2(cx * 0.5 + sway * 0.8, y_hem + (1.6 if sin(facing_angle) >= -0.2 else -1.2))
	var p_h_l := Vector2(-w_hem + sway * 0.4, y_hem)

	var skirt_poly := PackedVector2Array([p_w_l, p_w_r, p_h_r, p_h_c, p_h_l])

	# Se for paper_cutout, desenha dupla sombra suave de recorte de papel
	if get_assembly_mode() == "paper_cutout":
		var sh_poly1 := PackedVector2Array()
		var sh_poly2 := PackedVector2Array()
		for pt in skirt_poly:
			sh_poly1.append(pt + Vector2(1.2, 1.8))
			sh_poly2.append(pt + Vector2(2.6, 3.6))
		draw_colored_polygon(sh_poly2, Color(0.05, 0.03, 0.07, 0.12))
		draw_colored_polygon(sh_poly1, Color(0.05, 0.03, 0.07, 0.22))

	draw_colored_polygon(skirt_poly, get_cardigan_color())

	# Sombra de profundidade volumétrica no lado direito (afastado da luz clássica 2.5D)
	var shade_poly := PackedVector2Array([
		Vector2(1.5, y_waist),
		p_w_r,
		p_h_r,
		p_h_c,
	])
	draw_colored_polygon(shade_poly, get_cardigan_shadow())

	var out_col := get_outline_color()
	if out_col.a > 0.02:
		draw_polyline(skirt_poly, out_col, 1.5, true)
		draw_line(p_h_l, p_h_c, out_col, 1.5, true)
		draw_line(p_h_c, p_h_r, out_col, 1.5, true)

	if get_assembly_mode() == "paper_cutout":
		draw_polyline(PackedVector2Array([p_h_l, p_w_l, p_w_r]), Color(1.0, 1.0, 1.0, 0.24), 1.2)

	# Detalhes finos: Pesponto de alfaiataria pontilhado na barra
	var stitch_count := 7
	for s in range(stitch_count):
		var frac := float(s) / float(stitch_count - 1)
		var sp := p_h_l.lerp(p_h_r, frac)
		draw_line(sp + Vector2(0.0, -2.0), sp + Vector2(0.0, -1.0), get_cardigan_shadow(), 1.0)

	# Fenda traseira do sobretudo (se estiver virado de costas / Norte)
	if sin(facing_angle) < -0.15:
		var p_waist_c := Vector2(0.0, y_waist)
		if out_col.a > 0.02:
			draw_line(p_waist_c, p_h_c, out_col, 1.8, true)
		draw_line(p_waist_c, p_h_c, get_trim_color(), 1.2, true)
	else:
		# Linha de transpasse frontal do sobretudo
		var p_mid_c := Vector2(cx, y_waist)
		if out_col.a > 0.02:
			draw_line(p_mid_c, p_h_c, out_col, 1.5, true)
		elif get_assembly_mode() == "flat_geometric":
			draw_line(p_mid_c, p_h_c, get_cardigan_shadow(), 1.5, true)


## Desenha a parte superior do sobretudo (ombros confortáveis, lapela e abotoamento duplo)
func _draw_overcoat_torso(torso_z: float) -> void:
	var p_top := Vector2(0.0, -(torso_z + 5.5))
	var p_bot := Vector2(0.0, -(torso_z - 4.8))
	var rx := 8.5
	var ry := 3.8

	var body_poly := PackedVector2Array([
		p_top + Vector2(-rx, 0.0),
		p_top + Vector2(rx, 0.0),
		p_bot + Vector2(rx, 1.2),
		p_bot + Vector2(0.0, ry),
		p_bot + Vector2(-rx, 1.2),
	])

	# Se for paper_cutout, desenha dupla sombra suave de recorte de papel
	if get_assembly_mode() == "paper_cutout":
		var sh_poly1 := PackedVector2Array()
		var sh_poly2 := PackedVector2Array()
		for pt in body_poly:
			sh_poly1.append(pt + Vector2(1.2, 1.6))
			sh_poly2.append(pt + Vector2(2.4, 3.2))
		draw_colored_polygon(sh_poly2, Color(0.05, 0.03, 0.07, 0.12))
		draw_colored_polygon(sh_poly1, Color(0.05, 0.03, 0.07, 0.22))

	draw_colored_polygon(body_poly, get_cardigan_color())

	# Sombra lateral
	var shade_poly := PackedVector2Array([
		p_top + Vector2(1.5, 0.0),
		p_top + Vector2(rx, 0.0),
		p_bot + Vector2(rx, 1.2),
		p_bot + Vector2(1.5, ry * 0.8),
	])
	draw_colored_polygon(shade_poly, get_cardigan_shadow())

	var out_col := get_outline_color()
	if out_col.a > 0.02:
		draw_polyline(PackedVector2Array([
			p_top + Vector2(-rx, 0.0),
			p_bot + Vector2(-rx, 1.2),
			p_bot + Vector2(0.0, ry),
			p_bot + Vector2(rx, 1.2),
			p_top + Vector2(rx, 0.0),
		]), out_col, 1.5, true)
	elif get_assembly_mode() == "paper_cutout":
		draw_polyline(PackedVector2Array([
			p_bot + Vector2(-rx, 1.2),
			p_top + Vector2(-rx, 0.0),
			p_top + Vector2(rx, 0.0),
		]), Color(1.0, 1.0, 1.0, 0.24), 1.2)

	var front_vis := sin(facing_angle)
	if front_vis > -0.25:
		var cx := cos(facing_angle) * 4.8
		var p_neck := Vector2(cx, -(torso_z + 4.8))
		var p_mid  := Vector2(cx, -(torso_z + 0.0))
		var p_hem  := Vector2(cx, -(torso_z - 4.5))

		# 1. Colete interno de luthier (vest) em azul marinho/petróleo nobre sob o sobretudo
		var vest_col := Color(0.18, 0.24, 0.32)
		var vest_poly := PackedVector2Array([
			p_neck + Vector2(-3.4, -0.6),
			p_neck + Vector2(3.4, -0.6),
			p_mid + Vector2(2.0, 0.0),
			p_mid + Vector2(-2.0, 0.0),
		])
		if get_assembly_mode() == "paper_cutout":
			var sh_vest := PackedVector2Array()
			for pt in vest_poly:
				sh_vest.append(pt + Vector2(0.8, 1.2))
			draw_colored_polygon(sh_vest, Color(0.05, 0.03, 0.07, 0.18))
		draw_colored_polygon(vest_poly, vest_col)

		# 3 botõezinhos finos de madrepérola no centro do colete
		for vi in range(3):
			var v_frac := 0.22 + float(vi) * 0.28
			var vp := p_neck.lerp(p_mid, v_frac)
			draw_circle(vp, 0.7, Color(0.95, 0.94, 0.88))
			draw_circle(vp + Vector2(-0.2, -0.2), 0.3, Color(1.0, 1.0, 1.0, 0.9))

		# Correntinha Albert de ouro para relógio de bolso (catenária suave)
		var p_btn_chain := p_neck.lerp(p_mid, 0.50)
		var p_vest_pocket := p_mid + Vector2(-2.8, -1.8)
		var p_chain_curve := p_btn_chain.lerp(p_vest_pocket, 0.5) + Vector2(0.0, 1.6)
		draw_polyline(PackedVector2Array([p_btn_chain, p_chain_curve, p_vest_pocket]), COL_WATCH_CHAIN, 1.1, true)
		draw_circle(p_vest_pocket, 0.8, Color(0.88, 0.72, 0.25))

		# Lenço de bolso de seda branca (pocket square) no bolso superior
		var p_pocket_sq := p_neck + Vector2(3.8, 2.2)
		draw_line(p_pocket_sq + Vector2(-1.2, 0), p_pocket_sq + Vector2(1.2, 0), Color(0.24, 0.14, 0.10), 1.4)
		draw_colored_polygon(PackedVector2Array([
			p_pocket_sq + Vector2(-0.8, 0),
			p_pocket_sq + Vector2(0.0, -1.4),
			p_pocket_sq + Vector2(0.8, 0),
		]), Color(0.96, 0.96, 0.98))

		# 2. Lapela de sobretudo em V com acabamento em nogueira/veludo
		var lapel_l := PackedVector2Array([
			p_neck + Vector2(-4.6, -0.6),
			p_neck + Vector2(-1.2, -0.6),
			p_mid + Vector2(-0.4, 0.0),
			p_mid + Vector2(-3.4, -2.4),
		])
		var lapel_r := PackedVector2Array([
			p_neck + Vector2(1.2, -0.6),
			p_neck + Vector2(4.6, -0.6),
			p_mid + Vector2(3.4, -2.4),
			p_mid + Vector2(0.4, 0.0),
		])
		if get_assembly_mode() == "paper_cutout":
			var sh_ll := PackedVector2Array()
			var sh_lr := PackedVector2Array()
			for pt in lapel_l:
				sh_ll.append(pt + Vector2(0.8, 1.2))
			for pt in lapel_r:
				sh_lr.append(pt + Vector2(0.8, 1.2))
			draw_colored_polygon(sh_ll, Color(0.05, 0.03, 0.07, 0.20))
			draw_colored_polygon(sh_lr, Color(0.05, 0.03, 0.07, 0.20))

		draw_colored_polygon(lapel_l, get_trim_color())
		draw_colored_polygon(lapel_r, get_trim_color())
		if get_assembly_mode() == "paper_cutout":
			draw_polyline(PackedVector2Array([p_neck + Vector2(-4.6, -0.6), p_mid + Vector2(-0.4, 0.0)]), Color(1.0, 1.0, 1.0, 0.24), 1.0)
			draw_polyline(PackedVector2Array([p_neck + Vector2(1.2, -0.6), p_mid + Vector2(3.4, -2.4)]), Color(1.0, 1.0, 1.0, 0.24), 1.0)

		if out_col.a > 0.02:
			draw_polyline(lapel_l, out_col, 1.3, true)
			draw_polyline(lapel_r, out_col, 1.3, true)
			draw_line(p_mid, p_hem, out_col, 1.4, true)
		elif get_assembly_mode() == "flat_geometric":
			draw_line(p_mid, p_hem, get_cardigan_shadow(), 1.4, true)

		# Detalhes finos: Broche / Pin de Diapasão Dourado na lapela esquerda do mestre
		var side_facing := cos(facing_angle)
		var p_pin := p_neck + Vector2(-2.8 if side_facing >= -0.2 else 2.8, 3.4)
		# Cabo do diapasão
		draw_line(p_pin + Vector2(0.0, 1.6), p_pin + Vector2(0.0, 3.8), Color(0.96, 0.82, 0.35), 1.1, true)
		draw_circle(p_pin + Vector2(0.0, 4.2), 0.7, Color(0.96, 0.82, 0.35))
		# Pontas paralelas do diapasão
		draw_line(p_pin + Vector2(-0.9, -1.8), p_pin + Vector2(-0.9, 1.6), Color(0.96, 0.82, 0.35), 1.0, true)
		draw_line(p_pin + Vector2(0.9, -1.8), p_pin + Vector2(0.9, 1.6), Color(0.96, 0.82, 0.35), 1.0, true)
		draw_arc(p_pin + Vector2(0.0, 1.6), 0.9, 0.0, PI, 5, Color(0.96, 0.82, 0.35), 1.0, true)
		draw_circle(p_pin + Vector2(-0.9, -1.5), 0.4, Color(1.0, 1.0, 1.0, 0.85))

		# Botões duplos de latão com aro esculpido
		var b_ratios: Array[float] = [0.25, 0.65]
		for b_ratio in b_ratios:
			var bp := p_mid.lerp(p_hem, b_ratio)
			var b_signs: Array[float] = [-1.0, 1.0]
			for b_sign in b_signs:
				var b_pos := bp + Vector2(b_sign * 2.8, 0.0)
				if out_col.a > 0.02:
					draw_circle(b_pos, 1.5, out_col)
				draw_circle(b_pos, 1.2, COL_BUTTON_AMBER)
				draw_circle(b_pos, 0.8, COL_BUTTON_AMBER.darkened(0.18))
				draw_circle(b_pos + Vector2(-0.3, -0.3), 0.5, Color(1.0, 0.96, 0.75, 0.95))


## Desenha o cachecol de concerto de lã aconchegante em azul chambray
func _draw_concert_scarf(torso_z: float) -> void:
	var out_col := get_outline_color()
	var front_vis := sin(facing_angle)
	if front_vis < -0.35:
		var p_neck_back := Vector2(0.0, -(torso_z + 5.0))
		if out_col.a > 0.02:
			draw_line(p_neck_back + Vector2(-5.5, 0.0), p_neck_back + Vector2(5.5, 0.0), out_col, 4.4, true)
		draw_line(p_neck_back + Vector2(-5.2, 0.0), p_neck_back + Vector2(5.2, 0.0), COL_SHIRT_CREAM, 3.0, true)
		return

	var cx := cos(facing_angle) * 4.8
	var p_collar := Vector2(cx, -(torso_z + 5.0))
	var scarf_col := COL_SHIRT_CREAM

	var neck_pts := PackedVector2Array([
		p_collar + Vector2(-5.6, -1.0),
		p_collar + Vector2(5.6, -1.0),
		p_collar + Vector2(4.8, 2.2),
		p_collar + Vector2(-4.8, 2.2),
	])

	if get_assembly_mode() == "paper_cutout":
		var sh_poly := PackedVector2Array()
		for pt in neck_pts:
			sh_poly.append(pt + Vector2(1.2, 1.6))
		draw_colored_polygon(sh_poly, Color(0.05, 0.03, 0.07, 0.22))

	draw_colored_polygon(neck_pts, scarf_col)
	if out_col.a > 0.02:
		draw_polyline(neck_pts, out_col, 1.4, true)
		draw_line(p_collar + Vector2(-4.8, 2.2), p_collar + Vector2(4.8, 2.2), out_col, 1.4, true)

	var sway_scarf := sin(breath_phase * 1.5) * 0.8
	var p_end1_top := p_collar + Vector2(-1.8, 1.8)
	var p_end1_bot := p_collar + Vector2(-2.5 + sway_scarf, 8.2)
	var p_end2_top := p_collar + Vector2(1.2, 1.8)
	var p_end2_bot := p_collar + Vector2(2.0 + sway_scarf, 10.0)

	if get_assembly_mode() == "paper_cutout":
		draw_line(p_end1_top + Vector2(1.2, 1.6), p_end1_bot + Vector2(1.2, 1.6), Color(0.05, 0.03, 0.07, 0.20), 3.2, true)
		draw_line(p_end2_top + Vector2(1.2, 1.6), p_end2_bot + Vector2(1.2, 1.6), Color(0.05, 0.03, 0.07, 0.20), 3.2, true)

	if out_col.a > 0.02:
		draw_line(p_end1_top, p_end1_bot, out_col, 4.2, true)
	draw_line(p_end1_top, p_end1_bot, scarf_col, 2.8, true)

	if out_col.a > 0.02:
		draw_line(p_end2_top, p_end2_bot, out_col, 4.4, true)
	draw_line(p_end2_top, p_end2_bot, scarf_col.darkened(0.08), 3.0, true)

	# Detalhes finos: Listras discretas de trama e franjas de lã na ponta do cachecol
	var p_stripe1 := p_end1_top.lerp(p_end1_bot, 0.6)
	var p_stripe2 := p_end2_top.lerp(p_end2_bot, 0.6)
	draw_line(p_stripe1 + Vector2(-1.2, 0), p_stripe1 + Vector2(1.2, 0), Color(0.42, 0.52, 0.66), 1.1)
	draw_line(p_stripe2 + Vector2(-1.3, 0), p_stripe2 + Vector2(1.3, 0), Color(0.42, 0.52, 0.66), 1.1)

	# 4 franjas finas em cada ponta do cachecol
	for t in range(4):
		var frac := float(t) / 3.0
		var p_f1 := p_end1_bot + Vector2(lerpf(-1.2, 1.2, frac), 0.0)
		var p_f2 := p_end2_bot + Vector2(lerpf(-1.3, 1.3, frac), 0.0)
		draw_line(p_f1, p_f1 + Vector2(sin(float(t) * 1.2 + breath_phase) * 0.5, 2.2), scarf_col.darkened(0.12), 1.0)
		draw_line(p_f2, p_f2 + Vector2(sin(float(t + 1) * 1.2 + breath_phase) * 0.5, 2.4), scarf_col.darkened(0.20), 1.0)


func _draw_leg(right_ofs: float, forward_ofs: float, foot_z: float, hip_z: float) -> void:
	var p_hip := _char_to_screen(0.0, right_ofs * 0.85, hip_z)
	var p_ankle := _char_to_screen(forward_ofs, right_ofs, foot_z + 2.5)
	var p_toe := _char_to_screen(forward_ofs + 3.8, right_ofs, foot_z + 0.8)
	var out_col := get_outline_color()

	if out_col.a > 0.02:
		draw_line(p_hip, p_ankle, out_col, 7.4, true)
	draw_line(p_hip, p_ankle, get_pants_color(), 5.2, true)
	draw_line(p_ankle + Vector2(-1.6, 0.0), p_ankle + Vector2(1.6, 0.0), get_pants_cuff_color(), 2.2, true)

	var p_sole0 := p_ankle + Vector2(0.0, 1.4)
	var p_sole1 := p_toe + Vector2(0.0, 1.4)
	if out_col.a > 0.02:
		draw_line(p_sole0, p_sole1, out_col, 7.0, true)
	draw_line(p_sole0, p_sole1, COL_SHOE_SOLE, 5.0, true)
	draw_line(p_ankle, p_toe, get_shoe_color(), 4.4, true)
	draw_circle(p_toe + Vector2(-0.4, -0.6), 1.5, COL_SHOE_SHINE)


func _draw_arm_cozy(sh_right: float, hd_right: float, hd_forward: float, sh_z: float, hd_z: float) -> void:
	var p_sh := _char_to_screen(0.0, sh_right, sh_z)
	var p_hd := _char_to_screen(hd_forward, hd_right, hd_z)
	var p_elbow := p_sh.lerp(p_hd, 0.52)
	var p_wrist := p_sh.lerp(p_hd, 0.84)
	var out_col := get_outline_color()

	if get_assembly_mode() == "paper_cutout":
		draw_line(p_sh + Vector2(1.2, 1.8), p_hd + Vector2(1.2, 1.8), Color(0.05, 0.03, 0.07, 0.20), 6.4, true)

	if out_col.a > 0.02:
		draw_line(p_sh, p_hd, out_col, 7.2, true)
	draw_line(p_sh, p_hd, get_cardigan_color(), 5.0, true)
	draw_circle(p_elbow, 2.5, get_trim_color())
	draw_line(p_wrist + Vector2(-1.6, 0.0), p_wrist + Vector2(1.6, 0.0), get_trim_color(), 2.4, true)
	if out_col.a > 0.02:
		draw_circle(p_hd, 3.6, out_col)
	draw_circle(p_hd, 2.7, COL_SKIN_BASE)


func _draw_cane_cozy(p_hand: Vector2, p_tip: Vector2, tip_lift: float) -> void:
	var p_ground := Vector2(p_tip.x, p_tip.y + tip_lift)
	draw_circle(p_ground, 2.8, Color(0.05, 0.03, 0.02, 0.28))

	var p_grip_end := p_hand.lerp(p_tip, 0.20)
	var p_brass    := p_hand.lerp(p_tip, 0.24)
	var p_red0     := p_hand.lerp(p_tip, 0.82)
	var p_red1     := p_hand.lerp(p_tip, 0.90)
	var out_col    := get_outline_color()

	if get_assembly_mode() == "paper_cutout":
		draw_line(p_hand + Vector2(1.0, 1.5), p_tip + Vector2(1.0, 1.5), Color(0.05, 0.03, 0.07, 0.18), 3.0, true)

	if out_col.a > 0.02:
		draw_line(p_hand, p_tip, out_col, 4.2, true)
	draw_line(p_hand, p_tip, COL_CANE_WHITE, 2.6, true)
	# Empunhadura de madeira nobre talhada e virola dourada
	draw_line(p_hand, p_grip_end, Color(0.24, 0.15, 0.10), 3.6, true)
	draw_circle(p_hand, 2.0, Color(0.20, 0.12, 0.08))
	draw_line(p_grip_end, p_brass, Color(0.92, 0.78, 0.32), 3.2, true)
	draw_line(p_red0, p_red1, get_cane_band_color(), 2.8, true)
	if out_col.a > 0.02:
		draw_circle(p_tip, 2.4, out_col)
	draw_circle(p_tip, 1.9, Color(0.96, 0.96, 0.96)) # Ponteira rolante esférica
	draw_circle(p_tip + Vector2(-0.4, -0.4), 0.7, Color(1.0, 1.0, 1.0, 0.8))

	if cane_tap_flash > 0.01:
		var flash_r1 := 9.0 * (1.0 - cane_tap_flash)
		var flash_r2 := 16.0 * (1.0 - cane_tap_flash)
		var flash_alpha := 0.85 * cane_tap_flash
		draw_arc(p_tip, flash_r1, 0.0, TAU, 20, Color(0.40, 0.88, 1.0, flash_alpha), 1.6, true)
		draw_arc(p_tip, flash_r2, 0.0, TAU, 24, Color(0.95, 0.82, 0.45, flash_alpha * 0.6), 1.2, true)
		draw_circle(p_tip, 2.2 * cane_tap_flash, Color(1.0, 1.0, 1.0, flash_alpha))


func _draw_torso_cozy(torso_z: float) -> void:
	var p_top := Vector2(0.0, -(torso_z + 5.5))
	var p_bot := Vector2(0.0, -(torso_z - 6.5))
	var rx := 8.6
	var ry := 4.2

	var body_poly := PackedVector2Array([
		p_top + Vector2(-rx, 0.0),
		p_top + Vector2(rx, 0.0),
		p_bot + Vector2(rx, 1.5),
		p_bot + Vector2(0.0, ry),
		p_bot + Vector2(-rx, 1.5),
	])
	draw_colored_polygon(body_poly, get_cardigan_color())

	var shade_poly := PackedVector2Array([
		p_top + Vector2(1.5, 0.0),
		p_top + Vector2(rx, 0.0),
		p_bot + Vector2(rx, 1.5),
		p_bot + Vector2(1.5, ry * 0.85),
	])
	draw_colored_polygon(shade_poly, get_cardigan_shadow())

	draw_polyline(PackedVector2Array([
		p_top + Vector2(-rx, 0.0),
		p_bot + Vector2(-rx, 1.5),
		p_bot + Vector2(0.0, ry),
		p_bot + Vector2(rx, 1.5),
		p_top + Vector2(rx, 0.0),
	]), COL_OUTLINE, 1.5, true)

	draw_line(p_bot + Vector2(-rx, 1.5), p_bot + Vector2(0.0, ry), get_trim_color(), 1.8, true)
	draw_line(p_bot + Vector2(0.0, ry), p_bot + Vector2(rx, 1.5), get_trim_color(), 1.8, true)

	var front_vis := sin(facing_angle)
	if front_vis > -0.25:
		var cx := cos(facing_angle) * 5.0
		var p_neck := Vector2(cx, -(torso_z + 4.8))
		var p_mid := Vector2(cx, -(torso_z + 0.2))
		var p_hem := Vector2(cx, -(torso_z - 5.8))

		var rib_xs: Array[float] = [-5.2, -2.6, 2.6, 5.2]
		for rib_x in rib_xs:
			var r_top := p_top + Vector2(cx + rib_x, 1.8)
			var r_bot := p_bot + Vector2(cx + rib_x, 1.0)
			draw_line(r_top, r_bot, get_cardigan_highlight(), 1.0, true)

		draw_colored_polygon(PackedVector2Array([
			p_neck + Vector2(-3.4, -0.6),
			p_neck + Vector2(3.4, -0.6),
			p_mid,
		]), COL_SHIRT_CREAM)
		draw_line(p_neck + Vector2(-3.4, -0.6), p_mid, get_trim_color(), 1.8, true)
		draw_line(p_neck + Vector2(3.4, -0.6), p_mid, get_trim_color(), 1.8, true)
		draw_line(p_mid, p_hem, get_trim_color(), 1.8, true)

		var b_ratios: Array[float] = [0.22, 0.52, 0.82]
		for b_ratio in b_ratios:
			var bp := p_mid.lerp(p_hem, b_ratio)
			draw_circle(bp, 1.4, COL_OUTLINE)
			draw_circle(bp, 1.1, COL_BUTTON_AMBER)
			draw_circle(bp + Vector2(-0.3, -0.3), 0.5, Color(1.0, 0.95, 0.7, 0.9))

		var pocket_signs: Array[float] = [-1.0, 1.0]
		for pocket_sign in pocket_signs:
			var px: float = cx + pocket_sign * 5.4
			var py: float = -(torso_z - 2.5)
			draw_line(Vector2(px - 2.0, py), Vector2(px + 2.0, py), get_trim_color(), 2.0, true)
			draw_circle(Vector2(px, py + 1.6), 1.3, get_cardigan_shadow())

		var p_pocket_l := Vector2(cx - 5.4, -(torso_z - 2.5))
		var p_btn2 := p_mid.lerp(p_hem, 0.52)
		var p_chain_mid := p_pocket_l.lerp(p_btn2, 0.5) + Vector2(0.0, 2.2)
		draw_polyline(PackedVector2Array([p_pocket_l, p_chain_mid, p_btn2]), COL_WATCH_CHAIN, 1.2, true)

		var p_bow := p_neck + Vector2(0.0, 1.2)
		var bow_col := get_bowtie_color()
		draw_circle(p_bow + Vector2(-2.2, 0.0), 2.2, COL_OUTLINE)
		draw_circle(p_bow + Vector2(2.2, 0.0), 2.2, COL_OUTLINE)
		draw_circle(p_bow + Vector2(-2.0, 0.0), 1.6, bow_col)
		draw_circle(p_bow + Vector2(2.0, 0.0), 1.6, bow_col)
		draw_circle(p_bow, 1.6, COL_OUTLINE)
		draw_circle(p_bow, 1.2, bow_col.lightened(0.22))


## Renderiza a cabeça com suporte modular a chapéus/boinas, óculos escuros e arquétipos
func _draw_head_cozy(head_z: float) -> void:
	var hc := Vector2(sin(head_tilt_rad) * 2.8, -head_z)
	var R := 9.8
	var out_col := get_outline_color()

	var is_apprentice := get_character_archetype() == "apprentice"
	var cur_eyewear := get_eyewear_style()
	var cur_headwear := get_headwear_style()
	var mode := get_assembly_mode()

	var depth_f := sin(facing_angle)      # 1.0 = frente (Sul), -1.0 = costas (Norte), 0.0 = perfil
	var side_facing := cos(facing_angle)  # 1.0 = perfil leste (olhando p/ direita), -1.0 = perfil oeste
	var abs_side := absf(side_facing)
	var dir_sign := 1.0 if side_facing >= 0.0 else -1.0

	# Sombra suave de recorte de papel da cabeça
	if mode == "paper_cutout":
		draw_circle(hc + Vector2(1.2, 1.8), R + 0.6, Color(0.05, 0.03, 0.07, 0.22))
		draw_circle(hc + Vector2(2.4, 3.2), R + 0.4, Color(0.05, 0.03, 0.07, 0.12))

	var hair_col_base := COL_HAIR_BROWN if is_apprentice else COL_HAIR_SILVER
	var hair_col_hi   := COL_HAIR_BROWN_HI if is_apprentice else COL_HAIR_WHITE
	var hair_col_sh   := hair_col_base.darkened(0.18)

	# =========================================================================
	# 1. ESFERA DA CABEÇA (CRÂNIO BASE)
	# =========================================================================
	var skull_center := hc + Vector2(-side_facing * 0.6, 0.0)
	if out_col.a > 0.02:
		draw_circle(skull_center, R + 1.2, out_col)
	draw_circle(skull_center, R, COL_SKIN_SHADOW)
	draw_circle(skull_center + Vector2(-0.7, -0.8), R * 0.88, COL_SKIN_BASE)

	# Calvície iluminada no topo da cabeça do mestre idoso
	if not is_apprentice and cur_headwear == "none":
		draw_circle(skull_center + Vector2(-1.2, -4.4), R * 0.36, COL_SKIN_BASE.lightened(0.18))
		draw_circle(skull_center + Vector2(-1.6, -4.8), R * 0.16, Color(1.0, 1.0, 1.0, 0.42))

	if mode == "paper_cutout":
		draw_arc(skull_center, R * 0.94, -PI * 0.75, -PI * 0.25, 12, Color(1.0, 1.0, 1.0, 0.26), 1.2)

	# =========================================================================
	# 2. CASO COSTAS (NORTE): COROA DE CABELO NA NUCA E ORELHAS LATERAIS
	# =========================================================================
	if depth_f < -0.25:
		for esign in [-1.0, 1.0]:
			var pe := skull_center + Vector2(esign * (R * 0.92), 1.0)
			if out_col.a > 0.02:
				draw_circle(pe, 2.8, out_col)
			draw_circle(pe, 2.1, COL_SKIN_SHADOW)

		# Faixa de cabelo em ferradura envolvendo toda a nuca (sobreposta à parte de trás do crânio!)
		var back_hair_poly := PackedVector2Array([
			skull_center + Vector2(-R * 0.96, -1.5),
			skull_center + Vector2(-R * 0.65, -0.2),
			skull_center + Vector2(0.0, 0.4),
			skull_center + Vector2(R * 0.65, -0.2),
			skull_center + Vector2(R * 0.96, -1.5),
			skull_center + Vector2(R * 1.02, 2.5),
			skull_center + Vector2(R * 0.72, 6.2),
			skull_center + Vector2(0.0, 7.2),
			skull_center + Vector2(-R * 0.72, 6.2),
			skull_center + Vector2(-R * 1.02, 2.5),
		])
		if mode == "paper_cutout":
			var sh_bh := PackedVector2Array()
			for pt in back_hair_poly:
				sh_bh.append(pt + Vector2(0.8, 1.4))
			draw_colored_polygon(sh_bh, Color(0.05, 0.03, 0.07, 0.22))
		draw_colored_polygon(back_hair_poly, hair_col_base)
		if out_col.a > 0.02:
			draw_polyline(back_hair_poly, out_col, 1.3, true)
		# Mechas verticais prateadas na nuca
		for mx in [-5.5, -2.8, 0.0, 2.8, 5.5]:
			draw_line(skull_center + Vector2(mx, 0.8), skull_center + Vector2(mx * 0.9, 5.8), hair_col_hi, 1.3, true)
		if cur_headwear == "flat_cap":
			_draw_flat_cap(hc, R)
		return

	# =========================================================================
	# 3. CASO PERFIL OU 3/4 (LESTE / OESTE / SUDESTE / SUDOESTE)
	# =========================================================================
	if abs_side > 0.32:
		# A orelha fica no lado posterior da cabeça (atrás do centro do crânio)
		var p_ear := skull_center + Vector2(-dir_sign * 3.8, 1.2)

		# Cabelo da nuca e lateral traseira (entre a orelha e a nuca, cobrindo a parte de trás do crânio)
		var side_hair_poly := PackedVector2Array([
			p_ear + Vector2(dir_sign * 0.8, -4.2),
			skull_center + Vector2(-dir_sign * 4.5, -5.2),
			skull_center + Vector2(-dir_sign * (R * 0.95), -2.5),
			skull_center + Vector2(-dir_sign * (R * 1.02), 1.8),
			skull_center + Vector2(-dir_sign * (R * 0.78), 5.6),
			p_ear + Vector2(-dir_sign * 1.2, 4.8),
			p_ear + Vector2(dir_sign * 1.4, 2.2), # Costeleta na frente da orelha
			p_ear + Vector2(dir_sign * 1.6, -1.8),
		])
		if mode == "paper_cutout":
			var sh_sh := PackedVector2Array()
			for pt in side_hair_poly:
				sh_sh.append(pt + Vector2(0.8, 1.4))
			draw_colored_polygon(sh_sh, Color(0.05, 0.03, 0.07, 0.22))

		draw_colored_polygon(side_hair_poly, hair_col_base)
		# Sombra na parte inferior da nuca e brilho nas mechas superiores
		draw_line(skull_center + Vector2(-dir_sign * 4.0, -3.8), skull_center + Vector2(-dir_sign * 8.2, 0.5), hair_col_hi, 1.8, true)
		draw_line(p_ear + Vector2(dir_sign * 0.6, -3.2), p_ear + Vector2(dir_sign * 1.2, 1.6), hair_col_hi, 1.4, true)
		draw_line(skull_center + Vector2(-dir_sign * 8.6, 2.0), p_ear + Vector2(-dir_sign * 1.0, 4.4), hair_col_sh, 1.8, true)
		if out_col.a > 0.02:
			draw_polyline(side_hair_poly, out_col, 1.3, true)

		# Desenha a Orelha aninhada no cabelo lateral
		if out_col.a > 0.02:
			draw_circle(p_ear, 3.0, out_col)
		draw_circle(p_ear, 2.3, COL_SKIN_BASE)
		draw_circle(p_ear + Vector2(dir_sign * 0.3, 0.3), 1.1, COL_SKIN_SHADOW)

		if cur_headwear == "flat_cap":
			_draw_flat_cap(hc, R)

		# Nariz aquilino discreto na borda frontal do rosto
		var p_nose := skull_center + Vector2(dir_sign * (R * 0.88), 0.8)
		var nose_poly := PackedVector2Array([
			p_nose + Vector2(-dir_sign * 1.8, -2.4),
			p_nose + Vector2(dir_sign * 2.2, 0.4),
			p_nose + Vector2(-dir_sign * 0.6, 1.6),
		])
		draw_colored_polygon(nose_poly, COL_SKIN_BASE)
		if out_col.a > 0.02:
			draw_polyline(nose_poly, out_col, 1.3, true)

		# Óculos Escuros com Haste conectada à Orelha
		var p_lens_center := skull_center + Vector2(dir_sign * 5.6, -1.4)
		if cur_eyewear == "dark_shades":
			# 1. Haste metálica/acetato indo da lente até o topo da orelha
			var p_temple_start := p_lens_center + Vector2(-dir_sign * 1.4, -1.0)
			var p_temple_ear   := p_ear + Vector2(0.0, -1.8)
			draw_line(p_temple_start, p_temple_ear, Color(0.14, 0.12, 0.16), 2.0, true)
			draw_line(p_temple_start, p_temple_ear, Color(0.76, 0.60, 0.25), 1.0, true)

			# 2. Lente frontal (e segunda lente parcial se estiver em 3/4)
			if abs_side < 0.82:
				var p_far_lens := p_lens_center + Vector2(dir_sign * 3.2, -0.2)
				draw_rect(Rect2(p_far_lens - Vector2(1.8, 2.2), Vector2(3.6, 4.4)), Color(0.10, 0.09, 0.12), true)
			var l_rect := Rect2(p_lens_center - Vector2(2.6, 2.4), Vector2(5.2, 4.8))
			if mode == "paper_cutout":
				draw_rect(Rect2(l_rect.position + Vector2(0.8, 1.2), l_rect.size), Color(0.05, 0.03, 0.07, 0.24), true)
			if out_col.a > 0.02:
				draw_rect(l_rect.grow(0.6), out_col, true)
			draw_rect(l_rect, Color(0.11, 0.09, 0.13), true)
			draw_rect(l_rect.grow(-0.6), Color(0.20, 0.20, 0.26), true)
			# Duplo corte de reflexo especular estilizado
			draw_line(p_lens_center + Vector2(-1.4, -1.6), p_lens_center + Vector2(0.4, 1.4), Color(1.0, 1.0, 1.0, 0.75), 1.0, true)
			draw_line(p_lens_center + Vector2(0.8, -1.6), p_lens_center + Vector2(1.8, 0.4), Color(1.0, 1.0, 1.0, 0.45), 0.8, true)
			draw_circle(p_lens_center + Vector2(-dir_sign * 2.2, -1.2), 0.6, Color(0.92, 0.78, 0.32))
		else:
			draw_arc(p_lens_center, 2.0, PI * 0.15, PI * 0.85, 8, COL_SKIN_SHADOW.darkened(0.3), 1.6, true)

		# Bigode de morsa contido e alinhado sob o nariz (com vinco labial de alta separação)
		if not is_apprentice:
			var p_mus_c := skull_center + Vector2(dir_sign * 5.8, 3.0)
			var mus_pts := PackedVector2Array([
				p_mus_c + Vector2(-dir_sign * 3.4, 0.4),
				p_mus_c + Vector2(-dir_sign * 1.0, -1.2),
				p_mus_c + Vector2(dir_sign * 3.0, -0.4),
				p_mus_c + Vector2(dir_sign * 3.4, 1.4),
				p_mus_c + Vector2(0.0, 2.0),
			])
			if mode == "paper_cutout":
				var sh_mp := PackedVector2Array()
				for pt in mus_pts:
					sh_mp.append(pt + Vector2(0.8, 1.2))
				draw_colored_polygon(sh_mp, Color(0.05, 0.03, 0.07, 0.22))

			# Vinco de sombra profunda sob o bigode para separação nítida da boca/pele
			draw_line(p_mus_c + Vector2(-dir_sign * 2.8, 2.0), p_mus_c + Vector2(dir_sign * 3.2, 1.5), Color(0.38, 0.18, 0.10), 1.8, true)

			draw_colored_polygon(mus_pts, Color(0.96, 0.97, 1.0))
			draw_line(p_mus_c + Vector2(-dir_sign * 2.2, 0.0), p_mus_c + Vector2(dir_sign * 2.4, 0.2), Color(1.0, 1.0, 1.0), 1.6, true)

			# Contorno nítido ou vinco separador mesmo no modo stroke-less
			if out_col.a > 0.02:
				draw_polyline(mus_pts, out_col, 1.2, true)
			else:
				# Vinco escuro de oclusão para o Pixelpipe separar o bigode da bochecha/queixo
				draw_line(p_mus_c + Vector2(0.0, 2.0), p_mus_c + Vector2(dir_sign * 3.4, 1.4), Color(0.35, 0.16, 0.10), 1.1, true)
				draw_line(p_mus_c + Vector2(0.0, 2.0), p_mus_c + Vector2(-dir_sign * 3.4, 0.4), Color(0.35, 0.16, 0.10), 1.1, true)
		return

	# =========================================================================
	# 4. CASO FRENTE (SUL): SIMETRIA CLÁSSICA COM COSTELAS NAS TÊMPORAS
	# =========================================================================
	for esign in [-1.0, 1.0]:
		var pe := skull_center + Vector2(esign * 8.8, 1.2)
		if out_col.a > 0.02:
			draw_circle(pe, 2.8, out_col)
		draw_circle(pe, 2.1, COL_SKIN_BASE)
		draw_circle(pe + Vector2(-esign * 0.3, 0.3), 1.1, COL_SKIN_SHADOW)

		# Cabelo lateral contido nas têmporas (acima da orelha)
		var p_temple_top := skull_center + Vector2(esign * 8.2, -2.8)
		var p_temple_bot := skull_center + Vector2(esign * 8.8, 0.6)
		draw_line(p_temple_top, p_temple_bot, hair_col_base, 3.6, true)
		draw_line(p_temple_top + Vector2(-esign * 0.4, 0), p_temple_bot + Vector2(-esign * 0.4, 0), hair_col_hi, 1.6, true)

	if cur_headwear == "flat_cap":
		_draw_flat_cap(hc, R)

	# Óculos Wayfarer Frontais
	var p_eye_l := skull_center + Vector2(-4.4, -1.2)
	var p_eye_r := skull_center + Vector2(4.4, -1.2)
	if cur_eyewear == "dark_shades":
		draw_line(p_eye_l, p_eye_r, Color(0.12, 0.10, 0.14), 2.2, true)
		draw_line(p_eye_l, p_eye_r, Color(0.76, 0.60, 0.25), 1.1, true)
		for pe in [p_eye_l, p_eye_r]:
			var shade_rect := Rect2(pe - Vector2(3.5, 2.4), Vector2(7.0, 4.8))
			if mode == "paper_cutout":
				draw_rect(Rect2(shade_rect.position + Vector2(0.8, 1.2), shade_rect.size), Color(0.05, 0.03, 0.07, 0.24), true)
			if out_col.a > 0.02:
				draw_rect(shade_rect.grow(0.7), out_col, true)
			draw_rect(shade_rect, Color(0.11, 0.09, 0.13), true)
			draw_rect(shade_rect.grow(-0.6), Color(0.20, 0.20, 0.26), true)
			# Duplo corte de reflexo especular de quadrinho/papel recortado:
			draw_line(pe + Vector2(-2.2, -1.4), pe + Vector2(-0.8, 1.4), Color(1.0, 1.0, 1.0, 0.75), 1.0, true)
			draw_line(pe + Vector2(0.2, -1.4), pe + Vector2(1.2, 0.6), Color(1.0, 1.0, 1.0, 0.45), 0.8, true)
			var pin_x: float = -3.2 if pe.x < skull_center.x else 3.2
			draw_circle(pe + Vector2(pin_x, -1.2), 0.6, Color(0.92, 0.78, 0.32))
	else:
		for pe in [p_eye_l, p_eye_r]:
			draw_arc(pe, 2.1, PI * 0.15, PI * 0.85, 8, COL_SKIN_SHADOW.darkened(0.3), 1.6, true)

	# Nariz e Bigode Frontais
	var p_nose_f := skull_center + Vector2(0.0, 1.2)
	draw_circle(p_nose_f, 1.7, COL_SKIN_SHADOW.lightened(0.10))
	draw_circle(p_nose_f + Vector2(-0.3, -0.3), 0.7, COL_SKIN_BASE.lightened(0.22))

	if not is_apprentice:
		var p_mus_f := skull_center + Vector2(0.0, 3.2)
		var mus_f_poly := PackedVector2Array([
			p_mus_f + Vector2(-4.6, 1.2),
			p_mus_f + Vector2(-2.2, -0.8),
			p_mus_f + Vector2(0.0, -0.4),
			p_mus_f + Vector2(2.2, -0.8),
			p_mus_f + Vector2(4.6, 1.2),
			p_mus_f + Vector2(2.0, 1.8),
			p_mus_f + Vector2(0.0, 1.2),
			p_mus_f + Vector2(-2.0, 1.8),
		])
		if mode == "paper_cutout":
			var sh_mf := PackedVector2Array()
			for pt in mus_f_poly:
				sh_mf.append(pt + Vector2(0.8, 1.2))
			draw_colored_polygon(sh_mf, Color(0.05, 0.03, 0.07, 0.22))

		# Sombra labial escura sob o bigode para separação nítida em qualquer resolução
		draw_line(p_mus_f + Vector2(-3.4, 2.0), p_mus_f + Vector2(3.4, 2.0), Color(0.38, 0.18, 0.10), 1.8, true)

		# Bigode prateado brilhante com realce branco puro
		draw_colored_polygon(mus_f_poly, Color(0.96, 0.97, 1.0))
		draw_line(p_mus_f + Vector2(-3.6, 0.3), p_mus_f + Vector2(3.6, 0.3), Color(1.0, 1.0, 1.0), 1.6, true)

		if out_col.a > 0.02:
			draw_polyline(mus_f_poly, out_col, 1.2, true)
		else:
			# Vinco de separação para o Pixelpipe
			draw_line(p_mus_f + Vector2(-4.6, 1.2), p_mus_f + Vector2(-2.0, 1.8), Color(0.35, 0.16, 0.10), 1.1, true)
			draw_line(p_mus_f + Vector2(4.6, 1.2), p_mus_f + Vector2(2.0, 1.8), Color(0.35, 0.16, 0.10), 1.1, true)
			draw_line(p_mus_f + Vector2(-2.0, 1.8), p_mus_f + Vector2(2.0, 1.8), Color(0.35, 0.16, 0.10), 1.1, true)


## Desenha a boina de lã tweed clássica com aba direcional apontando o movimento
func _draw_flat_cap(hc: Vector2, R: float) -> void:
	var cap_center := hc + Vector2(0.0, -R * 0.42)
	var rx := R * 1.06
	var ry := 5.6

	# 1. Copa da boina tweed
	var cap_pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		cap_pts.append(cap_center + Vector2(cos(a) * rx, sin(a) * ry))

	draw_colored_polygon(cap_pts, COL_FLAT_CAP)
	draw_polyline(cap_pts, COL_OUTLINE, 1.4, true)

	# Sombra da copa
	var cap_sh_pts := PackedVector2Array()
	for i in range(12):
		var a := float(i) * PI / 11.0
		cap_sh_pts.append(cap_center + Vector2(cos(a) * rx, sin(a) * ry))
	cap_sh_pts.append(cap_center + Vector2(0.0, ry * 0.2))
	draw_colored_polygon(cap_sh_pts, COL_FLAT_CAP_SH)

	# 2. Aba direcional da boina (aponta para onde o personagem caminha no espaço 2.5D!)
	var dir_f := Vector2(cos(facing_angle), sin(facing_angle))
	var p_visor_base := cap_center + Vector2(dir_f.x * (rx * 0.75), dir_f.y * (ry * 0.75) + 1.2)
	var p_visor_tip  := cap_center + Vector2(dir_f.x * (rx * 1.15), dir_f.y * (ry * 1.15) + 2.2)

	draw_line(p_visor_base, p_visor_tip, COL_OUTLINE, 5.0, true)
	draw_line(p_visor_base, p_visor_tip, COL_FLAT_CAP_SH, 3.4, true)

	# Botãozinho no topo da boina
	draw_circle(cap_center + Vector2(0.0, -ry * 0.3), 1.6, COL_OUTLINE)
	draw_circle(cap_center + Vector2(0.0, -ry * 0.3), 1.2, COL_FLAT_CAP.lightened(0.18))


## Desenha o violoncelo luthier apoiado entre os joelhos do personagem
func _draw_held_cello(torso_z: float) -> void:
	var cx := cos(facing_angle) * 4.8
	var p_center := Vector2(cx - 1.2, -(torso_z - 3.8))
	draw_paper_cutout_cello(self, p_center, -0.16, 1.05, get_assembly_mode(), get_outline_color())


## Desenha o braço direito segurando o arco de concerto apoiado sobre o violoncelo
func _draw_held_bow_and_arm(torso_z: float) -> void:
	var bow_sweep := sin(breath_phase * 2.2) * 2.6 if anim_state != "walk" else 0.0
	var hand_r_f := 7.5 + bow_sweep * 0.35
	var hand_r_r := 6.8 + bow_sweep
	var hand_r_z := torso_z - 1.2

	# 1. Braço direito
	_draw_arm_cozy(7.8, hand_r_r, hand_r_f, torso_z + 4.2, hand_r_z)

	# 2. O Arco de Concerto apoiado sobre as cordas do violoncelo
	var p_frog := _char_to_screen(hand_r_f, hand_r_r, hand_r_z)
	var p_tip  := _char_to_screen(6.2 - bow_sweep * 0.35, -7.8 - bow_sweep * 0.8, torso_z - 2.8)

	var out_col := get_outline_color()
	if get_assembly_mode() == "paper_cutout":
		draw_line(p_frog + Vector2(1.0, 1.5), p_tip + Vector2(1.0, 1.5), Color(0.05, 0.03, 0.07, 0.20), 2.6, true)

	if out_col.a > 0.02:
		draw_line(p_frog, p_tip, out_col, 3.4, true)
	# Vareta de pau-brasil envergada
	draw_line(p_frog, p_tip, Color(0.46, 0.20, 0.12), 2.0, true)
	# Crina de cavalo branca/creme tensionada sob a vareta
	draw_line(p_frog + Vector2(0.0, 1.2), p_tip + Vector2(0.0, 1.0), Color(0.96, 0.95, 0.90), 1.2, true)
	# Talão de ébano com olho de madrepérola
	draw_circle(p_frog, 1.6, Color(0.12, 0.10, 0.14))
	draw_circle(p_frog, 0.6, Color(0.85, 0.90, 0.98))
	draw_circle(p_frog + Vector2(0.8, -0.6), 0.7, Color(0.92, 0.78, 0.30))


## Renderizador Procedural de Violoncelo de Concerto (Estilo Luthier Artesanal).
## Pode ser usado tanto pelo boneco segurando quanto em estantes/marcos acústicos.
static func draw_paper_cutout_cello(ci: CanvasItem, origin: Vector2, tilt_angle: float, scale_f: float, mode: String, out_col: Color) -> void:
	var rot := func(pt: Vector2) -> Vector2:
		return origin + pt.rotated(tilt_angle) * scale_f

	# 1. Espigão de Metal (Endpin) apoiado no piso
	var p_end_b: Vector2 = rot.call(Vector2(0.0, 23.5))
	var p_end_g: Vector2 = rot.call(Vector2(0.0, 36.0))
	ci.draw_circle(p_end_g + Vector2(1.2, 1.8), 2.4, Color(0.05, 0.03, 0.07, 0.28))
	ci.draw_line(p_end_b, p_end_g, Color(0.78, 0.82, 0.88), 1.8 * scale_f, true)
	ci.draw_line(p_end_b, (rot.call(Vector2(0.0, 26.5)) as Vector2), Color(0.92, 0.78, 0.30), 2.4 * scale_f, true)
	ci.draw_circle(p_end_g, 1.4 * scale_f, Color(0.12, 0.10, 0.14))

	# 2. Caixa Harmônica do Violoncelo (Contorno em 8 com 4 cantos pontiagudos de luthier)
	var body_raw: Array[Vector2] = [
		Vector2(0.0, -14.0),
		Vector2(-9.0, -11.0),
		Vector2(-11.5, -6.0),
		Vector2(-9.5, -2.0),
		Vector2(-7.2, 2.0),
		Vector2(-10.2, 6.0),
		Vector2(-13.5, 12.0),
		Vector2(-7.0, 22.0),
		Vector2(0.0, 23.5),
		Vector2(7.0, 22.0),
		Vector2(13.5, 12.0),
		Vector2(10.2, 6.0),
		Vector2(7.2, 2.0),
		Vector2(9.5, -2.0),
		Vector2(11.5, -6.0),
		Vector2(9.0, -11.0),
	]
	var body_poly := PackedVector2Array()
	for pt in body_raw:
		body_poly.append(rot.call(pt))

	# Dupla sombra suave de cartolina
	if mode == "paper_cutout":
		var sh_poly1 := PackedVector2Array()
		var sh_poly2 := PackedVector2Array()
		for pt in body_poly:
			sh_poly1.append(pt + Vector2(1.4, 2.0))
			sh_poly2.append(pt + Vector2(2.8, 3.8))
		ci.draw_colored_polygon(sh_poly2, Color(0.05, 0.03, 0.07, 0.14))
		ci.draw_colored_polygon(sh_poly1, Color(0.05, 0.03, 0.07, 0.24))

	# Tampo em Abeto Dourado Luminoso / Mel Acústico (Alto contraste com o casaco terracota)
	ci.draw_colored_polygon(body_poly, Color(0.92, 0.62, 0.22))

	# Realce de luz no lobo superior e esquerdo
	var hi_raw: Array[Vector2] = [
		Vector2(0.0, -14.0),
		Vector2(-9.0, -11.0),
		Vector2(-11.5, -6.0),
		Vector2(-9.5, -2.0),
		Vector2(-7.2, 2.0),
		Vector2(0.0, 2.0),
	]
	var hi_poly := PackedVector2Array()
	for pt in hi_raw:
		hi_poly.append(rot.call(pt))
	ci.draw_colored_polygon(hi_poly, Color(0.98, 0.76, 0.38))

	# Sombra volumétrica lateral nas ilhargas (faixas de bordo e nogueira nobre à direita)
	var shade_raw: Array[Vector2] = [
		Vector2(0.0, -14.0),
		Vector2(9.0, -11.0),
		Vector2(11.5, -6.0),
		Vector2(9.5, -2.0),
		Vector2(7.2, 2.0),
		Vector2(10.2, 6.0),
		Vector2(13.5, 12.0),
		Vector2(7.0, 22.0),
		Vector2(0.0, 23.5),
	]
	var shade_poly := PackedVector2Array()
	for pt in shade_raw:
		shade_poly.append(rot.call(pt))
	ci.draw_colored_polygon(shade_poly, Color(0.55, 0.26, 0.09))

	# Filetagem de Luthier (Purfling) — friso duplo entalhado
	var purf_raw := PackedVector2Array()
	for pt in body_raw:
		purf_raw.append(rot.call(pt * 0.88))
	ci.draw_polyline(purf_raw, Color(0.24, 0.12, 0.06, 0.75), 1.0 * scale_f, true)

	# Borda de encordoamento / Friso de separação perimetral escuro em ébano
	# (Garante 100% de separação ótica entre o violoncelo e o sobretudo terracota em qualquer resolução!)
	ci.draw_polyline(body_poly, Color(0.20, 0.09, 0.05), 1.3 * scale_f, true)

	if out_col.a > 0.02:
		ci.draw_polyline(body_poly, out_col, 1.4 * scale_f, true)
	elif mode == "paper_cutout":
		# Borda de luz de corte de cartolina no topo e esquerda
		var rim_pts := PackedVector2Array()
		for i in range(8):
			rim_pts.append(body_poly[i])
		ci.draw_polyline(rim_pts, Color(1.0, 1.0, 1.0, 0.28), 1.2 * scale_f)

	# 3. Aberturas Acústicas em "ff" (F-Holes vazados com sombra interna)
	for f_side in [-1.0, 1.0]:
		var f_c: Vector2 = rot.call(Vector2(f_side * 5.8, 4.0))
		var f_top: Vector2 = rot.call(Vector2(f_side * 5.2, -1.5))
		var f_bot: Vector2 = rot.call(Vector2(f_side * 5.5, 8.5))
		ci.draw_line(f_top, f_bot, Color(0.12, 0.08, 0.06), 1.8 * scale_f, true)
		ci.draw_circle(f_top, 1.2 * scale_f, Color(0.12, 0.08, 0.06))
		ci.draw_circle(f_bot, 1.4 * scale_f, Color(0.12, 0.08, 0.06))
		# Entalhe central do corte do "f"
		ci.draw_line(f_c, (rot.call(Vector2(f_side * 7.0, 4.0)) as Vector2), Color(0.12, 0.08, 0.06), 1.1 * scale_f, true)

	# 4. Estandarte (Tailpiece) em ébano triangular com micro-afinadores de ouro
	var tp_poly := PackedVector2Array([
		(rot.call(Vector2(-2.4, 8.5)) as Vector2),
		(rot.call(Vector2(2.4, 8.5)) as Vector2),
		(rot.call(Vector2(1.2, 19.5)) as Vector2),
		(rot.call(Vector2(-1.2, 19.5)) as Vector2),
	])
	ci.draw_colored_polygon(tp_poly, Color(0.14, 0.12, 0.16))
	if out_col.a > 0.02:
		ci.draw_polyline(tp_poly, out_col, 1.0 * scale_f, true)
	for mi in range(4):
		var frac := float(mi) / 3.0
		var mp: Vector2 = rot.call(Vector2(lerpf(-1.8, 1.8, frac), 10.0))
		ci.draw_circle(mp, 0.6 * scale_f, Color(0.92, 0.78, 0.30))

	# 5. Cavalete (Bridge) de bordo esculpido
	var p_br0: Vector2 = rot.call(Vector2(-4.2, 3.5))
	var p_br1: Vector2 = rot.call(Vector2(4.2, 3.5))
	ci.draw_line(p_br0, p_br1, Color(0.92, 0.84, 0.72), 2.2 * scale_f, true)
	ci.draw_circle((rot.call(Vector2(0.0, 3.2)) as Vector2), 1.0 * scale_f, Color(0.82, 0.72, 0.58))

	# 6. Espelho (Fingerboard) e Braço de Ébano subindo até o topo
	var fb_poly := PackedVector2Array([
		(rot.call(Vector2(-2.0, 2.5)) as Vector2),
		(rot.call(Vector2(2.0, 2.5)) as Vector2),
		(rot.call(Vector2(1.4, -26.0)) as Vector2),
		(rot.call(Vector2(-1.4, -26.0)) as Vector2),
	])
	if mode == "paper_cutout":
		var sh_fb := PackedVector2Array()
		for pt in fb_poly:
			sh_fb.append(pt + Vector2(0.6, 1.0))
		ci.draw_colored_polygon(sh_fb, Color(0.05, 0.03, 0.07, 0.25))
	ci.draw_colored_polygon(fb_poly, Color(0.12, 0.10, 0.14))
	if out_col.a > 0.02:
		ci.draw_polyline(fb_poly, out_col, 1.0 * scale_f, true)

	# 7. Caixa de Cravelhas e Voluta Esculpida (Pegbox & Scroll)
	var p_nut: Vector2 = rot.call(Vector2(0.0, -26.0))
	var p_scroll: Vector2 = rot.call(Vector2(0.0, -36.0))
	ci.draw_line(p_nut, p_scroll, Color(0.50, 0.24, 0.10), 3.4 * scale_f, true)
	# 4 Cravelhas de afinação laterais em ébano
	for pi in range(4):
		var py := -28.0 - float(pi) * 2.2
		var peg_dir := -1.0 if pi % 2 == 0 else 1.0
		var peg0: Vector2 = rot.call(Vector2(0.0, py))
		var peg1: Vector2 = rot.call(Vector2(peg_dir * 5.2, py))
		ci.draw_line(peg0, peg1, Color(0.16, 0.14, 0.18), 1.2 * scale_f, true)
		ci.draw_circle(peg1, 1.1 * scale_f, Color(0.14, 0.12, 0.16))
	# Voluta em espiral (Scroll)
	ci.draw_circle(p_scroll, 2.4 * scale_f, Color(0.72, 0.38, 0.17))
	ci.draw_arc(p_scroll, 1.8 * scale_f, -PI * 0.8, PI * 0.6, 8, Color(0.38, 0.18, 0.08), 1.2 * scale_f)

	# 8. As 4 Cordas de Prata / Aço (C, G, D, A)
	for si in range(4):
		var frac := float(si) / 3.0
		var str_tail: Vector2 = rot.call(Vector2(lerpf(-1.8, 1.8, frac), 9.5))
		var str_bridge: Vector2 = rot.call(Vector2(lerpf(-3.2, 3.2, frac), 3.2))
		var str_nut: Vector2 = rot.call(Vector2(lerpf(-1.0, 1.0, frac), -26.0))
		var str_col := Color(0.92, 0.94, 0.98, 0.85) if si >= 2 else Color(0.82, 0.85, 0.90, 0.75)
		ci.draw_line(str_tail, str_bridge, str_col, 1.0 * scale_f)
		ci.draw_line(str_bridge, str_nut, str_col, 1.0 * scale_f)
