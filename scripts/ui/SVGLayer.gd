@tool
extends TextureRect
class_name KingdomOverlay

## Custom node that extracts and renders a specific SVG path from Map.svg at runtime
## Uses Image.load_svg_from_string() for infinite scalability without pre-exports

@export_file("*.svg") var svg_source: String = "res://assets/map/Map.svg":
	set(value):
		svg_source = value
		if is_node_ready():
			_update_texture()

@export var kingdom_name: String = "":
	set(value):
		kingdom_name = value
		if is_node_ready():
			_update_texture()

@export_enum("highlight", "shadow") var layer_type: String = "highlight":
	set(value):
		layer_type = value
		if is_node_ready():
			_update_texture()

@export var overlay_color: Color = Color(1.0, 0.95, 0.7, 0.5):
	set(value):
		overlay_color = value
		modulate = overlay_color

@export var render_width: int = 2000  # High res for quality when zooming
@export var render_height: int = 1200

var _cached_texture: ImageTexture = null

func _ready():
	print("[KingdomOverlay] _ready called for: ", name, " (", kingdom_name, " - ", layer_type, ")")
	expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = overlay_color
	_update_texture()

func _update_texture():
	print("[KingdomOverlay] _update_texture called for: ", kingdom_name, " (", layer_type, ")")
	if not svg_source or not kingdom_name:
		print("[KingdomOverlay] WARNING: Missing svg_source or kingdom_name!")
		return
	
	# Map kingdom names to SVG path IDs (using underscores as in the actual SVG)
	var layer_mapping = {
		"Vylfod Dominion": "Vylfod_Dominion",
		"Rabaric Republic": "Rabaric_Republic", 
		"Kingdom of El Ruhn": "Kingdom_of_El_Ruhn",
		"Kingdom of ElRuhn": "Kingdom_of_El_Ruhn",  # Handle both naming variants
		"Kelsin Federation": "Kelsin_Federation",
		"Divine Empire of Gosain": "Divine_Empire_of_Gosain",
		"Yozuan Desert": "Yozuan_Desert"
	}
	
	var svg_layer_name = layer_mapping.get(kingdom_name, kingdom_name)
	var path_id = svg_layer_name
	print("[KingdomOverlay] Looking for SVG path ID: ", path_id)
	
	# Extract and render the specific SVG path
	var svg_path_data = _extract_svg_path(path_id)
	if svg_path_data.is_empty():
		push_error("[KingdomOverlay] ERROR: Could not find SVG path: " + path_id)
		return
	
	print("[KingdomOverlay] Found SVG path data (", svg_path_data.length(), " characters)")
	
	# Create minimal SVG with CORRECT viewBox to match Map.svg exactly
	var fill_color = "#FFFFFF" if layer_type == "highlight" else "#000000"
	var isolated_svg = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 843.75 568.5" width="%d" height="%d">
	<path d="%s" fill="%s" fill-opacity="0.6"/>
</svg>""" % [render_width, render_height, svg_path_data, fill_color]
	
	# Render SVG to Image at runtime
	var image = Image.new()
	var error = image.load_svg_from_string(isolated_svg, 1.0)
	
	if error == OK:
		_cached_texture = ImageTexture.create_from_image(image)
		texture = _cached_texture
		print("[KingdomOverlay] Rendered %s %s at %dx%d" % [kingdom_name, layer_type, render_width, render_height])
	else:
		push_error("Failed to render SVG path: " + path_id)

func _extract_svg_path(path_id: String) -> String:
	"""Extract the 'd' attribute from an SVG path element by ID"""
	if not FileAccess.file_exists(svg_source):
		return ""
	
	var file = FileAccess.open(svg_source, FileAccess.READ)
	if not file:
		return ""
	
	var svg_content = file.get_as_text()
	file.close()
	
	# Parse SVG to find path with matching id
	var parser = XMLParser.new()
	parser.open_buffer(svg_content.to_utf8_buffer())
	
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			if parser.get_node_name() == "path":
				# Check if this path has our target id
				for i in range(parser.get_attribute_count()):
					if parser.get_attribute_name(i) == "id":
						if parser.get_attribute_value(i) == path_id:
							# Found it! Extract the 'd' attribute
							for j in range(parser.get_attribute_count()):
								if parser.get_attribute_name(j) == "d":
									return parser.get_attribute_value(j)
	
	return ""

func refresh_at_scale(scale_factor: float = 1.0):
	"""Re-render the SVG at a different resolution for zoom levels"""
	render_width = int(2000 * scale_factor)
	render_height = int(1200 * scale_factor)
	_update_texture()
