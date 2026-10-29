import { Container, Graphics, FederatedPointerEvent, Text } from "pixi.js";
import { NOTES, NOTE_KEYS, nearestNoteForFrequency } from "../core/notes";
import { FacingMath } from "../core/facing";
import { ColorSchemeManager } from "../core/colorSchemes";

export interface PitchScrollCallbacks {
  onDragStart: (freqHz: number) => void;
  onDragMove: (freqHz: number, angleRad: number, noteKey: string) => void;
  onDragEnd: (finalNoteKey: string, finalFreqHz: number) => void;
}

export class PitchScrollInput {
  public readonly container: Container;
  private readonly _gBackground: Graphics;
  private readonly _gFretMarkers: Graphics;
  private readonly _gString: Graphics;
  private readonly _gIndicator: Graphics;
  private readonly _noteText: Text;
  private readonly _freqText: Text;

  private _isDragging: boolean = false;
  private _currentFreq: number = 262.0;
  private _vibratePhase: number = 0;

  private readonly _minFreq = 262.0; // C4
  private readonly _maxFreq = 494.0; // B4
  private readonly _width = 62;
  private readonly _height = 400;

  private _callbacks: PitchScrollCallbacks;

  constructor(callbacks: PitchScrollCallbacks) {
    this._callbacks = callbacks;
    this.container = new Container();
    this.container.eventMode = "static";

    this._gBackground = new Graphics();
    this._gFretMarkers = new Graphics();
    this._gString = new Graphics();
    this._gIndicator = new Graphics();

    this._noteText = new Text({
      text: "",
      style: {
        fontFamily: "Georgia, serif",
        fontSize: 16,
        fontWeight: "bold",
        fill: 0xffffff,
      },
    });
    this._noteText.anchor.set(1.0, 0.5);

    this._freqText = new Text({
      text: "",
      style: {
        fontFamily: "monospace",
        fontSize: 11,
        fontWeight: "bold",
        fill: 0xfbc02d,
      },
    });
    this._freqText.anchor.set(1.0, 0.5);

    this.container.addChild(this._gBackground);
    this.container.addChild(this._gFretMarkers);
    this.container.addChild(this._gString);
    this.container.addChild(this._gIndicator);
    this.container.addChild(this._noteText);
    this.container.addChild(this._freqText);

    this._drawFretlessBoard();
    this._setupEvents();

    const colorMgr = ColorSchemeManager.getInstance();
    colorMgr.onSchemeChanged = () => this._drawFretlessBoard();
    colorMgr.onControlCuesChanged = () => this._drawFretlessBoard();
  }

  private _freqToY(freq: number): number {
    const pad = 20;
    const ratio = 1.0 - (freq - this._minFreq) / (this._maxFreq - this._minFreq);
    return pad + ratio * (this._height - pad * 2);
  }

  private _drawFretlessBoard(): void {
    this._gBackground.clear();
    // 1. Moldura externa de madeira nobre de luthier (mogno / jacarandá)
    this._gBackground.roundRect(-3, -3, this._width + 6, this._height + 6, 12)
      .fill(0x3e1f14)
      .stroke({ color: 0x24120a, width: 2.0 });

    // 2. Espelho do braço em ébano negro lustrado
    this._gBackground.roundRect(0, 0, this._width, this._height, 10)
      .fill(0x130e0b)
      .stroke({ color: 0x543926, width: 1.5 });

    // Filetes dourados sutis nas bordas laterais
    this._gBackground.moveTo(4, 8).lineTo(4, this._height - 8).stroke({ color: 0xd4af37, width: 0.8, alpha: 0.6 });
    this._gBackground.moveTo(this._width - 4, 8).lineTo(this._width - 4, this._height - 8).stroke({ color: 0xd4af37, width: 0.8, alpha: 0.6 });

    // Pestana de osso/marfim no topo
    this._gBackground.rect(6, 4, this._width - 12, 7)
      .fill(0xfffaec)
      .stroke({ color: 0xd8caa8, width: 0.8 });

    // 3. Marcações de harmônicos / pontos de afinação de madrepérola (inlays)
    this._gFretMarkers.clear();
    const cx = this._width * 0.5;

    for (const key of NOTE_KEYS) {
      const note = NOTES[key];
      const y = this._freqToY(note.freq);
      const isNatural = !note.label.includes("#");

      if (isNatural) {
        // Linha fina de harmônico de latão
        this._gFretMarkers.moveTo(12, y).lineTo(this._width - 12, y)
          .stroke({ color: 0xd4af37, width: 1.0, alpha: 0.4 });
        // Ponto de madrepérola à esquerda
        this._gFretMarkers.circle(8, y, 1.8).fill(0xfffdf5);
        this._gFretMarkers.circle(this._width - 8, y, 1.8).fill(0xfffdf5);
      } else {
        // Marcador sutil para semitons
        this._gFretMarkers.moveTo(cx - 6, y).lineTo(cx + 6, y)
          .stroke({ color: 0x8d6e63, width: 0.8, alpha: 0.35 });
      }
    }
  }

  private _setupEvents(): void {
    this.container.on("pointerdown", (e: FederatedPointerEvent) => {
      this._isDragging = true;
      this._updateFromPointer(e.getLocalPosition(this.container).y);
      const angle = FacingMath.angleForFrequency(this._currentFreq);
      const note = nearestNoteForFrequency(this._currentFreq);
      this._callbacks.onDragStart(this._currentFreq);
      this._callbacks.onDragMove(this._currentFreq, angle, note);
    });

    this.container.on("globalpointermove", (e: FederatedPointerEvent) => {
      if (!this._isDragging) return;
      this._updateFromPointer(e.getLocalPosition(this.container).y);
      const angle = FacingMath.angleForFrequency(this._currentFreq);
      const note = nearestNoteForFrequency(this._currentFreq);
      this._callbacks.onDragMove(this._currentFreq, angle, note);
    });

    const finish = () => {
      if (!this._isDragging) return;
      this._isDragging = false;
      const finalNote = nearestNoteForFrequency(this._currentFreq);
      this._callbacks.onDragEnd(finalNote, this._currentFreq);
      this._renderIndicator(0, "");
    };

    this.container.on("pointerup", finish);
    this.container.on("pointerupoutside", finish);
  }

  private _updateFromPointer(localY: number): void {
    const pad = 20;
    const clampedY = Math.max(pad, Math.min(this._height - pad, localY));
    const ratio = 1.0 - (clampedY - pad) / (this._height - pad * 2);
    this._currentFreq = this._minFreq + ratio * (this._maxFreq - this._minFreq);

    const note = nearestNoteForFrequency(this._currentFreq);
    this._renderIndicator(clampedY, note);
  }

  private _renderIndicator(y: number, noteKey: string): void {
    this._gIndicator.clear();
    if (!this._isDragging || !noteKey) {
      this._noteText.text = "";
      this._freqText.text = "";
      return;
    }

    const noteInfo = NOTES[noteKey];
    const colorHex = ColorSchemeManager.getInstance().getColorHexNumber(noteKey, true);
    const label = noteInfo ? noteInfo.label : "";
    const cx = this._width * 0.5;

    // Halo de afinação harmônica
    this._gIndicator.circle(cx, y, 22)
      .fill({ color: colorHex, alpha: 0.25 });

    // Anel de latão torneado do botão de afinação
    this._gIndicator.circle(cx, y, 13)
      .fill(0x3e2723)
      .stroke({ color: 0xd4af37, width: 2.0 });

    // Gema central translúcida na cor da nota afinada
    this._gIndicator.circle(cx, y, 7.5)
      .fill(colorHex)
      .stroke({ color: 0xffffff, width: 1.5 });

    // Linha guia de mira horizontal
    this._gIndicator.moveTo(2, y).lineTo(this._width - 2, y)
      .stroke({ color: colorHex, width: 1.8, alpha: 0.85 });

    // Ponto harmônico correspondente na escala acende na cor da nota
    const targetY = this._freqToY(noteInfo.freq);
    this._gIndicator.circle(8, targetY, 3.0).fill(colorHex);
    this._gIndicator.circle(this._width - 8, targetY, 3.0).fill(colorHex);

    // Tipografia fina com nota e frequência exata
    const centsOffset = Math.round(1200.0 * Math.log2(this._currentFreq / noteInfo.freq));
    const centsStr = centsOffset >= 0 ? `+${centsOffset}¢` : `${centsOffset}¢`;

    this._noteText.text = `${label} (${noteInfo.key})`;
    this._noteText.position.set(-18, y - 8);
    this._noteText.style.fill = colorHex;

    this._freqText.text = `${Math.round(this._currentFreq)} Hz  ${centsStr}`;
    this._freqText.position.set(-18, y + 10);
  }

  public update(dt: number): void {
    this._gString.clear();
    const cx = this._width * 0.5;

    if (this._isDragging) {
      this._vibratePhase += dt * 55.0;
      const vibAmp = Math.sin(this._vibratePhase) * 2.4;

      // Corda de aço vibrando com curva suave
      this._gString.moveTo(cx, 0)
        .bezierCurveTo(cx + vibAmp, this._height * 0.5, cx - vibAmp, this._height * 0.5, cx, this._height)
        .stroke({ color: 0xffffff, width: 3.0 });
    } else {
      // Corda de aço niquelada em repouso
      this._gString.moveTo(cx, 0).lineTo(cx, this._height)
        .stroke({ color: 0xe0e0e0, width: 2.4 });
    }
  }
}
