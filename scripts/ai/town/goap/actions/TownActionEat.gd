class_name TownActionEat
extends Action

const HUNGER_PROP: String = "hunger"

@export var hunger_reduction: float = 0.6

func get_validity_checks() -> Array[Precondition]:
	return [
		Precondition.agent_has_property(HUNGER_PROP),
		Precondition.agent_property_greater_than(HUNGER_PROP, 0.0),
	]

func get_action_cost(_agent_blackboard: GdPAIBlackboard, _world_state: GdPAIBlackboard) -> float:
	return 2.0

func get_preconditions() -> Array[Precondition]:
	return []

func simulate_effect(agent_blackboard: GdPAIBlackboard, _world_state: GdPAIBlackboard):
	var hunger := float(agent_blackboard.get_property(HUNGER_PROP))
	agent_blackboard.set_property(HUNGER_PROP, clampf(hunger - hunger_reduction, 0.0, 1.0))

func perform_action(agent: GdPAIAgent, _delta: float) -> Action.Status:
	var hunger := float(agent.blackboard.get_property(HUNGER_PROP))
	agent.blackboard.set_property(HUNGER_PROP, clampf(hunger - hunger_reduction, 0.0, 1.0))
	return Action.Status.SUCCESS

func get_title() -> String:
	return "Eat"

func get_description() -> String:
	return "Reduce hunger."