@tool
extends EditorScript

const ROOT_PATH := "res://assets/tilesets/fantasy_iso"
const TILE_IMAGE_SIZE := Vector2i(128, 256)
const TILE_FOOTPRINT := Vector2i(128, 64)
const PIVOT_X := 0.5
# Pivot is given from bottom in the pack docs.
const PIVOT_Y_FROM_BOTTOM := 0.18
const PIVOT_Y_FROM_TOP := 1.0 - PIVOT_Y_FROM_BOTTOM

func _run() -> void:
	var paths: Array[String] = []
	_collect_tilesets(ROOT_PATH, paths)
	if paths.is_empty():
		push_warning("[IsoSetup] No TileSet resources found under: %s" % ROOT_PATH)
		return

	for path in paths:
		var ts := load(path) as TileSet
		if ts == null:
			push_warning("[IsoSetup] Failed to load TileSet: %s" % path)
			continue
		# Apply isometric settings (128x64 footprint for 128x256 textures).
		ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
		ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
		ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		# 2:1 footprint for the pack's 128x256 tiles.
		ts.tile_size = TILE_FOOTPRINT
		
		# Set texture_region_size on each atlas source
		var source_count: int = ts.get_source_count()
		for i in range(source_count):
			var source_id: int = ts.get_source_id(i)
			var source: TileSetSource = ts.get_source(source_id)
			if source and source is TileSetAtlasSource:
				var atlas := source as TileSetAtlasSource
				var tex_size := TILE_IMAGE_SIZE
				if atlas.texture:
					tex_size = atlas.texture.get_size()
				var tile_count := atlas.get_tiles_count()
				# Only force region size for single-tile PNG atlases.
				if tile_count == 1 and tex_size == TILE_IMAGE_SIZE:
					atlas.texture_region_size = tex_size
				for t in range(tile_count):
					var coords := atlas.get_tile_id(t)
					if atlas.has_tile(coords):
						var data := atlas.get_tile_data(coords, 0)
						if data and tex_size == TILE_IMAGE_SIZE:
							# Align pack pivot to the diamond center.
							var origin_x := int(round(TILE_FOOTPRINT.x * 0.5 - tex_size.x * PIVOT_X))
							var origin_y := int(round(TILE_FOOTPRINT.y * 0.5 - tex_size.y * PIVOT_Y_FROM_TOP))
							data.texture_origin = Vector2i(origin_x, origin_y)
		
		if ResourceSaver.save(ts, path) != OK:
			push_warning("[IsoSetup] Failed to save TileSet: %s" % path)

	print("[IsoSetup] Updated TileSets:", paths.size())


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


func _guess_tile_size(ts: TileSet) -> Vector2i:
	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var size: Vector2i = atlas.get_tile_size()
		if size != Vector2i.ZERO:
			return size
	return Vector2i.ZERO
