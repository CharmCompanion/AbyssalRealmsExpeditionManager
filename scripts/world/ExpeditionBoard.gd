extends Node
class_name ExpeditionBoard

const RunCodeUtil = preload("res://scripts/run/RunCode.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")

# Generates a rotating set of jobs/contracts based on current dungeon threats and town needs.
# No UI here: callers can display jobs however they like.

@export var jobs_per_board: int = 4
@export var board_refresh_days: int = 3

var run_code: String = ""
var run_log_path: String = ""
var base_seed: int = 0

var current_day: int = 0
var current_board_day: int = -999999
var jobs: Array[Dictionary] = []

func setup(p_run_code: String, p_run_log_path: String, p_base_seed: int) -> void:
	run_code = String(p_run_code)
	run_log_path = String(p_run_log_path)
	base_seed = int(p_base_seed)

func on_day(day: int, sites: Array[Dictionary], town_state: Dictionary) -> void:
	current_day = int(day)
	if current_day - current_board_day < maxi(1, board_refresh_days):
		return
	current_board_day = current_day
	jobs = _generate_board(current_day, sites, town_state)
	_log("jobs.board", {"run_code": run_code, "seed": base_seed, "day": current_day, "jobs": jobs})

func _seed_for(tag: String) -> int:
	if run_code.strip_edges() != "":
		return RunCodeUtil.seed_from_code(run_code + "|" + tag)
	return RunCodeUtil.seed_from_code("seed:" + str(base_seed) + "|" + tag)

func _generate_board(day: int, sites: Array[Dictionary], town_state: Dictionary) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for("jobs|day:%d" % day)

	var out: Array[Dictionary] = []
	var sorted_sites := sites.duplicate(true)
	sorted_sites.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("threat", 0.0)) > float(b.get("threat", 0.0))
	)

	# 1) Always include a "clear" style job for the top threat dungeon if any.
	if sorted_sites.size() > 0:
		out.append(_make_job("clear", sorted_sites[0], rng))

	# 2) Include a scout job for another site if present.
	if sorted_sites.size() > 1:
		out.append(_make_job("scout", sorted_sites[1], rng))

	# 3) Town-need job (based on low resources).
	out.append(_make_town_need_job(town_state, rng))

	# 4) Wildcard.
	if sorted_sites.size() > 0 and out.size() < jobs_per_board:
		out.append(_make_job("seal", sorted_sites[rng.randi_range(0, sorted_sites.size() - 1)], rng))

	# Trim/pad.
	while out.size() > maxi(1, jobs_per_board):
		out.pop_back()
	return out

func _make_job(job_type: String, site: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var threat := float(site.get("threat", 0.0))
	var distance := int(site.get("distance_days", 5))
	var risk := clampf((threat / 100.0) * 0.75 + (distance / 20.0) * 0.25, 0.05, 0.95)
	var duration := maxi(2, distance * 2 + rng.randi_range(1, 4))
	return {
		"job_id": "%s_%s_%d" % [job_type, String(site.get("site_id", "site")), current_day],
		"job_type": job_type,
		"site_id": String(site.get("site_id", "")),
		"theme_id": String(site.get("theme_id", "")),
		"distance_days": distance,
		"risk": risk,
		"duration_days": duration,
		"reward_hint": _reward_hint(job_type, threat),
	}

func _make_town_need_job(town_state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var food := int(town_state.get("food", 0))
	var gold := int(town_state.get("gold", 0))
	var pop := int(town_state.get("population", 0))
	var need := "supplies"
	if food < max(25, pop * 2):
		need = "gather_food"
	elif gold < 100:
		need = "recover_relics"
	return {
		"job_id": "%s_%d" % [need, current_day],
		"job_type": need,
		"risk": rng.randf_range(0.05, 0.25),
		"duration_days": rng.randi_range(2, 6),
		"reward_hint": "stabilize town",
	}

func _reward_hint(job_type: String, _threat: float) -> String:
	match job_type:
		"clear":
			return "reduce threat + loot"
		"scout":
			return "intel + small loot"
		"seal":
			return "big threat reduction (risky)"
		_:
			return "mixed"

func _log(event_type: String, payload: Dictionary) -> void:
	if run_log_path.strip_edges() == "":
		return
	RunLogUtil.append_to(run_log_path, event_type, payload)
