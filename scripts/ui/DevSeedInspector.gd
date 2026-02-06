extends Control

const RunCodeUtil = preload("res://scripts/run/RunCode.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")
const Recipe = preload("res://scripts/appearance/CharacterAppearanceRecipe.gd")

# Hardcoded dev password (for now). Must be exactly 6 chars and include
# at least 1 uppercase letter and 1 special character.
const DEV_PASSWORD := "Ab123!"

@onready var password_input: LineEdit = $Root/PasswordRow/PasswordInput
@onready var btn_unlock: Button = $Root/PasswordRow/Unlock
@onready var password_status: Label = $Root/PasswordStatus

@onready var seed_input: LineEdit = $Root/TopRow/SeedInput
@onready var btn_load_save: Button = $Root/TopRow/LoadSave
@onready var btn_decode: Button = $Root/TopRow/Decode
@onready var btn_copy: Button = $Root/TopRow/Copy
@onready var btn_export: Button = $Root/TopRow/Export
@onready var btn_close: Button = $Root/TopRow/Close
@onready var output: TextEdit = $Root/Output

var _log_path_override: String = ""
var _unlocked: bool = false

func _ready() -> void:
	btn_unlock.pressed.connect(_attempt_unlock)
	password_input.text_submitted.connect(func(_t: String) -> void:
		_attempt_unlock()
	)

	btn_load_save.pressed.connect(_load_from_save)
	btn_decode.pressed.connect(_decode)
	btn_copy.pressed.connect(_copy)
	btn_export.pressed.connect(_export)
	btn_close.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	)

	_set_locked_state(true)

	if seed_input.text.strip_edges() != "":
		# Only auto-decode after unlocking.
		if _unlocked:
			_decode()

func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _set_locked_state(locked: bool) -> void:
	_unlocked = not locked
	if locked:
		password_status.text = "Locked"
		output.text = "(Locked) Enter password to use Seed Inspector."
	else:
		password_status.text = "Unlocked"
		output.text = ""

	seed_input.editable = not locked
	btn_load_save.disabled = locked
	btn_decode.disabled = locked
	btn_copy.disabled = locked
	btn_export.disabled = locked


func _attempt_unlock() -> void:
	var attempt := password_input.text
	var policy := _validate_password_policy(attempt)
	if not policy.ok:
		password_status.text = "Locked: %s" % policy.reason
		return
	if attempt != DEV_PASSWORD:
		password_status.text = "Locked: wrong password"
		return
	_set_locked_state(false)
	if seed_input.text.strip_edges() != "":
		_decode()


func _validate_password_policy(pwd: String) -> Dictionary:
	if pwd.length() != 6:
		return {"ok": false, "reason": "must be 6 chars"}
	var has_upper := false
	var has_special := false
	for i in range(pwd.length()):
		var ch := pwd[i]
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			has_upper = true
		# Special = not a letter or digit
		var is_digit := (code >= 48 and code <= 57)
		var is_upper := (code >= 65 and code <= 90)
		var is_lower := (code >= 97 and code <= 122)
		if not (is_digit or is_upper or is_lower):
			has_special = true
	if not has_upper:
		return {"ok": false, "reason": "needs 1 uppercase"}
	if not has_special:
		return {"ok": false, "reason": "needs 1 special"}
	return {"ok": true, "reason": ""}

func _load_from_save() -> void:
	if not _unlocked:
		password_status.text = "Locked: unlock first"
		return
	var path := "user://savegame.json"
	if not FileAccess.file_exists(path):
		output.text = "No save found at user://savegame.json"
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		output.text = "Failed to open save file"
		return
	var txt := f.get_as_text()
	f.close()
	var v: Variant = JSON.parse_string(txt)
	if typeof(v) != TYPE_DICTIONARY:
		output.text = "Save file is not valid JSON dictionary"
		return
	var d: Dictionary = v
	_log_path_override = String(d.get("run_log_path", "")).strip_edges()
	var rc := String(d.get("run_code", ""))
	if rc == "":
		# Fallback: try numeric seed.
		rc = String(d.get("seed", ""))
	seed_input.text = rc
	_decode()

func _decode() -> void:
	if not _unlocked:
		password_status.text = "Locked: unlock first"
		return
	var text := seed_input.text.strip_edges()
	output.text = _build_report(text)

func _copy() -> void:
	if not _unlocked:
		password_status.text = "Locked: unlock first"
		return
	DisplayServer.clipboard_set(output.text)

func _export() -> void:
	if not _unlocked:
		password_status.text = "Locked: unlock first"
		return
	var stamp := str(Time.get_unix_time_from_system())
	var path := "user://seed_report_%s.txt" % stamp
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(output.text)
	f.close()

func _build_report(seed_text: String) -> String:
	var lines: Array[String] = []
	lines.append("Seed Inspector")
	lines.append("----------------")
	lines.append("Input: %s" % seed_text)
	if _log_path_override != "":
		lines.append("Log path (from save): %s" % _log_path_override)

	var run_code := ""
	var settings: Dictionary = {}
	var derived_seed: int = 0
	if RunCodeUtil.is_run_code(seed_text):
		run_code = seed_text
		settings = RunCodeUtil.decode(run_code)
		lines.append("Type: RunCode")
		derived_seed = RunCodeUtil.seed_from_code(run_code)
		lines.append("Derived numeric seed: %d" % derived_seed)
	else:
		lines.append("Type: raw seed")
		derived_seed = RunCodeUtil.seed_from_code("freeform:" + seed_text)
		lines.append("Derived numeric seed: %d" % derived_seed)

	if not settings.is_empty():
		lines.append("")
		lines.append("Decoded Settings (pre-run)")
		lines.append(JSON.stringify(settings, "\t"))

		# Lord appearance summary if present.
		var la: Dictionary = Dictionary(settings.get("lord_appearance", {}))
		if not la.is_empty():
			var recipe := Recipe.from_dict(la)
			lines.append("")
			lines.append("Lord Appearance")
			lines.append(JSON.stringify(recipe.part_folders, "\t"))

	# Run log (post-run-ish): filter by derived seed if possible.
	lines.append("")
	lines.append("Run Log")
	var log_path := _log_path_override
	if log_path == "":
		log_path = RunLogUtil.LOG_PATH
	var entries := RunLogUtil.read_all_from(log_path)
	var verify := RunLogUtil.verify_chain(entries)
	lines.append("Log chain ok: %s" % str(bool(verify.get("ok", false))))
	if not bool(verify.get("ok", false)):
		lines.append("Chain break at index: %s" % str(verify.get("bad_index", -1)))
	lines.append("Entries: %d" % int(verify.get("count", 0)))
	lines.append("Tail hash: %s" % String(verify.get("tail_hash", "")))
	lines.append("Log file: %s" % log_path)

	var show_entries: Array[Dictionary] = entries
	if run_code != "":
		show_entries = []
		for e in entries:
			var dd: Dictionary = Dictionary((e as Dictionary).get("data", {}))
			if String(dd.get("run_code", "")) == run_code:
				show_entries.append(e)
		lines.append("Entries matching RunCode: %d" % show_entries.size())
	else:
		# Best-effort filter by seed if no RunCode.
		show_entries = []
		for e in entries:
			var dd2: Dictionary = Dictionary((e as Dictionary).get("data", {}))
			if int(dd2.get("seed", -1)) == derived_seed:
				show_entries.append(e)
		lines.append("Entries matching seed: %d" % show_entries.size())

	# Show last 25 entries for quick debugging.
	var start := maxi(0, show_entries.size() - 25)
	for i in range(start, show_entries.size()):
		var e: Dictionary = show_entries[i]
		lines.append("- %s" % JSON.stringify(e))

	return "\n".join(lines)
