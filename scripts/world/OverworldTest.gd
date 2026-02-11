extends Node2D

const AppearanceGenerator = preload("res://scripts/appearance/CharacterAppearanceGenerator.gd")
const AppearanceProfiles = preload("res://scripts/appearance/CharacterAppearanceProfiles.gd")

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var props_layer: TileMapLayer = $PropsLayer
@onready var buildings_layer: TileMapLayer = $BuildingsLayer
@onready var trees_layer: TileMapLayer = $TreesLayer
@onready var flora_layer: TileMapLayer = $FloraLayer
@onready var lord_rig: Node = $Player/LordRig
@onready var camera: Camera2D = $Camera2D

@export var lord_seed: int = 1337
@export var lord_profile_id: String = AppearanceProfiles.PROFILE_ADVENTURER
@export var lord_kingdom_id: int = 0

const STARTER_WIDTH: int = 128
const STARTER_HEIGHT: int = 128

func _ready() -> void:
	_setup_lord_rig()
	_build_starter_scene()
	_center_camera_on_grid()

func _setup_lord_rig() -> void:
	if lord_rig == null:
		push_warning("[OverworldTest] LordRig node not found; cannot apply appearance.")
		return
	if not lord_rig.has_method("set_part_folder"):
		push_warning("[OverworldTest] LordRig missing expected methods; appearance not applied.")
		return
	var spritesheets_root := ""
	if "spritesheets_root" in lord_rig:
		spritesheets_root = String(lord_rig.spritesheets_root)
	var generator = AppearanceGenerator.new(spritesheets_root)
	var recipe = generator.generate(lord_profile_id, lord_seed, {"kingdom_id": lord_kingdom_id})
	if recipe != null:
		recipe.apply_to(lord_rig)
	if lord_rig.has_method("set_action"):
		lord_rig.call("set_action", "Idle")

func _build_starter_scene() -> void:
	_clear_layers()

	var ground_info: Dictionary = _find_tile_by_texture(ground_layer, "Ground A1_E.png")
	if ground_info.is_empty():
		ground_info = _pick_first_tile(ground_layer)
	if ground_info.is_empty():
		push_warning("[OverworldTest] Ground TileSet has no tiles.")
		return

	var ground_source_id: int = int(ground_info.get("source_id", -1))
	var ground_coords: Vector2i = Vector2i(ground_info.get("coords", Vector2i.ZERO))
	for y in range(STARTER_HEIGHT):
		for x in range(STARTER_WIDTH):
			ground_layer.set_cell(Vector2i(x, y), ground_source_id, ground_coords)

	print("[OverworldTest] Ground filled: ", STARTER_WIDTH, "x", STARTER_HEIGHT)


func _center_camera_on_grid() -> void:
	if camera == null or ground_layer == null:
		return
	# Center on the midpoint of the generated grid.
	var center_map := Vector2(STARTER_WIDTH, STARTER_HEIGHT) * 0.5
	var center_world := ground_layer.map_to_local(center_map)
	camera.position = center_world


func _clear_layers() -> void:
	if ground_layer != null:
		ground_layer.clear()
	if props_layer != null:
		props_layer.clear()
	if buildings_layer != null:
		buildings_layer.clear()
	if trees_layer != null:
		trees_layer.clear()
	if flora_layer != null:
		flora_layer.clear()


func _pick_first_tile(layer: TileMapLayer) -> Dictionary:
	if layer == null:
		return {}
	var ts: TileSet = layer.tile_set
	if ts == null:
		return {}
	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var tiles_count: int = atlas.get_tiles_count()
		if tiles_count <= 0:
			continue
		var coords: Vector2i = atlas.get_tile_id(0)
		return {
			"source_id": source_id,
			"coords": coords,
		}
	return {}


func _find_tile_by_texture(layer: TileMapLayer, texture_name: String) -> Dictionary:
	if layer == null:
		return {}
	var ts: TileSet = layer.tile_set
	if ts == null:
		return {}
	var source_count: int = ts.get_source_count()
	for i in range(source_count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
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
		var coords: Vector2i = atlas.get_tile_id(0)
		return {
			"source_id": source_id,
			"coords": coords,
		}
	return {}
