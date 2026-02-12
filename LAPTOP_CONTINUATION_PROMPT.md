# LAPTOP CONTINUATION — ISO TILESETS + OVERWORLD PAINTING + PROCGEN DIRECTION
**Project:** Abyssal Realms Expedition Manager
**Session Date:** Feb 11, 2026
**Status:** Ground painting fixed ✅ | Wall sorting fixed ✅ | Wall paint-under-mouse still being tuned ⚠️ | Overworld exploration prototype added ✅

---

## ✅ What we did this session

### 0) Core fix: iso TileSet selection/painting
- Root cause was PNGs (often 256×256) being treated like multi-cell atlases → “4 squares” selection + wrong snapping.
- Added/iterated an editor script that tightens atlas selection and removes stray atlas coords:
  - [tools/tighten_iso_tileset_selection.gd](tools/tighten_iso_tileset_selection.gd)
- Ground painting now behaves correctly (pixel-tight selection, no stray atlas coords).

### 1) Sorting/overlap improvements
- Enabled Y-sort on the iso layers that needed correct overlap.
- Overworld test scene updates:
  - GroundLayer: `y_sort_enabled = true`
  - WallLayer: `y_sort_enabled = true` and `x_draw_order_reversed = true` (iso tie-break fix)

### 2) Overworld exploration prototype (player + camera + ground streaming)
- Scene: [scenes/world/overworld/OverworldTest.tscn](scenes/world/overworld/OverworldTest.tscn)
- Added a simple `Player` (CharacterBody2D) + `Camera2D` follow.
- Added an exploration controller that inherits the building placement script and streams ground tiles around the player:
  - [scripts/world/OverworldExploreController.gd](scripts/world/OverworldExploreController.gd)
  - Note: project treats warnings as errors → avoid Variant-inference patterns (`min()`, `max()` without explicit typing).

### 3) Mouse-to-tile placement fixes (runtime)
- Fixed incorrect coordinate conversion: `TileMapLayer.local_to_map()` needs layer-local coords.
- Added an iso cursor offset knob (still being tuned):
  - [scripts/world/BuildingPlacement.gd](scripts/world/BuildingPlacement.gd)

### 4) Addon noise/warnings cleanup
- Fixed WFC addon warning: removed duplicate scene UID from one demo scene:
  - [addons/wfc/examples/demo_wfc_2d_tilemap.tscn](addons/wfc/examples/demo_wfc_2d_tilemap.tscn)

### 5) Procgen direction (agreed intent)
- Goal: no hand-made maps; deterministic seeded world; persistent main town saved; expeditions/quests can generate temporary overlays.
- Recommended structure:
  - Base world terrain = deterministic (noise + biome rules) per world seed.
  - POIs (towns/dungeons/routes) = deterministic placement per world seed + stored persistent discoveries.
  - Expedition overlay = generated per expedition seed (can change per quest/run), optionally “committed” to save.

---

## ✅ Current files touched (high-signal)
- [tools/tighten_iso_tileset_selection.gd](tools/tighten_iso_tileset_selection.gd)
- [scripts/world/BuildingPlacement.gd](scripts/world/BuildingPlacement.gd)
- [scripts/world/OverworldExploreController.gd](scripts/world/OverworldExploreController.gd)
- [scripts/world/OverworldPlayer.gd](scripts/world/OverworldPlayer.gd)
- [scenes/world/overworld/OverworldTest.tscn](scenes/world/overworld/OverworldTest.tscn)
- [assets/tilesets/fantasy_iso/Fantasy_Ground.tres](assets/tilesets/fantasy_iso/Fantasy_Ground.tres)
- [assets/tilesets/fantasy_iso/Fantasy_Wall.tres](assets/tilesets/fantasy_iso/Fantasy_Wall.tres)
- [addons/wfc/examples/demo_wfc_2d_tilemap.tscn](addons/wfc/examples/demo_wfc_2d_tilemap.tscn)

---

## ⚠️ Known issues / things to verify
1) **Wall paint-under-mouse still off in editor**
  - Walls must keep a consistent origin to avoid gaps; cursor alignment needs to be solved via preview/placement logic, not per-tile origin.
2) **Warnings-as-errors**
  - Avoid Variant-inferred locals (e.g. `var x := min(...)`). Use explicit types and simple clamps.
3) **Re-run the tileset tightening when resources drift**
  - Run [tools/tighten_iso_tileset_selection.gd](tools/tighten_iso_tileset_selection.gd) to re-save TileSets consistently.

---

## 🔜 What we need to do next

### A) Finish wall cursor alignment (without gaps)
- Add a “paint preview” sprite that follows the mouse and snaps to the computed cell (visual confirmation).
- Make the preview use the wall tile’s origin so the user clicks where they see.

### B) Procgen scaffolding (next milestone)
- Define `WorldSeed` + save data schema (persistent POIs vs temporary overlays).
- Implement chunk generator:
  - deterministic ground/biomes per chunk
  - deterministic POI placement per chunk
  - expedition overlay generation per expedition/quest

### C) Optional: use Voronoi/Delaunay for macro layout
- Voronoi cells = regions/kingdoms/biomes.
- Delaunay edges = roads/expedition routes graph.

---

## 📌 Plan going forward (short)
1) Lock down tile painting UX (especially walls) so authoring + testing is fast.
2) Implement deterministic chunked overworld base layer (noise/biomes).
3) Add POI placement + persistence (main town always saved).
4) Add expedition overlays (change per quest/run, optionally commit discoveries).

---

## 🧪 Quick test checklist
- Open OverworldTest, confirm:
  - Ground painting selects only visible pixels (no “4 squares”)
  - Walls Y-sort correctly (no corner behind)
  - No UID duplicate warnings
  - No script parse errors from warnings-as-errors

---

**STATUS:** Ground painting + sorting stable; wall paint-under-mouse still needs a clean UX fix.  
**NEXT MILESTONE:** Deterministic chunked overworld + POI persistence.