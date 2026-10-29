import { LEVEL_QUARTO, LEVEL_BANHEIRO, LEVEL_SALA, LevelDef } from "./level";

export interface LevelMetadata {
  id: string;
  name: string;
  category: "historia" | "suzuki";
  chapter: string;
  songTitle: string;
  composer: string;
  storyQuote: string;
  levelDef: LevelDef;
  maxTripsForThreeStars: number;
}

export interface StarEvaluation {
  stars: number;
  hasMemory: boolean; // 🏅 Memória Resgatada (chegou ao fim)
  hasEar: boolean;    // 👂 Ouvido Fino (100% de primeira)
  hasStep: boolean;   // 🦯 Passo Firme (sem colisões)
  details: {
    firstTryHits: number;
    totalNotes: number;
    wallBumps: number;
    pitchMisses: number;
    elapsedSec: number;
  };
}

export const CAMPAIGN_CATALOG: LevelMetadata[] = [
  {
    id: "ch1_quarto_radio",
    name: "Quarto do Luthier",
    category: "historia",
    chapter: "Capítulo 1: O Despertar da Memória",
    songTitle: "Lullaby (Berceuse em Sol Maior)",
    composer: "Johannes Brahms",
    storyQuote: "Nas noites calmas, a madeira repousa. Cada poro do abeto guarda a memória das canções antigas.",
    levelDef: LEVEL_QUARTO,
    maxTripsForThreeStars: 0,
  },
  {
    id: "ch1_banheiro_drip",
    name: "O Som das Gotas",
    category: "historia",
    chapter: "Capítulo 1: O Despertar da Memória",
    songTitle: "Minueto em Sol Maior, BWV Anh. 114",
    composer: "Johann Sebastian Bach",
    storyQuote: "O ritmo da água contra a porcelana afinou meus passos. Até o gotejar da torneira tem compasso.",
    levelDef: LEVEL_BANHEIRO,
    maxTripsForThreeStars: 0,
  },
  {
    id: "ch1_sala_pendulo",
    name: "A Sala de Estar e Música",
    category: "historia",
    chapter: "Capítulo 1: O Despertar da Memória",
    songTitle: "Canção de Maio (K. 596)",
    composer: "Wolfgang Amadeus Mozart",
    storyQuote: "O relógio de pêndulo ainda dita o tempo da casa. O violoncelo no suporte parece me chamar pelo nome.",
    levelDef: LEVEL_SALA,
    maxTripsForThreeStars: 0,
  },
  {
    id: "arcade_suzuki_1",
    name: "Brilha, Brilha Estrelinha",
    category: "suzuki",
    chapter: "Caderno Suzuki • Volume 1",
    songTitle: "Tema e Variações em Dó",
    composer: "Shinichi Suzuki (Tradicional)",
    storyQuote: "O primeiro degrau de todo estudante de cordas. A simplicidade onde reside a afinação perfeita.",
    levelDef: {
      ...LEVEL_QUARTO,
      id: "arcade_suzuki_1",
      name: "Caderno Suzuki: Brilha, Brilha",
      presetNotes: ["C4", "C4", "G4", "G4", "A4", "A4", "G4"],
    },
    maxTripsForThreeStars: 0,
  },
  {
    id: "arcade_suzuki_2",
    name: "Canção do Vento Ensolarado",
    category: "suzuki",
    chapter: "Caderno Suzuki • Volume 1",
    songTitle: "Canção do Vento (Song of the Wind)",
    composer: "Shinichi Suzuki",
    storyQuote: "Arcadas curtas e ágeis. Sentir a vibração do ar antes mesmo de encostar o arco na corda.",
    levelDef: {
      ...LEVEL_BANHEIRO,
      id: "arcade_suzuki_2",
      name: "Caderno Suzuki: Canção do Vento",
      presetNotes: ["E4", "F4", "G4", "G4", "F4", "E4", "D4", "C4"],
    },
    maxTripsForThreeStars: 0,
  },
  {
    id: "arcade_suzuki_3",
    name: "Coro dos Caçadores",
    category: "suzuki",
    chapter: "Caderno Suzuki • Volume 2",
    songTitle: "Coro dos Caçadores (Der Freischütz)",
    composer: "Carl Maria von Weber",
    storyQuote: "Um chamado forte e rítmico que ecoava pelas montanhas quando eu era jovem.",
    levelDef: {
      ...LEVEL_SALA,
      id: "arcade_suzuki_3",
      name: "Caderno Suzuki: Coro dos Caçadores",
      presetNotes: ["C4", "E4", "G4", "C4", "E4", "G4", "A4", "G4"],
    },
    maxTripsForThreeStars: 0,
  },
];

export class CampaignManager {
  static getLevels(): LevelMetadata[] {
    return CAMPAIGN_CATALOG;
  }

  static getLevelById(id: string): LevelMetadata | undefined {
    return CAMPAIGN_CATALOG.find((lvl) => lvl.id === id);
  }

  static getNextLevel(currentId: string): LevelMetadata | undefined {
    const idx = CAMPAIGN_CATALOG.findIndex((lvl) => lvl.id === currentId);
    if (idx >= 0 && idx < CAMPAIGN_CATALOG.length - 1) {
      return CAMPAIGN_CATALOG[idx + 1];
    }
    return undefined;
  }

  /**
   * Avalia rigorosamente a conquista das 3 estrelas categóricas (DEC-0005):
   * 1ª ⭐: Memória Resgatada (completar a travessia até o farol sonoro)
   * 2ª ⭐: Ouvido Fino (100% de precisão de afinação na 1ª tentativa, sem notas erradas)
   * 3ª ⭐: Passo Firme (nenhuma colisão física com paredes ou móveis)
   */
  static evaluateStars(
    levelMeta: LevelMetadata,
    stats: {
      firstTryHits: number;
      totalNotes: number;
      wallBumps: number;
      pitchMisses: number;
      elapsedSec: number;
    }
  ): StarEvaluation {
    const hasMemory = true; // Alcançar o final sempre garante a 1ª estrela
    const hasEar = stats.totalNotes > 0 && stats.firstTryHits >= stats.totalNotes && stats.pitchMisses === 0;
    const hasStep = stats.wallBumps <= levelMeta.maxTripsForThreeStars;

    let stars = 1;
    if (hasEar) stars++;
    if (hasStep) stars++;

    return {
      stars,
      hasMemory,
      hasEar,
      hasStep,
      details: { ...stats },
    };
  }
}
