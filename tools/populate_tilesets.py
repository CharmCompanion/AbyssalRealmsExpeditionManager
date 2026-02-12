#!/usr/bin/env python3
"""
Populate fantasy_iso tilesets with Small Scale Int Fantasy Tileset sprites.
Generates TileSet .tres files with proper Godot 4.6 TileSetAtlasSource structure.
"""

import os
import re
from pathlib import Path
from collections import defaultdict

# Configuration
ASSET_ROOT = Path("imported/Map and Character/Fantasy tileset - 2D Isometric/Environment")
TILESET_OUTPUT = Path("assets/tilesets/fantasy_iso")

# Tile dimensions and pivot
TILE_WIDTH = 128
TILE_HEIGHT = 128  # Tight grid - covers only visible sprite geometry
PIVOT_X = 0.5
PIVOT_Y = 0.18  # Standard for ground/grass tiles; 0.43 for cliff tiles

# Mapping of asset directories to tileset files and Godot TileSet names
CATEGORY_MAPPING = {
    "Ground": ("Fantasy_Ground.tres", "GroundTiles"),
    "Flora": ("Fantasy_Flora.tres", "FloraTiles"),
    "Tree": ("Fantasy_Trees.tres", "TreeTiles"),
    "Roof": ("Fantasy_Roof.tres", "RoofTiles"),
    "Wall": ("Fantasy_Wall.tres", "WallTiles"),
    "Stone": ("Fantasy_Stone.tres", "StoneTiles"),
}


def get_tile_id(sprite_name: str) -> str:
    """Extract tile ID from sprite name (e.g., 'Ground A1_N.png' -> 'A1')."""
    match = re.search(r"([A-Z]\d+)_[NSEW]", sprite_name)
    return match.group(1) if match else sprite_name.replace(".png", "")


def get_sprites_by_tile(category_dir: Path) -> dict:
    """
    Group sprites by tile ID.
    Returns dict: {tile_id: {'N': path, 'S': path, 'E': path, 'W': path}}
    """
    tiles = defaultdict(dict)
    
    if not category_dir.exists():
        return tiles
    
    for png_file in sorted(category_dir.glob("*.png")):
        if png_file.name.endswith(".import"):
            continue
        
        # Extract tile ID and direction
        match = re.match(r".*([A-Z]\d+)_([NSEW])\.png$", png_file.name)
        if match:
            tile_id = match.group(1)
            direction = match.group(2)
            tiles[tile_id][direction] = png_file.name
    
    return tiles


def generate_tileset_gdscript(category_name: str, sprites_by_tile: dict, 
                              category_dir: Path) -> str:
    """Generate complete Godot 4.6 TileSet GDScript resource."""
    
    if not sprites_by_tile:
        # Return empty but valid tileset
        return """[gd_resource type="TileSet" format=3]

[resource]
"""
    
    # Start TileSet resource
    lines = [
        '[gd_resource type="TileSet" format=3]',
        "",
        "[resource]",
    ]
    
    # Create TileSetAtlasSource for this category
    atlas_id = 0
    lines.append(f"sources/{atlas_id} = SubResource(\"TileSetAtlasSource_{atlas_id}\")")
    
    # Collect all tile definitions
    atlas_sources = []
    tile_index = 0
    
    for tile_id in sorted(sprites_by_tile.keys()):
        directions = sprites_by_tile[tile_id]
        
        # For this asset pack, we'll use the North-facing sprite as the main texture
        # (iso tiles typically show one perspective)
        if 'N' in directions:
            texture_name = directions['N']
            texture_path = f"res://imported/Map and Character/Fantasy tileset - 2D Isometric/Environment/{category_name}/{texture_name}"
            
            tile_index += 1
    
    # Create SubResource for TileSetAtlasSource
    atlas_source_lines = [
        "",
        f"[sub_resource type=\"TileSetAtlasSource\" id=\"TileSetAtlasSource_{atlas_id}\"]",
        f"texture_filter = 1",
        f"texture = SubResource(\"Image_{tile_index}\")",
        f"margins = Vector2i(0, 0)",
        f"separation = Vector2i(0, 0)",
        f"texture_region_size = Vector2i({TILE_WIDTH}, {TILE_HEIGHT})",
        f"use_texture_padding = false",
    ]
    
    # Add tile definitions
    tile_index = 0
    for tile_id in sorted(sprites_by_tile.keys()):
        directions = sprites_by_tile[tile_id]
        
        if 'N' in directions:
            atlas_source_lines.append(f"tiles/{tile_index} = {tile_id}")
            
            # Add tile metadata
            tile_data_line = f"tiles/{tile_index}/physics_layer_0/polygons = [PackedVector2Array()]"
            atlas_source_lines.append(tile_data_line)
            
            tile_index += 1
    
    lines.extend(atlas_source_lines)
    
    # Add image resources for each sprite
    tile_index = 0
    for tile_id in sorted(sprites_by_tile.keys()):
        directions = sprites_by_tile[tile_id]
        
        if 'N' in directions:
            texture_name = directions['N']
            texture_path = f"res://imported/Map and Character/Fantasy tileset - 2D Isometric/Environment/{category_name}/{texture_name}"
            
            lines.append("")
            lines.append(f'[sub_resource type="Image" id="Image_{tile_index}"]')
            lines.append(f'resource_path = "{texture_path}"')
            
            tile_index += 1
    
    return "\n".join(lines)


def generate_tileset_simple(category_name: str, sprites_by_tile: dict,
                           category_dir: Path) -> str:
    """
    Generate a simpler TileSet that references individual sprites.
    Correct order: headers → ext_resources → sub_resources → [resource] section
    """
    
    if not sprites_by_tile:
        return """[gd_resource type="TileSet" format=3]

[resource]
tile_size = Vector2i(128, 256)
"""
    
    lines = [
        '[gd_resource type="TileSet" format=3]',
        "",
    ]
    
    # First, add all ExtResources (external texture references)
    for idx, tile_id in enumerate(sorted(sprites_by_tile.keys())):
        directions = sprites_by_tile[tile_id]
        
        if 'N' in directions:
            texture_name = directions['N']
            texture_path = f"res://imported/Map and Character/Fantasy tileset - 2D Isometric/Environment/{category_name}/{texture_name}"
            
            lines.append(f'[ext_resource type="Texture2D" id="{tile_id}" path="{texture_path}"]')
    
    # Then, add all SubResource definitions
    for idx, tile_id in enumerate(sorted(sprites_by_tile.keys())):
        directions = sprites_by_tile[tile_id]
        
        if 'N' in directions:
            lines.append("")
            lines.append(f'[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_{idx}"]')
            lines.append('texture_filter = 1')
            lines.append(f'texture = ExtResource("{tile_id}")')
            lines.append('margins = Vector2i(0, 0)')
            lines.append('separation = Vector2i(0, 0)')
            lines.append(f'texture_region_size = Vector2i({TILE_WIDTH}, {TILE_HEIGHT})')
            lines.append('tiles/0/0 = 0')
    
    # Finally, add the main [resource] section with references
    lines.append("")
    lines.append("[resource]")
    lines.append(f"tile_size = Vector2i({TILE_WIDTH}, {TILE_HEIGHT})")
    
    for idx in range(len(sprites_by_tile)):
        lines.append(f"sources/{idx} = SubResource(\"TileSetAtlasSource_{idx}\")")
    
    return "\n".join(lines)


def main():
    """Generate all tileset files."""
    
    TILESET_OUTPUT.mkdir(parents=True, exist_ok=True)
    
    for category_name, (tileset_filename, tileset_godot_name) in CATEGORY_MAPPING.items():
        category_dir = ASSET_ROOT / category_name
        
        print(f"\nProcessing {category_name}...")
        
        if not category_dir.exists():
            print(f"  ⚠️  Directory not found: {category_dir}")
            continue
        
        sprites_by_tile = get_sprites_by_tile(category_dir)
        
        if not sprites_by_tile:
            print(f"  ⚠️  No sprites found in {category_name}")
            continue
        
        print(f"  Found {len(sprites_by_tile)} unique tiles")
        
        # Generate tileset content
        tileset_content = generate_tileset_simple(category_name, sprites_by_tile, category_dir)
        
        # Write tileset file
        output_path = TILESET_OUTPUT / tileset_filename
        output_path.write_text(tileset_content, encoding='ascii')
        
        print(f"  ✓ Generated: {tileset_filename}")
        print(f"    Tiles: {', '.join(sorted(sprites_by_tile.keys())[:5])}{'...' if len(sprites_by_tile) > 5 else ''}")


if __name__ == "__main__":
    main()
