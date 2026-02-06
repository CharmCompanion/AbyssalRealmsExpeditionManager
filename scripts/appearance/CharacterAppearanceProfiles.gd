extends RefCounted
class_name CharacterAppearanceProfiles

# NOTE: These are *generation* profiles (not UI).
# Parts match the existing preview rig naming: Body, Head, Chest, Hands, Belt, Legs, Shoes.

const PROFILE_CIVILIAN := "civilian"
const PROFILE_ADVENTURER := "adventurer"
const PROFILE_ENEMY := "enemy"

# Common body/clothing layers.
const BASE_PARTS: PackedStringArray = [
	"Body",
	"Head",
	"Chest",
	"Hands",
	"Belt",
	"Legs",
	"Shoes",
]

# Accessory/extra layers available in the spritesheets set.
# These are only applied if the target rig supports them.
const EXTRA_PARTS: PackedStringArray = [
	"Bag",
	"Melee",
	"Ranged",
	"Shield",
	"Magic",
	"Effect",
	"Wings",
	"Mount",
]

# Mapping from part name -> folder prefix (or exact folder if it doesn't exist as a prefix).
const PART_TO_PREFIX := {
	"Body": "NakedBody",
	"Head": "Head",
	"Chest": "Chest",
	"Hands": "Hands",
	"Belt": "Belt",
	"Legs": "Legs",
	"Shoes": "Shoes",
	"Bag": "Bag",
	"Melee": "Melee",
	"Ranged": "Ranged",
	"Shield": "Shield",
	"Magic": "Magic",
	"Effect": "Effect",
	"Wings": "Wings",
	"Mount": "Mount",
}

# Parts that usually allow being empty.
const DEFAULT_ALLOW_NONE := {
	"Body": false,
	"Head": true,
	"Chest": true,
	"Hands": true,
	"Belt": true,
	"Legs": true,
	"Shoes": true,
	"Bag": true,
	"Melee": true,
	"Ranged": true,
	"Shield": true,
	"Magic": true,
	"Effect": true,
	"Wings": true,
	"Mount": true,
}

static func allowed_parts(profile_id: String) -> PackedStringArray:
	match profile_id:
		PROFILE_CIVILIAN:
			return BASE_PARTS
		PROFILE_ADVENTURER:
			# Accessories allowed except Mount; Wings/Effect are handled by generator rules (evil chance).
			return BASE_PARTS + PackedStringArray(["Bag", "Melee", "Ranged", "Shield", "Magic"])
		PROFILE_ENEMY:
			return BASE_PARTS + EXTRA_PARTS
		_:
			return BASE_PARTS

static func allow_none_for_part(part_name: String, _profile_id: String) -> bool:
	# For now, all profiles use the same default allow-none rules.
	return bool(DEFAULT_ALLOW_NONE.get(part_name, true))

static func prefix_for_part(part_name: String) -> String:
	return String(PART_TO_PREFIX.get(part_name, ""))
