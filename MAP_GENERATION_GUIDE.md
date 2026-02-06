# Map Generation Guide (Fantasy Tileset - 2D Isometric)

This project already has deterministic generation (RunCode/seed). The goal is: **biome + kingdom + run seed** → generate a believable isometric map region, then carve/flatten a town area and populate it.

## 1) Use the pack correctly in Godot (Isometric TileMap)

1. Import the pack assets into `assets/` (don’t move them after Godot creates `.import` files).
2. Create a `TileSet` resource from the pack textures.
3. Create a `TileMap` node and set:
   - `tile_set` to your TileSet
   - `tile_map` orientation/layout to **Isometric** (Godot 4 TileMap supports isometric layouts)
4. Prefer multiple TileMap layers (or multiple TileMaps) for readability:
   - `Ground` (base terrain)
   - `Cliffs/Edges` (optional)
   - `Nature` (trees/rocks)
   - `Props` (small items)
   - `Roads` (optional)

## 2) Determinism: seed derivation

Pick a single integer seed per region:
- `region_seed = hash(run_code + ":region:" + kingdom_id + ":" + biome_id + ":" + region_index)`

Then use sub-seeds for passes so results are stable even if you add new passes later:
- `seed_ground = hash(region_seed + ":ground")`
- `seed_town = hash(region_seed + ":town")`
- `seed_decor = hash(region_seed + ":decor")`

(Where `hash()` is your existing safe signed hashing style.)

## 3) Generation pipeline (recommended)

### Pass A — Base terrain (biome-driven)
Goal: generate believable ground tile distribution.

Simple MVP approach (looks good fast):
1. Generate two noise maps (e.g. FastNoiseLite):
   - `height` in 0..1
   - `moisture` in 0..1
2. Convert to ground tile types via biome rules:
   - **Forest:** mostly grass + occasional dirt patches
   - **Plains:** grass + more dirt patches
   - **Desert:** sand + cracked sand + rare scrub
   - **Tundra:** snow + packed snow + exposed rock
   - **Coastal/Wetlands:** grass + mud + shallow water pockets
3. Paint the `Ground` layer.

MVP rule example:
- `if height < waterline` → water/shallow water tile
- else `if moisture > 0.7` → lush grass
- else `if moisture > 0.4` → grass
- else → dirt/sand/rock depending on biome

### Pass B — Choose and flatten the town area
Goal: a flat, readable buildable region.

1. Pick a town center (biased toward mid-height, away from water).
2. Define a town radius (e.g. 12–18 tiles).
3. Override the ground tiles inside the radius to a “flat base” tile (packed dirt / cobble / grass).
4. Create 2–4 wider “roads” leaving town center toward edges or toward a dungeon site direction.

This pass is what makes the map feel like a place (and supports your free-build/demolish gameplay).

### Pass C — Nature/rocks decoration (believability pass)
Goal: scatter props with constraints.

Use weighted placement with rejection rules:
- Never place trees/rocks on roads.
- Avoid placing props too close to town center.
- Cluster in a natural way using another noise map or Poisson-ish spacing.

Per-biome prop bias examples:
- Forest: lots of trees, some stumps, few rocks
- Mountains: many rocks, sparse trees
- Plains: few trees, more bushes
- Desert: rocks + scrub, rare trees near oasis

### Pass D — Points of interest (POIs)
- Dungeon entrances (match your dungeon sites)
- Ruins, shrines, camps

Deterministic placement rule:
- each POI gets `poi_seed = hash(region_seed + ":poi:" + poi_id)`

## 4) Practical “tile registry” mapping (avoid hard-coded tile IDs)

Don’t hardcode numeric tile IDs in many places.

Instead, keep a small scriptable mapping:
- `BiomeToTiles.gd` / dictionary:
  - `ground_grass`, `ground_dirt`, `ground_sand`, `water_shallow`, `road`, `rock_small`, `tree_1`...

Then generation code uses semantic keys.

## 5) How this ties into your existing systems

- **Kingdom** selects the biome pair + palette bias (already present in CreateTown).
- **RunCode** defines region seed and therefore:
  - which patches, which trees, which rock clusters
  - where flat town area is
  - where POIs are
- **RunLog** can record “region generated” entries with summary (counts and the chosen center).

## 6) MVP checklist (smallest thing that looks good)

1. One isometric TileMap with Ground tiles.
2. A deterministic flattened town circle.
3. A road cross (N/E/S/W).
4. 2 prop types per biome (trees + rocks).

Once that’s solid, expand with cliffs, rivers, and themed POIs.
