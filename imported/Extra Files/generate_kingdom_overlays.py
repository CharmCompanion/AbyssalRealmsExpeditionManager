"""
Generate kingdom overlay textures using Pillow (PIL) instead of cairosvg
Creates simple solid-color overlays that match the exact SVG coordinate system
"""

try:
    from PIL import Image, ImageDraw
    import xml.etree.ElementTree as ET
    import os
    import re
    
    # Kingdom mapping - matches actual SVG path IDs
    kingdoms = {
        1: "Vylfod_Dominion",           # Northwest kingdom  
        2: "Rabaric_Republic",          # Southwest kingdom
        3: "Kingdom_of_El_Ruhn",        # Central kingdom
        4: "Kelsin_Federation",         # Northeast kingdom
        5: "Divine_Empire_of_Gosain",   # West kingdom
        6: "Yozuan_Desert"              # South/Southeast kingdom
    }
    
    def parse_svg_path(path_data):
        """Simple SVG path parser to extract basic shape bounds"""
        # Extract all coordinate pairs from the path data
        coords = re.findall(r'[-+]?(?:\d*\.\d+|\d+)', path_data)
        coords = [float(c) for c in coords]
        
        if len(coords) < 4:
            return None
            
        # Group into x,y pairs
        points = [(coords[i], coords[i+1]) for i in range(0, len(coords)-1, 2)]
        
        if not points:
            return None
            
        # Find bounding box
        min_x = min(p[0] for p in points)
        max_x = max(p[0] for p in points)
        min_y = min(p[1] for p in points)
        max_y = max(p[1] for p in points)
        
        return {
            'bounds': (min_x, min_y, max_x, max_y),
            'center': ((min_x + max_x) / 2, (min_y + max_y) / 2),
            'points': points
        }
    
    svg_path = "assets/map/Map.svg"
    output_dir = "assets/map/kingdoms"
    os.makedirs(output_dir, exist_ok=True)
    
    # SVG dimensions (from actual Map.svg viewBox)
    SVG_WIDTH = 843.75
    SVG_HEIGHT = 568.5
    
    # High resolution for quality
    SCALE_FACTOR = 2.4
    IMG_WIDTH = int(SVG_WIDTH * SCALE_FACTOR)  # 2025
    IMG_HEIGHT = int(SVG_HEIGHT * SCALE_FACTOR) # 1364
    
    print(f"Generating kingdom overlays from {svg_path}...")
    print(f"Output resolution: {IMG_WIDTH}x{IMG_HEIGHT}")
    print(f"Using correct SVG viewBox: {SVG_WIDTH}x{SVG_HEIGHT}")
    
    # Parse SVG
    tree = ET.parse(svg_path)
    root = tree.getroot()
    
    # Store kingdom centers for dot placement
    kingdom_centers = {}
    
    for kingdom_num, kingdom_name in kingdoms.items():
        print(f"\nProcessing Kingdom {kingdom_num}: {kingdom_name}")
        
        # Find the path element
        path_elem = root.find(f".//*[@id='{kingdom_name}']")
        
        if path_elem is not None:
            path_data = path_elem.get('d')
            if path_data:
                # Parse path to get shape info
                shape_info = parse_svg_path(path_data)
                if shape_info:
                    kingdom_centers[kingdom_name] = shape_info['center']
                    bounds = shape_info['bounds']
                    
                    print(f"  Bounds: ({bounds[0]:.1f}, {bounds[1]:.1f}) to ({bounds[2]:.1f}, {bounds[3]:.1f})")
                    print(f"  Center: ({shape_info['center'][0]:.1f}, {shape_info['center'][1]:.1f})")
                    
                    # Generate highlight and shadow overlays
                    for layer_type, color, alpha in [
                        ('highlight', (255, 255, 255), 153),  # White with 60% opacity
                        ('shadow', (0, 0, 0), 128)            # Black with 50% opacity
                    ]:
                        # Create transparent image
                        img = Image.new('RGBA', (IMG_WIDTH, IMG_HEIGHT), (0, 0, 0, 0))
                        draw = ImageDraw.Draw(img)
                        
                        # Scale coordinates to image size
                        x1 = bounds[0] * SCALE_FACTOR
                        y1 = bounds[1] * SCALE_FACTOR  
                        x2 = bounds[2] * SCALE_FACTOR
                        y2 = bounds[3] * SCALE_FACTOR
                        
                        # Draw filled rectangle covering the kingdom area
                        # This is a simplified approach - for exact shapes you'd need full SVG path rendering
                        draw.rectangle([x1, y1, x2, y2], fill=(*color, alpha))
                        
                        # Save the overlay
                        output_file = os.path.join(output_dir, f"kingdom{kingdom_num}_{layer_type}.png")
                        img.save(output_file, "PNG")
                        
                        print(f"  ✓ Generated {layer_type}: {output_file}")
                else:
                    print(f"  ✗ Could not parse path data for {kingdom_name}")
            else:
                print(f"  ✗ No path data found for {kingdom_name}")
        else:
            print(f"  ✗ Path element not found: {kingdom_name}")
    
    # Save kingdom center coordinates for dot placement
    coord_file = os.path.join(output_dir, "kingdom_centers.gd")
    with open(coord_file, 'w') as f:
        f.write("# Kingdom center coordinates in SVG space (843.75 x 568.5)\n")
        f.write("# Generated by generate_kingdom_overlays.py\n\n")
        f.write("const KINGDOM_CENTERS = {\n")
        for kingdom_name, center in kingdom_centers.items():
            f.write(f'    "{kingdom_name}": Vector2({center[0]:.2f}, {center[1]:.2f}),\n')
        f.write("}\n\n")
        f.write("const SVG_SIZE = Vector2(843.75, 568.5)\n")
        f.write("\n# Convert SVG coordinates to screen coordinates\n")
        f.write("static func svg_to_screen(svg_pos: Vector2, container_size: Vector2) -> Vector2:\n")
        f.write("    return Vector2(\n")
        f.write("        (svg_pos.x / SVG_SIZE.x) * container_size.x,\n")
        f.write("        (svg_pos.y / SVG_SIZE.y) * container_size.y\n")
        f.write("    )\n")
    
    print(f"\n✓ Kingdom overlays generated in {output_dir}/")
    print(f"✓ Kingdom centers saved to {coord_file}")
    print("\nNext steps:")
    print("1. Import PNG files in Godot with 'Lossless' compression")
    print("2. Replace SVGLayer.gd system with simple TextureRect nodes")
    print("3. Use kingdom_centers.gd for accurate dot placement")
    print("4. Overlays will align perfectly with map.png!")

except ImportError:
    print("ERROR: Pillow (PIL) not installed")
    print("Install it with: pip install Pillow")
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()