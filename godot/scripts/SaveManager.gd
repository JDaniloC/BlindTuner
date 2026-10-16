extends Node
## Autoload singleton — Gerenciamento e persistência de dados do jogador.
## Salva níveis desbloqueados, estrelas, recordes e preferências.

const DEFAULT_SAVE_PATH := "user://save_data.json"
var save_file_path: String = DEFAULT_SAVE_PATH

var _data: Dictionary = {}

func _ready() -> void:
	load_data()

func get_default_data() -> Dictionary:
	return {
		"unlocked_levels": ["ch1_quarto_radio"],
		"completed_levels": {},
		"preferences": {
			"master_volume": 1.0,
			"instrument_volume": 1.0,
			"sfx_volume": 1.0,
			"preferred_input_mode": 0,
			"talkback_enabled": false
		}
	}

func get_preference(key: String, default_value = null):
	if _data.is_empty():
		load_data()
	var prefs: Dictionary = _data.get("preferences", {})
	return prefs.get(key, default_value)

func set_preference(key: String, value) -> void:
	if _data.is_empty():
		load_data()
	if not _data.has("preferences") or not (_data["preferences"] is Dictionary):
		_data["preferences"] = get_default_data()["preferences"]
	_data["preferences"][key] = value
	save_data()

func load_data() -> void:
	if not FileAccess.file_exists(save_file_path):
		_data = get_default_data()
		return
	
	var file := FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		_data = get_default_data()
		return
	
	var json_str := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK or not (json.data is Dictionary):
		_data = get_default_data()
		return
	
	_data = json.data
	# Garante chaves essenciais
	if not _data.has("unlocked_levels") or not (_data["unlocked_levels"] is Array):
		_data["unlocked_levels"] = ["ch1_quarto_radio"]
	if not _data.has("completed_levels") or not (_data["completed_levels"] is Dictionary):
		_data["completed_levels"] = {}
	if not _data.has("preferences") or not (_data["preferences"] is Dictionary):
		_data["preferences"] = get_default_data()["preferences"]

func save_data() -> bool:
	var file := FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		return false
	var json_str := JSON.stringify(_data, "\t")
	file.store_string(json_str)
	file.close()
	return true

func is_level_unlocked(level_id: String) -> bool:
	if _data.is_empty():
		load_data()
	var unlocked: Array = _data.get("unlocked_levels", [])
	if level_id in ["ch1_quarto_radio", "arcade_suzuki_1_1", "arcade_suzuki_2_1"]:
		return true
	return level_id in unlocked

func unlock_level(level_id: String) -> bool:
	if level_id.is_empty():
		return false
	if _data.is_empty():
		load_data()
	var unlocked: Array = _data.get("unlocked_levels", [])
	if not (level_id in unlocked):
		unlocked.append(level_id)
		_data["unlocked_levels"] = unlocked
		save_data()
		return true
	return false

func record_level_completion(
	level_id: String,
	stars: int,
	elapsed_sec: float,
	trips: int,
	first_try_hits: int
) -> Dictionary:
	if _data.is_empty():
		load_data()
	
	var completed: Dictionary = _data.get("completed_levels", {})
	var prev: Dictionary = completed.get(level_id, {})
	
	var prev_stars: int = int(prev.get("stars", 0))
	var best_time: float = float(prev.get("best_time", INF))
	var min_trips: int = int(prev.get("min_trips", 999999))
	
	var new_stars := maxi(stars, prev_stars)
	var new_best_time := minf(elapsed_sec, best_time)
	var new_min_trips := mini(trips, min_trips)
	
	var entry := {
		"stars": new_stars,
		"best_time": new_best_time,
		"min_trips": new_min_trips,
		"last_elapsed_sec": elapsed_sec,
		"last_first_try_hits": first_try_hits
	}
	
	completed[level_id] = entry
	_data["completed_levels"] = completed
	save_data()
	return entry

func get_level_stars(level_id: String) -> int:
	if _data.is_empty():
		load_data()
	var completed: Dictionary = _data.get("completed_levels", {})
	if completed.has(level_id):
		return int(completed[level_id].get("stars", 0))
	return 0

func get_level_record(level_id: String) -> Dictionary:
	if _data.is_empty():
		load_data()
	var completed: Dictionary = _data.get("completed_levels", {})
	return completed.get(level_id, {})

func get_total_stars() -> int:
	if _data.is_empty():
		load_data()
	var total := 0
	var completed: Dictionary = _data.get("completed_levels", {})
	for k in completed:
		total += int(completed[k].get("stars", 0))
	return total

func reset_progress() -> void:
	_data = get_default_data()
	save_data()
