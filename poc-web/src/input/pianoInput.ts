import { Container, Graphics, Text, TextStyle } from "pixi.js";
import { NOTES, isMovementNote } from "../core/notes";
import { ColorSchemeManager } from "../core/colorSchemes";

export interface PianoInputOptions {
  onNoteTriggered: (noteKey: string) => void;
  onPreviewNote?: (noteKey: string) => void;
  width?: number;
  height?: number;
}

export class PianoInput {
  public readonly container: Container;
  private readonly _keys: {
    noteKey: string;
    isBlack: boolean;
    container: Container;
    gKey: Graphics;
    isArmed: boolean;
  }[] = [];

  private _onNoteTriggered: (noteKey: string) => void;
  private _onPreviewNote?: (noteKey: string) => void;

  public readonly whiteKeyWidth: number = 32;
  public readonly whiteKeyHeight: number = 105;
  public readonly blackKeyWidth: number = 20;
  public readonly blackKeyHeight: number = 66;

  // Teclas pretas: índices cromáticos 1 (Cs4), 3 (Ds4), 6 (Fs4), 8 (Gs4), 10 (As4)
  private readonly _chromaticKeys = [
    "C4", "Cs4", "D4", "Ds4", "E4", "F4", "Fs4", "G4", "Gs4", "A4", "As4", "B4",
  ];
  private readonly _blackIndices = [1, 3, 6, 8, 10];
  private readonly _whiteIndicesForBlack: Record<number, number> = {
    1: 0, 3: 1, 6: 3, 8: 4, 10: 5,
  };
  private readonly _whiteIndexMap: Record<number, number> = {
    0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6,
  };

  constructor(options: PianoInputOptions) {
    this._onNoteTriggered = options.onNoteTriggered;
    this._onPreviewNote = options.onPreviewNote;
    this.container = new Container();

    this._buildPiano();

    const colorMgr = ColorSchemeManager.getInstance();
    colorMgr.onSchemeChanged = () => this.refreshColors();
    colorMgr.onControlCuesChanged = () => this.refreshColors();
  }

  public refreshColors(): void {
    for (const k of this._keys) {
      this._redrawSingleKey(k, k.isArmed, false);
    }
  }

  private _redrawSingleKey(k: { noteKey: string; isBlack: boolean; gKey: Graphics }, armed: boolean, pressed: boolean): void {
    const kw = k.isBlack ? this.blackKeyWidth : this.whiteKeyWidth - 1.5;
    const kh = k.isBlack ? this.blackKeyHeight : this.whiteKeyHeight;
    const colHex = ColorSchemeManager.getInstance().getColorHexNumber(k.noteKey, true);

    k.gKey.clear();
    if (k.isBlack) {
      const fillCol = armed ? 0x3949ab : (pressed ? 0x37474f : 0x1e1e24);
      k.gKey.roundRect(0, 0, kw, kh, 4)
        .fill(fillCol)
        .stroke({ color: armed ? 0xffffff : 0x08080a, width: armed ? 2.0 : 1.2 });

      k.gKey.roundRect(2, 2, kw - 4, 6, 2)
        .fill(colHex);
    } else {
      const fillCol = armed ? 0xe8eaf6 : (pressed ? 0xd7ccc8 : 0xf5f3ee);
      k.gKey.roundRect(0, 0, kw, kh, 5)
        .fill(fillCol)
        .stroke({ color: armed ? 0x3949ab : 0xbcaaa4, width: armed ? 2.5 : 1.0 });

      k.gKey.roundRect(2, 4, kw - 4, 5, 2)
        .fill(colHex);
    }
  }

  private _buildPiano(): void {
    const totalWhite = 7;
    const totalW = totalWhite * this.whiteKeyWidth;
    const totalH = this.whiteKeyHeight;

    // Moldura de marcenaria em mogno envernizado e friso de latão
    const gFrame = new Graphics();
    gFrame.roundRect(-8, -10, totalW + 16, totalH + 20, 10)
      .fill({ color: 0x1a0f0a, alpha: 0.95 })
      .stroke({ color: 0x4a2818, width: 3.0 });

    // Friso de feltro carmesim no topo das teclas (como um piano acústico real)
    gFrame.rect(0, 0, totalW, 4)
      .fill(0xb71c1c);

    this.container.addChild(gFrame);

    const whiteLayer = new Container();
    const blackLayer = new Container();
    this.container.addChild(whiteLayer);
    this.container.addChild(blackLayer);

    const actionIcons: Record<string, string> = {
      Gs4: "🦯",
      A4: "👂",
      As4: "🏃",
      B4: "🦘",
    };

    const directionArrows: Record<string, string> = {
      C4: "↑", Cs4: "↗", D4: "→", Ds4: "↘",
      E4: "↓", F4: "↙", Fs4: "←", G4: "↖",
    };

    this._chromaticKeys.forEach((noteKey, cIdx) => {
      const isBlack = this._blackIndices.includes(cIdx);
      const btn = new Container();
      btn.eventMode = "static";
      btn.cursor = "pointer";

      let kx = 0;
      let kw = 0;
      let kh = 0;

      if (isBlack) {
        const leftWhite = this._whiteIndicesForBlack[cIdx];
        kx = (leftWhite + 1) * this.whiteKeyWidth - this.blackKeyWidth * 0.5;
        kw = this.blackKeyWidth;
        kh = this.blackKeyHeight;
        blackLayer.addChild(btn);
      } else {
        const wIdx = this._whiteIndexMap[cIdx];
        kx = wIdx * this.whiteKeyWidth;
        kw = this.whiteKeyWidth - 1.5;
        kh = this.whiteKeyHeight;
        whiteLayer.addChild(btn);
      }

      btn.position.set(kx, 0);

      const gKey = new Graphics();
      btn.addChild(gKey);

      const redrawKey = (armed: boolean, pressed: boolean = false) => {
        this._redrawSingleKey({ noteKey, isBlack, gKey }, armed, pressed);
      };

      redrawKey(false);

      // Ícone ou seta na base da tecla
      const symbol = isMovementNote(noteKey) ? directionArrows[noteKey] : actionIcons[noteKey];
      if (symbol) {
        const iconStyle = new TextStyle({
          fontSize: isBlack ? 11 : 13,
          fontWeight: "bold",
          fill: isBlack ? 0xffffff : 0x22130c,
        });
        const iconText = new Text({ text: symbol, style: iconStyle });
        iconText.anchor.set(0.5, 0.5);
        iconText.position.set(kw * 0.5, kh - (isBlack ? 12 : 16));
        btn.addChild(iconText);
      }

      // Nome da nota
      const nameStyle = new TextStyle({
        fontSize: isBlack ? 8.5 : 9.5,
        fontWeight: "bold",
        fill: isBlack ? 0xd1d8e0 : 0x4e342e,
      });
      const label = NOTES[noteKey]?.label || noteKey;
      const nameText = new Text({ text: label, style: nameStyle });
      nameText.anchor.set(0.5, 0.5);
      nameText.position.set(kw * 0.5, isBlack ? kh * 0.42 : kh * 0.55);
      btn.addChild(nameText);

      btn.on("pointerdown", () => {
        redrawKey(false, true);
        this._onPreviewNote?.(noteKey);
        this._onNoteTriggered(noteKey);
      });

      btn.on("pointerup", () => {
        const item = this._keys.find((k) => k.noteKey === noteKey);
        redrawKey(item ? item.isArmed : false, false);
      });

      btn.on("pointerupoutside", () => {
        const item = this._keys.find((k) => k.noteKey === noteKey);
        redrawKey(item ? item.isArmed : false, false);
      });

      this._keys.push({
        noteKey,
        isBlack,
        container: btn,
        gKey,
        isArmed: false,
      });
    });
  }

  public setArmedState(running: boolean, jumping: boolean): void {
    for (const k of this._keys) {
      if (k.noteKey === "As4") {
        k.isArmed = running;
      } else if (k.noteKey === "B4") {
        k.isArmed = jumping;
      }
    }
  }
}
