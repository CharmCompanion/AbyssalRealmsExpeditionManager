extends RefCounted
class_name RunLog

# Simple append-only JSONL log with a hash chain.
# This is *tamper-evident*, not tamper-proof.

const LOG_PATH := "user://run_log.jsonl"

const _FNV_OFFSET_64 := 1469598103934665603
const _FNV_PRIME_64 := 1099511628211
const _MASK_63 := 0x7fffffffffffffff

static func append(event_type: String, data: Dictionary) -> void:
	append_to(LOG_PATH, event_type, data)

static func append_to(path: String, event_type: String, data: Dictionary) -> void:
	var entry := {
		"t": Time.get_unix_time_from_system(),
		"type": String(event_type),
		"data": data,
	}
	var prev_hash := _read_last_hash_from(path)
	entry["prev_hash"] = prev_hash
	entry["hash"] = _hash_to_hex(_hash_entry(prev_hash, entry))

	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		# Try create.
		file = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return
	else:
		file.seek_end()

	file.store_line(JSON.stringify(entry))
	file.close()


static func log_choice_to(path: String, run_code: String, _seed: int, choice_type: String, payload: Dictionary) -> void:
	# Standard helper for logging player choices / game decisions.
	# Example:
	#   RunLog.log_choice_to(run_log_path, run_code, seed, "recruit", {"unit_id": 12})
	append_to(path, "choice", {
		"run_code": run_code,
		"seed": _seed,
		"choice_type": choice_type,
		"payload": payload,
	})


static func log_generation_to(
	path: String,
	run_code: String,
	_seed: int,
	profile_id: String,
	recipe_dict: Dictionary,
	context: Dictionary = {}
) -> void:
	# Standard helper for logging generation outputs.
	append_to(path, "generation.character_recipe", {
		"run_code": run_code,
		"seed": _seed,
		"profile_id": profile_id,
		"recipe": recipe_dict,
		"context": context,
	})


static func log_generation_batch_to(
	path: String,
	run_code: String,
	_seed: int,
	profile_id: String,
	recipes: Array,
	context: Dictionary = {}
) -> void:
	# Batch version to avoid spamming the log with many lines.
	append_to(path, "generation.batch", {
		"run_code": run_code,
		"seed": _seed,
		"profile_id": profile_id,
		"recipes": recipes,
		"context": context,
	})

static func read_all() -> Array[Dictionary]:
	return read_all_from(LOG_PATH)

static func read_all_from(path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return out
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return out
	while not file.eof_reached():
		var line := file.get_line()
		if String(line).strip_edges() == "":
			continue
		var v: Variant = JSON.parse_string(line)
		if typeof(v) == TYPE_DICTIONARY:
			out.append(v)
	file.close()
	return out

static func verify_chain(entries: Array) -> Dictionary:
	var ok := true
	var bad_index := -1
	var prev := ""
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		var expected_prev := String(e.get("prev_hash", ""))
		if expected_prev != prev:
			ok = false
			bad_index = i
			break
		var stored_hash := String(e.get("hash", ""))
		var computed := _hash_to_hex(_hash_entry(prev, e))
		if stored_hash != computed:
			ok = false
			bad_index = i
			break
		prev = stored_hash
	return {"ok": ok, "bad_index": bad_index, "tail_hash": prev, "count": entries.size()}

static func tail_hash() -> String:
	return _read_last_hash_from(LOG_PATH)

static func tail_hash_from(path: String) -> String:
	return _read_last_hash_from(path)

static func _read_last_hash_from(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var last := ""
	while not file.eof_reached():
		var line := file.get_line()
		if String(line).strip_edges() != "":
			last = line
	file.close()
	if last == "":
		return ""
	var v: Variant = JSON.parse_string(last)
	if typeof(v) == TYPE_DICTIONARY:
		return String((v as Dictionary).get("hash", ""))
	return ""

static func _hash_entry(prev_hash: String, entry: Dictionary) -> int:
	# Hash over (prev_hash + canonical json without hash fields)
	var stripped: Dictionary = entry.duplicate(true)
	stripped.erase("hash")
	var payload: String = String(prev_hash) + "|" + _canonical_json(stripped)
	return _fnv1a64(payload)

static func _canonical_json(v: Variant) -> String:
	var t := typeof(v)
	match t:
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return JSON.stringify(v)
		TYPE_ARRAY:
			var a: Array = v
			var parts: Array[String] = []
			parts.resize(a.size())
			for i in range(a.size()):
				parts[i] = _canonical_json(a[i])
			return "[" + ",".join(parts) + "]"
		TYPE_DICTIONARY:
			var d: Dictionary = v
			var keys: Array = d.keys()
			keys.sort_custom(func(a: Variant, b: Variant) -> bool:
				return str(a) < str(b)
			)
			var kvs: Array[String] = []
			for k in keys:
				kvs.append(JSON.stringify(str(k)) + ":" + _canonical_json(d[k]))
			return "{" + ",".join(kvs) + "}"
		_:
			# Fallback to JSON for other variants (e.g., Vector2) after stringifying.
			return JSON.stringify(str(v))

static func _fnv1a64(text: String) -> int:
	# NOTE: Godot ints are signed 64-bit; using a full 0xffff... mask causes parse/runtime issues.
	# We keep a stable 63-bit FNV-style hash instead (still deterministic + good for tamper-evidence).
	var h: int = _FNV_OFFSET_64
	for i in text.length():
		h = h ^ int(text.unicode_at(i))
		h = int(h * _FNV_PRIME_64) & _MASK_63
	return h

static func _hash_to_hex(h: int) -> String:
	var v: int = int(h) & _MASK_63
	return String.num_int64(v, 16).pad_zeros(16)
