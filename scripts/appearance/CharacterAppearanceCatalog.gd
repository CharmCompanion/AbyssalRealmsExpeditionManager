extends RefCounted
class_name CharacterAppearanceCatalog

var spritesheets_root: String

# Cache: prefix/exact -> folders
var _folders_cache: Dictionary = {}

func _init(root_path: String) -> void:
	spritesheets_root = root_path

func list_folders(prefix_or_exact: String, allow_exact_fallback: bool = true) -> Array[String]:
	var key := "%s|%s" % [prefix_or_exact, str(allow_exact_fallback)]
	if _folders_cache.has(key):
		return _folders_cache[key].duplicate()

	var result: Array[String] = []
	var dir := DirAccess.open(spritesheets_root)
	if dir == null:
		_folders_cache[key] = result
		return result

	for name in dir.get_directories():
		if String(name).begins_with(prefix_or_exact):
			result.append(String(name))

	# Some categories are a single folder rather than a prefix (e.g. NakedBody).
	if result.is_empty() and allow_exact_fallback:
		if dir.dir_exists(prefix_or_exact):
			result.append(prefix_or_exact)

	result.sort()
	_folders_cache[key] = result
	return result.duplicate()

func has_folder(folder_name: String) -> bool:
	var dir := DirAccess.open(spritesheets_root)
	if dir == null:
		return false
	return dir.dir_exists(folder_name)

func list_actions_for_folder(folder_name: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open("%s/%s" % [spritesheets_root, folder_name])
	if dir == null:
		return result
	for file_name in dir.get_files():
		var f := String(file_name)
		if not f.ends_with(".png"):
			continue
		result.append(f.trim_suffix(".png"))
	result.sort()
	return result
