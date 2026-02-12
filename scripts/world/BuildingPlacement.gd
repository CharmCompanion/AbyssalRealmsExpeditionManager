extends Node2D
## Building placement system for the overworld
## Manages tile selection, preview, and placement on BuildLayer

@onready var build_layer: TileMapLayer = $BuildLayer
@onready var ground_layer: TileMapLayer = $GroundLayer

# Cursor-to-cell calibration for isometric TileSets.
# Positive X = right, positive Y = down.
@export var iso_cursor_cell_offset: Vector2i = Vector2i(1, 3)

# Track the currently selected building type/tile
var selected_tile_id: int = 0
var selected_building: int = 0  # Building variant to place (for future UI)

# Current tile under mouse
var current_tile_pos: Vector2i = Vector2i.ZERO
var last_tile_pos: Vector2i = Vector2i.ZERO
var is_over_build_slot: bool = false

# Tile IDs for black placeholder
const BLACK_TILE_ID: int = 0
const BLACK_TILE_SOURCE: int = 0

func _ready() -> void:
	print("BuildingPlacement: Ready - Black tiles are placeholders for buildings")
	print("BuildLayer z-index: %d (below all other tiles)" % build_layer.layer)

func _process(_delta: float) -> void:
	if not build_layer:
		return
	
	# Get mouse position in world coordinates
	var mouse_global := get_global_mouse_position()

	# Convert world position to TileMapLayer-local position.
	# TileMapLayer.local_to_map() expects a *local* position, not global.
	var mouse_local: Vector2 = build_layer.to_local(mouse_global)

	# Isometric maps often feel like you must click "too high" because the map
	# coordinate is based on the diamond center while the visible contact point is
	# lower. Nudging the sampling point upward makes placement match the cursor.
	var ts: TileSet = build_layer.tile_set
	if ts != null and ts.tile_shape == TileSet.TILE_SHAPE_ISOMETRIC:
		mouse_local.y -= float(ts.tile_size.y) * 0.5
	
	# Convert to tile coordinates
	current_tile_pos = build_layer.local_to_map(mouse_local)
	if ts != null and ts.tile_shape == TileSet.TILE_SHAPE_ISOMETRIC:
		current_tile_pos += iso_cursor_cell_offset
	
	# Check if we're over a build slot (black tile)
	var cell_data = build_layer.get_cell_source_id(current_tile_pos)
	is_over_build_slot = (cell_data != -1)  # -1 means empty tile
	
	# Update preview if tile changed
	if current_tile_pos != last_tile_pos:
		last_tile_pos = current_tile_pos
		_update_preview()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_over_build_slot:
			_place_building_at(current_tile_pos)
			get_tree().root.set_input_as_handled()

func _update_preview() -> void:
	"""Show visual feedback for tile selection"""
	if is_over_build_slot:
		# Emit a signal or debug draw to show selection
		print("Preview: Black tile at %s - ready to place building" % current_tile_pos)
	else:
		print("Not over build slot")

func _place_building_at(tile_pos: Vector2i) -> void:
	"""Replace a black tile with a building tile from another layer"""
	print("Attempting to place building at: %s" % tile_pos)
	
	# Get the current source/id from the black tile
	var source_id = build_layer.get_cell_source_id(tile_pos)
	if source_id == -1:
		print("Error: No tile at %s" % tile_pos)
		return
	
	# For now, just mark it as "selected" - we'll replace with actual building
	# when building type is chosen from UI
	print("Building slot %s is now selected - waiting for building menu" % tile_pos)
	
	# Future: Replace with selected building from UI menu
	# build_layer.set_cell(tile_pos, roof_layer_id, building_tile_coords)

func set_selected_building(building_id: int) -> void:
	"""Called from UI when player selects a building type"""
	selected_building = building_id
	print("Selected building type: %d" % building_id)

func get_black_tile_positions() -> Array:
	"""Return array of all black tile positions (build slots)"""
	var positions: Array = []
	
	# Iterate through all tiles in BuildLayer
	for tile_pos in build_layer.get_used_cells():
		positions.append(tile_pos)
	
	return positions

func highlight_slot(tile_pos: Vector2i, highlight: bool = true) -> void:
	"""Show/hide visual highlight on a specific slot (for UI selection)"""
	# Currently only logs; could add visual effects here
	if highlight:
		print("Highlighting build slot: %s" % tile_pos)
	else:
		print("Unhighlighting build slot: %s" % tile_pos)
