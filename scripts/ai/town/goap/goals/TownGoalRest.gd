class_name TownGoalRest
extends Goal

const REST_PROP: String = "rest_need"

@export var satisfied_at_or_below: float = 0.2

func compute_reward(agent: GdPAIAgent) -> float:
	var rest_need := float(agent.blackboard.get_property(REST_PROP))
	# Rest need is [0..1] where 1 = exhausted.
	return clampf(rest_need, 0.0, 1.0) * 80.0

func get_desired_state(_agent: GdPAIAgent) -> Array[Precondition]:
	return [Precondition.agent_property_leq_than(REST_PROP, satisfied_at_or_below)]

func get_title() -> String:
	return "Rest"

func get_description() -> String:
	return "Get rest and recover."