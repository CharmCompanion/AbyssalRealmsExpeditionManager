extends Node
class_name AppearanceService

# A thin wrapper around the generator + background queue.
# Intended to be added as an Autoload later, or instantiated by a world manager.

@export var spritesheets_root := "res://imported/Map and Character/Stand-alone Character creator - 2D Fantasy V1-0-3 (1)/Character creator - 2D Fantasy_Data/StreamingAssets/spritesheets"
@export var per_frame_budget := 10

signal recipe_generated(recipe)
signal batch_complete(request_id: int, recipes: Array)

const Profiles = preload("res://scripts/appearance/CharacterAppearanceProfiles.gd")
const Generator = preload("res://scripts/appearance/CharacterAppearanceGenerator.gd")
const Queue = preload("res://scripts/appearance/CharacterGenerationQueue.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")

var _generator: CharacterAppearanceGenerator
var _queue: CharacterGenerationQueue

var _batch_log_meta: Dictionary = {} # request_id -> {log_path, run_code, seed, profile_id, context}

func _ready() -> void:
	_generator = Generator.new(spritesheets_root)

	_queue = Queue.new()
	_queue.spritesheets_root = spritesheets_root
	_queue.per_frame_budget = per_frame_budget
	add_child(_queue)

	_queue.recipe_generated.connect(func(recipe) -> void:
		recipe_generated.emit(recipe)
	)
	_queue.batch_complete.connect(func(request_id: int, recipes: Array) -> void:
		# Optional log for this batch.
		if _batch_log_meta.has(request_id):
			var meta: Dictionary = _batch_log_meta.get(request_id, {})
			_batch_log_meta.erase(request_id)
			var log_path := String(meta.get("log_path", ""))
			if log_path != "":
				var out: Array = []
				for r in recipes:
					if r != null and (r as Object).has_method("to_dict"):
						out.append((r as Object).call("to_dict"))
				RunLogUtil.log_generation_batch_to(
					log_path,
					String(meta.get("run_code", "")),
					int(meta.get("seed", 0)),
					String(meta.get("profile_id", "")),
					out,
					Dictionary(meta.get("context", {}))
				)
		batch_complete.emit(request_id, recipes)
	)

func generate_one(profile_id: String, _seed: int, opts: Dictionary = {}) -> Resource:
	# Synchronous generation.
	return _generator.generate(profile_id, _seed, opts)

func generate_one_logged(profile_id: String, _seed: int, opts: Dictionary, log_path: String, run_code: String, context: Dictionary = {}) -> Resource:
	var recipe: Resource = generate_one(profile_id, _seed, opts)
	if log_path != "" and recipe != null and (recipe as Object).has_method("to_dict"):
		RunLogUtil.log_generation_to(log_path, run_code, _seed, profile_id, (recipe as Object).call("to_dict"), context)
	return recipe

func request_batch(count: int, profile_id: String, _seed: int, opts: Dictionary = {}) -> int:
	return _queue.request_batch(count, profile_id, _seed, opts)

func request_batch_logged(count: int, profile_id: String, _seed: int, opts: Dictionary, log_path: String, run_code: String, context: Dictionary = {}) -> int:
	var request_id := request_batch(count, profile_id, _seed, opts)
	if log_path != "":
		_batch_log_meta[request_id] = {
			"log_path": log_path,
			"run_code": run_code,
			"seed": _seed,
			"profile_id": profile_id,
			"context": context,
		}
	return request_id


func generate_civilian_population(count: int, _seed: int, opts: Dictionary = {}) -> Dictionary:
	# Generates a mix of family civilians and single civilians.
	# Returns:
	#  {
	#    "recipes": Array[CharacterAppearanceRecipe],
	#    "family_index": Dictionary (family_id -> Array[int] indices),
	#    "meta": Dictionary
	#  }
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_seed)

	var family_fraction := clampf(float(opts.get("family_fraction", 0.55)), 0.0, 1.0)
	var min_family_size := maxi(2, int(opts.get("min_family_size", 2)))
	var max_family_size := maxi(min_family_size, int(opts.get("max_family_size", 5)))
	var family_strength := clampf(float(opts.get("family_strength", 0.70)), 0.0, 1.0)
	var kid_chance := clampf(float(opts.get("kid_chance", 0.22)), 0.0, 1.0)
	var kid_scale := clampf(float(opts.get("kid_scale", 0.85)), 0.5, 1.0)

	var target_family_members := int(round(count * family_fraction))
	# If we don't have room for at least one family, make all singles.
	if target_family_members < 2:
		target_family_members = 0

	# Build family size list deterministically.
	var family_sizes: Array[int] = []
	var remaining := target_family_members
	while remaining >= 2:
		var sz := rng.randi_range(min_family_size, max_family_size)
		sz = mini(sz, remaining)
		if sz < 2:
			break
		family_sizes.append(sz)
		remaining -= sz

	# Prepare individual slots.
	var recipes: Array = []
	recipes.resize(maxi(0, count))
	var family_index: Dictionary = {}

	# Fill family members first.
	var cursor := 0
	var kingdom_id := int(opts.get("kingdom_id", 0))
	var group_id_base := String(opts.get("group_id", ""))
	if group_id_base == "":
		group_id_base = "pop|%d|kingdom:%d" % [_seed, kingdom_id]

	for fi in range(family_sizes.size()):
		var fid := "%s|fam:%d" % [group_id_base, fi]
		family_index[fid] = []
		for j in range(family_sizes[fi]):
			if cursor >= count:
				break
			var item_seed := int(_seed) + cursor * 7919
			var o := opts.duplicate(true)
			o["family_id"] = fid
			o["family_strength"] = family_strength
			o["group_id"] = group_id_base
			# Kids: keep at least 1-2 adults per family, then roll kid chance.
			var make_kid := false
			if j >= 2 and rng.randf() < kid_chance:
				make_kid = true
			elif j == 1 and family_sizes[fi] >= 4 and rng.randf() < (kid_chance * 0.5):
				# Occasionally allow 1 kid earlier in bigger families.
				make_kid = true
			o["kid"] = make_kid
			if make_kid:
				o["kid_scale"] = kid_scale
			var r := _generator.generate(Profiles.PROFILE_CIVILIAN, item_seed, o)
			recipes[cursor] = r
			(family_index[fid] as Array).append(cursor)
			cursor += 1

	# Fill the rest as singles.
	while cursor < count:
		var item_seed2 := int(_seed) + cursor * 7919
		var o2 := opts.duplicate(true)
		o2.erase("family_id")
		o2.erase("family_strength")
		o2.erase("kid")
		o2.erase("kid_scale")
		o2["group_id"] = group_id_base
		recipes[cursor] = _generator.generate(Profiles.PROFILE_CIVILIAN, item_seed2, o2)
		cursor += 1

	return {
		"recipes": recipes,
		"family_index": family_index,
		"meta": {
			"count": count,
			"seed": seed,
			"family_fraction": family_fraction,
			"family_members_target": target_family_members,
			"family_count": family_sizes.size(),
			"kid_chance": kid_chance,
			"kid_scale": kid_scale,
			"group_id": group_id_base,
			"kingdom_id": kingdom_id,
		}
	}

func apply_recipe_to_rig(recipe: Resource, rig: Object) -> void:
	if recipe == null or rig == null:
		return
	if recipe.has_method("apply_to"):
		recipe.apply_to(rig)

# Convenience constants for callers.
func civilian_id() -> String:
	return Profiles.PROFILE_CIVILIAN

func adventurer_id() -> String:
	return Profiles.PROFILE_ADVENTURER

func enemy_id() -> String:
	return Profiles.PROFILE_ENEMY
