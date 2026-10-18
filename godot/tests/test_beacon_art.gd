extends GutTest
## Cobra que a miniatura de todo farol do catálogo exista de verdade no disco.
## Sem isto, um caminho errado só deixa o card do Diário sem imagem, em silêncio.

const BeaconArt := preload("res://scripts/BeaconArt.gd")

func test_every_mapped_path_exists_on_disk():
	for id in BeaconArt.PATHS:
		var p: String = BeaconArt.PATHS[id]
		assert_true(FileAccess.file_exists(p), "Farol '%s' aponta para arquivo inexistente: %s" % [id, p])

func test_every_mapped_beacon_yields_a_texture():
	for id in BeaconArt.PATHS:
		assert_not_null(BeaconArt.texture_for(id), "Farol '%s' não gerou textura" % id)

func test_every_catalog_beacon_has_art_or_is_declared_missing():
	for lvl in LevelCatalog.ALL:
		var id: String = lvl.beacon_sound_id
		if id.is_empty():
			continue
		var known: bool = BeaconArt.PATHS.has(id) or id in BeaconArt.SEM_ARTE
		assert_true(known, "Farol '%s' (fase %s) sem miniatura: mapeie em BeaconArt.PATHS ou declare em SEM_ARTE" % [id, lvl.id])
