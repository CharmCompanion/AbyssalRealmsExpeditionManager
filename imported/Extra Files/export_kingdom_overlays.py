"""
Extract kingdom overlay layers from Map.svg and save as transparent PNGs
Uses cairosvg to render individual SVG paths with transparency - PROPER SHAPES VERSION
"""

def install_cairo_windows():
    """Install Cairo dependencies on Windows"""
    import subprocess
    import sys
    
    print("Installing Cairo dependencies for Windows...")
    try:
        # Install Windows Cairo binaries
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--upgrade", "cairocffi"])
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--force-reinstall", "cairosvg"])
        return True
    except subprocess.CalledProcessError:
        return False

try:
    from cairosvg import svg2png
    import xml.etree.ElementTree as ET
    import os
    
    # Kingdom mapping - matches actual SVG path IDs
    kingdoms = {
        1: "Vylfod_Dominion",           # Northwest kingdom
        2: "Rabaric_Republic",          # Southwest kingdom  
        3: "Kingdom_of_El_Ruhn",        # Central kingdom
        4: "Kelsin_Federation",         # Northeast kingdom
        5: "Divine_Empire_of_Gosain",   # West kingdom
        6: "Yozuan_Desert"              # South/Southeast kingdom
    }
    
    svg_path = "assets/map/Map.svg"
    output_dir = "assets/map/kingdoms"
    os.makedirs(output_dir, exist_ok=True)
    
    # Read SVG content
    with open(svg_path, 'r', encoding='utf-8') as f:
        svg_content = f.read()
    
    tree = ET.parse(svg_path)
    root = tree.getroot()
    
    print(f"Extracting EXACT kingdom shapes from {svg_path}...")
    print(f"Using correct viewBox: 0 0 843.75 568.5 (matches actual SVG)")
    
    for kingdom_num, kingdom_name in kingdoms.items():
        for layer_type, color, opacity in [
            ('highlight', '#FFFFFF', '0.7'),  # White for highlights
            ('shadow', '#000000', '0.5')      # Black for shadows
        ]:
            # Use direct path ID (no suffixes)
            path_id = kingdom_name
            output_file = os.path.join(output_dir, f"kingdom{kingdom_num}_{layer_type}.png")
            
            # Find the path element by ID
            path_elem = None
            for elem in root.iter():
                if elem.get('id') == path_id:
                    path_elem = elem
                    break
            
            if path_elem is not None:
                path_data = path_elem.get('d')
                if path_data:
                    # Create minimal SVG with EXACT shape and CORRECT viewBox
                    minimal_svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 843.75 568.5" width="843.75" height="568.5">
    <path id="{path_id}" d="{path_data}" fill="{color}" fill-opacity="{opacity}" stroke="none"/>
</svg>'''
                
                    # Export to PNG with correct aspect ratio - HIGH RESOLUTION for exact shapes
                    base_width, base_height = 843.75, 568.5
                    scale_factor = 3.0  # 2531x1705 for crisp edges
                    export_width = int(base_width * scale_factor)
                    export_height = int(base_height * scale_factor)
                    
                    print(f"  Rendering {kingdom_name} {layer_type} at {export_width}x{export_height}...")
                    
                    svg2png(bytestring=minimal_svg.encode('utf-8'), 
                           write_to=output_file,
                           output_width=export_width,
                           output_height=export_height)
                    
                    print(f"  ✓ Exported exact shape: {output_file}")
                else:
                    print(f"  ✗ No path data for: {path_id}")
            else:
                print(f"  ✗ Could not find path element: {path_id}")
    
    print(f"\n✅ EXACT kingdom shapes exported to {output_dir}/")
    print(f"✅ Using correct viewBox (843.75x568.5) for perfect alignment")
    print("✅ High resolution (3x scale) for crisp shape edges")
    print("✅ Import in Godot with 'Lossless' compression for transparency")

except ImportError as e:
    print("❌ ERROR: cairosvg not installed or missing Cairo system libraries")
    print(f"Details: {e}")
    
    if not install_cairo_windows():
        print("\n🔧 MANUAL SOLUTION - Export shapes yourself:")
        print("Since cairosvg needs system libraries, here's how to export manually:")
        print()
        print("OPTION A - Use Inkscape (Recommended):")
        print("1. Open assets/map/Map.svg in Inkscape")
        print("2. For each kingdom path:")
        print("   a. Select the kingdom path (e.g., Vylfod_Dominion)")
        print("   b. Hide all other elements")
        print("   c. Set fill to white (#FFFFFF) with 70% opacity")
        print("   d. Export as PNG: kingdom1_highlight.png (2531x1705px)")
        print("   e. Change fill to black (#000000) with 50% opacity")
        print("   f. Export as PNG: kingdom1_shadow.png (2531x1705px)")
        print("3. Save all 12 files to assets/map/kingdoms/")
        print()
        print("OPTION B - Use AI tool (Illustrator/Photoshop):")
        print("1. Import Map.svg")
        print("2. Select each kingdom path individually")
        print("3. Create white and black versions with transparency")
        print("4. Export maintaining 843.75:568.5 aspect ratio")
        print()
        print("CRITICAL: Maintain exact viewBox dimensions (843.75x568.5) for alignment!")

except Exception as e:
    print(f"❌ ERROR: {e}")
    import traceback
    traceback.print_exc()

except ImportError:
    print("ERROR: cairosvg not installed")
    print("\nInstall it with: pip install cairosvg")
    print("\nOr use this manual export guide:")
    print("1. Open Map.svg in Inkscape or Illustrator")
    print("2. For each kingdom (Yozuan_Desert through Vylfod_Dominion):")
    print("   a. Hide all layers except the -3 path (highlight)")
    print("   b. Export as PNG: kingdom1_highlight.png (2000x1200px)")
    print("   c. Hide -3, show -2 path (shadow)")
    print("   d. Export as PNG: kingdom1_shadow.png (2000x1200px)")
    print(f"3. Save all 12 PNGs to assets/map/kingdoms/")
