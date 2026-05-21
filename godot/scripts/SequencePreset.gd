extends Resource
class_name SequencePreset
## Sequência autoral de notas. Start/goal/walls vivem em MapPreset (FK via map_id).

@export var id: String = ""
@export var label: String = ""
@export var size_class: String = ""  # "curto" | "medio" | "longo"
@export var map_id: String = ""
@export var notes: Array[String] = []
