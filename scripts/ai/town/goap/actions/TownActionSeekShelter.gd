class_name TownActionSeekShelter
extends Action

const SHELTER_PROP: String = "is_sheltered"

func get_validity_checks() -> Array[Precondition]:
	return [
		Precondition.agent_has_property(SHELTER_PROP),
		Precondition.agent_property_equal_to(SHELTER_PROP, false),
	]

func get_action_cost(_agent_blackboard: GdPAIBlackboard, _world_state: GdPAIBlackboard) -> float:
	return 1.0

func get_preconditions() -> Array[Precondition]:
	return []

func simulate_effect(agent_blackboard: GdPAIBlackboard, _world_state: GdPAIBlackboard):
	agent_blackboard.set_property(SHELTER_PROP, true)

func perform_action(agent: GdPAIAgent, _delta: float) -> Action.Status:
	agent.blackboard.set_property(SHELTER_PROP, true)
	return Action.Status.SUCCESS

func get_title() -> String:
	return "Seek Shelter"

func get_description() -> String:
	return "Move to safety (abstract)."