Abyssal Realms Expedition Manager — World + Quest System Spec (Godot 2D Iso)
Goal

Build a large isometric 2D world in Godot that:

World geography stays the same every playthrough:

Countries, biomes, coastlines, water

Major settlements/landmarks

Dungeon entrance locations

Each playthrough (“run”) changes:

Player starting biome / starting settlement

Which dungeons are “active”, “dormant”, “breaking”

Generated quests (exterminate, gather, escort, etc.)

Event pressure (bandits, weather patterns, outbreaks, merchant routes)

Navigation has no “walk 493m to marker”:

Players can roam freely.

Quest directions come from rumors/clues and environmental reasoning.

Knowledgeable players can find targets with zero clues if they know the world.

The system supports “unlimited replayability” without repetitive NPC dialogue:

Procedural generation produces facts (structured clues), not infinite freeform dialogue.

NPCs reveal facts using many templates, with anti-repeat + player knowledge tracking.

High-level design: split “world” vs “run”

We use two independent layers:

1) Static World Layer (Persistent)

This defines the canonical map and never changes (unless you manually update it):

Biomes layout from exported SVG/PNGs

Countries/borders layout

Water/coastline mask

Fixed anchor points:

Villages/towns/camps (safe-ish nodes)

Major landmarks (shrines, watchtowers, ruins, bridges, giant trees, etc.)

Dungeon entrances (static world positions)

This layer is generated once (or authored), saved as a data file, and reused forever.

2) Run Layer (Changes each run)

This is generated each time you start a run:

Starting location (in a biome/settlement) based on RUN_SEED

Dungeon run-state:

dormant / active / breaking / sealed / cleared / etc.

Quest board generation:

exterminate / gather / escort / deliver / scout / cleanse / recover

tied to anchors/regions/dungeons

Traveling events: bandits, merchants, patrols, outbreaks

Weather/season start pattern (optional)

Overworld: chunked tile-based isometric

The world is huge, so it must be chunked and streamed.

World grid

Overworld is a tile grid: WORLD_W_TILES x WORLD_H_TILES

One tile = one iso tile from tileset.

Chunking

Chunk size: CHUNK_SIZE = 64 or 128 tiles (recommend start at 64)

Stream around player:

LOAD_RADIUS = 3 chunks (loads a 7x7 area)

Chunk contents

Each chunk scene contains:

TileMap for ground

Optional TileMap for details/props

Optional TileMap for roads/water overlays

Optional Node2D for placed objects/POIs

Chunks generate tiles from biome rules, deterministically.

Map inputs: convert SVG layers to “logic maps”

SVG is for authoring; runtime sampling uses raster maps:

Required maps

Biome ID map (recommended): one PNG where each biome has a unique exact RGB color.

Water mask (optional separate, or encoded as biome=water).

Country ID map (optional) if you want faction borders as logic.

Important: avoid anti-aliasing

Biome/country ID maps must be flat colors with no blended pixels.
If edges are anti-aliased, implement nearest-color matching or re-export cleanly.

Coordinate mapping

Overworld tile coordinate (tx, ty) must map to image pixel (px, py):

Example mapping: world grid and map image share the same aspect ratio

Use uv = (tx / WORLD_W_TILES, ty / WORLD_H_TILES) then pixel sample.

Core systems (spine)

Implement these 5 systems first. Everything else plugs into them.

1) WorldMapSampler (static)

Responsibilities:

Load biome/country/water textures as Image in memory (once).

Provide fast sampling:

get_biome_at_tile(Vector2i tile) -> BiomeId

get_country_at_tile(tile) -> CountryId (optional)

is_water(tile) -> bool

Provide biome transition checks for clue logic.

2) WorldDB (static)

A saved list of all fixed anchors in the world:

Settlements

Landmarks

Dungeons

Stored in JSON or Godot Resource (recommended JSON for debugging).

Example:

data/world/world_db.json

3) ChunkStreamer (runtime)

Responsibilities:

Based on player tile position, determine current chunk.

Load chunk scenes within LOAD_RADIUS

Unload chunks out of range

Chunks request ground tile painting from WorldMapSampler

Chunk generation must be deterministic so the same chunk always looks the same.

4) RunDirector (per-run)

Responsibilities:

Create a new run from RUN_SEED:

choose player start location (biome + nearest settlement)

generate dungeon states (active/dormant/breaking)

generate quest board items

Save run-state to:

data/runs/run_<id>.json or in memory for now.

5) Quest/Rumor Director (per-run)

Responsibilities:

Generate quests from “quest grammar” (objective + target + constraints).

Generate structured clue facts for each quest:

direction band

distance band

landmark reference

hazard warning

route hint

NPCs reveal facts via templates (anti-repeat).

Static anchors: what “fixed” means

Dungeons are fixed entrances with variable run-state.

Dungeon Entrance (static)

Stored in WorldDB:

id

name

tile_position (entrance tile)

biome_id

nearby_landmarks (computed once)

tags (cave/ruins/crypt/mineshaft etc.)

Dungeon Run-State (per run)

Stored in RunDirector save:

dungeon_id

state: dormant | active | breaking | sealed | cleared

pressure: 0..100 (break risk)

content_seed (for dungeon interior generation)

infestation_type / faction / hazard flags

Meaning:

Entrance location stays constant.

“Active” affects:

quest generation frequency

monster presence in surrounding area

risk events near it

“break” countdown / dungeon break mechanics

Quest generation: constraints, not coordinates

A quest does not store “go to exact XY.”
It stores a target (anchor or region constraint) + clue facts.

Quest object (per run)

Fields:

id

type: Exterminate | Gather | Escort | Deliver | Scout | Cleanse | Recover

issuer_settlement_id

target_kind: dungeon | region | npc_route | landmark

target_ref: dungeon_id or region constraints

constraints:

biome allowed

distance band from issuer

near_landmark_tag

near_road or far_from_road (optional)

time_window (optional)

danger_profile (bandits, disease, cold, etc.)

rewards

clue_facts[] (generated separately)

Region constraints

Use map sampler to find valid tiles:

biome must match

not water

(optional) altitude/roughness from height map

within min/max distance from issuer settlement

Pick a “target tile region” and then choose nearby landmarks to support clue-giving.

No waypoint navigation: structured clue network

Players locate targets by interpreting clues.

Clue facts are structured, not freeform text

ClueFact fields:

type: Direction | Distance | Landmark | Hazard | Route | “TooFarIf”

payload:

direction: N/NE/E… or “toward mountains/coast”

distance_band: near / half-day / full-day / multi-day

landmark_id reference: “Broken Bridge”, “Old Watchtower”

hazard: “swamp gas”, “bandit road”, “avalanche”

route: “follow river until fork”

truth_level:

accurate | vague | slightly_wrong | outdated

confidence:

high | medium | low

source_role:

hunter, guard, merchant, herbalist, traveler

NPC dialogue: templates + anti-repeat

NPCs do not invent locations. They reveal clue facts.

Use many templates per clue type:

“Head {direction} until you see {landmark}…”

“If you reach {landmark}, you’ve gone too far…”

“It’s about a {distance_band} from here, give or take…”

Anti-repeat:

track last N templates used per NPC

track what player already knows for quest Q

track “settlement rumor fatigue”

This makes NPC talk feel non-stagnant without needing AI chat.

Knowledgeable players can use zero clues

Because the world geography and dungeon entrances are stable, players can learn:

where “Old Quarry” dungeon is

how to reach it by roads/landmarks

which biome transitions indicate closeness

Clues are optional; they help new players and increase certainty in harsh conditions.

“Harsh but fair” survival integration

The world layer provides biome context. The run layer provides threats.

Biome drives:

exposure rate (cold/wet/heat)

parasite risk / disease prevalence

fire-start difficulty

food spoil rate modifiers

Quest constraints can include “weather window” or “danger profile,” so preparation matters.

Avoid unfair randomness:

hazards should have mitigation steps (boil water, cook properly, shelter, herbs)

log failures clearly (journal: why poisoned, why froze, etc.)

Implementation order (milestones)
Milestone 1: World sampler + chunk streaming

Implement WorldMapSampler

Implement ChunkStreamer + Chunk.tscn

Paint ground tiles per biome

Player can move around in huge world (chunks load/unload)

Milestone 2: WorldDB anchors (static)

Create world_db.json with:

settlements, landmarks, dungeons

Display anchor icons on overworld (optional)

Milestone 3: RunDirector (per run)

Create run save structure

Choose starting settlement based on RUN_SEED

Assign dungeon run-states (active/breaking/etc.)

Generate 5–10 quests

Milestone 4: Rumor/Clue system

Generate ClueFact[] for each quest

Implement “Ask about quest” UI at settlements

NPC returns clue facts via templates

Journal records facts as bullets

Milestone 5: Dungeon zones

Enter dungeon scene from fixed entrance tile

Dungeon interior generated from run dungeon content seed

Suggested file structure (Godot)

scripts/world/WorldMapSampler.gd

scripts/world/ChunkStreamer.gd

scripts/world/WorldDB.gd (or util loader for json)

scripts/run/RunDirector.gd

scripts/quests/QuestDirector.gd

scripts/quests/RumorDirector.gd

scripts/quests/ClueTemplates.gd (or JSON template data)

data/world/world_db.json

data/runs/run_<id>.json

assets/map/biome_id.png

assets/map/country_id.png (optional)

assets/map/water_mask.png (optional)

Key constants

CHUNK_SIZE = 64

LOAD_RADIUS = 3

WORLD_W_TILES, WORLD_H_TILES match intended world scale

BIOME_COLORS dictionary mapping RGB -> Biome enum

Design decisions locked in

Engine: Godot 2D isometric, tile-based overworld

World: static geography (same every run)

Dungeons: static entrance locations; run changes “active/breaking/contents”

Quests: generated per run; tied to anchors/regions

Navigation: no waypoint; structured clue facts via NPCs; players can ignore clues

Replayability: stable world + variable run layer + quest grammar + world state

Deliverable request for Copilot / GPT

Implement the systems in this order, as full copy/paste-ready scripts:

WorldMapSampler.gd

ChunkStreamer.gd + basic Chunk.tscn assumptions (TileMap nodes)

JSON schema + loader for world_db.json

RunDirector.gd that generates run state (starting location + dungeon states + quests)

QuestDirector.gd that produces quests and ClueFact[]

RumorDirector.gd that returns varied NPC clue lines using templates + anti-repeat tracking

Minimal Journal data model to store clue bullets and failure reasons

No snippets—full files.