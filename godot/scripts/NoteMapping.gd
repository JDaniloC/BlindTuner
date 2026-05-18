extends Node
## Autoload singleton — fonte única de verdade do mapeamento nota ↔ direção ↔ frequência ↔ cor.

const NOTES := {
    "C4":  { "freq": 262, "angle":   0, "color": Color("#E91E63"), "label": "Dó",   "direction": Vector2i(-1, -1), "is_movement": true  },
    "Cs4": { "freq": 277, "angle":  30, "color": Color("#1B5E20"), "label": "Dó#",  "direction": Vector2i.ZERO,    "is_movement": false },
    "D4":  { "freq": 294, "angle":  60, "color": Color("#FF9800"), "label": "Ré",   "direction": Vector2i( 0, -1), "is_movement": true  },
    "Ds4": { "freq": 311, "angle":  90, "color": Color("#1976D2"), "label": "Ré#",  "direction": Vector2i( 1, -1), "is_movement": true  },
    "E4":  { "freq": 330, "angle": 120, "color": Color("#FBC02D"), "label": "Mi",   "direction": Vector2i.ZERO,    "is_movement": false },
    "F4":  { "freq": 349, "angle": 150, "color": Color("#7B1FA2"), "label": "Fá",   "direction": Vector2i( 1,  0), "is_movement": true  },
    "Fs4": { "freq": 370, "angle": 180, "color": Color("#388E3C"), "label": "Fá#",  "direction": Vector2i( 1,  1), "is_movement": true  },
    "G4":  { "freq": 392, "angle": 210, "color": Color("#D32F2F"), "label": "Sol",  "direction": Vector2i.ZERO,    "is_movement": false },
    "Gs4": { "freq": 415, "angle": 240, "color": Color("#00838F"), "label": "Sol#", "direction": Vector2i( 0,  1), "is_movement": true  },
    "A4":  { "freq": 440, "angle": 270, "color": Color("#FB8C00"), "label": "Lá",   "direction": Vector2i(-1,  1), "is_movement": true  },
    "As4": { "freq": 466, "angle": 300, "color": Color("#3949AB"), "label": "Lá#",  "direction": Vector2i.ZERO,    "is_movement": false },
    "B4":  { "freq": 494, "angle": 330, "color": Color("#7CB342"), "label": "Si",   "direction": Vector2i(-1,  0), "is_movement": true  },
}

## Recebe ângulo em graus, retorna a chave da nota cujo ângulo é o mais próximo.
## Normaliza para [0, 360) antes de comparar.
func snap_angle_to_note(angle_degrees: float) -> String:
    var normalized := fposmod(angle_degrees, 360.0)
    var best_key := "C4"
    var best_distance := INF
    for key in NOTES:
        var note_angle: float = NOTES[key]["angle"]
        var diff: float = absf(normalized - note_angle)
        var distance: float = minf(diff, 360.0 - diff)
        if distance < best_distance:
            best_distance = distance
            best_key = key
    return best_key

func is_movement_note(note_key: String) -> bool:
    return NOTES[note_key]["is_movement"]

func direction_for(note_key: String) -> Vector2i:
    return NOTES[note_key]["direction"]

func frequency_for(note_key: String) -> int:
    return NOTES[note_key]["freq"]

func color_for(note_key: String) -> Color:
    return NOTES[note_key]["color"]

func label_for(note_key: String) -> String:
    return NOTES[note_key]["label"]
