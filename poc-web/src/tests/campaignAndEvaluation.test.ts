import { describe, it, expect, beforeEach } from "vitest";
import { CampaignManager, CAMPAIGN_CATALOG } from "../core/campaign";
import { SaveManager } from "../core/saveManager";
import { NOTES } from "../core/notes";

describe("Fase 5: Catálogo de Campanha e Caderno Suzuki", () => {
  it("carrega todos os níveis da campanha e do caderno Suzuki com metadados musicais completos", () => {
    expect(CAMPAIGN_CATALOG.length).toBeGreaterThanOrEqual(6);

    for (const lvl of CAMPAIGN_CATALOG) {
      expect(lvl.id).toBeTruthy();
      expect(lvl.name).toBeTruthy();
      expect(lvl.chapter).toBeTruthy();
      expect(lvl.songTitle).toBeTruthy();
      expect(lvl.composer).toBeTruthy();
      expect(lvl.storyQuote).toBeTruthy();
      expect(lvl.levelDef.presetNotes.length).toBeGreaterThanOrEqual(4);

      // Todas as notas devem ser válidas e com frequência definida
      for (const nKey of lvl.levelDef.presetNotes) {
        expect(NOTES[nKey]).toBeDefined();
        expect(NOTES[nKey].freq).toBeGreaterThan(0);
      }
    }
  });

  it("permite navegar para a próxima lembrança na ordem da campanha", () => {
    const first = CAMPAIGN_CATALOG[0];
    const second = CampaignManager.getNextLevel(first.id);
    expect(second).toBeDefined();
    expect(second?.id).toBe(CAMPAIGN_CATALOG[1].id);

    const last = CAMPAIGN_CATALOG[CAMPAIGN_CATALOG.length - 1];
    const afterLast = CampaignManager.getNextLevel(last.id);
    expect(afterLast).toBeUndefined();
  });
});

describe("Fase 5: Sistema de Avaliação de 3 Estrelas (DEC-0005)", () => {
  const levelMeta = CAMPAIGN_CATALOG[0];

  it("concede 3 Estrelas em travessia perfeita sem tropeços e com 100% de primeira", () => {
    const result = CampaignManager.evaluateStars(levelMeta, {
      firstTryHits: 6,
      totalNotes: 6,
      wallBumps: 0,
      pitchMisses: 0,
      elapsedSec: 12.5,
    });

    expect(result.stars).toBe(3);
    expect(result.hasMemory).toBe(true);
    expect(result.hasEar).toBe(true);
    expect(result.hasStep).toBe(true);
  });

  it("concede 2 Estrelas quando há tropeço em parede (perde Passo Firme)", () => {
    const result = CampaignManager.evaluateStars(levelMeta, {
      firstTryHits: 6,
      totalNotes: 6,
      wallBumps: 1,
      pitchMisses: 0,
      elapsedSec: 14.0,
    });

    expect(result.stars).toBe(2);
    expect(result.hasMemory).toBe(true);
    expect(result.hasEar).toBe(true);
    expect(result.hasStep).toBe(false);
  });

  it("concede 2 Estrelas quando erra a afinação (perde Ouvido Fino)", () => {
    const result = CampaignManager.evaluateStars(levelMeta, {
      firstTryHits: 5,
      totalNotes: 6,
      wallBumps: 0,
      pitchMisses: 2,
      elapsedSec: 16.0,
    });

    expect(result.stars).toBe(2);
    expect(result.hasMemory).toBe(true);
    expect(result.hasEar).toBe(false);
    expect(result.hasStep).toBe(true);
  });

  it("concede 1 Estrela (Memória Resgatada) quando há tropeços e erros de afinação", () => {
    const result = CampaignManager.evaluateStars(levelMeta, {
      firstTryHits: 4,
      totalNotes: 6,
      wallBumps: 2,
      pitchMisses: 3,
      elapsedSec: 22.0,
    });

    expect(result.stars).toBe(1);
    expect(result.hasMemory).toBe(true);
    expect(result.hasEar).toBe(false);
    expect(result.hasStep).toBe(false);
  });
});

describe("Fase 5: Persistência com SaveManager", () => {
  beforeEach(() => {
    SaveManager.getInstance().resetProgress();
  });

  it("desbloqueia níveis e grava recordes corretamente", () => {
    const save = SaveManager.getInstance();
    expect(save.isLevelUnlocked("ch1_quarto_radio")).toBe(true);

    // Desbloqueia novo nível
    save.unlockLevel("ch1_banheiro_drip");
    expect(save.isLevelUnlocked("ch1_banheiro_drip")).toBe(true);

    // Grava conclusão
    save.recordCompletion("ch1_quarto_radio", 3, 10.5, 0, 6);
    expect(save.getLevelStars("ch1_quarto_radio")).toBe(3);
    expect(save.getTotalStars()).toBe(3);

    // Tentativa subsequente com pontuação menor preserva o recorde máximo
    save.recordCompletion("ch1_quarto_radio", 1, 15.0, 2, 4);
    expect(save.getLevelStars("ch1_quarto_radio")).toBe(3);
  });

  it("persiste e recupera preferências do jogador", () => {
    const save = SaveManager.getInstance();
    save.setPreference("visionImpairment", "cataract");
    save.setPreference("cueLevel", 2);

    const prefs = save.getPreferences();
    expect(prefs.visionImpairment).toBe("cataract");
    expect(prefs.cueLevel).toBe(2);
  });
});
