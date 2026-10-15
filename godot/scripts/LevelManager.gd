extends Node
## Autoload singleton — Gerencia o ciclo de vida dos níveis, pontuação e progressão.

signal level_selected(level_data)
signal level_completed(level_data, summary: Dictionary)

const LevelCatalogScript := preload("res://scripts/LevelCatalog.gd")
const LevelDataScript := preload("res://scripts/LevelData.gd")

var current_level = null
var is_sandbox: bool = true

func _ready() -> void:
	if current_level == null:
		var first = LevelCatalog.get_first_level()
		if first != null:
			current_level = first

func select_level(level_id: String) -> bool:
	var lvl = LevelCatalog.by_id(level_id)
	if lvl == null:
		return false
	current_level = lvl
	level_selected.emit(current_level)
	return true

func get_current_level():
	if current_level == null:
		current_level = LevelCatalog.get_first_level()
	return current_level

func calculate_stars(level, stats: Dictionary) -> int:
	if level == null:
		return 0
	
	# Estrela 1: Conclusão do nível
	var stars := 1
	
	# Estrela 2: Ouvido Fino (todas as notas acertadas na primeira tentativa)
	var first_try_hits: int = int(stats.get("first_try_hits", 0))
	var total_notes: int = int(stats.get("total_notes", level.total_steps()))
	if total_notes > 0 and first_try_hits >= total_notes:
		stars += 1
	
	# Estrela 3: Passo Firme (sem tropeços ou dentro da tolerância do nível)
	var total_trips: int = int(stats.get("total_trips", 0))
	if total_trips <= level.max_trips_for_three_stars:
		stars += 1
	
	return stars

func complete_level(stats: Dictionary) -> Dictionary:
	if current_level == null:
		return {}
	
	var stars := calculate_stars(current_level, stats)
	var elapsed: float = float(stats.get("elapsed_sec", 0.0))
	var trips: int = int(stats.get("total_trips", 0))
	var first_try: int = int(stats.get("first_try_hits", 0))
	
	var prev_stars := SaveManager.get_level_stars(current_level.id)
	SaveManager.record_level_completion(current_level.id, stars, elapsed, trips, first_try)
	
	var next_level = LevelCatalog.get_next_level(current_level.id)
	var new_unlock := false
	var next_id := ""
	
	if next_level != null:
		next_id = next_level.id
		if not SaveManager.is_level_unlocked(next_id):
			SaveManager.unlock_level(next_id)
			new_unlock = true
	
	var summary := {
		"level_id": current_level.id,
		"stars": stars,
		"is_new_high_score": stars > prev_stars,
		"elapsed_sec": elapsed,
		"trips": trips,
		"first_try_hits": first_try,
		"has_next_level": next_level != null,
		"next_level_id": next_id,
		"is_new_unlock": new_unlock
	}
	
	level_completed.emit(current_level, summary)
	return summary
