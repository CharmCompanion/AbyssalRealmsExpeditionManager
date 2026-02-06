# AI addon integration notes (LimboAI + GdPlanningAI)

## Goal
- Use **GdPlanningAI (GOAP)** for **civilians + in-town adventurers** (life sim: needs, jobs, routines).
- Use **LimboAI (BT/HSM)** for **enemies** and **adventurers while on expeditions/quests** (tactics + danger).

This project currently keeps AI addons **optional** so the game still runs even if the addons are not installed.

## Install locations
### GdPlanningAI
- Asset: https://godotengine.org/asset-library/asset/4156
- IMPORTANT: Install into `res://addons/GdPlanningAI` (the author notes the asset library may try to install at project root).

### LimboAI
- Install into `res://addons/limboai` (typical).

## Adapter layer (safe without addons)
Files:
- scripts/ai/AIAddons.gd
- scripts/ai/town/CivilianPlannerGOAP.gd
- scripts/ai/enemy/EnemyBrainLimbo.gd

These files:
- detect addon presence by folder (`res://addons/...`) to avoid hard dependencies
- do not reference addon classes directly (prevents parse errors if the addon is missing)
- provide stubs + logging hooks so we can wire real planners/BT runners later

## Next wiring steps (when addons are installed)
1) Confirm folders exist:
   - `res://addons/GdPlanningAI`
   - `res://addons/limboai`
2) Find each addon’s runtime API:
   - how to instantiate a planner (GOAP)
   - how to tick/run a behavior tree / HSM (LimboAI)
3) Replace stubs:
   - `CivilianPlannerGOAP.choose_goal()` should call GOAP planner and return `{goal, plan}`
   - `EnemyBrainLimbo.ensure_started()` + `tick()` should construct the Limbo runner and tick it (time-sliced)
4) Keep determinism:
   - seed AI randomness using RunCode-derived seeds (no `Randomize()` in brains)
   - log key decisions with RunLog (`ai.*` events)

## Performance guidance (many agents)
- Don’t tick every agent every frame.
- Use time-slicing (update a subset each frame) + distance-based LOD.
- Prefer event-driven decisions (signals) over polling.
