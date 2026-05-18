extends PanelContainer
## HUD da última nota. Visibilidade dos elementos segue CueSettings.

@onready var _label: Label = $Margin/HBox/Label
@onready var _freq: Label = $Margin/HBox/Freq
@onready var _color_chip: ColorRect = $Margin/HBox/ColorChip

func _ready() -> void:
	CueSettings.cue_level_changed.connect(_on_cue_changed)
	_apply_cue()

func _on_cue_changed(_level: int) -> void:
	_apply_cue()

func _apply_cue() -> void:
	visible = CueSettings.cue_level < 3
	_label.visible = CueSettings.shows_name()
	_freq.visible = CueSettings.shows_freq()
	_color_chip.visible = CueSettings.shows_color()

func display_note(note_key: String) -> void:
	_label.text = NoteMapping.label_for(note_key)
	_freq.text = "%d Hz" % NoteMapping.frequency_for(note_key)
	_color_chip.color = NoteMapping.color_for(note_key)
