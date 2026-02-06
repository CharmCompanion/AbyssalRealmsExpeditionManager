extends Node
class_name DungeonThreatSystem

const RunCodeUtil = preload("res://scripts/run/RunCode.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")
const KingdomThemeResolverUtil = preload("res://scripts/appearance/KingdomThemeResolver.gd")

# Pure logic system (no UI). Manages a set of dungeon sites that accumulate threat.
# When threat overflows, a breach schedules a raid event.

signal raid_warning(raid: Dictionary)
signal raid_arrival(raid: Dictionary)

@export var dungeons_per_kingdom: int = 3
@export var extra_dungeon_spawn_chance_per_day: float = 0.0
@export var min_distance_days: int = 2
@export var max_distance_days: int = 10
@export var raid_warning_days: int = 2

var run_code: String = ""
var run_log_path: String = ""
var base_seed: int = 0
var kingdom_id: int = 0

var sites: Array[Dictionary] = []
var raids: Array[Dictionary] = []

func setup(p_run_code: String, p_run_log_path: String, p_base_seed: int, p_kingdom_id: int) -> void:
	run_code = String(p_run_code)
	run_log_path = String(p_run_log_path)
	base_seed = int(p_base_seed)
	kingdom_id = int(p_kingdom_id)
	_generate_initial_sites()

func on_day(day: int) -> void:
	_update_sites(day)
	_maybe_spawn_extra_site(day)


func apply_threat_delta(site_id: String, delta: float, context: Dictionary = {}) -> void:
	# Used by other systems (e.g., expeditions) to reduce or increase threat deterministically.
	var sid := String(site_id)
	for i in range(sites.size()):
		var s: Dictionary = sites[i]
		if String(s.get("site_id", "")) != sid:
			continue
		var before := float(s.get("threat", 0.0))
		var after := clampf(before + float(delta), 0.0, 200.0)
		s["threat"] = after
		sites[i] = s
		_log("dungeon.threat_change", {
			"run_code": run_code,
			"seed": base_seed,
			"site_id": sid,
			"before": before,
			"delta": float(delta),
			"after": after,
			"context": context,
		})
		return

func _seed_for(tag: String) -> int:
	if run_code.strip_edges() != "":
		return RunCodeUtil.seed_from_code(run_code + "|" + tag)
	return RunCodeUtil.seed_from_code("seed:" + str(base_seed) + "|" + tag)

func _generate_initial_sites() -> void:
	sites.clear()
	raids.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for("dungeons|kingdom:%d" % kingdom_id)

	var base_theme := KingdomThemeResolverUtil.theme_id_for_kingdom(kingdom_id)
	var theme_pool := [base_theme, "abyssal", "undead", "fungal", "bandits", "ruins"]

	var count := maxi(0, dungeons_per_kingdom)
	for i in range(count):
		var site_id := "k%d_site_%d" % [kingdom_id, i]
		var theme_id := String(theme_pool[rng.randi_range(0, theme_pool.size() - 1)])
		var distance_days := rng.randi_range(min_distance_days, max_distance_days)
		var growth := rng.randf_range(1.0, 3.5)
		var threat0 := rng.randf_range(5.0, 18.0)
		sites.append({
			"site_id": site_id,
			"kingdom_id": kingdom_id,
			"theme_id": theme_id,
			"distance_days": distance_days,
			"threat": threat0,
			"growth": growth,
			"state": "stable",
			"spawn_day": 0,
		})

	_log("dungeon.init", {"run_code": run_code, "seed": base_seed, "kingdom_id": kingdom_id, "sites": sites})

func _update_sites(day: int) -> void:
	for i in range(sites.size()):
		var s := sites[i]
		var threat := float(s.get("threat", 0.0))
		var growth := float(s.get("growth", 0.0))
		threat = minf(200.0, threat + growth)
		s["threat"] = threat

		if threat >= 100.0 and String(s.get("state", "")) != "breached":
			s["state"] = "breached"
			var distance_days := int(s.get("distance_days", 5))
			var arrival_day := day + maxi(1, distance_days)
			var raid_count := maxi(5, int(round(threat / 6.0)))
			var raid := {
				"site_id": String(s.get("site_id", "")),
				"theme_id": String(s.get("theme_id", "")),
				"scheduled_day": day,
				"arrival_day": arrival_day,
				"warning_day": maxi(0, arrival_day - raid_warning_days),
				"enemy_count": raid_count,
				"resolved": false,
			}
			raids.append(raid)
			_log("dungeon.breach", {"run_code": run_code, "seed": base_seed, "day": day, "site": s, "raid": raid})

			# Cool down after breach.
			s["threat"] = 60.0

		sites[i] = s

	# Emit raid warnings and arrivals (as logs only for now).
	for r_i in range(raids.size()):
		var r := raids[r_i]
		if bool(r.get("resolved", false)):
			continue
		var warning_day := int(r.get("warning_day", -1))
		var arrival_day := int(r.get("arrival_day", -1))
		if warning_day == day:
			_log("raid.warning", {"run_code": run_code, "seed": base_seed, "day": day, "raid": r})
			raid_warning.emit(r)
		if arrival_day == day:
			_log("raid.arrival", {"run_code": run_code, "seed": base_seed, "day": day, "raid": r})
			raid_arrival.emit(r)
			# Mark as unresolved; actual combat/damage can be implemented later.
		r_i += 1

func _maybe_spawn_extra_site(day: int) -> void:
	var p := clampf(extra_dungeon_spawn_chance_per_day, 0.0, 1.0)
	if p <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for("dungeons.extra|day:%d|kingdom:%d" % [day, kingdom_id])
	if rng.randf() > p:
		return

	var site_id := "k%d_extra_%d" % [kingdom_id, day]
	var base_theme := KingdomThemeResolverUtil.theme_id_for_kingdom(kingdom_id)
	var theme_pool := [base_theme, "abyssal", "undead", "fungal", "ruins"]
	var theme_id := String(theme_pool[rng.randi_range(0, theme_pool.size() - 1)])
	var distance_days := rng.randi_range(min_distance_days, max_distance_days)
	var growth := rng.randf_range(1.5, 4.0)
	var threat0 := rng.randf_range(10.0, 25.0)
	var s := {
		"site_id": site_id,
		"kingdom_id": kingdom_id,
		"theme_id": theme_id,
		"distance_days": distance_days,
		"threat": threat0,
		"growth": growth,
		"state": "stable",
		"spawn_day": day,
	}
	sites.append(s)
	_log("dungeon.spawn", {"run_code": run_code, "seed": base_seed, "day": day, "site": s})

func _log(event_type: String, payload: Dictionary) -> void:
	if run_log_path.strip_edges() == "":
		return
	RunLogUtil.append_to(run_log_path, event_type, payload)
