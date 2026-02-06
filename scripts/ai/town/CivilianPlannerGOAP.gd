extends Node
class_name CivilianPlannerGOAP

# Adapter layer for GdPlanningAI (GOAP) civilian/adventurer-in-town planning.
# Avoids direct references to addon classes so the project runs without the addon.

const AIAddonsUtil = preload("res://scripts/ai/AIAddons.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")

const GdPAIWorldNodeScript = preload("res://addons/GdPlanningAI/scripts/nodes/gdpai_world_node.gd")
const TownGoalSafetyScript = preload("res://scripts/ai/town/goap/goals/TownGoalSafety.gd")
const TownGoalEatScript = preload("res://scripts/ai/town/goap/goals/TownGoalEat.gd")
const TownGoalRestScript = preload("res://scripts/ai/town/goap/goals/TownGoalRest.gd")
const TownActionSeekShelterScript = preload("res://scripts/ai/town/goap/actions/TownActionSeekShelter.gd")
const TownActionEatScript = preload("res://scripts/ai/town/goap/actions/TownActionEat.gd")
const TownActionRestScript = preload("res://scripts/ai/town/goap/actions/TownActionRest.gd")

const GdPAIBlackboardPlanScript = preload("res://addons/GdPlanningAI/scripts/gdpai_blackboard_plan.gd")
const PlanScript = preload("res://addons/GdPlanningAI/scripts/refcounteds/plan.gd")
const GdPAIAgentScript = preload("res://addons/GdPlanningAI/scripts/nodes/gdpai_agent.gd")

@export var enabled: bool = true

var run_log_path: String = ""
var run_code: String = ""

func setup(p_run_code: String, p_run_log_path: String) -> void:
	run_code = String(p_run_code)
	run_log_path = String(p_run_log_path)

func is_available() -> bool:
	return enabled and AIAddonsUtil.has_gdplanningai()

func choose_goal(agent_state: Dictionary, world_state: Dictionary) -> Dictionary:
	# Returns a goal/action plan descriptor.
	# When GdPlanningAI is installed, this uses its Plan simulator to pick a goal and a valid plan.
	if not is_available():
		return {"goal": "idle", "plan": []}

	# NOTE: GdPlanningAI's Plan logic is async (awaits preconditions/cost), so this function becomes a coroutine.

	# Build a temporary GdPAI agent instance (off-tree) with blackboards.
	var agent := GdPAIAgentScript.new()

	var agent_bb_plan := GdPAIBlackboardPlanScript.new()
	var agent_backend: Dictionary = agent_state.duplicate(true)
	if not agent_backend.has("hunger"):
		agent_backend["hunger"] = 0.0
	if not agent_backend.has("rest_need"):
		# Keep naming consistent with our goals/actions.
		agent_backend["rest_need"] = float(agent_state.get("rest_need", agent_state.get("rest", 0.0)))
	if not agent_backend.has("is_sheltered"):
		agent_backend["is_sheltered"] = false
	agent_bb_plan.blackboard_backend = agent_backend
	agent.blackboard = agent_bb_plan.generate_blackboard()

	var world_bb_plan := GdPAIBlackboardPlanScript.new()
	var world_backend: Dictionary = world_state.duplicate(true)
	if not world_backend.has("danger"):
		world_backend["danger"] = 0.0
	world_bb_plan.blackboard_backend = world_backend
	var world_bb := world_bb_plan.generate_blackboard()

	# Plan._compute_plan() assumes agent.world_node and agent.world_node.world_state are non-null.
	# Since this agent is off-tree, we provide a minimal real GdPAIWorldNode and inject our blackboard.
	var world_node := GdPAIWorldNodeScript.new()
	world_node.blackboard_plan = world_bb_plan
	world_node.set("world_state", world_bb)
	agent.world_node = world_node
	if agent.world_node == null or agent.world_node.world_state == null:
		_log("ai.town.goap.invalid_world_state", {
			"agent_state": agent_state,
			"world_state": world_state,
		})
		return {"goal": "idle", "plan": []}

	# Define available actions.
	var actions: Array[Action] = [
		TownActionSeekShelterScript.new(),
		TownActionEatScript.new(),
		TownActionRestScript.new(),
	]

	# Define goals.
	var goals: Array[Goal] = [
		TownGoalSafetyScript.new(),
		TownGoalEatScript.new(),
		TownGoalRestScript.new(),
	]

	var best_goal: Goal = null
	var best_plan: Plan = null
	var best_reward: float = -INF

	for g in goals:
		var reward := float(g.compute_reward(agent))
		if reward <= 0.0:
			continue
		var p := PlanScript.new()
		await p.initialize(agent, g, actions, 4)
		var plan_actions: Array = p.get_plan()
		# Plans include a dummy root Action node; filter it out later.
		if plan_actions.size() == 0:
			continue
		if reward > best_reward:
			best_reward = reward
			best_goal = g
			best_plan = p

	if best_goal == null or best_plan == null:
		_log("ai.town.goap.no_plan", {
			"agent_state": agent_state,
			"world_state": world_state,
		})
		return {"goal": "idle", "plan": []}

	var chosen_plan: Array = best_plan.get_plan()
	# Plan actions are returned from leaf->root; reverse for readability.
	chosen_plan.reverse()

	var plan_titles: Array[String] = []
	for a in chosen_plan:
		if a == null:
			continue
		var title := ""
		if a.has_method("get_title"):
			title = String(a.get_title())
		if title == "" or title == "Action":
			continue
		plan_titles.append(title)

	_log("ai.town.goap.plan_selected", {
		"goal": best_goal.get_title(),
		"reward": best_reward,
		"plan": plan_titles,
		"agent_state": agent_backend,
		"world_state": world_backend,
	})

	return {"goal": best_goal.get_title(), "plan": plan_titles}

func _log(event_type: String, payload: Dictionary) -> void:
	if run_log_path.strip_edges() == "":
		return
	RunLogUtil.append_to(run_log_path, event_type, {
		"run_code": run_code,
		"payload": payload,
	})
