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


ADVENTURER_CLASSES = {
    "warrior": {
        "name": "Warrior",
        "portrait": "⚔️",
        "desc": "Heavy melee fighter with high strength and endurance.",
        "stat_bonuses": {"strength": 4, "endurance": 3, "tactics": 2},
        "base_hp": 120,
        "hp_per_level": 12,
        "equipment_slots": ["weapon", "armor", "shield", "accessory"],
        "preferred_weapon": "Greatsword",
    },
    "mage": {
        "name": "Mage",
        "portrait": "🧙",
        "desc": "Arcane spellcaster with devastating magical power.",
        "stat_bonuses": {"magic": 5, "wisdom": 3, "faith": 1},
        "base_hp": 70,
        "hp_per_level": 6,
        "equipment_slots": ["weapon", "robe", "focus", "accessory"],
        "preferred_weapon": "Crystal Staff",
    },
    "ranger": {
        "name": "Ranger",
        "portrait": "🏹",
        "desc": "Versatile scout skilled in survival and ranged combat.",
        "stat_bonuses": {"exploration": 4, "survival": 3, "speed": 2},
        "base_hp": 90,
        "hp_per_level": 8,
        "equipment_slots": ["weapon", "armor", "quiver", "accessory"],
        "preferred_weapon": "Longbow",
    },
    "cleric": {
        "name": "Cleric",
        "portrait": "⛪",
        "desc": "Divine healer who bolsters the party's resilience.",
        "stat_bonuses": {"faith": 5, "wisdom": 3, "endurance": 1},
        "base_hp": 85,
        "hp_per_level": 8,
        "equipment_slots": ["weapon", "armor", "holy_symbol", "accessory"],
        "preferred_weapon": "Blessed Mace",
    },
    "rogue": {
        "name": "Rogue",
        "portrait": "🗡️",
        "desc": "Cunning operative excelling at stealth and treasure.",
        "stat_bonuses": {"speed": 4, "trade": 3, "wealth": 2},
        "base_hp": 80,
        "hp_per_level": 7,
        "equipment_slots": ["weapon", "light_armor", "tools", "accessory"],
        "preferred_weapon": "Twin Daggers",
    },
    "paladin": {
        "name": "Paladin",
        "portrait": "🛡️",
        "desc": "Holy knight combining martial prowess with divine magic.",
        "stat_bonuses": {"strength": 3, "faith": 3, "leadership": 2, "endurance": 1},
        "base_hp": 110,
        "hp_per_level": 10,
        "equipment_slots": ["weapon", "heavy_armor", "shield", "accessory"],
        "preferred_weapon": "Holy Sword",
    },
}

ADVENTURER_TRAITS = [
    {"id": "brave", "name": "Brave", "desc": "+15% combat effectiveness", "effect": {"combat_mult": 1.15}},
    {"id": "cautious", "name": "Cautious", "desc": "-10% injury chance", "effect": {"injury_mult": 0.9}},
    {"id": "lucky", "name": "Lucky", "desc": "+20% loot chance", "effect": {"loot_mult": 1.2}},
    {"id": "tough", "name": "Tough", "desc": "+25 max HP", "effect": {"hp_bonus": 25}},
    {"id": "swift", "name": "Swift", "desc": "+2 speed", "effect": {"speed_bonus": 2}},
    {"id": "scholarly", "name": "Scholarly", "desc": "+3 wisdom, +2 knowledge gain", "effect": {"wisdom_bonus": 3}},
    {"id": "devout", "name": "Devout", "desc": "+3 faith, faster recovery", "effect": {"faith_bonus": 3}},
    {"id": "greedy", "name": "Greedy", "desc": "+30% gold from expeditions", "effect": {"gold_mult": 1.3}},
    {"id": "veteran", "name": "Veteran", "desc": "+2 tactics, +1 endurance", "effect": {"tactics_bonus": 2, "endurance_bonus": 1}},
    {"id": "wild", "name": "Wild", "desc": "+3 survival, +2 exploration", "effect": {"survival_bonus": 3, "exploration_bonus": 2}},
    {"id": "charismatic", "name": "Charismatic", "desc": "+3 diplomacy, +2 leadership", "effect": {"diplomacy_bonus": 3, "leadership_bonus": 2}},
    {"id": "cursed", "name": "Cursed", "desc": "+4 magic but +10% injury chance", "effect": {"magic_bonus": 4, "injury_mult": 1.1}},
]

ADVENTURER_FIRST_NAMES = [
    "Aldric", "Brenna", "Caelum", "Dara", "Edric", "Fiona", "Gareth", "Helena",
    "Ivar", "Johanna", "Kael", "Lyra", "Magnus", "Nessa", "Orin", "Petra",
    "Quinn", "Rowan", "Seren", "Thane", "Ulric", "Vera", "Wren", "Xara",
    "Yorick", "Zara", "Ashwin", "Brigid", "Corvin", "Delia", "Eamon", "Freya",
    "Gideon", "Hilda", "Idris", "Jael", "Kieran", "Lena", "Mordecai", "Niamh",
]

ADVENTURER_LAST_NAMES = [
    "Ashford", "Blackwood", "Cinderfell", "Darkhollow", "Evernight", "Frostborne",
    "Grimshaw", "Holloway", "Ironvale", "Jadecrest", "Knightfall", "Lionsgate",
    "Moorfield", "Nightshade", "Oakenhelm", "Pyreforge", "Quicksilver", "Ravencrest",
    "Stormwind", "Thornwick", "Underhill", "Voidwalker", "Whitecliff", "Yarrow",
]

ADVENTURER_STATUS_TYPES = {
    "idle": {"label": "Idle", "color": "#4ade80", "icon": "🟢"},
    "deployed": {"label": "Deployed", "color": "#facc15", "icon": "🟡"},
    "injured": {"label": "Injured", "color": "#f97316", "icon": "🟠"},
    "recovering": {"label": "Recovering", "color": "#60a5fa", "icon": "🔵"},
    "dead": {"label": "Dead", "color": "#ef4444", "icon": "🔴"},
}


def generate_adventurer(seed_val, index=0):
    seed_int = seed_from_code(str(seed_val) if seed_val is not None else "0")
    rng = random.Random(seed_from_code("adventurer|seed:%s|idx:%d" % (seed_val, index)))

    class_keys = list(ADVENTURER_CLASSES.keys())
    class_id = class_keys[rng.randint(0, len(class_keys) - 1)]
    cls = ADVENTURER_CLASSES[class_id]

    first = ADVENTURER_FIRST_NAMES[rng.randint(0, len(ADVENTURER_FIRST_NAMES) - 1)]
    last = ADVENTURER_LAST_NAMES[rng.randint(0, len(ADVENTURER_LAST_NAMES) - 1)]

    level = 1
    xp = 0
    xp_to_next = 100

    stats = {}
    for category in STAT_CATEGORIES:
        for stat_name in STAT_CATEGORIES[category]:
            base = 3 + rng.randint(0, 7)
            bonus = cls["stat_bonuses"].get(stat_name, 0)
            stats[stat_name] = base + bonus

    trait_pool = list(ADVENTURER_TRAITS)
    rng.shuffle(trait_pool)
    num_traits = rng.randint(1, 2)
    traits = [{"id": t["id"], "name": t["name"], "desc": t["desc"]} for t in trait_pool[:num_traits]]

    hp_bonus = 0
    for t in traits:
        trait_data = next((tr for tr in ADVENTURER_TRAITS if tr["id"] == t["id"]), None)
        if trait_data:
            hp_bonus += trait_data["effect"].get("hp_bonus", 0)

    max_hp = cls["base_hp"] + (cls["hp_per_level"] * (level - 1)) + hp_bonus
    hp = max_hp

    morale = 70 + rng.randint(0, 30)
    kills = 0
    missions_completed = 0
    days_hired = 0
    injury_days_left = 0

    equipment = {}
    for slot_name in cls["equipment_slots"]:
        if slot_name == "weapon":
            equipment[slot_name] = {"name": cls["preferred_weapon"], "quality": "Common"}
        else:
            equipment[slot_name] = None

    return {
        "id": "adv_%d_%d" % (seed_int % 100000, index),
        "name": first + " " + last,
        "class_id": class_id,
        "class_name": cls["name"],
        "portrait": cls["portrait"],
        "desc": cls["desc"],
        "level": level,
        "xp": xp,
        "xp_to_next": xp_to_next,
        "hp": hp,
        "max_hp": max_hp,
        "morale": morale,
        "status": "idle",
        "stats": stats,
        "traits": traits,
        "equipment": equipment,
        "kills": kills,
        "missions_completed": missions_completed,
        "days_hired": days_hired,
        "injury_days_left": injury_days_left,
    }


def generate_starting_adventurers(seed_val, count=4):
    adventurers = []
    for i in range(count):
        adventurers.append(generate_adventurer(seed_val, i))
    return adventurers


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
