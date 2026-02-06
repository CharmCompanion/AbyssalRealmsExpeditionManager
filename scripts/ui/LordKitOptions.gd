extends VBoxContainer

signal appearance_changed

@export var spritesheets_root := "res://imported/Map and Character/Stand-alone Character creator - 2D Fantasy V1-0-3 (1)/Character creator - 2D Fantasy_Data/StreamingAssets/spritesheets"

const Recipe = preload("res://scripts/appearance/CharacterAppearanceRecipe.gd")

@onready var _preview_rig := get_node_or_null("../../../../LordChoicesPanel/ChoicesPad/PreviewVBox/PreviewViewport/SubViewport/PreviewRig")

@onready var _idles_label := get_node_or_null("TopGrids/IdlesLabel") as Label
@onready var _idles_grid := get_node_or_null("TopGrids/IdlesGrid") as GridContainer

@onready var _action_option := get_node_or_null("ActionRow/ActionOption") as OptionButton

var _parts: Dictionary = {}

var _suppress_appearance_signal: bool = false


func _ready() -> void:
	randomize()

	# Dropdown + color picker per option.
	_init_row_part("Body", "NakedBody", $OptionsColumns/BodyPartsGrid/BodyRow, "Body", false)

	# Blank/none entry for each option (as requested).
	# If you want Body to also be hideable, change the last arg above to true.
	_init_row_part("Head", "Head", $OptionsColumns/BodyPartsGrid/HeadRow, "Head", true)
	_init_row_part("Chest", "Chest", $OptionsColumns/BodyPartsGrid/ChestRow, "Chest", true)
	_init_row_part("Hands", "Hands", $OptionsColumns/BodyPartsGrid/HandsRow, "Hands", true)
	_init_row_part("Belt", "Belt", $OptionsColumns/BodyPartsGrid/BeltRow, "Belt", true)
	_init_row_part("Legs", "Legs", $OptionsColumns/BodyPartsGrid/LegsRow, "Legs", true)
	_init_row_part("Shoes", "Shoes", $OptionsColumns/BodyPartsGrid/ShoesRow, "Shoes", true)

	_init_action()
	_init_idle_grid()

	for part_name in _parts.keys():
		_apply_part(part_name)
		_refresh_row(part_name)


func _init_row_part(part_name: String, folder_prefix: String, row: HBoxContainer, ui_prefix: String, allow_none: bool) -> void:
	if row == null:
		return

	var dropdown := row.get_node_or_null("%sDropdown" % ui_prefix) as OptionButton
	if dropdown == null:
		return
	# Note: OptionButton does not expose Button's text alignment as a public property in Godot 4.
	# Keep defaults here to avoid runtime errors.

	var color_picker := row.get_node_or_null("%sColorPicker" % ui_prefix) as ColorPickerButton

	var folders := _list_folders(folder_prefix)
	if folders.is_empty():
		# Some categories are a single folder (e.g., "NakedBody") rather than a prefix.
		var root_dir := DirAccess.open(spritesheets_root)
		if root_dir != null and root_dir.dir_exists(folder_prefix):
			folders.append(folder_prefix)
		else:
			row.visible = false
			return
	if allow_none:
		folders.push_front("")

	dropdown.clear()
	for folder in folders:
		var f := String(folder)
		dropdown.add_item("(None)" if f == "" else _short_name(folder_prefix, f))

	var start_index := 0
	if allow_none and folders.size() > 1:
		start_index = 1

	var data := {
		"folders": folders,
		"index": start_index,
		"prefix": folder_prefix,
		"dropdown": dropdown,
		"color_picker": color_picker,
		"color": Color.WHITE,
	}
	_parts[part_name] = data

	dropdown.select(start_index)
	dropdown.item_selected.connect(func(idx: int) -> void:
		_set_part_index(part_name, idx)
	)

	var prev_btn := row.get_node_or_null("%sPrev" % ui_prefix) as Button
	if prev_btn:
		prev_btn.pressed.connect(func() -> void:
			_cycle_part(part_name, -1)
		)

	var next_btn := row.get_node_or_null("%sNext" % ui_prefix) as Button
	if next_btn:
		next_btn.pressed.connect(func() -> void:
			_cycle_part(part_name, 1)
		)

	# Re-using the legacy "Icon" button as per-row random.
	var random_btn := row.get_node_or_null("%sIcon" % ui_prefix) as Button
	if random_btn:
		random_btn.pressed.connect(func() -> void:
			_randomize_part(part_name)
		)

	# Re-using the legacy "Color" button as per-row clear.
	var clear_btn := row.get_node_or_null("%sColor" % ui_prefix) as Button
	if clear_btn:
		clear_btn.pressed.connect(func() -> void:
			_clear_part(part_name)
		)

	if color_picker:
		color_picker.edit_alpha = true
		color_picker.color = Color.WHITE
		color_picker.color_changed.connect(func(c: Color) -> void:
			_set_color(part_name, c)
		)


func randomize_all_parts() -> void:
	# Randomizes all appearance options (excluding the name). Used by CreateTown's Random button.
	_suppress_appearance_signal = true
	for part_name in _parts.keys():
		_randomize_part(String(part_name))
	_suppress_appearance_signal = false
	appearance_changed.emit()


func randomize_all_options() -> void:
	# Randomizes all Lord tab options (excluding the name). This includes appearance + selected action.
	_suppress_appearance_signal = true
	for part_name in _parts.keys():
		_randomize_part(String(part_name))

	if _action_option != null and _action_option.item_count > 0:
		var idx := randi() % _action_option.item_count
		_action_option.select(idx)
		if _preview_rig and _preview_rig.has_method("set_action"):
			_preview_rig.set_action(_action_option.get_item_text(idx))
		_init_idle_grid()

	_suppress_appearance_signal = false
	appearance_changed.emit()


func _selected_folder(part_name: String) -> String:
	if not _parts.has(part_name):
		return ""
	var data: Dictionary = _parts[part_name]
	var folders: Array[String] = data.folders
	if folders.is_empty():
		return ""
	var idx := clampi(int(data.index), 0, folders.size() - 1)
	return String(folders[idx])


func _set_part_index(part_name: String, new_index: int) -> void:
	if not _parts.has(part_name):
		return
	var data: Dictionary = _parts[part_name]
	var folders: Array[String] = data.folders
	if folders.is_empty():
		return

	var idx := clampi(new_index, 0, folders.size() - 1)
	data.index = idx
	_apply_part(part_name)
	_refresh_row(part_name)
	if not _suppress_appearance_signal:
		appearance_changed.emit()


func _cycle_part(part_name: String, delta: int) -> void:
	if not _parts.has(part_name):
		return
	var data: Dictionary = _parts[part_name]
	var folders: Array[String] = data.folders
	if folders.is_empty():
		return
	var count := folders.size()
	var idx := int(data.index) + delta
	idx = ((idx % count) + count) % count
	_set_part_index(part_name, idx)


func _randomize_part(part_name: String) -> void:
	if not _parts.has(part_name):
		return
	var data: Dictionary = _parts[part_name]
	var folders: Array[String] = data.folders
	if folders.is_empty():
		return

	var candidates: Array[int] = []
	for i in range(folders.size()):
		if String(folders[i]) != "":
			candidates.append(i)
	if candidates.is_empty():
		_set_part_index(part_name, 0)
		return

	var pick := candidates[randi() % candidates.size()]
	_set_part_index(part_name, pick)


func _clear_part(part_name: String) -> void:
	if not _parts.has(part_name):
		return
	var data: Dictionary = _parts[part_name]
	var folders: Array[String] = data.folders
	if folders.is_empty():
		return

	var none_idx := folders.find("")
	if none_idx >= 0:
		_set_part_index(part_name, none_idx)
	else:
		# Body doesn't include (None) by default; treat clear as reset.
		_set_part_index(part_name, 0)


func _set_color(part_name: String, color: Color) -> void:
	if not _parts.has(part_name):
		return
	var data: Dictionary = _parts[part_name]
	data.color = color
	_apply_color(part_name)
	_refresh_row(part_name)
	if not _suppress_appearance_signal:
		appearance_changed.emit()


func get_recipe() -> CharacterAppearanceRecipe:
	var r := Recipe.new()
	r.profile_id = "lord"
	for part_name in _parts.keys():
		var part := String(part_name)
		r.part_folders[part] = _selected_folder(part)
		var data: Dictionary = _parts[part]
		r.part_colors[part] = data.get("color", Color.WHITE)
	return r


func apply_recipe(recipe: CharacterAppearanceRecipe) -> void:
	if recipe == null:
		return
	_suppress_appearance_signal = true
	for part_name in _parts.keys():
		var part := String(part_name)
		var data: Dictionary = _parts[part]
		var folders: Array[String] = data.folders
		var dropdown := data.get("dropdown", null) as OptionButton
		if dropdown != null:
			var desired_folder := String(recipe.part_folders.get(part, _selected_folder(part)))
			var idx := folders.find(desired_folder)
			if idx < 0:
				# If the desired folder isn't available, keep current.
				idx = int(data.index)
			_set_part_index(part, idx)

		var desired_color: Color = recipe.part_colors.get(part, data.get("color", Color.WHITE))
		_set_color(part, desired_color)

	_suppress_appearance_signal = false
	appearance_changed.emit()


func _apply_part(part_name: String) -> void:
	if _preview_rig == null or not _preview_rig.has_method("set_part_folder"):
		return
	var folder := _selected_folder(part_name)
	_preview_rig.set_part_folder(part_name, folder)
	_apply_color(part_name)


func _apply_color(part_name: String) -> void:
	if _preview_rig == null or not _preview_rig.has_method("set_part_color"):
		return
	if not _parts.has(part_name):
		return
	var data: Dictionary = _parts[part_name]
	_preview_rig.set_part_color(part_name, data.color)


func _refresh_row(part_name: String) -> void:
	if not _parts.has(part_name):
		return
	var data: Dictionary = _parts[part_name]

	var dropdown := data.get("dropdown", null) as OptionButton
	if dropdown:
		var idx := clampi(int(data.index), 0, dropdown.item_count - 1)
		if dropdown.selected != idx:
			dropdown.select(idx)

	var picker := data.get("color_picker", null) as ColorPickerButton
	if picker:
		picker.color = data.color
		picker.disabled = (_selected_folder(part_name) == "")


func _init_action() -> void:
	if _action_option == null:
		return

	_action_option.clear()
	var actions := _list_actions_for_folder("NakedBody")
	if actions.is_empty():
		actions = ["Idle", "Walk"]

	for action in actions:
		_action_option.add_item(action)

	_select_action("Idle" if actions.has("Idle") else actions[0])

	_action_option.item_selected.connect(func(_idx: int) -> void:
		if _preview_rig and _preview_rig.has_method("set_action"):
			_preview_rig.set_action(_action_option.get_item_text(_action_option.selected))
		_init_idle_grid()
	)


func _select_action(action_name: String) -> void:
	if _action_option == null:
		return

	for i in _action_option.item_count:
		if _action_option.get_item_text(i) == action_name:
			_action_option.select(i)
			if _preview_rig and _preview_rig.has_method("set_action"):
				_preview_rig.set_action(action_name)
			if _idles_grid:
				for child in _idles_grid.get_children():
					var b := child as BaseButton
					if b:
						b.button_pressed = (b.text == action_name)
			return


func _init_idle_grid() -> void:
	if _idles_grid == null or _action_option == null:
		if _idles_label:
			_idles_label.visible = false
		return

	var idle_actions: Array[String] = []
	for i in _action_option.item_count:
		var a := _action_option.get_item_text(i)
		if String(a).begins_with("Idle"):
			idle_actions.append(String(a))

	if idle_actions.is_empty():
		if _idles_label:
			_idles_label.visible = false
		_idles_grid.visible = false
		return

	_idles_grid.visible = true
	if _idles_label:
		_idles_label.visible = true

	for child in _idles_grid.get_children():
		child.queue_free()

	var group := ButtonGroup.new()
	for action_name in idle_actions:
		var action := String(action_name)
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = group
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(52, 30)
		btn.text = action
		_idles_grid.add_child(btn)
		btn.toggled.connect(func(pressed: bool) -> void:
			if not pressed:
				return
			_select_action(action)
		)

	var current := _action_option.get_item_text(_action_option.selected)
	var select := current if String(current).begins_with("Idle") else "Idle"
	_select_action(select)


func _list_folders(prefix: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(spritesheets_root)
	if dir == null:
		return result
	for dir_name in dir.get_directories():
		if dir_name.begins_with(prefix):
			result.append(dir_name)
	result.sort()
	return result


func _list_actions_for_folder(folder_name: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open("%s/%s" % [spritesheets_root, folder_name])
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".png"):
			continue
		var action := file_name.trim_suffix(".png")
		result.append(action)
	result.sort()
	return result


func _short_name(prefix: String, folder: String) -> String:
	if folder.begins_with(prefix):
		var suffix := folder.substr(prefix.length())
		if suffix != "":
			return suffix
	return folder
