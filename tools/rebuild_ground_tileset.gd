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
	var ts_path := "res://assets/tilesets/fantasy_iso/Fantasy_Ground.tres"
	var ts := TileSet.new()
	
	# Apply isometric settings
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	# 2:1 footprint for the pack's 128x256 tiles.
	ts.tile_size = TILE_FOOTPRINT
	
	# Get all ground textures
	var ground_dir := "res://imported/Map and Character/Fantasy tileset - 2D Isometric/Environment/Ground"
	var dir := DirAccess.open(ground_dir)
	if dir == null:
		push_error("[RebuildGround] Cannot open: %s" % ground_dir)
		return
	
	var textures: Array[Texture2D] = []
	var tex_names: Array[String] = []
	
	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file == "":
			break
		if file.ends_with(".png"):
			var tex_path := ground_dir.path_join(file)
			var tex := load(tex_path) as Texture2D
			if tex:
				textures.append(tex)
				tex_names.append(file)
	dir.list_dir_end()
	
	print("[RebuildGround] Found %d textures" % textures.size())
	
	# Create atlas sources
	for i in range(textures.size()):
		var atlas := TileSetAtlasSource.new()
		atlas.texture = textures[i]
		var tex_size := atlas.texture.get_size() if atlas.texture else Vector2(TILE_IMAGE_SIZE)
		var tex_size_i := Vector2i(tex_size)
		atlas.texture_region_size = tex_size_i
		atlas.separation = Vector2i(0, 0)
		atlas.margins = Vector2i(0, 0)
		
		# Each PNG is a single 128x256 tile.
		var coords := Vector2i(0, 0)
		atlas.create_tile(coords)
		var data := atlas.get_tile_data(coords, 0)
		if data:
			# Align pack pivot to the diamond center.
			var origin_x := int(round(TILE_FOOTPRINT.x * 0.5 - tex_size.x * PIVOT_X))
			var origin_y := int(round(TILE_FOOTPRINT.y * 0.5 - tex_size.y * PIVOT_Y_FROM_TOP))
			data.texture_origin = Vector2i(origin_x, origin_y)

		print("[RebuildGround] Added source %d: %s (1 tile)" % [i + 1, tex_names[i]])
	
	# Save
	if ResourceSaver.save(ts, ts_path) == OK:
		print("[RebuildGround] Saved to: %s" % ts_path)
	else:
		push_error("[RebuildGround] Failed to save!")

	_repair_tilesets(ROOT_PATH)


func _repair_tilesets(root_path: String) -> void:
	var paths: Array[String] = []
	_collect_tilesets(root_path, paths)
	if paths.is_empty():
		push_warning("[IsoSetup] No TileSet resources found under: %s" % root_path)
		return

	for path in paths:
		var ts := load(path) as TileSet
		if ts == null:
			push_warning("[IsoSetup] Failed to load TileSet: %s" % path)
			continue
		ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
		ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
		ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		ts.tile_size = TILE_FOOTPRINT

		var source_count: int = ts.get_source_count()
		for i in range(source_count):
			var source_id: int = ts.get_source_id(i)
			var source: TileSetSource = ts.get_source(source_id)
			if source and source is TileSetAtlasSource:
				var atlas := source as TileSetAtlasSource
				if atlas.texture == null:
					continue
				var tex_size := atlas.texture.get_size()
				var tex_size_i := Vector2i(tex_size)
				if tex_size_i != TILE_IMAGE_SIZE:
					# Leave non-pack atlases untouched.
					continue

				# Force single-tile atlas for 128x256 PNGs.
				atlas.texture_region_size = TILE_IMAGE_SIZE
				var existing_coords: Array[Vector2i] = []
				var tile_count := atlas.get_tiles_count()
				for t in range(tile_count):
					existing_coords.append(atlas.get_tile_id(t))
				for coords in existing_coords:
					if atlas.has_tile(coords):
						atlas.remove_tile(coords)
				atlas.create_tile(Vector2i(0, 0))
				var data := atlas.get_tile_data(Vector2i(0, 0), 0)
				if data:
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
