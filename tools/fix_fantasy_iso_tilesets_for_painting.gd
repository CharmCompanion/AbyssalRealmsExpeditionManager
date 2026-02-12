@tool
extends EditorScript

# Fixes the fantasy_iso TileSets so TileMap painting behaves sanely:
# - TileSet tile_size is the *footprint* (128x64) so floor tiles touch.
# - Atlas texture_region_size is the *selectable black-square cell* (128x128).
# - Keeps only the first atlas tile (0,0) per source to avoid 2x2 (4-squares) palettes and empty quadrants.

const ROOT_PATH := "res://assets/tilesets/fantasy_iso"
const REGION_SIZE := Vector2i(128, 128) # black square cell
const FOOTPRINT_SIZE := Vector2i(128, 64) # 2:1 iso footprint
const KEEP_ATLAS_COORDS := Vector2i(0, 0) # "first sprite"

# Optional: also create .backup copies of the .tres TileSets before saving.
const MAKE_TRES_BACKUPS := true

func _run() -> void:
	var paths: Array[String] = []
	_collect_tilesets(ROOT_PATH, paths)
	if paths.is_empty():
		push_warning("[IsoPaintFix] No TileSet resources found under: %s" % ROOT_PATH)
		return

	var updated := 0
	for path in paths:
		var ts := load(path) as TileSet
		if ts == null:
			push_warning("[IsoPaintFix] Failed to load TileSet: %s" % path)
			continue

		var changed := _fix_tileset(ts)
		if not changed:
			continue

		if MAKE_TRES_BACKUPS:
			_make_backup_if_missing(path)

		if ResourceSaver.save(ts, path) == OK:
			updated += 1
		else:
			push_warning("[IsoPaintFix] Failed to save TileSet: %s" % path)

	print("[IsoPaintFix] Updated TileSets:", updated, "/", paths.size())


func _fix_tileset(ts: TileSet) -> bool:
	var changed := false

	# Enforce consistent isometric grid.
	if ts.tile_shape != TileSet.TILE_SHAPE_ISOMETRIC:
		ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
		changed = true
	if ts.tile_layout != TileSet.TILE_LAYOUT_STACKED:
		ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
		changed = true
	if ts.tile_offset_axis != TileSet.TILE_OFFSET_AXIS_VERTICAL:
		ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		changed = true
	if ts.tile_size != FOOTPRINT_SIZE:
		ts.tile_size = FOOTPRINT_SIZE
		changed = true

	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null or not (source is TileSetAtlasSource):
			continue

		var atlas := source as TileSetAtlasSource
		if atlas.texture == null:
			continue

		# Enforce black-square selection region.
		if Vector2i(atlas.texture_region_size) != REGION_SIZE:
			atlas.texture_region_size = REGION_SIZE
			changed = true
		if atlas.separation != Vector2i.ZERO:
			atlas.separation = Vector2i.ZERO
			changed = true
		if atlas.margins != Vector2i.ZERO:
			atlas.margins = Vector2i.ZERO
			changed = true

		# Remove all tiles except the first one (0,0).
		var coords_to_remove: Array[Vector2i] = []
		var tile_count := atlas.get_tiles_count()
		for t in range(tile_count):
			var coords := atlas.get_tile_id(t)
			if coords != KEEP_ATLAS_COORDS:
				coords_to_remove.append(coords)

		for coords in coords_to_remove:
			if atlas.has_tile(coords):
				atlas.remove_tile(coords)
				changed = true

		# Ensure the kept tile exists.
		if not atlas.has_tile(KEEP_ATLAS_COORDS):
			atlas.create_tile(KEEP_ATLAS_COORDS)
			changed = true

		# Align the 128x128 region onto a 128x64 footprint so tiles touch.
		var data := atlas.get_tile_data(KEEP_ATLAS_COORDS, 0)
		if data != null:
			var desired_origin := Vector2i(0, FOOTPRINT_SIZE.y - REGION_SIZE.y) # (0, -64)
			if data.texture_origin != desired_origin:
				data.texture_origin = desired_origin
				changed = true

	return changed


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


func _make_backup_if_missing(res_path: String) -> void:
	# res://... -> absolute path
	var abs_path := ProjectSettings.globalize_path(res_path)
	var backup_path := abs_path + ".backup"
	if FileAccess.file_exists(backup_path):
		return
	var src := FileAccess.open(abs_path, FileAccess.READ)
	if src == null:
		push_warning("[IsoPaintFix] Backup skipped; cannot read: %s" % abs_path)
		return
	var data := src.get_buffer(src.get_length())
	src.close()
	var dst := FileAccess.open(backup_path, FileAccess.WRITE)
	if dst == null:
		push_warning("[IsoPaintFix] Backup skipped; cannot write: %s" % backup_path)
		return
	dst.store_buffer(data)
	dst.close()
