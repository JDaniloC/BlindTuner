extends Control
## Joystick virtual circular que trava em 12 ângulos (a cada 30°) e emite a nota correspondente ao soltar.

signal note_triggered(note_key: String)

const RADIUS := 80.0
const DEAD_ZONE := 15.0

var _dragging := false
var _thumb_offset := Vector2.ZERO

@onready var _background: ColorRect = $Background
@onready var _thumb: ColorRect = $Thumb

func _ready() -> void:
    if _background and _thumb:
        _thumb.position = _background.size / 2.0 - _thumb.size / 2.0

func _gui_input(event: InputEvent) -> void:
    # Ignora scroll wheel e botões secundários — só botão esquerdo / touch.
    if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
        return
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        if event.pressed:
            _dragging = true
            _update_thumb(_local_pointer(event))
            accept_event()
        else:
            if _dragging:
                _emit_for_offset(_thumb_offset)
            _dragging = false
            _reset_thumb()
            accept_event()
    elif event is InputEventScreenDrag or event is InputEventMouseMotion:
        if _dragging:
            _update_thumb(_local_pointer(event))
            accept_event()

func _local_pointer(event: InputEvent) -> Vector2:
    if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion:
        return event.position - size / 2.0
    return Vector2.ZERO

func _update_thumb(offset: Vector2) -> void:
    _thumb_offset = offset.limit_length(RADIUS)
    var center := size / 2.0
    _thumb.position = center + _thumb_offset - _thumb.size / 2.0

func _reset_thumb() -> void:
    _thumb_offset = Vector2.ZERO
    var center := size / 2.0
    _thumb.position = center - _thumb.size / 2.0

func _emit_for_offset(offset: Vector2) -> void:
    var note := vector_to_note(offset)
    if note != "":
        note_triggered.emit(note)

## Converte um vetor 2D (relativo ao centro do joystick) numa chave de nota.
## Y negativo = norte (cima). Retorna "" se vetor está na dead zone.
func vector_to_note(v: Vector2) -> String:
    if v.length() < DEAD_ZONE:
        return ""
    # Calcular ângulo em graus, 0° = norte, sentido horário.
    var angle_rad := atan2(v.x, -v.y)
    var angle_deg := rad_to_deg(angle_rad)
    return NoteMapping.snap_angle_to_note(angle_deg)
