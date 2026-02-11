@tool
extends EditorPlugin

var _panel: Control

func _enter_tree() -> void:
	_panel = preload("res://addons/tileset_tagger/ui/tileset_tagger_panel.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _panel)
	_panel.visible = true

func _exit_tree() -> void:
	if _panel:
		remove_control_from_docks(_panel)
		_panel.queue_free()
		_panel = null
