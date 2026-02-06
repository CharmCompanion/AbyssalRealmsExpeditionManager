## Unreal Engine Migration & Asset Conversion Checklist (2026-01-05)

### 1. Preparation
- List all current assets: models, textures, audio, scripts, UI, etc.
- Identify file formats for each asset (e.g., .fbx, .png, .wav).
- Back up the entire project before starting migration.

### 2. Unreal Project Setup
- Install the latest stable Unreal Engine version.
- Create a new Unreal project (choose Blueprint or C++ as needed).
- Set up project folders to match your asset organization.

### 3. Asset Conversion
- Convert 3D models to .fbx (preferred for Unreal import).
- Convert textures to .png or .tga (Unreal-friendly formats).
- Export animations as .fbx with baked keyframes.
- Prepare audio files as .wav or .ogg.
- Gather all UI assets (images, fonts, etc.).

### 4. Importing to Unreal
- Import models, textures, and animations using Unreal’s Content Browser.
- Set up materials and shaders (use Unreal’s Material Editor for stylized looks).
- Recreate or import UI using Unreal’s UMG (UI Designer).
- Set up audio cues and sound assets.

### 5. Logic & Scripting
- Recreate gameplay logic using Blueprints or C++.
- Migrate or rewrite scripts (Godot/GDScript or Python will need to be rewritten).
- Set up player controls, camera, and input mappings.

### 6. Testing & Polish
- Test all imported assets for errors or missing data.
- Check materials and shaders for correct appearance.
- Playtest basic gameplay loop in Unreal.
- Optimize assets and fix any issues found.

### 7. Documentation
- Document any issues, fixes, or workflow changes during migration.
- Keep a changelog for future reference.

---
# Updated Graphics & Gameplay Direction (2026-01-05)

## Art Style Inspiration
- Shift visual direction to a style inspired by the game "Peak" (minimalist, stylized, manageable art assets).
- Research how "Peak" was made, focusing on art pipeline, asset creation, and rendering techniques.
- Plan to convert existing game visuals to this new style for consistency and appeal.

## Gameplay Loop & Expedition System
- The player manages a town, hiring adventurers to form parties for expeditions.
- Expeditions involve:
	- Buying supplies and gear.
	- Traveling to dungeons (driving carts, horses, or pushing if animals die).
	- Camping, gathering resources, handling random encounters, and managing survival elements (sickness, hunger, sleep, hydration, weather).
	- Reaching the dungeon, preparing, raiding floors, defeating bosses, and returning to town.
- Dungeons are located outside the main town, emphasizing the journey and preparation.
- Potential for co-op or online capabilities in the future.

## Next Steps
- Update asset and UI plans to reflect "Peak"-like visuals.
- Research and document "Peak" development resources and techniques.
- Refine expedition and town management mechanics based on this new direction.

---
# Chimera 3D System Integration Plan

## 1. Procedural 3D Map Generation by Kingdom/Biome
- Kingdom selection sets starting biome and seed.
- Each kingdom has a primary biome (forest, desert, tundra, etc.).
- Use procedural generation (Perlin/simplex noise) for terrain, decorated with biome-specific assets.
- Seed is tied to kingdom and map location for uniqueness.
- Multiple generations per biome using terrain/prop/feature presets or rulesets.

## 2. Modular, Part-by-Part Building System
- Each wall, floor, roof, etc. is a separate mesh/resource.
- Players craft or buy parts before placement.
- Snap all parts to a 3D grid.
- Hologram (semi-transparent) mesh for placement preview.
- Animate build process with a progress shader.

## 3. Blueprints, Templates, and Advanced Placement
- Save every building as a resource with part list, transforms, and metadata.
- Provide pre-made buildings for quick placement.
- Hologram guides for suggested layouts.
- Allow rotate, skew, tilt, resize, flip, mirror, multi-copy, and deletion.
- Quick build from list: click a saved building to enter hologram placement mode.

## 4. Interior Generation and Prop Placement
- Use recursive bisection or Wave Function Collapse (WFC) to auto-generate rooms and corridors.
- Place props and details from a categorized asset library, with rules for valid placement.
- Manual and assisted modes for interior building.

## 5. Implementation Steps
1. Map Generation: Noise-based terrain, biome assignment, seed = hash(kingdom, location, user seed).
2. Modular Construction: Each part is a .glb mesh, grid snap, all transforms, hologram shader.
3. Blueprints/Templates: Serialize building data, allow save/load/copy, UI for selection/placement.
4. Interior Generation: Recursive bisection or WFC for layout, constraint solvers for prop placement.
5. UI/UX: Toggles for manual/template build, build progress, cancel/undo.

## 6. Workspace Integration
- Use scripts/world/TownView.gd for grid and placement logic.
- Store modular parts in assets/buildings and assets/props/.
- Implement blueprint/resource serialization in scripts/world/BlueprintResource.gd.
- Use Docs/3D_Asset_List.csv as your part catalog.

## 7. References
- Godot Modular Building System Example: https://forum.godotengine.org/t/need-help-with-building-system-in-3d/53748
- Wave Function Collapse for Interiors: https://ar5iv.labs.arxiv.org/html/1211.5842
- Godot Hologram Shader Example: https://www.reddit.com/r/godot/comments/1aqnzsm/i_made_a_hologram_shader/
- Blueprint/Template System: https://devotedstudios.com/what-are-3d-modular-systems-in-game-development-a-beginner-friendly-guide/

## 8. Summary Table
| Feature                      | Where to Start/Reference                                 |
|-----------------------------|---------------------------------------------------------|
| Procedural Map/Kingdom/Biome| scripts/ui/CreateTown.gd, Game Feature Research_ Maps & Buildings.txt |
| Modular Building/Parts       | assets/buildings, Docs/3D_Asset_List.csv                |
| Hologram Placement           | Custom shader, Game Feature Research_ Maps & Buildings.txt |
| Blueprints/Templates         | New script, Game Feature Research_ Maps & Buildings.txt  |
| Interior Generation          | WFC/bisection, Game Feature Research_ Maps & Buildings.txt |
| Prop/Detail Placement        | assets/props/, asset library                             |
