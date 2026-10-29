export interface NoteInfo {
  readonly key: string;
  readonly freq: number;
  readonly angle: number;
  readonly color: string;
  readonly label: string;
  readonly direction: { readonly x: number; readonly y: number };
  readonly isMovement: boolean;
  readonly isAction: boolean;
  readonly actionId: string;
}

export const NOTES: Record<string, NoteInfo> = {
  C4:  { key: "C4",  freq: 262, angle:   0, color: "#E91E63", label: "Dó",   direction: { x: -1, y: -1 }, isMovement: true,  isAction: false, actionId: "" },
  Cs4: { key: "Cs4", freq: 277, angle:  30, color: "#1B5E20", label: "Dó#",  direction: { x:  0, y: -1 }, isMovement: true,  isAction: false, actionId: "" },
  D4:  { key: "D4",  freq: 294, angle:  60, color: "#FF9800", label: "Ré",   direction: { x:  1, y: -1 }, isMovement: true,  isAction: false, actionId: "" },
  Ds4: { key: "Ds4", freq: 311, angle:  90, color: "#1976D2", label: "Ré#",  direction: { x:  1, y:  0 }, isMovement: true,  isAction: false, actionId: "" },
  E4:  { key: "E4",  freq: 330, angle: 120, color: "#FBC02D", label: "Mi",   direction: { x:  1, y:  1 }, isMovement: true,  isAction: false, actionId: "" },
  F4:  { key: "F4",  freq: 349, angle: 150, color: "#7B1FA2", label: "Fá",   direction: { x:  0, y:  1 }, isMovement: true,  isAction: false, actionId: "" },
  Fs4: { key: "Fs4", freq: 370, angle: 180, color: "#388E3C", label: "Fá#",  direction: { x: -1, y:  1 }, isMovement: true,  isAction: false, actionId: "" },
  G4:  { key: "G4",  freq: 392, angle: 210, color: "#795548", label: "Sol",  direction: { x: -1, y:  0 }, isMovement: true,  isAction: false, actionId: "" },
  Gs4: { key: "Gs4", freq: 415, angle: 240, color: "#00838F", label: "Sol#", direction: { x:  0, y:  0 }, isMovement: false, isAction: true,  actionId: "interagir" },
  A4:  { key: "A4",  freq: 440, angle: 270, color: "#FB8C00", label: "Lá",   direction: { x:  0, y:  0 }, isMovement: false, isAction: true,  actionId: "pegar" },
  As4: { key: "As4", freq: 466, angle: 300, color: "#3949AB", label: "Lá#",  direction: { x:  0, y:  0 }, isMovement: false, isAction: true,  actionId: "correr" },
  B4:  { key: "B4",  freq: 494, angle: 330, color: "#7CB342", label: "Si",   direction: { x:  0, y:  0 }, isMovement: false, isAction: true,  actionId: "pular" },
};

export const NOTE_KEYS: readonly string[] = Object.keys(NOTES);

export function nearestNoteForFrequency(freqHz: number): string {
  let bestKey = "C4";
  let bestDist = Infinity;
  for (const key of NOTE_KEYS) {
    const dist = Math.abs(freqHz - NOTES[key].freq);
    if (dist < bestDist) {
      bestDist = dist;
      bestKey = key;
    }
  }
  return bestKey;
}

export function isRest(noteKey: string): boolean {
  return noteKey === "REST" || noteKey === "PAUSE";
}

export function isMovementNote(noteKey: string): boolean {
  if (isRest(noteKey) || !(noteKey in NOTES)) return false;
  return NOTES[noteKey].isMovement;
}

export function snapAngleToNote(angleDeg: number, movementOnly: boolean = false): string {
  let normalized = angleDeg % 360.0;
  if (normalized < 0) normalized += 360.0;

  let bestKey = "C4";
  let bestDistance = Infinity;
  let movementIdx = 0;

  for (const key of NOTE_KEYS) {
    const note = NOTES[key];
    if (movementOnly && !note.isMovement) continue;

    const noteAngle = movementOnly ? movementIdx * 45.0 : note.angle;
    if (movementOnly) movementIdx++;

    const diff = Math.abs(normalized - noteAngle);
    const distance = Math.min(diff, 360.0 - diff);
    const roundedDist = Math.round(distance * 1e6) / 1e6;
    const roundedBest = Math.round(bestDistance * 1e6) / 1e6;

    if (roundedDist < roundedBest) {
      bestDistance = distance;
      bestKey = key;
    }
  }
  return bestKey;
}
