/**
 * AudioWorkletProcessor de Modelagem Física de Corda Friccionada (Violoncelo Contínuo).
 * Zero zumbidos, sem artefatos periódicos de buffer e com transição contínua perfeita de afinação.
 */
export const ACOUSTIC_WORKLET_CODE = `
class AcousticCelloProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.phase = 0.0;
    this.targetFreq = 262.0;
    this.currentFreq = 262.0;
    this.active = false;
    this.gain = 0.0;
    this.lfoPhase = 0.0;
    this.bowPressure = 0.65;

    // Gerador de ruído rosa estocástico contínuo (sem repetição por bloco!)
    this.noiseZ1 = 0.0;
    this.noiseZ2 = 0.0;
    this.prngSeed = 123456789;

    // Banco de Ressonadores Modais de Madeira (Corpo do Violoncelo)
    this.sampleRate = 44100;
    this.initBodyResonators();

    this.port.onmessage = (e) => {
      const data = e.data;
      if (data.type === 'start') {
        this.targetFreq = data.freq || 262.0;
        this.currentFreq = this.targetFreq;
        this.active = true;
      } else if (data.type === 'setFreq') {
        this.targetFreq = data.freq;
      } else if (data.type === 'stop') {
        this.active = false;
      }
    };
  }

  // PRNG contínuo LCG (Linear Congruential Generator) de alta velocidade
  nextRandom() {
    this.prngSeed = (1664525 * this.prngSeed + 1013904223) % 4294967296;
    return (this.prngSeed / 2147483648.0) - 1.0;
  }

  calcBandpass(freq, q, sr) {
    const w0 = (2.0 * Math.PI * freq) / sr;
    const cos_w0 = Math.cos(w0);
    const alpha = Math.sin(w0) / (2.0 * q);
    const a0 = 1.0 + alpha;
    return {
      b0: alpha / a0,
      b1: 0.0,
      b2: -alpha / a0,
      a1: (-2.0 * cos_w0) / a0,
      a2: (1.0 - alpha) / a0
    };
  }

  initBodyResonators() {
    // 4 modos acústicos reais da caixa de ressonância de um violoncelo
    this.c0 = this.calcBandpass(108.0, 4.8, this.sampleRate); // Modo de ar A0
    this.c1 = this.calcBandpass(212.0, 5.2, this.sampleRate); // Tampo de abeto B1
    this.c2 = this.calcBandpass(510.0, 4.0, this.sampleRate); // Corpo médio
    this.c3 = this.calcBandpass(1950.0, 3.0, this.sampleRate); // Bridge Hill (projeção vocal)

    this.z1_0 = 0.0; this.z2_0 = 0.0;
    this.z1_1 = 0.0; this.z2_1 = 0.0;
    this.z1_2 = 0.0; this.z2_2 = 0.0;
    this.z1_3 = 0.0; this.z2_3 = 0.0;
    this.woodLp = 0.0;
  }

  processBody(x) {
    const y0 = this.c0.b0 * x + this.z1_0;
    this.z1_0 = this.c0.b1 * x - this.c0.a1 * y0 + this.z2_0;
    this.z2_0 = this.c0.b2 * x - this.c0.a2 * y0;

    const y1 = this.c1.b0 * x + this.z1_1;
    this.z1_1 = this.c1.b1 * x - this.c1.a1 * y1 + this.z2_1;
    this.z2_1 = this.c1.b2 * x - this.c1.a2 * y1;

    const y2 = this.c2.b0 * x + this.z1_2;
    this.z1_2 = this.c2.b1 * x - this.c2.a1 * y2 + this.z2_2;
    this.z2_2 = this.c2.b2 * x - this.c2.a2 * y2;

    const y3 = this.c3.b0 * x + this.z1_3;
    this.z1_3 = this.c3.b1 * x - this.c3.a1 * y3 + this.z2_3;
    this.z2_3 = this.c3.b2 * x - this.c3.a2 * y3;

    this.woodLp += (x - this.woodLp) * 0.32;
    const woodRadiation = (y0 * 0.65) + (y1 * 0.75) + (y2 * 0.50) + (y3 * 0.38);
    return this.woodLp * 0.55 + woodRadiation * 0.65;
  }

  // Movimento físico de Helmholtz (corda friccionada com arco em beta ≈ 1/9)
  helmholtzWave(phase) {
    const p = phase % 1.0;
    // Rampa assimétrica de arco (stick-slip) com transição arredondada
    let wave = 0.0;
    if (p < 0.88) {
      wave = (p / 0.88) * 2.0 - 1.0; // Fase 'stick' (arco arrastando a corda)
    } else {
      wave = 1.0 - ((p - 0.88) / 0.12) * 2.0; // Fase 'slip' (corda soltando)
    }
    // Suavização harmônica que evita a aspereza de dente de serra sintética
    return Math.sin(wave * 1.5707963) * 0.95;
  }

  process(inputs, outputs, parameters) {
    const output = outputs[0];
    const channel = output[0];
    if (!channel) return true;

    const targetGain = this.active ? 0.72 : 0.0;
    const lfoInc = 5.2 / this.sampleRate; // Vibrato natural cantabile a 5.2 Hz

    for (let i = 0; i < channel.length; i++) {
      this.gain += (targetGain - this.gain) * 0.006;

      if (this.gain < 0.0001 && !this.active) {
        channel[i] = 0.0;
        continue;
      }

      // Glissando contínuo instantâneo
      this.currentFreq += (this.targetFreq - this.currentFreq) * 0.015;

      // Vibrato orgânico de mão esquerda (~16 cents)
      const vibCents = 16.0 * Math.sin(this.lfoPhase * 2.0 * Math.PI);
      const vibMult = Math.pow(2.0, vibCents / 1200.0);
      const instFreq = this.currentFreq * vibMult;

      // Ruído estocástico de atrito da crina com breu (sem zumbido!)
      const whiteNoise = this.nextRandom();
      this.noiseZ1 += (whiteNoise - this.noiseZ1) * 0.08;
      this.noiseZ2 += (this.noiseZ1 - this.noiseZ2) * 0.08;
      const rosinFriction = this.noiseZ2 * 0.035;

      // Corda de Helmholtz excitada pelo arco
      const rawString = this.helmholtzWave(this.phase) + rosinFriction;

      // Ressonância na caixa de madeira do violoncelo
      const bodyOut = this.processBody(rawString);

      channel[i] = Math.max(-0.95, Math.min(0.95, bodyOut * this.gain));

      this.phase = (this.phase + instFreq / this.sampleRate) % 1.0;
      this.lfoPhase = (this.lfoPhase + lfoInc) % 1.0;
    }

    return true;
  }
}

registerProcessor('acoustic-cello-processor', AcousticCelloProcessor);
`;
