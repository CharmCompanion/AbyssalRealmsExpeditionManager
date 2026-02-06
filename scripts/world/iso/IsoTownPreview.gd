extends Node2D

# A standalone, runnable preview scene that generates an isometric 2D town floor
# using your isometric tiles in assets/tilesets/fantasy_iso/Environment.
#
# Scene: res://scenes/world/iso/IsoTownPreview.tscn

enum Biome { PLAINS, FOREST, ROCKY, SAND, SNOW }

@export var map_size: Vector2i = Vector2i(64, 64)
@export var world_seed: int = 0

# These are the important knobs for "feels real".
@export_range(0.0, 1.0, 0.01) var forest_tree_density: float = 0.12
@export_range(0.0, 1.0, 0.01) var plains_tree_density: float = 0.02
@export_range(0.0, 1.0, 0.01) var rocky_tree_density: float = 0.01

@export_range(0.0, 1.0, 0.01) var forest_flora_density: float = 0.08
@export_range(0.0, 1.0, 0.01) var plains_flora_density: float = 0.03
@export_range(0.0, 1.0, 0.01) var rocky_flora_density: float = 0.005

@export_range(0.0, 1.0, 0.01) var chest_density: float = 0.001

@export var enable_roads: bool = true
@export_range(1, 8, 1) var road_spokes: int = 3
@export_range(0.0, 1.0, 0.01) var road_wobble: float = 0.22
@export_range(0.0, 1.0, 0.01) var road_widen_chance: float = 0.12

@export var center_clearing_radius: int = 8

# Option B: use the full imported isometric kit (individual PNG tiles).
@export var use_full_imported_kit: bool = true
@export var imported_env_dir: String = "res://imported/Map and Character/Fantasy tileset - 2D Isometric/Environment"

# Imported kit: we default to using the sprite size as the grid size to avoid
# per-tile origin/pivot work in strict mode. We can refine to a smaller diamond
# footprint later once we lock in the kit's intended grid metrics.
@export var imported_tile_size: Vector2i = Vector2i(256, 256)

# Placement (hook this up to your building sprites later)
@export var enable_building_placement: bool = true
@export var default_building_texture: Texture2D
@export var building_sprite_offset: Vector2 = Vector2(0, -48)

# 8-direction orientation index (0..7). For now we rotate the sprite.
var _build_dir: int = 0

# Legacy tileset assumptions (small atlas subset in assets/tilesets/fantasy_iso).
const TILE_SIZE := Vector2i(64, 32)
const GROUND_REGION_SIZE := Vector2i(64, 32)
const TREE_REGION_SIZE := Vector2i(64, 64)

const NEIGHBOR_OFFSETS: Array[int] = [-1, 0, 1]

const ENV_DIR := "res://assets/tilesets/fantasy_iso/Environment/"
const GROUND_SHEETS := [
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
]
const STONE_SHEETS := ["Stone A1_N.png"]
const TREE_SHEETS := ["Tree A1_N.png", "Tree B1_N.png"]

@onready var cam: Camera2D = $Camera2D
@onready var ground_map: TileMap = $Ground
@onready var props_map: TileMap = $Props
@onready var buildings_map: TileMap = $Buildings
@onready var placed_buildings: Node2D = $PlacedBuildings

var _ts: TileSet
var _rng := RandomNumberGenerator.new()

# biome -> { source_id: int, atlas_coords: Array[Vector2i] }
var _biome_sources: Dictionary = {}
var _tree_sources: Array[Dictionary] = []

# Roads + extra prop pools (Option B). Stored as the same tile pick format.
var _road_pool: Dictionary = {}
var _flora_sources: Array[Dictionary] = []
var _chest_sources: Array[Dictionary] = []

# cell_index(int) -> Sprite2D
var _placed: Dictionary = {}

# occupancy grid for props/buildings (used by generator + future placement)
var _blocked: PackedByteArray
var _road: PackedByteArray

func _ready() -> void:
	set_process_unhandled_input(true)
	if world_seed == 0:
		world_seed = int(Time.get_unix_time_from_system())
	_rng.seed = world_seed

	_ts = _build_tileset_runtime()
	ground_map.tile_set = _ts
	props_map.tile_set = _ts
	buildings_map.tile_set = _ts

	_generate_and_paint()
	_center_camera()

func _unhandled_input(event: InputEvent) -> void:
	# Simple pan/zoom so you can inspect the generated level.
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if enable_building_placement and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_place_building_at_mouse()
			return
		if enable_building_placement and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_remove_building_at_mouse()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cam.zoom *= Vector2(0.9, 0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cam.zoom *= Vector2(1.1, 1.1)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			cam.position -= mm.relative * cam.zoom
	elif enable_building_placement and event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo:
			return
		# Q/E rotates 8-direction placement
		if k.keycode == KEY_Q:
			_build_dir = (_build_dir + 7) % 8
		elif k.keycode == KEY_E:
			_build_dir = (_build_dir + 1) % 8

func _center_camera() -> void:
	# For isometric, map_to_local will be correct once the TileSet has isometric shape.
	var mid := Vector2i(map_size.x / 2, map_size.y / 2)
	cam.position = ground_map.map_to_local(mid)

func _generate_and_paint() -> void:
	ground_map.clear()
	props_map.clear()
	buildings_map.clear()
	for c in placed_buildings.get_children():
		c.queue_free()
	_placed.clear()

	_blocked = PackedByteArray()
	_blocked.resize(map_size.x * map_size.y)
	_road = PackedByteArray()
	_road.resize(map_size.x * map_size.y)

	var biome_map := _generate_biomes()
	_smooth_biomes(biome_map, 2)

	_paint_ground(biome_map)
	_paint_roads(biome_map)
	_scatter_trees(biome_map)
	_scatter_flora(biome_map)
	_scatter_chests(biome_map)

func _generate_biomes() -> PackedInt32Array:
	# Two-noise biome selection (height + moisture).
	var out := PackedInt32Array()
	out.resize(map_size.x * map_size.y)

	var height_noise: FastNoiseLite = FastNoiseLite.new()
	height_noise.seed = int(_rng.randi())
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_noise.frequency = 0.035

	var moist_noise: FastNoiseLite = FastNoiseLite.new()
	moist_noise.seed = int(_rng.randi())
	moist_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moist_noise.frequency = 0.045

	var cx: float = float(map_size.x) * 0.5
	var cy: float = float(map_size.y) * 0.5

	for y in range(map_size.y):
		for x in range(map_size.x):
			var h: float = height_noise.get_noise_2d(float(x), float(y))
			var m: float = moist_noise.get_noise_2d(float(x), float(y))

			# Light bias toward plains near the center (town core).
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			var center_bias: float = clamp(1.0 - (dist / float(max(1, center_clearing_radius * 3))), 0.0, 1.0)
			m = lerp(m, -0.1, center_bias)

			var b: int
			if h > 0.55:
				b = Biome.ROCKY
			elif h < -0.45:
				b = Biome.SAND
			elif m > 0.25:
				b = Biome.FOREST
			elif m < -0.35:
				b = Biome.SAND
			else:
				b = Biome.PLAINS

			# Sparse snow on high-ish, low moisture areas
			if h > 0.35 and m < -0.05 and _rng.randf() < 0.08:
				b = Biome.SNOW

			out[_idx(x, y)] = b

	return out

func _smooth_biomes(biome_map: PackedInt32Array, passes: int) -> void:
	for _p in range(passes):
		var copy: PackedInt32Array = biome_map.duplicate()
		for y in range(map_size.y):
			for x in range(map_size.x):
				var counts := {Biome.PLAINS: 0, Biome.FOREST: 0, Biome.ROCKY: 0, Biome.SAND: 0, Biome.SNOW: 0}
				for oy: int in NEIGHBOR_OFFSETS:
					for ox: int in NEIGHBOR_OFFSETS:
						if ox == 0 and oy == 0:
							continue
						var nx: int = x + ox
						var ny: int = y + oy
						if nx < 0 or ny < 0 or nx >= map_size.x or ny >= map_size.y:
							continue
						var nb: int = int(copy[_idx(nx, ny)])
						counts[nb] = int(counts[nb]) + 1
				var best: int = int(copy[_idx(x, y)])
				var best_count: int = int(counts[best])
				for k in counts.keys():
					if int(counts[k]) > best_count:
						best = int(k)
						best_count = int(counts[k])
				biome_map[_idx(x, y)] = best

func _paint_ground(biome_map: PackedInt32Array) -> void:
	for y in range(map_size.y):
		for x in range(map_size.x):
			var biome := biome_map[_idx(x, y)]
			var pick := _pick_ground_tile(biome)
			ground_map.set_cell(0, Vector2i(x, y), int(pick["source_id"]), pick["atlas_coords"])

func _scatter_trees(biome_map: PackedInt32Array) -> void:
	# Clustered tree distribution:
	# - a low-frequency noise adds clumps
	# - a min-distance check prevents "salt & pepper" spam
	# - density depends on biome
	var clump_noise: FastNoiseLite = FastNoiseLite.new()
	clump_noise.seed = int(_rng.randi())
	clump_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	clump_noise.frequency = 0.06

	var cx: float = float(map_size.x) * 0.5
	var cy: float = float(map_size.y) * 0.5
	var min_dist := 2
	var placed_cells: Array[Vector2i] = []

	for y in range(map_size.y):
		for x in range(map_size.x):
			var biome := biome_map[_idx(x, y)]
			var density := 0.0
			match biome:
				Biome.FOREST:
					density = forest_tree_density
				Biome.PLAINS:
					density = plains_tree_density
				Biome.ROCKY:
					density = rocky_tree_density
				_:
					density = 0.0

			if density <= 0.0:
				continue

			# Keep a playable/placable clearing in the center.
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			if sqrt(dx * dx + dy * dy) <= float(center_clearing_radius):
				continue

			var clump := (clump_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			# boost within clumps; clamp so it's stable
			density = clamp(density * (0.55 + clump * 1.25), 0.0, 0.45)

			if _rng.randf() > density:
				continue
			if _is_blocked(x, y):
				continue
			if _is_road(x, y):
				continue
			if _too_close_to_any(Vector2i(x, y), placed_cells, min_dist):
				continue

			var tree_pick := _pick_tree_tile()
			props_map.set_cell(0, Vector2i(x, y), int(tree_pick["source_id"]), tree_pick["atlas_coords"])
			_set_blocked(x, y, true)
			placed_cells.append(Vector2i(x, y))

func _scatter_flora(biome_map: PackedInt32Array) -> void:
	if _flora_sources.is_empty():
		return

	# Similar to trees, but smaller/denser and never inside center clearing.
	var clump_noise: FastNoiseLite = FastNoiseLite.new()
	clump_noise.seed = int(_rng.randi())
	clump_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	clump_noise.frequency = 0.08

	var cx: float = float(map_size.x) * 0.5
	var cy: float = float(map_size.y) * 0.5
	var min_dist := 1
	var placed_cells: Array[Vector2i] = []

	for y in range(map_size.y):
		for x in range(map_size.x):
			if _is_blocked(x, y) or _is_road(x, y):
				continue

			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			if sqrt(dx * dx + dy * dy) <= float(center_clearing_radius):
				continue

			var biome := biome_map[_idx(x, y)]
			var density := 0.0
			match biome:
				Biome.FOREST:
					density = forest_flora_density
				Biome.PLAINS:
					density = plains_flora_density
				Biome.ROCKY:
					density = rocky_flora_density
				_:
					density = 0.0

			if density <= 0.0:
				continue

			var clump := (clump_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			density = clamp(density * (0.65 + clump * 1.1), 0.0, 0.55)
			if _rng.randf() > density:
				continue
			if _too_close_to_any(Vector2i(x, y), placed_cells, min_dist):
				continue

			var flora_pick := _pick_flora_tile()
			props_map.set_cell(0, Vector2i(x, y), int(flora_pick["source_id"]), flora_pick["atlas_coords"])
			_set_blocked(x, y, true)
			placed_cells.append(Vector2i(x, y))

func _scatter_chests(biome_map: PackedInt32Array) -> void:
	if _chest_sources.is_empty() or chest_density <= 0.0:
		return

	var cx: float = float(map_size.x) * 0.5
	var cy: float = float(map_size.y) * 0.5
	var max_r: float = float(max(1, center_clearing_radius * 3))

	for y in range(map_size.y):
		for x in range(map_size.x):
			if _is_blocked(x, y) or _is_road(x, y):
				continue
			# Bias chests toward the town core outskirts.
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= float(center_clearing_radius):
				continue
			var bias: float = clamp(1.0 - (dist / max_r), 0.0, 1.0)
			var chance: float = chest_density * (0.25 + bias * 1.75)
			if _rng.randf() > chance:
				continue
			var chest_pick := _pick_chest_tile()
			props_map.set_cell(0, Vector2i(x, y), int(chest_pick["source_id"]), chest_pick["atlas_coords"])
			_set_blocked(x, y, true)

func _too_close_to_any(p: Vector2i, points: Array[Vector2i], min_dist: int) -> bool:
	for q in points:
		if abs(p.x - q.x) <= min_dist and abs(p.y - q.y) <= min_dist:
			# Cheaper than true distance; good enough for spacing props.
			return true
	return false

func _place_building_at_mouse() -> void:
	var cell := _mouse_to_cell()
	if not _cell_in_bounds(cell):
		return
	if _is_blocked(cell.x, cell.y):
		return
	# For now, 1-tile footprint. Expand later per building type.
	_set_blocked(cell.x, cell.y, true)

	var idx := _idx(cell.x, cell.y)
	if _placed.has(idx):
		return

	var spr := Sprite2D.new()
	spr.texture = default_building_texture
	if spr.texture == null:
		# Fallback: use the tileset preview if no building art is assigned.
		spr.texture = load(ENV_DIR + "TilePreview.png")
	spr.centered = true
	# 8-direction: rotate 45 degrees per step.
	spr.rotation_degrees = float(_build_dir) * 45.0

	# Draw ordering: in iso, larger y means "in front".
	# This makes y-sort behave well.
	spr.position = ground_map.map_to_local(cell) + building_sprite_offset

	placed_buildings.add_child(spr)
	_placed[idx] = spr

func _remove_building_at_mouse() -> void:
	var cell := _mouse_to_cell()
	if not _cell_in_bounds(cell):
		return
	var idx := _idx(cell.x, cell.y)
	if not _placed.has(idx):
		return
	var spr := _placed[idx] as Node
	_placed.erase(idx)
	if spr:
		spr.queue_free()
	_set_blocked(cell.x, cell.y, false)

func _mouse_to_cell() -> Vector2i:
	var local_pos := ground_map.to_local(get_global_mouse_position())
	return ground_map.local_to_map(local_pos)

func _cell_in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < map_size.x and c.y < map_size.y

func _pick_ground_tile(biome: int) -> Dictionary:
	# Conservative default mapping:
	# - PLAINS / FOREST -> Ground A (grass-ish)
	# - SAND -> Ground C (sand-ish)
	# - SNOW -> Ground D (snow-ish)
	# - ROCKY -> Stone A
	var entry: Dictionary
	match biome:
		Biome.PLAINS, Biome.FOREST:
			entry = _biome_sources.get(Biome.PLAINS)
		Biome.SAND:
			entry = _biome_sources.get(Biome.SAND)
		Biome.SNOW:
			entry = _biome_sources.get(Biome.SNOW)
		Biome.ROCKY:
			entry = _biome_sources.get(Biome.ROCKY)
		_:
			entry = _biome_sources.get(Biome.PLAINS)

	if entry == null:
		# Should not happen; fallback to the first ground source.
		entry = _biome_sources.values()[0]

	# Imported-kit pools store a list of possible single-image source IDs.
	if entry.has("source_ids"):
		var ids: Array[int] = entry["source_ids"]
		if ids.is_empty():
			return {"source_id": -1, "atlas_coords": Vector2i.ZERO}
		return {
			"source_id": ids[_rng.randi_range(0, ids.size() - 1)],
			"atlas_coords": Vector2i.ZERO,
		}

	var coords: Array = entry["atlas_coords"]
	return {
		"source_id": int(entry["source_id"]),
		"atlas_coords": coords[_rng.randi_range(0, coords.size() - 1)],
	}

func _pick_tree_tile() -> Dictionary:
	if _tree_sources.is_empty():
		return {"source_id": -1, "atlas_coords": Vector2i.ZERO}

	var entry: Dictionary = _tree_sources[_rng.randi_range(0, _tree_sources.size() - 1)]
	var coords: Array = entry["atlas_coords"]
	return {
		"source_id": int(entry["source_id"]),
		"atlas_coords": coords[_rng.randi_range(0, coords.size() - 1)],
	}

func _pick_flora_tile() -> Dictionary:
	if _flora_sources.is_empty():
		return {"source_id": -1, "atlas_coords": Vector2i.ZERO}
	var entry: Dictionary = _flora_sources[_rng.randi_range(0, _flora_sources.size() - 1)]
	var coords: Array = entry["atlas_coords"]
	return {
		"source_id": int(entry["source_id"]),
		"atlas_coords": coords[_rng.randi_range(0, coords.size() - 1)],
	}

func _pick_chest_tile() -> Dictionary:
	if _chest_sources.is_empty():
		return {"source_id": -1, "atlas_coords": Vector2i.ZERO}
	var entry: Dictionary = _chest_sources[_rng.randi_range(0, _chest_sources.size() - 1)]
	var coords: Array = entry["atlas_coords"]
	return {
		"source_id": int(entry["source_id"]),
		"atlas_coords": coords[_rng.randi_range(0, coords.size() - 1)],
	}

func _pick_road_tile() -> Dictionary:
	var entry: Dictionary = _road_pool
	if entry == null or entry.is_empty():
		return {"source_id": -1, "atlas_coords": Vector2i.ZERO}
	if entry.has("source_ids"):
		var ids: Array[int] = entry["source_ids"]
		if ids.is_empty():
			return {"source_id": -1, "atlas_coords": Vector2i.ZERO}
		return {"source_id": ids[_rng.randi_range(0, ids.size() - 1)], "atlas_coords": Vector2i.ZERO}
	var coords: Array = entry["atlas_coords"]
	return {"source_id": int(entry["source_id"]), "atlas_coords": coords[_rng.randi_range(0, coords.size() - 1)]}

func _paint_roads(_biome_map: PackedInt32Array) -> void:
	if not enable_roads:
		return
	if _road_pool == null or _road_pool.is_empty():
		return

	var cx: int = map_size.x / 2
	var cy: int = map_size.y / 2
	var start := Vector2i(cx, cy)

	# Choose endpoints on the map edge.
	var endpoints: Array[Vector2i] = []
	var spokes: int = max(1, road_spokes)
	for _i in range(spokes):
		var side: int = _rng.randi_range(0, 3)
		var endp := Vector2i.ZERO
		match side:
			0:
				endp = Vector2i(_rng.randi_range(0, map_size.x - 1), 0)
			1:
				endp = Vector2i(map_size.x - 1, _rng.randi_range(0, map_size.y - 1))
			2:
				endp = Vector2i(_rng.randi_range(0, map_size.x - 1), map_size.y - 1)
			3:
				endp = Vector2i(0, _rng.randi_range(0, map_size.y - 1))
		if not endpoints.has(endp):
			endpoints.append(endp)

	# Carve each spoke.
	for endp in endpoints:
		_carve_road_path(start, endp)

func _carve_road_path(start: Vector2i, goal: Vector2i) -> void:
	var cur := start
	var max_steps: int = map_size.x * map_size.y
	var steps := 0
	while cur != goal and steps < max_steps:
		_mark_road(cur.x, cur.y)

		var dx: int = goal.x - cur.x
		var dy: int = goal.y - cur.y
		var sx: int = 0 if dx == 0 else (1 if dx > 0 else -1)
		var sy: int = 0 if dy == 0 else (1 if dy > 0 else -1)

		# Occasionally wobble perpendicular to avoid ruler-straight roads.
		if _rng.randf() < road_wobble:
			if abs(dx) > abs(dy):
				sy = _rng.randi_range(-1, 1)
			else:
				sx = _rng.randi_range(-1, 1)

		var prefer_x: bool = abs(dx) >= abs(dy)
		var step := Vector2i.ZERO
		if sx != 0 and sy != 0:
			# Mostly follow the dominant axis, sometimes switch.
			if prefer_x:
				step = Vector2i(sx, 0) if _rng.randf() < 0.7 else Vector2i(0, sy)
			else:
				step = Vector2i(0, sy) if _rng.randf() < 0.7 else Vector2i(sx, 0)
		elif sx != 0:
			step = Vector2i(sx, 0)
		elif sy != 0:
			step = Vector2i(0, sy)
		else:
			break

		var next := cur + step
		if not _cell_in_bounds(next):
			break
		cur = next
		steps += 1

	# mark the final cell
	_mark_road(goal.x, goal.y)

func _mark_road(x: int, y: int) -> void:
	if x < 0 or y < 0 or x >= map_size.x or y >= map_size.y:
		return
	var i := _idx(x, y)
	if _road[i] != 0:
		return
	_road[i] = 1
	# Roads should block trees/flora/building placement.
	_set_blocked(x, y, true)
	var pick := _pick_road_tile()
	ground_map.set_cell(0, Vector2i(x, y), int(pick["source_id"]), pick["atlas_coords"])

	# Occasionally widen by 1 tile.
	if _rng.randf() < road_widen_chance:
		var ox: int = _rng.randi_range(-1, 1)
		var oy: int = _rng.randi_range(-1, 1)
		if ox != 0 or oy != 0:
			var nx: int = x + ox
			var ny: int = y + oy
			if nx >= 0 and ny >= 0 and nx < map_size.x and ny < map_size.y:
				var ni := _idx(nx, ny)
				if _road[ni] == 0:
					_road[ni] = 1
					_set_blocked(nx, ny, true)
					var pick2 := _pick_road_tile()
					ground_map.set_cell(0, Vector2i(nx, ny), int(pick2["source_id"]), pick2["atlas_coords"])

func _is_road(x: int, y: int) -> bool:
	return _road[_idx(x, y)] != 0

func _build_tileset_runtime() -> TileSet:
	if use_full_imported_kit:
		var ts_imported := _build_tileset_from_imported_kit()
		if ts_imported != null:
			return ts_imported

	var ts := TileSet.new()
	# Core: make the map behave like an isometric grid.
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_size = TILE_SIZE

	_biome_sources.clear()
	_tree_sources.clear()
	_road_pool = {}
	_flora_sources.clear()
	_chest_sources.clear()

	# Ground biomes
	var plains_src := _add_atlas_source(ts, ENV_DIR + "Ground A1_N.png", GROUND_REGION_SIZE)
	var sand_src := _add_atlas_source(ts, ENV_DIR + "Ground C1_N.png", GROUND_REGION_SIZE)
	var snow_src := _add_atlas_source(ts, ENV_DIR + "Ground D1_N.png", GROUND_REGION_SIZE)
	var rocky_src := _add_atlas_source(ts, ENV_DIR + "Stone A1_N.png", GROUND_REGION_SIZE)

	_biome_sources[Biome.PLAINS] = plains_src
	_biome_sources[Biome.SAND] = sand_src
	_biome_sources[Biome.SNOW] = snow_src
	_biome_sources[Biome.ROCKY] = rocky_src
	_biome_sources[Biome.FOREST] = plains_src

	# Trees
	for sheet in TREE_SHEETS:
		_tree_sources.append(_add_atlas_source(ts, ENV_DIR + sheet, TREE_REGION_SIZE))

	# Roads: reuse rocky ground as a stand-in.
	_road_pool = rocky_src

	return ts


func _build_tileset_from_imported_kit() -> TileSet:
	# We only pull the tile categories we need for procedural generation right now
	# (ground + trees). We can add roofs/walls/props once we add building rules.
	var dir := DirAccess.open(imported_env_dir)
	if dir == null:
		push_warning("[IsoTownPreview] Imported kit dir not found: " + imported_env_dir)
		return null

	var ground_paths_by_letter: Dictionary = {}
	var stone_paths: Array[String] = []
	var tree_paths: Array[String] = []
	var flora_paths: Array[String] = []
	var chest_paths: Array[String] = []
	var road_ground_paths: Array[String] = []

	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.to_lower().ends_with(".png"):
			# Roads: user-specified set Ground B2_E .. Ground E15_W (inclusive).
			# We include all direction variants since these tiles are authored per-view.
			if fname.begins_with("Ground "):
				var rest_for_road: String = fname.substr(7, fname.length() - 7) # e.g. "B2_E.png"
				var parts: PackedStringArray = rest_for_road.split("_", false)
				if parts.size() == 2:
					var code: String = parts[0] # e.g. "B2" or "E15"
					var dir_part: String = parts[1] # e.g. "E.png"
					var dir_letter: String = dir_part.substr(0, 1)
					if code.length() >= 2:
						var letter_for_road: String = code.substr(0, 1)
						var num_str: String = code.substr(1, code.length() - 1)
						var num: int = int(num_str)
						if (letter_for_road == "B" or letter_for_road == "C" or letter_for_road == "D" or letter_for_road == "E") and num >= 2 and num <= 15:
							if dir_letter == "E" or dir_letter == "N" or dir_letter == "S" or dir_letter == "W":
								road_ground_paths.append(imported_env_dir.path_join(fname))

			# Ground tiles: use North variants as canonical.
			if fname.begins_with("Ground ") and fname.ends_with("_N.png"):
				var rest: String = fname.substr(7, fname.length() - 7) # e.g. "A12_N.png"
				var letter: String = rest.substr(0, 1)
				var full_path: String = imported_env_dir.path_join(fname)
				if not ground_paths_by_letter.has(letter):
					ground_paths_by_letter[letter] = []
				(ground_paths_by_letter[letter] as Array).append(full_path)
			elif fname.begins_with("Stone ") and fname.ends_with("_N.png"):
				stone_paths.append(imported_env_dir.path_join(fname))
			elif fname.begins_with("Tree ") and fname.ends_with("_N.png"):
				tree_paths.append(imported_env_dir.path_join(fname))
			elif fname.begins_with("Flora ") and fname.ends_with("_N.png"):
				flora_paths.append(imported_env_dir.path_join(fname))
			elif fname.begins_with("Chest ") and fname.ends_with("_N.png"):
				chest_paths.append(imported_env_dir.path_join(fname))
		fname = dir.get_next()
	dir.list_dir_end()

	# If we didn't find any ground tiles, bail out to legacy.
	if ground_paths_by_letter.is_empty():
		push_warning("[IsoTownPreview] No Ground *_N.png tiles found in: " + imported_env_dir)
		return null

	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
	ts.tile_size = imported_tile_size

	_biome_sources.clear()
	_tree_sources.clear()
	_road_pool = {}
	_flora_sources.clear()
	_chest_sources.clear()

	# Create biome pools. We map biomes to letter groups conservatively.
	# If a letter doesn't exist, we fall back to any available group.
	var plains_letters: Array[String] = ["A", "B"]
	var forest_letters: Array[String] = ["B", "A"]
	var sand_letters: Array[String] = ["C", "D", "A"]
	var snow_letters: Array[String] = ["E", "F", "A"]
	var rocky_letters: Array[String] = ["D", "C", "A"]

	_biome_sources[Biome.PLAINS] = _add_ground_pool(ts, ground_paths_by_letter, plains_letters)
	_biome_sources[Biome.FOREST] = _add_ground_pool(ts, ground_paths_by_letter, forest_letters)
	_biome_sources[Biome.SAND] = _add_ground_pool(ts, ground_paths_by_letter, sand_letters)
	_biome_sources[Biome.SNOW] = _add_ground_pool(ts, ground_paths_by_letter, snow_letters)

	# Prefer stone tiles for ROCKY if we have them, else fall back to a ground group.
	if not stone_paths.is_empty():
		_biome_sources[Biome.ROCKY] = _add_single_tile_pool(ts, stone_paths)
	else:
		_biome_sources[Biome.ROCKY] = _add_ground_pool(ts, ground_paths_by_letter, rocky_letters)

	# Roads: prefer the user-selected ground range; else use stone; else plains.
	if not road_ground_paths.is_empty():
		_road_pool = _add_single_tile_pool(ts, road_ground_paths)
	elif not stone_paths.is_empty():
		_road_pool = _add_single_tile_pool(ts, stone_paths)
	else:
		_road_pool = _biome_sources.get(Biome.PLAINS, {})

	# Trees
	if not tree_paths.is_empty():
		_tree_sources = _add_multi_single_tiles(ts, tree_paths)
	else:
		push_warning("[IsoTownPreview] No Tree *_N.png tiles found in: " + imported_env_dir)

	# Flora + chests (extra props)
	if not flora_paths.is_empty():
		_flora_sources = _add_multi_single_tiles(ts, flora_paths)
	if not chest_paths.is_empty():
		_chest_sources = _add_multi_single_tiles(ts, chest_paths)

	return ts


func _add_ground_pool(ts: TileSet, by_letter: Dictionary, letters: Array[String]) -> Dictionary:
	for letter in letters:
		if by_letter.has(letter):
			return _add_single_tile_pool(ts, by_letter[letter])
	# fallback: any group
	for k in by_letter.keys():
		return _add_single_tile_pool(ts, by_letter[k])
	return {"source_id": -1, "atlas_coords": []}


func _add_single_tile_pool(ts: TileSet, texture_paths: Array) -> Dictionary:
	# Adds N individual PNG tiles as N sources; returns a pool over those sources.
	var coords: Array[Vector2i] = [Vector2i.ZERO]
	var source_ids: Array[int] = []
	for p in texture_paths:
		var sid := _add_single_png_source(ts, String(p))
		if sid >= 0:
			source_ids.append(sid)
	# Store as a special pool: atlas_coords list is unused (always ZERO); we pick source_id randomly.
	return {"source_ids": source_ids, "atlas_coords": coords}


func _add_multi_single_tiles(ts: TileSet, texture_paths: Array[String]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in texture_paths:
		var sid := _add_single_png_source(ts, p)
		if sid >= 0:
			out.append({"source_id": sid, "atlas_coords": [Vector2i.ZERO]})
	return out


func _add_single_png_source(ts: TileSet, texture_path: String) -> int:
	var tex := load(texture_path) as Texture2D
	if tex == null:
		return -1
	var src := TileSetAtlasSource.new()
	src.texture = tex
	# Single-image tile: region size == full texture size.
	src.texture_region_size = tex.get_size()
	var sid := ts.add_source(src)
	var ac := Vector2i.ZERO
	src.create_tile(ac)
	return sid

func _add_atlas_source(ts: TileSet, texture_path: String, region_size: Vector2i) -> Dictionary:
	var tex := load(texture_path) as Texture2D
	if tex == null:
		push_warning("[IsoTownPreview] Missing texture: " + texture_path)
		return {"source_id": -1, "atlas_coords": []}

	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = region_size

	var source_id := ts.add_source(src)

	# Create tiles across the whole sheet.
	var tex_size: Vector2i = tex.get_size()
	var cols := int(tex_size.x / region_size.x)
	var rows := int(tex_size.y / region_size.y)
	var coords: Array[Vector2i] = []
	for y in range(rows):
		for x in range(cols):
			var ac := Vector2i(x, y)
			src.create_tile(ac)
			coords.append(ac)

	return {"source_id": source_id, "atlas_coords": coords}

func _idx(x: int, y: int) -> int:
	return y * map_size.x + x

func _is_blocked(x: int, y: int) -> bool:
	return _blocked[_idx(x, y)] != 0

func _set_blocked(x: int, y: int, v: bool) -> void:
	_blocked[_idx(x, y)] = 1 if v else 0
