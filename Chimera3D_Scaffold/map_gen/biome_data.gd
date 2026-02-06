# Kingdom and Biome Data
# Defines the kingdoms, biomes, and their attributes for procedural map generation.
extends Resource

class_name BiomeData

# Example structure for a kingdom/biome
dict = {
	"Igneous Peaks": {
		"biome": "Volcanic",
		"terrain_complexity": 0.8,
		"humidity_bias": -0.3,
		"color": Color(0.7, 0.2, 0.1)
	},
	"Glacial Expanses": {
		"biome": "Tundra",
		"terrain_complexity": 0.6,
		"humidity_bias": 0.5,
		"color": Color(0.8, 0.9, 1.0)
	},
	# ...add other kingdoms
}
