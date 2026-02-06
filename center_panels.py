import re

file_path = r"c:\Users\RY0M\Desktop\DungeonTycoon\Abyssal Realms Expedition Manager\scenes\ui\CreateTown_Flat.tscn"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add vertical alignment to all kingdom and deity panel Content VBoxContainers
# Pattern: VBoxContainer with parent path containing Kingdom or Deity and ending in /Content
panels = [
    "GostinPanel", "KelsinPanel", "YozuanPanel", "RabaricPanel", "ElRuhnPanel", "TzaludPanel",
    "NivariusPanel", "SeraPanel", "FortPanel", "ThornPanel", "AureliaPanel", "ZephraPanel"
]

for panel in panels:
    # Find the Content VBoxContainer for each panel
    if "Panel" in panel:
        # Determine if it's a Kingdom or Deity panel
        if panel in ["GostinPanel", "KelsinPanel", "YozuanPanel", "RabaricPanel", "ElRuhnPanel", "TzaludPanel"]:
            parent_path = f"TabContainer/Kingdom/KingdomContainer/{panel}"
        else:
            parent_path = f"TabContainer/Deity/DeityContainer/{panel}"
        
        # Add alignment = 1 to center vertically
        pattern = rf'(\[node name="Content" type="VBoxContainer" parent="{parent_path}"\]\s*layout_mode = 1\s*anchors_preset = 15\s*anchor_right = 1\.0\s*anchor_bottom = 1\.0\s*offset_left = 12\.0\s*offset_top = 12\.0\s*offset_right = -12\.0\s*offset_bottom = -12\.0\s*)(theme_override_constants/separation = 4)'
        replacement = r'\1alignment = 1\n\2'
        content = re.sub(pattern, replacement, content)

# Adjust ActionButtons to fit within panel - move them higher
content = re.sub(
    r'(\[node name="ActionButtons" type="HBoxContainer" parent="\."]\s*layout_mode = 1\s*)anchor_left = 0\.28\s*anchor_top = 0\.86\s*anchor_right = 0\.72\s*anchor_bottom = 0\.93',
    r'\1anchor_left = 0.28\nanchor_top = 0.84\nanchor_right = 0.72\nanchor_bottom = 0.90',
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Panel content centered and buttons repositioned successfully")
