@tool
extends BTAction
class_name ARXRaidLog

const RunLog = preload("res://scripts/run/RunLog.gd")

@export var event_type: String = "ai.enemy.raid"
@export var message: String = ""

func _tick(delta: float) -> Status:
	var bb: Object = get_blackboard()
	if bb == null:
		return SUCCESS
	var log_path: String = String(bb.call("get_var", &"run_log_path", "", false))
	if log_path.strip_edges() == "":
		return SUCCESS

	var run_code: String = String(bb.call("get_var", &"run_code", "", false))
	var agent: Object = get_agent()
	var data: Dictionary = {
		"message": message,
		"delta": delta,
		"agent": str(agent) if agent != null else "",
	}
	RunLog.append_to(log_path, event_type, {
		"run_code": run_code,
		"payload": data,
	})
	return SUCCESS
