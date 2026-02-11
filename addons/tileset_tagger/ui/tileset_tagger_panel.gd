@tool
extends Control

const DEFAULT_JSON_PATH := "res://tools/tileset_tagger/tileset_tags.json"
const DEFAULT_MAP_PATH := "res://tools/tileset_tagger/tileset_tag_map.json"
const HISTORY_PATH := "res://tools/tileset_tagger/tag_history.json"
const CUSTOM_DATA_LAYER := "tag"
const DIRECTION_LAYER := "direction"
const IS_ANIM_LAYER := "is_animation"
const ANIM_TYPE_LAYER := "animation_type"

@onready var tileset_path: LineEdit = $Root/Toolbar/TileSetPath
@onready var browse_tileset: Button = $Root/Toolbar/BrowseTileSet
@onready var reload_btn: Button = $Root/Toolbar/Reload
@onready var help_toggle: Button = $Root/Toolbar/HelpToggle
@onready var help_panel: PanelContainer = $Root/HelpPanel
@onready var tag_input: LineEdit = $Root/TagRow/TagInput
@onready var apply_tag: Button = $Root/TagRow/ApplyTag
@onready var clear_tag: Button = $Root/TagRow/ClearTag
@onready var paint_toggle: CheckBox = $Root/TagRow/PaintToggle
@onready var history_option: OptionButton = $Root/TagRow/HistoryOption
@onready var direction_option: OptionButton = $Root/MetaRow/DirectionOption
@onready var is_anim_check: CheckBox = $Root/MetaRow/IsAnimCheck
@onready var anim_type_input: LineEdit = $Root/MetaRow/AnimTypeInput
@onready var json_path: LineEdit = $Root/IoRow/JsonPath
@onready var dump_json: Button = $Root/IoRow/DumpJson
@onready var load_json: Button = $Root/IoRow/LoadJson
@onready var save_map: Button = $Root/IoRow/SaveMap
@onready var tile_list: ItemList = $Root/Split/TileList
@onready var preview_tex: TextureRect = $Root/Split/Preview/PreviewTexture
@onready var preview_info: Label = $Root/Split/Preview/PreviewInfo
@onready var tileset_dialog: FileDialog = $Dialogs/TileSetDialog
@onready var json_dialog: FileDialog = $Dialogs/JsonDialog

var _tileset: TileSet
var _tile_keys: Array = []
var _history_tags: PackedStringArray = []

func _ready() -> void:
	json_path.text = DEFAULT_JSON_PATH
	_load_history()
	_init_direction_options()

	browse_tileset.pressed.connect(_on_browse_tileset)
	reload_btn.pressed.connect(_on_reload)
	help_toggle.pressed.connect(_on_help_toggle)
	apply_tag.pressed.connect(_on_apply_tag)
	clear_tag.pressed.connect(_on_clear_tag)
	dump_json.pressed.connect(_on_dump_json)
	load_json.pressed.connect(_on_load_json)
	save_map.pressed.connect(_on_save_map)
	tile_list.item_selected.connect(_on_item_selected)
	tile_list.multi_selected.connect(_on_item_multi_selected)
	history_option.item_selected.connect(_on_history_selected)

	tileset_dialog.file_selected.connect(_on_tileset_selected)
	json_dialog.file_selected.connect(_on_json_selected)


func _init_direction_options() -> void:
	direction_option.clear()
	direction_option.add_item("None")
	direction_option.add_item("N")
	direction_option.add_item("NE")
	direction_option.add_item("E")
	direction_option.add_item("SE")
	direction_option.add_item("S")
	direction_option.add_item("SW")
	direction_option.add_item("W")
	direction_option.add_item("NW")


func _on_browse_tileset() -> void:
	tileset_dialog.popup_centered_ratio(0.6)


func _on_tileset_selected(path: String) -> void:
	tileset_path.text = path
	_load_tileset(path)


func _on_reload() -> void:
	_load_tileset(tileset_path.text.strip_edges())


func _on_help_toggle() -> void:
	help_panel.visible = not help_panel.visible


func _load_tileset(path: String) -> void:
	_tile_keys.clear()
	tile_list.clear()
	preview_tex.texture = null
	preview_info.text = "Select a tile to preview"

	if path == "":
		return
	var ts := load(path) as TileSet
	if ts == null:
		push_error("[TileSetTagger] TileSet not found: %s" % path)
		return
	_tileset = ts

	var count: int = ts.get_source_count()
	for i in range(count):
		var source_id: int = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var tex: Texture2D = atlas.texture
		var tile_size: Vector2i = atlas.get_tile_size()
		var tiles_count: int = atlas.get_tiles_count()
		for t in range(tiles_count):
			var coords: Vector2i = atlas.get_tile_id(t)
			var icon := _make_icon(tex, coords, tile_size)
			var label := "s:%d  (%d,%d)" % [source_id, coords.x, coords.y]
			tile_list.add_item(label, icon)
			_tile_keys.append({
				"source_id": source_id,
				"coords": coords,
				"texture_path": tex.resource_path if tex != null else "",
			})


func _make_icon(atlas_tex: Texture2D, coords: Vector2i, tile_size: Vector2i) -> Texture2D:
	if atlas_tex == null:
		return null
	var region := Rect2i(coords.x * tile_size.x, coords.y * tile_size.y, tile_size.x, tile_size.y)
	var at := AtlasTexture.new()
	at.atlas = atlas_tex
	at.region = region
	return at


func _on_item_selected(index: int) -> void:
	if Input.is_key_pressed(KEY_CTRL):
		_toggle_selection(index)
	elif not Input.is_key_pressed(KEY_SHIFT):
		_select_single(index)
	_update_preview(index)
	if Input.is_key_pressed(KEY_ALT) and paint_toggle.button_pressed:
		_clear_single(index)
		return
	if Input.is_key_pressed(KEY_ALT) and not paint_toggle.button_pressed:
		_clear_single(index)
		return
	_maybe_paint(index)


func _on_item_multi_selected(_index: int, _selected: bool) -> void:
	if tile_list.get_selected_items().size() == 1:
		_update_preview(tile_list.get_selected_items()[0])
	if _selected:
		if Input.is_key_pressed(KEY_ALT) and paint_toggle.button_pressed:
			_clear_single(_index)
			return
		if Input.is_key_pressed(KEY_ALT) and not paint_toggle.button_pressed:
			_clear_single(_index)
			return
		_maybe_paint(_index)


func _update_preview(index: int) -> void:
	if index < 0 or index >= _tile_keys.size():
		return
	var key: Dictionary = _tile_keys[index]
	var source_id: int = int(key.get("source_id", -1))
	var coords: Vector2i = Vector2i(key.get("coords", Vector2i.ZERO))
	var src := _tileset.get_source(source_id) as TileSetAtlasSource
	if src != null:
		preview_tex.texture = _make_icon(src.texture, coords, src.get_tile_size())
	preview_info.text = "Source %d / (%d,%d)" % [source_id, coords.x, coords.y]
	
	# Load current metadata
	var tile_data: TileData = _tileset.get_tile_data(source_id, coords, 0)
	if tile_data != null:
		# Load tag
		var current_tag: String = ""
		if _has_layer(CUSTOM_DATA_LAYER):
			current_tag = String(tile_data.get_custom_data(CUSTOM_DATA_LAYER))
		tag_input.text = current_tag
		
		# Load direction
		var current_dir: String = ""
		if _has_layer(DIRECTION_LAYER):
			current_dir = String(tile_data.get_custom_data(DIRECTION_LAYER))
		_set_direction_option(current_dir)
		
		# Load animation flag
		var is_anim: bool = false
		if _has_layer(IS_ANIM_LAYER):
			is_anim = bool(tile_data.get_custom_data(IS_ANIM_LAYER))
		is_anim_check.button_pressed = is_anim
		
		# Load or auto-detect animation type
		var current_anim_type: String = ""
		if _has_layer(ANIM_TYPE_LAYER):
			current_anim_type = String(tile_data.get_custom_data(ANIM_TYPE_LAYER))
		if current_anim_type == "":
			current_anim_type = _detect_animation_type(key.get("texture_path", ""))
		anim_type_input.text = current_anim_type


func _on_apply_tag() -> void:
	if _tileset == null:
		return
	var tag := tag_input.text.strip_edges()
	if tag == "":
		return
	_push_history(tag)
	_ensure_all_layers(_tileset)
	for idx in tile_list.get_selected_items():
		_apply_metadata_to_index(idx)
	ResourceSaver.save(_tileset, tileset_path.text.strip_edges())


func _on_clear_tag() -> void:
	if _tileset == null:
		return
	_ensure_all_layers(_tileset)
	for idx in tile_list.get_selected_items():
		_clear_metadata_at_index(idx)
	ResourceSaver.save(_tileset, tileset_path.text.strip_edges())


func _maybe_paint(index: int) -> void:
	if not paint_toggle.button_pressed:
		return
	if _tileset == null:
		return
	var tag := tag_input.text.strip_edges()
	if tag == "":
		return
	_push_history(tag)
	_ensure_all_layers(_tileset)
	_apply_metadata_to_index(index)
	ResourceSaver.save(_tileset, tileset_path.text.strip_edges())


func _select_single(index: int) -> void:
	if index < 0 or index >= tile_list.item_count:
		return
	tile_list.deselect_all()
	tile_list.select(index)


func _toggle_selection(index: int) -> void:
	if index < 0 or index >= tile_list.item_count:
		return
	if tile_list.is_selected(index):
		tile_list.deselect(index)
	else:
		tile_list.select(index, false)


func _clear_single(index: int) -> void:
	if _tileset == null:
		return
	_ensure_all_layers(_tileset)
	_clear_metadata_at_index(index)
	ResourceSaver.save(_tileset, tileset_path.text.strip_edges())


func _load_history() -> void:
	history_option.clear()
	history_option.add_item("History")
	history_option.set_item_disabled(0, true)
	_history_tags.clear()
	
	var data := _read_json(HISTORY_PATH)
	if data.is_empty():
		return
	var tags: Array = data.get("tags", [])
	for tag in tags:
		var t := String(tag).strip_edges()
		if t != "":
			_history_tags.append(t)
			history_option.add_item(t)


func _push_history(tag: String) -> void:
	if tag == "":
		return
	if _history_tags.has(tag):
		return
	_history_tags.append(tag)
	history_option.add_item(tag)
	_save_history()


func _save_history() -> void:
	var data := {
		"tags": Array(_history_tags),
	}
	_write_json(HISTORY_PATH, data)


func _on_history_selected(index: int) -> void:
	if index <= 0:
		return
	var tag := history_option.get_item_text(index)
	tag_input.text = tag


func _apply_tag_to_index(index: int, tag: String) -> void:
	if index < 0 or index >= _tile_keys.size():
		return
	var key: Dictionary = _tile_keys[index]
	var source_id: int = int(key.get("source_id", -1))
	var coords: Vector2i = Vector2i(key.get("coords", Vector2i.ZERO))
	var tile_data: TileData = _tileset.get_tile_data(source_id, coords, 0)
	if tile_data == null:
		return
	if tile_data.has_method("set_custom_data"):
		tile_data.set_custom_data(CUSTOM_DATA_LAYER, tag)


func _apply_metadata_to_index(index: int) -> void:
	if index < 0 or index >= _tile_keys.size():
		return
	var key: Dictionary = _tile_keys[index]
	var source_id: int = int(key.get("source_id", -1))
	var coords: Vector2i = Vector2i(key.get("coords", Vector2i.ZERO))
	var tile_data: TileData = _tileset.get_tile_data(source_id, coords, 0)
	if tile_data == null:
		return
	
	# Apply tag
	var tag := tag_input.text.strip_edges()
	tile_data.set_custom_data(CUSTOM_DATA_LAYER, tag)
	
	# Apply direction
	var dir := _get_selected_direction()
	tile_data.set_custom_data(DIRECTION_LAYER, dir)
	
	# Apply animation flag
	var is_anim := is_anim_check.button_pressed
	tile_data.set_custom_data(IS_ANIM_LAYER, is_anim)
	
	# Apply animation type
	var anim_type := anim_type_input.text.strip_edges()
	tile_data.set_custom_data(ANIM_TYPE_LAYER, anim_type)


func _clear_metadata_at_index(index: int) -> void:
	if index < 0 or index >= _tile_keys.size():
		return
	var key: Dictionary = _tile_keys[index]
	var source_id: int = int(key.get("source_id", -1))
	var coords: Vector2i = Vector2i(key.get("coords", Vector2i.ZERO))
	var tile_data: TileData = _tileset.get_tile_data(source_id, coords, 0)
	if tile_data == null:
		return
	
	tile_data.set_custom_data(CUSTOM_DATA_LAYER, "")
	tile_data.set_custom_data(DIRECTION_LAYER, "")
	tile_data.set_custom_data(IS_ANIM_LAYER, false)
	tile_data.set_custom_data(ANIM_TYPE_LAYER, "")


func _ensure_custom_data_layer(ts: TileSet) -> int:
	if not ts.has_method("get_custom_data_layer_count"):
		return -1
	var count: int = ts.get_custom_data_layer_count()
	for i in range(count):
		if ts.get_custom_data_layer_name(i) == CUSTOM_DATA_LAYER:
			return i
	if ts.has_method("add_custom_data_layer"):
		ts.add_custom_data_layer()
		var idx: int = ts.get_custom_data_layer_count() - 1
		if idx >= 0:
			if ts.has_method("set_custom_data_layer_name"):
				ts.set_custom_data_layer_name(idx, CUSTOM_DATA_LAYER)
			if ts.has_method("set_custom_data_layer_type"):
				ts.set_custom_data_layer_type(idx, TYPE_STRING)
			return idx
	return -1


func _ensure_all_layers(ts: TileSet) -> void:
	_ensure_layer(ts, CUSTOM_DATA_LAYER, TYPE_STRING)
	_ensure_layer(ts, DIRECTION_LAYER, TYPE_STRING)
	_ensure_layer(ts, IS_ANIM_LAYER, TYPE_BOOL)
	_ensure_layer(ts, ANIM_TYPE_LAYER, TYPE_STRING)


func _ensure_layer(ts: TileSet, layer_name: String, layer_type: int) -> int:
	if not ts.has_method("get_custom_data_layer_count"):
		return -1
	var count: int = ts.get_custom_data_layer_count()
	for i in range(count):
		if ts.get_custom_data_layer_name(i) == layer_name:
			return i
	if ts.has_method("add_custom_data_layer"):
		ts.add_custom_data_layer()
		var idx: int = ts.get_custom_data_layer_count() - 1
		if idx >= 0:
			ts.set_custom_data_layer_name(idx, layer_name)
			ts.set_custom_data_layer_type(idx, layer_type)
			return idx
	return -1


func _has_layer(layer_name: String) -> bool:
	if _tileset == null:
		return false
	var count: int = _tileset.get_custom_data_layer_count()
	for i in range(count):
		if _tileset.get_custom_data_layer_name(i) == layer_name:
			return true
	return false


func _get_selected_direction() -> String:
	var idx := direction_option.selected
	if idx <= 0:
		return ""
	return direction_option.get_item_text(idx)


func _set_direction_option(direction: String) -> void:
	var dir := direction.strip_edges()
	if dir == "":
		direction_option.selected = 0
		return
	for i in range(direction_option.item_count):
		if direction_option.get_item_text(i) == dir:
			direction_option.selected = i
			return
	direction_option.selected = 0


func _detect_animation_type(texture_path: String) -> String:
	if texture_path == "":
		return ""
	# Extract folder name from path like "res://assets/tilesets/Animations/walk/sprite.tres"
	var parts := texture_path.split("/")
	if parts.size() < 2:
		return ""
	# Look for common animation folder names
	for i in range(parts.size() - 1, -1, -1):
		var folder := parts[i].to_lower()
		if folder in ["walk", "idle", "run", "attack", "die", "death", "jump", "fall", "hit"]:
			return folder
		# Check for Animations or animated_tiles folders
		if folder == "animations" or folder == "animated_tiles" or folder == "animated":
			if i + 1 < parts.size():
				return parts[i + 1].get_basename()
	return ""


func _on_dump_json() -> void:
	if _tileset == null:
		return
	var out := {
		"tileset": tileset_path.text.strip_edges(),
		"entries": [],
	}

	var count: int = _tileset.get_source_count()
	for i in range(count):
		var source_id: int = _tileset.get_source_id(i)
		var source: TileSetSource = _tileset.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var entry := {
			"source_id": source_id,
			"type": source.get_class(),
			"texture": "",
			"tiles": [],
		}
		if atlas.texture != null:
			entry.texture = atlas.texture.resource_path
		var tiles_count: int = atlas.get_tiles_count()
		for t in range(tiles_count):
			var coords: Vector2i = atlas.get_tile_id(t)
			var tile_data: TileData = _tileset.get_tile_data(source_id, coords, 0)
			var tag: String = ""
			if tile_data != null and tile_data.has_method("get_custom_data"):
				tag = str(tile_data.get_custom_data(CUSTOM_DATA_LAYER))
			entry.tiles.append({
				"atlas_coords": [coords.x, coords.y],
				"tag": tag,
			})
		out.entries.append(entry)

	_write_json(json_path.text.strip_edges(), out)


func _on_load_json() -> void:
	json_dialog.popup_centered_ratio(0.6)


func _on_json_selected(path: String) -> void:
	json_path.text = path
	_apply_json_tags(path)


func _apply_json_tags(path: String) -> void:
	if _tileset == null:
		return
	var data := _read_json(path)
	if data.is_empty():
		return

	var entries: Array = data.get("entries", [])
	for entry in entries:
		var source_id: int = int(entry.get("source_id", -1))
		var source: TileSetSource = _tileset.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var tiles: Array = entry.get("tiles", [])
		for tile in tiles:
			var tag: String = String(tile.get("tag", "")).strip_edges()
			var coords_arr: Array = tile.get("atlas_coords", [0, 0])
			var coords: Vector2i = Vector2i(
				int(coords_arr[0]) if coords_arr.size() > 0 else 0,
				int(coords_arr[1]) if coords_arr.size() > 1 else 0
			)
			var tile_data: TileData = _tileset.get_tile_data(source_id, coords, 0)
			if tile_data != null and tile_data.has_method("set_custom_data"):
				tile_data.set_custom_data(CUSTOM_DATA_LAYER, tag)

	ResourceSaver.save(_tileset, tileset_path.text.strip_edges())


func _on_save_map() -> void:
	if _tileset == null:
		return
	var out := {
		"tileset": tileset_path.text.strip_edges(),
		"tags": [],
	}

	var count: int = _tileset.get_source_count()
	for i in range(count):
		var source_id: int = _tileset.get_source_id(i)
		var source: TileSetSource = _tileset.get_source(source_id)
		if source == null:
			continue
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		var tiles_count: int = atlas.get_tiles_count()
		for t in range(tiles_count):
			var coords: Vector2i = atlas.get_tile_id(t)
			var tile_data: TileData = _tileset.get_tile_data(source_id, coords, 0)
			if tile_data == null or not tile_data.has_method("get_custom_data"):
				continue
			var tag: String = str(tile_data.get_custom_data(CUSTOM_DATA_LAYER)).strip_edges()
			if tag == "":
				continue
			out.tags.append({
				"source_id": source_id,
				"atlas_coords": [coords.x, coords.y],
				"tag": tag,
			})

	_write_json(DEFAULT_MAP_PATH, out)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var result := JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		return {}
	return result as Dictionary


func _write_json(path: String, data: Dictionary) -> void:
	var text := JSON.stringify(data, "\t")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("[TileSetTagger] Failed to write: %s" % path)
		return
	f.store_string(text)
	f.close()
