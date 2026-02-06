extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const TOWN_VIEW_SCENE: String = "res://scenes/ui/TownView.tscn"

const SAVE_DIR: String = "user://saves"
const SAVE_EXT: String = "json"
const MAX_SLOTS: int = 8

@onready var slots_vbox: VBoxContainer = $"Wrap/Panel/Margin/Root/Body/Left/SlotsScroll/Slots"

@onready var detail_title: Label = $"Wrap/Panel/Margin/Root/Body/Right/DetailsPanel/DetailsMargin/Details/DetailTitle"
@onready var detail_body: Label = $"Wrap/Panel/Margin/Root/Body/Right/DetailsPanel/DetailsMargin/Details/DetailBody"

@onready var back_btn: Button = $"Wrap/Panel/Margin/Root/Footer/BackBtn"
@onready var delete_btn: Button = $"Wrap/Panel/Margin/Root/Footer/DeleteBtn"
@onready var new_btn: Button = $"Wrap/Panel/Margin/Root/Footer/NewBtn"
@onready var select_btn: Button = $"Wrap/Panel/Margin/Root/Footer/SelectBtn"

var _selected_path: String = ""

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	delete_btn.pressed.connect(_on_delete)
	new_btn.pressed.connect(_on_new)
	select_btn.pressed.connect(_on_select)

	_refresh_slots()

func _refresh_slots() -> void:
	_selected_path = ""
	_update_details("", "", false)

	for c in slots_vbox.get_children():
		c.queue_free()

	_ensure_save_dir()

	var saves := _list_save_files()
	saves.sort()

	var shown := 0
	for p in saves:
		if shown >= MAX_SLOTS:
			break
		_add_slot_button(p, "Save: " + p.get_file())
		shown += 1

	while shown < MAX_SLOTS:
		_add_slot_button("", "Empty Slot")
		shown += 1

func _add_slot_button(path: String, label_text: String) -> void:
	var b := Button.new()
	b.text = label_text
	b.custom_minimum_size = Vector2(0, 56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL

	if path == "":
		b.disabled = true
	else:
		b.pressed.connect(func() -> void:
			_selected_path = path
			_update_details(
				"Selected",
				_selected_path.replace("user://", ""),
				true
			)
		)

	slots_vbox.add_child(b)

func _update_details(title: String, body: String, has_selection: bool) -> void:
	if title == "":
		detail_title.text = "No slot selected"
		detail_body.text = "Pick a slot on the left.\n\nIf you have no saves yet, hit NEW to create one."
	else:
		detail_title.text = title
		detail_body.text = body

	select_btn.disabled = not has_selection
	delete_btn.disabled = not has_selection

func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_new() -> void:
	_ensure_save_dir()

	var new_path := _next_free_save_path()
	var payload := {
		"town_name": "New Town",
		"created_unix": Time.get_unix_time_from_system()
	}

	var f := FileAccess.open(new_path, FileAccess.WRITE)
	if f == null:
		push_error("[SaveSelect] Failed to create save: " + new_path)
		return

	f.store_string(JSON.stringify(payload, "\t"))
	f.close()

	_refresh_slots()

func _on_select() -> void:
	if _selected_path == "":
		return

	# Later: load the save data and pass it into TownView.
	# For now: just continue into TownView.
	get_tree().change_scene_to_file(TOWN_VIEW_SCENE)

func _on_delete() -> void:
	if _selected_path == "":
		return

	if FileAccess.file_exists(_selected_path):
		var da := DirAccess.open(SAVE_DIR)
		if da != null:
			da.remove(_selected_path.get_file())

	_refresh_slots()

func _ensure_save_dir() -> void:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _list_save_files() -> Array[String]:
	var out: Array[String] = []
	var da := DirAccess.open(SAVE_DIR)
	if da == null:
		return out

	da.list_dir_begin()
	while true:
		var f := da.get_next()
		if f == "":
			break
		if da.current_is_dir():
			continue
		if f.get_extension().to_lower() == SAVE_EXT:
			out.append(SAVE_DIR.path_join(f))
	da.list_dir_end()
	return out

func _next_free_save_path() -> String:
	for i in range(1, 9999):
		var name := "save_%04d.%s" % [i, SAVE_EXT]
		var p := SAVE_DIR.path_join(name)
		if not FileAccess.file_exists(p):
			return p
	return SAVE_DIR.path_join("save_%d.%s" % [Time.get_unix_time_from_system(), SAVE_EXT])
