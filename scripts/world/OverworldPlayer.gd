extends CharacterBody2D

@export var move_speed: float = 120.0
@export var rig_path: NodePath = ^"LordRig"

@onready var _rig: Node = get_node_or_null(rig_path)

func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	velocity = input_dir * move_speed
	move_and_slide()

	if _rig == null:
		return
	if _rig.has_method("set_direction_from_vector"):
		_rig.call("set_direction_from_vector", input_dir)
	if _rig.has_method("set_walking"):
		_rig.call("set_walking", input_dir.length() > 0.01)
	elif _rig.has_method("set_action"):
		_rig.call("set_action", "Walk" if input_dir.length() > 0.01 else "Idle")
