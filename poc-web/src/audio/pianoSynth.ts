export class PianoSynth {
  /**
   * Sintetiza uma nota de Piano de Cauda Acústico em um AudioBuffer mono.
   */
  static synthesize(ctx: AudioContext, freq: number, durationSec: number = 2.4): AudioBuffer {
    const sampleRate = ctx.sampleRate;
    const totalSamples = Math.floor(sampleRate * durationSec);
    const buffer = ctx.createBuffer(1, totalSamples, sampleRate);
    const data = buffer.getChannelData(0);

    // Parciais inarmônicos do piano de cauda
    const B = 0.00018; // coeficiente de rigidez da corda de aço
    const partialWeights = [1.0, 0.46, 0.24, 0.13, 0.075, 0.04, 0.02];
    const weightSum = 1.965;
    const partialRatios: number[] = [];
    for (let p = 0; p < partialWeights.length; p++) {
      const n = p + 1;
      const stretch = Math.sqrt(1.0 + B * n * n);
      partialRatios.push(n * stretch);
    }

    // Coro de 3 cordas em uníssono (~0.8 cents de dispersão)
    const detune1 = 0.99954;
    const detune2 = 1.00000;
    const detune3 = 1.00046;

    let phase1 = 0;
    let phase2 = 0;
    let phase3 = 0;
    const inc1 = (freq * detune1) / sampleRate;
    const inc2 = (freq * detune2) / sampleRate;
    const inc3 = (freq * detune3) / sampleRate;

    let woodPhase = 0;
    const woodInc = 145.0 / sampleRate;
    let feltLp = 0;

    for (let i = 0; i < totalSamples; i++) {
      const t = i / sampleRate;

      // Envelope ADSR suave
      let env = 1.0;
      if (t < 0.005) {
        env = t / 0.005; // ataque rápido de martelo
      } else {
        env = Math.exp(-(t - 0.005) * 1.5); // decaimento acústico natural
      }

      // Coro triplo na fundamental + 2ª parcial
      const choirFund = (
        Math.sin(phase1 * Math.PI * 2) +
        Math.sin(phase2 * Math.PI * 2) +
        Math.sin(phase3 * Math.PI * 2)
      ) * 0.333333;

      const choirOct = (
        Math.sin(phase1 * Math.PI * 2 * partialRatios[1]) +
        Math.sin(phase2 * Math.PI * 2 * partialRatios[1]) +
        Math.sin(phase3 * Math.PI * 2 * partialRatios[1])
      ) * 0.333333;

      // Parciais superiores com decaimento exponencial proporcional à ordem
      let tone = choirFund * partialWeights[0] + choirOct * partialWeights[1] * Math.exp(-t * 1.8);
      for (let p = 2; p < partialWeights.length; p++) {
        const decayP = Math.exp(-t * (1.6 * (p + 1)));
        tone += partialWeights[p] * decayP * Math.sin(phase2 * Math.PI * 2 * partialRatios[p]);
      }
      tone /= weightSum;

      // Transiente acústico do feltro do martelo batendo no cavalete nos primeiros 20ms
      const hammerEnv = Math.exp(-t * 150.0);
      feltLp += (Math.sin(i * 1.618) - feltLp) * 0.18;
      const hammerThump = (Math.sin(woodPhase * Math.PI * 2) * 0.65 + feltLp * 0.35) * hammerEnv * 0.15;

      data[i] = Math.max(-0.95, Math.min(0.95, (tone + hammerThump) * env * 0.62));

      phase1 = (phase1 + inc1) % 1.0;
      phase2 = (phase2 + inc2) % 1.0;
      phase3 = (phase3 + inc3) % 1.0;
      woodPhase = (woodPhase + woodInc) % 1.0;
    }

    return buffer;
  }
}
