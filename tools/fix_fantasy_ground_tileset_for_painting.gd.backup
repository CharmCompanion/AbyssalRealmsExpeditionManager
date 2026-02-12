@tool
extends EditorScript

# Surgical fix for floor painting (Ground only):
# - Uses the black-square grid cell as selection size (128x128).
# - Uses a 2:1 isometric footprint (128x64) so tiles touch.
# - Keeps ONLY the first atlas tile (0,0) per source so you don't get 2x2 (4-squares) palettes or empty quadrants.

const TILESET_PATH := "res://assets/tilesets/fantasy_iso/Fantasy_Ground.tres"

const REGION_SIZE := Vector2i(128, 128) # black square cell
const FOOTPRINT_SIZE := Vector2i(128, 64) # floor footprint so neighbors touch
const KEEP_ATLAS_COORDS := Vector2i(0, 0) # "first sprite" in the sheet

const MAKE_BACKUP := true

func _run() -> void:
	var ts := load(TILESET_PATH) as TileSet
	if ts == null:
		push_error("[GroundPaintFix] Failed to load TileSet: %s" % TILESET_PATH)
		return

	var changed := _fix_tileset(ts)
	if not changed:
		print("[GroundPaintFix] No changes needed.")
		return

	if MAKE_BACKUP:
		_make_backup_if_missing(TILESET_PATH)

	if ResourceSaver.save(ts, TILESET_PATH) != OK:
		push_error("[GroundPaintFix] Failed to save TileSet: %s" % TILESET_PATH)
		return

	print("[GroundPaintFix] Updated: %s" % TILESET_PATH)


func _fix_tileset(ts: TileSet) -> bool:
	var changed := false

	# Consistent isometric grid for floor painting.
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

		# Align 128x128 onto a 128x64 footprint so neighbors touch.
		var data := atlas.get_tile_data(KEEP_ATLAS_COORDS, 0)
		if data != null:
			var desired_origin := Vector2i(0, FOOTPRINT_SIZE.y - REGION_SIZE.y) # (0, -64)
			if data.texture_origin != desired_origin:
				data.texture_origin = desired_origin
				changed = true

	return changed


func _make_backup_if_missing(res_path: String) -> void:
	var abs_path := ProjectSettings.globalize_path(res_path)
	var backup_path := abs_path + ".backup"
	if FileAccess.file_exists(backup_path):
		return
	var src := FileAccess.open(abs_path, FileAccess.READ)
	if src == null:
		push_warning("[GroundPaintFix] Backup skipped; cannot read: %s" % abs_path)
		return
	var data := src.get_buffer(src.get_length())
	src.close()
	var dst := FileAccess.open(backup_path, FileAccess.WRITE)
	if dst == null:
		push_warning("[GroundPaintFix] Backup skipped; cannot write: %s" % backup_path)
		return
	dst.store_buffer(data)
	dst.close()
