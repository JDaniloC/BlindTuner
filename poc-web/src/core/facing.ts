import { NOTES, NOTE_KEYS, nearestNoteForFrequency } from "./notes";
import { IsoMath } from "./iso";

export class FacingMath {
  /**
   * Ângulo de tela em radianos para uma direção de grid (dx, dy).
   * Usa a projeção isométrica 2:1 real (screenX = dx - dy, screenY = (dx + dy) * 0.5).
   */
  static angleForGridDirection(dx: number, dy: number): number {
    if (dx === 0 && dy === 0) return Math.PI * 0.5; // padrão: frente
    const proj = IsoMath.project({ x: dx, y: dy, z: 0 });
    return Math.atan2(proj.y, proj.x);
  }

  /**
   * Ângulo de tela para uma nota nominal (ex: "C4", "Cs4", "D4").
   * Se for nota de movimento, calcula via projeção isométrica do grid.
   * Se for ação/descanso, mapeia proporcionalmente no círculo cromático de 360°.
   */
  static angleForNote(noteKey: string): number {
    const note = NOTES[noteKey];
    if (!note) return Math.PI * 0.5;
    if (note.isMovement) {
      return FacingMath.angleForGridDirection(note.direction.x, note.direction.y);
    }
    // Mapeamento angular cromático contínuo para notas de ação
    return ((note.angle + 90) % 360) * (Math.PI / 180.0);
  }

  /**
   * Ângulo contínuo de rotação para qualquer frequência em Hz (ex: modo Scroll de Cello).
   * Interpola suavemente (via menor arco de círculo) entre todas as 12 notas cromáticas,
   * permitindo um giro de 360° fluido e ininterrupto por toda a extensão do braço de afinação.
   */
  static angleForFrequency(freqHz: number): number {
    const keys = NOTE_KEYS;
    if (freqHz <= NOTES[keys[0]].freq) {
      return FacingMath.angleForNote(keys[0]);
    }
    const lastKey = keys[keys.length - 1];
    if (freqHz >= NOTES[lastKey].freq) {
      return FacingMath.angleForNote(lastKey);
    }

    for (let i = 0; i < keys.length - 1; i++) {
      const k0 = keys[i];
      const k1 = keys[i + 1];
      const f0 = NOTES[k0].freq;
      const f1 = NOTES[k1].freq;
      if (freqHz >= f0 && freqHz <= f1) {
        const t = (freqHz - f0) / (f1 - f0);
        const a0 = FacingMath.angleForNote(k0);
        const a1 = FacingMath.angleForNote(k1);
        return FacingMath.lerpAngle(a0, a1, t);
      }
    }
    return FacingMath.angleForNote(nearestNoteForFrequency(freqHz));
  }

  /**
   * Interpolação linear de ângulos garantindo o caminho mais curto pelo círculo trigonométrico.
   */
  static lerpAngle(fromRad: number, toRad: number, weight: number): number {
    let diff = (toRad - fromRad) % (Math.PI * 2);
    if (diff > Math.PI) diff -= Math.PI * 2;
    if (diff < -Math.PI) diff += Math.PI * 2;
    return fromRad + diff * Math.max(0, Math.min(1, weight));
  }
}
