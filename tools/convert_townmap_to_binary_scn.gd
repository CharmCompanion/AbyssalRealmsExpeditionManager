@tool
extends EditorScript

const SOURCE_SCENE := "res://scenes/world/TownMap.tscn"
const TARGET_SCENE := "res://scenes/world/TownMap.scn"

func _run() -> void:
	var packed_scene := load(SOURCE_SCENE) as PackedScene
	if packed_scene == null:
		push_error("[SceneBinaryConvert] Could not load source scene: %s" % SOURCE_SCENE)
		return

	var err := ResourceSaver.save(packed_scene, TARGET_SCENE)
	if err != OK:
		push_error("[SceneBinaryConvert] Failed to save binary scene (%s): error %d" % [TARGET_SCENE, err])
		return

	print("[SceneBinaryConvert] Saved binary scene: %s" % TARGET_SCENE)
	print("[SceneBinaryConvert] Open and use %s to avoid large-text save warnings." % TARGET_SCENE)
