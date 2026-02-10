extends Node2D

const AppearanceGenerator = preload("res://scripts/appearance/CharacterAppearanceGenerator.gd")
const AppearanceProfiles = preload("res://scripts/appearance/CharacterAppearanceProfiles.gd")

@onready var sampler: WorldMapSampler = $WorldMapSampler
@onready var tile_layer: TileMapLayer = $TileMapLayer
@onready var lord_rig: Node = $Player/LordRig

@export var lord_seed: int = 1337
@export var lord_profile_id: String = AppearanceProfiles.PROFILE_ADVENTURER
@export var lord_kingdom_id: int = 0

# How many tiles to show in each dimension in this debug view.
# The sampler will map these tiles across the full source images.
const DEBUG_WIDTH_TILES: int = 128
const DEBUG_HEIGHT_TILES: int = 72

func _ready() -> void:
	if sampler == null:
		push_warning("[OverworldTest] WorldMapSampler node not found; cannot draw debug map.")
		return
	_setup_lord_rig()
	_draw_debug_map()

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

func _draw_debug_map() -> void:
	if tile_layer == null:
		push_warning("[OverworldTest] TileMapLayer node not found; cannot draw debug map.")
		return
	tile_layer.clear()
	var world_size: Vector2i = sampler.get_world_size_tiles()
	if world_size.x <= 0 or world_size.y <= 0:
		push_warning("[OverworldTest] World world_size_tiles is zero; check sampler config.")
		return

	# We map a DEBUG_WIDTH_TILES x DEBUG_HEIGHT_TILES grid into the full world
	# size for quick preview, without creating an enormous TileMap.
	for y in range(DEBUG_HEIGHT_TILES):
		for x in range(DEBUG_WIDTH_TILES):
			var u: float = float(x) / float(max(1, DEBUG_WIDTH_TILES - 1))
			var v: float = float(y) / float(max(1, DEBUG_HEIGHT_TILES - 1))
			var wx: int = int(u * float(world_size.x))
			var wy: int = int(v * float(world_size.y))
			var world_tile := Vector2i(wx, wy)

			var biome_id: int = sampler.get_biome_at_tile(world_tile)
			var is_water: bool = sampler.is_water(world_tile)

			var tile_coord := Vector2i(x, y)
			var source_id: int = 0
			var atlas_coord: Vector2i = Vector2i.ZERO

			if is_water:
				# Water tiles: use a dedicated atlas coord (e.g. (1,0))
				atlas_coord = Vector2i(1, 0)
			else:
				# Non-water: encode biome_id into atlas x for quick differentiation.
				# This assumes the TileSet has a row of colored debug tiles.
				atlas_coord = Vector2i(max(0, biome_id), 0)

			# TileMapLayer API in Godot 4.6.
			tile_layer.set_cell(tile_coord, source_id, atlas_coord)

	print("[OverworldTest] Debug map drawn ", DEBUG_WIDTH_TILES, "x", DEBUG_HEIGHT_TILES, " using world size ", world_size)
