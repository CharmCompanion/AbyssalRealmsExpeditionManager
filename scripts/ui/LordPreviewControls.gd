extends Control

@export var turn_step_degrees := 45.0

var _walking := false

@onready var _preview_rig := get_node_or_null("PreviewViewport/SubViewport/PreviewRig")
@onready var _turn_left_button: Button = $PreviewControls/TurnLeft
@onready var _anim_toggle_button: Button = $PreviewControls/AnimToggle
@onready var _turn_right_button: Button = $PreviewControls/TurnRight

func _ready() -> void:
	if _turn_left_button:
		_turn_left_button.pressed.connect(_on_turn_left)
	if _turn_right_button:
		_turn_right_button.pressed.connect(_on_turn_right)
	if _anim_toggle_button:
		_anim_toggle_button.pressed.connect(_on_toggle_anim)
	_update_anim_button_text()

func _on_turn_left() -> void:
	if _preview_rig != null and _preview_rig.has_method("rotate_step"):
		_preview_rig.rotate_step(-1, deg_to_rad(turn_step_degrees))

func _on_turn_right() -> void:
	if _preview_rig != null and _preview_rig.has_method("rotate_step"):
		_preview_rig.rotate_step(1, deg_to_rad(turn_step_degrees))

func _on_toggle_anim() -> void:
	_walking = !_walking
	_update_anim_button_text()
	if _preview_rig != null and _preview_rig.has_method("set_walking"):
		_preview_rig.set_walking(_walking)

func _update_anim_button_text() -> void:
	if _anim_toggle_button == null:
		return
	_anim_toggle_button.text = "Walking" if _walking else "Idle"
