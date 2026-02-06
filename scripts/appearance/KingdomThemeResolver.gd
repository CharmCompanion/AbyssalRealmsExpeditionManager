extends RefCounted
class_name KingdomThemeResolver

# Minimal mapping for the 6 kingdoms currently in CreateTown.
# Returns a theme_id that the appearance generator understands.

const KINGDOM_PRIMARY_BIOME := {
	1: "coastal", # Vylfod Dominion
	2: "plains",  # Rabaric Republic
	3: "forest",  # Kingdom of El’Ruhn
	4: "forest",  # Kelsin Federation
	5: "tundra",  # Divine Empire of Gosain
	6: "desert",  # Yozuan Desert
}

static func theme_id_for_kingdom(kingdom_id: int) -> String:
	return String(KINGDOM_PRIMARY_BIOME.get(int(kingdom_id), "forest"))
