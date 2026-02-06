extends Control

const RunCodeUtil = preload("res://scripts/run/RunCode.gd")
const RunLogUtil = preload("res://scripts/run/RunLog.gd")
const AppearanceGenerator = preload("res://scripts/appearance/CharacterAppearanceGenerator.gd")
const AppearanceProfiles = preload("res://scripts/appearance/CharacterAppearanceProfiles.gd")
const AppearanceRecipe = preload("res://scripts/appearance/CharacterAppearanceRecipe.gd")

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const TOWN_VIEW_SCENE: String = "res://scenes/ui/TownView.tscn"

const LORD_TAB_INDEX: int = 2

const KINGDOM_TO_DEITY: Dictionary = {
	1: 0,
	5: 1,
	6: 2,
	3: 3,
	4: 4,
	2: 5
}

const DEITY_BONUSES: Dictionary = {
	0: {
		"name": "Nivarius",
		"desc": "Wisdom / Knowledge",
		"passive_text": "Expedition outcomes are more consistent (less extreme failures and jackpots).",
		"active_text": "Academy: Improve Expedition Preparation → reduces casualty chance next expedition.",
		"bane_text": "Building construction and upgrades take longer.",
		"passive": {},
		"bane": {},
		"expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0}
	},
	1: {
		"name": "Seraphina",
		"desc": "Faith",
		"passive_text": "Morale loss from expedition deaths is reduced.",
		"active_text": "Temple: Bless Expedition → wounded adventurers recover faster on return.",
		"bane_text": "Expedition loot sells for less Gold.",
		"passive": {},
		"bane": {},
		"expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0}
	},
	2: {
		"name": "Fortane",
		"desc": "Darkness / Luck",
		"passive_text": "Expedition loot has higher variance (very good or very bad).",
		"active_text": "Bank: Speculative Funding → pay extra Gold to increase loot potential next expedition.",
		"bane_text": "Recruitment cost is less consistent.",
		"passive": {},
		"bane": {},
		"expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0}
	},
	3: {
		"name": "Thorn",
		"desc": "Nature / Food",
		"passive_text": "Expeditions suffer fewer attrition-related deaths.",
		"active_text": "Cottages: Provision Expedition → spend Food to reduce expedition death chance.",
		"bane_text": "Trade income scales worse.",
		"passive": {},
		"bane": {},
		"expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0}
	},
	4: {
		"name": "Aurelia",
		"desc": "Strength",
		"passive_text": "Expedition combat events are more survivable (less severe injuries).",
		"active_text": "Estates: Train Party → improves survivability of next expedition.",
		"bane_text": "Expeditions consume more supplies.",
		"passive": {},
		"bane": {},
		"expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0}
	},
	5: {
		"name": "Zephra",
		"desc": "Speed",
		"passive_text": "Expeditions complete faster.",
		"active_text": "Adventurer's Guild: Rush Deployment → shorter expedition prep and cooldown.",
		"bane_text": "Adventurers recover slower from injuries (burnout).",
		"passive": {},
		"bane": {},
		"expedition": {"duration_mult": 0.85, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0}
	}
}

const KINGDOM_DATA: Dictionary = {
	1: {
		"name": "Vylfod Dominion",
		"biomes": ["coastal", "wetlands"],
		"climate": "humid",
		"favored_resources": ["fish", "salt", "herbs"],
		"favored_building": "Harbor"
	},
	2: {
		"name": "Rabaric Republic",
		"biomes": ["plains", "hills"],
		"climate": "temperate",
		"favored_resources": ["food", "wood", "stone"],
		"favored_building": "Market"
	},
	3: {
		"name": "Kingdom of El’Ruhn",
		"biomes": ["forest", "mountains"],
		"climate": "temperate",
		"favored_resources": ["wood", "ore", "gems"],
		"favored_building": "Lumberyard"
	},
	4: {
		"name": "Kelsin Federation",
		"biomes": ["forest", "oasis"],
		"climate": "lush",
		"favored_resources": ["wood", "food", "mana"],
		"favored_building": "Sanctum"
	},
	5: {
		"name": "Divine Empire of Gosain",
		"biomes": ["tundra", "mountains"],
		"climate": "cold",
		"favored_resources": ["stone", "ore", "relics"],
		"favored_building": "Cathedral"
	},
	6: {
		"name": "Yozuan Desert",
		"biomes": ["desert", "canyons", "oasis"],
		"climate": "arid",
		"favored_resources": ["stone", "gems", "mana"],
		"favored_building": "Caravanserai"
	}
}

const KINGDOM_LOCATIONS: Dictionary = {
	1: ["Deepwood Vale", "Ironpine Ridge", "Mossfang Hollow", "Starfall Glade"],
	2: ["Greenfield Plains", "Windmere Hills", "Riverbend Crossing", "Stonegate Meadows"],
	3: ["Saltmarsh Bay", "Coral Haven", "Mistfen Delta", "Seabreeze Port"],
	4: ["Frostpeak Pass", "Glacierholm", "Icemarch Valley", "Snowspire Outpost"],
	5: ["Golden Dunes", "Mirage Oasis", "Sunfire Canyon", "Dustwind Basin"],
	6: ["Redrock Wastes", "Scorpion Gulch", "Burning Sands", "Echo Canyon"]
}

const BIOME_DATA: Dictionary = {
	"forest": {"desc": "Dense woodland rich in timber", "bonus": {"wood": 30}},
	"mountains": {"desc": "High peaks full of minerals", "bonus": {"stone": 25, "ore": 30, "gems": 10}},
	"plains": {"desc": "Open grasslands ideal for farming", "bonus": {"food": 35}},
	"hills": {"desc": "Rolling hills with mixed resources", "bonus": {"stone": 15, "food": 20, "ore": 10}},
	"coastal": {"desc": "Coastal region with abundant fish", "bonus": {"fish": 30, "salt": 20}},
	"wetlands": {"desc": "Marshes rich in rare herbs", "bonus": {"herbs": 25}},
	"tundra": {"desc": "Frozen lands with hardy resources", "bonus": {"stone": 15, "ore": 10, "relics": 10}},
	"desert": {"desc": "Harsh desert with hidden riches", "bonus": {"gems": 10, "stone": 10}},
	"oasis": {"desc": "Life-giving water and mana-rich springs", "bonus": {"food": 10, "mana": 10}},
	"canyons": {"desc": "Deep canyons with ancient secrets", "bonus": {"stone": 20, "ore": 10, "relics": 10}}
}

const STAT_CATEGORIES: Dictionary = {
	"military": ["strength", "endurance", "tactics"],
	"civic": ["diplomacy", "leadership", "justice"],
	"mystic": ["magic", "wisdom", "faith"],
	"survival": ["survival", "exploration"],
	"commerce": ["wealth", "trade"],
	"mobility": ["speed"]
}

const BASE_RESOURCES: Array[String] = [
	"food", "wood", "stone", "ore",
	"gems", "relics", "knowledge", "mana"
]

const KINGDOM_BIOME_MODIFIERS: Dictionary = {
	1: {"biome": "coastal", "secondary": "wetlands"},
	2: {"biome": "plains", "secondary": "hills"},
	3: {"biome": "forest", "secondary": "mountains"},
	4: {"biome": "forest", "secondary": "oasis"},
	5: {"biome": "tundra", "secondary": "mountains"},
	6: {"biome": "desert", "secondary": "canyons"}
}

var town_name_input: LineEdit
var seed_input: LineEdit
var random_seed_button: Button

var lord_name_input: LineEdit

var create_button: Button
var back_button: Button

var tab_container: TabContainer

var kingdom_buttons: Array[Button] = []
var selected_kingdom_name: Label
var selected_kingdom_meta: RichTextLabel
var selected_deity_header: Label
var selected_deity_info: RichTextLabel

var gold_input: LineEdit
var gold_minus: Button
var gold_plus: Button
var pop_input: LineEdit
var pop_minus: Button
var pop_plus: Button
var food_input: LineEdit
var food_minus: Button
var food_plus: Button
var wood_input: LineEdit
var wood_minus: Button
var wood_plus: Button
var stone_input: LineEdit
var stone_minus: Button
var stone_plus: Button
var ore_input: LineEdit
var ore_minus: Button
var ore_plus: Button

var extra_dungeon_chance: HSlider
var extra_dungeon_chance_value: Label

var map_container: Control
var map_background: TextureRect
var biome_layer: TextureRect
var biome_toggle: BaseButton
var randomize_dot_button: Button
var kingdom_overlays: Control
var city_dot: Control
var city_dot_sprite: CanvasItem
var _city_dot_blink_tween: Tween

var boundary_detector: Node
var boundary_ready: bool = false

var selected_kingdom: int = -1
var selected_deity: int = -1
var selected_location: int = 0
var current_seed: int = 0
var mouse_in_map: bool = false
var hovered_kingdom: int = -1

var run_code: String = ""
var run_log_path: String = ""
var _suppress_seed_change: bool = false
var _suppress_recalc: bool = false
var _suppress_lord_seed_apply: bool = false

const _HOLD_DELAY_SECONDS: float = 0.35
const _HOLD_REPEAT_SECONDS: float = 0.08
var _held_resource_buttons: Dictionary = {} # int(instance_id) -> Dictionary

var lord_options: Node

var available_locations: Array[String] = []
var generated_resources: Dictionary = {}
var generated_stats: Dictionary = {}

func _ready() -> void:
	randomize()
	_resolve_ui()
	_setup_boundary_detector()
	_setup_ui_connections()
	_generate_random_seed()

	if create_button:
		create_button.disabled = true

	_update_button_states()

	_setup_kingdom_buttons()
	_setup_map_hooks()

	if biome_toggle and biome_layer:
		biome_layer.visible = biome_toggle.button_pressed

	_start_city_dot_blink()
	set_process(true)


func _process(delta: float) -> void:
	# Press-and-hold behavior for resource +/- buttons.
	if _held_resource_buttons.is_empty():
		return
	var to_remove: Array[int] = []
	for k in _held_resource_buttons.keys():
		var id: int = int(k)
		var rec: Dictionary = _held_resource_buttons[id]
		var btn: BaseButton = rec.get("btn", null) as BaseButton
		var le: LineEdit = rec.get("le", null) as LineEdit
		if btn == null or le == null or (not is_instance_valid(btn)) or (not is_instance_valid(le)):
			to_remove.append(id)
			continue
		# If the button is no longer pressed, stop repeating.
		if not btn.is_pressed():
			to_remove.append(id)
			continue

		rec["elapsed"] = float(rec.get("elapsed", 0.0)) + delta
		var elapsed: float = float(rec["elapsed"])
		if elapsed < _HOLD_DELAY_SECONDS:
			_held_resource_buttons[id] = rec
			continue

		rec["repeat_accum"] = float(rec.get("repeat_accum", 0.0)) + delta
		while float(rec["repeat_accum"]) >= _HOLD_REPEAT_SECONDS:
			rec["repeat_accum"] = float(rec["repeat_accum"]) - _HOLD_REPEAT_SECONDS
			var base_delta: int = int(rec.get("delta", 0))
			# Holding should jump by 10.
			_on_resource_adjust(le, base_delta * 10)

		_held_resource_buttons[id] = rec

	for id in to_remove:
		_held_resource_buttons.erase(id)

func _pick_node(paths: Array[String]) -> Node:
	for p in paths:
		var n: Node = get_node_or_null(p)
		if n != null:
			return n
	return null

func _resolve_ui() -> void:
	tab_container = _pick_node([
		"ContentRoot/TabContainer",
	]) as TabContainer

	town_name_input = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/SettlementInput",
		"ContentRoot/TabContainer/Town/BasicInfo/SettlementInput",
		"ContentRoot/TabContainer/Town/BasicInfo/TownNameInput",
	]) as LineEdit

	seed_input = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/SeedContainer/SeedInput",
		"ContentRoot/TabContainer/Town/BasicInfo/SeedContainer/SeedInput",
	]) as LineEdit

	random_seed_button = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/SeedContainer/RandomButton",
		"ContentRoot/TabContainer/Town/BasicInfo/SeedContainer/RandomButton",
	]) as Button

	create_button = _pick_node([
		"ContentRoot/BottomButtons/StartButton",
		"ContentRoot/TabRowRightButtons/StartButton",
		"Panel/ActionButtons/StartButton",
		"Panel/ActionButtons/CreateButton",
	]) as Button

	back_button = _pick_node([
		"ContentRoot/BottomButtons/BackButton",
		"ContentRoot/TabRowRightButtons/BackButton",
		"Panel/ActionButtons/BackButton",
	]) as Button

	lord_name_input = _pick_node([
		"ContentRoot/TabContainer/Lord/LordSplit/LordDetailsPanel/DetailsPad/OptionsScroll/LordOptions/LordNameInput",
		"ContentRoot/TabContainer/Lord/LordSplit/LordChoicesPanel/ChoicesPad/ChoicesScroll/LordChoices/LordNameInput",
		"ContentRoot/TabContainer/Lord/LordPad/LordContent/LordNameInput",
		"ContentRoot/TabContainer/Lord/LordNameInput",
	]) as LineEdit

	lord_options = _pick_node([
		"ContentRoot/TabContainer/Lord/LordSplit/LordDetailsPanel/DetailsPad/OptionsScroll/LordOptions",
	])

	kingdom_buttons.clear()
	for i in range(1, 7):
		var b: Button = get_node_or_null("ContentRoot/TabContainer/Kingdom/KingdomSplit/KingdomListPanel/ListPad/KingdomList/KingdomBtn" + str(i)) as Button
		if b != null:
			kingdom_buttons.append(b)

	selected_kingdom_name = get_node_or_null("ContentRoot/TabContainer/Kingdom/KingdomSplit/KingdomDetailsPanel/DetailsPad/DetailsScroll/KingdomDetails/SelectedKingdomName") as Label
	selected_kingdom_meta = get_node_or_null("ContentRoot/TabContainer/Kingdom/KingdomSplit/KingdomDetailsPanel/DetailsPad/DetailsScroll/KingdomDetails/SelectedKingdomMeta") as RichTextLabel
	selected_deity_header = get_node_or_null("ContentRoot/TabContainer/Kingdom/KingdomSplit/KingdomDetailsPanel/DetailsPad/DetailsScroll/KingdomDetails/SelectedDeityHeader") as Label
	selected_deity_info = get_node_or_null("ContentRoot/TabContainer/Kingdom/KingdomSplit/KingdomDetailsPanel/DetailsPad/DetailsScroll/KingdomDetails/SelectedDeityInfo") as RichTextLabel

	gold_input = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/GoldContainer/GoldInput",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/GoldContainer/GoldInput",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/GoldContainer/GoldInput",
	]) as LineEdit
	gold_minus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/GoldContainer/GoldMinus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/GoldContainer/GoldMinus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/GoldContainer/GoldMinus",
	]) as Button
	gold_plus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/GoldContainer/GoldPlus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/GoldContainer/GoldPlus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/GoldContainer/GoldPlus",
	]) as Button

	pop_input = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/PopulationContainer/PopInput",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/PopulationContainer/PopInput",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/PopulationContainer/PopInput",
	]) as LineEdit
	pop_minus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/PopulationContainer/PopMinus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/PopulationContainer/PopMinus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/PopulationContainer/PopMinus",
	]) as Button
	pop_plus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/PopulationContainer/PopPlus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/PopulationContainer/PopPlus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/PopulationContainer/PopPlus",
	]) as Button

	food_input = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/FoodContainer/FoodInput",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/FoodContainer/FoodInput",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/FoodContainer/FoodInput",
	]) as LineEdit
	food_minus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/FoodContainer/FoodMinus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/FoodContainer/FoodMinus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/FoodContainer/FoodMinus",
	]) as Button
	food_plus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/FoodContainer/FoodPlus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/FoodContainer/FoodPlus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/FoodContainer/FoodPlus",
	]) as Button

	wood_input = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/WoodContainer/WoodInput",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/WoodContainer/WoodInput",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/WoodContainer/WoodInput",
	]) as LineEdit
	wood_minus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/WoodContainer/WoodMinus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/WoodContainer/WoodMinus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/WoodContainer/WoodMinus",
	]) as Button
	wood_plus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/WoodContainer/WoodPlus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/WoodContainer/WoodPlus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/WoodContainer/WoodPlus",
	]) as Button

	stone_input = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/StoneContainer/StoneInput",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/StoneContainer/StoneInput",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/StoneContainer/StoneInput",
	]) as LineEdit
	stone_minus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/StoneContainer/StoneMinus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/StoneContainer/StoneMinus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/StoneContainer/StoneMinus",
	]) as Button
	stone_plus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/StoneContainer/StonePlus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/StoneContainer/StonePlus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/StoneContainer/StonePlus",
	]) as Button

	ore_input = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/OreContainer/OreInput",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/OreContainer/OreInput",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/OreContainer/OreInput",
	]) as LineEdit
	ore_minus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/OreContainer/OreMinus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/OreContainer/OreMinus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/OreContainer/OreMinus",
	]) as Button
	ore_plus = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/ResourcesSection/ResourcesGrid/OreContainer/OrePlus",
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/ResourcesSection/ResourcesGrid/OreContainer/OrePlus",
		"ContentRoot/TabContainer/Town/ResourcesSection/ResourcesGrid/OreContainer/OrePlus",
	]) as Button

	extra_dungeon_chance = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/WorldDangerSection/ExtraDungeonRow/ExtraDungeonChance",
		"ContentRoot/TabContainer/Town/WorldDangerSection/ExtraDungeonRow/ExtraDungeonChance",
	]) as HSlider

	extra_dungeon_chance_value = _pick_node([
		"ContentRoot/TabContainer/Town/LeftPanel/LeftPad/BasicInfo/WorldDangerSection/ExtraDungeonRow/ExtraDungeonChanceValue",
		"ContentRoot/TabContainer/Town/WorldDangerSection/ExtraDungeonRow/ExtraDungeonChanceValue",
	]) as Label

	map_container = _pick_node([
		"ContentRoot/TabContainer/Town/RightColumn/MapSection/MapContainer",
		"ContentRoot/TabContainer/Town/MapSection/MapContainer",
	]) as Control

	map_background = _pick_node([
		"ContentRoot/TabContainer/Town/RightColumn/MapSection/MapContainer/MapBackground",
		"ContentRoot/TabContainer/Town/MapSection/MapContainer/MapBackground",
	]) as TextureRect

	biome_layer = _pick_node([
		"ContentRoot/TabContainer/Town/RightColumn/MapSection/MapContainer/BiomesLayer",
		"ContentRoot/TabContainer/Town/MapSection/MapContainer/BiomesLayer",
	]) as TextureRect

	biome_toggle = _pick_node([
		"ContentRoot/BottomButtons/BiomeToggle",
		"ContentRoot/TabRowCenter/BiomeToggle",
		"ContentRoot/TabContainer/Town/MapSection/MapControls/BiomeToggle",
	]) as BaseButton

	randomize_dot_button = _pick_node([
		"ContentRoot/TabContainer/Town/MapSection/MapControls/RandomizeDotButton",
	]) as Button

	kingdom_overlays = _pick_node([
		"ContentRoot/TabContainer/Town/RightColumn/MapSection/MapContainer/KingdomOverlays",
		"ContentRoot/TabContainer/Town/MapSection/MapContainer/KingdomOverlays",
	]) as Control

	city_dot = _pick_node([
		"ContentRoot/TabContainer/Town/RightColumn/MapSection/MapContainer/CityDot",
		"ContentRoot/TabContainer/Town/MapSection/MapContainer/CityDot",
	]) as Control

	city_dot_sprite = _pick_node([
		"ContentRoot/TabContainer/Town/RightColumn/MapSection/MapContainer/CityDot/DotSprite",
		"ContentRoot/TabContainer/Town/MapSection/MapContainer/CityDot/DotSprite",
	]) as CanvasItem

func _setup_ui_connections() -> void:
	if random_seed_button:
		random_seed_button.pressed.connect(_on_random_pressed)

	if create_button:
		create_button.pressed.connect(_on_create_pressed)

	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	if seed_input:
		seed_input.text_changed.connect(_on_seed_changed)

	if town_name_input:
		town_name_input.text_changed.connect(_on_town_name_changed)

	if lord_name_input:
		lord_name_input.text_changed.connect(func(_t: String) -> void:
			_recalculate_run_code_from_ui()
		)

	# Update run-code when resources are edited.
	for le in [gold_input, pop_input, food_input, wood_input, stone_input, ore_input]:
		if le != null:
			le.text_changed.connect(func(_t: String) -> void:
				_recalculate_run_code_from_ui()
			)

	if extra_dungeon_chance != null:
		extra_dungeon_chance.value_changed.connect(func(_v: float) -> void:
			_update_extra_dungeon_label()
			_recalculate_run_code_from_ui()
		)

	# Update run-code when appearance changes.
	if lord_options != null and lord_options.has_signal("appearance_changed"):
		lord_options.connect("appearance_changed", Callable(self, "_recalculate_run_code_from_ui"))

	if biome_toggle:
		biome_toggle.toggled.connect(_on_biome_toggle)

	if randomize_dot_button:
		randomize_dot_button.pressed.connect(_randomize_city_dot_within_selected_kingdom)

	_wire_resource_button(gold_minus, gold_input, -1)
	_wire_resource_button(gold_plus, gold_input, 1)
	_wire_resource_button(pop_minus, pop_input, -1)
	_wire_resource_button(pop_plus, pop_input, 1)
	_wire_resource_button(food_minus, food_input, -1)
	_wire_resource_button(food_plus, food_input, 1)
	_wire_resource_button(wood_minus, wood_input, -1)
	_wire_resource_button(wood_plus, wood_input, 1)
	_wire_resource_button(stone_minus, stone_input, -1)
	_wire_resource_button(stone_plus, stone_input, 1)
	_wire_resource_button(ore_minus, ore_input, -1)
	_wire_resource_button(ore_plus, ore_input, 1)


func _wire_resource_button(btn: Button, le: LineEdit, delta: int) -> void:
	if btn == null or le == null:
		return
	# Single click: +/-1
	btn.pressed.connect(_on_resource_adjust.bind(le, delta))
	# Holding: after a short delay, repeats +/-10.
	btn.button_down.connect(func() -> void:
		var id: int = btn.get_instance_id()
		_held_resource_buttons[id] = {
			"btn": btn,
			"le": le,
			"delta": delta,
			"elapsed": 0.0,
			"repeat_accum": 0.0,
		}
	)
	btn.button_up.connect(func() -> void:
		_held_resource_buttons.erase(btn.get_instance_id())
	)
	btn.mouse_exited.connect(func() -> void:
		_held_resource_buttons.erase(btn.get_instance_id())
	)


func _read_int(le: LineEdit, fallback: int) -> int:
	if le == null:
		return fallback
	var t := le.text.strip_edges()
	if t.is_valid_int():
		return int(t)
	return fallback


func _read_float_slider(slider: HSlider, fallback: float) -> float:
	if slider == null:
		return fallback
	return float(slider.value)


func _set_float_slider_if_not_editing(slider: HSlider, v: float) -> void:
	if slider == null:
		return
	if slider.has_focus():
		return
	slider.value = v
	_update_extra_dungeon_label()


func _update_extra_dungeon_label() -> void:
	if extra_dungeon_chance_value == null:
		return
	var p := _read_float_slider(extra_dungeon_chance, 0.0)
	extra_dungeon_chance_value.text = "%d%%" % int(round(p * 100.0))


func _set_int_if_not_editing(le: LineEdit, v: int) -> void:
	if le == null:
		return
	if le.has_focus():
		return
	le.text = str(v)


func _on_resource_adjust(le: LineEdit, delta: int) -> void:
	if le == null:
		return
	# UX: tap adjusts by 1; holding Shift adjusts by 10.
	var step_delta := int(delta)
	if Input.is_key_pressed(KEY_SHIFT):
		step_delta *= 10
	var cur: int = _read_int(le, 0)
	cur = max(0, cur + step_delta)
	le.text = str(cur)
	_recalculate_run_code_from_ui()


func _on_random_pressed() -> void:
	_randomize_town_and_kingdom_except_lord_appearance()


func _randomize_town_and_kingdom_except_lord_appearance() -> void:
	# Randomizes seed/resources/kingdom (and derived kingdom data), but does NOT randomize Lord appearance.
	# Also keeps the user on the Town tab.
	var keep_town_name := town_name_input.text if town_name_input != null else ""
	var keep_lord_name := lord_name_input.text if lord_name_input != null else ""

	_suppress_recalc = true
	_generate_random_seed_without_changing_lord()

	# Kingdom (implies deity lock).
	if kingdom_buttons.size() > 0:
		_on_kingdom_selected(randi_range(0, kingdom_buttons.size() - 1))
	elif selected_kingdom >= 0:
		_generate_kingdom_data()
		_update_kingdom_details_ui()
		_highlight_kingdom(selected_kingdom + 1)

	# Location index.
	if available_locations.size() > 0:
		selected_location = randi_range(0, available_locations.size() - 1)
	else:
		selected_location = 0

	# World danger slider.
	if extra_dungeon_chance != null:
		var minv := float(extra_dungeon_chance.min_value)
		var maxv := float(extra_dungeon_chance.max_value)
		extra_dungeon_chance.value = randf_range(minv, maxv)
		_update_extra_dungeon_label()

	# Starting resources.
	_set_int_if_not_editing(gold_input, randi_range(50, 500))
	_set_int_if_not_editing(pop_input, randi_range(5, 50))
	_set_int_if_not_editing(food_input, max(0, int(generated_resources.get("food", 0)) + randi_range(-10, 10)))
	_set_int_if_not_editing(wood_input, max(0, int(generated_resources.get("wood", 0)) + randi_range(-10, 10)))
	_set_int_if_not_editing(stone_input, max(0, int(generated_resources.get("stone", 0)) + randi_range(-10, 10)))
	_set_int_if_not_editing(ore_input, max(0, int(generated_resources.get("ore", 0)) + randi_range(-10, 10)))

	# Map dot.
	_randomize_city_dot_within_selected_kingdom()

	# Restore names.
	if town_name_input != null:
		town_name_input.text = keep_town_name
	if lord_name_input != null:
		lord_name_input.text = keep_lord_name

	# Stay on Town tab.
	if tab_container:
		var town_tab := _get_tab_index_by_name("Town")
		if town_tab >= 0:
			tab_container.current_tab = town_tab

	_suppress_recalc = false
	_recalculate_run_code_from_ui()


func _generate_random_seed_without_changing_lord() -> void:
	# Creates a new random seed without re-deriving Lord appearance from it.
	_suppress_lord_seed_apply = true
	_generate_random_seed()
	_suppress_lord_seed_apply = false


func _get_tab_index_by_name(tab_name: String) -> int:
	if tab_container == null:
		return -1
	for i in range(tab_container.get_tab_count()):
		var child: Node = tab_container.get_child(i)
		if child != null and child.name == tab_name:
			return i
	return -1

func _setup_kingdom_buttons() -> void:
	for i in range(kingdom_buttons.size()):
		var b: Button = kingdom_buttons[i]
		if b == null:
			continue
		b.pressed.connect(_on_kingdom_selected.bind(i))

func _setup_map_hooks() -> void:
	if map_background:
		map_background.mouse_entered.connect(_on_map_mouse_entered)
		map_background.mouse_exited.connect(_on_map_mouse_exited)
	if map_container:
		map_container.gui_input.connect(_on_map_container_gui_input)

func _setup_boundary_detector() -> void:
	boundary_detector = null
	boundary_ready = false
	if map_background == null:
		return

	var detector_path: String = "res://scripts/KingdomBoundaryDetector.gd"
	if not ResourceLoader.exists(detector_path):
		return

	var detector_script: Script = load(detector_path) as Script
	if detector_script == null:
		return

	var inst: Node = detector_script.new() as Node
	if inst == null:
		return

	add_child(inst)
	boundary_detector = inst

	var centers: Dictionary = {}
	var centers_path: String = "res://scripts/ui/kingdom_centers.gd"
	if ResourceLoader.exists(centers_path):
		var centers_script: Script = load(centers_path) as Script
		if centers_script != null:
			var cs: Object = centers_script.new()
			if cs != null and cs.has_method("get"):
				var v: Variant = cs.get("KINGDOM_CENTERS")
				if typeof(v) == TYPE_DICTIONARY:
					centers = v

	if boundary_detector.has_method("setup_boundaries"):
		boundary_detector.call("setup_boundaries", map_background, centers)

	if boundary_detector.has_method("get"):
		var ready_val: Variant = boundary_detector.get("is_ready")
		if typeof(ready_val) == TYPE_BOOL:
			boundary_ready = bool(ready_val)

func _generate_random_seed() -> void:
	# Creates a new random playthrough.
	current_seed = int(randi() % 999999)
	_suppress_seed_change = true
	if seed_input != null:
		seed_input.text = str(current_seed)
	_suppress_seed_change = false
	_on_seed_changed(str(current_seed))

func _on_seed_changed(new_text: String) -> void:
	if _suppress_seed_change:
		return
	var text := String(new_text).strip_edges()
	if RunCodeUtil.is_run_code(text):
		_apply_run_code(text)
		return

	# Allow numeric seeds (generates a new set of settings deterministically).
	if text.is_valid_int():
		current_seed = int(text)
		if selected_kingdom >= 0:
			_generate_kingdom_data()
		if not _suppress_lord_seed_apply:
			_apply_seed_to_lord_appearance()
		_recalculate_run_code_from_ui()
		return

	# Any other string becomes a seed too.
	current_seed = RunCodeUtil.seed_from_code("freeform:" + text)
	if selected_kingdom >= 0:
		_generate_kingdom_data()
	if not _suppress_lord_seed_apply:
		_apply_seed_to_lord_appearance()
	_recalculate_run_code_from_ui()

func _on_town_name_changed(_new_text: String) -> void:
	_update_button_states()
	_recalculate_run_code_from_ui()

func _update_button_states() -> void:
	if create_button == null:
		return
	var can_create: bool = (selected_kingdom >= 0) and (selected_deity >= 0)
	create_button.disabled = not can_create

func _on_kingdom_selected(kingdom_index: int) -> void:
	selected_kingdom = kingdom_index
	var kingdom_id: int = selected_kingdom + 1
	var locked_deity: int = int(KINGDOM_TO_DEITY.get(kingdom_id, -1))
	if locked_deity >= 0:
		selected_deity = locked_deity

	_generate_kingdom_data()
	_update_button_states()
	_update_kingdom_details_ui()
	_highlight_kingdom(kingdom_id)

	# Keep current tab; selection should not force a tab switch.

	_randomize_city_dot_within_selected_kingdom()
	_recalculate_run_code_from_ui()


func _recalculate_run_code_from_ui() -> void:
	if _suppress_recalc:
		return
	_suppress_recalc = true

	var lord_recipe_dict: Dictionary = {}
	if lord_options != null and lord_options.has_method("get_recipe"):
		var r: Resource = lord_options.call("get_recipe")
		if r != null and r.has_method("to_dict"):
			lord_recipe_dict = r.call("to_dict")

	var dot_norm := Vector2.ZERO
	if map_background != null and city_dot != null:
		var rect: Rect2 = map_background.get_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			# city_dot is positioned with an offset already, so store its center-ish.
			var px := city_dot.position + Vector2(6, 6)
			dot_norm = Vector2(px.x / rect.size.x, px.y / rect.size.y)

	var settings := {
		"v": 1,
		"kingdom_index": selected_kingdom,
		"deity_id": selected_deity,
		"location_index": selected_location,
		"town_name": (town_name_input.text if town_name_input else ""),
		"lord_name": (lord_name_input.text if lord_name_input else ""),
		"resources": {
			"gold": _read_int(gold_input, 100),
			"population": _read_int(pop_input, 50),
			"food": _read_int(food_input, int(generated_resources.get("food", 0))),
			"wood": _read_int(wood_input, int(generated_resources.get("wood", 0))),
			"stone": _read_int(stone_input, int(generated_resources.get("stone", 0))),
			"ore": _read_int(ore_input, int(generated_resources.get("ore", 0))),
		},
		"world": {
			"extra_dungeon_spawn_chance_per_day": _read_float_slider(extra_dungeon_chance, 0.0),
		},
		"city_dot": {"x": dot_norm.x, "y": dot_norm.y},
		"lord_appearance": lord_recipe_dict,
	}

	run_code = RunCodeUtil.encode(settings)
	current_seed = RunCodeUtil.seed_from_code(run_code)

	_suppress_seed_change = true
	if seed_input != null:
		seed_input.text = run_code
	_suppress_seed_change = false

	_suppress_recalc = false


func _apply_run_code(code: String) -> void:
	var d := RunCodeUtil.decode(code)
	if d.is_empty():
		return

	_suppress_recalc = true
	run_code = code
	current_seed = RunCodeUtil.seed_from_code(run_code)

	# Apply basic selections.
	selected_kingdom = int(d.get("kingdom_index", -1))
	selected_deity = int(d.get("deity_id", selected_deity))
	selected_location = int(d.get("location_index", 0))

	if town_name_input:
		town_name_input.text = String(d.get("town_name", ""))
	if lord_name_input:
		lord_name_input.text = String(d.get("lord_name", ""))

	# If we have a kingdom selection, regenerate derived info and UI.
	if selected_kingdom >= 0:
		_generate_kingdom_data()
		_update_button_states()
		_update_kingdom_details_ui()
		_highlight_kingdom(selected_kingdom + 1)

	# Apply resources.
	var rr: Dictionary = Dictionary(d.get("resources", {}))
	_set_int_if_not_editing(gold_input, int(rr.get("gold", 100)))
	_set_int_if_not_editing(pop_input, int(rr.get("population", 50)))
	_set_int_if_not_editing(food_input, int(rr.get("food", 0)))
	_set_int_if_not_editing(wood_input, int(rr.get("wood", 0)))
	_set_int_if_not_editing(stone_input, int(rr.get("stone", 0)))
	_set_int_if_not_editing(ore_input, int(rr.get("ore", 0)))

	# Apply world danger settings.
	var world: Dictionary = Dictionary(d.get("world", {}))
	_set_float_slider_if_not_editing(extra_dungeon_chance, float(world.get("extra_dungeon_spawn_chance_per_day", 0.0)))

	# Apply dot.
	var dotd: Dictionary = Dictionary(d.get("city_dot", {}))
	if map_background != null and city_dot != null:
		var rect: Rect2 = map_background.get_rect()
		var px := Vector2(float(dotd.get("x", 0.0)) * rect.size.x, float(dotd.get("y", 0.0)) * rect.size.y)
		_move_city_dot_to(px)

	# Apply Lord appearance exactly if present.
	var la: Dictionary = Dictionary(d.get("lord_appearance", {}))
	if lord_options != null and lord_options.has_method("apply_recipe") and not la.is_empty():
		var recipe := AppearanceRecipe.from_dict(la)
		lord_options.call("apply_recipe", recipe)
	else:
		_apply_seed_to_lord_appearance()

	_suppress_recalc = false


func _apply_seed_to_lord_appearance() -> void:
	if lord_options == null or not lord_options.has_method("apply_recipe"):
		return
	# Deterministic Lord appearance derived from the current run seed and chosen kingdom.
	var gen := AppearanceGenerator.new("res://imported/Map and Character/Stand-alone Character creator - 2D Fantasy V1-0-3 (1)/Character creator - 2D Fantasy_Data/StreamingAssets/spritesheets")
	var kingdom_id := (selected_kingdom + 1) if selected_kingdom >= 0 else 0
	var opts := {
		"kingdom_id": kingdom_id,
		"group_id": "%s|kingdom:%d" % [str(current_seed), kingdom_id],
	}
	var recipe: Resource = gen.generate(AppearanceProfiles.PROFILE_CIVILIAN, current_seed, opts)
	lord_options.call("apply_recipe", recipe)

func _generate_kingdom_data() -> void:
	if selected_kingdom < 0:
		return

	seed(current_seed)

	var kingdom_id: int = selected_kingdom + 1

	var locs: Array = KINGDOM_LOCATIONS.get(kingdom_id, [])
	available_locations = []
	for x in locs:
		available_locations.append(str(x))
	selected_location = 0

	generated_resources.clear()
	for res in BASE_RESOURCES:
		generated_resources[res] = 10 + int(randi() % 20)

	var mods: Dictionary = KINGDOM_BIOME_MODIFIERS.get(kingdom_id, {})
	var primary_biome: String = str(mods.get("biome", "forest"))
	var secondary_biome: String = str(mods.get("secondary", ""))

	_apply_biome_bonuses(primary_biome, 1.0)
	if secondary_biome != "":
		_apply_biome_bonuses(secondary_biome, 0.5)

	generated_stats.clear()
	for category in STAT_CATEGORIES.keys():
		var stats_list: Array = STAT_CATEGORIES[category]
		for s in stats_list:
			var stat_name: String = str(s)
			generated_stats[stat_name] = 5 + int(randi() % 10)

	# Sync displayed starting resources to the generated values.
	_set_int_if_not_editing(food_input, int(generated_resources.get("food", 0)))
	_set_int_if_not_editing(wood_input, int(generated_resources.get("wood", 0)))
	_set_int_if_not_editing(stone_input, int(generated_resources.get("stone", 0)))
	_set_int_if_not_editing(ore_input, int(generated_resources.get("ore", 0)))

func _apply_biome_bonuses(biome: String, multiplier: float) -> void:
	var biome_info: Dictionary = BIOME_DATA.get(biome, {})
	var bonus: Dictionary = biome_info.get("bonus", {})
	for res in bonus.keys():
		var k: String = str(res)
		if generated_resources.has(k):
			generated_resources[k] = int(generated_resources[k]) + int(float(bonus[res]) * multiplier)

func _update_kingdom_details_ui() -> void:
	if selected_kingdom < 0:
		return

	var kingdom_id: int = selected_kingdom + 1
	var kingdom_info: Dictionary = KINGDOM_DATA.get(kingdom_id, {})
	var mods: Dictionary = KINGDOM_BIOME_MODIFIERS.get(kingdom_id, {})
	var primary_biome: String = str(mods.get("biome", "forest"))
	var secondary_biome: String = str(mods.get("secondary", ""))

	if selected_kingdom_name:
		selected_kingdom_name.text = str(kingdom_info.get("name", ""))

	if selected_kingdom_meta:
		var biomes: Array = kingdom_info.get("biomes", [])
		var biome_list: Array[String] = []
		for b in biomes:
			biome_list.append(str(b).capitalize())

		var climate: String = str(kingdom_info.get("climate", "")).capitalize()

		var fr: Array = kingdom_info.get("favored_resources", [])
		var fr_list: Array[String] = []
		for r in fr:
			fr_list.append(str(r).capitalize())

		var fb: String = str(kingdom_info.get("favored_building", ""))

		selected_kingdom_meta.bbcode_enabled = true
		selected_kingdom_meta.text = "[center]" \
			+ "[color=#bfbfbf]Biomes:[/color] [color=#a8d6a8]" + ", ".join(biome_list) + "[/color]   " \
			+ "[color=#bfbfbf]Climate:[/color] [color=#a8d6a8]" + climate + "[/color]\n" \
			+ "[color=#bfbfbf]Favored Resources:[/color] [color=#7fd38a]" + ", ".join(fr_list) + "[/color]\n" \
			+ "[color=#bfbfbf]Favored Building:[/color] [color=#7fd38a]" + fb + "[/color]\n\n" \
			+ "[color=#bfbfbf]Starting Biome:[/color] [color=#a8d6a8]" + primary_biome.capitalize() + "[/color]" \
			+ (("   [color=#bfbfbf]Secondary:[/color] [color=#a8d6a8]" + secondary_biome.capitalize() + "[/color]") if secondary_biome != "" else "") \
			+ "[/center]"

	if selected_deity >= 0:
		var deity_info: Dictionary = DEITY_BONUSES.get(selected_deity, {})
		if selected_deity_header:
			selected_deity_header.text = "Patron Deity: " + str(deity_info.get("name", "")) + " — " + str(deity_info.get("desc", ""))

		if selected_deity_info:
			selected_deity_info.bbcode_enabled = true
			selected_deity_info.text = "" \
				+ "[color=#bfbfbf]Passive (Affinity Bonus):[/color]\n" \
				+ "[color=#7fd38a]" + str(deity_info.get("passive_text", "")) + "[/color]\n\n" \
				+ "[color=#bfbfbf]Active (Unique Building):[/color]\n" \
				+ "[color=#7fd38a]" + str(deity_info.get("active_text", "")) + "[/color]\n\n" \
				+ "[color=#bfbfbf]Bane (Unique):[/color]\n" \
				+ "[color=#d78a8a]" + str(deity_info.get("bane_text", "")) + "[/color]"

func _highlight_kingdom(kingdom_id: int) -> void:
	if kingdom_overlays == null:
		return
	var selected_id: int = (selected_kingdom + 1) if selected_kingdom >= 0 else -1
	for i in range(1, 7):
		var highlight: CanvasItem = kingdom_overlays.get_node_or_null("Kingdom" + str(i) + "Highlight") as CanvasItem
		var shadow: CanvasItem = kingdom_overlays.get_node_or_null("Kingdom" + str(i) + "Shadow") as CanvasItem
		if highlight != null:
			# If a kingdom is selected, keep highlight locked on the selection.
			highlight.visible = (i == selected_id) if selected_id > 0 else (i == kingdom_id)
		if shadow != null:
			# Darken non-selected kingdoms when a selection exists.
			shadow.visible = (selected_id > 0) and (i != selected_id)

func _on_biome_toggle(toggled_on: bool) -> void:
	if biome_layer != null:
		biome_layer.visible = toggled_on

func _on_map_mouse_entered() -> void:
	mouse_in_map = true

func _on_map_mouse_exited() -> void:
	mouse_in_map = false
	hovered_kingdom = -1
	if selected_kingdom >= 0:
		_highlight_kingdom(selected_kingdom + 1)
	else:
		_highlight_kingdom(-1)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_in_map:
		_check_map_hover()

func _check_map_hover() -> void:
	if map_background == null:
		return
	# Once a kingdom is selected, keep overlays stable (don't override selection with hover).
	if selected_kingdom >= 0:
		return
	if boundary_detector == null:
		return

	if not boundary_ready and boundary_detector.has_method("get"):
		var ready_val: Variant = boundary_detector.get("is_ready")
		if typeof(ready_val) == TYPE_BOOL:
			boundary_ready = bool(ready_val)
	if not boundary_ready:
		return
	if not boundary_detector.has_method("get_kingdom_at_position"):
		return

	var local_pos: Vector2 = map_background.get_local_mouse_position()
	var v: Variant = boundary_detector.call("get_kingdom_at_position", local_pos)
	var kingdom_id: int = 0
	if typeof(v) == TYPE_INT:
		kingdom_id = int(v)

	if kingdom_id != hovered_kingdom:
		hovered_kingdom = kingdom_id
		if kingdom_id > 0:
			_highlight_kingdom(kingdom_id)
		else:
			if selected_kingdom >= 0:
				_highlight_kingdom(selected_kingdom + 1)
			else:
				_highlight_kingdom(-1)

func _on_map_container_gui_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null:
		return
	if not mb.pressed:
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if map_background == null:
		return

	var local_pos: Vector2 = mb.position

	var clicked_kingdom_id: int = -1
	if boundary_detector != null:
		if not boundary_ready and boundary_detector.has_method("get"):
			var ready_val: Variant = boundary_detector.get("is_ready")
			if typeof(ready_val) == TYPE_BOOL:
				boundary_ready = bool(ready_val)
		if boundary_ready and boundary_detector.has_method("get_kingdom_at_position"):
			var r: Variant = boundary_detector.call("get_kingdom_at_position", local_pos)
			if typeof(r) == TYPE_INT:
				clicked_kingdom_id = int(r)

	if clicked_kingdom_id > 0:
		var clicked_index: int = clicked_kingdom_id - 1
		if selected_kingdom != clicked_index:
			_on_kingdom_selected(clicked_index)
		_move_city_dot_to(local_pos)
		_start_city_dot_blink()
		return

	_move_city_dot_to(local_pos)
	_start_city_dot_blink()

func _move_city_dot_to(pixel_pos: Vector2) -> void:
	if map_background == null or city_dot == null:
		return
	var rect: Rect2 = map_background.get_rect()
	var p: Vector2 = pixel_pos
	p.x = clampf(p.x, 0.0, rect.size.x)
	p.y = clampf(p.y, 0.0, rect.size.y)
	city_dot.position = p - Vector2(6, 6)
	city_dot.visible = true

func _start_city_dot_blink() -> void:
	if city_dot_sprite == null:
		return
	if _city_dot_blink_tween != null:
		_city_dot_blink_tween.kill()
	_city_dot_blink_tween = create_tween()
	_city_dot_blink_tween.set_loops()
	city_dot_sprite.modulate.a = 1.0
	_city_dot_blink_tween.tween_property(city_dot_sprite, "modulate:a", 0.2, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_city_dot_blink_tween.tween_property(city_dot_sprite, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _randomize_city_dot_within_selected_kingdom() -> void:
	if selected_kingdom < 0:
		return
	if map_background == null:
		return

	if boundary_detector != null:
		if not boundary_ready and boundary_detector.has_method("get"):
			var ready_val: Variant = boundary_detector.get("is_ready")
			if typeof(ready_val) == TYPE_BOOL:
				boundary_ready = bool(ready_val)
		if boundary_ready and boundary_detector.has_method("find_valid_dot_position"):
			var kingdom_id: int = selected_kingdom + 1
			var v: Variant = boundary_detector.call("find_valid_dot_position", kingdom_id)
			if typeof(v) == TYPE_VECTOR2:
				var rect: Rect2 = map_background.get_rect()
				var pos: Vector2 = v
				_move_city_dot_to(Vector2(rect.size.x * pos.x, rect.size.y * pos.y))
				_start_city_dot_blink()
				return

	var rect2: Rect2 = map_background.get_rect()
	var rx: float = randf_range(0.08, 0.92)
	var ry: float = randf_range(0.10, 0.90)
	_move_city_dot_to(Vector2(rect2.size.x * rx, rect2.size.y * ry))
	_start_city_dot_blink()

func _on_create_pressed() -> void:
	var lord_tab := _get_tab_index_by_name("Lord")
	if tab_container != null and lord_tab >= 0 and tab_container.current_tab != lord_tab:
		if selected_kingdom < 0 or selected_deity < 0:
			return
		# Avoid TabBar out-of-bounds if tab layout changes.
		if lord_tab < tab_container.get_tab_count():
			tab_container.current_tab = lord_tab
		return

	var final_lord_name: String = ""
	if lord_name_input != null:
		final_lord_name = lord_name_input.text.strip_edges()
	if final_lord_name == "":
		return

	if selected_kingdom < 0 or selected_deity < 0:
		return

	var gold_val: int = _read_int(gold_input, 100)
	var pop_val: int = _read_int(pop_input, 50)
	var food_val: int = _read_int(food_input, int(generated_resources.get("food", 0)))
	var wood_val: int = _read_int(wood_input, int(generated_resources.get("wood", 0)))
	var stone_val: int = _read_int(stone_input, int(generated_resources.get("stone", 0)))
	var ore_val: int = _read_int(ore_input, int(generated_resources.get("ore", 0)))
	var extra_dungeons_pday: float = _read_float_slider(extra_dungeon_chance, 0.0)

	var final_town_name: String = ""
	if town_name_input != null:
		final_town_name = town_name_input.text.strip_edges()
	if final_town_name == "":
		final_town_name = _generate_town_name()

	var deity_info: Dictionary = DEITY_BONUSES.get(selected_deity, {})
	var kingdom_id: int = selected_kingdom + 1
	var kingdom_info: Dictionary = KINGDOM_DATA.get(kingdom_id, {})

	var loc_name: String = ""
	if available_locations.size() > 0 and selected_location >= 0 and selected_location < available_locations.size():
		loc_name = available_locations[selected_location]

	var data: Dictionary = {
		"lord_name": final_lord_name,
		"seed": current_seed,
		"run_code": run_code,
		"run_log_path": run_log_path,
		"kingdom_id": kingdom_id,
		"kingdom_name": str(kingdom_info.get("name", "")),
		"kingdom_biomes": kingdom_info.get("biomes", []),
		"kingdom_climate": str(kingdom_info.get("climate", "")),
		"favored_resources": kingdom_info.get("favored_resources", []),
		"favored_building": str(kingdom_info.get("favored_building", "")),
		"deity_id": selected_deity,
		"deity_name": str(deity_info.get("name", "Unknown")),
		"deity_desc": str(deity_info.get("desc", "")),
		"deity_effects_text": {
			"passive": str(deity_info.get("passive_text", "")),
			"active": str(deity_info.get("active_text", "")),
			"bane": str(deity_info.get("bane_text", ""))
		},
		"deity_effects": {
			"passive": deity_info.get("passive", {}),
			"bane": deity_info.get("bane", {}),
			"expedition": deity_info.get("expedition", {})
		},
		"location_name": loc_name,
		"population": pop_val,
		"gold": gold_val,
		"food": food_val,
		"wood": wood_val,
		"stone": stone_val,
		"ore": ore_val,
		"world_settings": {
			"extra_dungeon_spawn_chance_per_day": extra_dungeons_pday,
		},
		"resources": generated_resources,
		"stats": generated_stats,
		"town_name": final_town_name
	}

	_ensure_run_log_started(data)
	data["run_log_path"] = run_log_path

	_save_character_data(data)
	get_tree().change_scene_to_file(TOWN_VIEW_SCENE)


func _ensure_run_log_started(run_start_data: Dictionary) -> void:
	# Start a per-run log file the first time we confirm creation.
	if run_log_path != "":
		return
	# Ensure directory exists.
	DirAccess.make_dir_recursive_absolute("user://run_logs")
	var stamp := str(Time.get_unix_time_from_system())
	var sid := str(RunCodeUtil.seed_from_code(run_code)) if run_code.strip_edges() != "" else str(current_seed)
	run_log_path = "user://run_logs/run_%s_%s.jsonl" % [sid, stamp]

	var decoded_settings: Dictionary = {}
	if RunCodeUtil.is_run_code(run_code):
		decoded_settings = RunCodeUtil.decode(run_code)

	RunLogUtil.append_to(run_log_path, "run_start", {
		"run_code": run_code,
		"seed": current_seed,
		"settings": decoded_settings,
		"run_start_data": run_start_data,
	})

func _save_character_data(data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _generate_town_name() -> String:
	var prefixes: Array[String] = ["New", "Fort", "Port", "Lake", "Stone", "Iron", "Gold", "Silver", "Crystal"]
	var suffixes: Array[String] = ["haven", "fall", "ridge", "wood", "dale", "keep", "shire", "ford", "gate"]
	return prefixes[int(randi() % prefixes.size())] + " " + suffixes[int(randi() % suffixes.size())].capitalize()
