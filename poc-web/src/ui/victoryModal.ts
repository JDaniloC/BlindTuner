import { LevelMetadata, StarEvaluation } from "../core/campaign";

export interface VictoryModalOptions {
  containerElement: HTMLElement;
  onNextLevelRequested?: () => void;
  onRetryRequested?: () => void;
  onLevelSelectRequested?: () => void;
}

export class VictoryModal {
  private readonly _wrapper: HTMLElement;
  private readonly _overlay: HTMLElement;
  private _options: VictoryModalOptions;

  constructor(options: VictoryModalOptions) {
    this._options = options;
    this._wrapper = options.containerElement;

    this._overlay = document.createElement("div");
    this._overlay.id = "victory-modal-overlay";
    this._overlay.style.position = "absolute";
    this._overlay.style.inset = "0";
    this._overlay.style.background = "rgba(10, 8, 7, 0.92)";
    this._overlay.style.backdropFilter = "blur(14px)";
    this._overlay.style.display = "none";
    this._overlay.style.zIndex = "120";
    this._overlay.style.alignItems = "center";
    this._overlay.style.justifyContent = "center";
    this._overlay.style.padding = "20px";
    this._overlay.style.overflowY = "auto";

    this._wrapper.appendChild(this._overlay);
  }

  public show(levelMeta: LevelMetadata, evaluation: StarEvaluation, hasNext: boolean): void {
    const isThreeStars = evaluation.stars === 3;
    const titleText = isThreeStars
      ? `${levelMeta.name} Afinada com Afeto!`
      : `${levelMeta.name} Guardada no Coração!`;

    const starsHtml = [0, 1, 2]
      .map((i) => {
        const active = i < evaluation.stars;
        const color = active ? "#ffd54f" : "#555";
        return `<span style="color: ${color}; font-size: 38px; margin: 0 4px; text-shadow: ${active ? "0 0 16px rgba(255, 213, 79, 0.65)" : "none"};">★</span>`;
      })
      .join("");

    this._overlay.innerHTML = `
      <div class="modal-box" style="max-width: 440px; width: 100%; border: 2px solid #8d6e63; background: #1c130d; border-radius: 16px; padding: 24px; box-shadow: 0 20px 60px rgba(0,0,0,0.9); text-align: center; color: #fff8e1;">
        <!-- Cabeçalho -->
        <div style="font-size: 26px; margin-bottom: 4px;">🎻✨</div>
        <h2 style="font-family: Georgia, serif; font-size: 22px; color: #f5d77f; margin: 0 0 6px 0;">
          ${titleText}
        </h2>
        <div style="font-size: 13px; color: #81d4fa; font-weight: bold; margin-bottom: 14px;">
          Peça: ${levelMeta.songTitle} • ${levelMeta.composer}
        </div>

        <!-- Estrelas Grandes -->
        <div style="margin-bottom: 12px; display: flex; justify-content: center; align-items: center;">
          ${starsHtml}
        </div>

        <!-- Citação Poética do Sr. Arthur -->
        <div style="background: rgba(28, 20, 15, 0.95); border-left: 3.5px solid #d4af37; border-radius: 6px; padding: 10px 14px; margin-bottom: 16px; font-family: Georgia, serif; font-style: italic; font-size: 13px; color: #e0d5ce; line-height: 1.5; text-align: left;">
          "${levelMeta.storyQuote}"
        </div>

        <!-- 3 Badges Categóricos (DEC-0005) -->
        <div style="display: flex; flex-direction: column; gap: 8px; margin-bottom: 18px; text-align: left;">
          <!-- Badge 1: Memória Resgatada -->
          <div style="background: #271912; border: 1.5px solid ${evaluation.hasMemory ? "#ffd54f" : "#444"}; border-radius: 8px; padding: 8px 12px; display: flex; align-items: center; justify-content: space-between;">
            <div>
              <div style="font-weight: bold; font-size: 13px; color: ${evaluation.hasMemory ? "#fff" : "#888"};">🏅 Memória Resgatada</div>
              <div style="font-size: 11px; color: #bbb;">Alcançou o objetivo final e completou o percurso.</div>
            </div>
            <div style="font-size: 11px; font-weight: bold; color: ${evaluation.hasMemory ? "#81c784" : "#e57373"};">
              ${evaluation.hasMemory ? "Conquistada" : "Pendente"}
            </div>
          </div>

          <!-- Badge 2: Ouvido Fino -->
          <div style="background: #271912; border: 1.5px solid ${evaluation.hasEar ? "#ffd54f" : "#444"}; border-radius: 8px; padding: 8px 12px; display: flex; align-items: center; justify-content: space-between;">
            <div>
              <div style="font-weight: bold; font-size: 13px; color: ${evaluation.hasEar ? "#fff" : "#888"};">👂 Ouvido Fino</div>
              <div style="font-size: 11px; color: #bbb;">100% de primeira tentativa sem desafinar.</div>
            </div>
            <div style="font-size: 11px; font-weight: bold; color: ${evaluation.hasEar ? "#81c784" : "#ffb74d"};">
              ${evaluation.hasEar ? "Conquistada" : `${evaluation.details.pitchMisses} desafinada(s)`}
            </div>
          </div>

          <!-- Badge 3: Passo Firme -->
          <div style="background: #271912; border: 1.5px solid ${evaluation.hasStep ? "#ffd54f" : "#444"}; border-radius: 8px; padding: 8px 12px; display: flex; align-items: center; justify-content: space-between;">
            <div>
              <div style="font-weight: bold; font-size: 13px; color: ${evaluation.hasStep ? "#fff" : "#888"};">🦯 Passo Firme</div>
              <div style="font-size: 11px; color: #bbb;">Navegação limpa sem colisões com obstáculos.</div>
            </div>
            <div style="font-size: 11px; font-weight: bold; color: ${evaluation.hasStep ? "#81c784" : "#ffb74d"};">
              ${evaluation.hasStep ? "Conquistada" : `${evaluation.details.wallBumps} tropeço(s)`}
            </div>
          </div>
        </div>

        <!-- Telemetria -->
        <div style="font-size: 11.5px; color: #a1887f; margin-bottom: 18px; font-family: monospace;">
          ⏱️ Tempo: ${evaluation.details.elapsedSec.toFixed(1)}s &nbsp;|&nbsp; 🎯 1ª tentativa: ${evaluation.details.firstTryHits}/${evaluation.details.totalNotes} &nbsp;|&nbsp; 💥 Colisões: ${evaluation.details.wallBumps}
        </div>

        <!-- Ações do Jogador -->
        <div style="display: flex; flex-direction: column; gap: 8px;">
          ${
            hasNext
              ? `<button id="btn-victory-next" class="btn-luthier" style="margin-top: 0; padding: 12px 20px; font-size: 14px; width: 100%;">Seguir para a Próxima Lembrança ➔</button>`
              : ""
          }
          <div style="display: flex; gap: 8px; justify-content: center;">
            <button id="btn-victory-retry" class="hud-mode-btn" style="flex: 1; padding: 10px; font-size: 12px; border-color: #ffd54f;">🔁 Tocar Outra Vez</button>
            <button id="btn-victory-menu" class="hud-mode-btn" style="flex: 1; padding: 10px; font-size: 12px;">📖 Folhear Diário</button>
          </div>
        </div>
      </div>
    `;

    this._overlay.style.display = "flex";

    // Bindings de botões
    const btnNext = document.getElementById("btn-victory-next");
    if (btnNext) {
      btnNext.addEventListener("click", () => {
        this.hide();
        this._options.onNextLevelRequested?.();
      });
    }

    const btnRetry = document.getElementById("btn-victory-retry");
    if (btnRetry) {
      btnRetry.addEventListener("click", () => {
        this.hide();
        this._options.onRetryRequested?.();
      });
    }

    const btnMenu = document.getElementById("btn-victory-menu");
    if (btnMenu) {
      btnMenu.addEventListener("click", () => {
        this.hide();
        this._options.onLevelSelectRequested?.();
      });
    }
  }

  public hide(): void {
    this._overlay.style.display = "none";
  }
}
