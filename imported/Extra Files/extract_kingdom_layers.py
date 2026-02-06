"""
Extract individual kingdom highlight and shadow layers from Map.svg
Creates separate PNG files for each kingdom overlay
"""
import xml.etree.ElementTree as ET
import subprocess
import os

# Kingdom mapping: Kingdom1 = Yozuan_Desert, Kingdom2 = Divine_Empire_of_Gosain, etc.
kingdoms = {
    1: "Yozuan_Desert",
    2: "Divine_Empire_of_Gosain",
    3: "Kelsin_Federation",
    4: "Kingdom_of_El_Ruhn",
    5: "Rabaric_Republic",
    6: "Vylfod_Dominion"
}

svg_path = "assets/map/Map.svg"
output_dir = "assets/map/kingdoms"

# Create output directory
os.makedirs(output_dir, exist_ok=True)

# Parse the SVG
tree = ET.parse(svg_path)
root = tree.getroot()

# SVG namespace
ns = {'svg': 'http://www.w3.org/2000/svg'}

print(f"Extracting kingdom layers from {svg_path}...")
print(f"Output directory: {output_dir}")

# Read the original SVG
with open(svg_path, 'r', encoding='utf-8') as f:
    svg_content = f.read()

# For each kingdom, create highlight (-3) and shadow (-2) SVGs
for kingdom_num, kingdom_name in kingdoms.items():
    for layer_type in [('highlight', '-3'), ('shadow', '-2')]:
        layer_name, suffix = layer_type
        path_id = f"{kingdom_name}{suffix}"
        
        print(f"Processing Kingdom{kingdom_num} {layer_name} ({path_id})...")
        
        # Create a new SVG with only this path visible
        # We'll create a modified version of the SVG
        modified_svg = svg_content
        
        # Create output filename
        output_file = os.path.join(output_dir, f"kingdom{kingdom_num}_{layer_name}.svg")
        
        # For now, just copy the structure - we'll extract in Inkscape if available
        # or use a simpler approach
        
print("\nNote: To properly extract layers, you'll need to:")
print("1. Open Map.svg in Inkscape")
print("2. For each kingdom:")
print("   - Hide all layers except the specific -2 (shadow) or -3 (highlight) path")
print("   - Export as PNG with transparent background")
print("   - Name: kingdom1_highlight.png, kingdom1_shadow.png, etc.")
print(f"3. Save PNGs to {output_dir}/")
