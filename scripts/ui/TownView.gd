extends Control
# TownView.gd - Main town building and management view

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"

const RunCodeUtil = preload("res://scripts/run/RunCode.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")
const SimClockScript = preload("res://scripts/world/SimClock.gd")
const DungeonThreatSystemScript = preload("res://scripts/world/DungeonThreatSystem.gd")
const ExpeditionBoardScript = preload("res://scripts/world/ExpeditionBoard.gd")
const AutonomousExpeditionsScript = preload("res://scripts/world/AutonomousExpeditions.gd")
const KingdomRegionTextureGeneratorScript = preload("res://scripts/world/KingdomRegionTextureGenerator.gd")
const CharacterAppearanceRecipeScript = preload("res://scripts/appearance/CharacterAppearanceRecipe.gd")

const FlyCameraScript := preload("res://addons/sk_fly_camera/src/fly_camera.gd")
const WorldmapViewScript := preload("res://addons/worldmap_builder/nodes/worldmap_view.gd")
const WorldmapGraphScript := preload("res://addons/worldmap_builder/nodes/worldmap_graph.gd")
const WorldmapNodeDataScript := preload("res://addons/worldmap_builder/resource_types/worldmap_node_data.gd")

const IsoTownPreviewScene := preload("res://scenes/world/iso/IsoTownPreview.tscn")


const CivilianPlannerGOAPScript = preload("res://scripts/ai/town/CivilianPlannerGOAP.gd")
const EnemyBrainLimboScript = preload("res://scripts/ai/enemy/EnemyBrainLimbo.gd")

# Character data (loaded from previous scene)
var lord_name: String = "Lord Unknown"
var town_name: String = "New Settlement"
var deity_name: String = "None"

var run_code: String = ""
var run_log_path: String = ""
var kingdom_id: int = 0

var _clock: SimClock
var _dungeons: DungeonThreatSystem
var _jobs: ExpeditionBoard
var _expeditions: AutonomousExpeditions

var _town_ai: CivilianPlannerGOAP
var _civilians: Array[Dictionary] = []
var _raid_root: Node

var sim_seconds_per_day: float = 30.0
var extra_dungeon_spawn_chance_per_day: float = 0.0

const BASE_SECONDS_PER_DAY: float = 30.0
const SPEED_STEPS: Array[int] = [1, 2, 5, 10]
var sim_speed_multiplier: int = 1

@export var use_isometric_level: bool = true
@export var iso_map_size: Vector2i = Vector2i(64, 64)

# Resource values
var gold: int = 500
var wood: int = 200
var stone: int = 150
var iron: int = 0
var food: int = 100
var population: int = 10

const TAB_BAR_WIDTH: float = 32.0
const TAB_BAR_PEEK_WIDTH: float = 16.0

const ACTION_SPEED_DOWN := "arx_speed_down"
const ACTION_SPEED_UP := "arx_speed_up"
const ACTION_PAUSE_TOGGLE := "arx_pause_toggle"
const ACTION_TABS_TOGGLE := "arx_tabs_toggle"
const ACTION_BUILD_MENU_TOGGLE := "arx_build_menu_toggle"

const ACTION_MENU_BUILD := "arx_menu_build"
const ACTION_MENU_LORD := "arx_menu_lord"
const ACTION_MENU_CITY := "arx_menu_city"
const ACTION_MENU_GUILD := "arx_menu_guild"
const ACTION_MENU_SETTINGS := "arx_menu_settings"

const ACTION_CAMERA_TOGGLE := "arx_camera_toggle"

# Grid settings
const GRID_SIZE: int = 20  # 20x20 grid
const CELL_SIZE: float = 2.0  # 2 meters per cell

# Node references - Top bar
@onready var lord_name_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/InfoCenter/InfoRow/LordValue
@onready var town_name_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/InfoCenter/InfoRow/TownValue
@onready var deity_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/InfoCenter/InfoRow/DeityValue

@onready var gold_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/ResourcesCenter/ResourcesRow/GoldBox/Value
@onready var wood_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/ResourcesCenter/ResourcesRow/WoodBox/Value
@onready var stone_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/ResourcesCenter/ResourcesRow/StoneBox/Value
@onready var iron_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/ResourcesCenter/ResourcesRow/IronBox/Value
@onready var food_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/ResourcesCenter/ResourcesRow/FoodBox/Value
@onready var population_value: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/RightCenter/RightVBox/ResourcesCenter/ResourcesRow/PopBox/Value

@onready var portrait_rig: Node2D = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/TopBarContent/PortraitFrame/PortraitMargin/PortraitContainer/PortraitViewport/PortraitRig

@onready var left_icon_bar: Control = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar
@onready var tabs_toggle_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/TabsToggle
@onready var buildings_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/BuildingsIcon

@onready var lord_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/LordIcon
@onready var city_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/CityIcon
@onready var guild_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/GuildIcon
@onready var skills_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/SkillsIcon
@onready var expeditions_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/ExpeditionsIcon
@onready var economy_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/EconomyIcon
@onready var reports_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/ReportsIcon
@onready var temple_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/TempleIcon
@onready var settings_icon_btn: Button = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/LeftIconBar/IconMargin/IconCenter/IconVBox/SettingsIcon

@onready var build_bar: Control = $PageContainer/BuildBar
@onready var build_bar_hbox: HBoxContainer = $PageContainer/BuildBar/BuildBarMargin/BuildBarScroll/BuildBarHBox

@onready var feature_popup: PanelContainer = $PageContainer/FeaturePopup
@onready var feature_title: Label = $PageContainer/FeaturePopup/FeatureMargin/FeatureVBox/FeatureTitle
@onready var feature_buttons: VBoxContainer = $PageContainer/FeaturePopup/FeatureMargin/FeatureVBox/FeatureButtons

@onready var map_overlay: Control = $PageContainer/MapOverlay
@onready var map_close_btn: Button = $PageContainer/MapOverlay/MapMargin/MapVBox/MapHeader/MapClose

@onready var lord_overlay: Control = $PageContainer/LordOverlay
@onready var lord_close_btn: Button = $PageContainer/LordOverlay/LordMargin/LordVBox/LordHeader/LordClose
@onready var lord_skills_btn: Button = $PageContainer/LordOverlay/LordMargin/LordVBox/LordPanel/LordPanelMargin/LordButtons/LordSkillsBtn

@onready var institutions_overlay: Control = $PageContainer/InstitutionsOverlay
@onready var institutions_close_btn: Button = $PageContainer/InstitutionsOverlay/InstitutionsMargin/InstitutionsVBox/InstitutionsHeader/InstitutionsClose
@onready var inst_temple_btn: Button = $PageContainer/InstitutionsOverlay/InstitutionsMargin/InstitutionsVBox/InstitutionsPanel/InstitutionsPanelMargin/InstitutionsButtons/InstTempleBtn

@onready var temple_overlay: Control = $PageContainer/TempleOverlay
@onready var temple_close_btn: Button = $PageContainer/TempleOverlay/TempleMargin/TempleVBox/TempleHeader/TempleClose

@onready var economy_overlay: Control = $PageContainer/EconomyOverlay
@onready var economy_close_btn: Button = $PageContainer/EconomyOverlay/EconomyMargin/EconomyVBox/EconomyHeader/EconomyClose
@onready var economy_summary_label: Label = $PageContainer/EconomyOverlay/EconomyMargin/EconomyVBox/EconomyPanel/EconomyPanelMargin/EconomySummary

@onready var expeditions_overlay: Control = $PageContainer/ExpeditionsOverlay
@onready var expeditions_close_btn: Button = $PageContainer/ExpeditionsOverlay/ExpeditionsMargin/ExpeditionsVBox/ExpeditionsHeader/ExpeditionsClose
@onready var expeditions_last_label: Label = $PageContainer/ExpeditionsOverlay/ExpeditionsMargin/ExpeditionsVBox/ExpeditionsPanel/ExpeditionsPanelMargin/ExpeditionsLast

@onready var reports_overlay: Control = $PageContainer/ReportsOverlay
@onready var reports_close_btn: Button = $PageContainer/ReportsOverlay/ReportsMargin/ReportsVBox/ReportsHeader/ReportsClose

@onready var settings_overlay: Control = $PageContainer/SettingsOverlay
@onready var settings_close_btn: Button = $PageContainer/SettingsOverlay/SettingsMargin/SettingsVBox/SettingsHeader/SettingsClose
@onready var settings_save_btn: Button = $PageContainer/SettingsOverlay/SettingsMargin/SettingsVBox/SettingsPanel/SettingsPanelMargin/SettingsButtons/SettingsSaveBtn
@onready var settings_reload_btn: Button = $PageContainer/SettingsOverlay/SettingsMargin/SettingsVBox/SettingsPanel/SettingsPanelMargin/SettingsButtons/SettingsReloadBtn
@onready var settings_main_menu_btn: Button = $PageContainer/SettingsOverlay/SettingsMargin/SettingsVBox/SettingsPanel/SettingsPanelMargin/SettingsButtons/SettingsMainMenuBtn
@onready var settings_quit_btn: Button = $PageContainer/SettingsOverlay/SettingsMargin/SettingsVBox/SettingsPanel/SettingsPanelMargin/SettingsButtons/SettingsQuitBtn

@onready var skill_overlay: Control = $PageContainer/SkillTreeOverlay
@onready var skill_close_btn: Button = $PageContainer/SkillTreeOverlay/SkillMargin/SkillVBox/SkillHeader/SkillClose
@onready var skill_host: Control = $PageContainer/SkillTreeOverlay/SkillMargin/SkillVBox/SkillPanel/SkillHost
@onready var skill_fallback: Label = $PageContainer/SkillTreeOverlay/SkillMargin/SkillVBox/SkillPanel/SkillHost/SkillFallback
@onready var skill_tab_prov: Button = $PageContainer/SkillTreeOverlay/SkillMargin/SkillVBox/SkillTabs/TabProvisioning
@onready var skill_tab_gov: Button = $PageContainer/SkillTreeOverlay/SkillMargin/SkillVBox/SkillTabs/TabGovernance
@onready var skill_tab_craft: Button = $PageContainer/SkillTreeOverlay/SkillMargin/SkillVBox/SkillTabs/TabCrafting

@onready var town_camera: Camera3D = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/CenterView/SubViewport/TownScene/Camera3D
@onready var town_subviewport: SubViewport = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/CenterView/SubViewport

# Time widget (top bar, right side)
@onready var time_value_label: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/TopBarContent/TopRight/TimeWidget/TimeMargin/TimeHBox/TimeInfo/TimeValue
@onready var date_value_label: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/TopBarContent/TopRight/TimeWidget/TimeMargin/TimeHBox/TimeInfo/DateValue
@onready var season_value_label: Label = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/TopBarContent/TopRight/TimeWidget/TimeMargin/TimeHBox/TimeInfo/SeasonValue

@onready var speed_slow_btn: Button = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/TopBarContent/TopRight/TimeWidget/TimeMargin/TimeHBox/TimeControls/Buttons/SlowBtn
@onready var speed_normal_btn: Button = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/TopBarContent/TopRight/TimeWidget/TimeMargin/TimeHBox/TimeControls/Buttons/NormalBtn
@onready var speed_fast_btn: Button = $PageContainer/ContentMargin/MainVBox/TopBarBackground/TopBarMargin/TopBarContent/TopRight/TimeWidget/TimeMargin/TimeHBox/TimeControls/Buttons/FastBtn

# Hover tooltip
@onready var hover_tooltip: PanelContainer = $PageContainer/HoverTooltip
@onready var tooltip_title: Label = $PageContainer/HoverTooltip/TooltipMargin/TooltipContent/TooltipTitle
@onready var tooltip_desc: Label = $PageContainer/HoverTooltip/TooltipMargin/TooltipContent/TooltipDesc
@onready var tooltip_cost: Label = $PageContainer/HoverTooltip/TooltipMargin/TooltipContent/TooltipCost
@onready var tooltip_benefit: Label = $PageContainer/HoverTooltip/TooltipMargin/TooltipContent/TooltipBenefit

@onready var town_scene: Node3D = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/CenterView/SubViewport/TownScene
@onready var grid_plane: MeshInstance3D = $PageContainer/ContentMargin/MainVBox/ContentHBox/MapLayer/CenterView/SubViewport/TownScene/GridPlane

var _iso_level: Node2D

var _tab_bar_open: bool = true
var _sim_paused: bool = false

var _active_side_panel_id: String = ""

var _freecam: CharacterBody3D
var _skill_view: Control
var _skill_graphs: Dictionary = {}
var _active_skill_category: String = "provisioning"
var _freecam_active: bool = false

var _build_buttons_by_name: Dictionary = {}

enum CameraMode { ISO, FREECAM }
var _camera_mode: int = CameraMode.ISO

var _overlay_forces_iso: bool = false
var _camera_mode_before_overlay: int = CameraMode.ISO

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
	_ensure_default_hotkeys()
	_load_save_data()
	_sim_speed_sync_from_seconds()
	_apply_lord_portrait_from_run_code()
	_setup_isometric_level()
	if not use_isometric_level:
		_create_grid_plane()
	_update_all_displays()
	_connect_buttons()
	_setup_sim_systems()
	_connect_left_icons()
	_connect_tab_toggle()
	_set_tab_bar_open(true, false)
	_update_time_widget()
	_ensure_menu_close_buttons()
	set_process_unhandled_input(true)
	_setup_skills_overlay()
	_connect_management_overlays()
	_ensure_freecam_ready()
	_set_camera_mode(CameraMode.ISO)
	_update_economy_overlay_text()
	# Ensure we start with no side menus open.
	_close_all_side_panels()


func _setup_isometric_level_seed() -> int:
	if run_code.strip_edges() != "" and RunCodeUtil.is_run_code(run_code):
		return int(RunCodeUtil.seed_from_code(run_code + "|iso_town"))
	return int(RunCodeUtil.seed_from_code("fallback|iso_town"))


func _setup_isometric_level() -> void:
	if not use_isometric_level:
		return
	if town_subviewport == null:
		push_warning("[TownView] Missing CenterView/SubViewport; cannot attach isometric level")
		return

	# Ensure the SubViewport routes mouse/keys properly to 2D children.
	town_subviewport.disable_3d = true
	town_subviewport.disable_2d = false
	town_subviewport.handle_input_locally = true

	# Keep the existing 3D nodes around (so nothing else breaks), but hide them.
	if town_scene != null:
		town_scene.visible = false
	if grid_plane != null:
		grid_plane.visible = false

	# Recreate if already present (e.g. re-entering scene).
	if is_instance_valid(_iso_level):
		_iso_level.queue_free()
		_iso_level = null

	var inst := IsoTownPreviewScene.instantiate()
	_iso_level = inst as Node2D
	if _iso_level == null:
		push_warning("[TownView] IsoTownPreview scene did not instance as Node2D")
		return

	# Configure generator from current run.
	if _iso_level.has_method("set"):
		_iso_level.set("map_size", iso_map_size)
		_iso_level.set("world_seed", _setup_isometric_level_seed())

	# Attach under the same center viewport used by the 3D town.
	town_subviewport.add_child(_iso_level)


func _connect_management_overlays() -> void:
	if lord_close_btn != null:
		_ensure_close_button_is_x(lord_close_btn)
		var cb_lc := Callable(self, "_on_lord_close_pressed")
		if not lord_close_btn.pressed.is_connected(cb_lc):
			lord_close_btn.pressed.connect(cb_lc)
	if lord_skills_btn != null:
		var cb_ls := Callable(self, "_on_lord_skills_pressed")
		if not lord_skills_btn.pressed.is_connected(cb_ls):
			lord_skills_btn.pressed.connect(cb_ls)

	if institutions_close_btn != null:
		_ensure_close_button_is_x(institutions_close_btn)
		var cb_ic := Callable(self, "_on_institutions_close_pressed")
		if not institutions_close_btn.pressed.is_connected(cb_ic):
			institutions_close_btn.pressed.connect(cb_ic)
	if inst_temple_btn != null:
		var cb_it := Callable(self, "_on_inst_temple_pressed")
		if not inst_temple_btn.pressed.is_connected(cb_it):
			inst_temple_btn.pressed.connect(cb_it)

	if temple_close_btn != null:
		_ensure_close_button_is_x(temple_close_btn)
		var cb_tc := Callable(self, "_on_temple_close_pressed")
		if not temple_close_btn.pressed.is_connected(cb_tc):
			temple_close_btn.pressed.connect(cb_tc)

	if economy_close_btn != null:
		_ensure_close_button_is_x(economy_close_btn)
		var cb_ec := Callable(self, "_on_economy_close_pressed")
		if not economy_close_btn.pressed.is_connected(cb_ec):
			economy_close_btn.pressed.connect(cb_ec)

	if expeditions_close_btn != null:
		_ensure_close_button_is_x(expeditions_close_btn)
		var cb_xc := Callable(self, "_on_expeditions_close_pressed")
		if not expeditions_close_btn.pressed.is_connected(cb_xc):
			expeditions_close_btn.pressed.connect(cb_xc)

	if reports_close_btn != null:
		_ensure_close_button_is_x(reports_close_btn)
		var cb_rc := Callable(self, "_on_reports_close_pressed")
		if not reports_close_btn.pressed.is_connected(cb_rc):
			reports_close_btn.pressed.connect(cb_rc)

	if settings_close_btn != null:
		_ensure_close_button_is_x(settings_close_btn)
		var cb_sc := Callable(self, "_on_settings_close_pressed")
		if not settings_close_btn.pressed.is_connected(cb_sc):
			settings_close_btn.pressed.connect(cb_sc)
	if settings_save_btn != null:
		var cb_ss := Callable(self, "_on_settings_save_pressed")
		if not settings_save_btn.pressed.is_connected(cb_ss):
			settings_save_btn.pressed.connect(cb_ss)
	if settings_reload_btn != null:
		var cb_sr := Callable(self, "_on_settings_reload_pressed")
		if not settings_reload_btn.pressed.is_connected(cb_sr):
			settings_reload_btn.pressed.connect(cb_sr)
	if settings_main_menu_btn != null:
		var cb_sm := Callable(self, "_on_settings_main_menu_pressed")
		if not settings_main_menu_btn.pressed.is_connected(cb_sm):
			settings_main_menu_btn.pressed.connect(cb_sm)
	if settings_quit_btn != null:
		var cb_sq := Callable(self, "_on_settings_quit_pressed")
		if not settings_quit_btn.pressed.is_connected(cb_sq):
			settings_quit_btn.pressed.connect(cb_sq)


func _hide_build_mode_if_open() -> void:
	if build_bar != null and build_bar.visible:
		build_bar.visible = false
		_set_freecam_active(false)


func _hide_all_overlays() -> void:
	if feature_popup != null:
		feature_popup.visible = false
	if map_overlay != null:
		map_overlay.visible = false
	if skill_overlay != null:
		skill_overlay.visible = false
	if lord_overlay != null:
		lord_overlay.visible = false
	if institutions_overlay != null:
		institutions_overlay.visible = false
	if temple_overlay != null:
		temple_overlay.visible = false
	if economy_overlay != null:
		economy_overlay.visible = false
	if expeditions_overlay != null:
		expeditions_overlay.visible = false
	if reports_overlay != null:
		reports_overlay.visible = false
	if settings_overlay != null:
		settings_overlay.visible = false


func _update_economy_overlay_text() -> void:
	if economy_summary_label == null:
		return
	economy_summary_label.text = "Gold: %d\nWood: %d\nStone: %d\nIron: %d\nFood: %d\nPopulation: %d" % [gold, wood, stone, iron, food, population]


func _on_lord_close_pressed() -> void:
	_close_side_panel("lord")


func _on_lord_skills_pressed() -> void:
	# Swap to the skill tree overlay.
	_open_side_panel("skills")


func _on_institutions_close_pressed() -> void:
	_close_side_panel("institutions")


func _on_inst_temple_pressed() -> void:
	_open_side_panel("temple")


func _on_economy_close_pressed() -> void:
	_close_side_panel("economy")


func _on_expeditions_close_pressed() -> void:
	_close_side_panel("expeditions")


func _on_reports_close_pressed() -> void:
	_close_side_panel("reports")


func _on_settings_close_pressed() -> void:
	_close_side_panel("settings")


func _on_settings_save_pressed() -> void:
	_save_game_state()


func _on_settings_reload_pressed() -> void:
	_load_save_data()
	_update_all_displays()
	_update_economy_overlay_text()


func _on_settings_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_settings_quit_pressed() -> void:
	get_tree().quit()


func _on_temple_close_pressed() -> void:
	_close_side_panel("temple")


func _toggle_temple_overlay() -> void:
	_toggle_side_panel("temple")


func _toggle_lord_overlay() -> void:
	_toggle_side_panel("lord")


func _toggle_institutions_overlay() -> void:
	_toggle_side_panel("institutions")


func _toggle_economy_overlay() -> void:
	_toggle_side_panel("economy")


func _toggle_expeditions_overlay() -> void:
	_toggle_side_panel("expeditions")


func _toggle_reports_overlay() -> void:
	_toggle_side_panel("reports")


func _toggle_settings_overlay() -> void:
	_toggle_side_panel("settings")

func _ensure_default_hotkeys() -> void:
	# Runtime defaults so the game works immediately; later you can move these into ProjectSettings/InputMap.
	_ensure_key_action(ACTION_SPEED_DOWN, [KEY_LEFT, KEY_KP_SUBTRACT])
	_ensure_key_action(ACTION_SPEED_UP, [KEY_RIGHT, KEY_KP_ADD])
	_ensure_key_action(ACTION_PAUSE_TOGGLE, [KEY_P])
	# Tab-column toggles.
	_ensure_key_action(ACTION_TABS_TOGGLE, [KEY_TAB, KEY_T])
	# Bottom build menu (same as clicking the buildings icon).
	_ensure_key_action(ACTION_BUILD_MENU_TOGGLE, [KEY_B])

	# Quick open menus (category icons).
	_ensure_key_action(ACTION_MENU_BUILD, [KEY_F1])
	_ensure_key_action(ACTION_MENU_LORD, [KEY_F2])
	_ensure_key_action(ACTION_MENU_CITY, [KEY_F3])
	_ensure_key_action(ACTION_MENU_GUILD, [KEY_F4])
	_ensure_key_action(ACTION_MENU_SETTINGS, [KEY_F5])
	# Camera toggle.
	# Y = toggle FreeCam.
	_set_key_action_exact(ACTION_CAMERA_TOGGLE, [KEY_Y])


func _setup_skills_overlay() -> void:
	if skill_overlay == null:
		return
	if skill_close_btn != null:
		var cb := Callable(self, "_on_skill_close_pressed")
		if not skill_close_btn.pressed.is_connected(cb):
			skill_close_btn.pressed.connect(cb)
	if skill_tab_prov != null:
		skill_tab_prov.pressed.connect(func() -> void:
			_open_skill_category("provisioning")
		)
	if skill_tab_gov != null:
		skill_tab_gov.pressed.connect(func() -> void:
			_open_skill_category("governance")
		)
	if skill_tab_craft != null:
		skill_tab_craft.pressed.connect(func() -> void:
			_open_skill_category("crafting")
		)


func _on_skill_close_pressed() -> void:
	if skill_overlay != null:
		skill_overlay.visible = false
		_exit_iso_overlay_lock()


func _toggle_skill_overlay() -> void:
	_toggle_side_panel("skills")


func _ensure_skill_view_ready() -> void:
	if skill_host == null:
		return
	if _skill_view != null:
		return

	# Worldmap builder registers class_name scripts; this load ensures the class exists.
	var WorldmapViewClass = WorldmapViewScript
	if WorldmapViewClass == null:
		if skill_fallback != null:
			skill_fallback.visible = true
		return

	var view: Control = WorldmapViewClass.new()
	view.name = "WorldmapView"
	view.anchor_left = 0.0
	view.anchor_top = 0.0
	view.anchor_right = 1.0
	view.anchor_bottom = 1.0
	view.offset_left = 0.0
	view.offset_top = 0.0
	view.offset_right = 0.0
	view.offset_bottom = 0.0
	skill_host.add_child(view)
	_skill_view = view
	if skill_fallback != null:
		skill_fallback.visible = false

	_build_skill_graphs(view)


func _build_skill_graphs(view: Control) -> void:
	# Minimal starter graphs. Data and effects will be wired to game systems later.
	_skill_graphs.clear()
	_skill_graphs["provisioning"] = _make_skill_graph("Provisioning", [
		"Granaries",
		"Rationing",
		"Hunting Parties",
		"Trade Caravans",
		"Cold Storage",
	])
	_skill_graphs["governance"] = _make_skill_graph("Governance", [
		"Tax Ledger",
		"Town Watch",
		"Edicts",
		"Public Works",
		"Stability",
	])
	_skill_graphs["crafting"] = _make_skill_graph("Crafting & Construction", [
		"Tooling",
		"Stonecutters",
		"Carpenters",
		"Guild Contracts",
		"Masterwork",
	])

	for k in _skill_graphs.keys():
		var g: Node = _skill_graphs[k]
		view.add_child(g)
		g.visible = false

	# Start on provisioning.
	var first_graph: Node2D = _skill_graphs.get("provisioning") as Node2D
	if first_graph != null:
		(view as Object).set("initial_item", first_graph)


func _make_skill_graph(title: String, skill_names: Array[String]) -> Node2D:
	var GraphClass = WorldmapGraphScript
	var NodeDataClass = WorldmapNodeDataScript
	var graph: Node2D = GraphClass.new()
	graph.name = title

	var node_count := 1 + skill_names.size()
	(graph as Object).set("node_count", node_count)

	# Root node.
	var root: Resource = NodeDataClass.new()
	root.set("id", StringName(title.to_lower().replace(" ", "_") + "_root"))
	root.set("name", title)
	root.set("desc", "Core skills for " + title + ".")
	(graph as Object).set("node_0/data", root)
	(graph as Object).set("node_0/position", Vector2(120, 160))

	for i in range(skill_names.size()):
		var nd: Resource = NodeDataClass.new()
		nd.set("id", StringName(title.to_lower().replace(" ", "_") + "_" + str(i + 1)))
		nd.set("name", skill_names[i])
		nd.set("desc", "TODO: effect description")
		(graph as Object).set("node_%d/data" % (i + 1), nd)
		(graph as Object).set("node_%d/position" % (i + 1), Vector2(120 + (i + 1) * 150, 160))

	(graph as Object).set("connection_count", skill_names.size())
	for i in range(skill_names.size()):
		(graph as Object).set("connection_%d/nodes" % i, Vector2i(i, i + 1))
		(graph as Object).set("connection_%d/costs" % i, Vector2(1, 1))

	return graph


func _open_skill_category(category_id: String) -> void:
	_active_skill_category = category_id
	if _skill_view == null:
		return
	for k in _skill_graphs.keys():
		var g: Node = _skill_graphs[k]
		g.visible = (k == category_id)
	var active_graph: Node2D = _skill_graphs.get(category_id) as Node2D
	if active_graph != null:
		(_skill_view as Object).set("initial_item", active_graph)


func _ensure_freecam_ready() -> void:
	if _freecam != null:
		return
	if town_scene == null:
		return
	_freecam = FlyCameraScript.new()
	_freecam.name = "FlyCamera"
	_freecam.process_mode = Node.PROCESS_MODE_DISABLED
	_freecam.visible = false
	# Start at the current town camera pose.
	if town_camera != null:
		_freecam.global_transform = town_camera.global_transform
	town_scene.add_child(_freecam)


func _set_freecam_active(active: bool) -> void:
	_set_camera_mode(CameraMode.FREECAM if active else CameraMode.ISO)


func _set_camera_mode(mode: int) -> void:
	_camera_mode = mode
	_freecam_active = (mode == CameraMode.FREECAM)

	# Ensure backing nodes exist.
	if mode == CameraMode.FREECAM:
		_ensure_freecam_ready()
	# Isometric camera is the main mode.
	if town_camera != null:
		town_camera.current = (mode == CameraMode.ISO)

	# Freecam
	if _freecam != null:
		if mode == CameraMode.FREECAM:
			# Sync pose before switching.
			# Prefer syncing from the isometric camera.
			if town_camera != null:
				_freecam.global_transform = town_camera.global_transform
			_freecam.visible = true
			_freecam.process_mode = Node.PROCESS_MODE_INHERIT
			if town_camera != null:
				town_camera.current = false
			# FlyCamera creates its own internal camera and sets it current.
		else:
			_freecam.visible = false
			_freecam.process_mode = Node.PROCESS_MODE_DISABLED


func _toggle_free_mode() -> void:
	if _overlay_forces_iso:
		return
	# If build mode is open, freecam is forced.
	if build_bar != null and build_bar.visible:
		_set_camera_mode(CameraMode.FREECAM)
		return
	if _camera_mode == CameraMode.FREECAM:
		_set_camera_mode(CameraMode.ISO)
	else:
		_set_camera_mode(CameraMode.FREECAM)


func _enter_iso_overlay_lock() -> void:
	if _overlay_forces_iso:
		return
	_overlay_forces_iso = true
	_camera_mode_before_overlay = _camera_mode
	# Map/Lord overlays should not be in build/free mode.
	if build_bar != null:
		build_bar.visible = false
	_set_camera_mode(CameraMode.ISO)


func _exit_iso_overlay_lock() -> void:
	if not _overlay_forces_iso:
		return
	_overlay_forces_iso = false
	# If build menu is open, it always forces freecam.
	if build_bar != null and build_bar.visible:
		_set_camera_mode(CameraMode.FREECAM)
		return
	_set_camera_mode(_camera_mode_before_overlay)


func _ensure_key_action(action_name: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for code in keycodes:
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = code
		# Avoid duplicates.
		var already: bool = false
		for existing: InputEvent in InputMap.action_get_events(action_name):
			if existing is InputEventKey and (existing as InputEventKey).keycode == code:
				already = true
				break
		if not already:
			InputMap.action_add_event(action_name, ev)


func _set_key_action_exact(action_name: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	# Clear existing key events so our runtime defaults don't accumulate across runs.
	for existing: InputEvent in InputMap.action_get_events(action_name):
		if existing is InputEventKey:
			InputMap.action_erase_event(action_name, existing)
	_ensure_key_action(action_name, keycodes)


func _connect_left_icons() -> void:
	if buildings_icon_btn != null:
		buildings_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("build")
		)
	if lord_icon_btn != null:
		lord_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("lord")
		)
	if city_icon_btn != null:
		city_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("map")
		)
	if guild_icon_btn != null:
		guild_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("institutions")
		)
	if skills_icon_btn != null:
		skills_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("skills")
		)
	if expeditions_icon_btn != null:
		expeditions_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("expeditions")
		)
	if economy_icon_btn != null:
		economy_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("economy")
		)
	if reports_icon_btn != null:
		reports_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("reports")
		)
	if temple_icon_btn != null:
		temple_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("temple")
		)
	if settings_icon_btn != null:
		settings_icon_btn.pressed.connect(func() -> void:
			_toggle_side_panel("settings")
		)


func _toggle_side_panel(panel_id: String) -> void:
	# Same icon closes; different icon swaps.
	if _active_side_panel_id == panel_id and _is_side_panel_open(panel_id):
		_close_side_panel(panel_id)
		return
	_open_side_panel(panel_id)


func _open_side_panel(panel_id: String) -> void:
	_close_all_side_panels()
	_active_side_panel_id = panel_id
	# Always bring the tab bar out when opening a menu.
	_set_tab_bar_open(true, true)

	match panel_id:
		"build":
			if build_bar != null:
				build_bar.visible = true
				_set_freecam_active(true)
			return
		"lord":
			if lord_overlay != null:
				lord_overlay.visible = true
				_enter_iso_overlay_lock()
			return
		"map":
			if map_overlay != null:
				map_overlay.visible = true
				_enter_iso_overlay_lock()
			return
		"institutions":
			if institutions_overlay != null:
				institutions_overlay.visible = true
				_enter_iso_overlay_lock()
			return
		"temple":
			if temple_overlay != null:
				temple_overlay.visible = true
				_enter_iso_overlay_lock()
			return
		"economy":
			if economy_overlay != null:
				economy_overlay.visible = true
				_update_economy_overlay_text()
				_enter_iso_overlay_lock()
			return
		"expeditions":
			if expeditions_overlay != null:
				expeditions_overlay.visible = true
				_enter_iso_overlay_lock()
			return
		"reports":
			if reports_overlay != null:
				reports_overlay.visible = true
				_enter_iso_overlay_lock()
			return
		"settings":
			if settings_overlay != null:
				settings_overlay.visible = true
				_enter_iso_overlay_lock()
			return
		"skills":
			if skill_overlay != null:
				skill_overlay.visible = true
				_enter_iso_overlay_lock()
				_ensure_skill_view_ready()
				_open_skill_category(_active_skill_category)
			return
		_:
			# Unknown panel id.
			_active_side_panel_id = ""
			return


func _close_side_panel(panel_id: String) -> void:
	match panel_id:
		"build":
			if build_bar != null:
				build_bar.visible = false
				_set_freecam_active(false)
		"lord":
			if lord_overlay != null:
				lord_overlay.visible = false
		"map":
			if map_overlay != null:
				map_overlay.visible = false
		"institutions":
			if institutions_overlay != null:
				institutions_overlay.visible = false
		"temple":
			if temple_overlay != null:
				temple_overlay.visible = false
		"economy":
			if economy_overlay != null:
				economy_overlay.visible = false
		"expeditions":
			if expeditions_overlay != null:
				expeditions_overlay.visible = false
		"reports":
			if reports_overlay != null:
				reports_overlay.visible = false
		"settings":
			if settings_overlay != null:
				settings_overlay.visible = false
		"skills":
			if skill_overlay != null:
				skill_overlay.visible = false
		_:
			pass

	if _active_side_panel_id == panel_id:
		_active_side_panel_id = ""
	_exit_iso_overlay_lock()


func _close_all_side_panels() -> void:
	# Fully reset menus so only one can ever be open.
	if build_bar != null and build_bar.visible:
		build_bar.visible = false
		_set_freecam_active(false)
	_hide_all_overlays()
	_exit_iso_overlay_lock()
	_active_side_panel_id = ""


func _is_side_panel_open(panel_id: String) -> bool:
	match panel_id:
		"build":
			return build_bar != null and build_bar.visible
		"lord":
			return lord_overlay != null and lord_overlay.visible
		"map":
			return map_overlay != null and map_overlay.visible
		"institutions":
			return institutions_overlay != null and institutions_overlay.visible
		"temple":
			return temple_overlay != null and temple_overlay.visible
		"economy":
			return economy_overlay != null and economy_overlay.visible
		"expeditions":
			return expeditions_overlay != null and expeditions_overlay.visible
		"reports":
			return reports_overlay != null and reports_overlay.visible
		"settings":
			return settings_overlay != null and settings_overlay.visible
		"skills":
			return skill_overlay != null and skill_overlay.visible
		_:
			return false


func _ensure_close_button_is_x(btn: Button) -> void:
	if btn == null:
		return
	btn.text = "X"
	btn.focus_mode = Control.FOCUS_NONE


func _ensure_menu_close_buttons() -> void:
	# Map & skill close buttons are not part of _connect_management_overlays().
	if map_close_btn != null:
		_ensure_close_button_is_x(map_close_btn)
	if skill_close_btn != null:
		_ensure_close_button_is_x(skill_close_btn)
	_ensure_build_bar_close_button()
	# Feature popup has no close button in the scene; add one.
	_ensure_feature_popup_close_button()


func _ensure_build_bar_close_button() -> void:
	if build_bar == null:
		return
	var existing: Button = build_bar.get_node_or_null("CloseX") as Button
	if existing != null:
		return
	var b := Button.new()
	b.name = "CloseX"
	b.text = "X"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(28, 0)
	# Position top-right without affecting layout.
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 0.0
	b.anchor_bottom = 0.0
	b.offset_left = -34.0
	b.offset_right = -6.0
	b.offset_top = 6.0
	b.offset_bottom = 30.0
	build_bar.add_child(b)
	b.pressed.connect(func() -> void:
		_close_side_panel("build")
	)


func _ensure_feature_popup_close_button() -> void:
	if feature_popup == null:
		return
	var existing: Button = feature_popup.get_node_or_null("CloseX") as Button
	if existing != null:
		return
	var b := Button.new()
	b.name = "CloseX"
	b.text = "X"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(28, 0)
	# Position top-right without affecting layout.
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 0.0
	b.anchor_bottom = 0.0
	b.offset_left = -34.0
	b.offset_right = -6.0
	b.offset_top = 6.0
	b.offset_bottom = 30.0
	feature_popup.add_child(b)
	b.pressed.connect(func() -> void:
		feature_popup.visible = false
	)


func _open_menu(menu_id: String) -> void:
	# Always bring the tab bar out when opening a menu.
	_set_tab_bar_open(true, true)
	if menu_id == "build":
		if build_bar != null:
			build_bar.visible = true
		return
	if menu_id == "lord":
		_enter_iso_overlay_lock()
	_show_feature_popup(menu_id)


func _show_feature_popup(menu_id: String) -> void:
	if feature_popup == null or feature_title == null or feature_buttons == null:
		return

	# Toggle off if same menu is already open.
	if feature_popup.visible and String(feature_popup.get_meta("menu_id", "")) == menu_id:
		feature_popup.visible = false
		if menu_id == "lord":
			_exit_iso_overlay_lock()
		return

	feature_popup.set_meta("menu_id", menu_id)
	feature_popup.visible = true

	for c in feature_buttons.get_children():
		c.queue_free()

	var title: String = "Menu"
	var labels: Array[String] = []
	var actions: Array[String] = []

	match menu_id:
		"lord":
			title = "Lord Management"
			labels = ["Lord Overview", "Skills", "Powers", "Edicts", "Diplomacy"]
			actions = ["lord_overview", "lord_skills", "lord_powers", "lord_edicts", "lord_diplomacy"]
		"city":
			title = "City Management"
			labels = ["City Overview", "Buildings (Placement)", "Economy", "Population"]
			actions = ["city_overview", "build_open", "city_economy", "city_population"]
		"expeditions":
			title = "Expeditions"
			labels = ["Expedition Board", "Active Expeditions", "Expedition Reports"]
			actions = ["exp_board", "exp_active", "exp_reports"]
		"economy":
			title = "Economy"
			labels = ["Overview", "Trade", "Taxes"]
			actions = ["econ_overview", "econ_trade", "econ_taxes"]
		"reports":
			title = "Reports"
			labels = ["Town Report", "Expedition Log", "Event Log"]
			actions = ["rep_town", "rep_expeditions", "rep_events"]
		"guild":
			title = "Institutions"
			labels = ["Adventurer's Guild", "Academy", "Temple", "Bank"]
			actions = ["inst_guild", "inst_academy", "inst_temple", "inst_bank"]
		"settings":
			title = "Game"
			labels = ["Settings", "Save/Load", "Return to Main Menu"]
			actions = ["game_settings", "game_save_load", "game_main_menu"]
		_:
			title = "Menu"
			labels = ["Coming soon"]
			actions = ["noop"]

	feature_title.text = title
	for i in range(labels.size()):
		var b: Button = Button.new()
		b.text = labels[i]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_feature_action_pressed.bind(actions[i]))
		feature_buttons.add_child(b)


func _on_feature_action_pressed(action_id: String) -> void:
	match action_id:
		"build_open":
			if build_bar != null:
				build_bar.visible = true
			# Keep the feature popup open; it functions as a hub.
		"lord_skills":
			_toggle_skill_overlay()
		"exp_board", "exp_active", "exp_reports", "econ_overview", "econ_trade", "econ_taxes", "rep_town", "rep_expeditions", "rep_events", "city_overview", "city_economy", "city_population", "game_settings", "game_save_load", "lord_overview", "lord_powers", "lord_edicts", "lord_diplomacy", "inst_guild", "inst_academy", "inst_temple", "inst_bank":
			# UI panels for these are planned but not implemented yet.
			pass
		"game_main_menu":
			get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		"noop":
			pass
		_:
			# Placeholder hooks for future windows.
			pass


func _connect_tab_toggle() -> void:
	if tabs_toggle_btn == null:
		return
	# Ensure we only connect once in case of hot reload.
	var cb := Callable(self, "_on_tabs_toggle_pressed")
	if not tabs_toggle_btn.pressed.is_connected(cb):
		tabs_toggle_btn.pressed.connect(cb)


func _on_tabs_toggle_pressed() -> void:
	_set_tab_bar_open(not _tab_bar_open, true)


func _set_tab_bar_open(open: bool, animated: bool) -> void:
	_tab_bar_open = open
	if left_icon_bar == null or tabs_toggle_btn == null:
		return

	var x := 0.0 if open else -(TAB_BAR_WIDTH - TAB_BAR_PEEK_WIDTH)
	# Flip direction based on open/closed.
	tabs_toggle_btn.text = "◀" if open else "▶"

	if animated:
		var t := create_tween()
		t.set_trans(Tween.TRANS_SINE)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(left_icon_bar, "offset_left", x, 0.15)
		t.parallel().tween_property(left_icon_bar, "offset_right", x + TAB_BAR_WIDTH, 0.15)
	else:
		left_icon_bar.offset_left = x
		left_icon_bar.offset_right = x + TAB_BAR_WIDTH


func _toggle_map_overlay() -> void:
	_toggle_side_panel("map")


func _populate_build_bar() -> void:
	if build_bar_hbox == null:
		return

	for c in build_bar_hbox.get_children():
		c.queue_free()
	_build_buttons_by_name.clear()

	# Minimal, deterministic ordering.
	var ordered: Array[String] = [
		"Academy",
		"Temple",
		"Adventurer's Guild",
		"Bank",
		"Cottage",
		"Estate",
		"Lord's Manor",
	]
	for building_name in ordered:
		if not building_data.has(building_name):
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(140, 0)
		b.text = building_name
		b.pressed.connect(_on_building_clicked.bind(building_name))
		b.mouse_entered.connect(_on_building_hover.bind(building_name))
		b.mouse_exited.connect(_on_building_unhover)
		build_bar_hbox.add_child(b)
		_build_buttons_by_name[building_name] = b


func _apply_lord_portrait_from_run_code() -> void:
	if portrait_rig == null:
		return
	if run_code.strip_edges() == "":
		return
	if not RunCodeUtil.is_run_code(run_code):
		return

	var settings := RunCodeUtil.decode(run_code)
	if settings.is_empty():
		return
	var la: Dictionary = Dictionary(settings.get("lord_appearance", {}))
	if la.is_empty():
		return
	var recipe := CharacterAppearanceRecipeScript.from_dict(la)
	recipe.apply_to(portrait_rig)
	if portrait_rig.has_method("set_action"):
		portrait_rig.call("set_action", "Idle")


func _load_save_data() -> void:
	var path := "user://savegame.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var v: Variant = JSON.parse_string(txt)
	if typeof(v) != TYPE_DICTIONARY:
		return
	var d: Dictionary = v

	lord_name = String(d.get("lord_name", lord_name))
	town_name = String(d.get("town_name", town_name))
	kingdom_id = int(d.get("kingdom_id", kingdom_id))
	run_code = String(d.get("run_code", run_code))
	run_log_path = String(d.get("run_log_path", run_log_path))

	# Seed can be numeric or derived from run_code.
	if run_code.strip_edges() != "" and RunCodeUtil.is_run_code(run_code):
		# Keep using the derived numeric seed for determinism.
		var _derived := RunCodeUtil.seed_from_code(run_code)
		# Nothing else currently stores this, but you may want it later.
		# (We still keep the saved numeric seed too.)
		pass

	# World settings.
	var world: Dictionary = Dictionary(d.get("world_settings", {}))
	extra_dungeon_spawn_chance_per_day = float(world.get("extra_dungeon_spawn_chance_per_day", extra_dungeon_spawn_chance_per_day))

	# Load resources if present.
	gold = int(d.get("gold", gold))
	wood = int(d.get("wood", wood))
	stone = int(d.get("stone", stone))
	iron = int(d.get("ore", d.get("iron", iron)))
	food = int(d.get("food", food))
	population = int(d.get("population", population))

	# Deity
	deity_name = String(d.get("deity_name", deity_name))

	# Sim speed preference (pacing only).
	sim_seconds_per_day = float(d.get("sim_seconds_per_day", sim_seconds_per_day))


func _setup_sim_systems() -> void:
	# Minimal sim loop: advance "days" on a real-time clock.
	# You can later expose speed controls, pause, etc.
	_clock = SimClockScript.new()
	_clock.seconds_per_day = sim_seconds_per_day
	add_child(_clock)

	_dungeons = DungeonThreatSystemScript.new()
	# Start with a few dungeons per kingdom (Zeus-like: persistent pressure sources).
	_dungeons.dungeons_per_kingdom = 3
	# Optional extra dungeons over time. Default off (0.0) to avoid overwhelming players.
	_dungeons.extra_dungeon_spawn_chance_per_day = extra_dungeon_spawn_chance_per_day
	add_child(_dungeons)

	_jobs = ExpeditionBoardScript.new()
	_jobs.jobs_per_board = 4
	_jobs.board_refresh_days = 3
	add_child(_jobs)

	_expeditions = AutonomousExpeditionsScript.new()
	_expeditions.expedition_interval_days = 2
	add_child(_expeditions)

	var base_seed := 0
	if RunCodeUtil.is_run_code(run_code):
		base_seed = int(RunCodeUtil.seed_from_code(run_code))
	else:
		base_seed = int(RunCodeUtil.seed_from_code("fallback:" + str(kingdom_id) + "|" + town_name))
	_dungeons.setup(run_code, run_log_path, base_seed, kingdom_id)
	_jobs.setup(run_code, run_log_path, base_seed)
	_expeditions.setup(run_code, run_log_path, base_seed)

	_clock.day_advanced.connect(_on_day_advanced)

	_expeditions.expedition_report.connect(_on_expedition_report)
	_dungeons.raid_arrival.connect(_on_raid_arrival)

	_connect_speed_buttons()
	_apply_speed_visuals()
	_update_time_widget()

	_setup_town_ai()


func _on_day_advanced(day: int) -> void:
	_dungeons.on_day(day)
	_jobs.on_day(day, _dungeons.sites, _town_state_snapshot())
	_expeditions.on_day(day, _jobs.jobs, _dungeons, _town_state_snapshot())
	_update_time_widget()
	_update_topbar_at_a_glance()
	# Run town AI as a separate coroutine (GOAP planning uses await internally).
	call_deferred("_run_town_ai_for_day", day)


func _update_time_widget() -> void:
	if time_value_label == null or date_value_label == null or season_value_label == null:
		return
	var day_index := 0
	if _clock != null:
		day_index = _clock.day

	# Simple calendar model: 30-day months, 12 months/year.
	var day_of_month := int(day_index % 30) + 1
	var month_index := int(floori(day_index / 30.0))
	var month := int(month_index % 12) + 1
	var year := int(floori(day_index / 360.0)) + 1

	var season_names: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]
	var season := season_names[int(floori((month - 1) / 3.0)) % 4]

	time_value_label.text = "Time: Day %d" % (day_index + 1)
	date_value_label.text = "%02d/%02d/%04d" % [day_of_month, month, year]
	season_value_label.text = season
	_apply_speed_visuals()


func _sim_speed_sync_from_seconds() -> void:
	# Align to the closest supported multiplier.
	if sim_seconds_per_day <= 0.0:
		sim_seconds_per_day = BASE_SECONDS_PER_DAY
	var approx: float = BASE_SECONDS_PER_DAY / sim_seconds_per_day
	var best: int = 1
	var best_diff: float = 999999.0
	for m: int in SPEED_STEPS:
		var diff: float = absf(float(m) - approx)
		if diff < best_diff:
			best_diff = diff
			best = m
	sim_speed_multiplier = best
	sim_seconds_per_day = BASE_SECONDS_PER_DAY / float(sim_speed_multiplier)


func _step_sim_speed(direction: int) -> void:
	# direction: -1 (slower), +1 (faster)
	var idx := SPEED_STEPS.find(sim_speed_multiplier)
	if idx == -1:
		idx = 0
	var next_idx := clampi(idx + direction, 0, SPEED_STEPS.size() - 1)
	# No wrap: if you're at x10, you must press slow to go back down.
	if next_idx == idx:
		_apply_speed_visuals()
		return
	sim_speed_multiplier = SPEED_STEPS[next_idx]
	_set_sim_speed_seconds(BASE_SECONDS_PER_DAY / float(sim_speed_multiplier), "x%d" % sim_speed_multiplier)


func _setup_town_ai() -> void:
	_town_ai = CivilianPlannerGOAPScript.new()
	_town_ai.enabled = true
	_town_ai.setup(run_code, run_log_path)
	add_child(_town_ai)
	_init_civilian_ai()


func _init_civilian_ai() -> void:
	_civilians.clear()
	var count := mini(population, 10)
	if count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	var rng_seed := int(RunCodeUtil.seed_from_code(run_code + "|town_ai_init")) if RunCodeUtil.is_run_code(run_code) else int(RunCodeUtil.seed_from_code("fallback|town_ai_init"))
	rng.seed = rng_seed
	for i in range(count):
		_civilians.append({
			"id": "civ_%d" % i,
			"hunger": rng.randf_range(0.0, 0.6),
			"rest_need": rng.randf_range(0.0, 0.6),
			"is_sheltered": false,
		})


func _run_town_ai_for_day(_day: int) -> void:
	if _town_ai == null or _civilians.is_empty():
		return

	var danger := _compute_town_danger()

	for i in range(_civilians.size()):
		var s: Dictionary = _civilians[i]
		# Basic needs drift upward each day.
		s["hunger"] = clampf(float(s.get("hunger", 0.0)) + 0.15, 0.0, 1.0)
		s["rest_need"] = clampf(float(s.get("rest_need", 0.0)) + 0.10, 0.0, 1.0)
		if danger < 0.5:
			s["is_sheltered"] = false

		var result: Dictionary = await _town_ai.choose_goal(s, {"danger": danger})
		var goal := String(result.get("goal", "idle"))
		# Apply a tiny amount of state change to reflect the chosen goal.
		if goal == "Seek Shelter":
			s["is_sheltered"] = true
		elif goal == "Eat":
			s["hunger"] = clampf(float(s.get("hunger", 0.0)) - 0.6, 0.0, 1.0)
		elif goal == "Rest":
			s["rest_need"] = clampf(float(s.get("rest_need", 0.0)) - 0.7, 0.0, 1.0)

		_civilians[i] = s


func _compute_town_danger() -> float:
	if _dungeons == null or _dungeons.sites.is_empty():
		return 0.0
	var sum := 0.0
	for s in _dungeons.sites:
		sum += float(s.get("threat", 0.0))
	return clampf((sum / float(_dungeons.sites.size())) / 100.0, 0.0, 1.0)


func _on_raid_arrival(raid: Dictionary) -> void:
	# Minimal integration: spawn a small set of enemy nodes and attach LimboAI brains.
	var enemy_count := maxi(1, int(raid.get("enemy_count", 5)))
	var spawn_count := mini(enemy_count, 12)
	if _raid_root == null:
		_raid_root = Node.new()
		_raid_root.name = "RaidEnemies"
		add_child(_raid_root)

	for i in range(spawn_count):
		var enemy := Node.new()
		enemy.name = "RaidEnemy_%s_%d" % [String(raid.get("site_id", "site")), i]
		_raid_root.add_child(enemy)
		var brain := EnemyBrainLimboScript.new()
		brain.setup(run_code, run_log_path)
		brain.enabled = true
		brain.behavior_resource_path = "res://ai/behaviors/raid_enemy_bt.tres"
		enemy.add_child(brain)
		brain.ensure_started()


func _connect_speed_buttons() -> void:
	# Keep speed control text right-aligned without changing layout.
	if speed_slow_btn != null and speed_slow_btn.has_method("set_text_alignment"):
		speed_slow_btn.set_text_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
	if speed_normal_btn != null and speed_normal_btn.has_method("set_text_alignment"):
		speed_normal_btn.set_text_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
	if speed_fast_btn != null and speed_fast_btn.has_method("set_text_alignment"):
		speed_fast_btn.set_text_alignment(HORIZONTAL_ALIGNMENT_RIGHT)

	if speed_slow_btn != null:
		speed_slow_btn.pressed.connect(func() -> void:
			_step_sim_speed(-1)
		)
	if speed_normal_btn != null:
		speed_normal_btn.pressed.connect(func() -> void:
			_toggle_pause_or_play()
		)
	if speed_fast_btn != null:
		speed_fast_btn.pressed.connect(func() -> void:
			_step_sim_speed(1)
		)


func _toggle_pause_or_play() -> void:
	_sim_paused = not _sim_paused
	if _clock != null:
		_clock.set_process(not _sim_paused)
	_apply_speed_visuals()


func _set_sim_speed_seconds(seconds_per_day: float, speed_id: String) -> void:
	# Selecting a speed should implicitly unpause.
	if _sim_paused:
		_sim_paused = false
		if _clock != null:
			_clock.set_process(true)
	sim_seconds_per_day = maxf(0.1, seconds_per_day)
	if _clock != null:
		_clock.seconds_per_day = sim_seconds_per_day
	_sim_speed_sync_from_seconds()
	_apply_speed_visuals()
	_save_game_pacing()
	if run_log_path.strip_edges() != "":
		RunLogUtil.log_choice_to(run_log_path, run_code, int(RunCodeUtil.seed_from_code(run_code)) if RunCodeUtil.is_run_code(run_code) else 0, "sim_speed", {
			"speed_id": speed_id,
			"seconds_per_day": sim_seconds_per_day,
		})


func _apply_speed_visuals() -> void:
	# Minimal visual feedback: disable the active speed button.
	# Middle button is play/pause, so keep it enabled.
	if speed_slow_btn != null:
		speed_slow_btn.disabled = sim_speed_multiplier <= 1
	if speed_normal_btn != null:
		speed_normal_btn.disabled = false
	if speed_fast_btn != null:
		speed_fast_btn.disabled = sim_speed_multiplier >= 10


func _unhandled_input(event: InputEvent) -> void:
	if temple_overlay != null and temple_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		temple_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return
	if lord_overlay != null and lord_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		lord_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return
	if institutions_overlay != null and institutions_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		institutions_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return
	if economy_overlay != null and economy_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		economy_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return
	if expeditions_overlay != null and expeditions_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		expeditions_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return
	if reports_overlay != null and reports_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		reports_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return
	if settings_overlay != null and settings_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		settings_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return

	if skill_overlay != null and skill_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		skill_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return

	if map_overlay != null and map_overlay.visible and Input.is_action_just_pressed("ui_cancel"):
		map_overlay.visible = false
		_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return

	if feature_popup != null and feature_popup.visible and Input.is_action_just_pressed("ui_cancel"):
		var menu_id := String(feature_popup.get_meta("menu_id", ""))
		feature_popup.visible = false
		if menu_id == "lord":
			_exit_iso_overlay_lock()
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_just_pressed(ACTION_SPEED_DOWN):
		_step_sim_speed(-1)
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed(ACTION_SPEED_UP):
		_step_sim_speed(1)
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed(ACTION_PAUSE_TOGGLE):
		_toggle_pause_or_play()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed(ACTION_TABS_TOGGLE):
		_on_tabs_toggle_pressed()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed(ACTION_BUILD_MENU_TOGGLE):
		if build_bar != null:
			build_bar.visible = not build_bar.visible
			_set_freecam_active(build_bar.visible)
			# If they open the build menu via hotkey, ensure the tab bar is visible too.
			if build_bar.visible:
				_set_tab_bar_open(true, true)
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_just_pressed(ACTION_MENU_BUILD):
		_open_menu("build")
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed(ACTION_MENU_LORD):
		_toggle_lord_overlay()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed(ACTION_MENU_CITY):
		_toggle_map_overlay()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed(ACTION_MENU_GUILD):
		_toggle_institutions_overlay()
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_just_pressed(ACTION_MENU_SETTINGS):
		_toggle_settings_overlay()
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_just_pressed(ACTION_CAMERA_TOGGLE):
		_toggle_free_mode()
		get_viewport().set_input_as_handled()
		return


func _save_game_pacing() -> void:
	var path := "user://savegame.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var v: Variant = JSON.parse_string(txt)
	if typeof(v) != TYPE_DICTIONARY:
		return
	var d: Dictionary = v
	d["sim_seconds_per_day"] = sim_seconds_per_day
	var wf: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if wf != null:
		wf.store_string(JSON.stringify(d, "\t"))
		wf.close()


func _town_state_snapshot() -> Dictionary:
	return {
		"gold": gold,
		"wood": wood,
		"stone": stone,
		"iron": iron,
		"food": food,
		"population": population,
		"town_name": town_name,
		"kingdom_id": kingdom_id,
	}


func _on_expedition_report(report: Dictionary) -> void:
	var loot: Dictionary = Dictionary(report.get("loot", {}))
	gold += int(loot.get("gold", 0))
	food += int(loot.get("food", 0))
	wood += int(loot.get("wood", 0))
	stone += int(loot.get("stone", 0))
	iron += int(loot.get("ore", loot.get("iron", 0)))

	# Treat deaths as population loss (simple model for now).
	population = max(0, population - int(report.get("deaths", 0)))

	_update_resource_display()
	_update_topbar_at_a_glance()
	_update_economy_overlay_text()
	if expeditions_last_label != null:
		var loot_parts: Array[String] = []
		for k in loot.keys():
			loot_parts.append("%s: %s" % [String(k), str(loot[k])])
		expeditions_last_label.text = "Last expedition:\nDeaths: %d\nLoot: %s" % [int(report.get("deaths", 0)), ", ".join(loot_parts)]
	_save_game_state()


func _save_game_state() -> void:
	var path := "user://savegame.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var v: Variant = JSON.parse_string(txt)
	if typeof(v) != TYPE_DICTIONARY:
		return
	var d: Dictionary = v
	d["gold"] = gold
	d["food"] = food
	d["wood"] = wood
	d["stone"] = stone
	d["ore"] = iron
	d["population"] = population

	# Preserve world settings and pacing.
	d["sim_seconds_per_day"] = sim_seconds_per_day
	var wf: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if wf != null:
		wf.store_string(JSON.stringify(d, "\t"))
		wf.close()

func _update_all_displays() -> void:
	_update_topbar_at_a_glance()
	
	# Update resources
	_update_resource_display()

func _update_topbar_at_a_glance() -> void:
	# Keep the perfected layout intact: only change text.
	if lord_name_value != null:
		lord_name_value.text = lord_name
	if deity_value != null:
		deity_value.text = "%s • E:%s" % [deity_name, _expedition_status_text()]
	if town_name_value != null:
		var danger_pct := int(round(_compute_town_danger() * 100.0))
		town_name_value.text = "%s • D:%d%% • R:%s" % [town_name, danger_pct, _raid_eta_text()]

func _expedition_status_text() -> String:
	if _expeditions == null or _clock == null:
		return "-"
	if _expeditions.active.is_empty():
		return "Idle"
	var return_day := int(_expeditions.active.get("return_day", -1))
	if return_day < 0:
		return "Active"
	var days_left := maxi(0, return_day - _clock.day)
	return "%dd" % days_left

func _raid_eta_text() -> String:
	if _dungeons == null or _clock == null:
		return "-"
	var soonest := 999999
	for r in _dungeons.raids:
		if bool(r.get("resolved", false)):
			continue
		soonest = mini(soonest, int(r.get("arrival_day", 999999)))
	if soonest == 999999:
		return "-"
	var days_left := maxi(0, soonest - _clock.day)
	return "%dd" % days_left

func _update_resource_display() -> void:
	gold_value.text = str(gold)
	wood_value.text = str(wood)
	stone_value.text = str(stone)
	iron_value.text = str(iron)
	food_value.text = str(food)
	population_value.text = str(population)

func _create_grid_plane() -> void:
	# Create a plane mesh with a deterministic region texture (kingdom-based).
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
	
	# Create region texture (biome/kingdom-driven).
	var base_seed: int = 0
	if RunCodeUtil.is_run_code(run_code):
		base_seed = int(RunCodeUtil.seed_from_code(run_code + "|region"))
	else:
		base_seed = int(RunCodeUtil.seed_from_code("fallback|region|" + str(kingdom_id) + "|" + town_name))
	var region_texture: ImageTexture
	if KingdomRegionTextureGeneratorScript.can_generate_isometric_tiles():
		region_texture = KingdomRegionTextureGeneratorScript.generate_isometric_region_texture(
			GRID_SIZE,
			base_seed,
			kingdom_id
		)
	else:
		region_texture = KingdomRegionTextureGeneratorScript.generate_region_texture(
			GRID_SIZE,
			16,
			base_seed,
			kingdom_id
		)
	grid_material.albedo_texture = region_texture
	grid_material.uv1_scale = Vector3(1, 1, 1)
	
	grid_plane.material_override = grid_material
	
	print("[TownView] Created ", GRID_SIZE, "x", GRID_SIZE, " region map (kingdom_id=", kingdom_id, ")")

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

func _connect_buttons() -> void:
	_populate_build_bar()
	if map_close_btn != null:
		var cb := Callable(self, "_on_map_close_pressed")
		if not map_close_btn.pressed.is_connected(cb):
			map_close_btn.pressed.connect(cb)
	if skill_close_btn != null:
		var scb := Callable(self, "_on_skill_close_pressed")
		if not skill_close_btn.pressed.is_connected(scb):
			skill_close_btn.pressed.connect(scb)


func _on_map_close_pressed() -> void:
	if map_overlay != null:
		map_overlay.visible = false

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
