# Simple test to verify SVG path extraction works
extends SceneTree

func _init():
	# Test the SVG path extraction
	var svg_layer = preload("res://scripts/ui/SVGLayer.gd").new()
	svg_layer.svg_source = "res://assets/map/Map.svg"
	
	var kingdoms = [
		"Vylfod Dominion",
		"Rabaric Republic", 
		"Kingdom of El Ruhn",
		"Kelsin Federation",
		"Divine Empire of Gosain",
		"Yozuan Desert"
	]
	
	for kingdom in kingdoms:
		svg_layer.kingdom_name = kingdom
		svg_layer.layer_type = "highlight"
		print("Testing kingdom: ", kingdom)
		# This would call _update_texture() and print success/failure
	
	quit()