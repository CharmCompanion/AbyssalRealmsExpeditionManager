# Expedition System Notes (Autonomous, Zeus-like City-Builder)

You want a Zeus-style city builder as the core, with autonomous adventurers that you fund/launch and then read reports for.
This document proposes a system that keeps the city loop intact while adding *infinite*, non-repeating expedition/quest content.

## The decision: Expeditions vs Quests vs Static Dungeons

### Recommendation: combine both (but keep one underlying system)

- **Dungeons** are persistent world nodes with a theme and a threat meter.
- **Expeditions** are the action you take against a dungeon (asynchronous simulation).
- **Quests** are *generated expedition jobs* that point at a dungeon *or* are town-driven requests (deliver/recover/scout).

In other words:
- “Quest” is the *contract/job*.
- “Expedition” is the *process* that resolves the contract.
- “Dungeon” is one (common) *target type*.

This avoids splitting your design into two separate systems.

## Keep the Zeus feel

Zeus is mostly about:
- housing/services driving growth
- solving city problems caused by shortages, unemployment, unrest

So adventurers should behave like:
- a *service* the town can support (through guilds, training, supplies)
- a *pressure valve* for external threats (dungeons rising in threat)

The player choices stay in the Zeus space:
- build/upgrade guild infrastructure
- manage supplies and funding
- pick which contracts to accept and how aggressive to be

## Spatial concern: “dungeon close to town breaks expeditions”

You can solve this without micromanagement by separating:
- **world distance** (affects duration)
- **threat proximity** (affects raid severity)

Model:
- Dungeons exist in a world list with an abstract “distance days” value.
- A dungeon can have an increasing “influence” over time.
- When influence crosses thresholds, it causes raids/pressure on the town.

So the dungeon can be “far away” (expeditions make sense) but still become “dangerous” (raids happen as *events*).

## Core data structures (engine-agnostic)

### DungeonSite
- `site_id`
- `theme_id` (abyssal, undead, fungal, etc.)
- `distance_days` (travel time)
- `threat` (0..1 or 0..100)
- `threat_growth_rate`
- `last_expedition_result` (optional)
- `loot_profile` (what kinds of rewards it yields)

### Contract / QuestJob
- `job_id`
- `job_type` ("clear", "scout", "rescue", "gather", "escort", "seal")
- `target_site_id` (optional)
- `requirements` (gold, food, tools, etc. — map to your game’s resources)
- `risk` and `expected_duration_days`
- `reward_profile`

### ExpeditionRun
- `run_id`
- `job_id`
- `party` (adventurer ids)
- `depart_day`, `return_day`
- `sim_seed` (derived deterministically)

### OutcomeReport
- `days_traveled`, `days_in_dungeon`
- `deaths`, `injuries`, `status_effects`
- `loot` (items/resources)
- `discoveries` (unlocks, new site modifiers, lore)

## Infinite scaling + “never similar” content (practical approach)

To avoid repetition, don’t try to generate handcrafted quests.
Instead generate:
- a stable set of **situation variables** (town shortages, dungeon threat state, deity modifiers)
- a stable set of **job templates** (scout/clear/rescue/etc.)
- and then a deterministic **parameterization** (distance, risk, rewards, special modifiers)

Example: Each month (or each N days) you roll a “job board”:
- 1–2 dungeon jobs (based on highest threat)
- 1 town need job (based on lowest resource)
- 1 wild-card job (based on deity/kingdom flavor)

Everything is derived from `RunCode.seed_from_code(run_code)` plus the current day index, so it’s replayable.

## How this ties into your existing deterministic + logging work

### Deterministic seeds
- Use RunCode-derived `current_seed` as the base.
- Derive subsystem seeds by namespacing:
  - `seed_jobs = seed_from_code(run_code + "|jobs|day:" + str(day))`
  - `seed_site = seed_from_code(run_code + "|site:" + site_id)`
  - `seed_expedition = seed_from_code(run_code + "|expedition:" + run_id)`

### What to log (anti-cheat + debugging)
Use the log helpers we added:
- `RunLog.log_choice_to(run_log_path, run_code, seed, "accept_job", {...})`
- `RunLog.append_to(run_log_path, "expedition.depart", {...})`
- `RunLog.append_to(run_log_path, "expedition.return", {...})`
- `RunLog.log_generation_to(...)` for generated job boards / dungeon sites

This gives you “pre-run settings” and “post-run decisions + outcomes” with tamper-evident chaining.

## Resource mapping (since you don’t have oil/horses)

Zeus housing needs goods like food/water/fleece/oil/wine/armor/horses.
In Abyssal Realms, map those *roles* to your existing economy:
- **Food** stays Food.
- **Water** becomes a general “Amenities/Sanitation” service, or keep Water if you want.
- **Fleece/Cloth** maps to “Cloth” or “Textiles” (or “Wood” early if you want fewer resources).
- **Oil/Wine** maps to “Luxuries” (a single abstract luxury resource).
- **Armor/Horses** maps to “Equipment” (crafted) and “Training” (service).

The point is: higher housing tiers demand *more* categories, not those exact items.

## Two clarifying choices (only if you want me to implement next)

1) Do you want raids to be purely event-driven (numbers + damage), or will you place visible monsters on the town map?
2) How fast is a “day” in your sim (real-time minutes, turns, or only when player clicks “end day”)?
