import { Container, Graphics } from "pixi.js";
import { IsoMath, Vector2 } from "../core/iso";
import { FurnitureRenderer } from "./furniture";
import { ArthurRig } from "./arthurRig";
import { ColorSchemeManager } from "../core/colorSchemes";
import { GoalAudioBeacon } from "./goalAudioBeacon";
import { LevelDef, LEVEL_QUARTO, ObstacleDef } from "../core/level";
import { SceneryTheme, SceneryThemes } from "./sceneryThemes";

export interface AcousticShockwave {
  x: number;
  y: number;
  radius: number;
  maxRadius: number;
  colorHex: number;
  alpha: number;
  speed: number;
}

export interface DustPuff {
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  alpha: number;
  life: number;
  maxLife: number;
}

export interface FocusGuide {
  fromX: number;
  fromY: number;
  toX: number;
  toY: number;
  alpha: number;
  pulsePhase: number;
}

export interface DustMote {
  x: number;
  y: number;
  baseX: number;
  baseY: number;
  speed: number;
  phase: number;
  radius: number;
  alpha: number;
}

export class RoomScene {
  public readonly stage: Container;
  public readonly worldContainer: Container;
  public readonly arthur: ArthurRig;
  public readonly beacon: GoalAudioBeacon;

  private readonly _gFloor: Graphics;
  private readonly _gWalls: Graphics;
  private readonly _gWindowLight: Graphics;
  private readonly _gWaves: Graphics;
  private readonly _gFocusGuide: Graphics;
  private readonly _gDustPuffs: Graphics;
  private readonly _gDust: Graphics;
  private readonly _gWallFlash: Graphics;

  private _furnitureContainers: Container[] = [];
  private _updatables: ((t: number) => void)[] = [];
  private _shockwaves: AcousticShockwave[] = [];
  private _dustMotes: DustMote[] = [];
  private _dustPuffs: DustPuff[] = [];
  private _focusGuide: FocusGuide | null = null;

  public wallFlashAlpha: number = 0;
  public screenShake: number = 0;
  public readonly step: number = 44;

  public currentLevel: LevelDef = LEVEL_QUARTO;
  public currentTheme: SceneryTheme = SceneryThemes.getTheme("quarto");

  constructor() {
    this.stage = new Container();
    this.worldContainer = new Container();
    this.worldContainer.sortableChildren = true;
    this.stage.addChild(this.worldContainer);

    this._gFloor = new Graphics();
    this._gFloor.zIndex = -100;
    this.worldContainer.addChild(this._gFloor);

    this._gWalls = new Graphics();
    this._gWalls.zIndex = -80;
    this.worldContainer.addChild(this._gWalls);

    this._gWindowLight = new Graphics();
    this._gWindowLight.zIndex = -70;
    this.worldContainer.addChild(this._gWindowLight);

    this._gWaves = new Graphics();
    this._gWaves.zIndex = -10;
    this.worldContainer.addChild(this._gWaves);

    this.beacon = new GoalAudioBeacon(this.step);
    this.worldContainer.addChild(this.beacon.container);

    this._gFocusGuide = new Graphics();
    this._gFocusGuide.zIndex = 30;
    this.worldContainer.addChild(this._gFocusGuide);

    this.arthur = new ArthurRig();
    this.worldContainer.addChild(this.arthur.container);

    this._gDustPuffs = new Graphics();
    this._gDustPuffs.zIndex = 400;
    this.worldContainer.addChild(this._gDustPuffs);

    this._gDust = new Graphics();
    this._gDust.zIndex = 500;
    this.worldContainer.addChild(this._gDust);

    this._gWallFlash = new Graphics();
    this._gWallFlash.zIndex = 900;
    this.worldContainer.addChild(this._gWallFlash);

    this.buildLevel(LEVEL_QUARTO);
    this._initDustMotes();
  }

  /**
   * Constrói ou reconstrói o cenário procedural com piso, paredes, iluminação,
   * móveis característicos e posicionamento do farol sonoro.
   */
  public buildLevel(level: LevelDef, customTheme?: SceneryTheme): void {
    this.currentLevel = level;
    this.currentTheme = customTheme || SceneryThemes.getTheme(level.themeId);

    // 1. Limpeza de instâncias anteriores de móveis
    for (const c of this._furnitureContainers) {
      this.worldContainer.removeChild(c);
      c.destroy({ children: true });
    }
    this._furnitureContainers = [];
    this._updatables = [];

    this._gFloor.clear();
    this._gWalls.clear();
    this._gWindowLight.clear();

    const s = this.step;
    const w = level.gridWidth;
    const h = level.gridHeight;
    const theme = this.currentTheme;

    // 2. Renderização do Piso conforme o Tipo de Pavimento
    if (theme.floorType === "tiles") {
      // Banheiro: Ladrilhos cerâmicos quadrados com mosaico sutil
      for (let gx = 0; gx < w; gx++) {
        for (let gy = 0; gy < h; gy++) {
          const p0 = IsoMath.gridToWorld(gx, gy, 0, s);
          const p1 = IsoMath.gridToWorld(gx + 1, gy, 0, s);
          const p2 = IsoMath.gridToWorld(gx + 1, gy + 1, 0, s);
          const p3 = IsoMath.gridToWorld(gx, gy + 1, 0, s);

          const isChecker = (gx + gy) % 2 === 0;
          const col = isChecker ? theme.floorA : theme.floorB;

          this._gFloor.poly([p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y])
            .fill(col)
            .stroke({ color: theme.wallOutline, width: 1.0, alpha: 0.45 });

          // Mosaico central discreto de ladrilho hidráulico
          if ((gx + gy) % 3 === 0) {
            const midX = (p0.x + p2.x) * 0.5;
            const midY = (p0.y + p2.y) * 0.5;
            this._gFloor.poly([
              midX, midY - 3,
              midX + 5, midY,
              midX, midY + 3,
              midX - 5, midY,
            ])
            .fill({ color: 0x81d4fa, alpha: 0.35 });
          }
        }
      }
    } else {
      // Quarto e Sala: Tacos de madeira nobre (parquet / herringbone)
      const baseColA = theme.floorA;
      const baseColB = theme.floorB;
      for (let gx = 0; gx < w; gx++) {
        for (let gy = 0; gy < h; gy++) {
          const p0 = IsoMath.gridToWorld(gx, gy, 0, s);
          const p1 = IsoMath.gridToWorld(gx + 1, gy, 0, s);
          const p2 = IsoMath.gridToWorld(gx + 1, gy + 1, 0, s);
          const p3 = IsoMath.gridToWorld(gx, gy + 1, 0, s);

          const isAlt = (gx * 3 + gy * 7 + (gx ^ gy)) % 2 === 0;
          const color = isAlt ? baseColA : baseColB;

          this._gFloor.poly([p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y])
            .fill(color)
            .stroke({ color: theme.wallOutline, width: 1.0, alpha: 0.5 });

          // Veios orgânicos de madeira
          const midX = (p0.x + p2.x) * 0.5;
          const midY = (p0.y + p2.y) * 0.5;
          this._gFloor.moveTo(midX - 7, midY - 3.5).lineTo(midX + 7, midY + 3.5)
            .stroke({ color: theme.wallOutline, width: 0.8, alpha: 0.25 });
        }
      }
    }

    // 3. Paredes Perimetrais em L com Altura e Espessura 3D
    const wallH = 105;
    // Parede NW
    const nw0 = IsoMath.gridToWorld(0, 0, 0, s);
    const nw1 = IsoMath.gridToWorld(w, 0, 0, s);
    this._gWalls.poly([
      nw0.x, nw0.y,
      nw1.x, nw1.y,
      nw1.x, nw1.y - wallH,
      nw0.x, nw0.y - wallH,
    ])
    .fill(theme.wallTop)
    .stroke({ color: theme.wallOutline, width: 2.0 });

    // Parede NE
    const ne0 = IsoMath.gridToWorld(0, 0, 0, s);
    const ne1 = IsoMath.gridToWorld(0, h, 0, s);
    this._gWalls.poly([
      ne0.x, ne0.y,
      ne1.x, ne1.y,
      ne1.x, ne1.y - wallH,
      ne0.x, ne0.y - wallH,
    ])
    .fill(theme.wallFront)
    .stroke({ color: theme.wallOutline, width: 2.0 });

    // Rodapé de madeira contínuo
    this._gWalls.moveTo(ne1.x, ne1.y).lineTo(ne0.x, ne0.y).lineTo(nw1.x, nw1.y)
      .stroke({ color: theme.wallOutline, width: 4.5 });

    // 4. Elementos Arquiteturais de Parede (Janela e Feixe de Luz)
    if (level.id === "quarto" || level.id === "sala") {
      const winX0 = 2.0 * s;
      const winX1 = 3.8 * s;
      const winZ0 = 34.0;
      const winZ1 = 84.0;

      const wTL = IsoMath.project({ x: winX0, y: 0, z: winZ1 });
      const wTR = IsoMath.project({ x: winX1, y: 0, z: winZ1 });
      const wBR = IsoMath.project({ x: winX1, y: 0, z: winZ0 });
      const wBL = IsoMath.project({ x: winX0, y: 0, z: winZ0 });

      // Moldura chanfrada de madeira escura
      const framePad = 4.0;
      const fTL = IsoMath.project({ x: winX0 - framePad, y: 0, z: winZ1 + framePad });
      const fTR = IsoMath.project({ x: winX1 + framePad, y: 0, z: winZ1 + framePad });
      const fBR = IsoMath.project({ x: winX1 + framePad, y: 0, z: winZ0 - framePad });
      const fBL = IsoMath.project({ x: winX0 - framePad, y: 0, z: winZ0 - framePad });

      this._gWalls.poly([fTL.x, fTL.y, fTR.x, fTR.y, fBR.x, fBR.y, fBL.x, fBL.y])
        .fill(0x3e2723)
        .stroke({ color: 0x1d110d, width: 1.5 });

      // Vidro da janela (azul crepúsculo profundo)
      this._gWalls.poly([wTL.x, wTL.y, wTR.x, wTR.y, wBR.x, wBR.y, wBL.x, wBL.y])
        .fill(0x132838)
        .stroke({ color: 0x09141c, width: 1.2 });

      // Esquadria da janela em cruz
      const winMidX = (winX0 + winX1) * 0.5;
      const winMidZ = (winZ0 + winZ1) * 0.5;
      const vTop = IsoMath.project({ x: winMidX, y: 0, z: winZ1 });
      const vBot = IsoMath.project({ x: winMidX, y: 0, z: winZ0 });
      const hLeft = IsoMath.project({ x: winX0, y: 0, z: winMidZ });
      const hRight = IsoMath.project({ x: winX1, y: 0, z: winMidZ });

      this._gWalls.moveTo(vTop.x, vTop.y).lineTo(vBot.x, vBot.y).stroke({ color: 0x4e342e, width: 2.2 });
      this._gWalls.moveTo(hLeft.x, hLeft.y).lineTo(hRight.x, hRight.y).stroke({ color: 0x4e342e, width: 2.2 });

      // Feixe de luz volumétrica (God Ray) no chão
      const rayFloor0 = IsoMath.gridToWorld(2.4, 2.0, 0, s);
      const rayFloor1 = IsoMath.gridToWorld(4.5, 3.2, 0, s);
      this._gWindowLight.poly([
        wBL.x, wBL.y,
        wBR.x, wBR.y,
        rayFloor1.x, rayFloor1.y,
        rayFloor0.x, rayFloor0.y,
      ])
      .fill({ color: 0x81d4fa, alpha: 0.08 });
    } else if (level.id === "banheiro") {
      // Janela basculante com vidro fosco de banheiro
      const winX0 = 4.2 * s;
      const winX1 = 5.8 * s;
      const winZ0 = 55.0;
      const winZ1 = 85.0;
      const wTL = IsoMath.project({ x: winX0, y: 0, z: winZ1 });
      const wTR = IsoMath.project({ x: winX1, y: 0, z: winZ1 });
      const wBR = IsoMath.project({ x: winX1, y: 0, z: winZ0 });
      const wBL = IsoMath.project({ x: winX0, y: 0, z: winZ0 });

      this._gWalls.poly([wTL.x, wTL.y, wTR.x, wTR.y, wBR.x, wBR.y, wBL.x, wBL.y])
        .fill(0xd0e8f4)
        .stroke({ color: 0x5a6470, width: 2.0 });
    }

    // 5. Instanciação Procedural dos Móveis a Partir de Obstacles
    for (const obs of level.obstacles) {
      this._spawnObstacleProp(obs, s);
    }

    // 6. Farol Sonoro de Objetivo (GoalAudioBeacon)
    this.beacon.setup(level.beaconSoundId, { x: level.goalPos.x, y: level.goalPos.y });
    this.beacon.start();
  }

  private _spawnObstacleProp(obs: ObstacleDef, s: number): void {
    switch (obs.type) {
      case "bed": {
        const bed = FurnitureRenderer.createBed(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(bed);
        this._furnitureContainers.push(bed);
        break;
      }
      case "nightstand": {
        const ns = FurnitureRenderer.createNightstand(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(ns.container);
        this._furnitureContainers.push(ns.container);
        this._updatables.push(ns.update);
        break;
      }
      case "clock": {
        const clk = FurnitureRenderer.createGrandfatherClock(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(clk.container);
        this._furnitureContainers.push(clk.container);
        this._updatables.push(clk.update);
        break;
      }
      case "armchair": {
        const ac = FurnitureRenderer.createArmchair(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(ac);
        this._furnitureContainers.push(ac);
        break;
      }
      case "coffee_table": {
        const tt = FurnitureRenderer.createTeaTable(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(tt.container);
        this._furnitureContainers.push(tt.container);
        this._updatables.push(tt.update);
        break;
      }
      case "sink": {
        const sink = FurnitureRenderer.createBathroomSink(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(sink.container);
        this._furnitureContainers.push(sink.container);
        this._updatables.push(sink.update);
        break;
      }
      case "bathtub": {
        const bt = FurnitureRenderer.createBathtub(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(bt);
        this._furnitureContainers.push(bt);
        break;
      }
      case "toilet": {
        const wc = FurnitureRenderer.createToilet(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(wc);
        this._furnitureContainers.push(wc);
        break;
      }
      case "sofa": {
        const sofa = FurnitureRenderer.createSofa(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(sofa);
        this._furnitureContainers.push(sofa);
        break;
      }
      case "bookcase": {
        const bc = FurnitureRenderer.createBookcase(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(bc);
        this._furnitureContainers.push(bc);
        break;
      }
      case "fireplace": {
        const fp = FurnitureRenderer.createFireplace(obs.gridX, obs.gridY, s);
        this.worldContainer.addChild(fp.container);
        this._furnitureContainers.push(fp.container);
        this._updatables.push(fp.update);
        break;
      }
      default:
        break;
    }
  }

  private _initDustMotes(): void {
    const count = 35;
    for (let i = 0; i < count; i++) {
      const bx = (Math.random() - 0.5) * 380;
      const by = (Math.random() - 0.5) * 240;
      this._dustMotes.push({
        baseX: bx,
        baseY: by,
        x: bx,
        y: by,
        speed: 0.3 + Math.random() * 0.5,
        phase: Math.random() * Math.PI * 2,
        radius: 1.0 + Math.random() * 1.5,
        alpha: 0.2 + Math.random() * 0.45,
      });
    }
  }

  public triggerAcousticPulse(noteKey: string, originGrid?: Vector2): void {
    const origin = originGrid ? IsoMath.gridToWorld(originGrid.x, originGrid.y, 0, this.step) : this.arthur.worldPos;
    const colorHex = ColorSchemeManager.getInstance().getColorHexNumber(noteKey);

    this._shockwaves.push({
      x: origin.x,
      y: origin.y,
      radius: 8,
      maxRadius: 240,
      colorHex,
      alpha: 0.95,
      speed: 210,
    });
  }

  public triggerTactileProbe(originWorld?: Vector2): void {
    const pos = originWorld || this.arthur.getCaneTipWorldPos();
    this._shockwaves.push({
      x: pos.x,
      y: pos.y,
      radius: 6,
      maxRadius: 180,
      colorHex: 0x00e5ff,
      alpha: 1.0,
      speed: 280,
    });
    this.spawnDustPuff(pos, 3);
  }

  public triggerFocusGuide(targetGrid?: Vector2): void {
    const target = targetGrid || this.currentLevel.goalPos;
    const targetWorld = IsoMath.gridToWorld(target.x + 0.5, target.y + 0.5, 0, this.step);
    this._focusGuide = {
      fromX: this.arthur.worldPos.x,
      fromY: this.arthur.worldPos.y - 20,
      toX: targetWorld.x,
      toY: targetWorld.y - 15,
      alpha: 1.0,
      pulsePhase: 0,
    };
  }

  public spawnDustPuff(worldPos: Vector2, count: number = 4): void {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 12 + Math.random() * 24;
      this._dustPuffs.push({
        x: worldPos.x + (Math.random() - 0.5) * 8,
        y: worldPos.y + (Math.random() - 0.5) * 4,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed * 0.5,
        radius: 2.0 + Math.random() * 2.5,
        alpha: 0.75,
        life: 0,
        maxLife: 0.35 + Math.random() * 0.25,
      });
    }
  }

  public triggerWallBounce(_dir?: Vector2): void {
    this.wallFlashAlpha = 0.55;
    this.screenShake = 6.0;
  }

  public update(dt: number, totalTime: number): void {
    this.arthur.update(dt);
    this.beacon.update(dt);

    for (const updateFn of this._updatables) {
      updateFn(totalTime);
    }

    if (this.screenShake > 0) {
      this.screenShake = Math.max(0, this.screenShake - dt * 18.0);
    }
    if (this.wallFlashAlpha > 0) {
      this.wallFlashAlpha = Math.max(0, this.wallFlashAlpha - dt * 2.2);
    }

    // Ondas de choque acústicas com anel duplo
    this._gWaves.clear();
    for (let i = this._shockwaves.length - 1; i >= 0; i--) {
      const sw = this._shockwaves[i];
      sw.radius += sw.speed * dt;
      sw.alpha = Math.max(0, 1.0 - sw.radius / sw.maxRadius);

      if (sw.alpha <= 0 || sw.radius >= sw.maxRadius) {
        this._shockwaves.splice(i, 1);
        continue;
      }

      this._gWaves.ellipse(sw.x, sw.y, sw.radius, sw.radius * 0.5)
        .stroke({ color: sw.colorHex, width: 2.5, alpha: sw.alpha });

      if (sw.radius > 16) {
        this._gWaves.ellipse(sw.x, sw.y, sw.radius - 8, (sw.radius - 8) * 0.5)
          .stroke({ color: 0xffffff, width: 1.2, alpha: sw.alpha * 0.5 });
      }
    }

    // Guia acústico dourado/ciano traçado entre o Sr. Arthur e o Farol Sonoro
    this._gFocusGuide.clear();
    if (this._focusGuide) {
      this._focusGuide.alpha = Math.max(0, this._focusGuide.alpha - dt * 0.9);
      this._focusGuide.pulsePhase += dt * 6.0;

      if (this._focusGuide.alpha <= 0) {
        this._focusGuide = null;
      } else {
        const fg = this._focusGuide;
        const beamPulse = 0.7 + 0.3 * Math.sin(fg.pulsePhase);
        this._gFocusGuide.moveTo(fg.fromX, fg.fromY).lineTo(fg.toX, fg.toY)
          .stroke({ color: 0xffd54f, width: 2.5 * beamPulse, alpha: fg.alpha * 0.75 });

        this._gFocusGuide.moveTo(fg.fromX, fg.fromY).lineTo(fg.toX, fg.toY)
          .stroke({ color: 0xffffff, width: 1.0, alpha: fg.alpha * 0.9 });
      }
    }

    // Puffs de poeira nos passos rápidos e aterrissagens
    this._gDustPuffs.clear();
    for (let i = this._dustPuffs.length - 1; i >= 0; i--) {
      const dp = this._dustPuffs[i];
      dp.life += dt;
      if (dp.life >= dp.maxLife) {
        this._dustPuffs.splice(i, 1);
        continue;
      }
      dp.x += dp.vx * dt;
      dp.y += dp.vy * dt;
      const progress = dp.life / dp.maxLife;
      const alpha = (1.0 - progress) * dp.alpha;
      const r = dp.radius * (1.0 + progress * 0.8);
      this._gDustPuffs.circle(dp.x, dp.y, r).fill({ color: 0xdeb887, alpha });
    }

    // Partículas de poeira suspensa na luz do ambiente
    this._gDust.clear();
    for (const m of this._dustMotes) {
      m.phase += dt * m.speed;
      m.x = m.baseX + Math.sin(m.phase) * 12;
      m.y = m.baseY + Math.cos(m.phase * 0.7) * 8;
      const pulseA = m.alpha * (0.6 + 0.4 * Math.sin(m.phase * 2));
      this._gDust.circle(m.x, m.y, m.radius).fill({ color: 0xfff8e1, alpha: pulseA });
    }

    // Flash e tremor de colisão com a parede
    this._gWallFlash.clear();
    if (this.wallFlashAlpha > 0.01) {
      this._gWallFlash.rect(-800, -800, 1600, 1600)
        .fill({ color: 0xef5350, alpha: this.wallFlashAlpha * 0.35 });
    }
  }
}
