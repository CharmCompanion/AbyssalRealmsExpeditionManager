@tool
extends EditorScript

const ROOT_PATH := "res://assets/tilesets/fantasy_iso"

func _run() -> void:
	var paths: Array[String] = []
	_collect_tilesets(ROOT_PATH, paths)
	if paths.is_empty():
		push_warning("[Cleanup] No TileSet resources found under: %s" % ROOT_PATH)
		return

	var deleted: Array[String] = []
	for path in paths:
		var ts := load(path) as TileSet
		if ts == null:
			continue
		if _tileset_is_bad(ts):
			if _delete_resource(path):
				deleted.append(path)

	if deleted.is_empty():
		print("[Cleanup] No bad TileSets found.")
	else:
		print("[Cleanup] Deleted TileSets:")
		for p in deleted:
			print("  - ", p)


func _tileset_is_bad(ts: TileSet) -> bool:
	var source_count := ts.get_source_count()
	for i in range(source_count):
		var source_id := ts.get_source_id(i)
		var source := ts.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		if atlas.texture == null:
			continue
		var tex_size := atlas.texture.get_size()
		var tex_size_i := Vector2i(tex_size)
		var region_size_i := Vector2i(atlas.texture_region_size)
		var tile_count := atlas.get_tiles_count()
		# If a single-tile image has multiple tile coords, it's corrupted.
		if region_size_i == tex_size_i and tile_count > 1:
			return true
		# Also mark as bad if the only tile isn't at (0, 0).
		if region_size_i == tex_size_i and tile_count == 1:
			var coords := atlas.get_tile_id(0)
			if coords != Vector2i(0, 0):
				return true
	return false


func _delete_resource(path: String) -> bool:
	var abs_path := ProjectSettings.globalize_path(path)
	var err := DirAccess.remove_absolute(abs_path)
	if err != OK:
		push_warning("[Cleanup] Failed to delete: %s" % path)
		return false
	return true


func _collect_tilesets(root: String, out: Array[String]) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var path := root.path_join(name)
		if dir.current_is_dir():
			_collect_tilesets(path, out)
		elif name.to_lower().ends_with(".tres"):
			out.append(path)
	dir.list_dir_end()
