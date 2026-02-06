
extends Control

const SAVE_DIR: String = "user://saves"
const SAVE_EXT: String = ".json"

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const CREATE_TOWN_SCENE: String = "res://scenes/ui/CreateTown.tscn"

@export var total_slots: int = 20
@export var slot_height: int = 78
@export var slot_spacing: int = 10
@export var auto_select_first_filled: bool = false

@onready var slots_box: VBoxContainer = $"ContentRoot/Margin/Content/PageContainer/RightPage/RightMargin/RightVBox/SlotsScroll/Slots"

@onready var btn_copy: Button = $"ContentRoot/Margin/Content/PageContainer/RightPage/RightMargin/RightVBox/BottomBar/Copy"
@onready var btn_delete: Button = $"ContentRoot/Margin/Content/PageContainer/RightPage/RightMargin/RightVBox/BottomBar/Delete"
@onready var btn_select: Button = $"ContentRoot/Margin/Content/PageContainer/RightPage/RightMargin/RightVBox/BottomBar/Select"
@onready var btn_create: Button = $"ContentRoot/Margin/Content/PageContainer/RightPage/RightMargin/RightVBox/BottomBar/Create"
@onready var btn_back: Button = $"ContentRoot/Margin/Content/PageContainer/RightPage/RightMargin/RightVBox/BottomBar/Back"

@onready var confirm: ConfirmationDialog = $"ContentRoot/Margin/Content/Confirm"

@onready var lbl_save_name: Label = $"ContentRoot/Margin/Content/PageContainer/LeftPage/LeftMargin/DetailPanel/BasicInfo/SaveName"
@onready var lbl_play_time: Label = $"ContentRoot/Margin/Content/PageContainer/LeftPage/LeftMargin/DetailPanel/BasicInfo/PlayTime"
@onready var lbl_last_saved: Label = $"ContentRoot/Margin/Content/PageContainer/LeftPage/LeftMargin/DetailPanel/BasicInfo/LastSaved"

@onready var val_population: Label = $"ContentRoot/Margin/Content/PageContainer/LeftPage/LeftMargin/DetailPanel/ResourcesGrid/PopulationValue"
@onready var val_gold: Label = $"ContentRoot/Margin/Content/PageContainer/LeftPage/LeftMargin/DetailPanel/ResourcesGrid/GoldValue2"
@onready var val_food: Label = $"ContentRoot/Margin/Content/PageContainer/LeftPage/LeftMargin/DetailPanel/ResourcesGrid/FoodValue2"
@onready var val_wood: Label = $"ContentRoot/Margin/Content/PageContainer/LeftPage/LeftMargin/DetailPanel/ResourcesGrid/WoodValue"
@onready var val_stone: Label = $"ContentRoot/Margin/Content/PageContainer/LeftPage/LeftMargin/DetailPanel/ResourcesGrid/StoneValue"

var _slot_buttons: Array[Button] = []

var _selected_slot_index: int = -1
var _selected_path: String = ""
var _selected_data: Dictionary = {}

# Locked source (chosen by pressing Select on a filled slot).
var _copy_source_slot_index: int = -1
var _copy_source_path: String = ""

var _pending_confirm_action: String = "" # "delete" | "copy_overwrite" | "copy_clear" | "create_overwrite" | "notice" | ""
var _pending_delete_path: String = ""
var _pending_delete_slot_index: int = -1

var _pending_copy_source_path: String = ""
var _pending_copy_destination_path: String = ""
var _pending_copy_destination_slot_index: int = -1

var _pending_create_path: String = ""
var _pending_create_slot_index: int = -1

func _ready() -> void:
	_ensure_save_dir()

	btn_copy.pressed.connect(_on_copy_pressed)
	btn_delete.pressed.connect(_on_delete_pressed)
	btn_select.pressed.connect(_on_select_pressed)
	btn_create.pressed.connect(_on_create_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	confirm.confirmed.connect(_on_confirm_dialog_confirmed)

	_build_slots()
	_refresh_slots()
	_set_selected_slot(-1)

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _build_slots() -> void:
	_clear_slots_ui()

	slots_box.add_theme_constant_override("separation", slot_spacing)

	for i: int in range(total_slots):
		var btn: Button = Button.new()
		btn.name = "Slot_%02d" % (i + 1)
		btn.text = "Slot %02d  —  Empty" % (i + 1)
		btn.toggle_mode = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, float(slot_height))
		btn.pressed.connect(_on_slot_pressed.bind(i))
		slots_box.add_child(btn)
		_slot_buttons.append(btn)

func _clear_slots_ui() -> void:
	for child: Node in slots_box.get_children():
		child.queue_free()
	_slot_buttons.clear()

func _slot_path(i: int) -> String:
	return "%s/slot_%02d%s" % [SAVE_DIR, i + 1, SAVE_EXT]

func _refresh_slots() -> void:
	var first_filled: int = -1

	for i: int in range(_slot_buttons.size()):
		var path: String = _slot_path(i)
		var exists: bool = FileAccess.file_exists(path)

		if exists and first_filled == -1:
			first_filled = i

		var title: String = "Slot %02d" % (i + 1)
		if exists:
			var data: Dictionary = _read_save(path)
			var town_name: String = _get_str(data, ["town_name", "townName", "settlement_name", "settlementName"], "Save")
			var last_saved_v: Variant = _get_any(data, ["last_saved", "lastSaved", "timestamp", "saved_at"], "")
			var last_saved: String = _format_timestamp(last_saved_v)
			_slot_buttons[i].text = "%s  —  %s  (%s)" % [title, town_name, last_saved]
		else:
			_slot_buttons[i].text = "%s  —  Empty" % title

		_slot_buttons[i].disabled = false

	if auto_select_first_filled:
		if _selected_slot_index == -1 and first_filled != -1:
			_on_slot_pressed(first_filled)
		elif _selected_slot_index != -1:
			var still_exists: bool = FileAccess.file_exists(_slot_path(_selected_slot_index))
			if not still_exists:
				_set_selected_slot(-1)

func _on_slot_pressed(i: int) -> void:
	_set_selected_slot(i)

func _set_selected_slot(i: int) -> void:
	_selected_slot_index = i
	_selected_path = ""
	_selected_data = {}

	for s_i: int in range(_slot_buttons.size()):
		_slot_buttons[s_i].button_pressed = (s_i == i)

	if i < 0 or i >= total_slots:
		_fill_details_empty()
		_update_action_buttons(false)
		return

	_selected_path = _slot_path(i)
	var has_file: bool = FileAccess.file_exists(_selected_path)
	if has_file:
		_selected_data = _read_save(_selected_path)
		_fill_details_from_save(_selected_data)
		_update_action_buttons(true)
	else:
		_fill_details_empty("Slot %02d" % (i + 1))
		_update_action_buttons(false)

func _update_action_buttons(selected_has_file: bool) -> void:
	btn_back.disabled = false

	# Select should be enabled for any slot once one is highlighted.
	btn_select.disabled = (_selected_slot_index < 0)
	# Create is available for any slot; it will confirm overwrite if needed.
	btn_create.disabled = (_selected_slot_index < 0)

	# Copy becomes available after pressing Select (locking a source slot), and requires a destination.
	var source_locked: bool = (_copy_source_slot_index != -1)
	var has_destination: bool = (_selected_slot_index >= 0)
	var same_as_source: bool = has_destination and (_selected_slot_index == _copy_source_slot_index)
	btn_copy.disabled = (not source_locked) or (not has_destination) or same_as_source

	# Delete deletes the currently highlighted slot (not the locked source).
	btn_delete.disabled = not selected_has_file

func _on_select_pressed() -> void:
	if _selected_slot_index < 0:
		return

	# Lock this slot as the source.
	_copy_source_slot_index = _selected_slot_index
	_copy_source_path = _selected_path

	_update_action_buttons(FileAccess.file_exists(_selected_path))

func _on_copy_pressed() -> void:
	if _copy_source_slot_index == -1:
		return
	if _selected_slot_index < 0 or _selected_slot_index == _copy_source_slot_index:
		_show_notice("Pick a destination slot, then press Copy.")
		return

	var source_exists: bool = FileAccess.file_exists(_copy_source_path)
	var dest_exists: bool = FileAccess.file_exists(_selected_path)

	# Copying from an empty source means "clear the destination".
	if not source_exists:
		if not dest_exists:
			_show_notice("Both source and destination are empty.")
			return
		_pending_confirm_action = "copy_clear"
		_pending_copy_destination_path = _selected_path
		_pending_copy_destination_slot_index = _selected_slot_index
		confirm.get_cancel_button().visible = true
		confirm.title = "Confirm Clear"
		confirm.dialog_text = "Clear (delete) the destination save? This cannot be undone."
		confirm.popup_centered()
		return

	# If destination already has a save, confirm overwrite.
	if dest_exists:
		_pending_confirm_action = "copy_overwrite"
		_pending_copy_source_path = _copy_source_path
		_pending_copy_destination_path = _selected_path
		_pending_copy_destination_slot_index = _selected_slot_index
		confirm.get_cancel_button().visible = true
		confirm.title = "Confirm Copy"
		confirm.dialog_text = "Overwrite the destination save with the selected save? This cannot be undone."
		confirm.popup_centered()
		return

	var data: Dictionary = _read_save(_copy_source_path)
	if data.is_empty():
		_show_notice("Copy failed: source save could not be read.")
		return

	data["copied_from_slot"] = _copy_source_slot_index + 1
	data["last_saved"] = Time.get_unix_time_from_system()

	if not _write_save(_selected_path, data):
		_show_notice("Copy failed.")
		return

	_refresh_slots()
	_set_selected_slot(_selected_slot_index)

func _on_delete_pressed() -> void:
	if _selected_slot_index < 0:
		return
	if not FileAccess.file_exists(_selected_path):
		_show_notice("Nothing to delete.")
		return

	_pending_confirm_action = "delete"
	_pending_delete_path = _selected_path
	_pending_delete_slot_index = _selected_slot_index

	confirm.get_cancel_button().visible = true
	confirm.title = "Confirm Delete"
	confirm.dialog_text = "Delete this save? This cannot be undone."
	confirm.popup_centered()


func _on_create_pressed() -> void:
	if _selected_slot_index < 0:
		return
	if _selected_path.is_empty():
		return

	if FileAccess.file_exists(_selected_path):
		_pending_confirm_action = "create_overwrite"
		_pending_create_path = _selected_path
		_pending_create_slot_index = _selected_slot_index
		confirm.get_cancel_button().visible = true
		confirm.title = "Confirm Overwrite"
		confirm.dialog_text = "Overwrite this slot and create a new town?"
		confirm.popup_centered()
		return

	_create_new_save(_selected_path)
	_refresh_slots()
	_set_selected_slot(_selected_slot_index)
	get_tree().change_scene_to_file(CREATE_TOWN_SCENE)

func _on_confirm_dialog_confirmed() -> void:
	if _pending_confirm_action == "delete":
		_pending_confirm_action = ""

		if _pending_delete_path.is_empty():
			return

		if FileAccess.file_exists(_pending_delete_path):
			DirAccess.remove_absolute(_pending_delete_path)

		# Clear locked source if it was deleted.
		if _copy_source_slot_index == _pending_delete_slot_index:
			_copy_source_slot_index = -1
			_copy_source_path = ""

		_pending_delete_path = ""
		_pending_delete_slot_index = -1

		_refresh_slots()
		_set_selected_slot(_selected_slot_index)
		return

	if _pending_confirm_action == "copy_clear":
		_pending_confirm_action = ""

		if _pending_copy_destination_path.is_empty():
			return
		if FileAccess.file_exists(_pending_copy_destination_path):
			DirAccess.remove_absolute(_pending_copy_destination_path)

		var dest_index := _pending_copy_destination_slot_index
		_pending_copy_destination_path = ""
		_pending_copy_destination_slot_index = -1

		_refresh_slots()
		_set_selected_slot(dest_index)
		return

	if _pending_confirm_action == "copy_overwrite":
		_pending_confirm_action = ""

		if _pending_copy_source_path.is_empty() or _pending_copy_destination_path.is_empty():
			return
		if not FileAccess.file_exists(_pending_copy_source_path):
			_show_notice("Copy failed: source save not found.")
			return

		var data: Dictionary = _read_save(_pending_copy_source_path)
		if data.is_empty():
			_show_notice("Copy failed: source save could not be read.")
			return
		data["copied_from_slot"] = _copy_source_slot_index + 1
		data["last_saved"] = Time.get_unix_time_from_system()

		if not _write_save(_pending_copy_destination_path, data):
			_show_notice("Copy failed.")
			return

		var dest_index := _pending_copy_destination_slot_index
		_pending_copy_source_path = ""
		_pending_copy_destination_path = ""
		_pending_copy_destination_slot_index = -1

		_refresh_slots()
		_set_selected_slot(dest_index)
		return

	if _pending_confirm_action == "create_overwrite":
		_pending_confirm_action = ""

		if _pending_create_path.is_empty():
			return

		_create_new_save(_pending_create_path)
		var slot_index := _pending_create_slot_index
		_pending_create_path = ""
		_pending_create_slot_index = -1

		_refresh_slots()
		_set_selected_slot(slot_index)
		get_tree().change_scene_to_file(CREATE_TOWN_SCENE)
		return

	# Notice (or unknown) just clears the pending action.
	_pending_confirm_action = ""

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _show_notice(msg: String) -> void:
	_pending_confirm_action = "notice"
	confirm.get_cancel_button().visible = false
	confirm.title = "Notice"
	confirm.dialog_text = msg
	confirm.popup_centered()


func _create_new_save(path: String) -> void:
	var new_data: Dictionary = {
		"town_name": "New Town",
		"last_saved": Time.get_unix_time_from_system(),
		"play_time": 0,
	}
	_write_save(path, new_data)

func _fill_details_empty(slot_label: String = "No Save Selected") -> void:
	lbl_save_name.text = "Town Name: %s" % slot_label
	lbl_play_time.text = "Play Time: ---"
	lbl_last_saved.text = "Last Saved: ---"

	val_population.text = "---"
	val_gold.text = "---"
	val_food.text = "---"
	val_wood.text = "---"
	val_stone.text = "---"

func _fill_details_from_save(data: Dictionary) -> void:
	var town_name: String = _get_str(data, ["town_name", "townName", "settlement_name", "settlementName"], "---")
	var play_time_v: Variant = _get_any(data, ["play_time", "playTimeSeconds", "playTime", "seconds_played"], 0)
	var play_time: String = _format_play_time(play_time_v)
	var last_saved_v: Variant = _get_any(data, ["last_saved", "lastSaved", "timestamp", "saved_at"], "")
	var last_saved: String = _format_timestamp(last_saved_v)

	lbl_save_name.text = "Town Name: %s" % town_name
	lbl_play_time.text = "Play Time: %s" % play_time
	lbl_last_saved.text = "Last Saved: %s" % last_saved

	val_population.text = _fmt_int_or_dash(_get_int(data, ["population", "pop"], -1))
	val_gold.text = _fmt_int_or_dash(_get_int(data, ["gold"], -1))
	val_food.text = _fmt_int_or_dash(_get_int(data, ["food", "food_stores", "foodStores"], -1))
	val_wood.text = _fmt_int_or_dash(_get_int(data, ["wood"], -1))
	val_stone.text = _fmt_int_or_dash(_get_int(data, ["stone"], -1))

func _fmt_int_or_dash(v: int) -> String:
	if v < 0:
		return "---"
	return str(v)

func _read_save(path: String) -> Dictionary:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}

	var txt: String = f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed as Dictionary
	return {}

func _write_save(path: String, data: Dictionary) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true

func _get_any(data: Dictionary, keys: Array, fallback: Variant) -> Variant:
	for k: Variant in keys:
		if data.has(k):
			return data[k]
	return fallback

func _get_str(data: Dictionary, keys: Array, fallback: String) -> String:
	var v: Variant = _get_any(data, keys, fallback)
	if v == null:
		return fallback
	return str(v)

func _get_int(data: Dictionary, keys: Array, fallback: int) -> int:
	var v: Variant = _get_any(data, keys, null)
	if v == null:
		return fallback
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_FLOAT:
		return int(v)
	if typeof(v) == TYPE_STRING and String(v).is_valid_int():
		return int(String(v))
	return fallback

func _format_timestamp(v: Variant) -> String:
	if v == null:
		return "---"

	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		var t: int = int(v)
		if t <= 0:
			return "---"
		var dt: Dictionary = Time.get_datetime_dict_from_unix_time(t)
		return "%04d-%02d-%02d %02d:%02d" % [int(dt["year"]), int(dt["month"]), int(dt["day"]), int(dt["hour"]), int(dt["minute"])]

	if typeof(v) == TYPE_STRING:
		var s: String = String(v).strip_edges()
		if s.is_empty():
			return "---"
		return s

	return "---"

func _format_play_time(v: Variant) -> String:
	var seconds: int = 0

	if typeof(v) == TYPE_INT:
		seconds = int(v)
	elif typeof(v) == TYPE_FLOAT:
		seconds = int(v)
	elif typeof(v) == TYPE_STRING and String(v).is_valid_int():
		seconds = int(String(v))
	else:
		return "---"

	if seconds < 0:
		return "---"

	var h: int = int(seconds / 3600.0)
	var m: int = int((seconds % 3600) / 60.0)
	var s: int = seconds % 60

	if h > 0:
		return "%dh %dm" % [h, m]
	if m > 0:
		return "%dm %ds" % [m, s]
	return "%ds" % s
