export type VisionCondition =
  | "none"
  | "cataract"
  | "macular_degeneration"
  | "glaucoma_tunnel"
  | "diabetic_retinopathy";

export interface VisionOverlayOptions {
  containerElement: HTMLElement;
}

export class VisionOverlay {
  private readonly _wrapper: HTMLElement;
  private readonly _canvas: HTMLCanvasElement;
  private readonly _ctx: CanvasRenderingContext2D;
  private _condition: VisionCondition = "none";
  private _motionClarity: number = 0;
  private _screenPos = { x: 0.5, y: 0.5 }; // Normalizado 0..1

  constructor(options: VisionOverlayOptions) {
    this._wrapper = options.containerElement;

    this._canvas = document.createElement("canvas");
    this._canvas.id = "vision-overlay-canvas";
    this._canvas.style.position = "absolute";
    this._canvas.style.inset = "0";
    this._canvas.style.width = "100%";
    this._canvas.style.height = "100%";
    this._canvas.style.pointerEvents = "none";
    this._canvas.style.zIndex = "6";
    this._canvas.style.transition = "backdrop-filter 0.3s ease";

    this._wrapper.appendChild(this._canvas);
    this._ctx = this._canvas.getContext("2d")!;

    this.resize();
    window.addEventListener("resize", () => this.resize());
  }

  public resize(): void {
    const rect = this._wrapper.getBoundingClientRect();
    this._canvas.width = rect.width || window.innerWidth;
    this._canvas.height = rect.height || window.innerHeight;
    this.render();
  }

  public setCondition(cond: VisionCondition): void {
    this._condition = cond;
    this._applyBackdropFilter();
    this.render();
  }

  get condition(): VisionCondition {
    return this._condition;
  }

  public pulseClarity(amount: number = 0.4): void {
    this._motionClarity = Math.min(1.0, this._motionClarity + amount);
    this.render();
  }

  public update(charScreenX: number, charScreenY: number, isMoving: boolean, dt: number): void {
    const targetClarity = isMoving ? 1.0 : 0.0;
    const speed = isMoving ? 4.0 : 2.0;
    this._motionClarity += (targetClarity - this._motionClarity) * Math.min(1.0, dt * speed);

    const w = this._canvas.width;
    const h = this._canvas.height;
    if (w > 0 && h > 0) {
      this._screenPos.x = charScreenX;
      this._screenPos.y = charScreenY;
    }

    if (this._condition !== "none") {
      this.render();
    }
  }

  private _applyBackdropFilter(): void {
    switch (this._condition) {
      case "cataract":
        // Catarata: Desfoque difuso, redução de contraste em 35% e leve amarelamento
        this._canvas.style.backdropFilter = "blur(3.8px) contrast(0.68) sepia(0.24) brightness(1.04)";
        break;
      case "macular_degeneration":
        // Degeneração macular: leve desfoque periférico, mancha central pintada no canvas
        this._canvas.style.backdropFilter = "contrast(0.92) blur(0.8px)";
        break;
      case "glaucoma_tunnel":
        // Glaucoma: campo visual em túnel estreito
        this._canvas.style.backdropFilter = "none";
        break;
      case "diabetic_retinopathy":
        this._canvas.style.backdropFilter = "contrast(0.85) blur(1.5px)";
        break;
      case "none":
      default:
        this._canvas.style.backdropFilter = "none";
        break;
    }
  }

  public render(): void {
    const w = this._canvas.width;
    const h = this._canvas.height;
    this._ctx.clearRect(0, 0, w, h);

    if (this._condition === "none") return;

    const cx = this._screenPos.x;
    const cy = this._screenPos.y;

    if (this._condition === "glaucoma_tunnel") {
      // Visão Tubular do Glaucoma: Túnel estreito de visão com névoa escura periférica
      const baseRadius = Math.min(w, h) * 0.22;
      const tunnelRadius = baseRadius * (1.0 + this._motionClarity * 0.25);
      const outerRadius = tunnelRadius + Math.min(w, h) * 0.35;

      const grad = this._ctx.createRadialGradient(cx, cy, tunnelRadius * 0.4, cx, cy, outerRadius);
      grad.addColorStop(0, "rgba(10, 8, 14, 0.0)");
      grad.addColorStop(0.35, "rgba(10, 8, 14, 0.25)");
      grad.addColorStop(0.7, "rgba(10, 8, 14, 0.78)");
      grad.addColorStop(1, "rgba(8, 6, 12, 0.94)");

      this._ctx.fillStyle = grad;
      this._ctx.fillRect(0, 0, w, h);
    } else if (this._condition === "macular_degeneration") {
      // Degeneração Macular: Escotoma central (mancha escura onde o olhar tenta focar)
      const spotRadius = Math.min(w, h) * 0.16;
      const grad = this._ctx.createRadialGradient(cx, cy, 0, cx, cy, spotRadius);
      grad.addColorStop(0, "rgba(20, 16, 24, 0.96)");
      grad.addColorStop(0.55, "rgba(28, 22, 34, 0.85)");
      grad.addColorStop(0.85, "rgba(40, 32, 45, 0.35)");
      grad.addColorStop(1, "rgba(0, 0, 0, 0.0)");

      this._ctx.fillStyle = grad;
      this._ctx.beginPath();
      this._ctx.arc(cx, cy, spotRadius, 0, Math.PI * 2);
      this._ctx.fill();
    } else if (this._condition === "diabetic_retinopathy") {
      // Retinopatia Diabética: Múltiplas manchas dispersas e perda de nitidez
      this._ctx.fillStyle = "rgba(14, 10, 18, 0.82)";
      const spots = [
        { dx: -70, dy: -50, r: 35 },
        { dx: 90, dy: -30, r: 42 },
        { dx: -40, dy: 80, r: 38 },
        { dx: 80, dy: 70, r: 48 },
        { dx: 10, dy: -90, r: 30 },
      ];
      for (const s of spots) {
        const sx = cx + s.dx;
        const sy = cy + s.dy;
        const g = this._ctx.createRadialGradient(sx, sy, 0, sx, sy, s.r);
        g.addColorStop(0, "rgba(15, 10, 12, 0.92)");
        g.addColorStop(0.7, "rgba(25, 18, 20, 0.6)");
        g.addColorStop(1, "rgba(0, 0, 0, 0.0)");
        this._ctx.fillStyle = g;
        this._ctx.beginPath();
        this._ctx.arc(sx, sy, s.r, 0, Math.PI * 2);
        this._ctx.fill();
      }
    }
  }
}
