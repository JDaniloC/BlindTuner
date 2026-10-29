import { Container, Graphics } from "pixi.js";
import { IsoMath, Vector2 } from "../core/iso";

export class ArthurRig {
  public readonly container: Container;
  private readonly _gShadow: Graphics;
  private readonly _gTuningHalo: Graphics;
  private readonly _gChar: Graphics;

  // Estado de orientação e animação
  public gridPos: Vector2 = { x: 1, y: 6 };
  public worldPos: Vector2 = { x: 0, y: 0 };
  public facingAngle: number = Math.PI * 0.5; // frente (Sul)
  public targetAngle: number = Math.PI * 0.5;

  public animState: "idle" | "walk" | "run" | "jump" | "trip" | "cane_probe" | "listen" = "idle";
  public jumpElevation: number = 0;
  public isArmedRun: boolean = false;
  public isArmedJump: boolean = false;
  public actionProgress: number = 0;
  public actionDuration: number = 0.5;
  public tripReason: "wall" | "miss" = "wall";
  public headTiltRad: number = 0;
  public caneTipSpark: number = 0;

  public isWalking: boolean = false;
  public walkPhase: number = 0;
  public breathPhase: number = 0;
  public isTuning: boolean = false;
  public tuningColorHex: number = 0xf59e0b;
  public isHoldingCello: boolean = true; // Por padrão, o Sr. Arthur empunha seu violoncelo de mestre
  public scaleFactor: number = 1.68; // Escala nobre, expressiva e detalhada

  // =========================================================================
  // PALETA DO MESTRE LUTHIER (Inspirada no ProceduralArthur25D do Godot)
  // =========================================================================
  private readonly COL_OUTLINE = 0x1a120c;       // Contorno espresso escuro de recorte artesanal
  private readonly COL_SKIN_BASE = 0xfad8bc;     // Pêssego acolhedor suave
  private readonly COL_SKIN_SHADOW = 0xe0b89a;   // Sombra quente da pele
  private readonly COL_BLUSH = 0xeb948b;         // Rubor rosado nas bochechas de vovô
  private readonly COL_HAIR = 0xffffff;          // Cabelo e bigode brancos de algodão
  private readonly COL_HAIR_SH = 0xd1d8e0;       // Mechas prateadas sombreadas
  private readonly COL_MUSTACHE_SH = 0x3a190e;   // Vinco labial escuro profundo sob o bigode (separação nítida)

  // Alfaiataria: Cardigã/Sobretudo Terracota Quente + Nogueira
  private readonly COL_COAT = 0x8f4733;          // Terracota quente de violoncelo nobre
  private readonly COL_COAT_SH = 0x6b3324;       // Sombra volumétrica do sobretudo
  private readonly COL_COAT_HI = 0xa85c42;       // Nervura e realce de luz
  private readonly COL_TRIM = 0x361c12;          // Lapela e cotoveleiras em nogueira nobre/couro
  private readonly COL_VEST = 0x182432;          // Colete de alfaiataria em azul petróleo nobre
  private readonly COL_SHIRT_CREAM = 0xd1e0f0;   // Camisa azul chambray suave
  private readonly COL_SCARF = 0x7b98b2;         // Cachecol de lã de concerto
  private readonly COL_SCARF_SH = 0x546e85;      // Sombra do cachecol

  // Metais nobres e Jóias
  private readonly COL_GOLD = 0xfbc02d;          // Latão polido, corrente Albert de ouro, broche
  private readonly COL_BUTTON_PEARL = 0xfffdf6;  // Botões de madrepérola

  // Óculos Escuros Virtuoso (estilo Ray Charles / Mestre Cego)
  private readonly COL_SHADES = 0x141218;        // Armação acetinada escura
  private readonly COL_SHADES_LENS = 0x24202c;   // Lente escura translúcida
  private readonly COL_SHADES_SPEC = 0xffffff;   // Duplo corte de reflexo especular estilizado

  // Boina Flat Cap de Lã Tweed
  private readonly COL_CAP = 0x4a3c31;           // Lã tweed cáqui/taupe
  private readonly COL_CAP_SH = 0x2e241c;        // Sombra da boina

  // Calças e Calçados
  private readonly COL_PANTS = 0x2e3238;         // Lã grafite tweed carvão
  private readonly COL_PANTS_CUFF = 0x3e424c;    // Dobra da barra
  private readonly COL_SHOE = 0x3a2012;          // Sapatos Oxford couro café escuro
  private readonly COL_SHOE_SOLE = 0x140c06;     // Sola escura
  private readonly COL_SHOE_SHINE = 0x6e4226;    // Brilho na biqueira

  // Violoncelo de Concerto
  private readonly COL_CELLO_TOP = 0x9e5229;     // Tampo dourado de abeto envernizado
  private readonly COL_CELLO_BACK = 0x4a230e;    // Fundo mogno escuro envernizado
  private readonly COL_CELLO_RIB = 0x361808;     // Faixas laterais (ribs)
  private readonly COL_CELLO_BRIDGE = 0xe8c79b;  // Cavalete de bordo claro
  private readonly COL_CELLO_EBONY = 0x140e0b;   // Espelho e estandarte de ébano

  constructor() {
    this.container = new Container();
    this.container.scale.set(this.scaleFactor, this.scaleFactor);

    this._gShadow = new Graphics();
    this._gTuningHalo = new Graphics();
    this._gChar = new Graphics();

    this.container.addChild(this._gShadow);
    this.container.addChild(this._gTuningHalo);
    this.container.addChild(this._gChar);

    this.snapToGrid(1, 6);
  }

  public snapToGrid(gx: number, gy: number, step: number = 44): void {
    this.gridPos = { x: gx, y: gy };
    this.worldPos = IsoMath.gridToWorld(gx, gy, 0, step);
    this.container.position.set(this.worldPos.x, this.worldPos.y);
    this.updateZIndex(step);
  }

  public updateZIndex(step: number = 44): void {
    this.container.zIndex = IsoMath.depthOf({
      x: this.gridPos.x * step + step * 0.5,
      y: this.gridPos.y * step + step * 0.5,
      z: 0,
    }) + 0.15;
  }

  public setTuning(active: boolean, angleRad: number, colorHex: number = 0xf59e0b): void {
    this.isTuning = active;
    this.targetAngle = angleRad;
    this.tuningColorHex = colorHex;
    this.isHoldingCello = true; // Mantém empunhado tocando o arco
    if (active) {
      this.animState = "idle";
    }
  }

  public triggerCaneProbe(): void {
    this.animState = "cane_probe";
    this.actionProgress = 0;
    this.actionDuration = 0.55;
    this.isHoldingCello = false;
    this.caneTipSpark = 1.0;
  }

  public triggerListenFocus(): void {
    this.animState = "listen";
    this.actionProgress = 0;
    this.actionDuration = 0.70;
    this.isHoldingCello = false;
  }

  public triggerTrip(reason: "wall" | "miss" = "wall"): void {
    this.animState = "trip";
    this.tripReason = reason;
    this.actionProgress = 0;
    this.actionDuration = 0.60;
    this.isArmedRun = false;
    this.isArmedJump = false;
    this.isHoldingCello = false;
  }

  public setArmedState(running: boolean, jumping: boolean): void {
    this.isArmedRun = running;
    this.isArmedJump = jumping;
  }

  public setJumpProgress(progress: number, arcHeight: number = 20): void {
    if (progress <= 0 || progress >= 1) {
      this.jumpElevation = 0;
      if (this.animState === "jump") {
        this.animState = "idle";
      }
    } else {
      this.animState = "jump";
      this.jumpElevation = Math.sin(progress * Math.PI) * arcHeight;
    }
  }

  public getCaneTipWorldPos(): Vector2 {
    const cosA = Math.cos(this.facingAngle);
    const sinA = Math.sin(this.facingAngle);
    // Ponta da bengala projetada no chão à frente
    const fwd = 18.0 * this.scaleFactor;
    const right = 8.0 * this.scaleFactor;
    const wx = cosA * fwd - sinA * right;
    const wy = (sinA * fwd + cosA * right) * 0.5;
    return {
      x: this.worldPos.x + wx,
      y: this.worldPos.y + wy,
    };
  }

  public update(dt: number): void {
    // Rotação suave contínua em 360° via menor arco trigonométrico
    let diff = (this.targetAngle - this.facingAngle) % (Math.PI * 2);
    if (diff > Math.PI) diff -= Math.PI * 2;
    if (diff < -Math.PI) diff += Math.PI * 2;
    this.facingAngle += diff * Math.min(1.0, dt * 16.0);

    this.breathPhase = (this.breathPhase + dt * 2.2) % (Math.PI * 2);

    if (this.caneTipSpark > 0) {
      this.caneTipSpark = Math.max(0, this.caneTipSpark - dt * 2.5);
    }

    // Atualização de ações transitórias
    if (this.animState === "cane_probe" || this.animState === "listen" || this.animState === "trip") {
      this.actionProgress += dt / this.actionDuration;
      if (this.actionProgress >= 1.0) {
        this.actionProgress = 0;
        this.animState = "idle";
        this.headTiltRad = 0;
      }
    }

    const isMoving = this.isWalking || this.animState === "walk" || this.animState === "run";
    const walkSpeed = this.animState === "run" ? 15.0 : 9.5;

    if (isMoving) {
      this.walkPhase = (this.walkPhase + dt * walkSpeed) % (Math.PI * 2);
    } else {
      this.walkPhase = 0;
    }

    this._render();
  }

  /**
   * Converte coordenadas locais do personagem (fwd = frente, right = direita, z = altura)
   * em coordenadas de tela com rotação isométrica 2:1 contínua.
   */
  private _charToScreen(fwd: number, right: number, zHeight: number): Vector2 {
    const cosA = Math.cos(this.facingAngle);
    const sinA = Math.sin(this.facingAngle);
    const horizX = cosA * fwd - sinA * right;
    const horizY = sinA * fwd + cosA * right;
    return {
      x: horizX,
      y: horizY * 0.5 - zHeight,
    };
  }

  /**
   * Chave de ordenação de profundidade individual (Z-sort) de cada membro/acessório.
   */
  private _charDepth(fwd: number, right: number, zBias: number = 0.0): number {
    const sinA = Math.sin(this.facingAngle);
    const cosA = Math.cos(this.facingAngle);
    const horizY = sinA * fwd + cosA * right;
    return horizY + zBias;
  }

  private _render(): void {
    const cosA = Math.cos(this.facingAngle);
    const sinA = Math.sin(this.facingAngle);
    const isFacingFront = sinA > -0.22;

    // 1. Sombra de contato no chão com redução de escala no salto
    const jumpScale = Math.max(0.40, 1.0 - (this.jumpElevation / 28.0) * 0.45);
    const shadowAlpha = (this.jumpElevation > 0.1 ? 0.20 : 0.40) * jumpScale;
    this._gShadow.clear();
    this._gShadow.ellipse(0, 0, 20 * jumpScale, 10 * jumpScale).fill({ color: 0x050711, alpha: shadowAlpha });
    this._gShadow.ellipse(0, 0, 14 * jumpScale, 7 * jumpScale).fill({ color: 0x030408, alpha: shadowAlpha * 0.7 });

    // 2. Halo Harmônico 360° e Auras de Estado Armado
    this._gTuningHalo.clear();

    // Aura armada de Corrida (Índigo/Âmbar)
    if (this.isArmedRun) {
      const pulse = 1.0 + Math.sin(this.breathPhase * 3.5) * 0.15;
      const r = 24 * pulse;
      this._gTuningHalo.ellipse(0, 0, r, r * 0.5)
        .stroke({ color: 0x3949ab, width: 2.5, alpha: 0.9 })
        .fill({ color: 0x3949ab, alpha: 0.22 });
      const dirFwdX = cosA * 26;
      const dirFwdY = sinA * 13;
      this._gTuningHalo.moveTo(0, 0).lineTo(dirFwdX, dirFwdY)
        .stroke({ color: 0xffd54f, width: 2.2, alpha: 0.85 });
      this._gTuningHalo.circle(dirFwdX, dirFwdY, 3.5).fill(0xffd54f);
    }

    // Aura armada de Salto (Verde Esmeralda)
    if (this.isArmedJump) {
      const pulse = 1.0 + Math.cos(this.breathPhase * 3.8) * 0.18;
      const r = 22 * pulse;
      this._gTuningHalo.ellipse(0, 0, r, r * 0.5)
        .stroke({ color: 0x7cb342, width: 2.5, alpha: 0.9 })
        .fill({ color: 0x7cb342, alpha: 0.22 });
      this._gTuningHalo.ellipse(0, 0, r * 0.65, r * 0.325)
        .stroke({ color: 0xaed581, width: 1.5, alpha: 0.7 });
    }

    // Centelha de contato tátil da bengala
    if (this.caneTipSpark > 0) {
      const tip = this._charToScreen(18.0, 4.0, 0.0);
      this._gTuningHalo.circle(tip.x, tip.y, 6.0 * this.caneTipSpark)
        .fill({ color: 0xffffff, alpha: 0.85 * this.caneTipSpark });
      this._gTuningHalo.circle(tip.x, tip.y, 12.0 * this.caneTipSpark)
        .stroke({ color: 0x00e5ff, width: 2.0, alpha: 0.75 * this.caneTipSpark });
    }

    // Halo Harmônico durante afinação contínua no Scroll
    if (this.isTuning) {
      const haloR = 32;
      this._gTuningHalo.ellipse(0, 0, haloR, haloR * 0.5)
        .stroke({ color: this.tuningColorHex, width: 2.5, alpha: 0.85 })
        .fill({ color: this.tuningColorHex, alpha: 0.16 });

      this._gTuningHalo.ellipse(0, 0, haloR + 6, (haloR + 6) * 0.5)
        .stroke({ color: this.tuningColorHex, width: 1.0, alpha: 0.35 });

      // Marcador de pontaria vetorial na direção de rotação exata
      const dirX = cosA * 36;
      const dirY = sinA * 18;
      this._gTuningHalo.circle(dirX, dirY, 4.5)
        .fill(0xffffff)
        .stroke({ color: this.tuningColorHex, width: 2.0 });

      this._gTuningHalo.moveTo(0, 0).lineTo(dirX, dirY)
        .stroke({ color: this.tuningColorHex, width: 1.5, alpha: 0.75 });
    }

    // 3. Renderização Multi-Camadas com Z-Sort individual
    this._gChar.clear();
    const g = this._gChar;

    const isMoving = this.isWalking || this.animState === "walk" || this.animState === "run";
    const strideAmp = this.animState === "run" ? 7.2 : 5.2;
    const liftAmp = this.animState === "run" ? 4.8 : 3.4;

    let bobZ = isMoving ? Math.abs(Math.sin(this.walkPhase)) * 2.4 : Math.sin(this.breathPhase) * 0.6;
    if (this.animState === "jump") {
      bobZ += this.jumpElevation;
    } else if (this.animState === "trip") {
      bobZ = -3.2 + Math.sin(this.actionProgress * Math.PI * 4) * 2.2;
    } else if (this.isArmedJump && !isMoving) {
      bobZ -= 3.2; // agachamento preparatório de salto
    } else if (this.animState === "cane_probe") {
      bobZ -= 1.0;
    }

    const sPhase = isMoving ? Math.sin(this.walkPhase) : 0.0;
    const torsoZ = 18.0 + bobZ;
    const fL = sPhase * strideAmp;
    const fR = -sPhase * strideAmp;
    const liftL = isMoving ? Math.max(0.0, Math.sin(this.walkPhase)) * liftAmp : 0.0;
    const liftR = isMoving ? Math.max(0.0, -Math.sin(this.walkPhase)) * liftAmp : 0.0;

    interface RenderLayer {
      depth: number;
      draw: () => void;
    }
    const layers: RenderLayer[] = [];

    // CAMADA A: Pernas e Sapatos Oxford
    layers.push({
      depth: this._charDepth(fL, -3.8, -6.0),
      draw: () => this._drawShoe(g, -3.8, fL, liftL),
    });
    layers.push({
      depth: this._charDepth(fR, 3.8, -6.0),
      draw: () => this._drawShoe(g, 3.8, fR, liftR),
    });

    // CAMADA B: Saia fluida do Sobretudo Terracota em A-Line
    layers.push({
      depth: this._charDepth(0.0, 0.0, -2.0),
      draw: () => this._drawOvercoatSkirt(g, torsoZ, bobZ, sPhase),
    });

    // CAMADA C: Tronco do Sobretudo com Colete Azul, Corrente Albert, Diapasão e Lapelas
    layers.push({
      depth: this._charDepth(0.0, 0.0, 0.0),
      draw: () => this._drawOvercoatTorso(g, torsoZ, isFacingFront, cosA),
    });

    // CAMADA D: Cachecol de Concerto com Franjas
    layers.push({
      depth: this._charDepth(2.5, 0.0, 1.5),
      draw: () => this._drawConcertScarf(g, torsoZ, isFacingFront, cosA),
    });

    // CAMADA E: Braços e Instrumento (Cello / Bengala / Poses de Ação Especiais)
    const showCello = this.isHoldingCello && !isMoving && this.animState !== "cane_probe" && this.animState !== "listen" && this.animState !== "trip";

    if (showCello) {
      // 1. Braço esquerdo segurando o braço/espelho do violoncelo
      layers.push({
        depth: this._charDepth(4.5, -5.2, torsoZ + 2.0),
        draw: () => this._drawArmCelloHolding(g, torsoZ),
      });

      // 2. O Violoncelo projetado em 3D rigoroso acompanhando a rotação do corpo em 360°!
      layers.push({
        depth: this._charDepth(6.0, -1.0, torsoZ - 1.0),
        draw: () => this._drawCello3DRotating(g, torsoZ, sinA, cosA),
      });

      // 3. Braço direito e arco sobre as cordas
      layers.push({
        depth: this._charDepth(7.5, 5.8, torsoZ - 0.5),
        draw: () => this._drawBowAndArm3D(g, torsoZ),
      });
    } else if (this.animState === "cane_probe") {
      // POSE 1: TATEAR COM A BENGALA (Varredura dinâmica na frente com centelhas)
      const sweepFactor = Math.sin(this.actionProgress * Math.PI);
      const sweepLateral = (0.5 - sweepFactor) * 16.0;
      const pHandR = this._charToScreen(13.0, 7.0, torsoZ - 1.5);
      const pCaneTip = this._charToScreen(20.0, 4.0 + sweepLateral, 0.0);

      layers.push({
        depth: this._charDepth(1.5, -8.6, 1.0),
        draw: () => this._drawArm(g, -7.8, -7.6, 1.5, torsoZ + 4.2, torsoZ - 2.0),
      });
      layers.push({
        depth: this._charDepth(13.0, 7.0, 2.0),
        draw: () => this._drawArm(g, 7.8, 7.0, 13.0, torsoZ + 4.2, torsoZ - 1.5),
      });
      layers.push({
        depth: this._charDepth(18.0, 6.0, 3.0),
        draw: () => this._drawCane(g, pHandR, pCaneTip, 0.0),
      });
    } else if (this.animState === "listen") {
      // POSE 2: ESCUTAR COM ATENÇÃO (Mão na orelha, cabeça inclinada, foco acústico)
      const pShL = this._charToScreen(0.0, -7.8, torsoZ + 4.2);
      const pEarL = this._charToScreen(0.0, -8.6, torsoZ + 14.0);

      layers.push({
        depth: this._charDepth(0.0, -8.6, torsoZ + 14.0),
        draw: () => {
          g.moveTo(pShL.x, pShL.y).lineTo(pEarL.x - 2.0, pEarL.y + 3.0).stroke({ color: this.COL_OUTLINE, width: 5.6 });
          g.moveTo(pShL.x, pShL.y).lineTo(pEarL.x - 2.0, pEarL.y + 3.0).stroke({ color: this.COL_COAT, width: 4.2 });
          g.ellipse((pShL.x + pEarL.x) * 0.5 - 2.5, (pShL.y + pEarL.y) * 0.5 + 1.0, 2.6, 1.8).fill(this.COL_TRIM);
          g.circle(pEarL.x, pEarL.y, 3.2).fill(this.COL_SKIN_BASE).stroke({ color: this.COL_OUTLINE, width: 0.9 });
          g.arc(pEarL.x + 0.5, pEarL.y, 2.2, -Math.PI * 0.4, Math.PI * 0.4).stroke({ color: this.COL_SKIN_SHADOW, width: 1.2 });
        },
      });

      const pHandR = this._charToScreen(4.0, 8.0, torsoZ - 3.0);
      const pCaneTip = this._charToScreen(12.0, 10.0, 0.0);
      layers.push({
        depth: this._charDepth(4.0, 8.0, 1.0),
        draw: () => this._drawArm(g, 7.8, 8.0, 4.0, torsoZ + 4.2, torsoZ - 3.0),
      });
      layers.push({
        depth: this._charDepth(10.0, 9.0, 2.0),
        draw: () => this._drawCane(g, pHandR, pCaneTip, 0.0),
      });
    } else if (this.animState === "trip") {
      // POSE 3: TROPEÇO / RECUO (Braços abertos em surpresa, bengala erguida)
      const flailL = Math.sin(this.actionProgress * Math.PI * 6) * 4.0;
      const flailR = -Math.sin(this.actionProgress * Math.PI * 6) * 4.0;
      const pHandR = this._charToScreen(-3.0, 11.0 + flailR, torsoZ + 8.0);
      const pCaneTip = this._charToScreen(8.0, 15.0, torsoZ + 14.0);

      layers.push({
        depth: this._charDepth(-3.0, -11.0, 2.0),
        draw: () => this._drawArm(g, -7.8, -11.0 + flailL, -3.0, torsoZ + 4.2, torsoZ + 6.0),
      });
      layers.push({
        depth: this._charDepth(-3.0, 11.0, 2.0),
        draw: () => this._drawArm(g, 7.8, 11.0 + flailR, -3.0, torsoZ + 4.2, torsoZ + 8.0),
      });
      layers.push({
        depth: this._charDepth(5.0, 14.0, 3.0),
        draw: () => this._drawCane(g, pHandR, pCaneTip, torsoZ + 14.0),
      });
    } else {
      // Modo Caminhada ou Repouso Padrão: Bengala de Guia Tátil Longa
      const armSwing = isMoving ? -sPhase * 3.8 : 0.0;
      const handLF = 1.6 + armSwing;
      const handRF = 5.2 - armSwing * 0.4;

      layers.push({
        depth: this._charDepth(handLF, -8.6, 1.0),
        draw: () => this._drawArm(g, -7.8, -8.6, handLF, torsoZ + 4.2, torsoZ - 3.0),
      });
      layers.push({
        depth: this._charDepth(handRF, 8.6, 1.0),
        draw: () => this._drawArm(g, 7.8, 8.6, handRF, torsoZ + 4.2, torsoZ - 2.0),
      });

      const caneLift = isMoving ? Math.max(0.0, Math.cos(this.walkPhase)) * 2.4 : 0.0;
      const pHandR = this._charToScreen(handRF, 8.6, torsoZ - 2.0);
      const pCaneTip = this._charToScreen(16.0, 9.8, caneLift);

      layers.push({
        depth: this._charDepth(11.5, 9.5, 3.0),
        draw: () => this._drawCane(g, pHandR, pCaneTip, caneLift),
      });
    }

    // CAMADA F: Cabeça Anatômica com Boina Tweed, Óculos Virtuoso Wayfarer e Bigode de Morsa
    const headZ = torsoZ + 14.0;
    layers.push({
      depth: 100.0, // Cabeça sempre no topo relativo do tronco
      draw: () => this._drawHeadAnatomical(g, headZ, isFacingFront, cosA, sinA),
    });

    // Ordenação e desenho em ordem Painter's Algorithm
    layers.sort((a, b) => a.depth - b.depth);
    for (const item of layers) {
      item.draw();
    }
  }

  // =========================================================================
  // SUB-MÉTODOS DE DESENHO ARTESANAL PAPER-CUTOUT DE ALTA DEFINIÇÃO
  // =========================================================================

  private _drawShoe(g: Graphics, rightOfs: number, fwdOfs: number, footLift: number): void {
    const pAnkle = this._charToScreen(fwdOfs, rightOfs, footLift + 2.2);
    const pToe = this._charToScreen(fwdOfs + 4.2, rightOfs, footLift + 0.6);

    // Sombra de contato do sapato
    g.poly([pAnkle.x + 1.2, pAnkle.y + 1.8, pToe.x + 1.2, pToe.y + 1.8, pToe.x, pToe.y, pAnkle.x, pAnkle.y])
      .fill({ color: 0x050307, alpha: 0.22 });

    // Sola de borracha escura
    g.moveTo(pAnkle.x, pAnkle.y + 1.5).lineTo(pToe.x, pToe.y + 1.5)
      .stroke({ color: this.COL_SHOE_SOLE, width: 4.8 });

    // Corpo de couro café
    g.moveTo(pAnkle.x, pAnkle.y).lineTo(pToe.x, pToe.y)
      .stroke({ color: this.COL_SHOE, width: 4.4 });

    // Brilho na biqueira (Cap-Toe)
    g.circle(pToe.x - 0.4, pToe.y - 0.6, 1.4).fill(this.COL_SHOE_SHINE);

    // Perna/tornozelo da calça grafite tweed sob o sobretudo
    g.moveTo(pAnkle.x, pAnkle.y - 4.2).lineTo(pAnkle.x, pAnkle.y - 1.0)
      .stroke({ color: this.COL_PANTS, width: 4.0 });

    // Dobra da barra da calça grafite tweed
    g.moveTo(pAnkle.x - 2.0, pAnkle.y - 1.0).lineTo(pAnkle.x + 2.0, pAnkle.y - 1.0)
      .stroke({ color: this.COL_PANTS_CUFF, width: 2.2 });
  }

  private _drawOvercoatSkirt(g: Graphics, torsoZ: number, bobZ: number, sPhase: number): void {
    const yWaist = -(torsoZ - 4.5);
    const yHem = -(2.6 + bobZ);
    const wWaist = 8.4;
    const wHem = 13.8;

    const sway = this.isWalking ? sPhase * 2.8 : Math.sin(this.breathPhase) * 0.5;
    const cx = Math.cos(this.facingAngle) * 4.8;

    const pWL = { x: -wWaist, y: yWaist };
    const pWR = { x: wWaist, y: yWaist };
    const pHR = { x: wHem + sway * 0.4, y: yHem };
    const pHC = { x: cx * 0.5 + sway * 0.8, y: yHem + (Math.sin(this.facingAngle) >= -0.2 ? 1.6 : -1.2) };
    const pHL = { x: -wHem + sway * 0.4, y: yHem };

    const skirtPts = [pWL.x, pWL.y, pWR.x, pWR.y, pHR.x, pHR.y, pHC.x, pHC.y, pHL.x, pHL.y];

    // Sombra de recorte
    g.poly([pWL.x + 1.5, pWL.y + 2.0, pWR.x + 1.5, pWR.y + 2.0, pHR.x + 1.5, pHR.y + 2.0, pHC.x + 1.5, pHC.y + 2.0, pHL.x + 1.5, pHL.y + 2.0])
      .fill({ color: 0x050307, alpha: 0.22 });

    // Tecido terracota quente
    g.poly(skirtPts).fill(this.COL_COAT);
    // Sombra lateral direita
    g.poly([1.5, yWaist, pWR.x, pWR.y, pHR.x, pHR.y, pHC.x, pHC.y]).fill(this.COL_COAT_SH);
    // Contorno
    g.poly(skirtPts).stroke({ color: this.COL_OUTLINE, width: 1.4 });

    // Pesponto pontilhado de alfaiataria na barra
    for (let s = 0; s < 6; s++) {
      const frac = s / 5;
      const spX = pHL.x + (pHR.x - pHL.x) * frac;
      const spY = yHem - 1.8;
      g.moveTo(spX, spY).lineTo(spX, spY + 1.0).stroke({ color: this.COL_COAT_SH, width: 1.0 });
    }

    // Fenda traseira quando de costas
    if (Math.sin(this.facingAngle) < -0.15) {
      g.moveTo(0, yWaist).lineTo(pHC.x, pHC.y).stroke({ color: this.COL_OUTLINE, width: 1.6 });
      g.moveTo(0, yWaist).lineTo(pHC.x, pHC.y).stroke({ color: this.COL_TRIM, width: 1.0 });
    } else {
      // Linha de transpasse frontal
      g.moveTo(cx, yWaist).lineTo(pHC.x, pHC.y).stroke({ color: this.COL_OUTLINE, width: 1.4 });
    }
  }

  private _drawOvercoatTorso(g: Graphics, torsoZ: number, isFacingFront: boolean, cosA: number): void {
    const pTop = { x: 0.0, y: -(torsoZ + 5.5) };
    const pBot = { x: 0.0, y: -(torsoZ - 4.8) };
    const rx = 8.6;
    const ry = 3.8;

    const bodyPts = [
      pTop.x - rx, pTop.y,
      pTop.x + rx, pTop.y,
      pBot.x + rx, pBot.y + 1.2,
      pBot.x, pBot.y + ry,
      pBot.x - rx, pBot.y + 1.2,
    ];

    // Sombra de recorte
    g.poly([pTop.x - rx + 1.5, pTop.y + 2.0, pTop.x + rx + 1.5, pTop.y + 2.0, pBot.x + rx + 1.5, pBot.y + 3.2, pBot.x + 1.5, pBot.y + ry + 2.0, pBot.x - rx + 1.5, pBot.y + 3.2])
      .fill({ color: 0x050307, alpha: 0.22 });

    g.poly(bodyPts).fill(this.COL_COAT);
    // Sombra volumétrica lateral
    g.poly([pTop.x + 1.5, pTop.y, pTop.x + rx, pTop.y, pBot.x + rx, pBot.y + 1.2, pBot.x + 1.5, pBot.y + ry * 0.8])
      .fill(this.COL_COAT_SH);
    // Nervuras sutis de realce de luz no sobretudo terracota
    g.moveTo(pTop.x - 4.0, pTop.y + 1.5).lineTo(pBot.x - 4.0, pBot.y + 0.5)
      .stroke({ color: this.COL_COAT_HI, width: 1.0, alpha: 0.75 });
    g.moveTo(pTop.x + 4.0, pTop.y + 1.5).lineTo(pBot.x + 4.0, pBot.y + 0.5)
      .stroke({ color: this.COL_COAT_HI, width: 1.0, alpha: 0.75 });
    g.poly(bodyPts).stroke({ color: this.COL_OUTLINE, width: 1.4 });

    if (isFacingFront) {
      const cx = cosA * 4.8;
      const pNeck = { x: cx, y: -(torsoZ + 4.8) };
      const pMid = { x: cx, y: -(torsoZ) };
      const pHem = { x: cx, y: -(torsoZ - 4.5) };

      // 1. Colete de Luthier em Azul Petróleo Nobre sob o sobretudo
      const vestPts = [
        pNeck.x - 3.4, pNeck.y - 0.6,
        pNeck.x + 3.4, pNeck.y - 0.6,
        pMid.x + 2.0, pMid.y,
        pMid.x - 2.0, pMid.y,
      ];
      g.poly(vestPts).fill(this.COL_VEST).stroke({ color: this.COL_OUTLINE, width: 1.0 });

      // 3 botõezinhos finos de madrepérola brilhante no colete
      for (let i = 0; i < 3; i++) {
        const t = 0.22 + i * 0.28;
        const by = pNeck.y + (pMid.y - pNeck.y) * t;
        g.circle(cx, by, 0.85).fill(this.COL_BUTTON_PEARL);
        g.circle(cx - 0.2, by - 0.2, 0.35).fill(0xffffff);
      }

      // Corrente Albert de ouro para relógio de bolso (curva catenária)
      const pChainStart = { x: cx, y: pNeck.y + (pMid.y - pNeck.y) * 0.5 };
      const pVestPocket = { x: cx - 2.8, y: pMid.y - 1.8 };
      g.moveTo(pChainStart.x, pChainStart.y)
        .bezierCurveTo(pChainStart.x - 1.5, pChainStart.y + 2.0, pVestPocket.x + 1.0, pVestPocket.y + 2.0, pVestPocket.x, pVestPocket.y)
        .stroke({ color: this.COL_GOLD, width: 1.2 });
      g.circle(pVestPocket.x, pVestPocket.y, 0.9).fill(this.COL_GOLD);

      // 2. Lapela de nogueira nobre em corte V
      const lapelL = [
        pNeck.x - 4.6, pNeck.y - 0.6,
        pNeck.x - 1.2, pNeck.y - 0.6,
        pMid.x - 0.4, pMid.y,
        pMid.x - 3.4, pMid.y - 2.4,
      ];
      const lapelR = [
        pNeck.x + 1.2, pNeck.y - 0.6,
        pNeck.x + 4.6, pNeck.y - 0.6,
        pMid.x + 3.4, pMid.y - 2.4,
        pMid.x + 0.4, pMid.y,
      ];
      g.poly(lapelL).fill(this.COL_TRIM).stroke({ color: this.COL_OUTLINE, width: 1.1 });
      g.poly(lapelR).fill(this.COL_TRIM).stroke({ color: this.COL_OUTLINE, width: 1.1 });

      // 3. Broche / Pin de Diapasão Dourado na lapela esquerda do mestre
      const pinX = cx - 2.8;
      const pinY = pNeck.y + 2.4;
      // Cabo do diapasão
      g.moveTo(pinX, pinY + 1.0).lineTo(pinX, pinY + 3.2).stroke({ color: this.COL_GOLD, width: 1.1 });
      g.circle(pinX, pinY + 3.6, 0.6).fill(this.COL_GOLD);
      // Hastes paralelas em U
      g.moveTo(pinX - 0.8, pinY - 1.6).lineTo(pinX - 0.8, pinY + 1.0).stroke({ color: this.COL_GOLD, width: 1.0 });
      g.moveTo(pinX + 0.8, pinY - 1.6).lineTo(pinX + 0.8, pinY + 1.0).stroke({ color: this.COL_GOLD, width: 1.0 });
      g.moveTo(pinX - 0.8, pinY + 1.0).lineTo(pinX + 0.8, pinY + 1.0).stroke({ color: this.COL_GOLD, width: 1.0 });
      g.circle(pinX - 0.8, pinY - 1.4, 0.35).fill(0xffffff);

      // 4. Lenço de bolso de seda branca (Pocket Square) no bolso superior
      const pPocketSq = { x: cx + 3.6, y: pNeck.y + 1.8 };
      g.moveTo(pPocketSq.x - 1.4, pPocketSq.y).lineTo(pPocketSq.x + 1.4, pPocketSq.y).stroke({ color: this.COL_TRIM, width: 1.4 });
      g.poly([pPocketSq.x - 0.8, pPocketSq.y, pPocketSq.x, pPocketSq.y - 1.6, pPocketSq.x + 0.8, pPocketSq.y]).fill(0xffffff);

      // 5. Botões duplos de latão com aro esculpido
      const bRatios = [0.25, 0.65];
      for (const r of bRatios) {
        const bpY = pMid.y + (pHem.y - pMid.y) * r;
        for (const s of [-1, 1]) {
          const bx = cx + s * 2.8;
          g.circle(bx, bpY, 1.4).fill(this.COL_OUTLINE);
          g.circle(bx, bpY, 1.1).fill(this.COL_GOLD);
          g.circle(bx - 0.3, bpY - 0.3, 0.45).fill(0xfff9c4);
        }
      }
    }
  }

  private _drawConcertScarf(g: Graphics, torsoZ: number, isFacingFront: boolean, cosA: number): void {
    const cx = cosA * 4.8;
    const neckY = -(torsoZ + 5.5);

    // Gola acolchoada do cachecol
    g.roundRect(cx - 6.5, neckY - 2.8, 13.0, 5.2, 2.5)
      .fill(this.COL_SCARF)
      .stroke({ color: this.COL_OUTLINE, width: 1.2 });

    if (isFacingFront) {
      const swayScarf = Math.sin(this.breathPhase * 1.5) * 0.8;
      const tailX = cx - 1.8;
      const tailY = neckY + 1.5;

      // Ponta esquerda drapeada
      g.poly([
        tailX - 2.6, tailY,
        tailX + 2.4, tailY,
        tailX + 1.8 + swayScarf, tailY + 8.8,
        tailX - 2.0 + swayScarf, tailY + 8.8,
      ]).fill(this.COL_SCARF).stroke({ color: this.COL_OUTLINE, width: 1.0 });

      // Listra de trama fina
      g.moveTo(tailX - 2.0 + swayScarf * 0.5, tailY + 5.5)
        .lineTo(tailX + 2.0 + swayScarf * 0.5, tailY + 5.5)
        .stroke({ color: this.COL_SHIRT_CREAM, width: 1.0 });

      // 4 franjas finas na ponta
      for (let f = 0; f < 4; f++) {
        const fx = tailX - 1.5 + f * 1.0 + swayScarf;
        g.moveTo(fx, tailY + 8.8).lineTo(fx + (f % 2 === 0 ? 0.4 : -0.4), tailY + 11.0)
          .stroke({ color: this.COL_SCARF_SH, width: 0.9 });
      }
    }
  }

  /**
   * Braço com manga terracota e Cotoveleira de Couro Nogueira
   */
  private _drawArm(g: Graphics, shoulderR: number, handR: number, handF: number, zSh: number, zHand: number): void {
    const pSh = this._charToScreen(0.0, shoulderR, zSh);
    const pHand = this._charToScreen(handF, handR, zHand);
    const pElbow = {
      x: (pSh.x + pHand.x) * 0.5,
      y: (pSh.y + pHand.y) * 0.5 + 1.2,
    };

    // Sombra de contorno
    g.moveTo(pSh.x, pSh.y).lineTo(pHand.x, pHand.y).stroke({ color: this.COL_OUTLINE, width: 5.6 });
    // Manga terracota
    g.moveTo(pSh.x, pSh.y).lineTo(pHand.x, pHand.y).stroke({ color: this.COL_COAT, width: 4.2 });

    // Cotoveleira de couro nogueira / avelã
    g.ellipse(pElbow.x, pElbow.y, 2.8, 1.8).fill(this.COL_TRIM).stroke({ color: this.COL_OUTLINE, width: 0.8 });

    // Punho de camisa azul clara
    const pCuff = { x: pHand.x - (pHand.x - pSh.x) * 0.16, y: pHand.y - (pHand.y - pSh.y) * 0.16 };
    g.circle(pCuff.x, pCuff.y, 1.6).fill(this.COL_SHIRT_CREAM);

    // Mão anatômica com dedos
    g.circle(pHand.x, pHand.y, 2.5).fill(this.COL_SKIN_BASE).stroke({ color: this.COL_OUTLINE, width: 0.8 });
    g.circle(pHand.x + (handR > 0 ? -0.6 : 0.6), pHand.y - 0.4, 1.2).fill(this.COL_SKIN_SHADOW);
  }

  /**
   * Mão esquerda segurando o espelho do violoncelo (fingerboard)
   */
  private _drawArmCelloHolding(g: Graphics, torsoZ: number): void {
    const pShL = this._charToScreen(0.0, -7.8, torsoZ + 4.2);
    const pHandL = this._charToScreen(4.5, -4.8, torsoZ + 2.2);
    const pElbow = { x: (pShL.x + pHandL.x) * 0.5 - 1.0, y: (pShL.y + pHandL.y) * 0.5 + 1.4 };

    // Manga
    g.moveTo(pShL.x, pShL.y).lineTo(pHandL.x, pHandL.y).stroke({ color: this.COL_OUTLINE, width: 5.6 });
    g.moveTo(pShL.x, pShL.y).lineTo(pHandL.x, pHandL.y).stroke({ color: this.COL_COAT, width: 4.2 });

    // Cotoveleira
    g.ellipse(pElbow.x, pElbow.y, 2.8, 1.8).fill(this.COL_TRIM).stroke({ color: this.COL_OUTLINE, width: 0.8 });

    // Mão curvada segurando as cordas contra o espelho
    g.circle(pHandL.x, pHandL.y, 2.6).fill(this.COL_SKIN_BASE).stroke({ color: this.COL_OUTLINE, width: 0.8 });
    // Dedos curvados sobre o ébano
    g.moveTo(pHandL.x - 1.2, pHandL.y - 1.4).lineTo(pHandL.x + 1.4, pHandL.y + 0.4)
      .stroke({ color: this.COL_SKIN_SHADOW, width: 1.4 });
  }

  /**
   * Mão direita empunhando o talão do arco e deslizando sobre as cordas
   */
  private _drawBowAndArm3D(g: Graphics, torsoZ: number): void {
    const pShR = this._charToScreen(0.0, 7.8, torsoZ + 4.2);
    const pHandR = this._charToScreen(6.2, 5.2, torsoZ - 0.5);
    const pElbow = { x: (pShR.x + pHandR.x) * 0.5 + 1.2, y: (pShR.y + pHandR.y) * 0.5 + 1.2 };

    // Manga
    g.moveTo(pShR.x, pShR.y).lineTo(pHandR.x, pHandR.y).stroke({ color: this.COL_OUTLINE, width: 5.6 });
    g.moveTo(pShR.x, pShR.y).lineTo(pHandR.x, pHandR.y).stroke({ color: this.COL_COAT, width: 4.2 });

    // Cotoveleira
    g.ellipse(pElbow.x, pElbow.y, 2.8, 1.8).fill(this.COL_TRIM).stroke({ color: this.COL_OUTLINE, width: 0.8 });

    // Mão direita segurando o talão
    g.circle(pHandR.x, pHandR.y, 2.5).fill(this.COL_SKIN_BASE).stroke({ color: this.COL_OUTLINE, width: 0.8 });

    // ARCO DE VIOLONCELO 3D:
    // Talão na mão direita:
    const pFrog = this._charToScreen(6.2, 6.2, torsoZ - 0.5);
    // Ponta atravessando as cordas no cavalete:
    const pTip = this._charToScreen(4.8, -5.8, torsoZ + 1.5);

    // Vareta nobre de pernambuco
    g.moveTo(pFrog.x, pFrog.y).lineTo(pTip.x, pTip.y).stroke({ color: 0x4a2511, width: 2.0 });
    // Crina branca esticada
    g.moveTo(pFrog.x, pFrog.y + 0.8).lineTo(pTip.x, pTip.y + 0.8).stroke({ color: 0xffffff, width: 1.1 });
    // Talão de ébano e anel de ouro
    g.circle(pFrog.x, pFrog.y, 1.4).fill(this.COL_GOLD);
    g.circle(pFrog.x - 0.8, pFrog.y, 1.0).fill(this.COL_CELLO_EBONY);
    // Ponteira de marfim
    g.circle(pTip.x, pTip.y, 1.1).fill(0xfffaec);
  }

  /**
   * VIOLONCELO 3D RIGOROSO: Cada vértice é projetado no espaço 3D relativo ao tronco do luthier.
   * Gira 360° com oclusão correta, faixas laterais para espessura volumétrica, tampo e efes.
   */
  private _drawCello3DRotating(g: Graphics, torsoZ: number, sinA: number, cosA: number): void {
    // 1. Espigão metálico tocando o chão
    const pEndpinGround = this._charToScreen(6.8, -0.6, 0.0);
    const pEndpinBase = this._charToScreen(6.0, -0.6, 3.2);

    g.circle(pEndpinGround.x, pEndpinGround.y, 2.4).fill({ color: 0x050307, alpha: 0.35 });
    g.moveTo(pEndpinBase.x, pEndpinBase.y).lineTo(pEndpinGround.x, pEndpinGround.y)
      .stroke({ color: 0xcfd8dc, width: 2.2 });
    g.circle(pEndpinBase.x, pEndpinBase.y, 1.8).fill(this.COL_GOLD);

    // Se estiver virado de costas quase plenas (Norte), o violoncelo fica quase todo ocluso pelo tronco
    if (sinA < -0.35) {
      const pScrollBack = this._charToScreen(2.8, -1.2, torsoZ + 14.5);
      g.circle(pScrollBack.x, pScrollBack.y, 2.6).fill(this.COL_CELLO_BACK).stroke({ color: this.COL_OUTLINE, width: 0.8 });
      return;
    }

    // Geometria 3D: Tampo Frontal (fwd + 1.2) e Fundo Traseiro (fwd - 1.2)
    const fwdBot = 5.8;
    const fwdMid = 4.8;
    const fwdTop = 3.8;
    const zBot = 5.0;
    const zMid = torsoZ - 2.0;
    const zTop = torsoZ + 5.0;

    const wBot = 6.4;
    const wMid = 3.8;
    const wTop = 5.0;

    // Tampo Frontal (Front Plate) com projeção isométrica verdadeira
    const pF_BotL = this._charToScreen(fwdBot + 1.2, -wBot - 0.6, zBot);
    const pF_BotR = this._charToScreen(fwdBot + 1.2, wBot - 0.6, zBot);
    const pF_MidL = this._charToScreen(fwdMid + 1.2, -wMid - 0.6, zMid);
    const pF_MidR = this._charToScreen(fwdMid + 1.2, wMid - 0.6, zMid);
    const pF_TopL = this._charToScreen(fwdTop + 1.2, -wTop - 0.6, zTop);
    const pF_TopR = this._charToScreen(fwdTop + 1.2, wTop - 0.6, zTop);

    // Fundo Traseiro (Back Plate)
    const pB_BotL = this._charToScreen(fwdBot - 1.2, -wBot - 0.6, zBot);
    const pB_BotR = this._charToScreen(fwdBot - 1.2, wBot - 0.6, zBot);
    const pB_MidL = this._charToScreen(fwdMid - 1.2, -wMid - 0.6, zMid);
    const pB_MidR = this._charToScreen(fwdMid - 1.2, wMid - 0.6, zMid);
    const pB_TopL = this._charToScreen(fwdTop - 1.2, -wTop - 0.6, zTop);
    const pB_TopR = this._charToScreen(fwdTop - 1.2, wTop - 0.6, zTop);

    // Fundo de mogno escuro envernizado
    const backPoly = [pB_BotL.x, pB_BotL.y, pB_BotR.x, pB_BotR.y, pB_MidR.x, pB_MidR.y, pB_TopR.x, pB_TopR.y, pB_TopL.x, pB_TopL.y, pB_MidL.x, pB_MidL.y];
    g.poly(backPoly).fill(this.COL_CELLO_BACK).stroke({ color: this.COL_OUTLINE, width: 1.2 });

    // Faixas Laterais (Ribs) que criam a espessura 3D visível quando gira
    if (cosA > 0.05) {
      g.poly([pB_BotR.x, pB_BotR.y, pF_BotR.x, pF_BotR.y, pF_MidR.x, pF_MidR.y, pB_MidR.x, pB_MidR.y])
        .fill(this.COL_CELLO_RIB).stroke({ color: this.COL_OUTLINE, width: 0.8 });
      g.poly([pB_MidR.x, pB_MidR.y, pF_MidR.x, pF_MidR.y, pF_TopR.x, pF_TopR.y, pB_TopR.x, pB_TopR.y])
        .fill(this.COL_CELLO_RIB).stroke({ color: this.COL_OUTLINE, width: 0.8 });
    } else if (cosA < -0.05) {
      g.poly([pB_BotL.x, pB_BotL.y, pF_BotL.x, pF_BotL.y, pF_MidL.x, pF_MidL.y, pB_MidL.x, pB_MidL.y])
        .fill(this.COL_CELLO_RIB).stroke({ color: this.COL_OUTLINE, width: 0.8 });
      g.poly([pB_MidL.x, pB_MidL.y, pF_MidL.x, pF_MidL.y, pF_TopL.x, pF_TopL.y, pB_TopL.x, pB_TopL.y])
        .fill(this.COL_CELLO_RIB).stroke({ color: this.COL_OUTLINE, width: 0.8 });
    }

    // Tampo Frontal (Front Plate) de abeto dourado com verniz nobre
    if (sinA > -0.15) {
      const frontPoly = [pF_BotL.x, pF_BotL.y, pF_BotR.x, pF_BotR.y, pF_MidR.x, pF_MidR.y, pF_TopR.x, pF_TopR.y, pF_TopL.x, pF_TopL.y, pF_MidL.x, pF_MidL.y];
      g.poly(frontPoly).fill(this.COL_CELLO_TOP).stroke({ color: this.COL_OUTLINE, width: 1.4 });

      // Efes (f-holes) clássicos esculpidos em coordenadas 3D relativas
      const pF_HoleL = this._charToScreen(fwdMid + 1.3, -2.4 - 0.6, zMid);
      const pF_HoleR = this._charToScreen(fwdMid + 1.3, 2.4 - 0.6, zMid);
      g.circle(pF_HoleL.x, pF_HoleL.y, 1.5).fill(this.COL_CELLO_EBONY);
      g.circle(pF_HoleR.x, pF_HoleR.y, 1.5).fill(this.COL_CELLO_EBONY);

      // Cavalete de madeira de bordo claro (Bridge)
      const pBridgeL = this._charToScreen(fwdMid + 1.6, -2.2 - 0.6, zMid + 0.8);
      const pBridgeR = this._charToScreen(fwdMid + 1.6, 2.2 - 0.6, zMid + 0.8);
      g.moveTo(pBridgeL.x, pBridgeL.y).lineTo(pBridgeR.x, pBridgeR.y)
        .stroke({ color: this.COL_CELLO_BRIDGE, width: 2.4 });

      // Estandarte (Tailpiece) de ébano na base com 4 microafinadores dourados
      const pTailpiece = this._charToScreen(fwdBot + 1.4, -0.6, zBot + 1.0);
      g.circle(pTailpiece.x, pTailpiece.y, 2.0).fill(this.COL_CELLO_EBONY);
      for (let m = -1; m <= 1; m += 0.66) {
        g.circle(pTailpiece.x + m * 1.0, pTailpiece.y - 0.5, 0.4).fill(this.COL_GOLD);
      }
    }

    // Braço, Espelho de ébano e Voluta (Scroll)
    const pScroll = this._charToScreen(2.8, -1.2, torsoZ + 14.5);
    const pFingerboardTop = this._charToScreen(3.4, -0.9, torsoZ + 8.0);
    const pFingerboardBot = this._charToScreen(fwdMid + 1.4, -0.6, zMid + 3.0);

    // Espelho de ébano (Fingerboard)
    g.moveTo(pFingerboardBot.x, pFingerboardBot.y).lineTo(pFingerboardTop.x, pFingerboardTop.y)
      .stroke({ color: this.COL_CELLO_EBONY, width: 3.6 });

    // Cordas prateadas brilhantes
    if (sinA > -0.15) {
      g.moveTo(pFingerboardBot.x - 0.9, pFingerboardBot.y).lineTo(pFingerboardTop.x - 0.7, pFingerboardTop.y)
        .stroke({ color: 0xffffff, width: 0.9 });
      g.moveTo(pFingerboardBot.x + 0.9, pFingerboardBot.y).lineTo(pFingerboardTop.x + 0.7, pFingerboardTop.y)
        .stroke({ color: 0xffffff, width: 0.9 });
    }

    // Voluta (Scroll) espiralada entalhada
    g.circle(pScroll.x, pScroll.y, 2.8).fill(this.COL_CELLO_BACK).stroke({ color: this.COL_OUTLINE, width: 1.0 });
  }

  private _drawCane(g: Graphics, pHand: Vector2, pTip: Vector2, caneLift: number): void {
    const pGround = { x: pTip.x, y: pTip.y + caneLift };
    g.circle(pGround.x, pGround.y, 2.6).fill({ color: 0x050307, alpha: 0.28 });

    g.moveTo(pHand.x, pHand.y).lineTo(pTip.x, pTip.y)
      .stroke({ color: this.COL_OUTLINE, width: 3.8 });
    g.moveTo(pHand.x, pHand.y).lineTo(pTip.x, pTip.y)
      .stroke({ color: 0xffffff, width: 2.6 });

    const pGripEnd = { x: pHand.x + (pTip.x - pHand.x) * 0.18, y: pHand.y + (pTip.y - pHand.y) * 0.18 };
    const pBrass = { x: pHand.x + (pTip.x - pHand.x) * 0.24, y: pHand.y + (pTip.y - pHand.y) * 0.24 };
    g.moveTo(pHand.x, pHand.y).lineTo(pGripEnd.x, pGripEnd.y).stroke({ color: 0x212121, width: 3.4 });
    g.moveTo(pGripEnd.x, pGripEnd.y).lineTo(pBrass.x, pBrass.y).stroke({ color: this.COL_GOLD, width: 3.0 });

    const pRed0 = { x: pHand.x + (pTip.x - pHand.x) * 0.82, y: pHand.y + (pTip.y - pHand.y) * 0.82 };
    const pRed1 = { x: pHand.x + (pTip.x - pHand.x) * 0.90, y: pHand.y + (pTip.y - pHand.y) * 0.90 };
    g.moveTo(pRed0.x, pRed0.y).lineTo(pRed1.x, pRed1.y).stroke({ color: 0xd32f2f, width: 2.8 });

    g.circle(pTip.x, pTip.y, 2.0).fill(0x111111);
  }

  /**
   * CABEÇA ANATÔMICA 2.5D REFINADA (Ultrapassando o original do Godot)
   * - Óculos escuros Wayfarer refinados estilo Virtuoso / Ray Charles com duplo corte de reflexo especular
   * - Bigode de morsa volumoso com vinco labial de sombra profunda (COL_MUSTACHE_SH)
   * - Boina Flat Cap de Lã Tweed com aba direcional (visor) que aponta na direção exata da rotação
   * - Bochechas rosadas de vovô acolhedor (COL_BLUSH)
   * - Orelhas anatômicas ancorando a haste dos óculos
   */
  private _drawHeadAnatomical(g: Graphics, headZ: number, isFacingFront: boolean, cosA: number, sinA: number): void {
    const tilt = this.animState === "listen" ? Math.sin(this.actionProgress * Math.PI) * 2.8 : 0;
    const tripShake = this.animState === "trip" ? (Math.random() - 0.5) * 2.5 : 0;
    const headCenter = { x: tilt + tripShake, y: -headZ };
    const R = 10.2;

    // 1. Sombra suave de recorte de papel da cabeça
    g.circle(headCenter.x + 1.2, headCenter.y + 1.8, R + 0.6).fill({ color: 0x050307, alpha: 0.22 });

    // 2. Esfera base do crânio com sombra inferior quente e bochechas coradas
    g.circle(headCenter.x, headCenter.y, R + 1.2).fill(this.COL_OUTLINE);
    g.circle(headCenter.x, headCenter.y, R).fill(this.COL_SKIN_SHADOW);
    g.circle(headCenter.x - 0.7, headCenter.y - 0.8, R * 0.88).fill(this.COL_SKIN_BASE);

    // Bochechas rosadas de vovô acolhedor
    if (isFacingFront) {
      g.circle(headCenter.x - 5.2, headCenter.y + 2.0, 2.4).fill({ color: this.COL_BLUSH, alpha: 0.55 });
      g.circle(headCenter.x + 5.2, headCenter.y + 2.0, 2.4).fill({ color: this.COL_BLUSH, alpha: 0.55 });
    }

    // =========================================================================
    // CASO COSTAS (NORTE): COROA DE CABELO NA NUCA
    // =========================================================================
    if (!isFacingFront) {
      // Orelhas laterais vistas por trás
      for (const esign of [-1, 1]) {
        const pe = { x: headCenter.x + esign * 9.2, y: headCenter.y + 1.0 };
        g.circle(pe.x, pe.y, 2.8).fill(this.COL_OUTLINE);
        g.circle(pe.x, pe.y, 2.1).fill(this.COL_SKIN_SHADOW);
      }

      // Coroa de cabelo em ferradura envolvendo toda a nuca
      const backHairPts = [
        headCenter.x - 9.8, headCenter.y - 1.5,
        headCenter.x - 6.5, headCenter.y - 0.2,
        headCenter.x, headCenter.y + 0.4,
        headCenter.x + 6.5, headCenter.y - 0.2,
        headCenter.x + 9.8, headCenter.y - 1.5,
        headCenter.x + 10.2, headCenter.y + 2.5,
        headCenter.x + 7.2, headCenter.y + 6.5,
        headCenter.x, headCenter.y + 7.5,
        headCenter.x - 7.2, headCenter.y + 6.5,
        headCenter.x - 10.2, headCenter.y + 2.5,
      ];
      g.poly(backHairPts).fill(this.COL_HAIR_SH).stroke({ color: this.COL_OUTLINE, width: 1.3 });
      for (const mx of [-5.5, -2.8, 0.0, 2.8, 5.5]) {
        g.moveTo(headCenter.x + mx, headCenter.y + 0.8)
          .lineTo(headCenter.x + mx * 0.9, headCenter.y + 6.2)
          .stroke({ color: this.COL_HAIR, width: 1.4 });
      }

      this._drawFlatCap(g, headCenter, R, cosA, sinA);
      return;
    }

    // =========================================================================
    // CASO PERFIL OU FRENTE (SUL / SUDESTE / SUDOESTE)
    // =========================================================================
    const absSide = Math.abs(cosA);
    const dirSign = cosA >= 0 ? 1 : -1;

    // Tufos de mechas prateadas nas têmporas/costeletas
    for (const esign of [-1, 1]) {
      const pe = { x: headCenter.x + esign * 9.0, y: headCenter.y + 1.2 };
      g.circle(pe.x, pe.y, 2.8).fill(this.COL_OUTLINE);
      g.circle(pe.x, pe.y, 2.1).fill(this.COL_SKIN_BASE);
      g.circle(pe.x - esign * 0.3, pe.y + 0.3, 1.1).fill(this.COL_SKIN_SHADOW);

      // Cabelo lateral acima da orelha
      const pTopT = { x: headCenter.x + esign * 8.4, y: headCenter.y - 2.8 };
      const pBotT = { x: headCenter.x + esign * 9.0, y: headCenter.y + 0.6 };
      g.moveTo(pTopT.x, pTopT.y).lineTo(pBotT.x, pBotT.y).stroke({ color: this.COL_HAIR_SH, width: 3.6 });
      g.moveTo(pTopT.x - esign * 0.4, pTopT.y).lineTo(pBotT.x - esign * 0.4, pBotT.y).stroke({ color: this.COL_HAIR, width: 1.6 });
    }

    // Desenha a Boina Flat Cap no topo
    this._drawFlatCap(g, headCenter, R, cosA, sinA);

    // =========================================================================
    // ÓCULOS ESCUROS WAYFARER VIRTUOSO (Inspirado no estilo Ray Charles / Mestre Luthier)
    // =========================================================================
    const faceX = headCenter.x + cosA * 5.4;
    const glassY = headCenter.y - 1.0;

    if (absSide > 0.45) {
      // Visão de Perfil / 3/4
      const pLensC = { x: headCenter.x + dirSign * 5.6, y: glassY };
      const pEar = { x: headCenter.x - dirSign * 3.8, y: glassY + 2.2 };

      // Haste metálica dourada conectando a armação ao topo da orelha
      g.moveTo(pLensC.x - dirSign * 1.4, pLensC.y - 0.8).lineTo(pEar.x, pEar.y - 1.8)
        .stroke({ color: this.COL_SHADES, width: 2.2 });
      g.moveTo(pLensC.x - dirSign * 1.4, pLensC.y - 0.8).lineTo(pEar.x, pEar.y - 1.8)
        .stroke({ color: this.COL_GOLD, width: 1.1 });

      // Lente distante parcial se estiver em 3/4
      if (absSide < 0.82) {
        const pFar = { x: pLensC.x + dirSign * 3.2, y: pLensC.y + 0.2 };
        g.roundRect(pFar.x - 2.0, pFar.y - 2.5, 4.0, 5.0, 1.2).fill(this.COL_SHADES);
      }

      // Lente frontal acetinada com armação
      g.roundRect(pLensC.x - 3.2, pLensC.y - 3.0, 6.4, 6.0, 1.6).fill(this.COL_OUTLINE);
      g.roundRect(pLensC.x - 2.7, pLensC.y - 2.5, 5.4, 5.0, 1.3).fill(this.COL_SHADES);
      g.roundRect(pLensC.x - 2.0, pLensC.y - 1.8, 4.0, 3.6, 1.0).fill(this.COL_SHADES_LENS);

      // Duplo corte de reflexo especular diagonal branco (luz da janela)
      g.moveTo(pLensC.x - 1.6, pLensC.y - 1.8).lineTo(pLensC.x + 0.5, pLensC.y + 1.6)
        .stroke({ color: this.COL_SHADES_SPEC, width: 1.1 });
      g.moveTo(pLensC.x + 0.8, pLensC.y - 1.8).lineTo(pLensC.x + 1.8, pLensC.y + 0.5)
        .stroke({ color: this.COL_SHADES_SPEC, width: 0.8, alpha: 0.65 });

      // Pino dourado de dobradiça na lateral
      g.circle(pLensC.x - dirSign * 2.4, pLensC.y - 1.4, 0.65).fill(this.COL_GOLD);

      // Nariz aquilino de perfil
      const pNoseP = { x: headCenter.x + dirSign * 8.6, y: headCenter.y + 1.4 };
      g.poly([
        pNoseP.x - dirSign * 2.0, pNoseP.y - 2.2,
        pNoseP.x + dirSign * 2.2, pNoseP.y + 0.2,
        pNoseP.x - dirSign * 0.8, pNoseP.y + 1.8,
      ]).fill(this.COL_SKIN_BASE).stroke({ color: this.COL_OUTLINE, width: 1.1 });

      // Bigode de Morsa de Perfil com Vinco Labial Escuro
      const pMusP = { x: headCenter.x + dirSign * 5.8, y: headCenter.y + 3.2 };
      // Vinco de sombra profunda sob o bigode para separação nítida
      g.moveTo(pMusP.x - dirSign * 3.0, pMusP.y + 2.0).lineTo(pMusP.x + dirSign * 3.4, pMusP.y + 1.6)
        .stroke({ color: this.COL_MUSTACHE_SH, width: 2.0 });

      const musPtsP = [
        pMusP.x - dirSign * 3.4, pMusP.y + 0.4,
        pMusP.x - dirSign * 1.0, pMusP.y - 1.2,
        pMusP.x + dirSign * 3.0, pMusP.y - 0.4,
        pMusP.x + dirSign * 3.4, pMusP.y + 1.6,
        pMusP.x, pMusP.y + 2.2,
      ];
      g.poly(musPtsP).fill(this.COL_HAIR).stroke({ color: this.COL_OUTLINE, width: 1.2 });
      g.moveTo(pMusP.x - dirSign * 2.2, pMusP.y + 0.2).lineTo(pMusP.x + dirSign * 2.4, pMusP.y + 0.4)
        .stroke({ color: 0xffffff, width: 1.4 });

    } else {
      // Visão Frontal (Sul)
      const pEyeL = { x: faceX - 4.6, y: glassY };
      const pEyeR = { x: faceX + 4.6, y: glassY };

      // Ponte nasal dourada entre as lentes
      g.moveTo(pEyeL.x, pEyeL.y).lineTo(pEyeR.x, pEyeR.y).stroke({ color: this.COL_OUTLINE, width: 2.4 });
      g.moveTo(pEyeL.x, pEyeL.y).lineTo(pEyeR.x, pEyeR.y).stroke({ color: this.COL_GOLD, width: 1.2 });

      for (const pe of [pEyeL, pEyeR]) {
        // Armação Wayfarer marcante
        g.roundRect(pe.x - 3.8, pe.y - 3.0, 7.6, 6.0, 1.8).fill(this.COL_OUTLINE);
        g.roundRect(pe.x - 3.2, pe.y - 2.5, 6.4, 5.0, 1.4).fill(this.COL_SHADES);
        g.roundRect(pe.x - 2.4, pe.y - 1.8, 4.8, 3.6, 1.0).fill(this.COL_SHADES_LENS);

        // Duplo corte de reflexo especular de quadrinho/papel recortado:
        g.moveTo(pe.x - 2.2, pe.y - 1.4).lineTo(pe.x - 0.6, pe.y + 1.5)
          .stroke({ color: this.COL_SHADES_SPEC, width: 1.1 });
        g.moveTo(pe.x + 0.4, pe.y - 1.4).lineTo(pe.x + 1.4, pe.y + 0.6)
          .stroke({ color: this.COL_SHADES_SPEC, width: 0.8, alpha: 0.65 });

        // Pino dourado de dobradiça na borda externa
        const pinSide = pe.x < faceX ? -3.2 : 3.2;
        g.circle(pe.x + pinSide, pe.y - 1.4, 0.65).fill(this.COL_GOLD);
      }

      // Nariz Frontal esculpido
      const pNoseF = { x: faceX, y: headCenter.y + 1.4 };
      g.circle(pNoseF.x, pNoseF.y, 1.8).fill(this.COL_SKIN_SHADOW);
      g.circle(pNoseF.x - 0.3, pNoseF.y - 0.3, 0.9).fill(this.COL_SKIN_BASE);

      // Bigode de Morsa Frontal com Vinco Labial Escuro
      const pMusF = { x: faceX, y: headCenter.y + 3.4 };

      // Sombra labial escura profunda sob o bigode para separação nítida
      g.moveTo(pMusF.x - 4.4, pMusF.y + 2.2).lineTo(pMusF.x + 4.4, pMusF.y + 2.2)
        .stroke({ color: this.COL_MUSTACHE_SH, width: 2.0 });

      // Bigode prateado brilhante com realce branco puro
      const musFPts = [
        pMusF.x - 5.0, pMusF.y + 1.2,
        pMusF.x - 2.4, pMusF.y - 0.8,
        pMusF.x, pMusF.y - 0.4,
        pMusF.x + 2.4, pMusF.y - 0.8,
        pMusF.x + 5.0, pMusF.y + 1.2,
        pMusF.x + 2.2, pMusF.y + 2.0,
        pMusF.x, pMusF.y + 1.4,
        pMusF.x - 2.2, pMusF.y + 2.0,
      ];
      g.poly(musFPts).fill(this.COL_HAIR).stroke({ color: this.COL_OUTLINE, width: 1.3 });
      g.moveTo(pMusF.x - 3.8, pMusF.y + 0.4).lineTo(pMusF.x + 3.8, pMusF.y + 0.4)
        .stroke({ color: 0xffffff, width: 1.6 });

      // Sorriso sereno acolhedor e queixo esculpido sob o bigode
      g.moveTo(faceX - 2.0, pMusF.y + 3.2).bezierCurveTo(faceX - 0.8, pMusF.y + 3.8, faceX + 0.8, pMusF.y + 3.8, faceX + 2.0, pMusF.y + 3.2)
        .stroke({ color: this.COL_MUSTACHE_SH, width: 1.1 });
      g.circle(faceX, pMusF.y + 4.8, 1.2).fill(this.COL_SKIN_SHADOW);
    }
  }

  /**
   * Boina Flat Cap de Lã Tweed com aba direcional (visor) apontando a rotação
   */
  private _drawFlatCap(g: Graphics, headCenter: Vector2, R: number, cosA: number, sinA: number): void {
    const capCenter = { x: headCenter.x, y: headCenter.y - 4.6 };
    const rx = R * 1.08;
    const ry = 5.8;

    // Copa da boina em lã tweed
    g.ellipse(capCenter.x, capCenter.y, rx, ry).fill(this.COL_CAP).stroke({ color: this.COL_OUTLINE, width: 1.4 });
    // Sombra volumétrica inferior da copa
    g.ellipse(capCenter.x, capCenter.y + 1.2, rx * 0.92, ry * 0.72).fill(this.COL_CAP_SH);

    // Aba direcional da boina (aponta para onde o personagem caminha no espaço 2.5D!)
    const pVisorBase = { x: capCenter.x + cosA * (rx * 0.72), y: capCenter.y + sinA * (ry * 0.72) + 1.2 };
    const pVisorTip = { x: capCenter.x + cosA * (rx * 1.18), y: capCenter.y + sinA * (ry * 1.18) + 2.4 };

    g.moveTo(pVisorBase.x, pVisorBase.y).lineTo(pVisorTip.x, pVisorTip.y)
      .stroke({ color: this.COL_OUTLINE, width: 5.2 });
    g.moveTo(pVisorBase.x, pVisorBase.y).lineTo(pVisorTip.x, pVisorTip.y)
      .stroke({ color: this.COL_CAP_SH, width: 3.6 });

    // Botãozinho central no topo da boina
    g.circle(capCenter.x, capCenter.y - ry * 0.35, 1.6).fill(this.COL_OUTLINE);
    g.circle(capCenter.x, capCenter.y - ry * 0.35, 1.2).fill(this.COL_CAP);
  }
}
