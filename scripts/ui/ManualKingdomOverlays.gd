extends Control
class_name ManualKingdomOverlays

## Uses the manually created PNG kingdom overlays for perfect alignment
## Your PNG files have exact shapes and guaranteed coordinate system match

# Preload your manually created kingdom overlay textures
var kingdom_overlays = {
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

var overlay_nodes: Array[TextureRect] = []

func _ready():
	setup_overlay_nodes()

func setup_overlay_nodes():
	"""Create TextureRect nodes for each kingdom overlay"""
	
	# Clear existing overlay nodes
	for child in get_children():
		if child is TextureRect:
			child.queue_free()
	
	overlay_nodes.clear()
	
	# Create one TextureRect for each kingdom (will switch between highlight/shadow)
	for i in range(6):
		var overlay = TextureRect.new()
		overlay.name = "KingdomOverlay" + str(i + 1)
		# Match the base map positioning and size exactly
		var parent_container = get_parent()
		var base_map = parent_container.get_node_or_null("MapBackground") if parent_container else null
		if base_map:
			overlay.anchor_left = base_map.anchor_left
			overlay.anchor_top = base_map.anchor_top
			overlay.anchor_right = base_map.anchor_right
			overlay.anchor_bottom = base_map.anchor_bottom
			overlay.offset_left = base_map.offset_left
			overlay.offset_top = base_map.offset_top
			overlay.offset_right = base_map.offset_right
			overlay.offset_bottom = base_map.offset_bottom
			overlay.stretch_mode = base_map.stretch_mode
		else:
			# Fallback positioning
			overlay.anchor_left = 0.0
			overlay.anchor_top = 0.0
			overlay.anchor_right = 1.0
			overlay.anchor_bottom = 1.0
			overlay.stretch_mode = TextureRect.STRETCH_KEEP
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.visible = false
		
		add_child(overlay)
		overlay_nodes.append(overlay)
	
	print("[ManualKingdomOverlays] Created ", overlay_nodes.size(), " overlay nodes")

func highlight_kingdom(kingdom_index: int):
	"""Show selected kingdom highlighted, all others darkened"""
	if kingdom_index < 1 or kingdom_index > 6:
		hide_all_overlays()
		return
	
	print("[ManualKingdomOverlays] Highlighting kingdom ", kingdom_index)
	
	# Show all kingdoms - selected one highlighted, others shadowed
	for i in range(overlay_nodes.size()):
		if i < 6:  # Only handle 6 kingdoms
			if i == kingdom_index - 1:
				# Show highlight for selected kingdom
				if i < kingdom_overlays["highlight"].size():
					overlay_nodes[i].texture = kingdom_overlays["highlight"][i]
					overlay_nodes[i].visible = true
					overlay_nodes[i].modulate = Color.WHITE
			else:
				# Show shadow for other kingdoms
				if i < kingdom_overlays["shadow"].size():
					overlay_nodes[i].texture = kingdom_overlays["shadow"][i]
					overlay_nodes[i].visible = true
					overlay_nodes[i].modulate = Color(0.7, 0.7, 0.7, 0.8)  # Darker shadow
			print("[ManualKingdomOverlays] Showing shadow for kingdom ", i + 1)

func hide_all_overlays():
	"""Hide all kingdom overlays"""
	for overlay in overlay_nodes:
		overlay.visible = false
	
	# Also remove any shadow overlays
	for child in get_children():
		if child.name.begins_with("KingdomShadow"):
			child.queue_free()

func get_overlay_node(kingdom_index: int) -> TextureRect:
	"""Get the overlay node for a specific kingdom"""
	if kingdom_index >= 1 and kingdom_index <= overlay_nodes.size():
		return overlay_nodes[kingdom_index - 1]
	return null