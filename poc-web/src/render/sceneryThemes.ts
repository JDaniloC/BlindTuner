/**
 * Paletas visuais e definições temáticas dos cômodos da Casa do Sr. Arthur.
 * Espelha fielmente SceneryTheme.gd e SceneryThemes.gd da versão Godot.
 */

export interface SceneryTheme {
  id: string;
  label: string;
  floorA: number;
  floorB: number;
  wallTop: number;
  wallFront: number;
  wallOutline: number;
  goalMarkerColor: number;
  floorType: "parquet" | "tiles" | "herringbone";
}

export const SCENERY_THEMES: Record<string, SceneryTheme> = {
  quarto: {
    id: "quarto",
    label: "Quarto Aconchegante",
    floorA: 0x8b5a2b,
    floorB: 0x7a4f25,
    wallTop: 0x7a6448,
    wallFront: 0x5a4530,
    wallOutline: 0x2a1f18,
    goalMarkerColor: 0xffd27a,
    floorType: "parquet",
  },
  banheiro: {
    id: "banheiro",
    label: "Banheiro Retrô",
    floorA: 0xe8e4d8,
    floorB: 0xd8d4c8,
    wallTop: 0xc8d0d8,
    wallFront: 0xaab4c0,
    wallOutline: 0x5a6470,
    goalMarkerColor: 0x66ccff,
    floorType: "tiles",
  },
  sala: {
    id: "sala",
    label: "Sala de Estar de Música",
    floorA: 0xc8a878,
    floorB: 0xb89868,
    wallTop: 0x8b7858,
    wallFront: 0x6b5840,
    wallOutline: 0x3a2d1e,
    goalMarkerColor: 0xffa040,
    floorType: "herringbone",
  },
};

export class SceneryThemes {
  static getTheme(themeId: string): SceneryTheme {
    return SCENERY_THEMES[themeId] || SCENERY_THEMES.quarto;
  }

  static getAll(): SceneryTheme[] {
    return Object.values(SCENERY_THEMES);
  }
}
