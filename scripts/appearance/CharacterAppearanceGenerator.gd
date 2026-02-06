extends RefCounted
class_name CharacterAppearanceGenerator

const Recipe = preload("res://scripts/appearance/CharacterAppearanceRecipe.gd")
const Catalog = preload("res://scripts/appearance/CharacterAppearanceCatalog.gd")
const Profiles = preload("res://scripts/appearance/CharacterAppearanceProfiles.gd")
const KingdomThemeResolverUtil = preload("res://scripts/appearance/KingdomThemeResolver.gd")

const _MASK_63: int = 0x7fffffffffffffff

# Simple dungeon theme definition (weights + palette hints).
class DungeonTheme:
	var id: String
	var tag: String
	var accessory_weights: Dictionary # part_name -> float
	var hue_range: Vector2 = Vector2(0.0, 1.0) # 0..1
	var sat_range: Vector2 = Vector2(0.15, 0.9)
	var val_range: Vector2 = Vector2(0.25, 1.0)

	func _init(theme_id: String) -> void:
		id = theme_id
		tag = theme_id
		accessory_weights = {}

var spritesheets_root: String

func _init(root_path: String) -> void:
	spritesheets_root = root_path

func generate(
	profile_id: String,
	_seed: int,
	opts: Dictionary = {}
) -> CharacterAppearanceRecipe:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_seed)

	var recipe := Recipe.new()
	recipe.rng_seed = int(_seed)
	recipe.profile_id = profile_id
	var theme_id := String(opts.get("theme_id", ""))
	if theme_id == "" and opts.has("kingdom_id"):
		theme_id = KingdomThemeResolverUtil.theme_id_for_kingdom(int(opts.get("kingdom_id", 0)))
	recipe.theme_id = theme_id
	recipe.family_id = String(opts.get("family_id", ""))
	var group_id := String(opts.get("group_id", ""))

	var catalog := Catalog.new(spritesheets_root)
	var parts := Profiles.allowed_parts(profile_id)

	var is_evil := bool(opts.get("evil", false))
	var is_kid := bool(opts.get("kid", false))
	if is_evil:
		recipe.tags.append("evil")
	if is_kid:
		recipe.tags.append("kid")
		recipe.suggested_scale = float(opts.get("kid_scale", 0.85))

	var theme := _resolve_theme(recipe.theme_id)
	if theme != null and theme.id != "":
		recipe.tags.append("theme:%s" % theme.id)

	# Family resemblance: create a stable family seed that nudges body + palette.
	var family_seed := 0
	if recipe.family_id != "":
		family_seed = int(_hash_to_u64(recipe.family_id) & 0x7fffffff)
	var family_rng := RandomNumberGenerator.new()
	family_rng.seed = family_seed if family_seed != 0 else rng.seed

	# Group coherence (e.g., dungeon/faction cluster): use it to keep a set of
	# enemies looking related without being literal "family".
	var group_seed := 0
	if group_id != "":
		group_seed = int(_hash_to_u64(group_id) & 0x7fffffff)
	var group_rng := RandomNumberGenerator.new()
	group_rng.seed = group_seed if group_seed != 0 else rng.seed

	var family_strength := clampf(float(opts.get("family_strength", 0.70)), 0.0, 1.0)
	if is_kid:
		family_strength = maxf(family_strength, 0.85)

	# 1) Pick base palette.
	var skin := _pick_skin_tone(family_rng, theme)
	recipe.part_colors["Body"] = skin

	# 2) Pick folders per part.
	for part_name in parts:
		var part := String(part_name)
		var prefix := Profiles.prefix_for_part(part)
		if prefix == "":
			continue

		# Handle evil adventurers occasionally getting Wings/Effect.
		if profile_id == Profiles.PROFILE_ADVENTURER and (part == "Wings" or part == "Effect"):
			# Normally not in allowed_parts for adventurer, but keep the hook if you add them later.
			continue

		var allow_none := Profiles.allow_none_for_part(part, profile_id)
		var folders := catalog.list_folders(prefix, true)
		if folders.is_empty():
			continue

		var chosen := ""
		if allow_none and _roll_none_chance(part, profile_id, is_kid, rng):
			chosen = ""
		else:
			var use_family := (recipe.family_id != "" and rng.randf() < family_strength)
			var pick_rng := family_rng if use_family else rng
			chosen = _pick_weighted_folder(folders, pick_rng)

		recipe.part_folders[part] = chosen

	# 3) Accessories for adventurers/enemies (extra logic beyond allowed_parts()).
	if profile_id == Profiles.PROFILE_ADVENTURER:
		_apply_adventurer_extras(recipe, catalog, rng, theme, is_kid, is_evil)
	elif profile_id == Profiles.PROFILE_ENEMY:
		_apply_enemy_extras(recipe, catalog, rng, theme, is_kid)

	# 4) Colors for clothing/accessories derived from palette.
	# Use group_rng for dungeon/faction cohesion when provided.
	var palette_rng := group_rng if group_id != "" else rng
	_apply_colors(recipe, palette_rng, theme)

	# Kid simplification: fewer layers/accessories.
	if is_kid:
		_simplify_for_kid(recipe, rng)

	return recipe

func _apply_adventurer_extras(recipe: CharacterAppearanceRecipe, catalog: CharacterAppearanceCatalog, rng: RandomNumberGenerator, theme: DungeonTheme, is_kid: bool, is_evil: bool) -> void:
	# Allowed accessories except mounts.
	_maybe_set_part(recipe, catalog, rng, "Bag", 0.65)
	_maybe_set_part(recipe, catalog, rng, "Shield", 0.35)
	_maybe_set_part(recipe, catalog, rng, "Melee", 0.55)
	_maybe_set_part(recipe, catalog, rng, "Ranged", 0.30)
	_maybe_set_part(recipe, catalog, rng, "Magic", 0.25)

	# Evil adventurers sometimes get wings/effects.
	if is_evil and not is_kid:
		_maybe_set_part(recipe, catalog, rng, "Wings", 0.25, theme)
		_maybe_set_part(recipe, catalog, rng, "Effect", 0.20, theme)

func _apply_enemy_extras(recipe: CharacterAppearanceRecipe, catalog: CharacterAppearanceCatalog, rng: RandomNumberGenerator, theme: DungeonTheme, is_kid: bool) -> void:
	# Enemies can have everything, but theme weights can push certain parts.
	_maybe_set_part(recipe, catalog, rng, "Wings", _theme_weight(theme, "Wings", 0.35), theme)
	_maybe_set_part(recipe, catalog, rng, "Effect", _theme_weight(theme, "Effect", 0.45), theme)
	_maybe_set_part(recipe, catalog, rng, "Magic", _theme_weight(theme, "Magic", 0.40), theme)
	_maybe_set_part(recipe, catalog, rng, "Melee", _theme_weight(theme, "Melee", 0.55), theme)
	_maybe_set_part(recipe, catalog, rng, "Ranged", _theme_weight(theme, "Ranged", 0.35), theme)
	_maybe_set_part(recipe, catalog, rng, "Shield", _theme_weight(theme, "Shield", 0.25), theme)
	_maybe_set_part(recipe, catalog, rng, "Bag", _theme_weight(theme, "Bag", 0.15), theme)
	# Mounts are allowed but should be rarer.
	if not is_kid:
		_maybe_set_part(recipe, catalog, rng, "Mount", _theme_weight(theme, "Mount", 0.10), theme)

func _maybe_set_part(recipe: CharacterAppearanceRecipe, catalog: CharacterAppearanceCatalog, rng: RandomNumberGenerator, part_name: String, chance: float, _theme: DungeonTheme = null) -> void:
	if rng.randf() > clampf(chance, 0.0, 1.0):
		recipe.part_folders[part_name] = ""
		return
	var prefix := Profiles.prefix_for_part(part_name)
	if prefix == "":
		recipe.part_folders[part_name] = ""
		return
	var folders := catalog.list_folders(prefix, true)
	if folders.is_empty():
		recipe.part_folders[part_name] = ""
		return
	recipe.part_folders[part_name] = _pick_weighted_folder(folders, rng)

func _theme_weight(theme: DungeonTheme, part_name: String, default_value: float) -> float:
	if theme == null:
		return default_value
	return float(theme.accessory_weights.get(part_name, default_value))

func _apply_colors(recipe: CharacterAppearanceRecipe, rng: RandomNumberGenerator, theme: DungeonTheme) -> void:
	# Body already has skin tone. For everything else, pick from a cohesive palette.
	var base_hsv := _pick_palette_hsv(rng, theme)
	for part_name in recipe.part_folders.keys():
		var part := String(part_name)
		if part == "Body":
			continue
		# Skip coloring if the part isn't present.
		if String(recipe.part_folders[part]) == "":
			continue
		recipe.part_colors[part] = _jitter_hsv(base_hsv, rng)

func _simplify_for_kid(recipe: CharacterAppearanceRecipe, rng: RandomNumberGenerator) -> void:
	# Kids: keep them simpler by clearing high-impact extras.
	for part in ["Effect", "Wings", "Mount"]:
		if recipe.part_folders.has(part):
			recipe.part_folders[part] = ""
			recipe.part_colors.erase(part)
	# Reduce weapons frequency if present.
	if recipe.part_folders.has("Melee") and rng.randf() < 0.6:
		recipe.part_folders["Melee"] = ""
	if recipe.part_folders.has("Ranged") and rng.randf() < 0.75:
		recipe.part_folders["Ranged"] = ""

func _roll_none_chance(part_name: String, profile_id: String, is_kid: bool, rng: RandomNumberGenerator) -> bool:
	# Tune per part. (Body typically required.)
	if part_name == "Body":
		return false
	var base := 0.10
	match profile_id:
		Profiles.PROFILE_CIVILIAN:
			base = 0.18
		Profiles.PROFILE_ADVENTURER:
			base = 0.10
		Profiles.PROFILE_ENEMY:
			base = 0.05
	if is_kid:
		base += 0.12
	# Hands/Head more often present.
	if part_name == "Head":
		base -= 0.05
	return rng.randf() < clampf(base, 0.0, 0.85)

func _pick_weighted_folder(folders: Array[String], rng: RandomNumberGenerator) -> String:
	# For now: uniform among available folders.
	# Extension point: weight by suffix number or tag.
	return String(folders[rng.randi_range(0, folders.size() - 1)])

func _pick_skin_tone(rng: RandomNumberGenerator, theme: DungeonTheme) -> Color:
	# Softly constrained skin tones. Theme can shift toward pale/dark.
	var h := 0.07 + rng.randf_range(-0.02, 0.02)
	var s := rng.randf_range(0.20, 0.55)
	var v := rng.randf_range(0.55, 0.95)
	if theme != null and theme.id == "undead":
		v = rng.randf_range(0.55, 0.80)
		s = rng.randf_range(0.05, 0.25)
		# slightly green/blue
		h = rng.randf_range(0.32, 0.62)
	return Color.from_hsv(h, s, v, 1.0)

func _pick_palette_hsv(rng: RandomNumberGenerator, theme: DungeonTheme) -> Vector3:
	var hmin := 0.0
	var hmax := 1.0
	var smin := 0.15
	var smax := 0.9
	var vmin := 0.25
	var vmax := 1.0
	if theme != null:
		hmin = theme.hue_range.x
		hmax = theme.hue_range.y
		smin = theme.sat_range.x
		smax = theme.sat_range.y
		vmin = theme.val_range.x
		vmax = theme.val_range.y
	var h := rng.randf_range(hmin, hmax)
	var s := rng.randf_range(smin, smax)
	var v := rng.randf_range(vmin, vmax)
	return Vector3(h, s, v)

func _jitter_hsv(base: Vector3, rng: RandomNumberGenerator) -> Color:
	var h := fposmod(base.x + rng.randf_range(-0.03, 0.03), 1.0)
	var s := clampf(base.y + rng.randf_range(-0.15, 0.15), 0.05, 1.0)
	var v := clampf(base.z + rng.randf_range(-0.12, 0.12), 0.10, 1.0)
	var a := clampf(1.0 + rng.randf_range(-0.05, 0.0), 0.75, 1.0)
	return Color.from_hsv(h, s, v, a)

func _resolve_theme(theme_id: String) -> DungeonTheme:
	var id := String(theme_id).strip_edges().to_lower()
	if id == "":
		return null

	match id:
		"coastal":
			var tc := DungeonTheme.new("coastal")
			tc.hue_range = Vector2(0.48, 0.68) # teal/blue
			tc.sat_range = Vector2(0.20, 0.70)
			tc.val_range = Vector2(0.35, 1.0)
			return tc
		"wetlands":
			var tw := DungeonTheme.new("wetlands")
			tw.hue_range = Vector2(0.22, 0.45) # green
			tw.sat_range = Vector2(0.15, 0.75)
			tw.val_range = Vector2(0.25, 0.95)
			return tw
		"plains":
			var tp := DungeonTheme.new("plains")
			tp.hue_range = Vector2(0.10, 0.22) # wheat/yellow-green
			tp.sat_range = Vector2(0.12, 0.55)
			tp.val_range = Vector2(0.45, 1.0)
			return tp
		"forest":
			var tf := DungeonTheme.new("forest")
			tf.hue_range = Vector2(0.24, 0.40)
			tf.sat_range = Vector2(0.18, 0.70)
			tf.val_range = Vector2(0.20, 0.90)
			return tf
		"tundra":
			var tt := DungeonTheme.new("tundra")
			tt.hue_range = Vector2(0.52, 0.72) # icy blues
			tt.sat_range = Vector2(0.05, 0.35)
			tt.val_range = Vector2(0.55, 1.0)
			return tt
		"desert":
			var td := DungeonTheme.new("desert")
			td.hue_range = Vector2(0.07, 0.16) # sand/amber
			td.sat_range = Vector2(0.12, 0.65)
			td.val_range = Vector2(0.55, 1.0)
			return td
		"undead":
			var t := DungeonTheme.new("undead")
			t.hue_range = Vector2(0.33, 0.65)
			t.sat_range = Vector2(0.05, 0.35)
			t.val_range = Vector2(0.35, 0.85)
			t.accessory_weights = {"Effect": 0.70, "Magic": 0.55, "Wings": 0.15}
			return t
		"inferno":
			var t2 := DungeonTheme.new("inferno")
			t2.hue_range = Vector2(0.0, 0.12)
			t2.sat_range = Vector2(0.35, 0.95)
			t2.val_range = Vector2(0.35, 1.0)
			t2.accessory_weights = {"Effect": 0.65, "Magic": 0.50, "Wings": 0.35}
			return t2
		"cultist":
			var t3 := DungeonTheme.new("cultist")
			t3.hue_range = Vector2(0.66, 0.92)
			t3.sat_range = Vector2(0.25, 0.85)
			t3.val_range = Vector2(0.20, 0.75)
			t3.accessory_weights = {"Magic": 0.65, "Effect": 0.40, "Wings": 0.20}
			return t3
		_:
			return DungeonTheme.new(id)

func _hash_to_u64(text: String) -> int:
	# Deterministic hash (simple FNV-1a 64-bit).
	var h: int = 1469598103934665603
	for i in text.length():
		h = h ^ int(text.unicode_at(i))
		# Keep this in signed 64-bit range (Godot uses signed ints).
		h = int((h * 1099511628211) & _MASK_63)
	return h
