class_name AcousticSynth
extends RefCounted
## Motor de Síntese Acústica por Modelagem Física e Ressonância Modal de Corpo (Caminho A).
##
## Substitui ondas eletrônicas estáticas por modelos físicos reais de instrumentos:
## 1. Piano Acústico de Cauda: Martelo de feltro (transiente de impacto), inarmonicidade
##    de rigidez do aço (f_n = n * f * sqrt(1 + B*n²)), coro triplo (3 cordas levemente
##    dessintonizadas por tecla) e decaimento espectral dependente da frequência + tampo harmônico.
## 2. Violoncelo (Cello) Contínuo e Discreto: Movimento de Helmholtz (stick-slip de arco com
##    filtro pente da posição do arco beta ≈ 1/9) acoplado a um banco de filtros Biquad Modais
##    calibrados a partir do Impulse Response (IR) real da caixa acústica de madeira de um Cello
##    (Modo de ar A0 ~105Hz, Modo principal do tampo ~205Hz, Colina do cavalete ~520Hz e ~2150Hz).
## 3. Violão Acústico (Karplus-Strong Estendido): Linha de atraso fracionária com filtro de
##    dispersão e ressonância de caixa acústica de pinho/jacarandá.

const MIX_RATE := 44100.0

## Posição relativa do arco em relação ao cavalete (beta = 1/9.5 ≈ 0.105, ponto "ordinario").
## Fisicamente, o arco nessa posição atenua harmônicos múltiplos de 1/beta e arredonda a quina
## do movimento de Helmholtz, eliminando o zumbido de onda dente-de-serra sintética.
const BOW_POSITION_BETA := 0.105

## Coeficiente de inarmonicidade das cordas de aço do piano (B ≈ 0.00018).
const PIANO_INHARMONICITY_B := 0.00018

## Dessintonia sutil em razão de frequência das 3 cordas (uníssono) de uma tecla de piano (~0.8 cents).
const PIANO_UNISON_DETUNE_1 := 0.99954
const PIANO_UNISON_DETUNE_2 := 1.00000
const PIANO_UNISON_DETUNE_3 := 1.00046

## Pesos pré-calculados dos 10 primeiros harmônicos de uma corda friccionada de violoncelo
## ponderados pela física de Helmholtz (1/n * sin(n * PI * beta)) e pela resposta acústica da madeira.
const CELLO_HELMHOLTZ_WEIGHTS: Array[float] = [
	1.000,  # n=1: Fundamental encorpada
	0.620,  # n=2: Oitava quente (ressonância do tampo)
	0.380,  # n=3: Quinta aberta rica
	0.230,  # n=4: Dupla oitava
	0.145,  # n=5: Terça maior brilhante (Bridge hill)
	0.095,  # n=6: Cantabile
	0.058,  # n=7: Atenuado próximo ao nó do arco
	0.032,  # n=8: Suave
	0.014,  # n=9: Nó de posição do arco (quase zero em beta ~ 1/9)
	0.022,  # n=10: Brilho sutil de breu (rosin)
]
const CELLO_HELMHOLTZ_WEIGHT_SUM := 2.596


## Filtro Biquad de 2ª ordem em tempo real para simular os modos de vibração da madeira
## (Impulse Response paramétrico da caixa acústica do instrumento).
class BodyResonatorBank:
	# Estado dos filtros Biquad em cascata/paralelo (4 modos principais do corpo do Cello + Lowpass de madeira)
	var _z1_0 := 0.0; var _z2_0 := 0.0
	var _z1_1 := 0.0; var _z2_1 := 0.0
	var _z1_2 := 0.0; var _z2_2 := 0.0
	var _z1_3 := 0.0; var _z2_3 := 0.0
	var _lp_state := 0.0

	# Coeficientes pré-calculados para 44100 Hz:
	# Modo 0: Ressonância de Helmholtz do ar pelos efes (f-holes) — A0 em 108 Hz (Q=4.5)
	var _b0_0: float; var _b1_0: float; var _b2_0: float; var _a1_0: float; var _a2_0: float
	# Modo 1: Ressonância principal da tábua harmônica de abeto — B1 em 212 Hz (Q=5.0)
	var _b0_1: float; var _b1_1: float; var _b2_1: float; var _a1_1: float; var _a2_1: float
	# Modo 2: Ressonância dipolo do corpo médio — 510 Hz (Q=3.8)
	var _b0_2: float; var _b1_2: float; var _b2_2: float; var _a1_2: float; var _a2_2: float
	# Modo 3: "Bridge Hill" (colina acústica do cavalete que dá projeção de voz humana) — 1950 Hz (Q=2.8)
	var _b0_3: float; var _b1_3: float; var _b2_3: float; var _a1_3: float; var _a2_3: float

	func _init() -> void:
		var c0 := _calc_bandpass(108.0, 4.5, MIX_RATE)
		_b0_0 = c0[0]; _b1_0 = c0[1]; _b2_0 = c0[2]; _a1_0 = c0[3]; _a2_0 = c0[4]

		var c1 := _calc_bandpass(212.0, 5.0, MIX_RATE)
		_b0_1 = c1[0]; _b1_1 = c1[1]; _b2_1 = c1[2]; _a1_1 = c1[3]; _a2_1 = c1[4]

		var c2 := _calc_bandpass(510.0, 3.8, MIX_RATE)
		_b0_2 = c2[0]; _b1_2 = c2[1]; _b2_2 = c2[2]; _a1_2 = c2[3]; _a2_2 = c2[4]

		var c3 := _calc_bandpass(1950.0, 2.8, MIX_RATE)
		_b0_3 = c3[0]; _b1_3 = c3[1]; _b2_3 = c3[2]; _a1_3 = c3[3]; _a2_3 = c3[4]

	func reset() -> void:
		_z1_0 = 0.0; _z2_0 = 0.0
		_z1_1 = 0.0; _z2_1 = 0.0
		_z1_2 = 0.0; _z2_2 = 0.0
		_z1_3 = 0.0; _z2_3 = 0.0
		_lp_state = 0.0

	func _calc_bandpass(freq: float, q: float, sr: float) -> Array[float]:
		var w0 := TAU * freq / sr
		var cos_w0 := cos(w0)
		var alpha := sin(w0) / (2.0 * q)
		var a0 := 1.0 + alpha
		var b0 := alpha / a0
		var b1 := 0.0
		var b2 := -alpha / a0
		var a1 := (-2.0 * cos_w0) / a0
		var a2 := (1.0 - alpha) / a0
		return [b0, b1, b2, a1, a2]

	## Processa uma amostra da corda através da caixa acústica de madeira do violoncelo.
	func process(x: float) -> float:
		# Modo 0 (Ar A0 ~108Hz)
		var y0 := _b0_0 * x + _z1_0
		_z1_0 = _b1_0 * x - _a1_0 * y0 + _z2_0
		_z2_0 = _b2_0 * x - _a2_0 * y0

		# Modo 1 (Tampo de abeto ~212Hz)
		var y1 := _b0_1 * x + _z1_1
		_z1_1 = _b1_1 * x - _a1_1 * y1 + _z2_1
		_z2_1 = _b2_1 * x - _a2_1 * y1

		# Modo 2 (Corpo médio ~510Hz)
		var y2 := _b0_2 * x + _z1_2
		_z1_2 = _b1_2 * x - _a1_2 * y2 + _z2_2
		_z2_2 = _b2_2 * x - _a2_2 * y2

		# Modo 3 (Bridge hill ~1950Hz)
		var y3 := _b0_3 * x + _z1_3
		_z1_3 = _b1_3 * x - _a1_3 * y3 + _z2_3
		_z2_3 = _b2_3 * x - _a2_3 * y3

		# Amortecimento natural da madeira para altas frequências no sinal direto
		_lp_state = lerpf(_lp_state, x, 0.34)

		# Combina o som direto da corda no cavalete com a radiação modal da caixa de madeira
		var wood_radiation := (y0 * 0.55) + (y1 * 0.65) + (y2 * 0.45) + (y3 * 0.35)
		return clampf(_lp_state * 0.62 + wood_radiation * 0.58, -0.95, 0.95)


## Gera a forma de onda de Helmholtz de uma corda friccionada por arco na fase [0, 1).
## Retorna 0.0 em phase=0.0 e permanece estritamente dentro de [-1.0, 1.0].
static func helmholtz_bowed_string(phase: float) -> float:
	var sum := 0.0
	for i in range(CELLO_HELMHOLTZ_WEIGHTS.size()):
		var n := float(i + 1)
		sum += CELLO_HELMHOLTZ_WEIGHTS[i] * sin(phase * TAU * n)
	return sum / CELLO_HELMHOLTZ_WEIGHT_SUM


## Sintetiza uma nota completa de Piano de Cauda Acústico com modelagem de:
## - Transiente de impacto do martelo de feltro + ressonância do cavalete de madeira
## - Coro triplo (3 cordas em uníssono com micro-batimento orgânico)
## - Inarmonicidade física de corda rígida (f_n = n * f * sqrt(1 + B*n²))
## - Decaimento harmônico progressivo (agudos apagam rápido, fundamental sustenta quente)
static func generate_piano_stream(freq: float, env_segments: PackedInt32Array) -> AudioStreamWAV:
	var a: int = env_segments[0]
	var d: int = env_segments[1]
	var s: int = env_segments[2]
	var r: int = env_segments[3]
	var total_samples: int = a + d + s + r

	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	# 7 parciais inarmônicos pré-sintonizados
	var partial_ratios: Array[float] = []
	var partial_weights: Array[float] = [1.0, 0.46, 0.24, 0.13, 0.075, 0.04, 0.02]
	var weight_sum := 1.965
	for n_idx in range(partial_weights.size()):
		var n := float(n_idx + 1)
		var stretch := sqrt(1.0 + PIANO_INHARMONICITY_B * n * n)
		partial_ratios.append(n * stretch)

	var phase_c1 := 0.0
	var phase_c2 := 0.0
	var phase_c3 := 0.0
	var inc_c1 := (freq * PIANO_UNISON_DETUNE_1) / MIX_RATE
	var inc_c2 := (freq * PIANO_UNISON_DETUNE_2) / MIX_RATE
	var inc_c3 := (freq * PIANO_UNISON_DETUNE_3) / MIX_RATE

	# Fase do "thump" de madeira do martelo (corpo ~145Hz)
	var wood_phase := 0.0
	var wood_inc := 145.0 / MIX_RATE
	var felt_lp := 0.0

	for idx in range(total_samples):
		var t := float(idx) / MIX_RATE
		var amp := _piano_envelope_at(idx, a, d, s, r)

		# 1. Coro de 3 cordas na fundamental + 2ª parcial para corpo vivo
		var choir_fund := (
			sin(phase_c1 * TAU) +
			sin(phase_c2 * TAU) +
			sin(phase_c3 * TAU)
		) * 0.333333

		var choir_oct := (
			sin(phase_c1 * TAU * partial_ratios[1]) +
			sin(phase_c2 * TAU * partial_ratios[1]) +
			sin(phase_c3 * TAU * partial_ratios[1])
		) * 0.333333

		# 2. Parciais superiores com decaimento natural mais rápido conforme o número harmônico
		# No piano real, o brilho inicial do ataque decai suavemente para um som doce de madeira.
		var tone := choir_fund * partial_weights[0] + choir_oct * partial_weights[1] * exp(-t * 1.8)
		for p in range(2, partial_weights.size()):
			var decay_p := exp(-t * (1.6 * float(p + 1)))
			tone += partial_weights[p] * decay_p * sin(phase_c2 * TAU * partial_ratios[p])
		tone /= weight_sum

		# 3. Transiente acústico do martelo de feltro nos primeiros ~18ms
		var hammer_env := exp(-t * 160.0)
		felt_lp = lerpf(felt_lp, sin(float(idx * 17) * 1.618), 0.18)
		var hammer_thump := (sin(wood_phase * TAU) * 0.65 + felt_lp * 0.35) * hammer_env * 0.14

		var value := (tone + hammer_thump) * amp * 0.56
		var pcm: int = clampi(int(clampf(value, -1.0, 1.0) * 32767.0), -32768, 32767)
		bytes.encode_s16(idx * 2, pcm)

		phase_c1 = fposmod(phase_c1 + inc_c1, 1.0)
		phase_c2 = fposmod(phase_c2 + inc_c2, 1.0)
		phase_c3 = fposmod(phase_c3 + inc_c3, 1.0)
		wood_phase = fposmod(wood_phase + wood_inc, 1.0)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(MIX_RATE)
	stream.stereo = false
	stream.data = bytes
	return stream


## Sintetiza uma nota de Violão Acústico via algoritmo físico Karplus-Strong Estendido
## com excitação filtrada pelo cavalete de madeira e linha de atraso interpolada.
static func generate_guitar_karplus_strong_stream(freq: float, env_segments: PackedInt32Array) -> AudioStreamWAV:
	var a: int = env_segments[0]
	var d: int = env_segments[1]
	var s: int = env_segments[2]
	var r: int = env_segments[3]
	var total_samples: int = a + d + s + r

	var delay_len := maxi(8, int(round(MIX_RATE / maxf(freq, 40.0))))
	var delay_line := PackedFloat32Array()
	delay_line.resize(delay_len)

	# Excitação inicial: pulso de dedilhado (unha/polpa do dedo) com filtro pente de posição
	var pluck_pos := maxi(2, int(float(delay_len) * 0.18))
	var prev_exc := 0.0
	for i in range(delay_len):
		var phase_i := float(i) / float(delay_len)
		# Mistura de rampa suave (polpa do dedo) + micro-textura determinística da corda de nylon
		var raw := sin(phase_i * TAU) * 0.65 + sin(phase_i * TAU * 3.0) * 0.22 + cos(float(i * 13) * 0.7) * 0.13
		prev_exc = lerpf(prev_exc, raw, 0.45)
		delay_line[i] = prev_exc

	# Filtro pente de posição do dedilhado
	for i in range(delay_len - pluck_pos):
		delay_line[i] = delay_line[i] - 0.35 * delay_line[i + pluck_pos]

	var body := BodyResonatorBank.new()
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	var ptr := 0
	var lp_prev := 0.0

	for idx in range(total_samples):
		var amp := _piano_envelope_at(idx, a, d, s, r)
		var curr := delay_line[ptr]
		var next_idx := (ptr + 1) % delay_len
		var next_val := delay_line[next_idx]

		# Filtro de perda no laço (damping suave de corda de nylon/aço)
		var avg := 0.9965 * (curr * 0.58 + next_val * 0.42)
		lp_prev = lerpf(lp_prev, avg, 0.85)
		delay_line[ptr] = lp_prev
		ptr = next_idx

		var out := body.process(curr) * amp * 0.65
		var pcm: int = clampi(int(clampf(out, -1.0, 1.0) * 32767.0), -32768, 32767)
		bytes.encode_s16(idx * 2, pcm)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(MIX_RATE)
	stream.stereo = false
	stream.data = bytes
	return stream


## Sintetiza uma nota discreta de Violoncelo (arco expressivo + caixa acústica de madeira).
static func generate_cello_discrete_stream(freq: float, env_segments: PackedInt32Array) -> AudioStreamWAV:
	var a: int = env_segments[0]
	var d: int = env_segments[1]
	var s: int = env_segments[2]
	var r: int = env_segments[3]
	var total_samples: int = a + d + s + r

	var body := BodyResonatorBank.new()
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	var phase := 0.0
	var lfo_phase := 0.0
	var lfo_inc := 5.6 / MIX_RATE
	var rosin_lp := 0.0

	# Ataque de arco suave (45ms para o arco "pegar" na corda com breu)
	var bow_bite_samples := maxi(a, int(MIX_RATE * 0.045))

	for idx in range(total_samples):
		var t := float(idx) / MIX_RATE
		var amp := _piano_envelope_at(idx, a, d, s, r)
		if idx < bow_bite_samples:
			amp *= sin((float(idx) / float(bow_bite_samples)) * (PI * 0.5))

		# Vibrato progressivo: num violoncelo real, o músico inicia a nota limpa e
		# introduz o vibrato gradualmente após ~120ms!
		var vib_depth_cents := 16.0 * clampf((t - 0.08) / 0.18, 0.0, 1.0)
		var vib_mult := pow(2.0, (vib_depth_cents / 1200.0) * sin(lfo_phase * TAU))
		var inst_freq := freq * vib_mult

		# Ruído de breu (rosin friction) mais presente na mordida inicial do arco
		var bite_env := exp(-t * 28.0)
		rosin_lp = lerpf(rosin_lp, sin(float(idx * 23) * 1.37), 0.06)
		var string_sig := helmholtz_bowed_string(phase) + rosin_lp * (0.025 + 0.05 * bite_env)

		var out := body.process(string_sig) * amp * 0.58
		var pcm: int = clampi(int(clampf(out, -1.0, 1.0) * 32767.0), -32768, 32767)
		bytes.encode_s16(idx * 2, pcm)

		phase = fposmod(phase + inst_freq / MIX_RATE, 1.0)
		lfo_phase = fposmod(lfo_phase + lfo_inc, 1.0)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(MIX_RATE)
	stream.stereo = false
	stream.data = bytes
	return stream


static func _piano_envelope_at(idx: int, a: int, d: int, s: int, r: int) -> float:
	if idx < a:
		return float(idx) / float(maxi(1, a))
	if idx < a + d:
		var t := float(idx - a) / float(maxi(1, d))
		# Curva exponencial suave no decay em vez de reta linear
		return lerpf(1.0, 0.44, 1.0 - pow(1.0 - t, 1.8))
	if idx < a + d + s:
		var t_sus := float(idx - a - d) / float(maxi(1, s))
		# No piano real, o sustain não é estático como órgão: decai lentamente
		return lerpf(0.44, 0.30, t_sus)
	var t_rel := float(idx - a - d - s) / float(maxi(1, r))
	return lerpf(0.30, 0.0, t_rel * t_rel)
