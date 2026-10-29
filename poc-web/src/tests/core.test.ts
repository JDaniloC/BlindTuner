import { describe, it, expect } from "vitest";
import { NOTES, NOTE_KEYS, nearestNoteForFrequency, isMovementNote } from "../core/notes";
import { IsoMath } from "../core/iso";
import { FacingMath } from "../core/facing";
import { Conductor, Phase } from "../core/conductor";
import { ROOM_LEVEL, isWalkable } from "../core/level";

describe("Core Logic & Bugfix Tests", () => {
  it("Notes: all 12 chromatic notes exist with valid frequencies and directions", () => {
    expect(NOTE_KEYS.length).toBe(12);
    expect(NOTES["C4"].freq).toBe(262);
    expect(NOTES["A4"].freq).toBe(440);
    expect(nearestNoteForFrequency(442)).toBe("A4");
    expect(nearestNoteForFrequency(261)).toBe("C4");
    expect(isMovementNote("C4")).toBe(true);
    expect(isMovementNote("A4")).toBe(false); // A4 é ação (pegar)
  });

  it("Iso: 2:1 projection matches Godot Iso25DCanvas specifications", () => {
    // x avança +1, +0.5 na tela; y avança -1, +0.5 na tela; z sobe -1 na tela
    const p0 = IsoMath.project({ x: 0, y: 0, z: 0 });
    expect(p0).toEqual({ x: 0, y: 0 });

    const pX = IsoMath.project({ x: 10, y: 0, z: 0 });
    expect(pX).toEqual({ x: 10, y: 5 });

    const pY = IsoMath.project({ x: 0, y: 10, z: 0 });
    expect(pY).toEqual({ x: -10, y: 5 });

    const pZ = IsoMath.project({ x: 0, y: 0, z: 10 });
    expect(pZ).toEqual({ x: 0, y: -10 });
  });

  it("Facing: cures the character turning misalignment bug", () => {
    // Para todas as 8 notas de movimento, o ângulo de rotação deve coincidir
    // perfeitamente com a direção do deslocamento de tela do passo!
    const movementKeys = NOTE_KEYS.filter((k) => NOTES[k].isMovement);
    expect(movementKeys.length).toBe(8);

    for (const key of movementKeys) {
      const note = NOTES[key];
      const proj = IsoMath.project({ x: note.direction.x, y: note.direction.y, z: 0 });
      const expectedAngle = Math.atan2(proj.y, proj.x);
      const computedAngle = FacingMath.angleForNote(key);

      // Diferença angular circular deve ser zero (< 1e-6)
      const diff = Math.atan2(Math.sin(computedAngle - expectedAngle), Math.cos(computedAngle - expectedAngle));
      expect(Math.abs(diff)).toBeLessThan(1e-6);
    }
  });

  it("Facing: continuous frequency tuning smoothly rotates 360 degrees", () => {
    const angleC4 = FacingMath.angleForFrequency(262);
    const angleCs4 = FacingMath.angleForFrequency(277);
    const angleMid = FacingMath.angleForFrequency((262 + 277) / 2);

    expect(typeof angleC4).toBe("number");
    expect(typeof angleCs4).toBe("number");
    expect(typeof angleMid).toBe("number");
  });

  it("Conductor: call-and-response loop progresses deterministically", () => {
    const conductor = new Conductor();
    const sequence = ["Cs4", "D4", "Ds4"];
    conductor.loadPreset(sequence, 0.5);

    expect(conductor.phase).toBe(Phase.IDLE);
    conductor.start();
    expect(conductor.phase).toBe(Phase.PREVIEW);

    // Tick PREVIEW
    conductor.update(0.5); // nota 0 tocada
    conductor.update(0.5); // nota 1 tocada
    conductor.update(0.5); // nota 2 tocada
    conductor.update(0.5); // fim do preview -> CALL
    expect(conductor.phase).toBe(Phase.CALL);
    expect(conductor.index).toBe(0);

    // Erro proposital: tentar F4 em vez de Cs4
    const hitWrong = conductor.submitNote("F4");
    expect(hitWrong).toBe(false);
    expect(conductor.index).toBe(0); // não avança
    expect(conductor.stats.totalTrips).toBe(1);
    expect(conductor.stats.firstTryHits).toBe(0);

    // Acerto nota 0
    const hit0 = conductor.submitNote("Cs4");
    expect(hit0).toBe(true);
    expect(conductor.index).toBe(1);
    expect(conductor.stats.firstTryHits).toBe(0); // não foi na 1ª tentativa desta nota

    // Acerto nota 1 de primeira
    const hit1 = conductor.submitNote("D4");
    expect(hit1).toBe(true);
    expect(conductor.index).toBe(2);
    expect(conductor.stats.firstTryHits).toBe(1);

    // Acerto nota 2 de primeira
    const hit2 = conductor.submitNote("Ds4");
    expect(hit2).toBe(true);
    expect(conductor.phase).toBe(Phase.REPLAY);

    // Tick REPLAY
    conductor.update(0.5);
    conductor.update(0.5);
    conductor.update(0.5);
    conductor.update(0.5);
    expect(conductor.phase).toBe(Phase.DONE);
    expect(conductor.stats.firstTryHits).toBe(2);
    expect(conductor.stats.totalTrips).toBe(1);
  });

  it("Level: room collision checks correctly protect walls and furniture", () => {
    expect(isWalkable(ROOM_LEVEL, 1, 6)).toBe(true); // start
    expect(isWalkable(ROOM_LEVEL, 6, 1)).toBe(true); // goal
    expect(isWalkable(ROOM_LEVEL, -1, 0)).toBe(false); // fora do mapa
    expect(isWalkable(ROOM_LEVEL, 1, 1)).toBe(false); // cama
  });
});
