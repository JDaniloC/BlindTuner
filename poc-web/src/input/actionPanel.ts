import { Container, Graphics, Text, TextStyle } from "pixi.js";
import { NOTES } from "../core/notes";
import { ColorSchemeManager } from "../core/colorSchemes";

export interface ActionPanelOptions {
  onActionTriggered: (noteKey: string) => void;
}

export class ActionPanel {
  public readonly container: Container;
  private readonly _buttons: {
    noteKey: string;
    actionId: string;
    gBtn: Graphics;
    lbl: Text;
    icon: Text;
    isArmed: boolean;
  }[] = [];

  private _onActionTriggered: (noteKey: string) => void;

  public readonly actionNotes = ["Gs4", "A4", "As4", "B4"];

  constructor(options: ActionPanelOptions) {
    this._onActionTriggered = options.onActionTriggered;
    this.container = new Container();
    this._buildUI();
    this._bindKeys();

    const colorMgr = ColorSchemeManager.getInstance();
    colorMgr.onSchemeChanged = () => this.refreshColors();
    colorMgr.onControlCuesChanged = () => this.refreshColors();
  }

  private _buildUI(): void {
    const btnW = 54;
    const btnH = 54;
    const gap = 8;

    const actionData: Record<string, { label: string; icon: string; keyHint: string }> = {
      Gs4: { label: "Tatear",  icon: "🦯", keyHint: "[1]" },
      A4:  { label: "Escutar", icon: "👂", keyHint: "[2]" },
      As4: { label: "Correr",  icon: "🏃", keyHint: "[3]" },
      B4:  { label: "Pular",   icon: "🦘", keyHint: "[4]" },
    };

    // Moldura de fundo em marcenaria mogno escuro
    const gBackdrop = new Graphics();
    gBackdrop.roundRect(-6, -6, btnW * 2 + gap + 12, btnH * 2 + gap + 12, 10)
      .fill({ color: 0x140e0b, alpha: 0.90 })
      .stroke({ color: 0x3d2314, width: 2.0 });
    this.container.addChild(gBackdrop);

    this.actionNotes.forEach((noteKey, idx) => {
      const col = idx % 2;
      const row = Math.floor(idx / 2);
      const bx = col * (btnW + gap);
      const by = row * (btnH + gap);

      const btnContainer = new Container();
      btnContainer.position.set(bx, by);
      btnContainer.eventMode = "static";
      btnContainer.cursor = "pointer";

      const gBtn = new Graphics();
      btnContainer.addChild(gBtn);

      const data = actionData[noteKey];
      const noteInfo = NOTES[noteKey];
      const baseCol = noteInfo ? parseInt(noteInfo.color.replace("#", "0x"), 16) : 0x455a64;

      const iconStyle = new TextStyle({
        fontSize: 18,
        fill: 0xffffff,
      });
      const iconText = new Text({ text: data.icon, style: iconStyle });
      iconText.anchor.set(0.5, 0.5);
      iconText.position.set(btnW * 0.5, btnH * 0.36);
      btnContainer.addChild(iconText);

      const lblStyle = new TextStyle({
        fontSize: 9.5,
        fontWeight: "bold",
        fill: 0xffffff,
        stroke: { color: 0x111111, width: 2 },
      });
      const lblText = new Text({ text: `${data.label} ${data.keyHint}`, style: lblStyle });
      lblText.anchor.set(0.5, 0.5);
      lblText.position.set(btnW * 0.5, btnH * 0.76);
      btnContainer.addChild(lblText);

      const redrawBtn = (armed: boolean, pressed: boolean = false) => {
        gBtn.clear();
        const borderColor = armed ? 0xffffff : 0x22130c;
        const borderWidth = armed ? 2.8 : 1.4;
        const fillAlpha = pressed ? 0.95 : (armed ? 0.90 : 0.65);
        const fillCol = armed ? (baseCol | 0x222222) : baseCol;

        gBtn.roundRect(0, 0, btnW, btnH, 8)
          .fill({ color: fillCol, alpha: fillAlpha })
          .stroke({ color: borderColor, width: borderWidth });

        if (armed) {
          // Borda externa brilhante pulsante
          gBtn.roundRect(-2, -2, btnW + 4, btnH + 4, 10)
            .stroke({ color: 0xffffff, width: 1.5, alpha: 0.8 });
        }
      };

      redrawBtn(false);

      btnContainer.on("pointerdown", () => {
        redrawBtn(false, true);
        this._onActionTriggered(noteKey);
      });

      btnContainer.on("pointerup", () => {
        const item = this._buttons.find((b) => b.noteKey === noteKey);
        redrawBtn(item ? item.isArmed : false, false);
      });

      btnContainer.on("pointerupoutside", () => {
        const item = this._buttons.find((b) => b.noteKey === noteKey);
        redrawBtn(item ? item.isArmed : false, false);
      });

      this.container.addChild(btnContainer);

      this._buttons.push({
        noteKey,
        actionId: noteInfo ? noteInfo.actionId : "",
        gBtn,
        lbl: lblText,
        icon: iconText,
        isArmed: false,
      });
    });
  }

  public setArmedState(running: boolean, jumping: boolean): void {
    for (const b of this._buttons) {
      if (b.noteKey === "As4") {
        b.isArmed = running;
      } else if (b.noteKey === "B4") {
        b.isArmed = jumping;
      }
      this._redrawItem(b);
    }
  }

  public refreshColors(): void {
    for (const b of this._buttons) {
      this._redrawItem(b);
    }
  }

  private _redrawItem(item: { noteKey: string; gBtn: Graphics; isArmed: boolean }): void {
    const baseCol = ColorSchemeManager.getInstance().getColorHexNumber(item.noteKey, true);
    const btnW = 54;
    const btnH = 54;

    item.gBtn.clear();
    const borderColor = item.isArmed ? 0xffffff : 0x22130c;
    const borderWidth = item.isArmed ? 2.8 : 1.4;
    const fillAlpha = item.isArmed ? 0.95 : 0.65;
    const fillCol = item.isArmed ? (baseCol | 0x222222) : baseCol;

    item.gBtn.roundRect(0, 0, btnW, btnH, 8)
      .fill({ color: fillCol, alpha: fillAlpha })
      .stroke({ color: borderColor, width: borderWidth });

    if (item.isArmed) {
      item.gBtn.roundRect(-2, -2, btnW + 4, btnH + 4, 10)
        .stroke({ color: 0xffffff, width: 1.5, alpha: 0.8 });
    }
  }

  private _bindKeys(): void {
    window.addEventListener("keydown", (e) => {
      // Ignora se o foco estiver em campo de texto
      if (document.activeElement && ["INPUT", "TEXTAREA"].includes(document.activeElement.tagName)) {
        return;
      }
      switch (e.key) {
        case "1":
          this._onActionTriggered("Gs4");
          break;
        case "2":
          this._onActionTriggered("A4");
          break;
        case "3":
          this._onActionTriggered("As4");
          break;
        case "4":
          this._onActionTriggered("B4");
          break;
      }
    });
  }
}
