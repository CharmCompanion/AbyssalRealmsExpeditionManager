@tool
extends EditorScript

# TileSet Tagger (batch labeling helper)
#
# Mode "dump":
# - Reads the TileSet and writes a JSON file listing all tiles with a blank tag field.
# Mode "build_map":
# - Reads the JSON (with your filled-in tags) and writes a compact tag map.
# Mode "apply_custom_data":
# - Applies the tags directly into the TileSet's custom data layer (editor-time).
#
# Usage:
# 1) Set TILESET_PATH to the TileSet you want to tag.
# 2) Run with MODE = "dump" to create/edit the tag list.
# 3) Fill in the "tag" fields in the JSON.
# 4) Run with MODE = "build_map" to generate the final tag map.

const MODE: String = "dump" # "dump" | "build_map" | "apply_custom_data"
const TILESET_PATH: String = "res://assets/tilesets/fantasy_iso/Fantasy_Ground.tres"
const TAG_LIST_PATH: String = "res://tools/tileset_tagger/tileset_tags.json"
const TAG_MAP_PATH: String = "res://tools/tileset_tagger/tileset_tag_map.json"
const CUSTOM_DATA_LAYER: String = "tag"

func _run() -> void:
	var tileset := load(TILESET_PATH) as TileSet
	if tileset == null:
		push_error("[TileSetTagger] TileSet not found: %s" % TILESET_PATH)
		return

	if MODE == "dump":
		_dump_tileset(tileset)
		return
	if MODE == "build_map":
		_build_tag_map()
		return
	if MODE == "apply_custom_data":
		_apply_custom_data(tileset)
		return

	push_error("[TileSetTagger] Unknown MODE: %s" % MODE)


func _dump_tileset(tileset: TileSet) -> void:
	var data := {
		"tileset": TILESET_PATH,
		"entries": [],
	}

	var source_count: int = tileset.get_source_count()
	for i in range(source_count):
		var source_id: int = tileset.get_source_id(i)
		var source: TileSetSource = tileset.get_source(source_id)
		if source == null:
			continue

		var entry := {
			"source_id": source_id,
			"type": source.get_class(),
			"texture": "",
			"tiles": [],
		}

		if source is TileSetAtlasSource:
			var atlas := source as TileSetAtlasSource
			if atlas.texture != null:
				entry["texture"] = atlas.texture.resource_path
			var tiles_count: int = atlas.get_tiles_count()
			for t in range(tiles_count):
				var coords: Vector2i = atlas.get_tile_id(t)
				entry["tiles"].append({
					"atlas_coords": [coords.x, coords.y],
					"tag": "",
				})
		else:
			# Fallback for non-atlas sources.
			entry["tiles"].append({
				"atlas_coords": [0, 0],
				"tag": "",
			})

		data["entries"].append(entry)

	_write_json(TAG_LIST_PATH, data)
	print("[TileSetTagger] Wrote tag list:", TAG_LIST_PATH)


func _build_tag_map() -> void:
	var data := _read_json(TAG_LIST_PATH)
	if data.is_empty():
		push_error("[TileSetTagger] Missing or invalid tag list: %s" % TAG_LIST_PATH)
		return

	var out := {
		"tileset": String(data.get("tileset", "")),
		"tags": [],
	}

	var entries: Array = data.get("entries", [])
	for entry in entries:
		var source_id: int = int(entry.get("source_id", -1))
		var tiles: Array = entry.get("tiles", [])
		for tile in tiles:
			var tag: String = String(tile.get("tag", "")).strip_edges()
			if tag == "":
				continue
			var coords_arr: Array = tile.get("atlas_coords", [0, 0])
			var ax := int(coords_arr[0]) if coords_arr.size() > 0 else 0
			var ay := int(coords_arr[1]) if coords_arr.size() > 1 else 0
			out["tags"].append({
				"source_id": source_id,
				"atlas_coords": [ax, ay],
				"tag": tag,
			})

	_write_json(TAG_MAP_PATH, out)
	print("[TileSetTagger] Wrote tag map:", TAG_MAP_PATH)


func _apply_custom_data(tileset: TileSet) -> void:
	var data := _read_json(TAG_LIST_PATH)
	if data.is_empty():
		push_error("[TileSetTagger] Missing or invalid tag list: %s" % TAG_LIST_PATH)
		return

	var entries: Array = data.get("entries", [])
	var applied := 0

	for entry in entries:
		var source_id: int = int(entry.get("source_id", -1))
		if source_id < 0:
			continue
		var source: TileSetSource = tileset.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource

		var tiles: Array = entry.get("tiles", [])
		for tile in tiles:
			var tag: String = String(tile.get("tag", "")).strip_edges()
			if tag == "":
				continue
			var coords_arr: Array = tile.get("atlas_coords", [0, 0])
			var ax := int(coords_arr[0]) if coords_arr.size() > 0 else 0
			var ay := int(coords_arr[1]) if coords_arr.size() > 1 else 0
			var coords: Vector2i = Vector2i(ax, ay)
			var tile_data: TileData = tileset.get_tile_data(source_id, coords, 0)
			if tile_data == null:
				continue
			if tile_data.has_method("set_custom_data"):
				tile_data.set_custom_data(CUSTOM_DATA_LAYER, tag)
				applied += 1

	if ResourceSaver.save(tileset, TILESET_PATH) != OK:
		push_error("[TileSetTagger] Failed to save TileSet: %s" % TILESET_PATH)
		return

	print("[TileSetTagger] Applied custom data tags:", applied)


func _ensure_custom_data_layer(tileset: TileSet) -> int:
	if not tileset.has_method("get_custom_data_layer_count"):
		return -1
	var count: int = tileset.get_custom_data_layer_count()
	for i in range(count):
		if tileset.get_custom_data_layer_name(i) == CUSTOM_DATA_LAYER:
			return i

	if tileset.has_method("add_custom_data_layer"):
		tileset.add_custom_data_layer()
	var idx: int = tileset.get_custom_data_layer_count() - 1
	if idx < 0:
		return -1
	if tileset.has_method("set_custom_data_layer_name"):
		tileset.set_custom_data_layer_name(idx, CUSTOM_DATA_LAYER)
	if tileset.has_method("set_custom_data_layer_type"):
		tileset.set_custom_data_layer_type(idx, TYPE_STRING)
	return idx


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var result: Variant = JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		return {}
	return result as Dictionary


func _write_json(path: String, data: Dictionary) -> void:
	var text := JSON.stringify(data, "\t")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("[TileSetTagger] Failed to write: %s" % path)
		return
	f.store_string(text)
	f.close()
