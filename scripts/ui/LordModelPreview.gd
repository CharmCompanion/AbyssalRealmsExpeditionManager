extends Node2D

@export var spritesheets_root := "res://imported/Map and Character/Stand-alone Character creator - 2D Fantasy V1-0-3 (1)/Character creator - 2D Fantasy_Data/StreamingAssets/spritesheets"
@export var preview_scale := 3.0
@export var center_offset := Vector2(0.0, 30.0)
@export var fps_idle := 8.0
@export var fps_walk := 10.0

const FRAME_SIZE := Vector2i(128, 128)
const DIRECTIONS := 8

const DEFAULT_LAYER_Z := {
	"Body": 0,
	"Legs": 10,
	"Shoes": 12,
	"Chest": 20,
	"Belt": 24,
	"Head": 30,
	"Hands": 40,
	# Future/optional layers (only used if nodes exist):
	"Bag": 45,
	"Shield": 46,
	"Melee": 47,
	"Ranged": 48,
	"Magic": 60,
	"Wings": 65,
	"Effect": 90,
	"Mount": -10,
}

var _walking := false
var _direction_index := 0
var _frame_index := 0
var _frame_accum := 0.0
var _action := "Idle"

var _layers: Dictionary = {}
var _part_colors: Dictionary = {}

var _part_folders: Dictionary = {}

const DEFAULT_PART_FOLDERS := {
	"Body": "NakedBody",
	"Legs": "Legs1",
	"Chest": "Chest1",
	"Head": "Head1",
	"Hands": "Hands1",
	"Shoes": "Shoes1",
	"Belt": "Belt1",
}

func _ready() -> void:
	scale = Vector2.ONE * preview_scale
	_build_layers()
	_reload_layer_textures()
	_apply_frame_to_layers()

	# SubViewport size can be 0 during _ready(); recenter after layout.
	call_deferred("_recenter_in_viewport")
	var vp := get_viewport()
	if vp != null:
		vp.size_changed.connect(func() -> void:
			call_deferred("_recenter_in_viewport")
		)


func _recenter_in_viewport() -> void:
	var sz: Vector2 = get_viewport_rect().size
	if sz == Vector2.ZERO:
		var vp := get_viewport()
		if vp != null:
			sz = Vector2(vp.size)
	if sz == Vector2.ZERO:
		return
	position = sz * 0.5 + center_offset


func _build_layers() -> void:
	_layers.clear()
	_part_colors.clear()
	_part_folders.clear()

	for child in get_children():
		var sprite := child as Sprite2D
		if sprite == null:
			continue
		_layers[String(sprite.name)] = sprite

	# Configure in a stable order.
	var names := _layers.keys()
	names.sort()
	var fallback_z := 50
	for layer_name in names:
		var part := String(layer_name)
		var layer: Sprite2D = _layers[part]
		var z := int(DEFAULT_LAYER_Z.get(part, fallback_z))
		if not DEFAULT_LAYER_Z.has(part):
			fallback_z += 1
		_configure_layer(layer, z)
		_part_colors[part] = Color.WHITE
		_part_folders[part] = ""

	# Known defaults.
	for part_name in DEFAULT_PART_FOLDERS.keys():
		var part := String(part_name)
		if _layers.has(part):
			_part_folders[part] = String(DEFAULT_PART_FOLDERS[part])

func _process(delta: float) -> void:
	var fps := fps_walk if _walking else fps_idle
	if fps <= 0.0:
		return
	_frame_accum += delta
	var step := 1.0 / fps
	while _frame_accum >= step:
		_frame_accum -= step
		_frame_index = (_frame_index + 1) % _get_columns()
		_apply_frame_to_layers()

func rotate_step(direction: int, step_radians: float) -> void:
	var approx_step := deg_to_rad(45.0)
	var steps := int(round(abs(step_radians) / approx_step))
	if steps < 1:
		steps = 1
	_direction_index = (_direction_index + direction * steps) % DIRECTIONS
	if _direction_index < 0:
		_direction_index += DIRECTIONS
	_apply_frame_to_layers()

func set_walking(walking: bool) -> void:
	_walking = walking
	_action = "Walk" if _walking else "Idle"
	_frame_index = 0
	_frame_accum = 0.0
	_reload_layer_textures()
	_apply_frame_to_layers()

func set_action(action_name: String) -> void:
	_action = action_name
	_walking = (_action == "Walk")
	_frame_index = 0
	_frame_accum = 0.0
	_reload_layer_textures()
	_apply_frame_to_layers()

func set_part_folder(part_name: String, folder_name: String) -> void:
	if _layers.is_empty():
		_build_layers()
	if not _layers.has(part_name):
		return
	_part_folders[part_name] = folder_name
	_reload_layer_textures()
	_apply_frame_to_layers()


func set_part_color(part_name: String, color: Color) -> void:
	if _layers.is_empty():
		_build_layers()
	if not _layers.has(part_name):
		return
	_part_colors[part_name] = color
	var layer: Sprite2D = _layers[part_name]
	if layer:
		layer.modulate = color

func _configure_layer(layer: Sprite2D, z: int) -> void:
	if layer == null:
		return
	layer.centered = true
	layer.region_enabled = true
	layer.z_index = z

func _reload_layer_textures() -> void:
	if _layers.is_empty():
		_build_layers()
	for part_name in _layers.keys():
		var part := String(part_name)
		var layer: Sprite2D = _layers[part]
		_set_layer_texture(layer, String(_part_folders.get(part, "")))
		layer.modulate = _part_colors.get(part, Color.WHITE)

func _set_layer_texture(layer: Sprite2D, folder: String) -> void:
	if layer == null:
		return
	if folder == "":
		layer.texture = null
		return
	var action := _action
	if action == "":
		action = "Idle"
	var path := "%s/%s/%s.png" % [spritesheets_root, folder, action]
	if not ResourceLoader.exists(path):
		# Fallback to Idle if a part doesn't have the action.
		path = "%s/%s/Idle.png" % [spritesheets_root, folder]
	if ResourceLoader.exists(path):
		layer.texture = load(path)
	else:
		layer.texture = null

func _apply_frame_to_layers() -> void:
	var columns := _get_columns()
	if columns <= 0:
		return
	var col := _frame_index % columns
	var row := clampi(_direction_index, 0, DIRECTIONS - 1)
	var rect := Rect2(col * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
	if _layers.is_empty():
		_build_layers()
	for layer in _layers.values():
		_apply_region(layer as Sprite2D, rect)

func _apply_region(layer: Sprite2D, rect: Rect2) -> void:
	if layer == null:
		return
	if layer.texture == null:
		return
	layer.region_rect = rect

func _get_columns() -> int:
	if _layers.is_empty():
		_build_layers()
	# Prefer body if available.
	if _layers.has("Body"):
		var body_layer: Sprite2D = _layers["Body"]
		if body_layer != null and body_layer.texture != null:
			return int(float(body_layer.texture.get_width()) / float(FRAME_SIZE.x))

	for layer in _layers.values():
		var s := layer as Sprite2D
		if s != null and s.texture != null:
			return int(float(s.texture.get_width()) / float(FRAME_SIZE.x))
	return 0
