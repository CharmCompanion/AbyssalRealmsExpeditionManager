import random

KINGDOM_DATA = {
    1: {
        "name": "Vylfod Dominion",
        "biomes": ["coastal", "wetlands"],
        "climate": "humid",
        "favored_resources": ["fish", "salt", "herbs"],
        "favored_building": "Harbor",
    },
    2: {
        "name": "Rabaric Republic",
        "biomes": ["plains", "hills"],
        "climate": "temperate",
        "favored_resources": ["food", "wood", "stone"],
        "favored_building": "Market",
    },
    3: {
        "name": "Kingdom of El'Ruhn",
        "biomes": ["forest", "mountains"],
        "climate": "temperate",
        "favored_resources": ["wood", "ore", "gems"],
        "favored_building": "Lumberyard",
    },
    4: {
        "name": "Kelsin Federation",
        "biomes": ["forest", "oasis"],
        "climate": "lush",
        "favored_resources": ["wood", "food", "mana"],
        "favored_building": "Sanctum",
    },
    5: {
        "name": "Divine Empire of Gosain",
        "biomes": ["tundra", "mountains"],
        "climate": "cold",
        "favored_resources": ["stone", "ore", "relics"],
        "favored_building": "Cathedral",
    },
    6: {
        "name": "Yozuan Desert",
        "biomes": ["desert", "canyons", "oasis"],
        "climate": "arid",
        "favored_resources": ["stone", "gems", "mana"],
        "favored_building": "Caravanserai",
    },
}

KINGDOM_TO_DEITY = {1: 0, 5: 1, 6: 2, 3: 3, 4: 4, 2: 5}

KINGDOM_LOCATIONS = {
    1: ["Deepwood Vale", "Ironpine Ridge", "Mossfang Hollow", "Starfall Glade"],
    2: ["Greenfield Plains", "Windmere Hills", "Riverbend Crossing", "Stonegate Meadows"],
    3: ["Saltmarsh Bay", "Coral Haven", "Mistfen Delta", "Seabreeze Port"],
    4: ["Frostpeak Pass", "Glacierholm", "Icemarch Valley", "Snowspire Outpost"],
    5: ["Golden Dunes", "Mirage Oasis", "Sunfire Canyon", "Dustwind Basin"],
    6: ["Redrock Wastes", "Scorpion Gulch", "Burning Sands", "Echo Canyon"],
}

DEITY_BONUSES = {
    0: {
        "name": "Nivarius",
        "desc": "Wisdom / Knowledge",
        "passive_text": "Expedition outcomes are more consistent (less extreme failures and jackpots).",
        "active_text": "Academy: Improve Expedition Preparation \u2192 reduces casualty chance next expedition.",
        "bane_text": "Building construction and upgrades take longer.",
        "passive": {},
        "bane": {},
        "expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0},
    },
    1: {
        "name": "Seraphina",
        "desc": "Faith",
        "passive_text": "Morale loss from expedition deaths is reduced.",
        "active_text": "Temple: Bless Expedition \u2192 wounded adventurers recover faster on return.",
        "bane_text": "Expedition loot sells for less Gold.",
        "passive": {},
        "bane": {},
        "expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0},
    },
    2: {
        "name": "Fortane",
        "desc": "Darkness / Luck",
        "passive_text": "Expedition loot has higher variance (very good or very bad).",
        "active_text": "Bank: Speculative Funding \u2192 pay extra Gold to increase loot potential next expedition.",
        "bane_text": "Recruitment cost is less consistent.",
        "passive": {},
        "bane": {},
        "expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0},
    },
    3: {
        "name": "Thorn",
        "desc": "Nature / Food",
        "passive_text": "Expeditions suffer fewer attrition-related deaths.",
        "active_text": "Cottages: Provision Expedition \u2192 spend Food to reduce expedition death chance.",
        "bane_text": "Trade income scales worse.",
        "passive": {},
        "bane": {},
        "expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0},
    },
    4: {
        "name": "Aurelia",
        "desc": "Strength",
        "passive_text": "Expedition combat events are more survivable (less severe injuries).",
        "active_text": "Estates: Train Party \u2192 improves survivability of next expedition.",
        "bane_text": "Expeditions consume more supplies.",
        "passive": {},
        "bane": {},
        "expedition": {"duration_mult": 1.0, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0},
    },
    5: {
        "name": "Zephra",
        "desc": "Speed",
        "passive_text": "Expeditions complete faster.",
        "active_text": "Adventurer's Guild: Rush Deployment \u2192 shorter expedition prep and cooldown.",
        "bane_text": "Adventurers recover slower from injuries (burnout).",
        "passive": {},
        "bane": {},
        "expedition": {"duration_mult": 0.85, "risk_mult": 1.0, "reward_mult": 1.0, "carry_bonus": 0, "slot_bonus": 0},
    },
}

BIOME_DATA = {
    "forest": {"desc": "Dense woodland rich in timber", "bonus": {"wood": 30}},
    "mountains": {"desc": "High peaks full of minerals", "bonus": {"stone": 25, "ore": 30, "gems": 10}},
    "plains": {"desc": "Open grasslands ideal for farming", "bonus": {"food": 35}},
    "hills": {"desc": "Rolling hills with mixed resources", "bonus": {"stone": 15, "food": 20, "ore": 10}},
    "coastal": {"desc": "Coastal region with abundant fish", "bonus": {"fish": 30, "salt": 20}},
    "wetlands": {"desc": "Marshes rich in rare herbs", "bonus": {"herbs": 25}},
    "tundra": {"desc": "Frozen lands with hardy resources", "bonus": {"stone": 15, "ore": 10, "relics": 10}},
    "desert": {"desc": "Harsh desert with hidden riches", "bonus": {"gems": 10, "stone": 10}},
    "oasis": {"desc": "Life-giving water and mana-rich springs", "bonus": {"food": 10, "mana": 10}},
    "canyons": {"desc": "Deep canyons with ancient secrets", "bonus": {"stone": 20, "ore": 10, "relics": 10}},
}

KINGDOM_BIOME_MODIFIERS = {
    1: {"biome": "coastal", "secondary": "wetlands"},
    2: {"biome": "plains", "secondary": "hills"},
    3: {"biome": "forest", "secondary": "mountains"},
    4: {"biome": "forest", "secondary": "oasis"},
    5: {"biome": "tundra", "secondary": "mountains"},
    6: {"biome": "desert", "secondary": "canyons"},
}

BASE_RESOURCES = ["food", "wood", "stone", "ore", "gems", "relics", "knowledge", "mana"]

STAT_CATEGORIES = {
    "military": ["strength", "endurance", "tactics"],
    "civic": ["diplomacy", "leadership", "justice"],
    "mystic": ["magic", "wisdom", "faith"],
    "survival": ["survival", "exploration"],
    "commerce": ["wealth", "trade"],
    "mobility": ["speed"],
}

SVG_SIZE = (843.75, 568.5)

KINGDOM_CENTERS = {
    "Vylfod_Dominion": (346.88, 284.34),
    "Rabaric_Republic": (206.19, 208.77),
    "Kingdom_of_El_Ruhn": (215.42, 146.32),
    "Kelsin_Federation": (351.50, 131.44),
    "Divine_Empire_of_Gosain": (277.22, 197.82),
    "Yozuan_Desert": (169.44, 155.78),
}

KINGDOM_MAP_FILES = {
    1: {"highlight": "VylfodDominionHighlight.png", "shadow": "VylfodDominionShadow.png"},
    2: {"highlight": "RabaricRepublicHighlight.png", "shadow": "RabaricRepublicShadow.png"},
    3: {"highlight": "KingdomofElRuhnHighlight.png", "shadow": "KingdomofElRuhnShadow.png"},
    4: {"highlight": "KelsinFederationHighlight.png", "shadow": "KelsinFederationShadow.png"},
    5: {"highlight": "DivineEmpireofGosainHighlight.png", "shadow": "DivineEmpireofGosainShadow.png"},
    6: {"highlight": "YozuanDesertHighlight.png", "shadow": "YozuanDesertShadow.png"},
}

BUILDING_TYPES = {
    "town_hall": {
        "name": "Town Hall",
        "base_cost": {"gold": 100, "wood": 50, "stone": 50},
        "production": {"gold": 5},
        "max_level": 5,
    },
    "tavern": {
        "name": "Tavern",
        "base_cost": {"gold": 80, "wood": 40},
        "production": {"gold": 3},
        "max_level": 5,
    },
    "barracks": {
        "name": "Barracks",
        "base_cost": {"gold": 120, "wood": 30, "stone": 60},
        "production": {},
        "max_level": 5,
    },
    "market": {
        "name": "Market",
        "base_cost": {"gold": 150, "wood": 40, "stone": 30},
        "production": {"gold": 8},
        "max_level": 5,
    },
    "farm": {
        "name": "Farm",
        "base_cost": {"gold": 60, "wood": 30},
        "production": {"food": 10},
        "max_level": 5,
    },
    "mine": {
        "name": "Mine",
        "base_cost": {"gold": 100, "wood": 20, "stone": 40},
        "production": {"ore": 5, "stone": 3},
        "max_level": 5,
    },
    "lumber_mill": {
        "name": "Lumber Mill",
        "base_cost": {"gold": 80, "wood": 20},
        "production": {"wood": 8},
        "max_level": 5,
    },
    "temple": {
        "name": "Temple",
        "base_cost": {"gold": 200, "stone": 80},
        "production": {"mana": 3, "knowledge": 2},
        "max_level": 5,
    },
    "library": {
        "name": "Library",
        "base_cost": {"gold": 150, "wood": 50, "stone": 30},
        "production": {"knowledge": 5},
        "max_level": 5,
    },
    "smithy": {
        "name": "Smithy",
        "base_cost": {"gold": 120, "ore": 30, "stone": 20},
        "production": {},
        "max_level": 5,
    },
}

_FNV_OFFSET_64 = 1469598103934665603
_FNV_PRIME_64 = 1099511628211
_MASK_63 = 0x7FFFFFFFFFFFFFFF


def _hash_to_u64(text):
    h = _FNV_OFFSET_64
    for ch in text:
        h = h ^ ord(ch)
        h = (h * _FNV_PRIME_64) & _MASK_63
    return h


def seed_from_code(code):
    h = _hash_to_u64(str(code))
    return int(h & 0x7FFFFFFF)


def _seed_for(base_seed, tag):
    return seed_from_code("seed:" + str(base_seed) + "|" + tag)


def _apply_biome_bonuses(resources, biome, multiplier):
    biome_info = BIOME_DATA.get(biome, {})
    bonus = biome_info.get("bonus", {})
    for res, val in bonus.items():
        if res in resources:
            resources[res] = resources[res] + int(val * multiplier)


def generate_kingdom_resources(kingdom_id, seed_val):
    rng = random.Random(seed_val)
    resources = {}
    for res in BASE_RESOURCES:
        resources[res] = 10 + rng.randint(0, 19)
    mods = KINGDOM_BIOME_MODIFIERS.get(kingdom_id, {})
    primary_biome = mods.get("biome", "forest")
    secondary_biome = mods.get("secondary", "")
    _apply_biome_bonuses(resources, primary_biome, 1.0)
    if secondary_biome:
        _apply_biome_bonuses(resources, secondary_biome, 0.5)
    return resources


def generate_stats(seed_val):
    rng = random.Random(seed_val)
    stats = {}
    for category in STAT_CATEGORIES:
        for stat_name in STAT_CATEGORIES[category]:
            stats[stat_name] = 5 + rng.randint(0, 9)
    return stats


def generate_town_name(seed_val):
    prefixes = ["New", "Fort", "Port", "Lake", "Stone", "Iron", "Gold", "Silver", "Crystal"]
    suffixes = ["haven", "fall", "ridge", "wood", "dale", "keep", "shire", "ford", "gate"]
    rng = random.Random(seed_val)
    prefix = prefixes[rng.randint(0, len(prefixes) - 1)]
    suffix = suffixes[rng.randint(0, len(suffixes) - 1)]
    return prefix + " " + suffix.capitalize()
