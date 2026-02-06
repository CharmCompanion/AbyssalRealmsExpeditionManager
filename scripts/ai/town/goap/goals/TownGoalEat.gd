class_name TownGoalEat
extends Goal

const HUNGER_PROP: String = "hunger"

@export var satisfied_at_or_below: float = 0.2

func compute_reward(agent: GdPAIAgent) -> float:
	var hunger := float(agent.blackboard.get_property(HUNGER_PROP))
	# Hunger is [0..1] where 1 = starving.
	return clampf(hunger, 0.0, 1.0) * 100.0

func get_desired_state(_agent: GdPAIAgent) -> Array[Precondition]:
	return [Precondition.agent_property_leq_than(HUNGER_PROP, satisfied_at_or_below)]

func get_title() -> String:
	return "Eat"

func get_description() -> String:
	return "Find food and reduce hunger."