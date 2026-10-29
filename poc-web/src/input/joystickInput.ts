import { Container, Graphics, Text, TextStyle } from "pixi.js";
import { NOTES, snapAngleToNote } from "../core/notes";
import { ColorSchemeManager } from "../core/colorSchemes";

export interface JoystickInputOptions {
  onNoteTriggered: (noteKey: string) => void;
  onPreviewAngle?: (angleRad: number, noteKey: string) => void;
  radius?: number;
}

export class JoystickInput {
  public readonly container: Container;
  private readonly _gBackdrop: Graphics;
  private readonly _gSlices: Graphics;
  private readonly _gThumb: Graphics;
  private readonly _labelsContainer: Container;

  private _onNoteTriggered: (noteKey: string) => void;
  private _onPreviewAngle?: (angleRad: number, noteKey: string) => void;

  public readonly radius: number;
  private _activeSliceKey: string | null = null;
  private _isDragging: boolean = false;
  private _thumbPos: { x: number; y: number } = { x: 0, y: 0 };

  // 8 Fatias de 45°
  public readonly movementNotes = ["C4", "Cs4", "D4", "Ds4", "E4", "F4", "Fs4", "G4"];
  private readonly arrowSymbols = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"];

  constructor(options: JoystickInputOptions) {
    this._onNoteTriggered = options.onNoteTriggered;
    this._onPreviewAngle = options.onPreviewAngle;
    this.radius = options.radius || 105;

    this.container = new Container();
    this.container.eventMode = "static";
    this.container.cursor = "pointer";

    this._gBackdrop = new Graphics();
    this._gSlices = new Graphics();
    this._labelsContainer = new Container();
    this._gThumb = new Graphics();

    this.container.addChild(this._gBackdrop);
    this.container.addChild(this._gSlices);
    this.container.addChild(this._labelsContainer);
    this.container.addChild(this._gThumb);

    this._buildSlices();
    this._renderThumb();
    this._setupInteraction();

    const colorMgr = ColorSchemeManager.getInstance();
    colorMgr.onSchemeChanged = () => this.refreshColors();
    colorMgr.onControlCuesChanged = () => this.refreshColors();
  }

  public refreshColors(): void {
    this._buildSlices();
    this._renderThumb();
  }

  private _buildSlices(): void {
    const R = this.radius;

    // Disco de fundo opaco de marcenaria de mogno / latão
    this._gBackdrop.clear();
    this._gBackdrop.circle(0, 0, R + 6)
      .fill({ color: 0x140e0b, alpha: 0.95 })
      .stroke({ color: 0x3d2314, width: 3.0 });

    this._gBackdrop.circle(0, 0, R)
      .stroke({ color: 0x54321f, width: 1.5 });

    this._renderSlices();

    // Rótulos e setas de cada fatia
    this._labelsContainer.removeChildren();
    const sliceAngle = (Math.PI * 2) / 8;

    this.movementNotes.forEach((nKey, idx) => {
      // Inicia em -90° (Norte / C4) e gira no sentido horário
      const angle = -Math.PI * 0.5 + idx * sliceAngle;
      const arrowR = R * 0.52;
      const labelR = R * 0.82;

      const ax = Math.cos(angle) * arrowR;
      const ay = Math.sin(angle) * arrowR;

      const arrowStyle = new TextStyle({
        fontSize: 16,
        fontWeight: "bold",
        fill: 0xffffff,
      });
      const arrowText = new Text({ text: this.arrowSymbols[idx], style: arrowStyle });
      arrowText.anchor.set(0.5, 0.5);
      arrowText.position.set(ax, ay);
      this._labelsContainer.addChild(arrowText);

      const noteInfo = NOTES[nKey];
      const lblStyle = new TextStyle({
        fontSize: 10,
        fontWeight: "bold",
        fill: 0xffffff,
        stroke: { color: 0x111111, width: 2 },
      });
      const lblText = new Text({ text: noteInfo ? noteInfo.label : nKey, style: lblStyle });
      lblText.anchor.set(0.5, 0.5);
      lblText.position.set(Math.cos(angle) * labelR, Math.sin(angle) * labelR);
      this._labelsContainer.addChild(lblText);
    });
  }

  private _renderSlices(): void {
    const R = this.radius;
    const deadZone = R * 0.22;
    const sliceAngle = (Math.PI * 2) / 8;

    this._gSlices.clear();

    this.movementNotes.forEach((nKey, idx) => {
      const startA = -Math.PI * 0.5 + idx * sliceAngle - sliceAngle * 0.5;
      const endA = startA + sliceAngle;
      const isActive = this._activeSliceKey === nKey;

      const colHex = ColorSchemeManager.getInstance().getColorHexNumber(nKey, true);
      const alpha = isActive ? 0.85 : 0.35;

      // Desenha cunha
      this._gSlices.poly([
        Math.cos(startA) * deadZone, Math.sin(startA) * deadZone,
        Math.cos(startA) * R, Math.sin(startA) * R,
        Math.cos((startA + endA) * 0.5) * R, Math.sin((startA + endA) * 0.5) * R,
        Math.cos(endA) * R, Math.sin(endA) * R,
        Math.cos(endA) * deadZone, Math.sin(endA) * deadZone,
      ])
      .fill({ color: colHex, alpha })
      .stroke({ color: isActive ? 0xffffff : 0x22130c, width: isActive ? 2.5 : 1.2 });
    });
  }

  private _renderThumb(): void {
    const R = this.radius;
    const thumbR = R * 0.26;

    this._gThumb.clear();
    // Sombra do botão central
    this._gThumb.circle(this._thumbPos.x + 1.5, this._thumbPos.y + 2.5, thumbR)
      .fill({ color: 0x050406, alpha: 0.35 });

    // Thumb de marfim / latão com friso dourado
    this._gThumb.circle(this._thumbPos.x, this._thumbPos.y, thumbR)
      .fill(this._isDragging ? 0xffd54f : 0xe8e4d8)
      .stroke({ color: 0x8d6e63, width: 2.5 });

    this._gThumb.circle(this._thumbPos.x, this._thumbPos.y, thumbR * 0.6)
      .stroke({ color: 0x5d4037, width: 1.2, alpha: 0.6 });
  }

  private _setupInteraction(): void {
    const handleMove = (e: any) => {
      if (!this._isDragging) return;
      const local = this.container.toLocal(e.global);
      const dist = Math.sqrt(local.x * local.x + local.y * local.y);
      const angleRad = Math.atan2(local.y, local.x);

      // Limita o thumb ao raio máximo
      const maxThumb = this.radius * 0.65;
      const clampedDist = Math.min(dist, maxThumb);
      this._thumbPos = {
        x: Math.cos(angleRad) * clampedDist,
        y: Math.sin(angleRad) * clampedDist,
      };
      this._renderThumb();

      if (dist > this.radius * 0.18) {
        // Converte ângulo matemático (0 = Leste) para grau positivo
        let deg = (angleRad * 180) / Math.PI;
        if (deg < 0) deg += 360;
        // Gira para alinhar Norte (270° = C4)
        const noteAngleDeg = (deg + 90) % 360;
        const noteKey = snapAngleToNote(noteAngleDeg, true);
        if (this._activeSliceKey !== noteKey) {
          this._activeSliceKey = noteKey;
          this._renderSlices();
        }
        this._onPreviewAngle?.(angleRad, noteKey);
      } else {
        if (this._activeSliceKey !== null) {
          this._activeSliceKey = null;
          this._renderSlices();
        }
      }
    };

    const handleEnd = () => {
      if (!this._isDragging) return;
      this._isDragging = false;
      const selected = this._activeSliceKey;
      this._thumbPos = { x: 0, y: 0 };
      this._activeSliceKey = null;
      this._renderThumb();
      this._renderSlices();

      if (selected) {
        this._onNoteTriggered(selected);
      }
    };

    this.container.on("pointerdown", (e) => {
      this._isDragging = true;
      handleMove(e);
    });

    this.container.on("pointermove", handleMove);
    this.container.on("pointerup", handleEnd);
    this.container.on("pointerupoutside", handleEnd);
  }
}
