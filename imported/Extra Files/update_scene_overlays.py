"""
Update CreateCharacter.tscn to use new pre-rendered kingdom overlays
Replaces the problematic SVGLayer.gd system with simple TextureRect nodes
"""

import re

def update_createcharacter_scene():
    scene_path = "scenes/ui/CreateCharacter.tscn"
    
    print(f"Updating {scene_path} to use pre-rendered kingdom overlays...")
    
    with open(scene_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Track changes made
    changes_made = []
    
    # Replace SVGLayer.gd script references with null (remove the script)
    # Find lines like: script = ExtResource("6_kingdom_overlay")
    old_script_pattern = r'script = ExtResource\("[^"]*kingdom_overlay[^"]*"\)'
    if re.search(old_script_pattern, content):
        content = re.sub(old_script_pattern, '# script = null  # Using MapOverlayManager instead', content)
        changes_made.append("Removed SVGLayer.gd script references")
    
    # Remove SVG-specific properties that are no longer needed
    svg_properties = [
        r'svg_source = "[^"]*"',
        r'kingdom_name = "[^"]*"',
        r'layer_type = "[^"]*"',
        r'overlay_color = [^\n]*',
        r'render_width = \d+',
        r'render_height = \d+'
    ]
    
    for prop_pattern in svg_properties:
        if re.search(prop_pattern, content):
            content = re.sub(prop_pattern, '', content)
    
    if svg_properties:
        changes_made.append("Removed SVG-specific properties")
    
    # Add MapContainer script reference if not present
    mapcontainer_pattern = r'\[node name="MapContainer"[^\]]*\]'
    if re.search(mapcontainer_pattern, content):
        # Check if MapContainer already has a script
        if 'script = ExtResource(' not in content[content.find('[node name="MapContainer"'):content.find('[node name="MapContainer"') + 500]:
            # Add the MapOverlayManager script to MapContainer
            replacement = '[node name="MapContainer" type="Control" parent="PageContainer/RightPage/RightPageContent/MapSection"]\nscript = ExtResource("map_overlay_manager")'
            content = re.sub(
                r'\[node name="MapContainer" type="Control" parent="PageContainer/RightPage/RightPageContent/MapSection"\]',
                replacement,
                content
            )
            changes_made.append("Added MapOverlayManager script to MapContainer")
    
    # Remove the ExtResource reference to SVGLayer.gd (find the line number first)
    lines = content.split('\n')
    svg_extresource_pattern = r'ExtResource.*path="[^"]*SVGLayer\.gd"'
    
    for i, line in enumerate(lines):
        if re.search(svg_extresource_pattern, line):
            # Replace with MapOverlayManager script reference
            lines[i] = '[ext_resource type="Script" path="res://scripts/ui/MapOverlayManager.gd" id="map_overlay_manager"]'
            changes_made.append("Replaced SVGLayer.gd ExtResource with MapOverlayManager.gd")
            break
    
    # Rebuild content
    content = '\n'.join(lines)
    
    # Write the updated scene
    with open(scene_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Updated {scene_path}")
    for change in changes_made:
        print(f"  - {change}")
    
    print(f"\nNext steps:")
    print(f"1. Open CreateCharacter.tscn in Godot")
    print(f"2. Import the PNG overlays with 'Lossless' compression")
    print(f"3. The MapOverlayManager will automatically assign textures to overlay nodes")
    print(f"4. Test kingdom selection - overlays should align perfectly!")

if __name__ == "__main__":
    update_createcharacter_scene()