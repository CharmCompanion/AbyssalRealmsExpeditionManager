extends Sprite2D

@export var idle_texture: Texture2D
@export var walk_texture: Texture2D
@export var frame_size: Vector2i = Vector2i(128, 128)
@export var directions: int = 8
@export var fps_idle: float = 6.0
@export var fps_walk: float = 8.0

# Optional remap if the spritesheet row order differs from the angle order.
@export var direction_row_map: PackedInt32Array = []

var _action: String = "Idle"
var _direction_index: int = 0
var _frame_index: int = 0
var _frame_accum: float = 0.0

func _ready() -> void:
	centered = true
	region_enabled = true
	_set_action(_action)
	_apply_frame()

func set_action(action_name: String) -> void:
	_set_action(action_name)

func set_walking(walking: bool) -> void:
	_set_action("Walk" if walking else "Idle")

func set_direction_from_vector(dir: Vector2) -> void:
	if dir.length() < 0.001:
		return
	var angle := atan2(dir.y, dir.x)
	var oct := int(round(angle / (TAU / 8.0)))
	oct = ((oct % 8) + 8) % 8
	_direction_index = _map_direction(oct)
	_apply_frame()

func _process(delta: float) -> void:
	var fps := fps_walk if _action == "Walk" else fps_idle
	if fps <= 0.0:
		return
	_frame_accum += delta
	var step := 1.0 / fps
	while _frame_accum >= step:
		_frame_accum -= step
		_frame_index = (_frame_index + 1) % max(1, _get_columns())
		_apply_frame()

func _set_action(action_name: String) -> void:
	_action = action_name
	_frame_index = 0
	_frame_accum = 0.0

	var tex: Texture2D = idle_texture
	if _action == "Walk" and walk_texture != null:
		tex = walk_texture
	texture = tex
	_apply_frame()

func _apply_frame() -> void:
	if texture == null:
		return
	if frame_size.x <= 0 or frame_size.y <= 0:
		return
	var columns := _get_columns()
	if columns <= 0:
		return
	var col := _frame_index % columns
	var row := clampi(_direction_index, 0, max(1, directions) - 1)
	region_rect = Rect2(col * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)

func _get_columns() -> int:
	if texture == null:
		return 0
	return int(float(texture.get_width()) / float(frame_size.x))

func _map_direction(idx: int) -> int:
	if direction_row_map.is_empty():
		return idx
	if idx < 0 or idx >= direction_row_map.size():
		return idx
	return int(direction_row_map[idx])
