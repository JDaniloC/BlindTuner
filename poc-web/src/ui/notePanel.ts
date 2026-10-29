import { ColorSchemeManager, ColorDistance } from "../core/colorSchemes";
import { CueSettingsManager } from "../core/cueSettings";
import { NOTES, NoteInfo } from "../core/notes";

export interface NotePanelOptions {
  containerElement: HTMLElement;
  onReplayRequested: () => void;
}

export class NotePanel {
  private readonly _el: HTMLElement;
  private readonly _chipEl: HTMLElement;
  private readonly _chipFrameEl: HTMLElement;
  private readonly _nameEl: HTMLElement;
  private readonly _freqEl: HTMLElement;
  private readonly _guidanceEl: HTMLElement;
  private readonly _soundOnlyEl: HTMLElement;
  private readonly _replayBtn: HTMLButtonElement;

  private _currentNoteKey: string | null = null;
  private _colorManager: ColorSchemeManager;
  private _cueManager: CueSettingsManager;

  constructor(options: NotePanelOptions) {
    this._el = options.containerElement;
    this._colorManager = ColorSchemeManager.getInstance();
    this._cueManager = CueSettingsManager.getInstance();

    this._el.innerHTML = `
      <div class="note-panel-inner" style="display: flex; align-items: center; justify-content: space-between; width: 100%; gap: 10px;">
        <div style="display: flex; align-items: center; gap: 10px;">
          <div id="note-chip-frame" style="width: 32px; height: 32px; border-radius: 6px; padding: 2px; display: flex; align-items: center; justify-content: center; background: #140e0b; border: 2px solid #543926; box-shadow: 0 2px 6px rgba(0,0,0,0.5);">
            <div id="note-chip" style="width: 100%; height: 100%; border-radius: 4px; background: #fbc02d; transition: background 0.2s;"></div>
          </div>
          <div style="display: flex; flex-direction: column; justify-content: center;">
            <div id="note-panel-name" style="font-family: Georgia, serif; font-size: 15px; font-weight: bold; color: #fff8e1; letter-spacing: 0.4px;">-</div>
            <div id="note-panel-freq" style="font-family: monospace; font-size: 11px; color: #fbc02d; font-weight: bold;">- Hz</div>
            <div id="note-panel-sound-only" style="display: none; font-size: 11px; color: #81d4fa; font-weight: bold;">🎧 Guiagem Auditiva (Só Som)</div>
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <div id="note-panel-guidance" style="font-size: 11px; font-weight: bold; color: #ffb74d;"></div>
          <button id="note-panel-replay-btn" class="hud-mode-btn" style="border-color: #fb8c00; color: #ffb74d; padding: 4px 8px; font-size: 10.5px;" title="Ouvir nota alvo novamente">🔁 Repetir</button>
        </div>
      </div>
    `;

    this._chipFrameEl = this._el.querySelector("#note-chip-frame") as HTMLElement;
    this._chipEl = this._el.querySelector("#note-chip") as HTMLElement;
    this._nameEl = this._el.querySelector("#note-panel-name") as HTMLElement;
    this._freqEl = this._el.querySelector("#note-panel-freq") as HTMLElement;
    this._guidanceEl = this._el.querySelector("#note-panel-guidance") as HTMLElement;
    this._soundOnlyEl = this._el.querySelector("#note-panel-sound-only") as HTMLElement;
    this._replayBtn = this._el.querySelector("#note-panel-replay-btn") as HTMLButtonElement;

    this._replayBtn.addEventListener("click", () => {
      options.onReplayRequested();
    });

    this._colorManager.onSchemeChanged = () => {
      this._updateDisplay();
    };

    this._cueManager.onCueLevelChanged = () => {
      this._updateDisplay();
    };

    this._updateDisplay();
  }

  public displayTargetNote(noteKey: string): void {
    this._currentNoteKey = noteKey;
    this._guidanceEl.textContent = "";
    this._updateDisplay();
  }

  public displayMissGuidance(playedFreq: number, targetFreq: number): void {
    if (playedFreq < targetFreq) {
      this._guidanceEl.textContent = "▲ Suba (Mais agudo)";
      this._guidanceEl.style.color = "#ffb74d";
    } else {
      this._guidanceEl.textContent = "▼ Desça (Mais grave)";
      this._guidanceEl.style.color = "#4fc3f7";
    }
  }

  public clear(): void {
    this._currentNoteKey = null;
    this._guidanceEl.textContent = "";
    this._updateDisplay();
  }

  private _updateDisplay(): void {
    if (!this._currentNoteKey || !NOTES[this._currentNoteKey]) {
      this._nameEl.textContent = "-";
      this._freqEl.textContent = "";
      this._chipEl.style.background = "#2a1c14";
      this._chipFrameEl.style.borderColor = "#543926";
      this._chipFrameEl.style.display = "flex";
      this._nameEl.style.display = "block";
      this._freqEl.style.display = "block";
      this._soundOnlyEl.style.display = "none";
      return;
    }

    const note = NOTES[this._currentNoteKey] as NoteInfo;
    const colorHex = this._colorManager.getColor(this._currentNoteKey, false);

    // Borda WCAG calculada para o Chip
    const borderContrast = ColorDistance.getBorderContrast(colorHex, "#1c130d");
    this._chipEl.style.background = colorHex;
    this._chipFrameEl.style.borderColor = borderContrast;

    // Regras de Pista (CueLevel 0..3)
    const showsName = this._cueManager.showsName();
    const showsFreq = this._cueManager.showsFreq();
    const showsColor = this._cueManager.showsColor();
    const isSoundOnly = this._cueManager.isSoundOnly();

    this._nameEl.textContent = showsName ? `${note.label} (${note.key})` : "";
    this._nameEl.style.display = showsName ? "block" : "none";

    this._freqEl.textContent = showsFreq ? `${note.freq} Hz` : "";
    this._freqEl.style.display = showsFreq ? "block" : "none";

    this._chipFrameEl.style.display = showsColor ? "flex" : "none";
    this._soundOnlyEl.style.display = isSoundOnly ? "block" : "none";
  }
}
