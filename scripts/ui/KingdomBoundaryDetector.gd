extends Node
class_name KingdomBoundaryDetector

## Detects valid positions within kingdom shapes for accurate dot placement
## Uses the user's manually created PNG overlays to find white areas

static func find_valid_dot_position(kingdom_index: int, map_container: Control) -> Vector2:
	"""Find a valid position within the kingdom's white highlighted area"""
	
	# Get the manual overlays node
	var manual_overlays = map_container.get_node_or_null("ManualKingdomOverlays")
	if not manual_overlays:
		print("[KingdomBoundary] ManualKingdomOverlays not found - using fallback center")
		return _get_fallback_center(kingdom_index, map_container)
	
	# Get the highlighted overlay texture for this kingdom
	var overlay_nodes = manual_overlays.get("overlay_nodes")
	if not overlay_nodes or kingdom_index - 1 >= overlay_nodes.size():
		print("[KingdomBoundary] No overlay node for kingdom ", kingdom_index)
		return _get_fallback_center(kingdom_index, map_container)
	
	var overlay_rect = overlay_nodes[kingdom_index - 1] as TextureRect
	if not overlay_rect or not overlay_rect.texture:
		print("[KingdomBoundary] No texture for kingdom ", kingdom_index)
		return _get_fallback_center(kingdom_index, map_container)
	
	# Sample the texture to find white pixels (highlighted areas)
	var texture = overlay_rect.texture
	var image = texture.get_image()
	if not image:
		return _get_fallback_center(kingdom_index, map_container)
	
	var map_rect = map_container.get_rect()
	var valid_positions = []
	
	# Sample points in a grid to find white areas
	var sample_step = 20  # Check every 20 pixels
	for x in range(0, image.get_width(), sample_step):
		for y in range(0, image.get_height(), sample_step):
			var pixel = image.get_pixel(x, y)
			
			# Check if pixel is white/highlighted (adjust threshold as needed)
			if pixel.r > 0.9 and pixel.g > 0.9 and pixel.b > 0.9 and pixel.a > 0.5:
				# Convert image coordinates to screen coordinates
				var screen_x = (float(x) / image.get_width()) * map_rect.size.x + map_rect.position.x
				var screen_y = (float(y) / image.get_height()) * map_rect.size.y + map_rect.position.y
				valid_positions.append(Vector2(screen_x, screen_y))
	
	if valid_positions.size() > 0:
		# Return a position near the center of valid positions
		var center_pos = Vector2.ZERO
		for pos in valid_positions:
			center_pos += pos
		center_pos /= valid_positions.size()
		
		print("[KingdomBoundary] Found ", valid_positions.size(), " valid positions for kingdom ", kingdom_index)
		return center_pos
	
	print("[KingdomBoundary] No valid positions found - using fallback")
	return _get_fallback_center(kingdom_index, map_container)

static func _get_fallback_center(kingdom_index: int, map_container: Control) -> Vector2:
	"""Fallback to original center-based positioning"""
	var map_rect = map_container.get_rect()
	
	# Simple fallback centers for each kingdom
	var fallback_centers = [
		Vector2(0.2, 0.3),  # Kingdom 1
		Vector2(0.5, 0.2),  # Kingdom 2  
		Vector2(0.8, 0.3),  # Kingdom 3
		Vector2(0.3, 0.7),  # Kingdom 4
		Vector2(0.7, 0.6),  # Kingdom 5
		Vector2(0.5, 0.8)   # Kingdom 6
	]
	
	if kingdom_index >= 1 and kingdom_index <= fallback_centers.size():
		var rel_pos = fallback_centers[kingdom_index - 1]
		return Vector2(
			rel_pos.x * map_rect.size.x + map_rect.position.x,
			rel_pos.y * map_rect.size.y + map_rect.position.y
		)
	
	return map_rect.get_center()