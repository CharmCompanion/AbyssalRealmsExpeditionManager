extends RefCounted
class_name KingdomRegionTextureGenerator

# Generates a simple deterministic "region" texture for the TownView ground plane.
# This is an MVP placeholder until the Fantasy Isometric tiles are wired into a TileSet/TileMap.

const _MASK_63: int = 0x7fffffffffffffff

const _ISO_ENV_DIR: String = "res://assets/tilesets/fantasy_iso/Environment/"

# NOTE: In Godot 4, const initializers must be constant expressions; calling
# PackedStringArray([...]) is not allowed in a const. Use runtime-initialized
# static vars instead.
static var _ISO_GROUND_CANDIDATES: PackedStringArray = PackedStringArray([
	"Ground A1_N.png",
	"Ground B1_N.png",
	"Ground C1_N.png",
	"Ground D1_N.png",
	"Ground E1_N.png",
	"Ground F1_N.png",
	"Ground G1_N.png",
	"Ground H1_N.png",
	"Ground I1_N.png",
	"Ground J1_N.png",
])

const _ISO_STONE_FALLBACK: String = "Stone A1_N.png"
static var _ISO_TREE_FALLBACKS: PackedStringArray = PackedStringArray([
	"Tree A1_N.png",
	"Tree B1_N.png",
])


static func can_generate_isometric_tiles() -> bool:
	if _ISO_GROUND_CANDIDATES.is_empty():
		return false
	return ResourceLoader.exists(_ISO_ENV_DIR + _ISO_GROUND_CANDIDATES[0])


static func _load_image_res(path: String) -> Image:
	# Export-safe way to obtain an Image from an imported texture resource.
	# Avoids Image.load_from_file(), which does not work in exported builds.
	if not ResourceLoader.exists(path):
		return Image.new()
	var res: Resource = load(path)
	if res == null:
		return Image.new()
	if res is Texture2D:
		var img: Image = (res as Texture2D).get_image()
		if img == null:
			return Image.new()
		return img
	return Image.new()


static func generate_isometric_region_texture(
	grid_size: int,
	_seed: int,
	kingdom_id: int
) -> ImageTexture:
	# Render an isometric tilemap into an ImageTexture using a small curated subset
	# of the "Fantasy tileset - 2D Isometric" pack.
	# If the assets aren't present, callers should fall back to generate_region_texture.
	if grid_size <= 0:
		grid_size = 1
	if not can_generate_isometric_tiles():
		return generate_region_texture(grid_size, 16, _seed, kingdom_id)

	var biome_id: String = _primary_biome_for_kingdom(kingdom_id)
	var tiles: Dictionary = _select_isometric_tiles(biome_id)
	if tiles.is_empty():
		return generate_region_texture(grid_size, 16, _seed, kingdom_id)

	var base_img: Image = tiles["base"]
	if base_img.is_empty():
		return generate_region_texture(grid_size, 16, _seed, kingdom_id)

	var water_img: Image = tiles.get("water", base_img)
	var rock_img: Image = tiles.get("rock", base_img)
	var town_img: Image = tiles.get("town", base_img)
	var road_img: Image = tiles.get("road", town_img)

	var tree_img: Image = tiles.get("tree", Image.new())

	var tile_w: int = base_img.get_width()
	var tile_h: int = base_img.get_height()
	if tile_w <= 0 or tile_h <= 0:
		return generate_region_texture(grid_size, 16, _seed, kingdom_id)

	var step_x: int = max(1, tile_w / 2)
	var step_y: int = max(1, tile_h / 2)

	var extra_top: int = 0
	if not tree_img.is_empty():
		extra_top = maxi(0, tree_img.get_height() - tile_h)

	var out_w: int = (2 * (grid_size - 1)) * step_x + tile_w
	var out_h: int = (2 * (grid_size - 1)) * step_y + tile_h + extra_top
	var out_img: Image = Image.create(maxi(1, out_w), maxi(1, out_h), false, Image.FORMAT_RGBA8)
	out_img.fill(Color(0.0, 0.0, 0.0, 0.0))

	# Believable deterministic worldgen: continents + mountains + climate + rivers.
	var maps: Dictionary = _generate_world_maps(grid_size, _seed, biome_id)
	var heights: PackedFloat32Array = maps["h"]
	var moist: PackedFloat32Array = maps["m"]
	var temp: PackedFloat32Array = maps["t"]
	var rivers: PackedByteArray = maps["r"]
	var sea: float = float(maps["sea"])

	var town_center := Vector2i(grid_size / 2, grid_size / 2)
	var town_r: float = float(grid_size) * 0.28

	var origin_x: int = (grid_size - 1) * step_x
	var origin_y: int = extra_top

	for y in range(grid_size):
		for x in range(grid_size):
			var idx: int = y * grid_size + x
			var h: float = heights[idx]
			var mm: float = moist[idx]
			var tt: float = temp[idx]
			var is_river: bool = rivers[idx] != 0

			var d2: float = Vector2(float(x - town_center.x), float(y - town_center.y)).length()

			var kind: String = "base"
			if d2 <= town_r:
				kind = "town"
			elif (x == town_center.x or y == town_center.y) and d2 <= town_r * 1.15:
				kind = "road"
			elif h < sea or is_river:
				kind = "water"
			elif h > 0.84:
				kind = "rock"
			else:
				# Subtle variation: dry/cold highs become more stony.
				if (1.0 - tt) > 0.75 and h > sea + 0.12:
					kind = "rock"
				elif (1.0 - mm) > 0.70 and biome_id in ["plains", "forest", "coastal"] and h > sea + 0.08:
					kind = "rock"

			var tile_img: Image = base_img
			match kind:
				"water":
					tile_img = water_img
				"rock":
					tile_img = rock_img
				"town":
					tile_img = town_img
				"road":
					tile_img = road_img

			var screen_x: int = (x - y) * step_x + origin_x
			var screen_y: int = (x + y) * step_y + origin_y
			_blend_image(out_img, tile_img, Vector2i(screen_x, screen_y))

			# Sparse trees for forest-ish tiles.
			if (not tree_img.is_empty()) and kind == "base" and biome_id == "forest":
				var r: int = int(_hash2(_seed, x, y) % 100)
				# Favor wetter areas.
				if r < int(10 + mm * 12.0) and d2 > town_r * 1.05:
					var tx: int = screen_x + int((tile_w - tree_img.get_width()) / 2)
					var ty: int = screen_y + tile_h - tree_img.get_height()
					_blend_image(out_img, tree_img, Vector2i(tx, ty))

	return ImageTexture.create_from_image(out_img)


static func _hash2(_seed: int, x: int, y: int) -> int:
	var h: int = int(_seed) & _MASK_63
	h = int((h ^ (x * 374761393)) & _MASK_63)
	h = int((h ^ (y * 668265263)) & _MASK_63)
	h = int((h * 1274126177) & _MASK_63)
	return h


static func _blend_image(dst: Image, src: Image, dest: Vector2i) -> void:
	if src.is_empty():
		return
	var dst_w: int = dst.get_width()
	var dst_h: int = dst.get_height()
	var src_w: int = src.get_width()
	var src_h: int = src.get_height()

	var dx: int = dest.x
	var dy: int = dest.y
	var sx: int = 0
	var sy: int = 0
	var w: int = src_w
	var h: int = src_h

	if dx < 0:
		sx = -dx
		w -= sx
		dx = 0
	if dy < 0:
		sy = -dy
		h -= sy
		dy = 0
	if dx >= dst_w or dy >= dst_h:
		return
	w = mini(w, dst_w - dx)
	h = mini(h, dst_h - dy)
	if w <= 0 or h <= 0:
		return

	dst.blend_rect(src, Rect2i(sx, sy, w, h), Vector2i(dx, dy))


static func _select_isometric_tiles(biome_id: String) -> Dictionary:
	# Load candidates and pick best matches by average color.
	var candidates: Array[Dictionary] = []
	for name in _ISO_GROUND_CANDIDATES:
		var p: String = _ISO_ENV_DIR + String(name)
		var img: Image = _load_image_res(p)
		if img.is_empty():
			continue
		candidates.append({
			"path": p,
			"img": img,
			"avg": _avg_color(img, 8),
		})

	if candidates.is_empty():
		return {}

	var best_water: Dictionary = _pick_best(candidates, func(c: Dictionary) -> float:
		var a: Color = c["avg"]
		return a.b - maxi(a.r, a.g)
	)
	var best_rock: Dictionary = _pick_best(candidates, func(c: Dictionary) -> float:
		var a: Color = c["avg"]
		var lum: float = (a.r + a.g + a.b) / 3.0
		var sat: float = maxi(maxi(abs(a.r - a.g), abs(a.g - a.b)), abs(a.b - a.r))
		return (1.0 - lum) - sat
	)

	var best_base: Dictionary = {}
	match biome_id:
		"desert":
			best_base = _pick_best(candidates, func(c: Dictionary) -> float:
				var a: Color = c["avg"]
				return (a.r + a.g) - (2.0 * a.b) - abs(a.r - a.g)
			)
		"tundra":
			best_base = _pick_best(candidates, func(c: Dictionary) -> float:
				var a: Color = c["avg"]
				return (a.r + a.g + a.b) / 3.0
			)
		_:
			best_base = _pick_best(candidates, func(c: Dictionary) -> float:
				var a: Color = c["avg"]
				return a.g - maxi(a.r, a.b)
			)

	var base_img: Image = best_base.get("img", candidates[0]["img"])
	var water_img: Image = best_water.get("img", base_img)
	var rock_img: Image = best_rock.get("img", base_img)

	var stone_img: Image = Image.new()
	var stone_path: String = _ISO_ENV_DIR + _ISO_STONE_FALLBACK
	stone_img = _load_image_res(stone_path)
	var town_img: Image = base_img
	var road_img: Image = base_img
	if not stone_img.is_empty():
		town_img = stone_img
		road_img = stone_img

	var tree_img: Image = Image.new()
	for tname in _ISO_TREE_FALLBACKS:
		var tp: String = _ISO_ENV_DIR + String(tname)
		tree_img = _load_image_res(tp)
		if not tree_img.is_empty():
			break

	return {
		"base": base_img,
		"water": water_img,
		"rock": rock_img,
		"town": town_img,
		"road": road_img,
		"tree": tree_img,
	}


static func _pick_best(candidates: Array[Dictionary], score_fn: Callable) -> Dictionary:
	var best: Dictionary = candidates[0]
	var best_score: float = float(score_fn.call(best))
	for i in range(1, candidates.size()):
		var c: Dictionary = candidates[i]
		var s: float = float(score_fn.call(c))
		if s > best_score:
			best_score = s
			best = c
	return best


static func _avg_color(img: Image, sample_step: int) -> Color:
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 0 or h <= 0:
		return Color(0.0, 0.0, 0.0, 0.0)
	var step: int = maxi(1, sample_step)
	var sum_r: float = 0.0
	var sum_g: float = 0.0
	var sum_b: float = 0.0
	var count: int = 0
	for y in range(0, h, step):
		for x in range(0, w, step):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.05:
				continue
			sum_r += c.r
			sum_g += c.g
			sum_b += c.b
			count += 1
	if count <= 0:
		return Color(0.0, 0.0, 0.0, 0.0)
	return Color(sum_r / float(count), sum_g / float(count), sum_b / float(count), 1.0)


static func _generate_world_maps(grid_size: int, _seed: int, biome_id: String) -> Dictionary:
	# Produces height/moisture/temperature + river flags in a deterministic way.
	# Simple-but-believable: continents -> mountains -> climate -> rivers.
	var gs: int = maxi(1, grid_size)
	var total: int = gs * gs

	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(total)
	var moist: PackedFloat32Array = PackedFloat32Array()
	moist.resize(total)
	var temp: PackedFloat32Array = PackedFloat32Array()
	temp.resize(total)
	var rivers: PackedByteArray = PackedByteArray()
	rivers.resize(total)

	var s: int = int(_seed) & _MASK_63

	var noise_cont := FastNoiseLite.new()
	noise_cont.seed = int((s ^ 0x51a3d1) & _MASK_63)
	noise_cont.frequency = 0.02
	noise_cont.fractal_octaves = 4
	noise_cont.fractal_gain = 0.50
	noise_cont.fractal_lacunarity = 2.0
	noise_cont.domain_warp_enabled = true
	noise_cont.domain_warp_frequency = 0.025
	noise_cont.domain_warp_amplitude = 18.0

	var noise_mtn := FastNoiseLite.new()
	noise_mtn.seed = int((s ^ 0x9e3779) & _MASK_63)
	noise_mtn.frequency = 0.06
	noise_mtn.fractal_octaves = 3
	noise_mtn.fractal_gain = 0.55
	noise_mtn.fractal_lacunarity = 2.1

	var noise_detail := FastNoiseLite.new()
	noise_detail.seed = int((s ^ 0x2c1b3c) & _MASK_63)
	noise_detail.frequency = 0.14
	noise_detail.fractal_octaves = 2
	noise_detail.fractal_gain = 0.5
	noise_detail.fractal_lacunarity = 2.0

	var noise_moist := FastNoiseLite.new()
	noise_moist.seed = int((s ^ 0x7f4a7c) & _MASK_63)
	noise_moist.frequency = 0.08
	noise_moist.fractal_octaves = 3
	noise_moist.fractal_gain = 0.52
	noise_moist.fractal_lacunarity = 2.0

	# Kingdom-biome biases.
	var moist_bias: float = 0.0
	var temp_bias: float = 0.0
	var sea_level: float = 0.46
	match biome_id:
		"coastal":
			moist_bias = 0.10
			sea_level = 0.48
		"forest":
			moist_bias = 0.12
			sea_level = 0.45
		"tundra":
			temp_bias = -0.18
			sea_level = 0.43
		"desert":
			moist_bias = -0.18
			temp_bias = 0.08
			sea_level = 0.42
		_:
			sea_level = 0.46

	var cx: float = float(gs - 1) * 0.5
	var cy: float = float(gs - 1) * 0.5
	var maxd: float = max(1.0, Vector2(cx, cy).length())

	for y in range(gs):
		var lat: float = 1.0
		if gs > 1:
			lat = abs((float(y) / float(gs - 1)) * 2.0 - 1.0)
		var base_temp: float = clamp(1.0 - lat + temp_bias, 0.0, 1.0)
		for x in range(gs):
			var idx: int = y * gs + x

			# Continent mask with edge falloff.
			var cont: float = (noise_cont.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			cont = pow(cont, 1.25)
			var d: float = Vector2(float(x) - cx, float(y) - cy).length() / maxd
			var edge: float = clamp(1.0 - d, 0.0, 1.0)
			edge = edge * edge
			cont = clamp(cont * 0.85 + edge * 0.25, 0.0, 1.0)

			# Ridged mountains.
			var mtn_n: float = noise_mtn.get_noise_2d(float(x), float(y))
			var ridge: float = 1.0 - abs(mtn_n)
			ridge = ridge * ridge

			var det: float = (noise_detail.get_noise_2d(float(x), float(y)) + 1.0) * 0.5

			var h: float = cont * 0.78 + ridge * 0.33 + det * 0.10 - 0.28
			h = clamp(h, 0.0, 1.0)
			heights[idx] = h

			var mm: float = (noise_moist.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			mm = clamp(mm + moist_bias - h * 0.22, 0.0, 1.0)
			moist[idx] = mm

			var tt: float = clamp(base_temp - h * 0.22, 0.0, 1.0)
			temp[idx] = tt
			rivers[idx] = 0

	# Force the town center region to be land-ish.
	var town_center := Vector2i(gs / 2, gs / 2)
	var town_r: float = float(gs) * 0.28
	for y in range(gs):
		for x in range(gs):
			var d2: float = Vector2(float(x - town_center.x), float(y - town_center.y)).length()
			if d2 <= town_r:
				var idx: int = y * gs + x
				heights[idx] = max(heights[idx], sea_level + 0.10)

	# Rivers: pick a few sources in high/wet areas and trace downhill.
	var max_sources: int = 3
	var attempts: int = 40
	var picked: int = 0
	var forbidden_r: float = town_r * 1.10
	for i in range(attempts):
		if picked >= max_sources:
			break
		var rx: int = int(_hash2(s, i * 13 + 7, 101) % gs)
		var ry: int = int(_hash2(s, i * 17 + 3, 211) % gs)
		var d2: float = Vector2(float(rx - town_center.x), float(ry - town_center.y)).length()
		if d2 <= forbidden_r:
			continue
		var idx: int = ry * gs + rx
		if heights[idx] < sea_level + 0.20:
			continue
		if moist[idx] < 0.45:
			continue
		_trace_river(gs, heights, rivers, sea_level, Vector2i(rx, ry), s)
		picked += 1

	return {
		"h": heights,
		"m": moist,
		"t": temp,
		"r": rivers,
		"sea": sea_level,
	}


static func _trace_river(
	gs: int,
	heights: PackedFloat32Array,
	rivers: PackedByteArray,
	sea: float,
	start: Vector2i,
	_seed: int
) -> void:
	var pos: Vector2i = start
	var max_steps: int = gs * 5
	for step in range(max_steps):
		if pos.x < 0 or pos.y < 0 or pos.x >= gs or pos.y >= gs:
			return
		var idx: int = pos.y * gs + pos.x
		if heights[idx] < sea + 0.01:
			return
		rivers[idx] = 1

		var best: Vector2i = pos
		var best_h: float = heights[idx]
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				if ox == 0 and oy == 0:
					continue
				var nx: int = pos.x + ox
				var ny: int = pos.y + oy
				if nx < 0 or ny < 0 or nx >= gs or ny >= gs:
					continue
				var nidx: int = ny * gs + nx
				var nh: float = heights[nidx]
				var jitter: float = float(_hash2(_seed, nx, ny) % 100) * 0.0002
				if nh + jitter < best_h:
					best_h = nh + jitter
					best = Vector2i(nx, ny)
		if best == pos:
			return
		pos = best

static func generate_region_texture(
	grid_size: int,
	cell_px: int,
	_seed: int,
	kingdom_id: int
) -> ImageTexture:
	var size_px: int = max(1, grid_size * max(1, cell_px))
	var img: Image = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)

	var biome_id: String = _primary_biome_for_kingdom(kingdom_id)
	var palette: Dictionary = _palette_for_biome(biome_id)

	var maps: Dictionary = _generate_world_maps(grid_size, _seed, biome_id)
	var heights: PackedFloat32Array = maps["h"]
	var moist: PackedFloat32Array = maps["m"]
	var temp: PackedFloat32Array = maps["t"]
	var rivers: PackedByteArray = maps["r"]
	var sea: float = float(maps["sea"])

	# Town center + roads
	var town_center := Vector2i(grid_size / 2, grid_size / 2)
	var town_r: float = float(grid_size) * 0.28

	for y in range(grid_size):
		for x in range(grid_size):
			var idx: int = y * grid_size + x
			var hx: float = heights[idx]
			var mx: float = moist[idx]
			var tx: float = temp[idx]
			var is_river: bool = rivers[idx] != 0

			var tile_color: Color = palette.get("base", Color(0.25, 0.65, 0.25, 1.0))
			if hx < sea or is_river:
				tile_color = palette.get("water", Color(0.12, 0.28, 0.55, 1.0))
			elif hx > 0.84:
				tile_color = palette.get("rock", Color(0.45, 0.45, 0.45, 1.0))
			else:
				var dryness: float = clamp(1.0 - mx, 0.0, 1.0)
				var cold: float = clamp(1.0 - tx, 0.0, 1.0)
				if cold > 0.70 and hx > sea + 0.10:
					tile_color = palette.get("dry", tile_color).lerp(Color(0.85, 0.88, 0.92, 1.0), 0.35)
				elif dryness > 0.60:
					tile_color = palette.get("dry", tile_color)
				elif mx > 0.72:
					tile_color = palette.get("lush", tile_color)

			# Flatten town area.
			var d2: float = Vector2(float(x - town_center.x), float(y - town_center.y)).length()
			if d2 <= town_r:
				tile_color = palette.get("town", Color(0.55, 0.45, 0.30, 1.0))

			# Roads: simple cross (can expand later).
			if x == town_center.x or y == town_center.y:
				if d2 <= town_r * 1.15:
					tile_color = palette.get("road", Color(0.40, 0.32, 0.22, 1.0))

			# Paint the cell.
			_fill_cell(img, x, y, cell_px, tile_color)

	# Subtle grid lines
	_draw_grid_lines(img, grid_size, cell_px, Color(0.0, 0.0, 0.0, 0.08))

	return ImageTexture.create_from_image(img)


static func _fill_cell(img: Image, cell_x: int, cell_y: int, cell_px: int, c: Color) -> void:
	var start_x: int = cell_x * cell_px
	var start_y: int = cell_y * cell_px
	for py in range(cell_px):
		for px in range(cell_px):
			img.set_pixel(start_x + px, start_y + py, c)


static func _draw_grid_lines(img: Image, grid_size: int, cell_px: int, c: Color) -> void:
	var size_px: int = grid_size * cell_px
	for x in range(0, size_px, cell_px):
		for y in range(size_px):
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(c, c.a))
	for y in range(0, size_px, cell_px):
		for x in range(size_px):
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(c, c.a))


static func _primary_biome_for_kingdom(kingdom_id: int) -> String:
	# Keep aligned with CreateTown’s kingdom/biome mapping.
	match kingdom_id:
		1:
			return "coastal"
		2:
			return "plains"
		3:
			return "forest"
		4:
			return "forest"
		5:
			return "tundra"
		6:
			return "desert"
		_:
			return "plains"


static func _palette_for_biome(biome_id: String) -> Dictionary:
	match biome_id:
		"coastal":
			return {
				"base": Color(0.25, 0.62, 0.32, 1.0),
				"lush": Color(0.22, 0.68, 0.30, 1.0),
				"dry": Color(0.30, 0.58, 0.26, 1.0),
				"water": Color(0.10, 0.28, 0.58, 1.0),
				"rock": Color(0.48, 0.48, 0.50, 1.0),
				"town": Color(0.56, 0.46, 0.32, 1.0),
				"road": Color(0.42, 0.33, 0.24, 1.0),
			}
		"forest":
			return {
				"base": Color(0.15, 0.55, 0.22, 1.0),
				"lush": Color(0.12, 0.62, 0.20, 1.0),
				"dry": Color(0.22, 0.50, 0.20, 1.0),
				"water": Color(0.10, 0.25, 0.45, 1.0),
				"rock": Color(0.45, 0.45, 0.45, 1.0),
				"town": Color(0.52, 0.42, 0.30, 1.0),
				"road": Color(0.38, 0.30, 0.22, 1.0),
			}
		"tundra":
			return {
				"base": Color(0.82, 0.86, 0.90, 1.0),
				"lush": Color(0.88, 0.90, 0.92, 1.0),
				"dry": Color(0.74, 0.78, 0.84, 1.0),
				"water": Color(0.12, 0.22, 0.40, 1.0),
				"rock": Color(0.55, 0.58, 0.62, 1.0),
				"town": Color(0.55, 0.48, 0.40, 1.0),
				"road": Color(0.44, 0.38, 0.32, 1.0),
			}
		"desert":
			return {
				"base": Color(0.82, 0.72, 0.42, 1.0),
				"lush": Color(0.76, 0.68, 0.40, 1.0),
				"dry": Color(0.88, 0.78, 0.46, 1.0),
				"water": Color(0.14, 0.30, 0.50, 1.0),
				"rock": Color(0.52, 0.46, 0.40, 1.0),
				"town": Color(0.60, 0.50, 0.34, 1.0),
				"road": Color(0.46, 0.38, 0.26, 1.0),
			}
		_:
			return {
				"base": Color(0.30, 0.65, 0.30, 1.0),
				"lush": Color(0.26, 0.70, 0.28, 1.0),
				"dry": Color(0.36, 0.60, 0.26, 1.0),
				"water": Color(0.12, 0.26, 0.52, 1.0),
				"rock": Color(0.45, 0.45, 0.45, 1.0),
				"town": Color(0.56, 0.46, 0.32, 1.0),
				"road": Color(0.42, 0.33, 0.24, 1.0),
			}
