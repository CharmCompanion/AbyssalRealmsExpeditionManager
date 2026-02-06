class_name TownActionRest
extends Action

const REST_PROP: String = "rest_need"

@export var rest_reduction: float = 0.7

func get_validity_checks() -> Array[Precondition]:
	return [
		Precondition.agent_has_property(REST_PROP),
		Precondition.agent_property_greater_than(REST_PROP, 0.0),
	]

func get_action_cost(_agent_blackboard: GdPAIBlackboard, _world_state: GdPAIBlackboard) -> float:
	return 2.0

func get_preconditions() -> Array[Precondition]:
	return []

func simulate_effect(agent_blackboard: GdPAIBlackboard, _world_state: GdPAIBlackboard):
	var rest_need := float(agent_blackboard.get_property(REST_PROP))
	agent_blackboard.set_property(REST_PROP, clampf(rest_need - rest_reduction, 0.0, 1.0))

func perform_action(agent: GdPAIAgent, _delta: float) -> Action.Status:
	var rest_need := float(agent.blackboard.get_property(REST_PROP))
	agent.blackboard.set_property(REST_PROP, clampf(rest_need - rest_reduction, 0.0, 1.0))
	return Action.Status.SUCCESS

func get_title() -> String:
	return "Rest"

func get_description() -> String:
	return "Reduce rest need."