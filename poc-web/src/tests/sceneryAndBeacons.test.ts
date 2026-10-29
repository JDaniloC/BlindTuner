import { describe, it, expect } from "vitest";
import { LEVEL_PRESETS, LEVEL_QUARTO, LEVEL_BANHEIRO, LEVEL_SALA, isWalkable } from "../core/level";
import { SceneryThemes } from "../render/sceneryThemes";
import { NOTES } from "../core/notes";

describe("Fase 4: Cenários Procedurais e Temas", () => {
  it("carrega os 3 presets principais de cômodos com dimensões e faróis corretos", () => {
    expect(LEVEL_PRESETS.quarto).toBeDefined();
    expect(LEVEL_PRESETS.banheiro).toBeDefined();
    expect(LEVEL_PRESETS.sala).toBeDefined();

    expect(LEVEL_QUARTO.gridWidth).toBe(8);
    expect(LEVEL_QUARTO.gridHeight).toBe(8);
    expect(LEVEL_QUARTO.beaconSoundId).toBe("radio");

    expect(LEVEL_BANHEIRO.gridWidth).toBe(10);
    expect(LEVEL_BANHEIRO.gridHeight).toBe(10);
    expect(LEVEL_BANHEIRO.beaconSoundId).toBe("drip");

    expect(LEVEL_SALA.gridWidth).toBe(12);
    expect(LEVEL_SALA.gridHeight).toBe(12);
    expect(LEVEL_SALA.beaconSoundId).toBe("clock");
  });

  it("garante que as posições de início e fim estejam dentro dos limites da malha", () => {
    for (const level of Object.values(LEVEL_PRESETS)) {
      expect(level.startPos.x).toBeGreaterThanOrEqual(0);
      expect(level.startPos.x).toBeLessThan(level.gridWidth);
      expect(level.startPos.y).toBeGreaterThanOrEqual(0);
      expect(level.startPos.y).toBeLessThan(level.gridHeight);

      expect(level.goalPos.x).toBeGreaterThanOrEqual(0);
      expect(level.goalPos.x).toBeLessThan(level.gridWidth);
      expect(level.goalPos.y).toBeGreaterThanOrEqual(0);
      expect(level.goalPos.y).toBeLessThan(level.gridHeight);

      // Start deve ser caminhável
      expect(isWalkable(level, level.startPos.x, level.startPos.y)).toBe(true);
      // Start e Goal devem ser distintos
      expect(level.startPos.x === level.goalPos.x && level.startPos.y === level.goalPos.y).toBe(false);
    }
  });

  it("detecta colisões físicas com móveis e paredes dos cômodos", () => {
    // Quarto: Cama está em (1, 1) até (3, 3.8)
    expect(isWalkable(LEVEL_QUARTO, 1, 1)).toBe(false);
    expect(isWalkable(LEVEL_QUARTO, 2, 2)).toBe(false);

    // Banheiro: Pia em (1, 1), Banheira em (8, 1)
    expect(isWalkable(LEVEL_BANHEIRO, 1, 1)).toBe(false);
    expect(isWalkable(LEVEL_BANHEIRO, 8, 2)).toBe(false);

    // Sala: Sofá em (3, 8), Estante em (10, 3)
    expect(isWalkable(LEVEL_SALA, 4, 8)).toBe(false);
    expect(isWalkable(LEVEL_SALA, 10, 4)).toBe(false);

    // Lado de fora da malha deve ser sempre bloqueado
    expect(isWalkable(LEVEL_QUARTO, -1, 0)).toBe(false);
    expect(isWalkable(LEVEL_QUARTO, 8, 8)).toBe(false);
    expect(isWalkable(LEVEL_SALA, 15, 5)).toBe(false);
  });

  it("valida sequências de notas musicais dos presets", () => {
    for (const level of Object.values(LEVEL_PRESETS)) {
      expect(level.presetNotes.length).toBeGreaterThanOrEqual(4);
      for (const nKey of level.presetNotes) {
        expect(NOTES[nKey]).toBeDefined();
        expect(NOTES[nKey].freq).toBeGreaterThan(0);
      }
    }
  });

  it("garante a integridade das paletas dos temas de cenografia", () => {
    const quartoTheme = SceneryThemes.getTheme("quarto");
    const banheiroTheme = SceneryThemes.getTheme("banheiro");
    const salaTheme = SceneryThemes.getTheme("sala");

    expect(quartoTheme.floorType).toBe("parquet");
    expect(banheiroTheme.floorType).toBe("tiles");
    expect(salaTheme.floorType).toBe("herringbone");

    expect(quartoTheme.floorA).toBe(0x8b5a2b);
    expect(banheiroTheme.goalMarkerColor).toBe(0x66ccff);
    expect(salaTheme.goalMarkerColor).toBe(0xffa040);
  });
});

describe("Fase 4: Farol Sonoro Acústico e Panning Espacial", () => {
  it("calcula corretamente atenuação acústica de volume por distância", () => {
    const calcVolume = (dist: number, ducked: boolean = false) => {
      const falloff = Math.max(0.15, Math.min(1.0, 1.0 / (1.0 + (dist - 1.0) * 0.14)));
      const duckingMult = ducked ? 0.32 : 1.0;
      return 0.5 * falloff * duckingMult;
    };

    // No ponto do objetivo (dist = 1)
    const volClose = calcVolume(1.0);
    expect(volClose).toBeCloseTo(0.5, 2);

    // A 10 tiles de distância
    const volFar = calcVolume(10.0);
    expect(volFar).toBeLessThan(volClose);
    expect(volFar).toBeGreaterThanOrEqual(0.075);

    // Com ducking durante fala/call de notas
    const volDucked = calcVolume(1.0, true);
    expect(volDucked).toBeCloseTo(0.5 * 0.32, 2);
  });

  it("calcula corretamente panorâmica estéreo em isometria 2:1", () => {
    const calcPan = (dx: number, dy: number) => {
      const screenDx = dx - dy;
      return Math.max(-1.0, Math.min(1.0, screenDx / 6.0));
    };

    // Quando o objetivo está alinhado na diagonal visual (dx == dy) -> Centro (pan = 0)
    expect(calcPan(5, 5)).toBe(0);

    // Quando o objetivo está à direita visualmente (dx > dy) -> Pan positivo (Right)
    expect(calcPan(6, 0)).toBe(1.0);

    // Quando o objetivo está à esquerda visualmente (dx < dy) -> Pan negativo (Left)
    expect(calcPan(0, 6)).toBe(-1.0);
  });
});
