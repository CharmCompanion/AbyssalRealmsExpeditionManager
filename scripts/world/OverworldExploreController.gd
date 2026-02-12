extends "res://scripts/world/BuildingPlacement.gd"

@export var player_path: NodePath = ^"Player"
@export var stream_radius: Vector2i = Vector2i(48, 48)
@export var base_ground_texture_name: String = "Ground A1_E.png"

var _base_ground_source_id: int = -1
var _base_ground_atlas_coords: Vector2i = Vector2i.ZERO
var _last_stream_center: Vector2i = Vector2i(2147483647, 2147483647)

func _ready() -> void:
	super._ready()
	_resolve_base_ground_tile()
	_stream_ground(true)

func _process(delta: float) -> void:
	super._process(delta)
	_stream_ground(false)


func _stream_ground(force: bool) -> void:
	if ground_layer == null:
		return
	if _base_ground_source_id < 0:
		return

	var player := get_node_or_null(player_path) as Node2D
	if player == null:
		return

	var player_local := ground_layer.to_local(player.global_position)
	var center_cell: Vector2i = ground_layer.local_to_map(player_local)
	if not force and center_cell == _last_stream_center:
		return
	_last_stream_center = center_cell

	var rx: int = stream_radius.x
	if rx < 0:
		rx = 0
	var ry: int = stream_radius.y
	if ry < 0:
		ry = 0

	for dy in range(-ry, ry + 1):
		for dx in range(-rx, rx + 1):
			var cell := center_cell + Vector2i(dx, dy)
			if ground_layer.get_cell_source_id(cell) != -1:
				continue
			ground_layer.set_cell(cell, _base_ground_source_id, _base_ground_atlas_coords)


func _resolve_base_ground_tile() -> void:
	_base_ground_source_id = -1
	_base_ground_atlas_coords = Vector2i.ZERO
	if ground_layer == null:
		return
	var ts: TileSet = ground_layer.tile_set
	if ts == null:
		return

	# Prefer a specific texture name if present.
	var from_texture := _find_tile_by_texture(ts, base_ground_texture_name)
	if not from_texture.is_empty():
		_base_ground_source_id = int(from_texture["source_id"])
		_base_ground_atlas_coords = Vector2i(from_texture["coords"])
		return

	# Fallback: first atlas tile.
	var first := _pick_first_tile(ts)
	if not first.is_empty():
		_base_ground_source_id = int(first["source_id"])
		_base_ground_atlas_coords = Vector2i(first["coords"])


func _pick_first_tile(ts: TileSet) -> Dictionary:
	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null or not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var tiles_count: int = atlas.get_tiles_count()
		if tiles_count <= 0:
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
		var tiles_count: int = atlas.get_tiles_count()
		if tiles_count <= 0:
			continue
		return {"source_id": source_id, "coords": atlas.get_tile_id(0)}
	return {}
