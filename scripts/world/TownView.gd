extends Control
# TownView.gd - Main town building and management view

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"

# Character data (loaded from previous scene)
var lord_name: String = "Lord Unknown"
var town_name: String = "New Settlement"
var deity_name: String = "None"

# Resource values
var gold: int = 500
var wood: int = 200
var stone: int = 150
var iron: int = 0
var food: int = 100
var population: int = 10

# Grid settings
const GRID_SIZE: int = 20  # 20x20 grid
const CELL_SIZE: float = 2.0  # 2 meters per cell

# Node references - Top bar
@onready var lord_name_value: Label = $PageContainer/TopBar/LordInfo/LordNameValue
@onready var town_name_value: Label = $PageContainer/TopBar/LordInfo/TownNameValue
@onready var deity_value: Label = $PageContainer/TopBar/LordInfo/DeityValue

@onready var gold_value: Label = $PageContainer/TopBar/Resources/GoldDisplay/GoldValue
@onready var wood_value: Label = $PageContainer/TopBar/Resources/WoodDisplay/WoodValue
@onready var stone_value: Label = $PageContainer/TopBar/Resources/StoneDisplay/StoneValue
@onready var iron_value: Label = $PageContainer/TopBar/Resources/IronDisplay/IronValue
@onready var food_value: Label = $PageContainer/TopBar/Resources/FoodDisplay/FoodValue
@onready var population_value: Label = $PageContainer/TopBar/Resources/PopulationDisplay/PopulationValue

# Hover tooltip
@onready var hover_tooltip: PanelContainer = $PageContainer/HoverTooltip
@onready var tooltip_title: Label = $PageContainer/HoverTooltip/TooltipMargin/TooltipContent/TooltipTitle
@onready var tooltip_desc: Label = $PageContainer/HoverTooltip/TooltipMargin/TooltipContent/TooltipDesc
@onready var tooltip_cost: Label = $PageContainer/HoverTooltip/TooltipMargin/TooltipContent/TooltipCost
@onready var tooltip_benefit: Label = $PageContainer/HoverTooltip/TooltipMargin/TooltipContent/TooltipBenefit

@onready var town_scene: Node3D = $PageContainer/ContentContainer/CenterView/SubViewport/TownScene
@onready var grid_plane: MeshInstance3D = $PageContainer/ContentContainer/CenterView/SubViewport/TownScene/GridPlane

# Building buttons
@onready var academy_btn: Button = $PageContainer/ContentContainer/LeftPanel/BuildingList/AcademyPanel/AcademyButton
@onready var temple_btn: Button = $PageContainer/ContentContainer/LeftPanel/BuildingList/TemplePanel/TempleButton
@onready var guild_btn: Button = $PageContainer/ContentContainer/LeftPanel/BuildingList/GuildPanel/GuildButton
@onready var bank_btn: Button = $PageContainer/ContentContainer/LeftPanel/BuildingList/BankPanel/BankButton
@onready var cottage_btn: Button = $PageContainer/ContentContainer/LeftPanel/BuildingList/CottagePanel/CottageButton
@onready var estate_btn: Button = $PageContainer/ContentContainer/LeftPanel/BuildingList/EstatePanel/EstateButton
@onready var manor_btn: Button = $PageContainer/ContentContainer/LeftPanel/BuildingList/ManorPanel/ManorButton

# Building data
var building_data = {
	"Academy": {
		"model": "res://assets/buildings/School.glb",
		"description": "A place of learning and research. Trains scholars and provides knowledge bonuses.",
		"cost": {"gold": 200, "wood": 100, "stone": 150},
		"upkeep": 10,
		"benefit": "+5 Knowledge per turn"
	},
	"Temple": {
		"model": "res://assets/buildings/Temple.glb",
		"description": "A sacred place of worship. Provides spiritual guidance and healing.",
		"cost": {"gold": 150, "wood": 80, "stone": 200},
		"upkeep": 8,
		"benefit": "+3 Faith, +2 Health per turn"
	},
	"Adventurer's Guild": {
		"model": "res://assets/buildings/Guild.glb",
		"description": "Headquarters for adventurers. Recruits heroes and manages expeditions.",
		"cost": {"gold": 250, "wood": 120, "stone": 100},
		"upkeep": 15,
		"benefit": "Recruit adventurers, +2 Quest capacity"
	},
	"Bank": {
		"model": "res://assets/buildings/Bank.glb",
		"description": "Manages town finances and trade. Increases gold income.",
		"cost": {"gold": 300, "wood": 50, "stone": 150},
		"upkeep": 12,
		"benefit": "+20 Gold per turn"
	},
	"Cottage": {
		"model": "res://assets/buildings/Cottage.glb",
		"description": "Simple housing for common folk. Increases population capacity.",
		"cost": {"gold": 50, "wood": 80, "stone": 30},
		"upkeep": 5,
		"benefit": "+10 Population capacity"
	},
	"Estate": {
		"model": "res://assets/buildings/Estate.glb",
		"description": "Housing for wealthy citizens. Attracts skilled workers.",
		"cost": {"gold": 150, "wood": 100, "stone": 80},
		"upkeep": 8,
		"benefit": "+5 Population, +2 Skilled workers"
	},
	"Lord's Manor": {
		"model": "res://assets/buildings/Manor.glb",
		"description": "Luxurious residence for nobility. Increases town prestige significantly.",
		"cost": {"gold": 400, "wood": 150, "stone": 250},
		"upkeep": 20,
		"benefit": "+10 Prestige, +5% Tax income"
	}
}

var selected_building: String = ""

func _ready() -> void:
	print("[TownView] _ready")
	_create_grid_plane()
	_setup_building_previews()
	_update_all_displays()
	_connect_buttons()

func _update_all_displays() -> void:
	# Update lord/town info
	lord_name_value.text = lord_name
	town_name_value.text = town_name
	deity_value.text = deity_name
	
	# Update resources
	_update_resource_display()

func _update_resource_display() -> void:
	gold_value.text = str(gold)
	wood_value.text = str(wood)
	stone_value.text = str(stone)
	iron_value.text = str(iron)
	food_value.text = str(food)
	population_value.text = str(population)

func _create_grid_plane() -> void:
	# Create a plane mesh with grid texture
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE)
	plane_mesh.subdivide_width = GRID_SIZE
	plane_mesh.subdivide_depth = GRID_SIZE
	
	grid_plane.mesh = plane_mesh
	
	# Create material with grid lines
	var grid_material := StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.85, 0.82, 0.7, 1.0)  # Parchment color
	grid_material.metallic = 0.0
	grid_material.roughness = 1.0
	
	# Create grid texture
	var grid_texture := _create_grid_texture()
	grid_material.albedo_texture = grid_texture
	grid_material.uv1_scale = Vector3(GRID_SIZE, GRID_SIZE, 1)
	
	grid_plane.material_override = grid_material
	
	print("[TownView] Created ", GRID_SIZE, "x", GRID_SIZE, " grid with ", CELL_SIZE, "m cells")

func _create_grid_texture() -> ImageTexture:
	# Create a small texture with grid lines
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.85, 0.82, 0.7, 1.0))  # Base parchment color
	
	# Draw grid lines
	var grid_color := Color(0.6, 0.55, 0.4, 1.0)  # Darker brown for lines
	for x in range(64):
		img.set_pixel(x, 0, grid_color)
		img.set_pixel(x, 63, grid_color)
	for y in range(64):
		img.set_pixel(0, y, grid_color)
		img.set_pixel(63, y, grid_color)
	
	var texture := ImageTexture.create_from_image(img)
	return texture

func _setup_building_previews() -> void:
	# Setup isometric camera and building model for each preview viewport
	var viewports = {
		"Academy": get_node_or_null("PageContainer/ContentContainer/LeftPanel/BuildingList/AcademyPanel/AcademyButton/AcademyContent/AcademyPreview/AcademySubViewport"),
		"Temple": get_node_or_null("PageContainer/ContentContainer/LeftPanel/BuildingList/TemplePanel/TempleButton/TempleContent/TemplePreview/TempleSubViewport"),
		"Guild": get_node_or_null("PageContainer/ContentContainer/LeftPanel/BuildingList/GuildPanel/GuildButton/GuildContent/GuildPreview/GuildSubViewport"),
		"Bank": get_node_or_null("PageContainer/ContentContainer/LeftPanel/BuildingList/BankPanel/BankButton/BankContent/BankPreview/BankSubViewport"),
		"Cottage": get_node_or_null("PageContainer/ContentContainer/LeftPanel/BuildingList/CottagePanel/CottageButton/CottageContent/CottagePreview/CottageSubViewport"),
		"Estate": get_node_or_null("PageContainer/ContentContainer/LeftPanel/BuildingList/EstatePanel/EstateButton/EstateContent/EstatePreview/EstateSubViewport"),
		"Manor": get_node_or_null("PageContainer/ContentContainer/LeftPanel/BuildingList/ManorPanel/ManorButton/ManorContent/ManorPreview/ManorSubViewport")
	}
	
	for building_name in viewports:
		var viewport = viewports[building_name]
		if viewport:
			var model_path = building_data[building_name if building_name != "Guild" else "Adventurer's Guild"]["model"]
			_setup_preview_viewport(viewport, model_path)

func _setup_preview_viewport(viewport: SubViewport, model_path: String) -> void:
	# Create scene container
	var scene_root := Node3D.new()
	viewport.add_child(scene_root)
	
	# Add isometric camera
	var camera := Camera3D.new()
	camera.projection = 1  # PROJECTION_ORTHOGRAPHIC
	camera.size = 3.0
	camera.transform = Transform3D(
		Vector3(0.707107, -0.408248, 0.57735),
		Vector3(0, 0.816497, 0.57735),
		Vector3(-0.707107, -0.408248, 0.57735),
		Vector3(0, 3, 0)
	)
	scene_root.add_child(camera)
	
	# Add light
	var light := DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.look_at(Vector3.ZERO, Vector3.UP)
	scene_root.add_child(light)
	
	# Load and add building model
	if ResourceLoader.exists(model_path):
		var building_scene = load(model_path)
		if building_scene:
			var building_instance = building_scene.instantiate()
			scene_root.add_child(building_instance)
			print("[TownView] Loaded preview: ", model_path)

func _connect_buttons() -> void:
	# Connect building selection
	academy_btn.pressed.connect(_on_building_clicked.bind("Academy"))
	temple_btn.pressed.connect(_on_building_clicked.bind("Temple"))
	guild_btn.pressed.connect(_on_building_clicked.bind("Adventurer's Guild"))
	bank_btn.pressed.connect(_on_building_clicked.bind("Bank"))
	cottage_btn.pressed.connect(_on_building_clicked.bind("Cottage"))
	estate_btn.pressed.connect(_on_building_clicked.bind("Estate"))
	manor_btn.pressed.connect(_on_building_clicked.bind("Lord's Manor"))
	
	# Connect hover events for tooltips
	academy_btn.mouse_entered.connect(_on_building_hover.bind("Academy"))
	temple_btn.mouse_entered.connect(_on_building_hover.bind("Temple"))
	guild_btn.mouse_entered.connect(_on_building_hover.bind("Adventurer's Guild"))
	bank_btn.mouse_entered.connect(_on_building_hover.bind("Bank"))
	cottage_btn.mouse_entered.connect(_on_building_hover.bind("Cottage"))
	estate_btn.mouse_entered.connect(_on_building_hover.bind("Estate"))
	manor_btn.mouse_entered.connect(_on_building_hover.bind("Lord's Manor"))
	
	academy_btn.mouse_exited.connect(_on_building_unhover)
	temple_btn.mouse_exited.connect(_on_building_unhover)
	guild_btn.mouse_exited.connect(_on_building_unhover)
	bank_btn.mouse_exited.connect(_on_building_unhover)
	cottage_btn.mouse_exited.connect(_on_building_unhover)
	estate_btn.mouse_exited.connect(_on_building_unhover)
	manor_btn.mouse_exited.connect(_on_building_unhover)

func _on_building_hover(building_name: String) -> void:
	var data = building_data[building_name]
	tooltip_title.text = building_name
	tooltip_desc.text = data["description"]
	
	var cost_str = "Cost: "
	if data["cost"].has("gold"): cost_str += str(data["cost"]["gold"]) + "g "
	if data["cost"].has("wood"): cost_str += str(data["cost"]["wood"]) + "w "
	if data["cost"].has("stone"): cost_str += str(data["cost"]["stone"]) + "s"
	tooltip_cost.text = cost_str
	
	tooltip_benefit.text = "Benefit: " + data["benefit"]
	hover_tooltip.visible = true

func _on_building_unhover() -> void:
	hover_tooltip.visible = false

func _on_building_clicked(building_name: String) -> void:
	selected_building = building_name
	var data = building_data[building_name]
	
	# Check if player can afford
	var can_afford = true
	if data["cost"].has("gold") and gold < data["cost"]["gold"]: can_afford = false
	if data["cost"].has("wood") and wood < data["cost"]["wood"]: can_afford = false
	if data["cost"].has("stone") and stone < data["cost"]["stone"]: can_afford = false
	
	if not can_afford:
		print("[TownView] Cannot afford ", building_name)
		return
	
	# Deduct resources
	if data["cost"].has("gold"): gold -= data["cost"]["gold"]
	if data["cost"].has("wood"): wood -= data["cost"]["wood"]
	if data["cost"].has("stone"): stone -= data["cost"]["stone"]
	
	_update_resource_display()
	
	# Load and place building model
	var building_scene = load(data["model"])
	if building_scene:
		var building_instance = building_scene.instantiate()
		town_scene.add_child(building_instance)
		# Position at grid center for now (TODO: implement drag & drop)
		building_instance.position = Vector3(0, 0, 0)
		print("[TownView] Placed building: ", selected_building)
