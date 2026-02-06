file_path = r"c:\Users\RY0M\Desktop\DungeonTycoon\Abyssal Realms Expedition Manager\scenes\ui\CreateTown_Flat.tscn"

with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# Read the header
header = []
i = 0
while i < len(lines) and not lines[i].startswith("[node name=\"CreateTown\""):
    header.append(lines[i])
    i += 1

# Build new structure
new_content = "".join(header)

new_content += """[node name="CreateTown" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Dim" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 0.45)

[node name="Panel" type="NinePatchRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = -10.0
texture = ExtResource("2")
patch_margin_left = 8
patch_margin_top = 8
patch_margin_right = 8
patch_margin_bottom = 8

[node name="Title" type="Label" parent="Panel"]
layout_mode = 1
anchor_left = 0.0
anchor_top = 0.02
anchor_right = 1.0
anchor_bottom = 0.08
theme_override_fonts/font = ExtResource("4")
theme_override_font_sizes/font_size = 36
text = "Create New Settlement"
horizontal_alignment = 1
vertical_alignment = 1

[node name="TabContainer" type="TabContainer" parent="Panel"]
layout_mode = 1
anchor_left = 0.02
anchor_top = 0.09
anchor_right = 0.98
anchor_bottom = 0.88
theme_override_font_sizes/font_size = 18

[node name="Town" type="VBoxContainer" parent="Panel/TabContainer"]
layout_mode = 2
theme_override_constants/separation = 20

[node name="BasicInfo" type="VBoxContainer" parent="Panel/TabContainer/Town"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="SettlementLabel" type="Label" parent="Panel/TabContainer/Town/BasicInfo"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Settlement Name:"

[node name="SettlementInput" type="LineEdit" parent="Panel/TabContainer/Town/BasicInfo"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
placeholder_text = "Enter settlement name..."

[node name="SeedLabel" type="Label" parent="Panel/TabContainer/Town/BasicInfo"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "World Seed:"

[node name="SeedContainer" type="HBoxContainer" parent="Panel/TabContainer/Town/BasicInfo"]
layout_mode = 2

[node name="SeedInput" type="LineEdit" parent="Panel/TabContainer/Town/BasicInfo/SeedContainer"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 18
placeholder_text = "Random seed..."

[node name="RandomButton" type="Button" parent="Panel/TabContainer/Town/BasicInfo/SeedContainer"]
custom_minimum_size = Vector2(120, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Random"

[node name="ResourcesSection" type="VBoxContainer" parent="Panel/TabContainer/Town"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 12

[node name="ResourcesLabel" type="Label" parent="Panel/TabContainer/Town/ResourcesSection"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "Starting Resources:"

[node name="ResourcesGrid" type="GridContainer" parent="Panel/TabContainer/Town/ResourcesSection"]
layout_mode = 2
theme_override_constants/h_separation = 20
theme_override_constants/v_separation = 12
columns = 2

[node name="GoldContainer" type="HBoxContainer" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid"]
layout_mode = 2

[node name="GoldLabel" type="Label" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/GoldContainer"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Gold:"

[node name="GoldMinus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/GoldContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "-"

[node name="GoldInput" type="LineEdit" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/GoldContainer"]
custom_minimum_size = Vector2(100, 40)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 18
text = "100"
alignment = 1

[node name="GoldPlus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/GoldContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "+"

[node name="PopulationContainer" type="HBoxContainer" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid"]
layout_mode = 2

[node name="PopLabel" type="Label" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/PopulationContainer"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Population:"

[node name="PopMinus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/PopulationContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "-"

[node name="PopInput" type="LineEdit" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/PopulationContainer"]
custom_minimum_size = Vector2(100, 40)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 18
text = "50"
alignment = 1

[node name="PopPlus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/PopulationContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "+"

[node name="FoodContainer" type="HBoxContainer" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid"]
layout_mode = 2

[node name="FoodLabel" type="Label" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/FoodContainer"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Food:"

[node name="FoodMinus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/FoodContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "-"

[node name="FoodInput" type="LineEdit" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/FoodContainer"]
custom_minimum_size = Vector2(100, 40)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 18
text = "75"
alignment = 1

[node name="FoodPlus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/FoodContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "+"

[node name="WoodContainer" type="HBoxContainer" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid"]
layout_mode = 2

[node name="WoodLabel" type="Label" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/WoodContainer"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Wood:"

[node name="WoodMinus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/WoodContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "-"

[node name="WoodInput" type="LineEdit" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/WoodContainer"]
custom_minimum_size = Vector2(100, 40)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 18
text = "50"
alignment = 1

[node name="WoodPlus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/WoodContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "+"

[node name="StoneContainer" type="HBoxContainer" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid"]
layout_mode = 2

[node name="StoneLabel" type="Label" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/StoneContainer"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Stone:"

[node name="StoneMinus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/StoneContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "-"

[node name="StoneInput" type="LineEdit" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/StoneContainer"]
custom_minimum_size = Vector2(100, 40)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 18
text = "50"
alignment = 1

[node name="StonePlus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/StoneContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "+"

[node name="IronContainer" type="HBoxContainer" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid"]
layout_mode = 2

[node name="IronLabel" type="Label" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/IronContainer"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Iron:"

[node name="IronMinus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/IronContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "-"

[node name="IronInput" type="LineEdit" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/IronContainer"]
custom_minimum_size = Vector2(100, 40)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 18
text = "25"
alignment = 1

[node name="IronPlus" type="Button" parent="Panel/TabContainer/Town/ResourcesSection/ResourcesGrid/IronContainer"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "+"

[node name="Kingdom" type="VBoxContainer" parent="Panel/TabContainer"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="KingdomLabel" type="Label" parent="Panel/TabContainer/Kingdom"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "Choose Starting Kingdom:"
horizontal_alignment = 1

[node name="KingdomContainer" type="GridContainer" parent="Panel/TabContainer/Kingdom"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/h_separation = 12
theme_override_constants/v_separation = 12
columns = 3

[node name="GostinPanel" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer/GostinPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Kingdom/KingdomContainer/GostinPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="KingdomName" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/GostinPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Gostin"
horizontal_alignment = 1
clip_text = true

[node name="Region" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/GostinPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Mountain Realm"
horizontal_alignment = 1
clip_text = true

[node name="Trait1" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/GostinPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Mining"
horizontal_alignment = 1
clip_text = true

[node name="Trait2" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/GostinPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Defense"
horizontal_alignment = 1
clip_text = true

[node name="KelsinPanel" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer/KelsinPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Kingdom/KingdomContainer/KelsinPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="KingdomName" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/KelsinPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Kelsin"
horizontal_alignment = 1
clip_text = true

[node name="Region" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/KelsinPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Forest Kingdom"
horizontal_alignment = 1
clip_text = true

[node name="Trait1" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/KelsinPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Lumber"
horizontal_alignment = 1
clip_text = true

[node name="Trait2" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/KelsinPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Hunting"
horizontal_alignment = 1
clip_text = true

[node name="YozuanPanel" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer/YozuanPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Kingdom/KingdomContainer/YozuanPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="KingdomName" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/YozuanPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Yozuan"
horizontal_alignment = 1
clip_text = true

[node name="Region" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/YozuanPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Desert Empire"
horizontal_alignment = 1
clip_text = true

[node name="Trait1" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/YozuanPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Trade"
horizontal_alignment = 1
clip_text = true

[node name="Trait2" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/YozuanPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Endurance"
horizontal_alignment = 1
clip_text = true

[node name="RabaricPanel" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer/RabaricPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Kingdom/KingdomContainer/RabaricPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="KingdomName" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/RabaricPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Rabaric"
horizontal_alignment = 1
clip_text = true

[node name="Region" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/RabaricPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Volcanic Domain"
horizontal_alignment = 1
clip_text = true

[node name="Trait1" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/RabaricPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Smithing"
horizontal_alignment = 1
clip_text = true

[node name="Trait2" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/RabaricPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Military"
horizontal_alignment = 1
clip_text = true

[node name="ElRuhnPanel" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer/ElRuhnPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Kingdom/KingdomContainer/ElRuhnPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="KingdomName" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/ElRuhnPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "El-Ruhn"
horizontal_alignment = 1
clip_text = true

[node name="Region" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/ElRuhnPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Coastal Nation"
horizontal_alignment = 1
clip_text = true

[node name="Trait1" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/ElRuhnPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Fishing"
horizontal_alignment = 1
clip_text = true

[node name="Trait2" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/ElRuhnPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Naval"
horizontal_alignment = 1
clip_text = true

[node name="TzaludPanel" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Kingdom/KingdomContainer/TzaludPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Kingdom/KingdomContainer/TzaludPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="KingdomName" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/TzaludPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Tzalud"
horizontal_alignment = 1
clip_text = true

[node name="Region" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/TzaludPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Arcane Sanctuary"
horizontal_alignment = 1
clip_text = true

[node name="Trait1" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/TzaludPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Magic"
horizontal_alignment = 1
clip_text = true

[node name="Trait2" type="Label" parent="Panel/TabContainer/Kingdom/KingdomContainer/TzaludPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Research"
horizontal_alignment = 1
clip_text = true

[node name="Deity" type="VBoxContainer" parent="Panel/TabContainer"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="DeityLabel" type="Label" parent="Panel/TabContainer/Deity"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "Choose Patron Deity:"
horizontal_alignment = 1

[node name="DeityContainer" type="GridContainer" parent="Panel/TabContainer/Deity"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/h_separation = 12
theme_override_constants/v_separation = 12
columns = 3

[node name="NivariusPanel" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer/NivariusPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Deity/DeityContainer/NivariusPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="DeityName" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/NivariusPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Nivarius"
horizontal_alignment = 1
clip_text = true

[node name="DeityTitle" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/NivariusPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "God of Mysteries"
horizontal_alignment = 1
clip_text = true

[node name="Bonus1" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/NivariusPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Magic"
horizontal_alignment = 1
clip_text = true

[node name="Bonus2" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/NivariusPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Wisdom"
horizontal_alignment = 1
clip_text = true

[node name="SeraPanel" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer/SeraPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Deity/DeityContainer/SeraPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="DeityName" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/SeraPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Seraphina"
horizontal_alignment = 1
clip_text = true

[node name="DeityTitle" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/SeraPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Goddess of Light"
horizontal_alignment = 1
clip_text = true

[node name="Bonus1" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/SeraPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Diplomacy"
horizontal_alignment = 1
clip_text = true

[node name="Bonus2" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/SeraPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Faith"
horizontal_alignment = 1
clip_text = true

[node name="FortPanel" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer/FortPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Deity/DeityContainer/FortPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="DeityName" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/FortPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Fortane"
horizontal_alignment = 1
clip_text = true

[node name="DeityTitle" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/FortPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "God of War"
horizontal_alignment = 1
clip_text = true

[node name="Bonus1" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/FortPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Strength"
horizontal_alignment = 1
clip_text = true

[node name="Bonus2" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/FortPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Endurance"
horizontal_alignment = 1
clip_text = true

[node name="ThornPanel" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer/ThornPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Deity/DeityContainer/ThornPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="DeityName" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/ThornPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Thorn"
horizontal_alignment = 1
clip_text = true

[node name="DeityTitle" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/ThornPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "God of Nature"
horizontal_alignment = 1
clip_text = true

[node name="Bonus1" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/ThornPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Survival"
horizontal_alignment = 1
clip_text = true

[node name="Bonus2" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/ThornPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Crafting"
horizontal_alignment = 1
clip_text = true

[node name="AureliaPanel" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer/AureliaPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Deity/DeityContainer/AureliaPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="DeityName" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/AureliaPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Aurelia"
horizontal_alignment = 1
clip_text = true

[node name="DeityTitle" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/AureliaPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Goddess of Fortune"
horizontal_alignment = 1
clip_text = true

[node name="Bonus1" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/AureliaPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Wealth"
horizontal_alignment = 1
clip_text = true

[node name="Bonus2" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/AureliaPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Trade"
horizontal_alignment = 1
clip_text = true

[node name="ZephraPanel" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer"]
custom_minimum_size = Vector2(200, 120)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Outline" type="Panel" parent="Panel/TabContainer/Deity/DeityContainer/ZephraPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_styles/panel = SubResource("1")

[node name="Content" type="VBoxContainer" parent="Panel/TabContainer/Deity/DeityContainer/ZephraPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
alignment = 1
theme_override_constants/separation = 4

[node name="DeityName" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/ZephraPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Zephra"
horizontal_alignment = 1
clip_text = true

[node name="DeityTitle" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/ZephraPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "Goddess of Winds"
horizontal_alignment = 1
clip_text = true

[node name="Bonus1" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/ZephraPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+2 Speed"
horizontal_alignment = 1
clip_text = true

[node name="Bonus2" type="Label" parent="Panel/TabContainer/Deity/DeityContainer/ZephraPanel/Content"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "+1 Exploration"
horizontal_alignment = 1
clip_text = true

[node name="Map" type="VBoxContainer" parent="Panel/TabContainer"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="MapLabel" type="Label" parent="Panel/TabContainer/Map"]
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "World Map"
horizontal_alignment = 1

[node name="MapContainer" type="Control" parent="Panel/TabContainer/Map"]
clip_contents = true
layout_mode = 2
size_flags_vertical = 3

[node name="MapBackground" type="TextureRect" parent="Panel/TabContainer/Map/MapContainer"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
texture = ExtResource("3")
expand_mode = 1
stretch_mode = 5

[node name="ActionButtons" type="HBoxContainer" parent="Panel"]
layout_mode = 1
anchor_left = 0.28
anchor_top = 0.91
anchor_right = 0.72
anchor_bottom = 0.97
theme_override_constants/separation = 40

[node name="BackButton" type="Button" parent="Panel/ActionButtons"]
custom_minimum_size = Vector2(180, 60)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 20
text = "Back"

[node name="StartButton" type="Button" parent="Panel/ActionButtons"]
custom_minimum_size = Vector2(180, 60)
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 20
text = "Start"
"""

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)

print("Full screen panel with 10px gaps created successfully")
