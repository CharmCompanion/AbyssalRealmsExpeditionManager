class_name TownGoalSafety
extends Goal

const SHELTER_PROP: String = "is_sheltered"
const DANGER_PROP: String = "danger"

@export var danger_threshold: float = 0.7

func compute_reward(agent: GdPAIAgent) -> float:
	var is_sheltered := bool(agent.blackboard.get_property(SHELTER_PROP))
	if is_sheltered:
		return 0.0

	var danger := 0.0
	if agent.world_node != null and agent.world_node.world_state != null:
		danger = float(agent.world_node.world_state.get_property(DANGER_PROP))

	if danger < danger_threshold:
		return 0.0
	return clampf(danger, 0.0, 1.0) * 120.0

func get_desired_state(_agent: GdPAIAgent) -> Array[Precondition]:
	return [Precondition.agent_property_equal_to(SHELTER_PROP, true)]

func get_title() -> String:
	return "Seek Shelter"

func get_description() -> String:
	return "Avoid danger by sheltering."