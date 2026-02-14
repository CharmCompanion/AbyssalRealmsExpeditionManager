@tool
extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var build_layer: TileMapLayer = $BuildLayer
@onready var wall_back_layer: TileMapLayer = $WallBackLayer
@onready var wall_front_layer: TileMapLayer = $WallFrontLayer
@onready var roof_back_layer: TileMapLayer = $RoofBackLayer
@onready var roof_front_layer: TileMapLayer = $RoofFrontLayer
@onready var props_layer: TileMapLayer = $PropsLayer
@onready var trees_layer: TileMapLayer = $TreesLayer
@onready var flora_layer: TileMapLayer = $FloraLayer
@onready var stone_layer: TileMapLayer = $StoneLayer

@export var seed: int = 1337
@export var clearing_size: Vector2i = Vector2i(35, 25)
@export var clearing_origin: Vector2i = Vector2i(0, 0)
@export var map_margin: Vector2i = Vector2i(50, 50)
@export var tree_gap_width: int = 4
@export var path_length: int = 30
@export var path_width: int = 4
@export var house_size: Vector2i = Vector2i(3, 3)

@export var player_path: NodePath = ^"Player"
@export var hide_front_when_inside: bool = true
@export var interior_padding: Vector2i = Vector2i(0, 0)
@export var front_fade_time: float = 0.25
@export var front_hidden_alpha: float = 0.1
@export var door_width: int = 1
# Front means "south" in isometric (positive Y). Change to (0, -1) if needed.
@export var door_dir: Vector2i = Vector2i(0, 1)

# Texture names from the Tile palettes (fallback to first tile if not found).
@export var ground_texture: String = "Ground A1_N.png"
@export var grass_texture: String = "Ground A9_E.png"
@export var path_texture: String = "Stone A1_N.png"
@export var tree_forest_texture: String = "Tree A1_N.png"
@export var tree_town_texture: String = "Tree A2_N.png"
@export var house_wall_back_names: PackedStringArray = [
	"Wall C1_N.png",
	"Wall C2_N.png",
	"Wall C3_N.png",
	"Wall C4_N.png",
]
@export var house_wall_front_names: PackedStringArray = [
	"Wall C1_N.png",
	"Wall C2_N.png",
	"Wall C3_N.png",
	"Wall C4_N.png",
]
@export var house_roof_back_names: PackedStringArray = [
	"Roof E1_N.png",
	"Roof E2_N.png",
	"Roof E3_N.png",
	"Roof E4_N.png",
	"Roof E5_N.png",
	"Roof E6_N.png",
	"Roof E7_N.png",
	"Roof E8_N.png",
	"Roof E9_N.png",
]
@export var house_roof_front_names: PackedStringArray = [
	"Roof E1_N.png",
	"Roof E2_N.png",
	"Roof E3_N.png",
	"Roof E4_N.png",
	"Roof E5_N.png",
	"Roof E6_N.png",
	"Roof E7_N.png",
	"Roof E8_N.png",
	"Roof E9_N.png",
]
@export var stone_names: PackedStringArray = [
	"Stone A1_N.png",
	"Stone A2_N.png",
	"Stone A3_N.png",
	"Stone A4_N.png",
	"Stone A5_N.png",
	"Stone A6_N.png",
	"Stone A7_N.png",
	"Stone A8_N.png",
	"Stone A9_N.png",
	"Stone A10_N.png",
	"Stone A11_N.png",
	"Stone A12_N.png",
]
@export var shop_stand_names: PackedStringArray = [
	"Shop Stand B14_N.png",
	"Shop Stand B14_E.png",
	"Shop Stand B14_S.png",
	"Shop Stand B14_W.png",
]

func _ready() -> void:
	_seed_rng()
	_clear_layers()
	_build_village()
	if Engine.is_editor_hint():
		print("[TownMap] Built village in editor.")
	else:
		_update_interior_visibility()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_interior_visibility()


func _seed_rng() -> void:
	seed = int(seed)
	RandomNumberGenerator.new().seed = seed


func _build_village() -> void:
	# Resolve tiles.
	var ground = _resolve_tile(ground_layer, ground_texture)
	var grass = _resolve_tile(ground_layer, grass_texture)
	var path_tile = _resolve_tile(stone_layer, path_texture)
	var tree_forest = _resolve_tile(trees_layer, tree_forest_texture)
	var tree_town = _resolve_tile(trees_layer, tree_town_texture)
	var house_walls_back := _resolve_tiles_by_names(wall_back_layer, house_wall_back_names)
	var house_walls_front := _resolve_tiles_by_names(wall_front_layer, house_wall_front_names)
	var house_roofs_back := _resolve_tiles_by_names(roof_back_layer, house_roof_back_names)
	var house_roofs_front := _resolve_tiles_by_names(roof_front_layer, house_roof_front_names)
	var stones := _resolve_tiles_by_names(stone_layer, stone_names)
	var shop_stands := _resolve_tiles_by_names(props_layer, shop_stand_names)

	if house_walls_back.is_empty():
		var fallback_wall := _pick_first_tile(wall_back_layer)
		if not fallback_wall.is_empty():
			house_walls_back = [fallback_wall]
		else:
			push_warning("[TownMap] No wall tiles found. Check Fantasy_Wall.tres.")
	if house_walls_front.is_empty():
		house_walls_front = house_walls_back
	if house_roofs_back.is_empty():
		var fallback_roof := _pick_first_tile(roof_back_layer)
		if not fallback_roof.is_empty():
			house_roofs_back = [fallback_roof]
		else:
			push_warning("[TownMap] No roof tiles found. Check Fantasy_Roof.tres.")
	if house_roofs_front.is_empty():
		house_roofs_front = house_roofs_back
	if stones.is_empty():
		var fallback_stone := _pick_first_tile(stone_layer)
		if not fallback_stone.is_empty():
			stones = [fallback_stone]
		else:
			push_warning("[TownMap] No stone tiles found. Check Fantasy_Stone.tres.")
	if shop_stands.is_empty():
		var fallback_shop := _pick_first_tile(props_layer)
		if not fallback_shop.is_empty():
			shop_stands = [fallback_shop]
		else:
			push_warning("[TownMap] No shop stand tiles found. Check Fantasy_Build.tres.")
	if tree_forest.is_empty():
		tree_forest = _pick_first_tile(trees_layer)
	if tree_town.is_empty():
		tree_town = tree_forest

	# 1) Base ground fill.
	var map_rect := Rect2i(clearing_origin - map_margin, clearing_size + (map_margin * 2))
	_fill_rect(ground_layer, map_rect, ground)

	# 2) Diamond-shaped clearing grass (flora layer), with ground beneath.
	var clear_rect := Rect2i(clearing_origin, clearing_size)
	var clear_center := clear_rect.position + Vector2i(clear_rect.size.x / 2, clear_rect.size.y / 2)
	var clear_radius := Vector2i(max(1, clear_rect.size.x / 2), max(1, clear_rect.size.y / 2))
	_fill_diamond(flora_layer, clear_center, clear_radius, grass)

	# 3) Path exits to the south using stone tiles.
	var path_start := clear_center + Vector2i(0, clear_radius.y)
	_fill_path(stone_layer, path_start, Vector2i(0, 1), path_length, path_width, path_tile)

	# 4) Fill outside with trees, only clearing has no trees.
	_fill_trees_outside(map_rect, clear_center, clear_radius, path_start, tree_forest, tree_town)

	# 5) Place decorative stones/boulders in the clearing edges.
	_place_boulders(clear_rect, clear_center, stones)

	# 6) Build structures based on your 3D references.
	_build_cottage(clearing_origin + Vector2i(3, 3), house_walls_back, house_walls_front, house_roofs_back, house_roofs_front)
	_build_manor(clearing_origin + Vector2i(clearing_size.x - 14, 5), house_walls_back, house_walls_front, house_roofs_back, house_roofs_front)
	_build_shop(clearing_origin + Vector2i(clearing_size.x / 2 - 3, clearing_size.y / 2 - 2), house_walls_back, house_walls_front, house_roofs_back, house_roofs_front, shop_stands)


func _fill_trees_outside(map_rect: Rect2i, clear_center: Vector2i, clear_radius: Vector2i, path_start: Vector2i, forest_tree: Dictionary, town_tree: Dictionary) -> void:
	if forest_tree.is_empty() and town_tree.is_empty():
		return
	var use_town := not town_tree.is_empty()
	var use_forest := not forest_tree.is_empty()
	var gap_half := int(max(1, tree_gap_width / 2))
	for y in range(map_rect.position.y, map_rect.position.y + map_rect.size.y):
		for x in range(map_rect.position.x, map_rect.position.x + map_rect.size.x):
			var pos := Vector2i(x, y)
			if _is_in_diamond(pos, clear_center, clear_radius):
				continue
			# Now path goes south (0, 1), so check vertical path corridor.
			if _is_in_path_corridor_vertical(pos, path_start, Vector2i(0, 1), path_length, gap_half):
				continue
			var pick := forest_tree
			if use_town and use_forest and ((x + y) % 5 == 0):
				pick = town_tree
			elif use_town and not use_forest:
				pick = town_tree
			_place_cell(trees_layer, pos, pick)


func _place_boulders(clear_rect: Rect2i, clear_center: Vector2i, boulders: Array) -> void:
	if boulders.is_empty():
		return
	# Place stones at compass points around clearing center, inside the diamond.
	var spots := [
		clear_center + Vector2i(-8, 0),
		clear_center + Vector2i(8, 0),
		clear_center + Vector2i(0, -5),
		clear_center + Vector2i(0, 5),
		clear_center + Vector2i(-5, -3),
		clear_center + Vector2i(5, -3),
	]
	for pos in spots:
		_place_cell_random(stone_layer, pos, boulders)


func _fill_diamond(layer: TileMapLayer, center: Vector2i, radius: Vector2i, tile: Dictionary) -> void:
	if tile.is_empty() or layer == null:
		return
	var min_x := center.x - radius.x
	var max_x := center.x + radius.x
	var min_y := center.y - radius.y
	var max_y := center.y + radius.y
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var pos := Vector2i(x, y)
			if _is_in_diamond(pos, center, radius):
				_place_cell(layer, pos, tile)


func _is_in_diamond(pos: Vector2i, center: Vector2i, radius: Vector2i) -> bool:
	var rx: float = max(1.0, float(radius.x))
	var ry: float = max(1.0, float(radius.y))
	var dx: float = abs(float(pos.x - center.x)) / rx
	var dy: float = abs(float(pos.y - center.y)) / ry
	return (dx + dy) <= 1.0


func _fill_path(layer: TileMapLayer, start: Vector2i, dir: Vector2i, length: int, width: int, tile: Dictionary) -> void:
	if tile.is_empty():
		return
	var half := int(max(1, width / 2))
	for i in range(length):
		var pos := start + (dir * i)
		for off in range(-half, half + 1):
			var p := pos + Vector2i(0, off)
			_place_cell(layer, p, tile)


func _is_in_path_corridor(pos: Vector2i, start: Vector2i, dir: Vector2i, length: int, half_width: int) -> bool:
	# Supports east-bound path for now.
	if dir != Vector2i(1, 0):
		return false
	if pos.x < start.x or pos.x > start.x + length:
		return false
	if abs(pos.y - start.y) > half_width:
		return false
	return true


func _is_in_path_corridor_vertical(pos: Vector2i, start: Vector2i, dir: Vector2i, length: int, half_width: int) -> bool:
	# Supports south-bound path (0, 1).
	if dir != Vector2i(0, 1):
		return false
	if pos.y < start.y or pos.y > start.y + length:
		return false
	if abs(pos.x - start.x) > half_width:
		return false
	return true


# Building structures based on 3D references.
func _build_cottage(pos: Vector2i, walls_back: Array, walls_front: Array, roofs_back: Array, roofs_front: Array) -> void:
	# Simple 4x4 cottage with door on south side.
	var size := Vector2i(4, 4)
	var rect := Rect2i(pos, size)
	var split_y := pos.y + 2
	
	# Walls: hollow rectangle (just perimeter).
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			var cell_pos := Vector2i(x, y)
			var is_edge := (x == pos.x or x == pos.x + size.x - 1 or y == pos.y or y == pos.y + size.y - 1)
			# Leave door opening on south wall center.
			var is_door := (y == pos.y + size.y - 1 and x >= pos.x + 1 and x <= pos.x + 2)
			if is_edge and not is_door:
				if y < split_y:
					_place_cell_random(wall_back_layer, cell_pos, walls_back)
					_place_cell_random(roof_back_layer, cell_pos, roofs_back)
				else:
					_place_cell_random(wall_front_layer, cell_pos, walls_front)
					_place_cell_random(roof_front_layer, cell_pos, roofs_front)
	
	_register_building(rect)


func _build_manor(pos: Vector2i, walls_back: Array, walls_front: Array, roofs_back: Array, roofs_front: Array) -> void:
	# Larger compound: 10x8 with courtyard in center.
	var size := Vector2i(10, 8)
	var rect := Rect2i(pos, size)
	var split_y := pos.y + 4
	
	# Outer walls with entrance on south.
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			var cell_pos := Vector2i(x, y)
			var is_outer_edge := (x == pos.x or x == pos.x + size.x - 1 or y == pos.y or y == pos.y + size.y - 1)
			var is_gate := (y == pos.y + size.y - 1 and x >= pos.x + 4 and x <= pos.x + 5)
			
			# Inner courtyard boundary (hollow center).
			var is_inner_wall := false
			if x >= pos.x + 2 and x <= pos.x + size.x - 3 and y >= pos.y + 2 and y <= pos.y + size.y - 3:
				is_inner_wall = (x == pos.x + 2 or x == pos.x + size.x - 3 or y == pos.y + 2 or y == pos.y + size.y - 3)
			
			if (is_outer_edge and not is_gate) or is_inner_wall:
				if y < split_y:
					_place_cell_random(wall_back_layer, cell_pos, walls_back)
					_place_cell_random(roof_back_layer, cell_pos, roofs_back)
				else:
					_place_cell_random(wall_front_layer, cell_pos, walls_front)
					_place_cell_random(roof_front_layer, cell_pos, roofs_front)
	
	_register_building(rect)


func _build_shop(pos: Vector2i, walls_back: Array, walls_front: Array, roofs_back: Array, roofs_front: Array, shop_stands: Array) -> void:
	# Small 5x4 shop with stand outside.
	var size := Vector2i(5, 4)
	var rect := Rect2i(pos, size)
	var split_y := pos.y + 2
	
	# Walls: hollow rectangle.
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			var cell_pos := Vector2i(x, y)
			var is_edge := (x == pos.x or x == pos.x + size.x - 1 or y == pos.y or y == pos.y + size.y - 1)
			var is_door := (y == pos.y + size.y - 1 and x == pos.x + 2)
			if is_edge and not is_door:
				if y < split_y:
					_place_cell_random(wall_back_layer, cell_pos, walls_back)
					_place_cell_random(roof_back_layer, cell_pos, roofs_back)
				else:
					_place_cell_random(wall_front_layer, cell_pos, walls_front)
					_place_cell_random(roof_front_layer, cell_pos, roofs_front)
	
	# Shop stand outside the door.
	if not shop_stands.is_empty():
		var stand_pos := pos + Vector2i(2, size.y)
		_place_cell_random(props_layer, stand_pos, shop_stands)
	
	_register_building(rect)


func _clear_layers() -> void:
	ground_layer.clear()
	build_layer.clear()
	wall_back_layer.clear()
	wall_front_layer.clear()
	roof_back_layer.clear()
	roof_front_layer.clear()
	props_layer.clear()
	trees_layer.clear()
	flora_layer.clear()
	stone_layer.clear()
	_building_zones.clear()
	_active_building_idx = -1
	_prev_player_cell = Vector2i(2147483647, 2147483647)
	_set_front_alpha(1.0)


func _fill_rect(layer: TileMapLayer, rect: Rect2i, tile: Dictionary) -> void:
	if tile.is_empty():
		return
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			layer.set_cell(Vector2i(x, y), tile["source_id"], tile["coords"])


func _fill_rect_random(layer: TileMapLayer, rect: Rect2i, tiles: Array) -> void:
	if tiles.is_empty():
		return
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_place_cell_random(layer, Vector2i(x, y), tiles)


func _fill_line(layer: TileMapLayer, start: Vector2i, dir: Vector2i, length: int, tile: Dictionary) -> void:
	if tile.is_empty():
		return
	var pos := start
	for _i in range(length):
		layer.set_cell(pos, tile["source_id"], tile["coords"])
		pos += dir


func _place_cell(layer: TileMapLayer, pos: Vector2i, tile: Dictionary) -> void:
	if tile.is_empty():
		return
	layer.set_cell(pos, tile["source_id"], tile["coords"])


func _place_cell_random(layer: TileMapLayer, pos: Vector2i, tiles: Array) -> void:
	if tiles.is_empty():
		return
	var idx := int(hash(pos) % tiles.size())
	_place_cell(layer, pos, tiles[idx])


func _resolve_tile(layer: TileMapLayer, texture_name: String) -> Dictionary:
	if layer == null or layer.tile_set == null:
		return {}
	if texture_name.strip_edges() != "":
		var found := _find_tile_by_texture(layer.tile_set, texture_name)
		if not found.is_empty():
			return found
	return _pick_first_tile(layer)


func _resolve_tiles_by_names(layer: TileMapLayer, names: PackedStringArray) -> Array:
	var tiles: Array = []
	if layer == null or layer.tile_set == null:
		return tiles
	if names.is_empty():
		return tiles
	var ts: TileSet = layer.tile_set
	var wanted := {}
	for name in names:
		wanted[name] = true
	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null or not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var tex: Texture2D = atlas.texture
		if tex == null:
			continue
		var file := tex.resource_path.get_file()
		if not wanted.has(file):
			continue
		if atlas.get_tiles_count() <= 0:
			continue
		tiles.append({"source_id": source_id, "coords": atlas.get_tile_id(0)})
	return tiles


func _resolve_tiles_by_prefix(layer: TileMapLayer, prefix: String) -> Array:
	var tiles: Array = []
	if layer == null or layer.tile_set == null:
		return tiles
	if prefix.strip_edges() == "":
		return tiles
	var ts: TileSet = layer.tile_set
	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null or not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var tex: Texture2D = atlas.texture
		if tex == null:
			continue
		if not tex.resource_path.get_file().begins_with(prefix):
			continue
		if atlas.get_tiles_count() <= 0:
			continue
		tiles.append({"source_id": source_id, "coords": atlas.get_tile_id(0)})
	return tiles


func _pick_first_tile(layer: TileMapLayer) -> Dictionary:
	var ts: TileSet = layer.tile_set
	if ts == null:
		return {}
	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null or not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		if atlas.get_tiles_count() <= 0:
			continue
		return {"source_id": source_id, "coords": atlas.get_tile_id(0)}
	return {}


func _find_tile_by_texture(ts: TileSet, texture_name: String) -> Dictionary:
	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null or not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var tex: Texture2D = atlas.texture
		if tex == null:
			continue
		if not tex.resource_path.ends_with(texture_name):
			continue
		if atlas.get_tiles_count() <= 0:
			continue
		return {"source_id": source_id, "coords": atlas.get_tile_id(0)}
	return {}


class BuildingZone:
	var rect: Rect2i
	var door_outside: Array[Vector2i]

	func _init(r: Rect2i, door_cells: Array[Vector2i]) -> void:
		rect = r
		door_outside = door_cells


var _building_zones: Array[BuildingZone] = []
var _active_building_idx: int = -1
var _prev_player_cell: Vector2i = Vector2i(2147483647, 2147483647)
var _front_tween: Tween = null


func _register_building(rect: Rect2i) -> void:
	var padded := Rect2i(rect.position - interior_padding, rect.size + (interior_padding * 2))
	var door_cells := _compute_door_outside_cells(padded)
	_building_zones.append(BuildingZone.new(padded, door_cells))


func _compute_door_outside_cells(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var half := int(max(1, door_width) / 2)
	var door_x := rect.position.x + int(rect.size.x / 2)
	var door_y := rect.position.y + int(rect.size.y / 2)

	if door_dir == Vector2i(0, 1):
		door_y = rect.position.y + rect.size.y - 1
	elif door_dir == Vector2i(0, -1):
		door_y = rect.position.y
	elif door_dir == Vector2i(1, 0):
		door_x = rect.position.x + rect.size.x - 1
	elif door_dir == Vector2i(-1, 0):
		door_x = rect.position.x

	for dx in range(-half, half + 1):
		var door_tile := Vector2i(door_x + dx, door_y)
		if door_dir.x != 0:
			door_tile = Vector2i(door_x, door_y + dx)
		var outside := door_tile + door_dir
		cells.append(outside)
	return cells


func _update_interior_visibility() -> void:
	if not hide_front_when_inside:
		_set_front_alpha(1.0)
		return
	if ground_layer == null:
		return
	var player := get_node_or_null(player_path) as Node2D
	if player == null:
		return
	var local_pos := ground_layer.to_local(player.global_position)
	var cell := ground_layer.local_to_map(local_pos)

	if _prev_player_cell == Vector2i(2147483647, 2147483647):
		_prev_player_cell = cell
		# If we start inside any building, hide front layers immediately.
		for i in range(_building_zones.size()):
			if _building_zones[i].rect.has_point(cell):
				_active_building_idx = i
				_set_front_alpha(front_hidden_alpha)
				break
			return

	if _active_building_idx == -1:
		var idx := _find_entered_building(cell, _prev_player_cell)
		if idx != -1:
			_active_building_idx = idx
			_set_front_alpha(front_hidden_alpha)
	else:
		var active := _building_zones[_active_building_idx]
		if not active.rect.has_point(cell):
			_active_building_idx = -1
			_set_front_alpha(1.0)

	_prev_player_cell = cell


func _find_entered_building(cell: Vector2i, prev_cell: Vector2i) -> int:
	for i in range(_building_zones.size()):
		var zone := _building_zones[i]
		if not zone.rect.has_point(cell):
			continue
		if zone.rect.has_point(prev_cell):
			continue
		for outside in zone.door_outside:
			if outside == prev_cell:
				return i
	return -1


func _set_front_alpha(target_alpha: float) -> void:
	if wall_front_layer == null or roof_front_layer == null:
		return
	if Engine.is_editor_hint():
		wall_front_layer.modulate.a = target_alpha
		roof_front_layer.modulate.a = target_alpha
		return
	if _front_tween != null and _front_tween.is_valid():
		_front_tween.kill()
	_front_tween = get_tree().create_tween()
	_front_tween.tween_property(wall_front_layer, "modulate:a", target_alpha, front_fade_time)
	_front_tween.parallel().tween_property(roof_front_layer, "modulate:a", target_alpha, front_fade_time)
