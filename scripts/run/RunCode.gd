extends RefCounted
class_name RunCode

# RunCode is a *replayable*, reversible seed string.
# - It can be pasted into the seed input to restore exact settings.
# - A numeric seed for RNG is derived from the code via a stable hash.

const PREFIX := "ARX1:"

const _FNV_OFFSET_64 := 1469598103934665603
const _FNV_PRIME_64 := 1099511628211
const _MASK_63 := 0x7fffffffffffffff

static func encode(settings: Dictionary) -> String:
	# Keep keys stable-ish by not pretty-printing.
	var json := JSON.stringify(settings)
	var b64 := Marshalls.utf8_to_base64(json)
	return PREFIX + b64

static func decode(code: String) -> Dictionary:
	var text := String(code).strip_edges()
	if not text.begins_with(PREFIX):
		return {}
	var b64 := text.substr(PREFIX.length())
	var json := Marshalls.base64_to_utf8(b64)
	var v: Variant = JSON.parse_string(json)
	if typeof(v) == TYPE_DICTIONARY:
		return v
	return {}

static func is_run_code(text: String) -> bool:
	return String(text).strip_edges().begins_with(PREFIX)

static func seed_from_code(code: String) -> int:
	# Stable 31-bit positive seed derived from the entire code.
	var h := _hash_to_u64(String(code))
	return int(h & 0x7fffffff)

static func _hash_to_u64(text: String) -> int:
	# Stable 63-bit hash (avoids unsigned 64-bit constants that break strict parsing).
	var h: int = _FNV_OFFSET_64
	for i in text.length():
		h = h ^ int(text.unicode_at(i))
		h = int(h * _FNV_PRIME_64) & _MASK_63
	return h
