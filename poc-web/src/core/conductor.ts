export enum Phase {
  IDLE = "IDLE",
  PREVIEW = "PREVIEW",
  CALL = "CALL",
  REPLAY = "REPLAY",
  DONE = "DONE",
}

export interface ConductorStats {
  firstTryHits: number;
  pitchMisses: number;
  wallBumps: number;
  totalTrips: number;
  elapsedSec: number;
}

export type PhaseChangeCallback = (phase: Phase) => void;
export type PreviewNoteCallback = (noteKey: string, index: number) => void;
export type CallCueCallback = (noteKey: string, index: number) => void;
export type NoteResolvedCallback = (hit: boolean, index: number, noteKey: string) => void;
export type ReplayNoteCallback = (noteKey: string, index: number) => void;
export type SequenceCompleteCallback = (stats: ConductorStats) => void;

export class Conductor {
  private _phase: Phase = Phase.IDLE;
  private _notes: string[] = [];
  private _index: number = 0;
  private _beatSec: number = 0.55;
  private _timerSec: number = 0;
  private _hasFailedThisIndex: boolean = false;
  private _startTimeMs: number = 0;
  private _stats: ConductorStats = { firstTryHits: 0, pitchMisses: 0, wallBumps: 0, totalTrips: 0, elapsedSec: 0 };

  // Callbacks de eventos
  public onPhaseChanged?: PhaseChangeCallback;
  public onPreviewNote?: PreviewNoteCallback;
  public onCallCue?: CallCueCallback;
  public onNoteResolved?: NoteResolvedCallback;
  public onReplayNote?: ReplayNoteCallback;
  public onSequenceComplete?: SequenceCompleteCallback;

  get phase(): Phase {
    return this._phase;
  }

  get index(): number {
    return this._index;
  }

  get totalNotes(): number {
    return this._notes.length;
  }

  get stats(): ConductorStats {
    return { ...this._stats };
  }

  public loadPreset(notes: string[], beatSec: number = 0.55): void {
    this._notes = [...notes];
    this._beatSec = beatSec;
    this._setPhase(Phase.IDLE);
  }

  public start(): void {
    if (this._notes.length === 0) {
      this._finish();
      return;
    }
    this._stats = { firstTryHits: 0, pitchMisses: 0, wallBumps: 0, totalTrips: 0, elapsedSec: 0 };
    this._index = 0;
    this._timerSec = 0;
    this._setPhase(Phase.PREVIEW);
  }

  public getTargetNote(): string | null {
    if (this._phase !== Phase.CALL || this._index >= this._notes.length) return null;
    return this._notes[this._index];
  }

  public recordWallBump(): void {
    this._stats.wallBumps++;
    this._stats.totalTrips++;
  }

  public replayCurrentCue(): void {
    if (this._phase === Phase.CALL && this._index < this._notes.length) {
      this.onCallCue?.(this._notes[this._index], this._index);
    }
  }

  /**
   * Avanço de tempo injetável (útil tanto para loop de requestAnimationFrame quanto para testes unitários).
   */
  public update(deltaSec: number): void {
    if (this._phase === Phase.PREVIEW || this._phase === Phase.REPLAY) {
      this._timerSec += deltaSec;
      if (this._timerSec >= this._beatSec) {
        this._timerSec -= this._beatSec;
        this._advanceTimerPhase();
      }
    }
  }

  public submitNote(noteKey: string): boolean {
    if (this._phase !== Phase.CALL) return false;
    const target = this._notes[this._index];
    const hit = noteKey === target;

    if (hit) {
      if (!this._hasFailedThisIndex) {
        this._stats.firstTryHits++;
      }
      this._hasFailedThisIndex = false;
      this.onNoteResolved?.(true, this._index, target);
      this._index++;

      if (this._index >= this._notes.length) {
        this._beginReplay();
      } else {
        this.onCallCue?.(this._notes[this._index], this._index);
      }
      return true;
    } else {
      this._stats.pitchMisses++;
      this._stats.totalTrips++;
      this._hasFailedThisIndex = true;
      this.onNoteResolved?.(false, this._index, target);
      this.onCallCue?.(this._notes[this._index], this._index); // re-toca o alvo
      return false;
    }
  }

  private _setPhase(phase: Phase): void {
    if (this._phase === phase) return;
    this._phase = phase;
    this.onPhaseChanged?.(this._phase);
  }

  private _advanceTimerPhase(): void {
    if (this._phase === Phase.PREVIEW) {
      if (this._index < this._notes.length) {
        const note = this._notes[this._index];
        const idx = this._index;
        this._index++;
        this.onPreviewNote?.(note, idx);
      } else {
        this._beginCall();
      }
    } else if (this._phase === Phase.REPLAY) {
      if (this._index < this._notes.length) {
        const note = this._notes[this._index];
        const idx = this._index;
        this._index++;
        this.onReplayNote?.(note, idx);
      } else {
        this._finish();
      }
    }
  }

  private _beginCall(): void {
    this._index = 0;
    this._hasFailedThisIndex = false;
    this._startTimeMs = Date.now();
    this._setPhase(Phase.CALL);
    if (this._notes.length > 0) {
      this.onCallCue?.(this._notes[0], 0);
    }
  }

  private _beginReplay(): void {
    this._stats.elapsedSec = Math.max(0.1, (Date.now() - this._startTimeMs) / 1000.0);
    this._index = 0;
    this._timerSec = 0;
    this._setPhase(Phase.REPLAY);
  }

  private _finish(): void {
    this._setPhase(Phase.DONE);
    this.onSequenceComplete?.(this.stats);
  }
}
