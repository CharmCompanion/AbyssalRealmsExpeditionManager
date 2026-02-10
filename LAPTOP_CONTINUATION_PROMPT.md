# LAPTOP CONTINUATION — ISO TEST MAP + LORD/NPC SETUP
**Project:** Abyssal Realms Expedition Manager
**Session Date:** Feb 10, 2026
**Status:** ISO test scene playable; map sampler + tileset workflow in progress ✅

---

## ✅ What we did this session

### 1) World map sampling (static layer)
- Added [scripts/world/WorldMapSampler.gd](scripts/world/WorldMapSampler.gd)
  - Reads `assets/map/Biomes.png`, `assets/map/map.png`, `assets/map/kingdoms/Water.png`
  - Exposes `get_biome_at_tile`, `get_country_at_tile`, `is_water`

### 2) Overworld test scene (walkable)
- Scene: [scenes/world/overworld/OverworldTest.tscn](scenes/world/overworld/OverworldTest.tscn)
- Player can walk via `OverworldPlayer.gd`
- Uses TileMapLayer (Godot 4.6) to avoid deprecation warnings
- Y-sorting enabled so sprites layer correctly in iso view

### 3) Player uses character-creator rig
- Player now uses a `LordRig` (from `LordModelPreview.gd`) instead of a static sprite
- Appearance generated at runtime via `CharacterAppearanceGenerator`
- Movement drives 8-direction facing + walk/idle actions

### 4) NPCs + enemy in the test map
- Added 3 NPCs and 1 enemy using iso sprite sheets
- New helper script for their sheet animation: [scripts/world/IsoCharacterSprite.gd](scripts/world/IsoCharacterSprite.gd)

### 5) Kit paths fixed
- Isometric environment dir now points to imported kit
  - [scripts/world/KingdomRegionTextureGenerator.gd](scripts/world/KingdomRegionTextureGenerator.gd)

### 6) TileSet sorting folders created
- assets/tilesets/fantasy_iso/Animations
- assets/tilesets/fantasy_iso/Animations/Animated Tiles
- assets/tilesets/fantasy_iso/Animations/Destructible tiles
- assets/tilesets/fantasy_iso/Animations/Effects
- assets/tilesets/fantasy_iso/Animations/Props

### 7) Fixed Godot parse error
- Fixed `biome_data.gd` (invalid top-level `dict`)
  - [Chimera3D_Scaffold/map_gen/biome_data.gd](Chimera3D_Scaffold/map_gen/biome_data.gd)

---

## ✅ Current files touched
- [scripts/world/WorldMapSampler.gd](scripts/world/WorldMapSampler.gd)
- [scripts/world/OverworldTest.gd](scripts/world/OverworldTest.gd)
- [scripts/world/OverworldPlayer.gd](scripts/world/OverworldPlayer.gd)
- [scripts/world/IsoCharacterSprite.gd](scripts/world/IsoCharacterSprite.gd)
- [scripts/ui/LordModelPreview.gd](scripts/ui/LordModelPreview.gd)
- [scripts/world/KingdomRegionTextureGenerator.gd](scripts/world/KingdomRegionTextureGenerator.gd)
- [scenes/world/overworld/OverworldTest.tscn](scenes/world/overworld/OverworldTest.tscn)

---

## ⚠️ Known issues / things to verify
1) **NPC/Enemy animation framing**
   - If sheet frames are not 128x128, update `frame_size` on the NPC Sprite2D nodes.
2) **TileSet coverage**
   - TileSet resources need to be created for each kit folder (Ground, Tree, Stone, etc.).

---

## 🔜 What we need to do next

### A) Finish tile set organization
- For each kit folder, create a TileSet resource (same workflow as Ground).
- Keep animated tiles in their own TileSet folder (Animations/Animated Tiles).

### B) Clean iso test map
- Paint a small starter map: ground, house, tree, rock, props.
- Confirm player/npc sorting looks correct.

### C) Replace NPC/enemy with character-creator rigs (optional next)
- If we want all actors using the creator system, swap NPC Sprite2D to layered rigs.

### D) Move toward chunked overworld
- Build `Chunk.tscn` + `ChunkStreamer.gd` to stream tiles by player position.

---

## 📌 Plan going forward (short)
1) Finalize TileSet resources for the iso kit folders.
2) Lock down the OverworldTest visual baseline (ground + props + working actors).
3) Start chunked overworld generation with `WorldMapSampler`.
4) Integrate quest/rumor systems after the overworld is stable.

---

## 🧪 Quick test checklist
- Open OverworldTest, confirm:
  - Player moves and faces correctly (8 directions)
  - NPCs and enemy animate
  - Y-sort looks right
  - TileMapLayer draws without warnings

---

**STATUS:** OverworldTest is playable, tile workflow in progress.  
**NEXT MILESTONE:** TileSets + chunked overworld streaming.