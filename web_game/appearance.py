import random
import math
from web_game.game_data import seed_from_code

KINGDOM_PRIMARY_BIOME = {
    1: "coastal",
    2: "plains",
    3: "forest",
    4: "forest",
    5: "tundra",
    6: "desert",
}

BASE_PARTS = ["Body", "Head", "Chest", "Hands", "Belt", "Legs", "Shoes"]
EXTRA_PARTS = ["Bag", "Melee", "Ranged", "Shield", "Magic", "Effect", "Wings", "Mount"]

SPRITE_FOLDERS = {
    "Body": ["NakedBody", "NakedBody2", "NakedBody3"],
    "Head": ["Head1", "Head2", "Head3", "Head4", "Head5", "Head6", "Head7", "Head8",
             "Head9", "Head10", "Head11", "Head12", "Head13", "Head14", "Head15",
             "Head16", "Head17", "Head18", "Head19", "Head20", "Head21", "Head22",
             "Head23", "Head24"],
    "Chest": ["Chest1", "Chest2", "Chest3", "Chest4", "Chest5", "Chest6", "Chest7",
              "Chest8", "Chest9", "Chest10", "Chest11", "Chest12", "Chest13",
              "Chest14", "Chest15", "Chest16", "Chest17", "Chest18", "Chest19"],
    "Hands": ["Hands1", "Hands2", "Hands3", "Hands4"],
    "Belt": ["Belt1", "Belt2"],
    "Legs": ["Legs1", "Legs2", "Legs3", "Legs4", "Legs5", "Legs6", "Legs7", "Legs8", "Legs9"],
    "Shoes": ["Shoes1", "Shoes2", "Shoes3", "Shoes4", "Shoes5"],
    "Bag": ["Bag1", "Bag2", "Bag3", "Bag4", "Bag5", "Bag6", "Bag8"],
    "Melee": ["Melee1", "Melee2", "Melee3", "Melee4", "Melee5", "Melee6", "Melee7",
              "Melee8", "Melee9", "Melee10", "Melee11", "Melee12", "Melee13",
              "Melee14", "Melee15", "Melee16", "Melee17", "Melee18", "Melee19",
              "Melee20", "Melee21", "Melee22", "Melee23", "Melee24", "Melee25"],
    "Ranged": ["Ranged1", "Ranged2", "Ranged3", "Ranged4", "Ranged5", "Ranged6", "Ranged7"],
    "Shield": ["Shield1", "Shield2", "Shield3", "Shield4", "Shield5", "Shield6", "Shield7"],
    "Magic": ["Magic1", "Magic2", "Magic3"],
    "Effect": ["Effect1", "Effect2", "Effect3", "Effect4", "Effect5"],
    "Wings": [],
    "Mount": ["Mount1", "Mount2", "Mount3", "Mount4", "Mount5"],
}

PART_TO_PREFIX = {
    "Body": "NakedBody", "Head": "Head", "Chest": "Chest", "Hands": "Hands",
    "Belt": "Belt", "Legs": "Legs", "Shoes": "Shoes", "Bag": "Bag",
    "Melee": "Melee", "Ranged": "Ranged", "Shield": "Shield", "Magic": "Magic",
    "Effect": "Effect", "Wings": "Wings", "Mount": "Mount",
}

DEFAULT_LAYER_Z = {
    "Body": 0, "Legs": 10, "Shoes": 12, "Chest": 20, "Belt": 24,
    "Head": 30, "Hands": 40, "Bag": 45, "Shield": 46, "Melee": 47,
    "Ranged": 48, "Magic": 60, "Wings": 65, "Effect": 90, "Mount": -10,
}

SKIN_TONES = [
    {"name": "Pale",    "h": 0.07, "s": 0.20, "v": 0.95},
    {"name": "Fair",    "h": 0.07, "s": 0.25, "v": 0.90},
    {"name": "Light",   "h": 0.07, "s": 0.30, "v": 0.85},
    {"name": "Medium",  "h": 0.07, "s": 0.35, "v": 0.78},
    {"name": "Tan",     "h": 0.07, "s": 0.40, "v": 0.70},
    {"name": "Olive",   "h": 0.08, "s": 0.38, "v": 0.65},
    {"name": "Brown",   "h": 0.07, "s": 0.45, "v": 0.55},
    {"name": "Dark",    "h": 0.06, "s": 0.50, "v": 0.40},
    {"name": "Ebony",   "h": 0.06, "s": 0.55, "v": 0.30},
]

BIOME_PALETTES = {
    "coastal": {"h_range": (0.50, 0.60), "s_range": (0.30, 0.60), "v_range": (0.50, 0.80)},
    "wetlands": {"h_range": (0.28, 0.40), "s_range": (0.25, 0.55), "v_range": (0.40, 0.70)},
    "plains":  {"h_range": (0.10, 0.18), "s_range": (0.30, 0.55), "v_range": (0.60, 0.85)},
    "forest":  {"h_range": (0.25, 0.38), "s_range": (0.30, 0.60), "v_range": (0.35, 0.65)},
    "tundra":  {"h_range": (0.55, 0.65), "s_range": (0.15, 0.35), "v_range": (0.70, 0.95)},
    "desert":  {"h_range": (0.08, 0.14), "s_range": (0.40, 0.70), "v_range": (0.65, 0.85)},
}

DUNGEON_PALETTES = {
    "undead":  {"h_range": (0.40, 0.55), "s_range": (0.10, 0.30), "v_range": (0.35, 0.60)},
    "inferno": {"h_range": (0.00, 0.08), "s_range": (0.60, 0.90), "v_range": (0.55, 0.85)},
    "cultist": {"h_range": (0.75, 0.85), "s_range": (0.30, 0.60), "v_range": (0.25, 0.50)},
    "abyssal": {"h_range": (0.60, 0.72), "s_range": (0.20, 0.50), "v_range": (0.20, 0.45)},
    "fungal":  {"h_range": (0.20, 0.35), "s_range": (0.40, 0.70), "v_range": (0.30, 0.55)},
    "bandits": {"h_range": (0.05, 0.12), "s_range": (0.20, 0.45), "v_range": (0.30, 0.55)},
    "ruins":   {"h_range": (0.08, 0.15), "s_range": (0.10, 0.30), "v_range": (0.40, 0.65)},
}

ADVENTURER_ACCESSORY_CHANCES = {
    "Bag": 0.65,
    "Melee": 0.55,
    "Shield": 0.35,
    "Ranged": 0.30,
    "Magic": 0.25,
}

EVIL_EXTRA_CHANCES = {
    "Effect": 0.20,
}

ENEMY_ACCESSORY_CHANCES = {
    "Effect": 0.45,
    "Magic": 0.40,
    "Melee": 0.55,
    "Ranged": 0.35,
    "Shield": 0.25,
    "Bag": 0.15,
    "Mount": 0.10,
}

FAMILY_FRACTION = 0.55
FAMILY_RESEMBLANCE_STRENGTH = 0.70
KID_CHANCE = 0.22
KID_SCALE = 0.85
MIN_FAMILY_SIZE = 2
MAX_FAMILY_SIZE = 5

NPC_FIRST_NAMES = [
    "Ada", "Bran", "Cora", "Dorin", "Elia", "Finn", "Greta", "Hugo",
    "Iris", "Jasper", "Kira", "Lief", "Mira", "Nolan", "Ora", "Pike",
    "Quinn", "Rhea", "Sable", "Tomas", "Uma", "Voss", "Willa", "Xander",
    "Yara", "Zeke", "Anya", "Bjorn", "Celia", "Dag", "Edda", "Falk",
    "Gwyn", "Halvar", "Ione", "Jorik", "Kenna", "Lars", "Maren", "Niall",
]

NPC_LAST_NAMES = [
    "Baker", "Carpenter", "Dyer", "Fletcher", "Gardner", "Harper",
    "Mason", "Miller", "Potter", "Sawyer", "Smith", "Tanner",
    "Thatcher", "Turner", "Warden", "Weaver", "Cooper", "Fisher",
    "Forester", "Hunter", "Miner", "Shepherd", "Steward", "Brewer",
]

NPC_ROLES = [
    "Farmer", "Merchant", "Guard", "Artisan", "Scholar", "Priest",
    "Miner", "Hunter", "Fisherman", "Innkeeper", "Healer", "Blacksmith",
    "Tailor", "Baker", "Woodcutter", "Stablehand", "Courier", "Herbalist",
]


def _hsv_to_hex(h, s, v):
    h = h % 1.0
    c = v * s
    x = c * (1 - abs((h * 6) % 2 - 1))
    m = v - c
    if h < 1/6:
        r, g, b = c, x, 0
    elif h < 2/6:
        r, g, b = x, c, 0
    elif h < 3/6:
        r, g, b = 0, c, x
    elif h < 4/6:
        r, g, b = 0, x, c
    elif h < 5/6:
        r, g, b = x, 0, c
    else:
        r, g, b = c, 0, x
    ri = min(255, max(0, int((r + m) * 255)))
    gi = min(255, max(0, int((g + m) * 255)))
    bi = min(255, max(0, int((b + m) * 255)))
    return "#%02x%02x%02x" % (ri, gi, bi)


def _palette_color(rng, palette):
    h = rng.uniform(palette["h_range"][0], palette["h_range"][1])
    s = rng.uniform(palette["s_range"][0], palette["s_range"][1])
    v = rng.uniform(palette["v_range"][0], palette["v_range"][1])
    return _hsv_to_hex(h, s, v)


def _skin_color(rng):
    tone = SKIN_TONES[rng.randint(0, len(SKIN_TONES) - 1)]
    h = tone["h"] + rng.uniform(-0.01, 0.01)
    s = tone["s"] + rng.uniform(-0.05, 0.05)
    v = tone["v"] + rng.uniform(-0.03, 0.03)
    return _hsv_to_hex(h, max(0.1, s), max(0.2, min(1.0, v))), tone["name"]


def _jitter_color(rng, base_h, base_s, base_v, amount=0.05):
    h = (base_h + rng.uniform(-amount, amount)) % 1.0
    s = max(0.05, min(1.0, base_s + rng.uniform(-amount * 2, amount * 2)))
    v = max(0.15, min(1.0, base_v + rng.uniform(-amount * 2, amount * 2)))
    return _hsv_to_hex(h, s, v)


def _pick_option(rng, options):
    return options[rng.randint(0, len(options) - 1)]


def generate_appearance(profile_id, seed_val, opts=None):
    if opts is None:
        opts = {}
    rng = random.Random(seed_from_code("appearance|%s|%s" % (profile_id, seed_val)))

    kingdom_id = opts.get("kingdom_id", 1)
    biome = KINGDOM_PRIMARY_BIOME.get(kingdom_id, "forest")
    palette = BIOME_PALETTES.get(biome, BIOME_PALETTES["forest"])

    dungeon_theme = opts.get("dungeon_theme")
    if dungeon_theme and dungeon_theme in DUNGEON_PALETTES:
        palette = DUNGEON_PALETTES[dungeon_theme]

    is_evil = opts.get("evil", False)
    is_kid = opts.get("is_kid", False)
    family_seed = opts.get("family_seed")

    if family_seed is not None:
        family_rng = random.Random(seed_from_code("family|%s" % family_seed))
        family_skin, family_skin_name = _skin_color(family_rng)
        family_base_h = family_rng.uniform(palette["h_range"][0], palette["h_range"][1])
        family_base_s = family_rng.uniform(palette["s_range"][0], palette["s_range"][1])
        family_base_v = family_rng.uniform(palette["v_range"][0], palette["v_range"][1])

        if rng.random() < FAMILY_RESEMBLANCE_STRENGTH:
            skin_hex = family_skin
            skin_name = family_skin_name
        else:
            skin_hex, skin_name = _skin_color(rng)
    else:
        skin_hex, skin_name = _skin_color(rng)
        family_base_h = rng.uniform(palette["h_range"][0], palette["h_range"][1])
        family_base_s = rng.uniform(palette["s_range"][0], palette["s_range"][1])
        family_base_v = rng.uniform(palette["v_range"][0], palette["v_range"][1])

    recipe = {
        "profile_id": profile_id,
        "seed": seed_val,
        "scale": KID_SCALE if is_kid else 1.0,
        "is_kid": is_kid,
        "is_evil": is_evil,
        "skin_tone": skin_name,
        "part_folders": {},
        "part_colors": {},
    }

    for part in BASE_PARTS:
        folders = SPRITE_FOLDERS.get(part, [])
        if not folders:
            continue
        if family_seed is not None and rng.random() < FAMILY_RESEMBLANCE_STRENGTH:
            idx = random.Random(seed_from_code("family|%s|%s" % (family_seed, part))).randint(0, len(folders) - 1)
        else:
            idx = rng.randint(0, len(folders) - 1)
        recipe["part_folders"][part] = folders[idx]

        if part == "Body":
            recipe["part_colors"][part] = skin_hex
        elif part == "Head":
            recipe["part_colors"][part] = skin_hex
        else:
            recipe["part_colors"][part] = _jitter_color(rng, family_base_h, family_base_s, family_base_v)

    acc_folders = {}
    if profile_id == "adventurer":
        chances = dict(ADVENTURER_ACCESSORY_CHANCES)
        if is_evil:
            chances.update(EVIL_EXTRA_CHANCES)
        for acc_part, chance in chances.items():
            if rng.random() < chance:
                folders = SPRITE_FOLDERS.get(acc_part, [])
                if folders:
                    acc_folders[acc_part] = _pick_option(rng, folders)
                    recipe["part_colors"][acc_part] = _palette_color(rng, palette)

    elif profile_id == "enemy":
        for acc_part, chance in ENEMY_ACCESSORY_CHANCES.items():
            if acc_part == "Mount" and is_kid:
                continue
            if rng.random() < chance:
                folders = SPRITE_FOLDERS.get(acc_part, [])
                if folders:
                    acc_folders[acc_part] = _pick_option(rng, folders)
                    recipe["part_colors"][acc_part] = _palette_color(rng, palette)

    elif profile_id == "civilian":
        if not is_kid and rng.random() < 0.15:
            folders = SPRITE_FOLDERS.get("Bag", [])
            if folders:
                acc_folders["Bag"] = _pick_option(rng, folders)
                recipe["part_colors"]["Bag"] = _palette_color(rng, palette)

    recipe["part_folders"].update(acc_folders)
    return recipe


def generate_npc_name(rng):
    first = NPC_FIRST_NAMES[rng.randint(0, len(NPC_FIRST_NAMES) - 1)]
    last = NPC_LAST_NAMES[rng.randint(0, len(NPC_LAST_NAMES) - 1)]
    return first + " " + last


def generate_civilian_population(count, seed_val, opts=None):
    if opts is None:
        opts = {}
    rng = random.Random(seed_from_code("population|%s" % seed_val))
    kingdom_id = opts.get("kingdom_id", 1)

    family_count = max(1, int(count * FAMILY_FRACTION / 3))
    family_member_budget = int(count * FAMILY_FRACTION)
    single_budget = count - family_member_budget

    civilians = []
    families = {}
    family_id_counter = 0

    for fi in range(family_count):
        if len(civilians) >= family_member_budget:
            break
        family_id_counter += 1
        family_id = "fam_%d_%d" % (seed_from_code(str(seed_val)) % 10000, family_id_counter)
        family_seed = seed_from_code("family_seed|%s|%d" % (seed_val, fi))
        family_size = rng.randint(MIN_FAMILY_SIZE, MAX_FAMILY_SIZE)
        family_last_name = NPC_LAST_NAMES[rng.randint(0, len(NPC_LAST_NAMES) - 1)]

        members = []
        for mi in range(family_size):
            if len(civilians) >= family_member_budget:
                break

            is_kid = False
            if mi >= 2 and rng.random() < KID_CHANCE:
                is_kid = True

            member_seed = seed_from_code("member|%s|%d|%d" % (seed_val, fi, mi))
            appearance = generate_appearance("civilian", member_seed, {
                "kingdom_id": kingdom_id,
                "family_seed": family_seed,
                "is_kid": is_kid,
            })

            first_name = NPC_FIRST_NAMES[rng.randint(0, len(NPC_FIRST_NAMES) - 1)]
            role = "Child" if is_kid else NPC_ROLES[rng.randint(0, len(NPC_ROLES) - 1)]

            npc = {
                "id": "npc_%d" % len(civilians),
                "name": first_name + " " + family_last_name,
                "role": role,
                "family_id": family_id,
                "is_kid": is_kid,
                "appearance": appearance,
                "mood": rng.choice(["content", "happy", "worried", "neutral"]),
                "hunger": round(rng.uniform(0, 0.3), 2),
                "rest_need": round(rng.uniform(0, 0.3), 2),
                "is_sheltered": True,
            }
            members.append(npc)
            civilians.append(npc)

        families[family_id] = {
            "family_name": family_last_name,
            "member_ids": [m["id"] for m in members],
        }

    for si in range(single_budget):
        if len(civilians) >= count:
            break
        member_seed = seed_from_code("single|%s|%d" % (seed_val, si))
        appearance = generate_appearance("civilian", member_seed, {
            "kingdom_id": kingdom_id,
        })
        name = generate_npc_name(rng)
        role = NPC_ROLES[rng.randint(0, len(NPC_ROLES) - 1)]

        npc = {
            "id": "npc_%d" % len(civilians),
            "name": name,
            "role": role,
            "family_id": None,
            "is_kid": False,
            "appearance": appearance,
            "mood": rng.choice(["content", "happy", "worried", "neutral"]),
            "hunger": round(rng.uniform(0, 0.3), 2),
            "rest_need": round(rng.uniform(0, 0.3), 2),
            "is_sheltered": True,
        }
        civilians.append(npc)

    return {
        "civilians": civilians[:count],
        "families": families,
    }


def generate_adventurer_appearance(seed_val, index, kingdom_id=1, is_evil=False):
    member_seed = seed_from_code("adv_appear|%s|%d" % (seed_val, index))
    return generate_appearance("adventurer", member_seed, {
        "kingdom_id": kingdom_id,
        "evil": is_evil,
    })


def generate_enemy_appearance(seed_val, index, dungeon_theme="undead", kingdom_id=1, is_kid=False):
    member_seed = seed_from_code("enemy_appear|%s|%d" % (seed_val, index))
    return generate_appearance("enemy", member_seed, {
        "kingdom_id": kingdom_id,
        "dungeon_theme": dungeon_theme,
        "is_kid": is_kid,
    })


def generate_enemy_party(count, seed_val, dungeon_theme="undead", kingdom_id=1):
    rng = random.Random(seed_from_code("enemy_party|%s" % seed_val))
    enemies = []

    ENEMY_NAMES = {
        "undead": ["Skeleton", "Zombie", "Wraith", "Ghoul", "Revenant", "Lich Thrall"],
        "inferno": ["Imp", "Hellhound", "Fire Elemental", "Demon Soldier", "Flame Knight"],
        "cultist": ["Acolyte", "Dark Mage", "Cult Enforcer", "Shadow Priest", "Void Walker"],
        "abyssal": ["Deep One", "Tentacle Horror", "Abyssal Lurker", "Void Spawn", "Shadow Beast"],
        "fungal": ["Sporeling", "Myconid", "Fungal Giant", "Spore Cloud", "Rot Walker"],
        "bandits": ["Thug", "Brigand", "Highwayman", "Bandit Captain", "Cutthroat"],
        "ruins": ["Animated Armor", "Stone Golem", "Guardian Spirit", "Ruin Crawler", "Sentinel"],
    }

    name_pool = ENEMY_NAMES.get(dungeon_theme, ENEMY_NAMES["undead"])

    for i in range(count):
        appearance = generate_enemy_appearance(seed_val, i, dungeon_theme, kingdom_id)
        name = name_pool[rng.randint(0, len(name_pool) - 1)]
        level = max(1, rng.randint(1, 5))
        hp = 30 + level * 15 + rng.randint(0, 20)

        enemy = {
            "id": "enemy_%d_%d" % (seed_from_code(str(seed_val)) % 10000, i),
            "name": name,
            "level": level,
            "hp": hp,
            "max_hp": hp,
            "theme": dungeon_theme,
            "appearance": appearance,
            "behavior": "idle",
            "raid_progress": 0.0,
        }
        enemies.append(enemy)

    return enemies
