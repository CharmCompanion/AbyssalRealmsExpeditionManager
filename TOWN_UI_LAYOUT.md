# Town UI Layout (Menu-Driven + Inspectable World)

Target feel: **Zeus-style management** with a **free camera map**. The map stays visible; UI panels slide/overlay on top using the existing book/panel style.

## Screen structure

### A) Top bar (always visible)
Contents:
- Lord portrait + name
- Town name
- Resource counters for: Gold, Food, Wood, Stone, Ore/Iron (+ any later resources)
- Delta indicators: `+X/day` / `-X/day` (computed from active buildings + policies + events)

Implementation notes:
- Keep it deterministic: deltas are derived from systems, not random.
- Clicking a resource can open the relevant panel (optional later).

### B) Left tab column (always visible)
A vertical tab list that switches which overlay panel is shown.

Suggested tabs (MVP):
- Build
- Bank/Inventory (town stockpile)
- Guild
- Academy
- Temple
- Expeditions
- Settings/Dev

Each tab shows **one** panel overlay on top of the map (reuse the same UI frame style from MainMenu/SaveSelect/CreateTown).

### C) Map (full remaining screen)
- Free camera pan/zoom
- Click buildings/NPCs

## Building interaction (click-to-inspect)

When the player clicks a building on the map:
1. Highlight the building (outline/modulate/selection marker).
2. Show a small tooltip near the building with:
   - Building name
   - Level / upgrade tier
   - Key output summary (e.g. “+3 Food/day”) and status (idle/working)
3. The main management happens in the left-tab panels.

Rule: clicking does NOT open a new separate screen; it only changes what the overlay panel shows (e.g. select Temple tab + focus that building instance).

## Building systems: mechanics first, AI as consumers

Your buildings should be deterministic subsystems that update daily; AI (GOAP) calls them.

### Bank (town inventory)
- Stores all resources: Gold, Stone, Food, etc.
- Used by building costs, upgrades, and expedition supply.
- Panel: stockpile view + daily change breakdown + pending costs.

### Guild (inn + adventurer guild + shop)
- Recruitment pool, party roster, rank ladder: F→E→D→C→B→A→S→SS→SSS→SSSS
- Slow gains: rank progression is a long-term loop (Dark Souls + Oregon Trail pacing).
- Shop inventory: supplies + gear, with restock on day tick.
- Panel: contracts/expeditions + shop + roster + rank progress.

### Academy
- Training tracks:
  - melee skills/talents/levels
  - magic skills/talents/levels
- Research upgrades
- Identify items via alchemy
- Panel: training slots + research queue + identification queue.

### Temple
- Blessings and god mechanics (Zeus-like): choose an active rite + unlockable miracles.
- Panel: rites, favor costs, cooldowns, town buffs.

### Housing progression (Lord/civilians)
- Lord: Cottage → Estate → Lord House
- Civilians: Cottage; promoted nobles: Estate
- Panel: housing counts, upgrades, population capacity effects.

## Future systems (placeholders)
- Farming and monster breeding can be added as new tabs/panels once assets exist.
- Keep the APIs stable: `advance_day(day)` and `get_daily_deltas()` so the top bar stays consistent.
