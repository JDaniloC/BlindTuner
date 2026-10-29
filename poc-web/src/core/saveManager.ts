export interface LevelRecord {
  stars: number;
  bestTime: number;
  minTrips: number;
  lastFirstTryHits: number;
}

export interface PlayerPreferences {
  preferredInputMode: "scroll" | "joystick" | "piano";
  cueLevel: number;
  colorScheme: "pedagogico" | "alto_contraste" | "classico";
  controlCuesEnabled: boolean;
  visionImpairment: "none" | "cataract" | "macular_degeneration" | "glaucoma_tunnel" | "diabetic_retinopathy";
  isPixelArtMode: boolean;
}

export interface SaveData {
  unlockedLevels: string[];
  completedLevels: Record<string, LevelRecord>;
  preferences: PlayerPreferences;
}

const STORAGE_KEY = "blindtuner_web_save_v1";

export class SaveManager {
  private static _instance: SaveManager | null = null;
  private _data: SaveData;

  private constructor() {
    this._data = this._loadData();
  }

  public static getInstance(): SaveManager {
    if (!SaveManager._instance) {
      SaveManager._instance = new SaveManager();
    }
    return SaveManager._instance;
  }

  private _getDefaultData(): SaveData {
    return {
      unlockedLevels: ["ch1_quarto_radio", "arcade_suzuki_1"],
      completedLevels: {},
      preferences: {
        preferredInputMode: "scroll",
        cueLevel: 0,
        colorScheme: "pedagogico",
        controlCuesEnabled: true,
        visionImpairment: "none",
        isPixelArtMode: true,
      },
    };
  }

  private _loadData(): SaveData {
    try {
      if (typeof window !== "undefined" && window.localStorage) {
        const raw = window.localStorage.getItem(STORAGE_KEY);
        if (raw) {
          const parsed = JSON.parse(raw);
          return {
            ...this._getDefaultData(),
            ...parsed,
            preferences: {
              ...this._getDefaultData().preferences,
              ...(parsed.preferences || {}),
            },
          };
        }
      }
    } catch {
      // Fallback em caso de modo anônimo ou restrição de storage
    }
    return this._getDefaultData();
  }

  public saveData(): void {
    try {
      if (typeof window !== "undefined" && window.localStorage) {
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(this._data));
      }
    } catch {
      // Ignora erro em storage restrito
    }
  }

  public isLevelUnlocked(levelId: string): boolean {
    const defaults = ["ch1_quarto_radio", "arcade_suzuki_1"];
    if (defaults.includes(levelId)) return true;
    return this._data.unlockedLevels.includes(levelId);
  }

  public unlockLevel(levelId: string): boolean {
    if (!this._data.unlockedLevels.includes(levelId)) {
      this._data.unlockedLevels.push(levelId);
      this.saveData();
      return true;
    }
    return false;
  }

  public recordCompletion(
    levelId: string,
    stars: number,
    elapsedSec: number,
    trips: number,
    firstTryHits: number
  ): LevelRecord {
    const prev = this._data.completedLevels[levelId] || {
      stars: 0,
      bestTime: Infinity,
      minTrips: Infinity,
      lastFirstTryHits: 0,
    };

    const newRecord: LevelRecord = {
      stars: Math.max(stars, prev.stars),
      bestTime: Math.min(elapsedSec, prev.bestTime),
      minTrips: Math.min(trips, prev.minTrips),
      lastFirstTryHits: firstTryHits,
    };

    this._data.completedLevels[levelId] = newRecord;
    this.saveData();
    return newRecord;
  }

  public getLevelStars(levelId: string): number {
    return this._data.completedLevels[levelId]?.stars || 0;
  }

  public getTotalStars(): number {
    return Object.values(this._data.completedLevels).reduce((acc, rec) => acc + rec.stars, 0);
  }

  public getPreferences(): PlayerPreferences {
    return { ...this._data.preferences };
  }

  public setPreference<K extends keyof PlayerPreferences>(key: K, value: PlayerPreferences[K]): void {
    this._data.preferences[key] = value;
    this.saveData();
  }

  public resetProgress(): void {
    this._data = this._getDefaultData();
    this.saveData();
  }
}
