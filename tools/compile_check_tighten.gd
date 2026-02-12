extends SceneTree

func _init() -> void:
	var script_res := load("res://tools/tighten_iso_tileset_selection.gd")
	if script_res == null:
		push_error("compile_check_tighten: FAILED to load tighten_iso_tileset_selection.gd")
		quit(1)
		return

	print("compile_check_tighten: OK (script parsed and loaded)")
	quit(0)
