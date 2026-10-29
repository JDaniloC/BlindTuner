import { Container, Graphics } from "pixi.js";
import { IsoMath, Vector2 } from "../core/iso";

export interface BeaconPulseWave {
  age: number;
  duration: number;
}

export interface BeaconMote {
  x: number;
  y: number;
  vx: number;
  vy: number;
  age: number;
  duration: number;
  size: number;
}

export class GoalAudioBeacon {
  public readonly container: Container;
  private readonly _gHalo: Graphics;
  private readonly _gWaves: Graphics;
  private readonly _gMotes: Graphics;

  public beaconType: string = "radio";
  public pulseInterval: number = 2.5;
  public isActive: boolean = true;
  public visualEnabled: boolean = true;
  public isDucked: boolean = false;

  private _time: number = 0;
  private _pulseTimer: number = 0;
  private _pulseWaves: BeaconPulseWave[] = [];
  private _motes: BeaconMote[] = [];
  public gridPos: Vector2 = { x: 0, y: 0 };
  public step: number = 44;

  public onPulsed?: (soundType: string, gridPos: Vector2) => void;

  constructor(step: number = 44) {
    this.step = step;
    this.container = new Container();
    this.container.sortableChildren = true;

    this._gHalo = new Graphics();
    this._gHalo.zIndex = 10;
    this.container.addChild(this._gHalo);

    this._gWaves = new Graphics();
    this._gWaves.zIndex = 20;
    this.container.addChild(this._gWaves);

    this._gMotes = new Graphics();
    this._gMotes.zIndex = 30;
    this.container.addChild(this._gMotes);
  }

  public setup(soundType: string, gridPos: Vector2, interval: number = 2.5): void {
    this.beaconType = soundType;
    this.gridPos = { ...gridPos };
    this.pulseInterval = interval;
    this._pulseTimer = 0;

    const world = IsoMath.gridToWorld(gridPos.x + 0.5, gridPos.y + 0.5, 0, this.step);
    this.container.x = world.x;
    this.container.y = world.y;
    this.container.zIndex = IsoMath.depthOf({ x: (gridPos.x + 0.5) * this.step, y: (gridPos.y + 0.5) * this.step, z: 0 });
  }

  public start(): void {
    this.isActive = true;
    this._pulseTimer = 0;
    this.pulseNow();
  }

  public stop(): void {
    this.isActive = false;
    this._pulseWaves = [];
    this._motes = [];
    this._gHalo.clear();
    this._gWaves.clear();
    this._gMotes.clear();
  }

  public setVisualEnabled(enabled: boolean): void {
    this.visualEnabled = enabled;
    if (!enabled) {
      this._gHalo.clear();
      this._gWaves.clear();
      this._gMotes.clear();
    }
  }

  public setDucking(ducked: boolean): void {
    this.isDucked = ducked;
  }

  public pulseNow(): void {
    if (!this.isActive) return;

    // Dispara onda de choque harmônica
    this._pulseWaves.push({ age: 0, duration: 1.4 });

    // Dispara 3 partículas acústicas em leque
    for (let i = 0; i < 3; i++) {
      const angle = (i - 1.0) * 0.65 + Math.sin(this._time * 3.1 + i) * 0.2;
      this._motes.push({
        x: Math.sin(angle) * 10,
        y: -6 - i * 3,
        vx: Math.sin(angle) * 7,
        vy: -22 - i * 4,
        age: 0,
        duration: 1.1 + i * 0.15,
        size: i === 1 ? 3.0 : 2.0,
      });
    }

    if (this.onPulsed) {
      this.onPulsed(this.beaconType, this.gridPos);
    }
  }

  public getBeaconColor(): number {
    switch (this.beaconType) {
      case "drip":
        return 0x4fc3f7; // Aqua/Cyan
      case "clock":
        return 0xffb74d; // Brass / Golden
      case "music_box":
        return 0x81d4fa; // Bell Light Blue
      case "cello_drone":
        return 0xd4af37; // Amber Gold
      case "radio":
      default:
        return 0xffd54f; // Warm Amber
    }
  }

  public update(dt: number): void {
    if (!this.isActive) return;

    this._time += dt;
    this._pulseTimer += dt;
    if (this._pulseTimer >= this.pulseInterval) {
      this._pulseTimer = 0;
      this.pulseNow();
    }

    // Atualiza ondas
    for (let i = this._pulseWaves.length - 1; i >= 0; i--) {
      this._pulseWaves[i].age += dt;
      if (this._pulseWaves[i].age >= this._pulseWaves[i].duration) {
        this._pulseWaves.splice(i, 1);
      }
    }

    // Atualiza motes
    for (let i = this._motes.length - 1; i >= 0; i--) {
      const m = this._motes[i];
      m.age += dt;
      m.x += m.vx * dt;
      m.y += m.vy * dt;
      if (m.age >= m.duration) {
        this._motes.splice(i, 1);
      }
    }

    if (!this.visualEnabled) return;

    const baseCol = this.getBeaconColor();
    const breath = 0.5 + 0.5 * Math.sin(this._time * 2.6);

    // 1. Halo luminoso 2D isométrico concêntrico no piso (2:1)
    this._gHalo.clear();
    const glowLayers = 3;
    for (let layer = 0; layer < glowLayers; layer++) {
      const ratio = (glowLayers - layer) / glowLayers;
      const rx = (24 + 6 * breath) * ratio;
      const ry = rx * 0.5;
      const alpha = (0.12 + 0.06 * breath) * (1.1 - ratio * 0.5);

      this._gHalo.ellipse(0, 0, rx, ry)
        .fill({ color: baseCol, alpha });
    }

    // Marcador central do ponto de chegada (diamante isométrico de latão)
    const dSize = 6.0;
    this._gHalo.poly([0, -dSize * 0.5, dSize, 0, 0, dSize * 0.5, -dSize, 0])
      .fill(baseCol)
      .stroke({ color: 0x1c130d, width: 1.2 });

    // 2. Anéis harmônicos em expansão
    this._gWaves.clear();
    for (const w of this._pulseWaves) {
      const t = Math.min(1.0, w.age / w.duration);
      const eased = 1.0 - Math.pow(1.0 - t, 2.2);
      const rx = 10.0 + eased * 48.0;
      const ry = rx * 0.5;
      const a = (1.0 - t) * 0.75;

      this._gWaves.ellipse(0, 0, rx, ry)
        .stroke({ color: baseCol, width: 2.0, alpha: a });

      if (t < 0.7) {
        const rxInner = 6.0 + eased * 30.0;
        this._gWaves.ellipse(0, 0, rxInner, rxInner * 0.5)
          .stroke({ color: 0xffffff, width: 1.2, alpha: a * 0.6 });
      }
    }

    // 3. Partículas acústicas (motes)
    this._gMotes.clear();
    for (const m of this._motes) {
      const t = Math.min(1.0, m.age / m.duration);
      const a = Math.sin(t * Math.PI) * 0.85;
      const s = m.size;

      this._gMotes.poly([
        m.x, m.y - s,
        m.x + s, m.y,
        m.x, m.y + s,
        m.x - s, m.y,
      ])
      .fill({ color: 0xfffae0, alpha: a });
    }
  }
}
