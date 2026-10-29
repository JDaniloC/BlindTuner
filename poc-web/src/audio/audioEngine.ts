import { ACOUSTIC_WORKLET_CODE } from "./acousticWorklet";
import { PianoSynth } from "./pianoSynth";
import { NOTES, NOTE_KEYS } from "../core/notes";

export type AudioEngineMode = "modal-convolver" | "faust-dsp";

export class AudioEngine {
  private _ctx: AudioContext | null = null;
  private _workletNode: AudioWorkletNode | null = null;
  private _convolverNode: ConvolverNode | null = null;
  private _convolverGain: GainNode | null = null;
  private _directGain: GainNode | null = null;
  private _pianoBuffers: Map<string, AudioBuffer> = new Map();
  private _masterGain: GainNode | null = null;
  private _isReady: boolean = false;
  private _activeMode: AudioEngineMode = "modal-convolver";

  get isReady(): boolean {
    return this._isReady;
  }

  get mode(): AudioEngineMode {
    return this._activeMode;
  }

  public setMode(mode: AudioEngineMode): void {
    this._activeMode = mode;
  }

  public async init(): Promise<void> {
    if (this._isReady) return;

    const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    this._ctx = new AudioContextClass();
    if (this._ctx.state === "suspended") {
      await this._ctx.resume();
    }

    this._masterGain = this._ctx.createGain();
    this._masterGain.gain.value = 0.85;
    this._masterGain.connect(this._ctx.destination);

    // 1. ConvolverNode com Impulse Response (IR) Acústico de Madeira Real
    this._convolverNode = this._ctx.createConvolver();
    this._convolverNode.buffer = this._generateCelloWoodIR(this._ctx);

    this._convolverGain = this._ctx.createGain();
    this._convolverGain.gain.value = 0.65;
    this._convolverNode.connect(this._convolverGain);
    this._convolverGain.connect(this._masterGain);

    this._directGain = this._ctx.createGain();
    this._directGain.gain.value = 0.55;
    this._directGain.connect(this._masterGain);

    // 2. AudioWorkletProcessor de Violoncelo
    const blob = new Blob([ACOUSTIC_WORKLET_CODE], { type: "application/javascript" });
    const workletUrl = URL.createObjectURL(blob);
    await this._ctx.audioWorklet.addModule(workletUrl);
    URL.revokeObjectURL(workletUrl);

    this._workletNode = new AudioWorkletNode(this._ctx, "acoustic-cello-processor");
    // Conecta o violoncelo tanto no caminho direto quanto na câmara de convolução da madeira
    this._workletNode.connect(this._directGain);
    this._workletNode.connect(this._convolverNode);

    // 3. Pré-renderiza os 12 buffers de Piano de Cauda com transiente acústico
    for (const key of NOTE_KEYS) {
      const freq = NOTES[key].freq;
      const buf = PianoSynth.synthesize(this._ctx, freq);
      this._pianoBuffers.set(key, buf);
    }

    this._isReady = true;
  }

  /**
   * Gera um Impulse Response (IR) de altíssima fidelidade da caixa acústica de madeira de um violoncelo.
   * Modos físicos: ar A0 (108 Hz), tampo de abeto B1 (212 Hz), dipolo (510 Hz), colina de cavalete (1950 Hz).
   */
  private _generateCelloWoodIR(ctx: AudioContext): AudioBuffer {
    const rate = ctx.sampleRate;
    const len = Math.floor(rate * 0.045); // 45 milissegundos de ressonância de madeira
    const buf = ctx.createBuffer(2, len, rate);
    const left = buf.getChannelData(0);
    const right = buf.getChannelData(1);

    const modes = [
      { f: 108.0, q: 6.0, w: 0.85 },
      { f: 212.0, q: 7.5, w: 1.00 },
      { f: 510.0, q: 5.0, w: 0.65 },
      { f: 1950.0, q: 4.0, w: 0.40 },
    ];

    for (let i = 0; i < len; i++) {
      const t = i / rate;
      const decay = Math.exp(-t * 85.0); // amortecimento natural da madeira de abeto
      let sample = 0;

      for (const m of modes) {
        const dM = Math.exp(-t * (m.f / m.q));
        sample += Math.sin(t * Math.PI * 2 * m.f) * m.w * dM;
      }

      const noise = (Math.random() * 2 - 1) * Math.exp(-t * 220.0) * 0.15;
      const val = (sample + noise) * decay * 0.55;

      left[i] = val;
      // Canal direito com micro-atraso de dispersão estéreo na madeira
      right[i] = val * (i > 8 ? 0.95 : 0.8);
    }

    return buf;
  }

  /**
   * Toca uma nota discreta de Piano de Cauda Acústico com ressonância.
   */
  public playPiano(noteKey: string): void {
    if (!this._ctx || !this._masterGain) return;
    const buf = this._pianoBuffers.get(noteKey);
    if (!buf) return;

    const src = this._ctx.createBufferSource();
    src.buffer = buf;

    if (this._convolverNode) {
      src.connect(this._convolverNode);
    }
    src.connect(this._masterGain);
    src.start();
  }

  /**
   * Inicia o tom contínuo de Violoncelo no Scroll de Afinação.
   */
  public startCello(freqHz: number): void {
    if (!this._workletNode) return;
    this._workletNode.port.postMessage({ type: "start", freq: freqHz });
  }

  /**
   * Modifica a frequência em tempo real durante o arraste (glissando perfeito sem degraus).
   */
  public setPitch(freqHz: number): void {
    if (!this._workletNode) return;
    this._workletNode.port.postMessage({ type: "setFreq", freq: freqHz });
  }

  /**
   * Encerra o tom contínuo do violoncelo.
   */
  public stopCello(): void {
    if (!this._workletNode) return;
    this._workletNode.port.postMessage({ type: "stop" });
  }

  /**
   * Efeito sonoro do toque da bengala de luthier no taco de madeira (parquet).
   */
  public playCaneTapSfx(): void {
    if (!this._ctx || !this._masterGain) return;
    const osc = this._ctx.createOscillator();
    const gain = this._ctx.createGain();

    osc.type = "sine";
    const now = this._ctx.currentTime;
    osc.frequency.setValueAtTime(320, now);
    osc.frequency.exponentialRampToValueAtTime(75, now + 0.045);

    gain.gain.setValueAtTime(0.45, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

    osc.connect(gain);
    gain.connect(this._masterGain);

    osc.start(now);
    osc.stop(now + 0.05);
  }

  /**
   * Efeito sonoro de impacto contra parede ou móvel de madeira (tropeço).
   */
  public playWallBumpSfx(): void {
    if (!this._ctx || !this._masterGain) return;
    const osc = this._ctx.createOscillator();
    const gain = this._ctx.createGain();

    osc.type = "triangle";
    const now = this._ctx.currentTime;
    osc.frequency.setValueAtTime(120, now);
    osc.frequency.exponentialRampToValueAtTime(45, now + 0.12);

    gain.gain.setValueAtTime(0.65, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);

    osc.connect(gain);
    gain.connect(this._masterGain);

    osc.start(now);
    osc.stop(now + 0.14);
  }

  /**
   * Efeito sonoro de erro de nota / dissonância na afinação.
   */
  public playNoteMissSfx(): void {
    if (!this._ctx || !this._masterGain) return;
    const osc1 = this._ctx.createOscillator();
    const osc2 = this._ctx.createOscillator();
    const gain = this._ctx.createGain();

    const now = this._ctx.currentTime;
    // Semitom menor dissonante
    osc1.frequency.setValueAtTime(220, now);
    osc2.frequency.setValueAtTime(233.08, now); // intervalo de segunda menor (dissonância acústica clássica)

    gain.gain.setValueAtTime(0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.18);

    osc1.connect(gain);
    osc2.connect(gain);
    gain.connect(this._masterGain);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 0.18);
    osc2.stop(now + 0.18);
  }

  /**
   * Farol Sonoro Temático Espacial 2D:
   * Calcula atenuação por distância e panorâmica estéreo em relação à posição do Sr. Arthur.
   */
  public playBeaconSound(beaconType: string, relativePos?: { dx: number; dy: number }, ducked: boolean = false): void {
    if (!this._ctx || !this._masterGain) return;

    let pan = 0;
    let dist = 1.0;
    if (relativePos) {
      // Isometria 2:1: eixo x da tela é dx - dy, eixo y é (dx + dy) * 0.5
      const screenDx = relativePos.dx - relativePos.dy;
      pan = Math.max(-1.0, Math.min(1.0, screenDx / 6.0));
      dist = Math.sqrt(relativePos.dx * relativePos.dx + relativePos.dy * relativePos.dy);
    }

    const falloff = Math.max(0.15, Math.min(1.0, 1.0 / (1.0 + (dist - 1.0) * 0.14)));
    const duckingMult = ducked ? 0.32 : 1.0;
    const baseGain = 0.5 * falloff * duckingMult;

    // Roteamento de Panning Estéreo
    const now = this._ctx.currentTime;
    const gainNode = this._ctx.createGain();
    gainNode.gain.setValueAtTime(baseGain, now);

    let outputTarget: AudioNode = gainNode;
    if (this._ctx.createStereoPanner) {
      const panner = this._ctx.createStereoPanner();
      panner.pan.setValueAtTime(pan, now);
      gainNode.connect(panner);
      outputTarget = panner;
    }
    outputTarget.connect(this._masterGain);

    switch (beaconType) {
      case "drip":
        this._playDripBeacon(gainNode, now);
        break;
      case "clock":
        this._playClockBeacon(gainNode, now);
        break;
      case "music_box":
        this._playMusicBoxBeacon(gainNode, now);
        break;
      case "cello_drone":
        this._playCelloDroneBeacon(gainNode, now);
        break;
      case "radio":
      default:
        this._playRadioBeacon(gainNode, now);
        break;
    }
  }

  private _playRadioBeacon(dest: AudioNode, now: number): void {
    if (!this._ctx) return;
    // Acorde E4 (329.63 Hz) + A4 (440 Hz) com modulação suave e leve granulação valvulada
    const osc1 = this._ctx.createOscillator();
    const osc2 = this._ctx.createOscillator();
    const subGain = this._ctx.createGain();

    osc1.type = "sine";
    osc2.type = "triangle";
    osc1.frequency.setValueAtTime(329.63, now);
    osc2.frequency.setValueAtTime(440.0, now);

    subGain.gain.setValueAtTime(0.01, now);
    subGain.gain.linearRampToValueAtTime(0.4, now + 0.08);
    subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.65);

    osc1.connect(subGain);
    osc2.connect(subGain);
    subGain.connect(dest);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 0.65);
    osc2.stop(now + 0.65);
  }

  private _playDripBeacon(dest: AudioNode, now: number): void {
    if (!this._ctx) return;
    // Varredura descendente de gota d'água de 1350 Hz para 600 Hz com decaimento aquoso rápido
    const osc = this._ctx.createOscillator();
    const subGain = this._ctx.createGain();

    osc.type = "sine";
    osc.frequency.setValueAtTime(1350.0, now);
    osc.frequency.exponentialRampToValueAtTime(600.0, now + 0.07);

    subGain.gain.setValueAtTime(0.01, now);
    subGain.gain.linearRampToValueAtTime(0.6, now + 0.005);
    subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);

    osc.connect(subGain);
    subGain.connect(dest);

    osc.start(now);
    osc.stop(now + 0.22);
  }

  private _playClockBeacon(dest: AudioNode, now: number): void {
    if (!this._ctx) return;
    // Estalo seco de pêndulo de madeira e latão (820 Hz com decaimento em 0.12s)
    const osc = this._ctx.createOscillator();
    const subGain = this._ctx.createGain();

    osc.type = "triangle";
    osc.frequency.setValueAtTime(820.0, now);
    osc.frequency.exponentialRampToValueAtTime(220.0, now + 0.08);

    subGain.gain.setValueAtTime(0.01, now);
    subGain.gain.linearRampToValueAtTime(0.55, now + 0.004);
    subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

    osc.connect(subGain);
    subGain.connect(dest);

    osc.start(now);
    osc.stop(now + 0.12);
  }

  private _playMusicBoxBeacon(dest: AudioNode, now: number): void {
    if (!this._ctx) return;
    // Nota cristalina E5 (659.25 Hz) com harmônicos e decaimento doce
    const osc = this._ctx.createOscillator();
    const subGain = this._ctx.createGain();

    osc.type = "sine";
    osc.frequency.setValueAtTime(659.25, now);

    subGain.gain.setValueAtTime(0.01, now);
    subGain.gain.linearRampToValueAtTime(0.5, now + 0.008);
    subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.75);

    osc.connect(subGain);
    subGain.connect(dest);

    osc.start(now);
    osc.stop(now + 0.75);
  }

  private _playCelloDroneBeacon(dest: AudioNode, now: number): void {
    if (!this._ctx) return;
    // Nota pedal C3 (130.81 Hz) encorpada
    const osc1 = this._ctx.createOscillator();
    const osc2 = this._ctx.createOscillator();
    const subGain = this._ctx.createGain();

    osc1.type = "sawtooth";
    osc2.type = "sine";
    osc1.frequency.setValueAtTime(130.81, now);
    osc2.frequency.setValueAtTime(261.63, now);

    subGain.gain.setValueAtTime(0.01, now);
    subGain.gain.linearRampToValueAtTime(0.35, now + 0.15);
    subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.95);

    osc1.connect(subGain);
    osc2.connect(subGain);
    subGain.connect(dest);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 0.95);
    osc2.stop(now + 0.95);
  }

  /**
   * Fanfarra triunfal de vitória:
   * Acorde maior de violoncelo acústico reverberado com arpejo e sinos de estrelas.
   */
  public playVictoryFanfare(): void {
    if (!this._ctx || !this._masterGain) return;
    const now = this._ctx.currentTime;
    const notes = [130.81, 196.0, 329.63, 523.25]; // C3, G3, E4, C5
    notes.forEach((freq, idx) => {
      const osc = this._ctx!.createOscillator();
      const gain = this._ctx!.createGain();
      const noteStart = now + idx * 0.12;
      osc.type = idx % 2 === 0 ? "sawtooth" : "triangle";
      osc.frequency.setValueAtTime(freq, noteStart);

      gain.gain.setValueAtTime(0.01, noteStart);
      gain.gain.linearRampToValueAtTime(0.35, noteStart + 0.08);
      gain.gain.exponentialRampToValueAtTime(0.001, noteStart + 1.2);

      osc.connect(gain);
      if (this._convolverNode) {
        gain.connect(this._convolverNode);
      }
      gain.connect(this._masterGain!);

      osc.start(noteStart);
      osc.stop(noteStart + 1.25);
    });

    // Star chimes em registro alto
    [1046.5, 1318.51].forEach((freq, i) => {
      const chimeOsc = this._ctx!.createOscillator();
      const chimeGain = this._ctx!.createGain();
      const cStart = now + 0.45 + i * 0.15;
      chimeOsc.type = "sine";
      chimeOsc.frequency.setValueAtTime(freq, cStart);

      chimeGain.gain.setValueAtTime(0.01, cStart);
      chimeGain.gain.linearRampToValueAtTime(0.25, cStart + 0.01);
      chimeGain.gain.exponentialRampToValueAtTime(0.001, cStart + 0.85);

      chimeOsc.connect(chimeGain);
      chimeGain.connect(this._masterGain!);

      chimeOsc.start(cStart);
      chimeOsc.stop(cStart + 0.9);
    });
  }
}
