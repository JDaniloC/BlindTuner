import { Graphics, Color } from "pixi.js";
import { IsoMath, Vector3 } from "../core/iso";

export interface IsoBoxStyle {
  baseColor: string | number;
  topColorMultiplier?: number;
  rightColorMultiplier?: number;
  leftColorMultiplier?: number;
  outlineColor?: string | number;
  outlineWidth?: number;
  highlightCrest?: boolean;
  shadowAlpha?: number;
  woodGrain?: boolean;
}

export class IsoBox {
  /**
   * Desenha uma caixa 3D em projeção isométrica 2:1 com iluminação cel-shaded refinada,
   * chanfros iluminados e veios sutis de madeira.
   */
  static draw(
    g: Graphics,
    pos: Vector3,
    size: Vector3,
    style: IsoBoxStyle
  ): void {
    const c = new Color(style.baseColor);
    const rgb = c.toRgbArray();

    const topMult = style.topColorMultiplier ?? 1.22;
    const rightMult = style.rightColorMultiplier ?? 0.92;
    const leftMult = style.leftColorMultiplier ?? 0.68;

    const topCol = new Color([Math.min(1, rgb[0] * topMult), Math.min(1, rgb[1] * topMult), Math.min(1, rgb[2] * topMult)]).toHex();
    const rightCol = new Color([rgb[0] * rightMult, rgb[1] * rightMult, rgb[2] * rightMult]).toHex();
    const leftCol = new Color([rgb[0] * leftMult, rgb[1] * leftMult, rgb[2] * leftMult]).toHex();

    const outlineCol = style.outlineColor ?? 0x16141c;
    const outlineW = style.outlineWidth ?? 1.2;

    const x0 = pos.x;
    const y0 = pos.y;
    const z0 = pos.z;
    const x1 = pos.x + size.x;
    const y1 = pos.y + size.y;
    const z1 = pos.z + size.z;

    // Vértices projetados 2:1
    const p100 = IsoMath.project({ x: x1, y: y0, z: z0 });
    const p110 = IsoMath.project({ x: x1, y: y1, z: z0 });
    const p010 = IsoMath.project({ x: x0, y: y1, z: z0 });

    const p001 = IsoMath.project({ x: x0, y: y0, z: z1 });
    const p101 = IsoMath.project({ x: x1, y: y0, z: z1 });
    const p111 = IsoMath.project({ x: x1, y: y1, z: z1 });
    const p011 = IsoMath.project({ x: x0, y: y1, z: z1 });

    // Sombra de contato suave e difusa no piso (se na base z0 == 0)
    if (z0 <= 0.1 && (style.shadowAlpha ?? 0.28) > 0) {
      const s0 = IsoMath.project({ x: x0 - 4, y: y0 - 4, z: 0 });
      const s1 = IsoMath.project({ x: x1 + 6, y: y0 - 4, z: 0 });
      const s2 = IsoMath.project({ x: x1 + 8, y: y1 + 6, z: 0 });
      const s3 = IsoMath.project({ x: x0 - 6, y: y1 + 6, z: 0 });

      g.poly([s0.x, s0.y, s1.x, s1.y, s2.x, s2.y, s3.x, s3.y])
        .fill({ color: 0x070913, alpha: style.shadowAlpha ?? 0.28 });
    }

    // 1. Face Sul-Oeste (Left Face - Sombra lateral)
    g.poly([p010.x, p010.y, p110.x, p110.y, p111.x, p111.y, p011.x, p011.y])
      .fill(leftCol)
      .stroke({ color: outlineCol, width: outlineW, alpha: 0.85 });

    // 2. Face Sul-Leste (Right Face - Meia-luz)
    g.poly([p100.x, p100.y, p110.x, p110.y, p111.x, p111.y, p101.x, p101.y])
      .fill(rightCol)
      .stroke({ color: outlineCol, width: outlineW, alpha: 0.85 });

    // 3. Face Superior (Top Face - Luz principal)
    g.poly([p001.x, p001.y, p101.x, p101.y, p111.x, p111.y, p011.x, p011.y])
      .fill(topCol)
      .stroke({ color: outlineCol, width: outlineW, alpha: 0.95 });

    // Veios de madeira orgânicos sutis na face superior (se habilitado)
    if (style.woodGrain && size.x > 8 && size.y > 8) {
      const grainCount = Math.min(4, Math.floor(size.y / 14));
      for (let gIdx = 1; gIdx <= grainCount; gIdx++) {
        const t = gIdx / (grainCount + 1);
        const yG = y0 + size.y * t;
        const gStart = IsoMath.project({ x: x0 + 2, y: yG, z: z1 });
        const gEnd = IsoMath.project({ x: x1 - 2, y: yG, z: z1 });
        g.moveTo(gStart.x, gStart.y)
          .lineTo(gEnd.x, gEnd.y)
          .stroke({ color: outlineCol, width: 0.8, alpha: 0.22 });
      }
    }

    // Chanfro de crista iluminado (crest highlight)
    if (style.highlightCrest) {
      g.moveTo(p001.x, p001.y)
        .lineTo(p101.x, p101.y)
        .stroke({ color: 0xffffff, width: 1.2, alpha: 0.5 });
      g.moveTo(p001.x, p001.y)
        .lineTo(p011.x, p011.y)
        .stroke({ color: 0xffffff, width: 0.9, alpha: 0.35 });
    }
  }

  /**
   * Desenha um cilindro isométrico com faces poligonais individuais devidamente renderizadas
   * (corrige a falha anterior da cúpula do abajur).
   */
  static drawCylinder(
    g: Graphics,
    baseCenter: Vector3,
    radius: number,
    height: number,
    colorHex: number,
    topColorHex?: number
  ): void {
    const steps = 16;
    const botPts: { x: number; y: number }[] = [];
    const topPts: { x: number; y: number }[] = [];

    for (let i = 0; i <= steps; i++) {
      const a = (i / steps) * Math.PI * 2;
      const rx = Math.cos(a) * radius;
      const ry = Math.sin(a) * radius;
      botPts.push(IsoMath.project({ x: baseCenter.x + rx, y: baseCenter.y + ry, z: baseCenter.z }));
      topPts.push(IsoMath.project({ x: baseCenter.x + rx, y: baseCenter.y + ry, z: baseCenter.z + height }));
    }

    const c = new Color(colorHex);
    const rgb = c.toRgbArray();

    // Renderiza cada face lateral individualmente com iluminação angular
    for (let i = 0; i < steps; i++) {
      const midAngle = ((i + 0.5) / steps) * Math.PI * 2;
      // Luz vem do Norte (+Z e -X, -Y)
      const lightFactor = 0.75 + Math.cos(midAngle - Math.PI * 0.75) * 0.35;
      const faceCol = new Color([
        Math.min(1, rgb[0] * lightFactor),
        Math.min(1, rgb[1] * lightFactor),
        Math.min(1, rgb[2] * lightFactor),
      ]).toHex();

      g.poly([
        botPts[i].x, botPts[i].y,
        topPts[i].x, topPts[i].y,
        topPts[i + 1].x, topPts[i + 1].y,
        botPts[i + 1].x, botPts[i + 1].y,
      ])
      .fill(faceCol)
      .stroke({ color: 0x16141c, width: 0.8, alpha: 0.6 });
    }

    // Tampa superior elíptica
    const topFlat: number[] = [];
    for (const p of topPts) {
      topFlat.push(p.x, p.y);
    }
    const finalTopCol = topColorHex ?? new Color([Math.min(1, rgb[0] * 1.25), Math.min(1, rgb[1] * 1.25), Math.min(1, rgb[2] * 1.25)]).toHex();

    g.poly(topFlat)
      .fill(finalTopCol)
      .stroke({ color: 0x16141c, width: 1.0, alpha: 0.8 });
  }
}
