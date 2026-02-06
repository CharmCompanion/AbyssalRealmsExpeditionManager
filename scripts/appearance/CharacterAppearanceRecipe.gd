extends Resource
class_name CharacterAppearanceRecipe

@export var rng_seed: int = 0
@export var profile_id: String = ""
@export var theme_id: String = ""
@export var family_id: String = ""
@export var tags: PackedStringArray = []

@export var part_folders: Dictionary = {}
@export var part_colors: Dictionary = {}

# Optional hint for world rendering (e.g., kids).
@export var suggested_scale: float = 1.0


func to_dict() -> Dictionary:
	return {
		"seed": rng_seed,
		"profile_id": profile_id,
		"theme_id": theme_id,
		"family_id": family_id,
		"tags": tags,
		"suggested_scale": suggested_scale,
		"part_folders": part_folders.duplicate(true),
		"part_colors": _colors_to_dict(part_colors),
	}


static func from_dict(d: Dictionary) -> CharacterAppearanceRecipe:
	var r := CharacterAppearanceRecipe.new()
	r.rng_seed = int(d.get("seed", 0))
	r.profile_id = String(d.get("profile_id", ""))
	r.theme_id = String(d.get("theme_id", ""))
	r.family_id = String(d.get("family_id", ""))
	r.tags = PackedStringArray(d.get("tags", []))
	r.suggested_scale = float(d.get("suggested_scale", 1.0))
	r.part_folders = Dictionary(d.get("part_folders", {}))
	r.part_colors = _colors_from_dict(Dictionary(d.get("part_colors", {})))
	return r

func apply_to(target: Object) -> void:
	if target == null:
		return

	# Apply folders first (textures), then colors (modulate).
	if target.has_method("set_part_folder"):
		for part_name in part_folders.keys():
			target.set_part_folder(String(part_name), String(part_folders[part_name]))

	if target.has_method("set_part_color"):
		for part_name in part_colors.keys():
			target.set_part_color(String(part_name), part_colors[part_name])

	if target.has_method("set_action"):
		# Default action is left up to the target.
		pass


static func _colors_to_dict(colors: Dictionary) -> Dictionary:
	var out := {}
	for k in colors.keys():
		var c: Color = colors[k]
		out[String(k)] = [c.r, c.g, c.b, c.a]
	return out


static func _colors_from_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d.keys():
		var arr_v: Variant = d[k]
		if arr_v is Array and (arr_v as Array).size() >= 4:
			var arr: Array = arr_v as Array
			out[String(k)] = Color(float(arr[0]), float(arr[1]), float(arr[2]), float(arr[3]))
	return out
