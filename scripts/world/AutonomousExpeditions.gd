extends Node
class_name AutonomousExpeditions

const RunCodeUtil = preload("res://scripts/run/RunCode.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")

signal expedition_departed(info: Dictionary)
signal expedition_report(report: Dictionary)

@export var expedition_interval_days: int = 2

# Future hook: if you later want adventurers to be simulated by an AI system
# (e.g., LimboAI controlling tactical decisions), you can flip this and route
# resolve to a dedicated encounter simulator.
@export var use_agent_ai: bool = false

var run_code: String = ""
var run_log_path: String = ""
var base_seed: int = 0

var current_day: int = 0
var last_depart_day: int = -999999
var active: Dictionary = {} # {job, depart_day, return_day, party_size}

func setup(p_run_code: String, p_run_log_path: String, p_base_seed: int) -> void:
	run_code = String(p_run_code)
	run_log_path = String(p_run_log_path)
	base_seed = int(p_base_seed)

func on_day(day: int, jobs: Array[Dictionary], dungeons: Node, town_state: Dictionary) -> void:
	current_day = int(day)
	# Resolve return first.
	if not active.is_empty() and current_day >= int(active.get("return_day", 999999)):
		var report := _resolve_active(dungeons, town_state)
		active.clear()
		expedition_report.emit(report)
		return

	# Otherwise maybe depart.
	if not active.is_empty():
		return
	if jobs.is_empty():
		return
	if current_day - last_depart_day < maxi(1, expedition_interval_days):
		return

	# Pick the top job (board is already threat-sorted).
	var job: Dictionary = jobs[0]
	_start(job)

func _seed_for(tag: String) -> int:
	if run_code.strip_edges() != "":
		return RunCodeUtil.seed_from_code(run_code + "|" + tag)
	return RunCodeUtil.seed_from_code("seed:" + str(base_seed) + "|" + tag)

func _start(job: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for("expedition.start|day:%d|job:%s" % [current_day, String(job.get("job_id", ""))])
	var party_size := rng.randi_range(3, 5)
	var duration := int(job.get("duration_days", rng.randi_range(2, 6)))
	var return_day := current_day + maxi(1, duration)

	active = {
		"job": job,
		"depart_day": current_day,
		"return_day": return_day,
		"party_size": party_size,
	}
	last_depart_day = current_day

	var info := {
		"run_code": run_code,
		"seed": base_seed,
		"day": current_day,
		"return_day": return_day,
		"job": job,
		"party_size": party_size,
	}
	_log("expedition.depart", info)
	expedition_departed.emit(info)

func _resolve_active(dungeons: Node, town_state: Dictionary) -> Dictionary:
	# Hook for future AI-driven tactical simulation.
	if use_agent_ai:
		# Not implemented yet; fall back to deterministic abstract simulation.
		pass

	var job: Dictionary = Dictionary(active.get("job", {}))
	var depart_day := int(active.get("depart_day", current_day))
	var return_day := int(active.get("return_day", current_day))
	var days_away := maxi(1, return_day - depart_day)
	var party_size := int(active.get("party_size", 4))

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for("expedition.resolve|return_day:%d|job:%s" % [current_day, String(job.get("job_id", ""))])

	var risk := float(job.get("risk", 0.15))
	var success_chance := clampf(1.0 - risk * 0.75, 0.05, 0.95)
	var success := rng.randf() <= success_chance

	var deaths := 0
	var injuries := 0
	if success:
		injuries = (1 if rng.randf() < (risk * 0.35) else 0)
	else:
		# Failure can be costly.
		deaths = (1 if rng.randf() < clampf(risk * 0.7, 0.05, 0.75) else 0)
		injuries = (1 if rng.randf() < clampf(risk * 0.9, 0.10, 0.90) else 0)

	deaths = mini(deaths, maxi(0, party_size - 1))
	injuries = mini(injuries, maxi(0, party_size - deaths))

	var loot := {
		"gold": 0,
		"food": 0,
		"wood": 0,
		"stone": 0,
		"ore": 0,
	}

	var threat_delta := 0.0
	var site_id := String(job.get("site_id", ""))
	var job_type := String(job.get("job_type", ""))

	if success:
		match job_type:
			"clear":
				loot["gold"] = rng.randi_range(20, 80)
				threat_delta = -rng.randf_range(18.0, 45.0)
			"seal":
				loot["gold"] = rng.randi_range(30, 120)
				threat_delta = -rng.randf_range(35.0, 80.0)
			"scout":
				loot["gold"] = rng.randi_range(10, 40)
				threat_delta = -rng.randf_range(5.0, 15.0)
			"gather_food":
				loot["food"] = rng.randi_range(15, 60)
			"recover_relics":
				loot["gold"] = rng.randi_range(25, 100)
			_:
				loot["gold"] = rng.randi_range(10, 60)
	else:
		# Minor consolation loot sometimes.
		if rng.randf() < 0.25:
			loot["gold"] = rng.randi_range(5, 15)

	if site_id != "" and absf(threat_delta) > 0.001 and dungeons != null and dungeons.has_method("apply_threat_delta"):
		dungeons.call("apply_threat_delta", site_id, threat_delta, {
			"source": "expedition",
			"job_id": String(job.get("job_id", "")),
			"day": current_day,
			"success": success,
		})

	var report := {
		"run_code": run_code,
		"seed": base_seed,
		"depart_day": depart_day,
		"return_day": return_day,
		"days_away": days_away,
		"job": job,
		"party_size": party_size,
		"success": success,
		"deaths": deaths,
		"injuries": injuries,
		"loot": loot,
		"threat_delta": threat_delta,
		"town_snapshot": town_state,
	}
	_log("expedition.report", report)
	return report

func _log(event_type: String, payload: Dictionary) -> void:
	if run_log_path.strip_edges() == "":
		return
	RunLogUtil.append_to(run_log_path, event_type, payload)
