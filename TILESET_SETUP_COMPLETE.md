# Tileset Setup Complete

## What's Been Set Up

### TileSet Files Generated (6 total)
All populated with Small Scale Int Fantasy Tileset sprites:

| File | Tiles | Purpose |
|------|-------|---------|
| `Fantasy_Ground.tres` | 113 | Grass, dirt, stone, sand, pathways (base terrain) |
| `Fantasy_Flora.tres` | 13 | Decorative flowers, bushes, clutter |
| `Fantasy_Trees.tres` | 18 | Trees and large nature objects |
| `Fantasy_Roof.tres` | 57 | Building roofs and tops |
| `Fantasy_Wall.tres` | 104 | Walls, columns, structures |
| `Fantasy_Stone.tres` | 22 | Rocks, cliffs, stone terrain |

**Location:** `assets/tilesets/fantasy_iso/`

### Scene Structure: OverworldTest.tscn
6 TileMapLayers stacked with proper z-ordering:

```
OverworldTest (Node2D at position 512, 384)
├── GroundLayer (z=0)  → Fantasy_Ground
├── StoneyLayer (z=1)  → Fantasy_Stone
├── FloraLayer (z=2)   → Fantasy_Flora
├── TreeLayer (z=3)    → Fantasy_Trees
├── WallLayer (z=4)    → Fantasy_Wall
└── RoofLayer (z=5)    → Fantasy_Roof
```

## How to Paint Maps

1. **Open OverworldTest.tscn in Godot**
   - Path: `scenes/world/overworld/OverworldTest.tscn`
   - All 6 TileMapLayers are ready and connected to their tilesets

2. **Select a Layer**
   - Click the layer name in the Scene tree (e.g., "GroundLayer")
   - The tileset palette will appear in the Inspector

3. **Paint Tiles**
   - Use the TileMap painting tools in the toolbar
   - Select tiles from the tileset palette
   - Click and drag on the scene canvas to paint
   - Y-sort is enabled, so tiles will layer properly

4. **Layer Information**
   - **Layer 0 (Ground):** Base terrain - paint dirt, grass, stone patterns
   - **Layer 1 (Stone):** Cliffs, rocky terrain
   - **Layer 2 (Flora):** Bushes, flowers, decorative elements
   - **Layer 3 (Trees):** Large trees
   - **Layer 4 (Walls):** Building walls and structures
   - **Layer 5 (Roofs):** Roofs and building tops

## Tile Specifications

- **Sprite Size:** 128×256 pixels
- **Pivot Point:** X=0.5, Y=0.18 (standard isometric)
- **Perspective:** Isometric top-down
- **Directions:** North-facing sprites loaded (N sprite shown in all 4 directions for simplicity; can be expanded with direction variants)

## Recommended Painting Order

1. Paint GroundLayer first (creates base terrain)
2. Add StoneyLayer for rocky areas/cliffs
3. Place FloraLayer for bushes and small details
4. Add TreeLayer for forest areas
5. Build with WallLayer for structures
6. Top with RoofLayer for building roofs

## Reference Maps to Create

### 1. Town Map
- Layered buildings with brown/tan walls, yellow/tan roofs
- Ground tiles with mixed textures
- Pathways between buildings
- Trees for vegetation

### 2. Expedition/Path Map
- Dense forest (heavy TreeLayer + FloraLayer)
- Winding paths (GroundLayer lighter colors)
- River or water features
- Natural landscape variation

### 3. Dungeon Entrance
- Raised platform (StoneyLayer)
- Stone entrance structure (WallLayer)
- Surrounding natural landscape
- Compact focal-point layout

## Script Files

- `tools/populate_tilesets.py` - Generated the .tres files from asset pack

## Tips for Best Results

1. **Layer Order Matters** - Paint from bottom (ground) to top (roof)
2. **Y-Sort Enabled** - Tiles automatically sort by Y position for proper depth
3. **Variation** - Mix different tile variants to avoid repetitive patterns
4. **Test Painting** - Start with a small area to see how tiles look together
5. **Save Often** - Godot auto-saves, but manual saves are good practice

## Troubleshooting

If tiles don't appear:
1. Check tileset files loaded (Inspector shows connections)
2. Verify layer is selected (highlighted in Scene tree)
3. Check that paint tool is active (TileMap tools)
4. Try scrolling in tileset palette to find tiles

If tiles look wrong:
1. Check Y-sort is enabled on layers (it is by default)
2. Verify layer order (StoneyLayer below TreeLayer, etc.)
3. Make sure right layer is selected for painting

## Next Steps

- Open OverworldTest.tscn in Godot 4.6
- Select GroundLayer and start painting base terrain
- Build reference maps matching the three provided images
- Expand to additional tilesets/layers as needed
