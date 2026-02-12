@tool
extends EditorScript

# Auto-fixes atlas selections so you only select/paint the pixels (not empty padding)
# and prevents Godot from treating each 256x256 PNG as a 2x2 (or worse) atlas.
#
# What it does:
# - For every TileSet under ROOT_PATH:
#   - For every TileSetAtlasSource with a texture:
#     - Reads the texture's Image and computes its non-transparent used rect.
#     - Sets atlas.texture_region_size = used_rect.size
#     - Sets atlas.margins = used_rect.position
#     - Sets atlas.separation = (0,0)
#     - Removes ALL tiles except atlas coord (0,0) (brute-force scan)
#     - Sets texture_origin so the bottom of the region aligns to the TileSet's tile_size.
#
# Special-case:
# - Fantasy_Ground.tres is forced to a 128x64 iso footprint so floor tiles touch.

const ROOT_PATH := "res://assets/tilesets/fantasy_iso"
const KEEP_ATLAS_COORDS := Vector2i(0, 0)

const FORCE_GROUND_FOOTPRINT := Vector2i(128, 64)

const MAKE_TRES_BACKUPS := true

func _run() -> void:
	var paths: Array[String] = []
	_collect_tilesets(ROOT_PATH, paths)
	if paths.is_empty():
		push_warning("[TightenAtlas] No TileSet resources found under: %s" % ROOT_PATH)
		return

	var updated: int = 0
	for path in paths:
		var ts := load(path) as TileSet
		if ts == null:
			push_warning("[TightenAtlas] Failed to load TileSet: %s" % path)
			continue

		var changed := _tighten_tileset(ts, path)
		if not changed:
			continue

		if MAKE_TRES_BACKUPS:
			_make_backup_if_missing(path)

		if ResourceSaver.save(ts, path) == OK:
			updated += 1
		else:
			push_warning("[TightenAtlas] Failed to save TileSet: %s" % path)

	print("[TightenAtlas] Updated TileSets:", updated, "/", paths.size())


func _tighten_tileset(ts: TileSet, res_path: String) -> bool:
	var changed: bool = false
	# Note: Wall tiles are very sensitive to per-texture anchoring differences.
	# Keeping them on the standard centered origin tends to keep corners and
	# segments aligning better than per-tile base-pixel anchoring.
	var is_wall_tileset: bool = res_path.ends_with("/Fantasy_Wall.tres")

	# For walls, compute ONE stable anchor from the *visible pixels* (used rect)
	# and apply it uniformly to every wall piece.
	# This keeps walls gap-free (all origins match) while making painting feel
	# closer to the mouse.
	var have_wall_anchor: bool = false
	var wall_anchor_center_x: float = 0.0
	var wall_anchor_bottom_y: int = 0

	# Only force footprint for the ground (so it paints as a contiguous floor).
	if res_path.ends_with("/Fantasy_Ground.tres"):
		# Ensure it is isometric.
		if ts.tile_shape != TileSet.TILE_SHAPE_ISOMETRIC:
			ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
			changed = true
		if ts.tile_layout != TileSet.TILE_LAYOUT_STACKED:
			ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
			changed = true
		if ts.tile_offset_axis != TileSet.TILE_OFFSET_AXIS_VERTICAL:
			ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
			changed = true
		if ts.tile_size != FORCE_GROUND_FOOTPRINT:
			ts.tile_size = FORCE_GROUND_FOOTPRINT
			changed = true

	var tile_footprint: Vector2i = Vector2i(ts.tile_size)
	if tile_footprint == Vector2i.ZERO:
		# Fallback to something sane; prevents divide-by-zero alignment.
		tile_footprint = Vector2i(128, 64)

	if is_wall_tileset:
		var centers: Array[float] = []
		var bottoms: Array[int] = []
		var source_count_for_anchor: int = ts.get_source_count()
		for si in range(source_count_for_anchor):
			var sid: int = ts.get_source_id(si)
			var s: TileSetSource = ts.get_source(sid)
			if s == null or not (s is TileSetAtlasSource):
				continue
			var a := s as TileSetAtlasSource
			if a.texture == null:
				continue
			var im: Image = a.texture.get_image()
			if im == null:
				continue
			var used_rect: Rect2i = im.get_used_rect()
			if used_rect.size.x <= 0 or used_rect.size.y <= 0:
				continue
			centers.append(float(used_rect.position.x) + float(used_rect.size.x) * 0.5)
			bottoms.append(int(used_rect.position.y + used_rect.size.y))

		if not centers.is_empty():
			wall_anchor_center_x = _median_float(centers)
			wall_anchor_bottom_y = _median_int(bottoms)
			have_wall_anchor = true

	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null or not (source is TileSetAtlasSource):
			continue

		var atlas := source as TileSetAtlasSource
		if atlas.texture == null:
			continue

		var img: Image = atlas.texture.get_image()
		if img == null:
			continue

		var tex_size := Vector2i(atlas.texture.get_size())
		if tex_size.x <= 0 or tex_size.y <= 0:
			continue

		# Compute bounds of visible pixels.
		var used_pixels: Rect2i = img.get_used_rect()
		if used_pixels.size.x <= 0 or used_pixels.size.y <= 0:
			# Fully empty/transparent texture; leave it alone.
			continue

		# Compute selection region.
		# Most tiles: tight bounds of non-transparent pixels.
		# Walls: keep the original full texture canvas so corners/segments align.
		var used: Rect2i = used_pixels
		if is_wall_tileset:
			used = Rect2i(Vector2i.ZERO, tex_size)

		# Apply selection rect.
		var desired_region_size: Vector2i = Vector2i(used.size)
		var desired_margins: Vector2i = Vector2i(used.position)
		if is_wall_tileset:
			desired_margins = Vector2i.ZERO

		if Vector2i(atlas.texture_region_size) != desired_region_size:
			atlas.texture_region_size = desired_region_size
			changed = true
		if atlas.margins != desired_margins:
			atlas.margins = desired_margins
			changed = true
		if atlas.separation != Vector2i.ZERO:
			atlas.separation = Vector2i.ZERO
			changed = true

		# Brutally remove all tiles except (0,0), without relying on get_tiles_count().
		# Godot can keep stray coords in the resource even when tile enumeration is weird.
		var region: Vector2i = Vector2i(atlas.texture_region_size)
		var denom_x: int = region.x
		if denom_x < 1:
			denom_x = 1
		var denom_y: int = region.y
		if denom_y < 1:
			denom_y = 1
		var max_cols: int = int(ceil(float(tex_size.x) / float(denom_x))) + 2
		var max_rows: int = int(ceil(float(tex_size.y) / float(denom_y))) + 2

		for y in range(max_rows):
			for x in range(max_cols):
				var c := Vector2i(x, y)
				if c == KEEP_ATLAS_COORDS:
					continue
				if atlas.has_tile(c):
					atlas.remove_tile(c)
					changed = true

		if not atlas.has_tile(KEEP_ATLAS_COORDS):
			atlas.create_tile(KEEP_ATLAS_COORDS)
			changed = true

		# Align the texture so tiles snap flush.
		# Default:
		# - center horizontally in the footprint
		# - align region bottom to footprint bottom
		var desired_origin: Vector2i = Vector2i(
			int(floor((tile_footprint.x - region.x) * 0.5)),
			tile_footprint.y - region.y
		)

		# Walls: keep a consistent origin (based on the full canvas) so that
		# segments and corners always connect without gaps.
		# Apply a uniform anchor (computed once) so painting feels closer to mouse
		# without breaking alignment.
		if is_wall_tileset and have_wall_anchor:
			desired_origin = Vector2i(
				int(round(float(tile_footprint.x) * 0.5 - wall_anchor_center_x)),
				tile_footprint.y - wall_anchor_bottom_y
			)

		# Walls: using the full texture canvas already preserves the intended alignment.

		# Use the tile footprint bottom point for Y-sorting.
		# TileMapLayer.map_to_local() returns the centered cell position, so the bottom
		# point of the footprint is roughly +tile_size.y/2.
		var desired_y_sort_origin: int = int(tile_footprint.y / 2.0)

		var data := atlas.get_tile_data(KEEP_ATLAS_COORDS, 0)
		if data != null:
			if data.texture_origin != desired_origin:
				data.texture_origin = desired_origin
				changed = true
			if data.y_sort_origin != desired_y_sort_origin:
				data.y_sort_origin = desired_y_sort_origin
				changed = true

	return changed


func _median_float(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	values.sort()
	var mid: int = values.size() / 2
	if values.size() % 2 == 1:
		return float(values[mid])
	return (float(values[mid - 1]) + float(values[mid])) * 0.5


func _median_int(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	values.sort()
	var mid: int = values.size() / 2
	if values.size() % 2 == 1:
		return int(values[mid])
	return int(round((float(values[mid - 1]) + float(values[mid])) * 0.5))


func _compute_base_anchor(img: Image, used: Rect2i) -> Vector2i:
	# Returns a point (x,y) in the used-rect coordinate space.
	# We scan a small band near the bottom and pick the row with the *most* opaque
	# pixels (stable against 1px shadows/stray pixels), then use the mid-point of
	# that row as the X anchor.
	var w := used.size.x
	var h := used.size.y
	if w <= 0 or h <= 0:
		return Vector2i(0, 0)

	var alpha_eps: float = 0.001
	var min_pixels: int = 6
	var band_max: int = 28

	# Find the true bottom-most opaque pixel row.
	var bottom_y := -1
	for local_y in range(h - 1, -1, -1):
		var src_y := used.position.y + local_y
		for local_x in range(w):
			var src_x := used.position.x + local_x
			if img.get_pixel(src_x, src_y).a > alpha_eps:
				bottom_y = local_y
				break
		if bottom_y != -1:
			break

	if bottom_y == -1:
		return Vector2i(int(round(w * 0.5)), h - 1)

	var band_height: int = bottom_y + 1
	if band_height > band_max:
		band_height = band_max
	var best_y := bottom_y
	var best_count := -1
	var best_min_x := 0
	var best_max_x := w - 1

	for dy in range(band_height):
		var local_y := bottom_y - dy
		var min_x := w
		var max_x := -1
		var count := 0
		var src_y := used.position.y + local_y
		for local_x in range(w):
			var src_x := used.position.x + local_x
			if img.get_pixel(src_x, src_y).a > alpha_eps:
				count += 1
				if local_x < min_x:
					min_x = local_x
				if local_x > max_x:
					max_x = local_x

		if count > best_count:
			best_count = count
			best_y = local_y
			best_min_x = min_x
			best_max_x = max_x

	# If even the densest row is extremely sparse, fall back to bottom-center.
	if best_count < min_pixels or best_max_x < 0:
		return Vector2i(int(round(w * 0.5)), bottom_y)

	return Vector2i(int(round((best_min_x + best_max_x) * 0.5)), best_y)

	# (unreachable)
	return Vector2i(int(round(w * 0.5)), bottom_y)


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
	var abs_path := ProjectSettings.globalize_path(res_path)
	var backup_path := abs_path + ".backup"
	if FileAccess.file_exists(backup_path):
		return
	var src := FileAccess.open(abs_path, FileAccess.READ)
	if src == null:
		push_warning("[TightenAtlas] Backup skipped; cannot read: %s" % abs_path)
		return
	var data := src.get_buffer(src.get_length())
	src.close()
	var dst := FileAccess.open(backup_path, FileAccess.WRITE)
	if dst == null:
		push_warning("[TightenAtlas] Backup skipped; cannot write: %s" % backup_path)
		return
	dst.store_buffer(data)
	dst.close()
