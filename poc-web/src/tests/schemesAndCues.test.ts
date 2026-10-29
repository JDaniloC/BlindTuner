import { describe, it, expect } from "vitest";
import { COLOR_SCHEMES, ColorDistance, ColorSchemeManager, NEUTRAL_CONTROL_COLOR } from "../core/colorSchemes";
import { CueSettingsManager } from "../core/cueSettings";

describe("Color Schemes & WCAG Contrast Tests", () => {
  it("Schemes: all 3 schemes define exactly 12 opaque valid hex colors", () => {
    const schemeIds = ["classico", "pedagogico", "alto_contraste"] as const;
    for (const id of schemeIds) {
      const scheme = COLOR_SCHEMES[id];
      expect(scheme).toBeDefined();
      expect(scheme.colors.length).toBe(12);

      for (let i = 0; i < 12; i++) {
        const hex = scheme.colors[i];
        expect(hex).toMatch(/^#[0-9A-Fa-f]{6}$/);
      }
    }
  });

  it("WCAG: relative luminance and contrast ratio calculations follow standard formulas", () => {
    const lumaBlack = ColorDistance.relativeLuminance("#000000");
    const lumaWhite = ColorDistance.relativeLuminance("#ffffff");

    expect(lumaBlack).toBeCloseTo(0.0, 4);
    expect(lumaWhite).toBeCloseTo(1.0, 4);

    const ratioMax = ColorDistance.contrastRatio("#000000", "#ffffff");
    expect(ratioMax).toBeCloseTo(21.0, 1);

    const ratioIdentical = ColorDistance.contrastRatio("#ff9800", "#ff9800");
    expect(ratioIdentical).toBeCloseTo(1.0, 4);
  });

  it("WCAG: contrasting text guarantees high contrast on bright and dark backgrounds", () => {
    // Fundo branco -> texto escuro
    expect(ColorDistance.getContrastingText("#ffffff")).toBe("#111111");
    // Fundo preto -> texto claro
    expect(ColorDistance.getContrastingText("#000000")).toBe("#ffffff");
    // Amarelo claro (#FFF200) -> texto escuro
    expect(ColorDistance.getContrastingText("#FFF200")).toBe("#111111");
    // Azul marinho escuro (#0D4A74) -> texto claro
    expect(ColorDistance.getContrastingText("#0D4A74")).toBe("#ffffff");
  });

  it("ColorSchemeManager: switches schemes and respects controlCuesEnabled", () => {
    const mgr = ColorSchemeManager.getInstance();
    mgr.setScheme("pedagogico");
    mgr.setControlCuesEnabled(true);

    const colC4 = mgr.getColor("C4", true);
    expect(colC4).toBe(COLOR_SCHEMES["pedagogico"].colors[0]);

    // Desliga pistas nos controles
    mgr.setControlCuesEnabled(false);
    const neutralC4 = mgr.getColor("C4", true);
    expect(neutralC4).toBe(NEUTRAL_CONTROL_COLOR);

    // Para o HUD (forControl=false), ainda mostra a cor mesmo com pistas de controle desligadas!
    const hudC4 = mgr.getColor("C4", false);
    expect(hudC4).toBe(COLOR_SCHEMES["pedagogico"].colors[0]);

    // Restaura
    mgr.setControlCuesEnabled(true);
  });
});

describe("CueSettings & Visibility Hierarchy Tests", () => {
  it("Hierarchy: correctly manages Level 0 (Tudo) through Level 3 (Só Som)", () => {
    const cueMgr = CueSettingsManager.getInstance();

    // Nível 0: Tudo (nome, freq, cor)
    cueMgr.setLevel(0);
    expect(cueMgr.showsName()).toBe(true);
    expect(cueMgr.showsFreq()).toBe(true);
    expect(cueMgr.showsColor()).toBe(true);
    expect(cueMgr.isSoundOnly()).toBe(false);

    // Nível 1: Freq + Cor (esconde nome)
    cueMgr.setLevel(1);
    expect(cueMgr.showsName()).toBe(false);
    expect(cueMgr.showsFreq()).toBe(true);
    expect(cueMgr.showsColor()).toBe(true);
    expect(cueMgr.isSoundOnly()).toBe(false);

    // Nível 2: Só Cor (esconde nome e freq)
    cueMgr.setLevel(2);
    expect(cueMgr.showsName()).toBe(false);
    expect(cueMgr.showsFreq()).toBe(false);
    expect(cueMgr.showsColor()).toBe(true);
    expect(cueMgr.isSoundOnly()).toBe(false);

    // Nível 3: Só Som (esconde nome, freq e cor)
    cueMgr.setLevel(3);
    expect(cueMgr.showsName()).toBe(false);
    expect(cueMgr.showsFreq()).toBe(false);
    expect(cueMgr.showsColor()).toBe(false);
    expect(cueMgr.isSoundOnly()).toBe(true);

    // Clamps to 0..3
    cueMgr.setLevel(99);
    expect(cueMgr.cueLevel).toBe(3);
    cueMgr.setLevel(-5);
    expect(cueMgr.cueLevel).toBe(0);
  });
});
