extends RefCounted
## Fonte única da miniatura 2D de cada farol sonoro (beacon_sound_id).
##
## Usado pelo Diário de Memórias e pelo modal de introdução. Antes cada tela
## tinha a própria tabela, com caminhos escritos de cabeça -- e 17 dos 19
## apontavam para arquivos que não existem, sem erro nenhum na tela (o card só
## ficava sem imagem). test_beacon_art.gd agora cobra que todo farol do catálogo
## resolva para um arquivo real ou esteja listado em SEM_ARTE.
##
## Carrega por Image.load_from_file, como BaseMob.load_texture_safe: a maioria
## dos PNGs gerados por script não tem .import, então load() falharia no
## headless e no export.

const PATHS := {
	"radio": "res://assets/sprites/props/radio_vintage_48x48.png",
	# Ainda sem prop próprio: a caixinha de música fica na mesa de cabeceira.
	"music_box": "res://assets/sprites/furniture/nightstand_lamp_48x64.png",
	"drip": "res://assets/sprites/furniture/sink_bathroom_48x48.png",
	"clock": "res://assets/sprites/furniture/clock_grandfather_32x80.png",
	"gate_latch": "res://assets/sprites/props/iron_gate_48x64.png",
	"shop_bell": "res://assets/sprites/props/bakery_counter_64x48.png",
	"fountain_birds": "res://assets/sprites/props/fountain_stone_64x64.png",
	"church_bell": "res://assets/sprites/props/church_portal_64x80.png",
	"window_wind": "res://assets/sprites/props/window_breeze_48x64.png",
	"wrist_watch": "res://assets/sprites/props/reading_desk_56x48.png",
	"watering_can": "res://assets/sprites/props/hanging_fern_48x64.png",
	"tea_cup": "res://assets/sprites/props/porcelain_cupboard_48x64.png",
	"cat_bell": "res://assets/sprites/mobs/cat_mimi_32x32.png",
	"broom_sweep": "res://assets/sprites/props/broom_bucket_36x48.png",
	"keys_jingle": "res://assets/sprites/props/hallway_stand_48x64.png",
	"ocean_waves": "res://assets/sprites/props/seaside_bench_56x40.png",
	"train_whistle": "res://assets/sprites/props/station_lantern_40x64.png",
	"cello_drone": "res://assets/sprites/props/cello_stand_48x64.png",
	"wind_chimes": "res://assets/sprites/props/wind_chimes_stand_48x64.png",
	"coffee_grinder": "res://assets/sprites/props/reading_desk_56x48.png",
	"kettle_whistle": "res://assets/sprites/props/porcelain_cupboard_48x64.png",
	"loom_shuttle": "res://assets/sprites/props/yarn_basket_40x36.png",
	"accordion_drone": "res://assets/sprites/props/bakery_counter_64x48.png",
	"castanets_click": "res://assets/sprites/props/hallway_stand_48x64.png",
	"dock_bell": "res://assets/sprites/props/station_lantern_40x64.png",
	"organ_pipe": "res://assets/sprites/props/church_portal_64x80.png",
	"tambourine_shake": "res://assets/sprites/props/fountain_stone_64x64.png",
	"cathedral_echo": "res://assets/sprites/props/church_portal_64x80.png",
}

## Faróis que existem no catálogo mas ainda não têm sprite. Explícito de
## propósito: o teste reprova farol novo que não esteja em PATHS nem aqui.
const SEM_ARTE := ["bike_bell", "paper_rustle"]

static var _cache: Dictionary = {}

static func path_for(beacon_id: String) -> String:
	return PATHS.get(beacon_id, "")

static func texture_for(beacon_id: String) -> Texture2D:
	if _cache.has(beacon_id):
		return _cache[beacon_id]
	var tex: Texture2D = null
	var p := path_for(beacon_id)
	if not p.is_empty() and FileAccess.file_exists(p):
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	_cache[beacon_id] = tex
	return tex
