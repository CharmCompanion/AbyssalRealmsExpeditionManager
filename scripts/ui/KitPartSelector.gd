@tool
extends HBoxContainer
class_name KitPartSelector

## Replicates the kit's part selector UI: < [icon] > [randomize] [✓]

signal part_changed(folder_name: String)
signal randomize_requested()
signal enabled_changed(enabled: bool)

@export var part_label := "BODY":
	set(val):
		part_label = val
		if _label:
			_label.text = part_label

var _available_folders: Array[String] = []
var _current_index := 0
var _enabled := true

@onready var _label: Label = $Label
@onready var _prev_button: Button = $PrevButton
@onready var _icon: TextureRect = $IconPreview
@onready var _next_button: Button = $NextButton
@onready var _randomize_button: Button = $RandomizeButton
@onready var _toggle_button: CheckButton = $ToggleCheck

func _ready() -> void:
	_label.text = part_label
	_prev_button.pressed.connect(_on_prev)
	_next_button.pressed.connect(_on_next)
	_randomize_button.pressed.connect(func() -> void: randomize_requested.emit())
	_toggle_button.toggled.connect(func(val: bool) -> void:
		_enabled = val
		enabled_changed.emit(val)
	)
	_toggle_button.button_pressed = true
	_update_buttons()

func set_folders(folders: Array[String]) -> void:
	_available_folders = folders
	_current_index = 0
	_update_buttons()
	_emit_current()

func get_current_folder() -> String:
	if _available_folders.is_empty():
		return ""
	return _available_folders[_current_index]

func is_enabled() -> bool:
	return _enabled

func _on_prev() -> void:
	if _available_folders.is_empty():
		return
	_current_index = (_current_index - 1 + _available_folders.size()) % _available_folders.size()
	_update_buttons()
	_emit_current()

func _on_next() -> void:
	if _available_folders.is_empty():
		return
	_current_index = (_current_index + 1) % _available_folders.size()
	_update_buttons()
	_emit_current()

func _update_buttons() -> void:
	if _prev_button:
		_prev_button.disabled = _available_folders.is_empty()
	if _next_button:
		_next_button.disabled = _available_folders.is_empty()
	if _label:
		if _available_folders.is_empty():
			_label.text = "%s: None" % part_label
		else:
			_label.text = "%s: %s" % [part_label, _available_folders[_current_index]]

func _emit_current() -> void:
	part_changed.emit(get_current_folder())
