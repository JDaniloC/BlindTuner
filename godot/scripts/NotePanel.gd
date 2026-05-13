extends PanelContainer
## HUD mostra última nota tocada: nome, frequência, chip colorido.

@onready var _label: Label = $Margin/HBox/Label
@onready var _freq: Label = $Margin/HBox/Freq
@onready var _color_chip: ColorRect = $Margin/HBox/ColorChip

func display_note(note_key: String) -> void:
	_label.text = NoteMapping.label_for(note_key)
	_freq.text = "%d Hz" % NoteMapping.frequency_for(note_key)
	_color_chip.color = NoteMapping.color_for(note_key)
