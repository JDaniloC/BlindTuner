import { Vector2 } from "./iso";
import { NOTES, isMovementNote, NoteInfo } from "./notes";
import { LevelDef, isWalkable } from "./level";

export enum TripReason {
  WALL = "WALL",
  NOTE_MISS = "NOTE_MISS",
}

export interface MoveStep {
  fromGrid: Vector2;
  toGrid: Vector2;
  durationSec: number;
  isRunning: boolean;
  isJumping: boolean;
  jumpArcHeight: number;
}

export interface CharacterControllerEvents {
  onMoved?: (newGrid: Vector2) => void;
  onBlocked?: (dir: Vector2, reason: TripReason) => void;
  onActionPerformed?: (actionId: string, gridPos: Vector2) => void;
  onArmedStateChanged?: (running: boolean, jumping: boolean) => void;
  onTactilePulseRequested?: (gridPos: Vector2) => void;
  onListeningFocusRequested?: () => void;
  onStepDust?: (gridPos: Vector2) => void;
}

export class CharacterController {
  public gridPos: Vector2 = { x: 1, y: 6 };
  public facingDir: Vector2 = { x: 0, y: 1 }; // Sul por padrão

  private _runNext: boolean = false;
  private _jumpNext: boolean = false;
  private _lastNoteKey: string = "";
  private _lastNoteTimeMs: number = 0;
  private _isTripping: boolean = false;
  private _level: LevelDef;
  private _events: CharacterControllerEvents;

  public readonly doubleTapWindowMs: number = 400;

  constructor(level: LevelDef, events: CharacterControllerEvents = {}) {
    this._level = level;
    this._events = events;
    this.gridPos = { ...level.startPos };
  }

  get isArmedRun(): boolean {
    return this._runNext;
  }

  get isArmedJump(): boolean {
    return this._jumpNext;
  }

  get isTripping(): boolean {
    return this._isTripping;
  }

  public setLevel(level: LevelDef): void {
    this._level = level;
    this.reset();
  }

  public reset(startPos?: Vector2): void {
    this.gridPos = startPos ? { ...startPos } : { ...this._level.startPos };
    this._runNext = false;
    this._jumpNext = false;
    this._isTripping = false;
    this._lastNoteKey = "";
    this._lastNoteTimeMs = 0;
    this._events.onArmedStateChanged?.(false, false);
  }

  public clearTrip(): void {
    this._isTripping = false;
  }

  public handleAction(actionId: string): void {
    if (this._isTripping) return;

    switch (actionId) {
      case "interagir": // Gs4 (Tatear com a bengala)
        this._events.onTactilePulseRequested?.({ ...this.gridPos });
        this._events.onActionPerformed?.("interagir", { ...this.gridPos });
        break;

      case "pegar": // A4 (Escutar o farol sonoro)
        this._events.onListeningFocusRequested?.();
        this._events.onActionPerformed?.("pegar", { ...this.gridPos });
        break;

      case "correr": // As4 (Armar corrida)
        this._runNext = !this._runNext;
        this._events.onArmedStateChanged?.(this._runNext, this._jumpNext);
        this._events.onActionPerformed?.("correr", { ...this.gridPos });
        break;

      case "pular": // B4 (Armar salto)
        this._jumpNext = !this._jumpNext;
        this._events.onArmedStateChanged?.(this._runNext, this._jumpNext);
        this._events.onActionPerformed?.("pular", { ...this.gridPos });
        break;
    }
  }

  /**
   * Processa uma nota tocada.
   * Retorna os passos de interpolação física ou null se for ação / tropeço / inválida.
   */
  public handleNote(noteKey: string): MoveStep[] | null {
    if (this._isTripping) return null;

    const note = NOTES[noteKey] as NoteInfo | undefined;
    if (!note) return null;

    if (note.isAction) {
      this.handleAction(note.actionId);
      return null;
    }

    if (!isMovementNote(noteKey)) return null;

    const dir = note.direction;
    this.facingDir = { ...dir };

    const now = performance.now();
    const isDoubleTap = noteKey === this._lastNoteKey && now - this._lastNoteTimeMs < this.doubleTapWindowMs;
    this._lastNoteKey = noteKey;
    this._lastNoteTimeMs = now;

    const running = this._runNext || isDoubleTap;
    const jumping = this._jumpNext;

    // Consome estados armados
    if (this._runNext || this._jumpNext) {
      this._runNext = false;
      this._jumpNext = false;
      this._events.onArmedStateChanged?.(false, false);
    }

    if (jumping) {
      return this._executeJump(dir, running);
    } else if (running) {
      return this._executeStep(dir, true);
    } else {
      return this._executeStep(dir, false);
    }
  }

  public handleTrip(reason: TripReason, dir?: Vector2): void {
    this._runNext = false;
    this._jumpNext = false;
    this._isTripping = true;
    this._events.onArmedStateChanged?.(false, false);
    this._events.onBlocked?.(dir || this.facingDir, reason);
  }

  private _executeStep(dir: Vector2, isRunning: boolean): MoveStep[] | null {
    const target = { x: this.gridPos.x + dir.x, y: this.gridPos.y + dir.y };

    if (!isWalkable(this._level, target.x, target.y)) {
      this.handleTrip(TripReason.WALL, dir);
      return null;
    }

    const prevGrid = { ...this.gridPos };
    this.gridPos = target;
    this._events.onMoved?.(this.gridPos);
    if (isRunning) {
      this._events.onStepDust?.(prevGrid);
    }

    return [
      {
        fromGrid: prevGrid,
        toGrid: target,
        durationSec: isRunning ? 0.12 : 0.22,
        isRunning,
        isJumping: false,
        jumpArcHeight: 0,
      },
    ];
  }

  private _executeJump(dir: Vector2, comboRun: boolean): MoveStep[] | null {
    const target1 = { x: this.gridPos.x + dir.x, y: this.gridPos.y + dir.y };
    if (!isWalkable(this._level, target1.x, target1.y)) {
      this.handleTrip(TripReason.WALL, dir);
      return null;
    }

    const target2 = { x: target1.x + dir.x, y: target1.y + dir.y };
    const prevGrid = { ...this.gridPos };

    // Se o 2º tile estiver bloqueado, salta apenas 1 tile
    if (!isWalkable(this._level, target2.x, target2.y)) {
      this.gridPos = target1;
      this._events.onMoved?.(this.gridPos);
      return [
        {
          fromGrid: prevGrid,
          toGrid: target1,
          durationSec: 0.18,
          isRunning: comboRun,
          isJumping: true,
          jumpArcHeight: 18,
        },
      ];
    }

    // Salta 2 tiles em parábola
    this.gridPos = target2;
    this._events.onMoved?.(this.gridPos);

    return [
      {
        fromGrid: prevGrid,
        toGrid: target1,
        durationSec: 0.13,
        isRunning: comboRun,
        isJumping: true,
        jumpArcHeight: 20,
      },
      {
        fromGrid: target1,
        toGrid: target2,
        durationSec: 0.13,
        isRunning: comboRun,
        isJumping: true,
        jumpArcHeight: 20,
      },
    ];
  }
}
