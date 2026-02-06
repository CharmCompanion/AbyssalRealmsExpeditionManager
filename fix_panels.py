import re

file_path = r"c:\Users\RY0M\Desktop\DungeonTycoon\Abyssal Realms Expedition Manager\scenes\ui\CreateTown_Flat.tscn"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Remove all BG ColorRect nodes (deity and kingdom panels)
content = re.sub(
    r'\[node name="BG" type="ColorRect" parent="(?:DeitySection/DeityButtonContainer|KingdomSection/KingdomContainer)/[^"]+"\]\s*layout_mode = 1\s*anchors_preset = 15\s*anchor_right = 1\.0\s*anchor_bottom = 1\.0\s*color = Color\([^)]+\)\s*\n',
    '',
    content
)

# Update all remaining deity panels (except Nivarius which is already done)
deity_panels = ["SeraPanel", "FortPanel", "ThornPanel", "AureliaPanel", "ZephraPanel"]
for panel in deity_panels:
    # Update panel size
    content = re.sub(
        rf'(\[node name="{panel}" type="Panel" parent="DeitySection/DeityButtonContainer"\]\s*custom_minimum_size = )Vector2\(150, 80\)',
        r'\1Vector2(180, 100)',
        content
    )
    # Update Content padding and separation
    pattern = rf'(\[node name="Content" type="VBoxContainer" parent="DeitySection/DeityButtonContainer/{panel}"\]\s*layout_mode = 1\s*anchors_preset = 15\s*anchor_right = 1\.0\s*anchor_bottom = 1\.0\s*)offset_left = 10\.0\s*offset_top = 10\.0\s*offset_right = -10\.0\s*offset_bottom = -10\.0\s*theme_override_constants/separation = 3'
    replacement = r'\1offset_left = 12.0\noffset_top = 12.0\noffset_right = -12.0\noffset_bottom = -12.0\ntheme_override_constants/separation = 4'
    content = re.sub(pattern, replacement, content)
    
    # Update DeityName font and add clip
    pattern = rf'(\[node name="DeityName" type="Label" parent="DeitySection/DeityButtonContainer/{panel}/Content"\]\s*layout_mode = 2\s*)theme_override_font_sizes/font_size = 18\s*text = "[^"]+"\s*horizontal_alignment = 1'
    def replace_name(m):
        text_match = re.search(r'text = "([^"]+)"', m.group(0))
        text = text_match.group(1) if text_match else ""
        return m.group(1) + f'theme_override_font_sizes/font_size = 16\ntext = "{text}"\nhorizontal_alignment = 1\nclip_text = true'
    content = re.sub(pattern, replace_name, content)
    
    # Update DeityTitle, Bonus1, Bonus2 fonts and add clip and center
    for label in ["DeityTitle", "Bonus1", "Bonus2"]:
        pattern = rf'(\[node name="{label}" type="Label" parent="DeitySection/DeityButtonContainer/{panel}/Content"\]\s*layout_mode = 2\s*)theme_override_font_sizes/font_size = 14\s*text = "([^"]+)"(\s*horizontal_alignment = 1)?'
        replacement = r'\1theme_override_font_sizes/font_size = 12\ntext = "\2"\nhorizontal_alignment = 1\nclip_text = true'
        content = re.sub(pattern, replacement, content)

# Update all kingdom panels
kingdom_panels = ["GostinPanel", "KelsinPanel", "YozuanPanel", "RabaricPanel", "ElRuhnPanel", "TzaludPanel"]
for panel in kingdom_panels:
    # Update panel size
    content = re.sub(
        rf'(\[node name="{panel}" type="Panel" parent="KingdomSection/KingdomContainer"\]\s*custom_minimum_size = )Vector2\(150, 80\)',
        r'\1Vector2(180, 100)',
        content
    )
    # Update Content padding and separation
    pattern = rf'(\[node name="Content" type="VBoxContainer" parent="KingdomSection/KingdomContainer/{panel}"\]\s*layout_mode = 1\s*anchors_preset = 15\s*anchor_right = 1\.0\s*anchor_bottom = 1\.0\s*)offset_left = 10\.0\s*offset_top = 10\.0\s*offset_right = -10\.0\s*offset_bottom = -10\.0\s*theme_override_constants/separation = 3'
    replacement = r'\1offset_left = 12.0\noffset_top = 12.0\noffset_right = -12.0\noffset_bottom = -12.0\ntheme_override_constants/separation = 4'
    content = re.sub(pattern, replacement, content)
    
    # Update KingdomName, Region, Trait1, Trait2 fonts and add clip and center
    for label in ["KingdomName", "Region", "Trait1", "Trait2"]:
        if label == "KingdomName":
            pattern = rf'(\[node name="{label}" type="Label" parent="KingdomSection/KingdomContainer/{panel}/Content"\]\s*layout_mode = 2\s*)theme_override_font_sizes/font_size = 18\s*text = "([^"]+)"\s*horizontal_alignment = 1'
            replacement = r'\1theme_override_font_sizes/font_size = 16\ntext = "\2"\nhorizontal_alignment = 1\nclip_text = true'
        else:
            pattern = rf'(\[node name="{label}" type="Label" parent="KingdomSection/KingdomContainer/{panel}/Content"\]\s*layout_mode = 2\s*)theme_override_font_sizes/font_size = 14\s*text = "([^"]+)"(\s*horizontal_alignment = 1)?'
            replacement = r'\1theme_override_font_sizes/font_size = 12\ntext = "\2"\nhorizontal_alignment = 1\nclip_text = true'
        content = re.sub(pattern, replacement, content)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("File updated successfully")
