extends Node
class_name EnemyBrainLimbo

# Adapter layer for LimboAI-based enemy brains.
# This file intentionally avoids referencing LimboAI classes directly.
# When LimboAI is installed, you can wire up a BT/HSM resource and tick it here.

const AIAddonsUtil = preload("res://scripts/ai/AIAddons.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")

@export var enabled: bool = true
@export var behavior_resource_path: String = ""  # e.g. res://ai/enemies/goblin_bt.tres

# If true, BTPlayer will run automatically (physics update). If false, you must call tick().
@export var auto_update_physics: bool = true

var run_log_path: String = ""
var run_code: String = ""

var _bt_player: Node = null
var _last_bt_status: int = -999

func setup(p_run_code: String, p_run_log_path: String) -> void:
	run_code = String(p_run_code)
	run_log_path = String(p_run_log_path)

func is_available() -> bool:
	# Guard both by folder presence and class availability.
	return enabled and AIAddonsUtil.has_limboai() and ClassDB.class_exists("BTPlayer")

func ensure_started() -> void:
	if _bt_player != null:
		return
	if not is_available():
		return

	var bt_player_obj: Object = ClassDB.instantiate("BTPlayer")
	if bt_player_obj == null or not (bt_player_obj is Node):
		return
	var bt_player: Node = bt_player_obj
	bt_player.name = "BTPlayer"

	# Attach BTPlayer to the enemy entity (assumes this script lives under the entity).
	var host: Node = get_parent() if get_parent() != null else self
	host.add_child(bt_player)
	_bt_player = bt_player

	# Load or build a behavior tree.
	var bt_res: Resource = null
	var behavior_path: String = behavior_resource_path.strip_edges()
	var wants_raid: bool = behavior_path.to_lower().find("raid") != -1
	if behavior_path != "" and ResourceLoader.exists(behavior_path):
		var r: Resource = load(behavior_path)
		if r != null:
			bt_res = r
	else:
		bt_res = _build_raid_behavior_tree() if wants_raid else _build_default_behavior_tree()

	if bt_res == null:
		_log("ai.enemy.limbo.no_bt", {"behavior": behavior_resource_path})
		return

	# Provide a blackboard for tasks that rely on it.
	var bb: Object = _create_blackboard()
	if bb != null:
		bt_player.set("blackboard", bb)

	# Configure BTPlayer.
	bt_player.set("behavior_tree", bt_res)
	bt_player.set("active", true)
	bt_player.set("monitor_performance", false)
	bt_player.set("update_mode", 1 if auto_update_physics else 2) # PHYSICS or MANUAL

	# Optional: log status transitions.
	if bt_player.has_signal("updated"):
		bt_player.connect("updated", Callable(self, "_on_bt_updated"))

	_log("ai.enemy.limbo.ready", {
		"behavior": behavior_resource_path,
		"auto_update_physics": auto_update_physics,
	})

func tick(_delta: float) -> void:
	if not enabled:
		return
	ensure_started()
	if _bt_player == null:
		return
	if auto_update_physics:
		return
	# Manual ticking.
	if _bt_player.has_method("update"):
		_bt_player.call("update", _delta)


func _build_default_behavior_tree() -> Resource:
	# A tiny idle tree: repeat forever -> wait.
	if not ClassDB.class_exists("BehaviorTree"):
		return null
	var tree_obj: Object = ClassDB.instantiate("BehaviorTree")
	if tree_obj == null:
		return null
	var tree: Resource = tree_obj as Resource
	if tree == null:
		return null

	var repeat_task: Object = ClassDB.instantiate("BTRepeat")
	var wait_task: Object = ClassDB.instantiate("BTWait")
	if repeat_task == null or wait_task == null:
		return tree

	repeat_task.set("forever", true)
	wait_task.set("duration", 0.5)
	# BTRepeat is a decorator; it expects one child.
	if repeat_task.has_method("add_child"):
		repeat_task.call("add_child", wait_task)
	if tree.has_method("set_root_task"):
		tree.call("set_root_task", repeat_task)
	return tree


func _build_raid_behavior_tree() -> Resource:
	# Raid tree (minimal tactical loop):
	# repeat forever -> sequence:
	#   log(tick)
	#   selector:
	#     sequence: advance(until reached)->log(attack)->wait(1.0)
	#     sequence: log(advancing)->wait(0.5)
	if not ClassDB.class_exists("BehaviorTree"):
		return null
	if not ClassDB.class_exists("BTRepeat"):
		return null
	if not ClassDB.class_exists("BTSequence"):
		return null
	if not ClassDB.class_exists("BTSelector"):
		return null
	if not ClassDB.class_exists("BTWait"):
		return null

	var tree_obj: Object = ClassDB.instantiate("BehaviorTree")
	if tree_obj == null:
		return null
	var tree: Resource = tree_obj as Resource
	if tree == null:
		return null

	var repeat_task: Object = ClassDB.instantiate("BTRepeat")
	var root_seq: Object = ClassDB.instantiate("BTSequence")
	if repeat_task == null or root_seq == null:
		return tree

	repeat_task.set("forever", true)
	if repeat_task.has_method("add_child"):
		repeat_task.call("add_child", root_seq)

	var log_tick: Object = _instantiate_script_task("res://ai/tasks/raid/ARXRaidLog.gd")
	if log_tick != null:
		log_tick.set("event_type", "ai.enemy.raid.tick")
		log_tick.set("message", "tick")
		root_seq.call("add_child", log_tick)

	var selector: Object = ClassDB.instantiate("BTSelector")
	if selector != null:
		root_seq.call("add_child", selector)

		# Attack branch.
		var attack_seq: Object = ClassDB.instantiate("BTSequence")
		if attack_seq != null:
			selector.call("add_child", attack_seq)
			var advance: Object = _instantiate_script_task("res://ai/tasks/raid/ARXRaidAdvance.gd")
			if advance != null:
				advance.set("step", 0.25)
				advance.set("reach_threshold", 1.0)
				attack_seq.call("add_child", advance)
			var log_attack: Object = _instantiate_script_task("res://ai/tasks/raid/ARXRaidLog.gd")
			if log_attack != null:
				log_attack.set("event_type", "ai.enemy.raid.attack")
				log_attack.set("message", "attack_town")
				attack_seq.call("add_child", log_attack)
			var wait_attack: Object = ClassDB.instantiate("BTWait")
			if wait_attack != null:
				wait_attack.set("duration", 1.0)
				attack_seq.call("add_child", wait_attack)

		# Advancing branch.
		var advance_seq: Object = ClassDB.instantiate("BTSequence")
		if advance_seq != null:
			selector.call("add_child", advance_seq)
			var log_adv: Object = _instantiate_script_task("res://ai/tasks/raid/ARXRaidLog.gd")
			if log_adv != null:
				log_adv.set("event_type", "ai.enemy.raid.advance")
				log_adv.set("message", "advance")
				advance_seq.call("add_child", log_adv)
			var wait_adv: Object = ClassDB.instantiate("BTWait")
			if wait_adv != null:
				wait_adv.set("duration", 0.5)
				advance_seq.call("add_child", wait_adv)

	if tree.has_method("set_root_task"):
		tree.call("set_root_task", repeat_task)
	return tree


func _instantiate_script_task(script_path: String) -> Object:
	if not ResourceLoader.exists(script_path):
		return null
	var s: Variant = load(script_path)
	if s == null:
		return null
	# LimboAI tasks are Resources; instancing as Object is fine.
	var obj: Object = s.new()
	return obj


func _create_blackboard() -> Object:
	if not ClassDB.class_exists("Blackboard"):
		return null
	var bb: Object = ClassDB.instantiate("Blackboard")
	if bb == null:
		return null
	# Populate commonly used vars. Keep deterministic.
	bb.call("set_var", &"run_code", run_code)
	bb.call("set_var", &"run_log_path", run_log_path)
	bb.call("set_var", &"raid_progress", 0.0)
	bb.call("set_var", &"has_reached_town", false)
	return bb


func _on_bt_updated(status: int) -> void:
	if status == _last_bt_status:
		return
	_last_bt_status = status
	_log("ai.enemy.limbo.bt_updated", {
		"status": status,
		"node": get_parent().name if get_parent() != null else name,
	})

func _log(event_type: String, payload: Dictionary) -> void:
	if run_log_path.strip_edges() == "":
		return
	RunLogUtil.append_to(run_log_path, event_type, {
		"run_code": run_code,
		"payload": payload,
	})
