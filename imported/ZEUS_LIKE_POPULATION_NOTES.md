# Zeus-like Population + Housing Notes (Implementation-Oriented)

This file is a *design translation* of publicly available references (HeavenGames game-info pages) plus a high-level synthesis of patterns from the Zeus strategy guide.

Goal: make a city sim loop that *feels* like Zeus/Prometheus (housing-driven population growth, service-driven evolution), while staying compatible with our deterministic RunCode + appearance generation system.

## Core ideas to copy (the *feel*, not the exact UI)

- Population is primarily constrained by **housing capacity**.
- Housing evolves/devolves based on **services + goods + desirability/appeal**.
- The player’s build order creates a natural progression: huts → shacks → … → townhouses; elite housing comes later.
- “Problems” (no food, no water, unemployment, high taxes, etc.) create unhappy citizens and can cascade.

## Housing levels (summary)

HeavenGames lists common and elite housing levels with:
- occupants per house level
- required services/goods per level
- per-house consumption rates for certain goods (food per occupant; some goods per house per time)

We should model housing levels as data:
- `capacity`
- `requirements` (boolean flags or numeric thresholds)
- `consumption` (per-house and/or per-occupant)
- `evolve_thresholds` / `devolve_thresholds` (appeal + service score)

## Recommended simulation objects

- `Household`
  - `id`
  - `home_id`
  - `members: Array[CitizenId]`
  - `family_id` (optional; empty means “single/small unrelated”)
  - `wealth_tier` (common/elite)

- `Citizen`
  - `id`
  - `household_id`
  - `age` or `is_kid`
  - `job_id` (optional)
  - `appearance_recipe` (CharacterAppearanceRecipe)

- `Home` (the building/lot)
  - `id`
  - `housing_level`
  - `capacity`
  - `required_goods/services` (evaluated from city state)
  - `appeal` / `desirability`

## How this maps to our existing appearance generator

We already support:
- deterministic generation from a numeric seed
- `family_id` + `family_strength` for resemblance
- `group_id` for neighborhood/faction coherence
- `kid=true` + `kid_scale` for children

So a Zeus-like housing system just needs to decide:
- how many citizens exist
- which citizens are in the same household
- which citizens are in families vs singles

Then call generation:
- use one `group_id` per neighborhood/block (keeps palette coherent)
- assign `family_id` per household for family resemblance

## A practical starting loop (MVP)

1) Compute total housing capacity from placed homes.
2) If capacity > population and unemployment is not terrible, add immigrants:
   - create a new `Household`
   - decide family size
   - generate members’ appearances using shared `family_id`
3) If capacity < population, mark overflow as homeless/unhappy (later: move out/depopulate).
4) Each tick, evaluate homes:
   - if requirements met → evolve level gradually
   - if requirements not met → devolve level gradually

## Expeditions + Dungeons (Zeus-like *feel*, Abyssal Realms theme)

Zeus/Pharaoh-style games usually have **walkers + services + housing evolution** as the core loop.
For Abyssal Realms, you can keep that *city loop* intact and add a second loop that feels like
"external threats" and "city requests" without turning the game into an RTS.

Key principle: **Adventurers are a city resource**, like workers, not a directly-controlled squad.

### Recommended model

- Town continues to grow primarily through housing/services.
- Dungeons are world nodes with a **Threat** meter.
- Threat rises over time; if ignored it triggers **Raid Events** (monsters leaking out).
- The player responds by funding/supplying **Expeditions** (asynchronous jobs), not micromanaging combat.

### Why this keeps the Zeus vibe

- The player still focuses on city layout, logistics, and stability.
- "Send an expedition" is like a policy/investment decision.
- Outcomes feed back into city systems (casualties → morale, loot → gold/materials, injuries → healer load).

### What to generate (procedurally)

- `DungeonSite`: location, theme, threat curve, possible loot tables, raid patterns.
- `ExpeditionJob`: target site, duration, risk, required supplies, expected reward ranges.
- `OutcomeReport`: deterministic narrative + stats (days, deaths, injuries, loot, discoveries).

All of the above should be derivable from RunCode + time/tick index so they are replayable and loggable.

## Notes

This is intentionally implementation-oriented and does not reproduce full tables verbatim.
