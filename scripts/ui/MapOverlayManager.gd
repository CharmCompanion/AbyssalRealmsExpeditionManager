extends Control
class_name MapOverlayManager

## Manages kingdom overlay highlights/shadows using pre-rendered textures
## Guarantees perfect alignment since all textures use the same coordinate system

# Reference to overlay TextureRect nodes (set in _ready)
var highlight_overlays: Array[TextureRect] = []
var shadow_overlays: Array[TextureRect] = []

# Preloaded kingdom textures - using your actual file names
var kingdom_textures = {
	"highlight": [
		preload("res://assets/map/kingdoms/VylfodDominionHighlight.png"),
		preload("res://assets/map/kingdoms/RabaricRepublicHighlight.png"),
		preload("res://assets/map/kingdoms/KingdomofElRuhnHighlight.png"),
		preload("res://assets/map/kingdoms/KelsinFederationHighlight.png"),
		preload("res://assets/map/kingdoms/DivineEmpireofGosainHighlight.png"),
		preload("res://assets/map/kingdoms/YozuanDesertHighlight.png")
	],
	"shadow": [
		preload("res://assets/map/kingdoms/VylfodDominionShadow.png"),
		preload("res://assets/map/kingdoms/RabaricRepublicShadow.png"),
		preload("res://assets/map/kingdoms/KingdomofElRuhnShadow.png"),
		preload("res://assets/map/kingdoms/KelsinFederationShadow.png"),
		preload("res://assets/map/kingdoms/DivineEmpireofGosainShadow.png"),
		preload("res://assets/map/kingdoms/YozuanDesertShadow.png")
	]
}

func _ready():
	_collect_overlay_nodes()

func _collect_overlay_nodes():
	"""Find and store references to all kingdom overlay TextureRect nodes"""
	highlight_overlays.clear()
	shadow_overlays.clear()
	
	# Collect highlight overlays (Kingdom1-6Highlight)
	for i in range(1, 7):
		var highlight_node = find_child("Kingdom%dHighlight" % i, true, false) as TextureRect
		if highlight_node:
			highlight_node.texture = kingdom_textures["highlight"][i-1]
			highlight_node.visible = false
			highlight_overlays.append(highlight_node)
		else:
			push_error("Could not find Kingdom%dHighlight node" % i)
	
	# Collect shadow overlays (Kingdom1-6Shadow)  
	for i in range(1, 7):
		var shadow_node = find_child("Kingdom%dShadow" % i, true, false) as TextureRect
		if shadow_node:
			shadow_node.texture = kingdom_textures["shadow"][i-1]
			shadow_node.visible = false
			shadow_overlays.append(shadow_node)
		else:
			push_error("Could not find Kingdom%dShadow node" % i)
	
	print("[MapOverlayManager] Collected %d highlight and %d shadow overlays" % [highlight_overlays.size(), shadow_overlays.size()])

func highlight_kingdom(kingdom_index: int):
	"""Show highlight for selected kingdom, shadows for others"""
	if kingdom_index < 1 or kingdom_index > 6:
		push_error("Invalid kingdom index: %d (must be 1-6)" % kingdom_index)
		return
	
	print("[MapOverlayManager] Highlighting kingdom %d" % kingdom_index)
	
	# Hide all overlays first
	hide_all_overlays()
	
	# Show highlight for selected kingdom (convert to 0-based index)
	var selected_idx = kingdom_index - 1
	if selected_idx < highlight_overlays.size():
		highlight_overlays[selected_idx].visible = true
		print("[MapOverlayManager] Showing highlight for kingdom %d" % kingdom_index)
	
	# Show shadows for all other kingdoms
	for i in range(shadow_overlays.size()):
		if i != selected_idx:  # Don't shadow the selected kingdom
			shadow_overlays[i].visible = true
			print("[MapOverlayManager] Showing shadow for kingdom %d" % (i + 1))

func hide_all_overlays():
	"""Hide all kingdom overlays"""
	for overlay in highlight_overlays:
		overlay.visible = false
	for overlay in shadow_overlays:
		overlay.visible = false

func get_kingdom_center_screen_pos(kingdom_index: int, container_size: Vector2) -> Vector2:
	"""Get kingdom center position in screen coordinates"""
	# Load kingdom centers data
	const KingdomCenters = preload("res://assets/map/kingdoms/kingdom_centers.gd")
	
	var kingdom_names = [
		"Vylfod_Dominion",
		"Rabaric_Republic", 
		"Kingdom_of_El_Ruhn",
		"Kelsin_Federation",
		"Divine_Empire_of_Gosain",
		"Yozuan_Desert"
	]
	
	if kingdom_index < 1 or kingdom_index > kingdom_names.size():
		push_error("Invalid kingdom index: %d" % kingdom_index)
		return Vector2.ZERO
	
	var kingdom_name = kingdom_names[kingdom_index - 1]
	var svg_pos = KingdomCenters.KINGDOM_CENTERS[kingdom_name]
	
	return KingdomCenters.svg_to_screen(svg_pos, container_size)