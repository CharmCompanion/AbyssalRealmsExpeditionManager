extends Node
class_name CharacterGenerationQueue

# Generates appearance recipes over multiple frames to avoid stalling.

signal recipe_generated(recipe)
signal batch_complete(request_id: int, recipes: Array)

@export var spritesheets_root := "res://imported/Map and Character/Stand-alone Character creator - 2D Fantasy V1-0-3 (1)/Character creator - 2D Fantasy_Data/StreamingAssets/spritesheets"
@export var per_frame_budget := 10

const Generator = preload("res://scripts/appearance/CharacterAppearanceGenerator.gd")

var _generator: CharacterAppearanceGenerator

var _next_request_id: int = 1
var _queue: Array = []

func _ready() -> void:
	_generator = Generator.new(spritesheets_root)

# Request format:
# {
#   id: int,
#   remaining: int,
#   profile_id: String,
#   seed: int,
#   opts: Dictionary,
#   results: Array
# }
func request_batch(count: int, profile_id: String, _seed: int, opts: Dictionary = {}) -> int:
	var req := {
		"id": _next_request_id,
		"remaining": maxi(0, count),
		"profile_id": profile_id,
		"seed": int(_seed),
		"opts": opts.duplicate(true),
		"results": [],
	}
	_next_request_id += 1
	_queue.append(req)
	set_process(true)
	return int(req.id)

func _process(_delta: float) -> void:
	if _queue.is_empty():
		set_process(false)
		return

	var budget := maxi(1, per_frame_budget)
	while budget > 0 and not _queue.is_empty():
		var req: Dictionary = _queue[0]
		var remaining := int(req.remaining)
		if remaining <= 0:
			_queue.pop_front()
			batch_complete.emit(int(req.id), req.results)
			continue

		# Derive per-item seed deterministically.
		var index := (int(req.results.size()))
		var item_seed := int(req.seed) + index * 7919

		var recipe := _generator.generate(String(req.profile_id), item_seed, req.opts)
		req.results.append(recipe)
		req.remaining = remaining - 1
		_queue[0] = req

		recipe_generated.emit(recipe)
		budget -= 1

	# If the queue emptied, stop processing.
	if _queue.is_empty():
		set_process(false)
