# Building Placement System Setup

## Overview

The building system is now ready with:
- **BuildLayer** (z-index -1) - Black tiles that serve as a **placement grid mask** for where ANY tile content can go
- **BuildingPlacement.gd** script - Handles tile selection, preview, and placement
- **Fantasy_Build.tres** - Tileset with the black placeholder tile

## Layer Structure

```
OverworldTest (BuildingPlacement.gd script attached)
├── BuildLayer (z=-1) ← BLACK TILES - Placement Grid (below everything)
├── GroundLayer (z=0)
├── StoneyLayer (z=1)
├── FloraLayer (z=2)
├── TreeLayer (z=3)
├── WallLayer (z=4)
└── RoofLayer (z=5)
```

**BuildLayer sits BEHIND all terrain.** Black tiles mark valid locations where you can place content. Paint black tiles first, then paint actual game content (buildings, trees, ground variations, etc.) on upper layers at those positions.

## How the System Works

### Current Behavior
1. **Paint black tiles on BuildLayer** to create the placement grid/layout for your map
2. **Paint actual content on upper layers** (ground, buildings, trees, props) at those same positions
3. **Black tiles stay behind everything** - they form the "void" that other tiles render on top of
4. **Selection system** tracks which tiles are placed and which are void

This creates a template: black tile positions define where the map exists, upper layers fill in the actual visuals.

### Key Script Functions

```gdscript
# Detect when player is over a black tile
is_over_build_slot: bool

# Called from UI when player picks a building
set_selected_building(building_id: int) -> void

# Get all black tile positions (useful for UI preview)
get_black_tile_positions() -> Array

# Replace black tile with building
_place_building_at(tile_pos: Vector2i) -> void
```

## Setting Up for Your Game

### Step 1: Create Placement Grid with Black Tiles
1. Open OverworldTest.tscn in Godot
2. Select **BuildLayer** in the scene tree
3. Paint black tiles to define the map layout - wherever you want ANY content to appear
4. Black tiles form the "void" - the areas of your map that exist
5. These mask positions define where you'll place ground, buildings, trees, props, etc.

Think of it like painting a floor plan first, then filling it in with details.

### Step 2: Paint Map Content on Upper Layers
Once black tiles define your layout, paint the actual game content:
- **GroundLayer** - Terrain (dirt, grass, stone) - fills the void
- **StoneyLayer** - Cliffs, rocky areas
- **FloraLayer** - Bushes, flowers, small details
- **TreeLayer** - Trees and large vegetation
- **WallLayer** - Building walls and structures
- **RoofLayer** - Roofs and building tops

All painted at black tile positions, rendering on top of them.

### Step 3: Connect UI Menu (Next Phase)
When you build your left-side UI menu for building selection, buildings will place on vacant black tile slots using the same system.

## How It Works: Placement Grid Concept

**Black tiles = Placement Grid**
- Black tiles mark valid locations for content
- They stay BEHIND all other layers
- They act as a template/mask for where your map exists

**Content Layers = Actual Map**
- Paint ground, buildings, trees, etc. on upper layers
- Content renders ON TOP of black tiles
- You can see black tiles in gaps where there's no content

**Future Building Placement**
- When UI menu is built, players will click vacant black tiles
- Building selected from menu replaces black tile with building content
- Same grid system works for props, trees, any interactive element

## Painting Workflow

### Map Creation Process:

**Phase 1: Plan with Black Tiles**
1. Select **BuildLayer**
2. Paint black tiles to define the overall map layout and shape
3. This is your placement grid - white spaces are "void" that won't have content

**Phase 2: Fill In Terrain**
1. Select **GroundLayer**
2. Paint ground tiles at each black tile position (creates base terrain)
3. Vary ground types (grass, dirt, stone) to add visual interest

**Phase 3: Add Environmental Details**
1. **StoneyLayer** - Add cliffs/rocks where appropriate
2. **FloraLayer** - Add flowers, bushes at black tile positions
3. **TreeLayer** - Add trees and large plants

**Phase 4: Add Structures** (Buildings)
1. **WallLayer** - Paint walls where buildings should be
2. **RoofLayer** - Paint roofs above walls

### Example: Simple Town Layout
```
Black tile layout (marked with █):
    █ █ █
    █ █ █  
    █ █ █

Ground layer (filled in):
    🌱 🌱 🌱
    🌱 🌱 🌱  
    🌱 🌱 🌱

Add buildings on some:
    🌱🏘️🌱
    🌱🏘️🌱  
    🌱🌱🌱

Result: Black tiles behind everything, visible as "void" where there's no content
```

### Tile Layering (Front to Back):
```
Roof (front - what player sees most)
Wall
Flora
Trees
Stoney
Ground
Build ← Black tiles (back - the placement grid)

## Testing the System

1. Open OverworldTest in Godot
2. **Select BuildLayer** in scene tree
3. **Paint a grid of black tiles** (10x10 or so for testing)
4. **Select GroundLayer** and paint ground tiles at the same positions
5. The ground should appear **on top of** the black tiles (BuildLayer is z=-1, GroundLayer is z=0)
6. Black tiles should be mostly hidden unless there's a gap in the ground layer
7. Move mouse over black tile positions - script will print debug messages
8. Click a black tile - script will print "Building slot selected"

This tests that:
- BuildLayer renders behind other layers ✓
- Selection system detects tile positions ✓
- Ready for content placement ✓

## Next Steps

1. ✅ Building placement framework is ready
2. ⏳ Create town map:
   - **Paint BuildLayer** with black tiles to define map layout
   - Fill in with GroundLayer terrain at those positions
   - Add details (trees, flora, buildings) on upper layers
3. ⏳ Create expedition/path map with similar black tile layout
4. ⏳ Create dungeon entrance map
5. ⏳ Build the UI menu (left side) for building selection
6. ⏳ Wire UI to place buildings on vacant black tile positions

## Key Files

- **Script:** [scripts/world/BuildingPlacement.gd](scripts/world/BuildingPlacement.gd)
- **Scene:** [scenes/world/overworld/OverworldTest.tscn](scenes/world/overworld/OverworldTest.tscn)
- **Tileset:** [assets/tilesets/fantasy_iso/Fantasy_Build.tres](assets/tilesets/fantasy_iso/Fantasy_Build.tres)

## Debug Output

When you run the scene and interact with black tiles, console shows:
```
BuildingPlacement: Ready - Black tiles are placeholders for buildings
BuildLayer z-index: -1 (below all other tiles)
Preview: Black tile at (5, 3) - ready to place building
Building slot (5, 3) is now selected - waiting for building menu
```

This confirms:
- BuildLayer is at z=-1 ✓
- Selection system detects black tile positions ✓
- Ready for content placement ✓
