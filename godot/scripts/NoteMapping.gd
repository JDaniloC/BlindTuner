extends Node
## Autoload singleton — fonte única de verdade do mapeamento nota ↔ direção ↔ frequência ↔ cor.

const NOTES := {
    "C4":  { "freq": 262, "angle":   0, "color": Color("#E91E63"), "label": "Dó",   "direction": Vector2i(-1, -1), "is_movement": true,  "is_action": false, "action_id": "" },
    "Cs4": { "freq": 277, "angle":  30, "color": Color("#1B5E20"), "label": "Dó#",  "direction": Vector2i( 0, -1), "is_movement": true,  "is_action": false, "action_id": "" },
    "D4":  { "freq": 294, "angle":  60, "color": Color("#FF9800"), "label": "Ré",   "direction": Vector2i( 1, -1), "is_movement": true,  "is_action": false, "action_id": "" },
    "Ds4": { "freq": 311, "angle":  90, "color": Color("#1976D2"), "label": "Ré#",  "direction": Vector2i( 1,  0), "is_movement": true,  "is_action": false, "action_id": "" },
    "E4":  { "freq": 330, "angle": 120, "color": Color("#FBC02D"), "label": "Mi",   "direction": Vector2i( 1,  1), "is_movement": true,  "is_action": false, "action_id": "" },
    "F4":  { "freq": 349, "angle": 150, "color": Color("#7B1FA2"), "label": "Fá",   "direction": Vector2i( 0,  1), "is_movement": true,  "is_action": false, "action_id": "" },
    "Fs4": { "freq": 370, "angle": 180, "color": Color("#388E3C"), "label": "Fá#",  "direction": Vector2i(-1,  1), "is_movement": true,  "is_action": false, "action_id": "" },
    "G4":  { "freq": 392, "angle": 210, "color": Color("#795548"), "label": "Sol",  "direction": Vector2i(-1,  0), "is_movement": true,  "is_action": false, "action_id": "" },
    "Gs4": { "freq": 415, "angle": 240, "color": Color("#00838F"), "label": "Sol#", "direction": Vector2i.ZERO,    "is_movement": false, "is_action": true,  "action_id": "interagir" },
    "A4":  { "freq": 440, "angle": 270, "color": Color("#FB8C00"), "label": "Lá",   "direction": Vector2i.ZERO,    "is_movement": false, "is_action": true,  "action_id": "pegar" },
    "As4": { "freq": 466, "angle": 300, "color": Color("#3949AB"), "label": "Lá#",  "direction": Vector2i.ZERO,    "is_movement": false, "is_action": true,  "action_id": "correr" },
    "B4":  { "freq": 494, "angle": 330, "color": Color("#7CB342"), "label": "Si",   "direction": Vector2i.ZERO,    "is_movement": false, "is_action": true,  "action_id": "pular" },
}

## Recebe ângulo em graus, retorna a chave da nota cujo ângulo é o mais próximo.
## Normaliza para [0, 360) antes de comparar.
## Empates são desempatados pela ordem de inserção do dicionário (primeira nota ganha).
##
## Sem movement_only: usa o ângulo cromático de cada nota (12 posições a 30°).
## Com movement_only=true: layout direcional 8x45° (4 cardinais + 4 diagonais),
## ignorando notas de ação. Notas de movimento em ordem de inserção mapeiam para
## 0°, 45°, 90°, ..., 315° na bússola de TELA (0° = para cima):
## C4=cima, Cs4=cima-direita, D4=direita, Ds4=baixo-direita, E4=baixo,
## F4=baixo-esquerda, Fs4=esquerda, G4=cima-esquerda.
##
## Cuidado ao ler o campo "direction" de cada nota: ele é um vetor de GRID
## isométrico, NÃO uma direção de tela. Character.grid_to_world projeta
## (x-y, x+y), então cada vetor de grid cai num octante de tela diferente do
## que o vetor "parece" sugerir -- C4 = grid(-1,-1) desenha reto PARA CIMA na
## tela (e não a noroeste); Ds4 = grid(1,0) desenha para baixo-direita.
## Confundir os dois já gerou setas 45° erradas nos ícones; a tabela
## grid -> ícone de tela vive em ActionIcon.ICON_FOR_DIRECTION.
func snap_angle_to_note(angle_degrees: float, movement_only: bool = false) -> String:
    var normalized := fposmod(angle_degrees, 360.0)
    var best_key := "C4"  # sentinela; C4 é sempre is_movement=true, válido com qualquer filtro
    var best_distance := INF
    var movement_idx := 0
    for key in NOTES:
        if movement_only and not NOTES[key]["is_movement"]:
            continue
        var note_angle: float
        if movement_only:
            note_angle = float(movement_idx) * 45.0
            movement_idx += 1
        else:
            note_angle = float(NOTES[key]["angle"])
        var diff: float = absf(normalized - note_angle)
        var distance: float = minf(diff, 360.0 - diff)
        # Quantiza para 6 casas decimais para absorver drift de atan2 em empates exatos
        # (ex.: 22.5° equidistante entre C4 e D4 no layout direcional). 1e-6° << 30°,
        # então a quantização não cria falsos empates entre notas adjacentes.
        var rounded_distance := roundf(distance * 1e6) / 1e6
        var rounded_best := roundf(best_distance * 1e6) / 1e6
        if rounded_distance < rounded_best:
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

func is_action_note(note_key: String) -> bool:
    return NOTES[note_key]["is_action"]

func action_id_for(note_key: String) -> String:
    return NOTES[note_key]["action_id"]

## Retorna a chave da nota cuja frequência (Hz) é a mais próxima da informada.
## Empates são desempatados pela ordem de inserção do dicionário (primeira nota ganha),
## mesmo critério de desempate de snap_angle_to_note.
func nearest_note_for_frequency(freq_hz: float) -> String:
    var best_key := "C4"
    var best_distance := INF
    for key in NOTES:
        var distance: float = absf(freq_hz - float(NOTES[key]["freq"]))
        if distance < best_distance:
            best_distance = distance
            best_key = key
    return best_key
