import random
from web_game.game_data import seed_from_code

_FNV_OFFSET_64 = 1469598103934665603
_FNV_PRIME_64 = 1099511628211
_MASK_63 = 0x7FFFFFFFFFFFFFFF


def _seed_for(base_seed, tag):
    return seed_from_code("seed:" + str(base_seed) + "|" + tag)


class SimClock:
    seconds_per_day = 30.0

    def __init__(self):
        self.day = 0
        self._accum = 0.0

    def set_day(self, new_day):
        self.day = max(0, int(new_day))

    def tick(self, delta):
        self._accum += max(0.0, delta)
        step = max(0.1, self.seconds_per_day)
        advanced = []
        while self._accum >= step:
            self._accum -= step
            self.day += 1
            advanced.append(self.day)
        return advanced


class DungeonThreatSystem:
    dungeons_per_kingdom = 3
    min_distance_days = 2
    max_distance_days = 10
    raid_warning_days = 2

    THEME_POOL = ["abyssal", "undead", "fungal", "bandits", "ruins"]

    def __init__(self, base_seed=0, extra_dungeon_spawn_chance=0.0):
        self.base_seed = base_seed
        self.extra_dungeon_spawn_chance = extra_dungeon_spawn_chance

    def generate_initial_sites(self, kingdom_id):
        rng = random.Random(_seed_for(self.base_seed, "dungeons|kingdom:%d" % kingdom_id))
        theme_pool = list(self.THEME_POOL)
        sites = []
        count = max(0, self.dungeons_per_kingdom)
        for i in range(count):
            site_id = "k%d_site_%d" % (kingdom_id, i)
            theme_id = theme_pool[rng.randint(0, len(theme_pool) - 1)]
            distance_days = rng.randint(self.min_distance_days, self.max_distance_days)
            growth = rng.uniform(1.0, 3.5)
            threat0 = rng.uniform(5.0, 18.0)
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
        return sites

    def on_day(self, day, sites):
        raids = []
        for i in range(len(sites)):
            s = sites[i]
            threat = float(s.get("threat", 0.0))
            growth = float(s.get("growth", 0.0))
            threat = min(200.0, threat + growth)
            s["threat"] = threat

            if threat >= 100.0 and s.get("state", "") != "breached":
                s["state"] = "breached"
                distance_days = int(s.get("distance_days", 5))
                arrival_day = day + max(1, distance_days)
                raid_count = max(5, int(round(threat / 6.0)))
                raid = {
                    "site_id": s.get("site_id", ""),
                    "theme_id": s.get("theme_id", ""),
                    "scheduled_day": day,
                    "arrival_day": arrival_day,
                    "warning_day": max(0, arrival_day - self.raid_warning_days),
                    "enemy_count": raid_count,
                    "resolved": False,
                }
                raids.append(raid)
                s["threat"] = 60.0

            sites[i] = s

        self._maybe_spawn_extra_site(day, sites)
        return raids

    def _maybe_spawn_extra_site(self, day, sites):
        p = max(0.0, min(1.0, self.extra_dungeon_spawn_chance))
        if p <= 0.0:
            return
        rng = random.Random(_seed_for(self.base_seed, "dungeons.extra|day:%d" % day))
        if rng.random() > p:
            return
        kingdom_id = sites[0]["kingdom_id"] if sites else 1
        site_id = "k%d_extra_%d" % (kingdom_id, day)
        theme_pool = list(self.THEME_POOL)
        theme_id = theme_pool[rng.randint(0, len(theme_pool) - 1)]
        distance_days = rng.randint(self.min_distance_days, self.max_distance_days)
        growth = rng.uniform(1.5, 4.0)
        threat0 = rng.uniform(10.0, 25.0)
        sites.append({
            "site_id": site_id,
            "kingdom_id": kingdom_id,
            "theme_id": theme_id,
            "distance_days": distance_days,
            "threat": threat0,
            "growth": growth,
            "state": "stable",
            "spawn_day": day,
        })

    def apply_threat_delta(self, sites, site_id, delta):
        for i in range(len(sites)):
            s = sites[i]
            if s.get("site_id", "") != site_id:
                continue
            before = float(s.get("threat", 0.0))
            after = max(0.0, min(200.0, before + float(delta)))
            s["threat"] = after
            sites[i] = s
            return


class ExpeditionBoard:
    jobs_per_board = 4
    board_refresh_days = 3

    def __init__(self, base_seed=0):
        self.base_seed = base_seed
        self.current_board_day = -999999

    def generate_board(self, day, sites, town_state):
        rng = random.Random(_seed_for(self.base_seed, "jobs|day:%d" % day))
        out = []

        sorted_sites = sorted(sites, key=lambda s: float(s.get("threat", 0.0)), reverse=True)

        if len(sorted_sites) > 0:
            out.append(self._make_job("clear", sorted_sites[0], rng, day))

        if len(sorted_sites) > 1:
            out.append(self._make_job("scout", sorted_sites[1], rng, day))

        out.append(self._make_town_need_job(town_state, rng, day))

        if len(sorted_sites) > 0 and len(out) < self.jobs_per_board:
            out.append(self._make_job("seal", sorted_sites[rng.randint(0, len(sorted_sites) - 1)], rng, day))

        while len(out) > max(1, self.jobs_per_board):
            out.pop()

        return out

    def _make_job(self, job_type, site, rng, current_day):
        threat = float(site.get("threat", 0.0))
        distance = int(site.get("distance_days", 5))
        risk = max(0.05, min(0.95, (threat / 100.0) * 0.75 + (distance / 20.0) * 0.25))
        duration = max(2, distance * 2 + rng.randint(1, 4))
        reward_hints = {
            "clear": "reduce threat + loot",
            "scout": "intel + small loot",
            "seal": "big threat reduction (risky)",
        }
        return {
            "job_id": "%s_%s_%d" % (job_type, site.get("site_id", "site"), current_day),
            "job_type": job_type,
            "site_id": site.get("site_id", ""),
            "theme_id": site.get("theme_id", ""),
            "distance_days": distance,
            "risk": risk,
            "duration_days": duration,
            "reward_hint": reward_hints.get(job_type, "mixed"),
        }

    def _make_town_need_job(self, town_state, rng, current_day):
        food = int(town_state.get("food", 0))
        gold = int(town_state.get("gold", 0))
        pop = int(town_state.get("population", 0))
        need = "supplies"
        if food < max(25, pop * 2):
            need = "gather_food"
        elif gold < 100:
            need = "recover_relics"
        return {
            "job_id": "%s_%d" % (need, current_day),
            "job_type": need,
            "risk": rng.uniform(0.05, 0.25),
            "duration_days": rng.randint(2, 6),
            "reward_hint": "stabilize town",
        }


class AutonomousExpeditions:
    expedition_interval_days = 2

    def __init__(self, base_seed=0):
        self.base_seed = base_seed
        self.last_depart_day = -999999
        self.active = {}

    def on_day(self, day, jobs, dungeons, town_state):
        if self.active and day >= int(self.active.get("return_day", 999999)):
            report = self._resolve_active(day, dungeons, town_state)
            self.active = {}
            return {"type": "report", "data": report}

        if self.active:
            return None

        if not jobs:
            return None

        if day - self.last_depart_day < max(1, self.expedition_interval_days):
            return None

        job = jobs[0]
        return self._start(day, job)

    def _start(self, day, job):
        rng = random.Random(_seed_for(self.base_seed, "expedition.start|day:%d|job:%s" % (day, job.get("job_id", ""))))
        party_size = rng.randint(3, 5)
        duration = int(job.get("duration_days", rng.randint(2, 6)))
        return_day = day + max(1, duration)

        self.active = {
            "job": job,
            "depart_day": day,
            "return_day": return_day,
            "party_size": party_size,
        }
        self.last_depart_day = day

        return {
            "type": "depart",
            "data": {
                "day": day,
                "return_day": return_day,
                "job": job,
                "party_size": party_size,
            },
        }

    def _resolve_active(self, current_day, dungeons, town_state):
        job = dict(self.active.get("job", {}))
        depart_day = int(self.active.get("depart_day", current_day))
        return_day = int(self.active.get("return_day", current_day))
        days_away = max(1, return_day - depart_day)
        party_size = int(self.active.get("party_size", 4))

        rng = random.Random(_seed_for(self.base_seed, "expedition.resolve|return_day:%d|job:%s" % (current_day, job.get("job_id", ""))))

        risk = float(job.get("risk", 0.15))
        success_chance = max(0.05, min(0.95, 1.0 - risk * 0.75))
        success = rng.random() <= success_chance

        deaths = 0
        injuries = 0
        if success:
            injuries = 1 if rng.random() < (risk * 0.35) else 0
        else:
            deaths = 1 if rng.random() < max(0.05, min(0.75, risk * 0.7)) else 0
            injuries = 1 if rng.random() < max(0.10, min(0.90, risk * 0.9)) else 0

        deaths = min(deaths, max(0, party_size - 1))
        injuries = min(injuries, max(0, party_size - deaths))

        loot = {"gold": 0, "food": 0, "wood": 0, "stone": 0, "ore": 0}
        threat_delta = 0.0
        site_id = job.get("site_id", "")
        job_type = job.get("job_type", "")

        if success:
            if job_type == "clear":
                loot["gold"] = rng.randint(20, 80)
                threat_delta = -rng.uniform(18.0, 45.0)
            elif job_type == "seal":
                loot["gold"] = rng.randint(30, 120)
                threat_delta = -rng.uniform(35.0, 80.0)
            elif job_type == "scout":
                loot["gold"] = rng.randint(10, 40)
                threat_delta = -rng.uniform(5.0, 15.0)
            elif job_type == "gather_food":
                loot["food"] = rng.randint(15, 60)
            elif job_type == "recover_relics":
                loot["gold"] = rng.randint(25, 100)
            else:
                loot["gold"] = rng.randint(10, 60)
        else:
            if rng.random() < 0.25:
                loot["gold"] = rng.randint(5, 15)

        if site_id and abs(threat_delta) > 0.001 and dungeons is not None:
            dungeons.apply_threat_delta(dungeons._sites_ref if hasattr(dungeons, '_sites_ref') else [], site_id, threat_delta)

        return {
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
        }
