extends RefCounted
class_name TownGOAPWorldStub

# Minimal world_node stand-in for GdPlanningAI's Plan logic.
# Plan only requires `world_state` to exist and be a GdPAIBlackboard.
var world_state: Object = null
