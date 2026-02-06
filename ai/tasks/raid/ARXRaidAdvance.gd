@tool
extends BTAction
class_name ARXRaidAdvance

@export var step: float = 0.25
@export var reach_threshold: float = 1.0

func _tick(_delta: float) -> Status:
	var bb: Object = get_blackboard()
	if bb == null:
		return FAILURE

	var progress_var: Variant = bb.call("get_var", &"raid_progress", 0.0, false)
	var progress: float = float(progress_var)
	progress = clamp(progress + step, 0.0, reach_threshold)
	bb.call("set_var", &"raid_progress", progress)

	if progress >= reach_threshold:
		bb.call("set_var", &"has_reached_town", true)
		return SUCCESS
	# Intentionally return FAILURE while advancing so a parent Selector can fall back
	# to a separate "advance"/"wander" branch.
	return FAILURE
