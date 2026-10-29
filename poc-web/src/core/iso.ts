export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface Vector2 {
  x: number;
  y: number;
}

export interface Point2D {
  x: number;
  y: number;
}

/**
 * Motor Geométrico 2.5D Isométrico (Projeção Matemática 2:1).
 * x = avança para Sul-Leste (+X, +Y/2 na tela)
 * y = avança para Sul-Oeste (-X, +Y/2 na tela)
 * z = altura vertical (-Y na tela)
 */
export class IsoMath {
  /** Converte ponto 3D para tela 2D isométrica 2:1 */
  static project(p: Vector3): Vector2 {
    return {
      x: p.x - p.y,
      y: (p.x + p.y) * 0.5 - p.z,
    };
  }

  /**
   * Converte coordenadas de grid inteiro (gx, gy) e elevação z em pixels de mundo.
   * tileW = 64, tileH = 32 -> passo unitário = tileW / 2 = 32px.
   */
  static gridToWorld(gx: number, gy: number, z: number = 0, step: number = 32): Vector2 {
    return IsoMath.project({
      x: gx * step,
      y: gy * step,
      z: z * step,
    });
  }

  /**
   * Chave de profundidade para o Painter's Algorithm:
   * Elementos com maior (x + y) e maior z ficam na frente.
   */
  static depthOf(p: Vector3): number {
    return (p.x + p.y) + p.z * 0.15;
  }

  /**
   * Rotação em torno do eixo vertical Z por radianos.
   */
  static rotateZ(p: Vector3, angleRad: number): Vector3 {
    const c = Math.cos(angleRad);
    const s = Math.sin(angleRad);
    return {
      x: p.x * c - p.y * s,
      y: p.x * s + p.y * c,
      z: p.z,
    };
  }
}
