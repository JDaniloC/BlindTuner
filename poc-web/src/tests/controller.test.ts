import { describe, it, expect } from "vitest";
import { CharacterController, TripReason } from "../core/characterController";
import { ROOM_LEVEL } from "../core/level";

describe("CharacterController & Special Actions Tests", () => {
  it("executes standard 1-tile walk and updates grid position", () => {
    let movedPos = { x: 0, y: 0 };
    const controller = new CharacterController(ROOM_LEVEL, {
      onMoved: (pos) => {
        movedPos = { ...pos };
      },
    });

    // Posição inicial (1, 6)
    expect(controller.gridPos).toEqual({ x: 1, y: 6 });

    // Cs4 é Nordeste: { x: 0, y: -1 } -> destino (1, 5)
    const steps = controller.handleNote("Cs4");
    expect(steps).not.toBeNull();
    expect(steps?.length).toBe(1);
    expect(steps![0].toGrid).toEqual({ x: 1, y: 5 });
    expect(steps![0].isRunning).toBe(false);
    expect(steps![0].isJumping).toBe(false);
    expect(controller.gridPos).toEqual({ x: 1, y: 5 });
    expect(movedPos).toEqual({ x: 1, y: 5 });
  });

  it("handles special actions Gs4 (Tatear) and A4 (Escutar)", () => {
    let tactileTriggered = false;
    let focusTriggered = false;

    const controller = new CharacterController(ROOM_LEVEL, {
      onTactilePulseRequested: () => {
        tactileTriggered = true;
      },
      onListeningFocusRequested: () => {
        focusTriggered = true;
      },
    });

    // Gs4: ação tátil
    const stepsGs4 = controller.handleNote("Gs4");
    expect(stepsGs4).toBeNull(); // ações não produzem deslocamento físico direto
    expect(tactileTriggered).toBe(true);

    // A4: escuta atenta
    const stepsA4 = controller.handleNote("A4");
    expect(stepsA4).toBeNull();
    expect(focusTriggered).toBe(true);
  });

  it("arms run via As4 and executes faster run on next movement note", () => {
    let armedRunState = false;
    const controller = new CharacterController(ROOM_LEVEL, {
      onArmedStateChanged: (running) => {
        armedRunState = running;
      },
    });

    // Arma corrida com As4
    controller.handleNote("As4");
    expect(controller.isArmedRun).toBe(true);
    expect(armedRunState).toBe(true);

    // Próximo passo corre
    const steps = controller.handleNote("Cs4");
    expect(steps).not.toBeNull();
    expect(steps![0].isRunning).toBe(true);
    expect(steps![0].durationSec).toBe(0.12);
    expect(controller.isArmedRun).toBe(false); // consumido!
  });

  it("arms jump via B4 and leaps 2 tiles in parabolic arc", () => {
    let armedJumpState = false;
    const controller = new CharacterController(ROOM_LEVEL, {
      onArmedStateChanged: (_running, jumping) => {
        armedJumpState = jumping;
      },
    });

    // Posiciona em (1, 6)
    controller.handleNote("B4");
    expect(controller.isArmedJump).toBe(true);
    expect(armedJumpState).toBe(true);

    // Pula para Nordeste (0, -1) -> 2 tiles vão para (1, 4)
    const steps = controller.handleNote("Cs4");
    expect(steps).not.toBeNull();
    expect(steps!.length).toBe(2);
    expect(steps![0].isJumping).toBe(true);
    expect(steps![0].jumpArcHeight).toBe(20);
    expect(steps![1].toGrid).toEqual({ x: 1, y: 4 });
    expect(controller.gridPos).toEqual({ x: 1, y: 4 });
    expect(controller.isArmedJump).toBe(false);
  });

  it("triggers wall trip when attempting to walk into a blocked obstacle or boundary", () => {
    let tripReason: TripReason | null = null;
    const controller = new CharacterController(ROOM_LEVEL, {
      onBlocked: (_dir, reason) => {
        tripReason = reason;
      },
    });

    // Posição inicial (1, 6)
    // Tenta andar para Sul (1, 1) -> (2, 7), depois (3, 8) fora dos limites (gridHeight = 8, limite é 7)
    controller.handleNote("E4"); // Sul: (2, 7) - válido
    expect(controller.gridPos).toEqual({ x: 2, y: 7 });

    const blockedSteps = controller.handleNote("E4"); // Sul: (3, 8) - fora do limite!
    expect(blockedSteps).toBeNull();
    expect(controller.isTripping).toBe(true);
    expect(tripReason).toBe(TripReason.WALL);
  });
});
