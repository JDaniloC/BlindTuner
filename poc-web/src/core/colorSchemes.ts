import { NOTE_KEYS } from "./notes";

export type ColorSchemeId = "classico" | "pedagogico" | "alto_contraste";

export interface ColorSchemeDef {
  readonly id: ColorSchemeId;
  readonly name: string;
  readonly description: string;
  readonly colors: readonly string[];
}

export const COLOR_SCHEMES: Record<ColorSchemeId, ColorSchemeDef> = {
  classico: {
    id: "classico",
    name: "Clássico",
    description: "Paleta original saturada com matizes tradicionais de cada nota musical.",
    colors: [
      "#E91E63", // C4  (Dó)
      "#1B5E20", // Cs4 (Dó#)
      "#FF9800", // D4  (Ré)
      "#1976D2", // Ds4 (Ré#)
      "#FBC02D", // E4  (Mi)
      "#7B1FA2", // F4  (Fá)
      "#388E3C", // Fs4 (Fá#)
      "#795548", // G4  (Sol)
      "#00838F", // Gs4 (Sol#)
      "#FB8C00", // A4  (Lá)
      "#3949AB", // As4 (Lá#)
      "#7CB342", // B4  (Si)
    ],
  },
  pedagogico: {
    id: "pedagogico",
    name: "Pedagógico",
    description: "Arco-íris de luminância corrigida; contraste >= 1.62:1 entre todos os 11 pares adjacentes.",
    colors: [
      "#9C000A", // C4
      "#CE3000", // Cs4
      "#EB6D00", // D4
      "#F8AD00", // Ds4
      "#FFF200", // E4
      "#009218", // F4
      "#00BC58", // Fs4
      "#00ECA6", // G4
      "#00A0C1", // Gs4
      "#81C8FF", // A4
      "#9D84FF", // As4
      "#FFADFB", // B4
    ],
  },
  alto_contraste: {
    id: "alto_contraste",
    name: "Alto Contraste",
    description: "7 matizes com consciência de daltonismo (protanopia/deuteranopia); sustenidos com L* +10.",
    colors: [
      "#0D4A74", // C4
      "#126296", // Cs4
      "#9B4507", // D4
      "#C1580C", // Ds4
      "#168763", // E4
      "#DC68AC", // F4
      "#F686C5", // Fs4
      "#E29E18", // G4
      "#F0BE76", // Gs4
      "#2FD9F4", // A4
      "#A5EEFE", // As4
      "#EAEA26", // B4
    ],
  },
};

export const NEUTRAL_CONTROL_COLOR = "#555558";
export const NEUTRAL_CONTROL_HEX = 0x555558;

export class ColorDistance {
  public static hexToRgb(hex: string): { r: number; g: number; b: number } {
    const cleaned = hex.replace("#", "");
    const bigint = parseInt(cleaned, 16);
    return {
      r: ((bigint >> 16) & 255) / 255.0,
      g: ((bigint >> 8) & 255) / 255.0,
      b: (bigint & 255) / 255.0,
    };
  }

  public static linearize(val: number): number {
    return val <= 0.04045 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
  }

  /**
   * Luminância relativa estrita WCAG 2.1 (0.0 a 1.0).
   */
  public static relativeLuminance(hex: string): number {
    const { r, g, b } = this.hexToRgb(hex);
    return 0.2126 * this.linearize(r) + 0.7152 * this.linearize(g) + 0.0722 * this.linearize(b);
  }

  /**
   * Razão de contraste WCAG 2.1 entre duas cores (1.0 a 21.0).
   */
  public static contrastRatio(hexA: string, hexB: string): number {
    const l1 = this.relativeLuminance(hexA);
    const l2 = this.relativeLuminance(hexB);
    const bright = Math.max(l1, l2);
    const dark = Math.min(l1, l2);
    return (bright + 0.05) / (dark + 0.05);
  }

  /**
   * Retorna "#ffffff" ou "#111111" garantindo o maior contraste WCAG sobre o fundo informado.
   */
  public static getContrastingText(bgHex: string): string {
    const ratioWhite = this.contrastRatio(bgHex, "#ffffff");
    const ratioBlack = this.contrastRatio(bgHex, "#111111");
    return ratioWhite >= ratioBlack ? "#ffffff" : "#111111";
  }

  /**
   * Retorna cor de borda de contraste para destacar amostras de cor sobre fundos claros ou escuros.
   */
  public static getBorderContrast(bgHex: string, panelBgHex: string = "#1c130d"): string {
    const chipLuma = this.relativeLuminance(bgHex);
    const panelLuma = this.relativeLuminance(panelBgHex);
    // Se o chip e o painel forem ambos escuros ou ambos claros, escolhe a borda de polaridade oposta
    if (chipLuma < 0.25 && panelLuma < 0.25) {
      return "#ffffff";
    }
    return chipLuma > 0.5 ? "#140e0b" : "#ffffff";
  }
}

export class ColorSchemeManager {
  private static _instance: ColorSchemeManager;

  public schemeId: ColorSchemeId = "pedagogico";
  public controlCuesEnabled: boolean = true;

  public onSchemeChanged?: (schemeId: ColorSchemeId) => void;
  public onControlCuesChanged?: (enabled: boolean) => void;

  public static getInstance(): ColorSchemeManager {
    if (!ColorSchemeManager._instance) {
      ColorSchemeManager._instance = new ColorSchemeManager();
    }
    return ColorSchemeManager._instance;
  }

  public setScheme(schemeId: ColorSchemeId): void {
    if (this.schemeId === schemeId) return;
    this.schemeId = schemeId;
    this.onSchemeChanged?.(this.schemeId);
  }

  public setControlCuesEnabled(enabled: boolean): void {
    if (this.controlCuesEnabled === enabled) return;
    this.controlCuesEnabled = enabled;
    this.onControlCuesChanged?.(this.controlCuesEnabled);
  }

  public getColor(noteKey: string, forControl: boolean = false): string {
    if (forControl && !this.controlCuesEnabled) {
      return NEUTRAL_CONTROL_COLOR;
    }
    const idx = NOTE_KEYS.indexOf(noteKey);
    if (idx < 0) return NEUTRAL_CONTROL_COLOR;
    return COLOR_SCHEMES[this.schemeId].colors[idx] || NEUTRAL_CONTROL_COLOR;
  }

  public getColorHexNumber(noteKey: string, forControl: boolean = false): number {
    const hex = this.getColor(noteKey, forControl);
    return parseInt(hex.replace("#", "0x"), 16);
  }
}
