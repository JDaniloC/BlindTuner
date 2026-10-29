export interface GridPos {
  x: number;
  y: number;
}

export type ObstacleType =
  | "bed"
  | "nightstand"
  | "clock"
  | "armchair"
  | "sink"
  | "toilet"
  | "bathtub"
  | "sofa"
  | "coffee_table"
  | "bookcase"
  | "fireplace"
  | "cello_stand"
  | "wall";

export interface ObstacleDef {
  id: string;
  gridX: number;
  gridY: number;
  gridW: number;
  gridD: number;
  height: number;
  type: ObstacleType;
}

export interface LevelDef {
  id: string;
  name: string;
  themeId: string;
  beaconSoundId: "radio" | "music_box" | "drip" | "clock" | "cello_drone";
  gridWidth: number;
  gridHeight: number;
  startPos: GridPos;
  goalPos: GridPos;
  presetNotes: string[];
  obstacles: ObstacleDef[];
}

export const LEVEL_QUARTO: LevelDef = {
  id: "quarto",
  name: "Quarto Aconchegante",
  themeId: "quarto",
  beaconSoundId: "radio",
  gridWidth: 8,
  gridHeight: 8,
  startPos: { x: 1, y: 6 },
  goalPos: { x: 6, y: 1 },
  // Caminho didático: (1,6) -> (1,5) [Cs4] -> (2,4) [D4] -> (3,3) [D4] -> (4,2) [D4] -> (5,2) [Ds4] -> (6,1) [D4]
  presetNotes: ["Cs4", "D4", "D4", "D4", "Ds4", "D4"],
  obstacles: [
    // Cama de casal de madeira (1,1 até 2,3)
    { id: "bed", gridX: 1, gridY: 1, gridW: 2.0, gridD: 3.0, height: 0.55, type: "bed" },
    // Criado mudo com abajur e rádio (3,1 até 3,2)
    { id: "nightstand", gridX: 3, gridY: 1, gridW: 1.0, gridD: 2.0, height: 0.6, type: "nightstand" },
    // Relógio de pêndulo na parede NW
    { id: "clock", gridX: 5, gridY: 0, gridW: 1.0, gridD: 1.0, height: 1.8, type: "clock" },
    // Poltrona estofada de leitura
    { id: "armchair", gridX: 6, gridY: 5, gridW: 2.0, gridD: 2.0, height: 0.85, type: "armchair" },
  ],
};

export const LEVEL_BANHEIRO: LevelDef = {
  id: "banheiro",
  name: "Banheiro Retrô",
  themeId: "banheiro",
  beaconSoundId: "drip",
  gridWidth: 10,
  gridHeight: 10,
  startPos: { x: 8, y: 8 },
  goalPos: { x: 3, y: 1 },
  // Caminho didático diagonal e perpendicular
  presetNotes: ["F4", "F4", "F4", "Fs4", "G4", "Fs4", "F4", "E4"],
  obstacles: [
    // Pia de porcelana em L com espelho e torneira pingando (1,1 até 2,2)
    { id: "sink", gridX: 1, gridY: 1, gridW: 2.0, gridD: 2.0, height: 0.85, type: "sink" },
    // Vaso sanitário com caixa acoplada (7,1 até 7,2)
    { id: "toilet", gridX: 7, gridY: 1, gridW: 1.0, gridD: 2.0, height: 0.75, type: "toilet" },
    // Banheira vitoriana de porcelana com pés de latão (8,1 até 9,3)
    { id: "bathtub", gridX: 8, gridY: 1, gridW: 2.0, gridD: 3.0, height: 0.7, type: "bathtub" },
  ],
};

export const LEVEL_SALA: LevelDef = {
  id: "sala",
  name: "Sala de Estar de Música",
  themeId: "sala",
  beaconSoundId: "clock",
  gridWidth: 12,
  gridHeight: 12,
  startPos: { x: 10, y: 10 },
  goalPos: { x: 1, y: 1 },
  // Sequência musical Suzuki / Travessia ampla
  presetNotes: ["C4", "Cs4", "D4", "Ds4", "E4", "F4", "Fs4", "G4"],
  obstacles: [
    // Sofá capitonê 3 lugares (3,8 até 5,9)
    { id: "sofa", gridX: 3, gridY: 8, gridW: 3.0, gridD: 2.0, height: 0.8, type: "sofa" },
    // Mesinha de centro com livros e xícara de chá (4,6)
    { id: "coffee_table", gridX: 4, gridY: 6, gridW: 2.0, gridD: 2.0, height: 0.45, type: "coffee_table" },
    // Estante alta de partituras e livros de luthier (10,2 até 11,5)
    { id: "bookcase", gridX: 10, gridY: 2, gridW: 2.0, gridD: 4.0, height: 2.2, type: "bookcase" },
    // Relógio de pêndulo esculpido (1,4)
    { id: "clock", gridX: 1, gridY: 4, gridW: 1.0, gridD: 1.0, height: 1.9, type: "clock" },
    // Lareira rústica de tijolos na parede NW (0,7)
    { id: "fireplace", gridX: 0, gridY: 7, gridW: 1.0, gridD: 2.0, height: 1.6, type: "fireplace" },
  ],
};

export const LEVEL_PRESETS: Record<string, LevelDef> = {
  quarto: LEVEL_QUARTO,
  banheiro: LEVEL_BANHEIRO,
  sala: LEVEL_SALA,
};

// Compatibilidade retroativa com código existente
export const ROOM_LEVEL = LEVEL_QUARTO;

export function isWalkable(level: LevelDef, x: number, y: number): boolean {
  // Limites do piso
  if (x < 0 || x >= level.gridWidth || y < 0 || y >= level.gridHeight) {
    return false;
  }
  // Colisão com obstáculos
  for (const obs of level.obstacles) {
    if (
      x >= obs.gridX &&
      x < obs.gridX + obs.gridW &&
      y >= obs.gridY &&
      y < obs.gridY + obs.gridD
    ) {
      return false;
    }
  }
  return true;
}
