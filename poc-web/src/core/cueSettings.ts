export type CueLevel = 0 | 1 | 2 | 3;

export interface CueLevelInfo {
  readonly level: CueLevel;
  readonly name: string;
  readonly description: string;
}

export const CUE_LEVELS: readonly CueLevelInfo[] = [
  { level: 0, name: "Pista 0: Tudo", description: "Nome da nota, frequência em Hz e amostra de cor." },
  { level: 1, name: "Pista 1: Freq+Cor", description: "Oculta o nome da nota; mantém frequência e cor." },
  { level: 2, name: "Pista 2: Só Cor", description: "Exibe exclusivamente a cor com moldura de contraste WCAG." },
  { level: 3, name: "Pista 3: Só Som", description: "Oculta pistas visuais; navegação 100% pelo ouvido." },
];

export class CueSettingsManager {
  private static _instance: CueSettingsManager;

  public cueLevel: CueLevel = 0;
  public onCueLevelChanged?: (level: CueLevel) => void;

  public static getInstance(): CueSettingsManager {
    if (!CueSettingsManager._instance) {
      CueSettingsManager._instance = new CueSettingsManager();
    }
    return CueSettingsManager._instance;
  }

  public setLevel(level: number): void {
    const clamped = Math.max(0, Math.min(3, Math.floor(level))) as CueLevel;
    if (this.cueLevel === clamped) return;
    this.cueLevel = clamped;
    this.onCueLevelChanged?.(this.cueLevel);
  }

  public showsName(): boolean {
    return this.cueLevel <= 0;
  }

  public showsFreq(): boolean {
    return this.cueLevel <= 1;
  }

  public showsColor(): boolean {
    return this.cueLevel <= 2;
  }

  public isSoundOnly(): boolean {
    return this.cueLevel === 3;
  }
}
