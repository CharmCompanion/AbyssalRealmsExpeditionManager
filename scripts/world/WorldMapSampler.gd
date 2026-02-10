extends Node
class_name WorldMapSampler

## WorldMapSampler
##
## Loads color-coded world maps (biomes, countries, water mask) and exposes
## fast tile-based queries:
##   - get_biome_at_tile(tile: Vector2i) -> int
##   - get_country_at_tile(tile: Vector2i) -> int
##   - is_water(tile: Vector2i) -> bool
##
## Assumptions / defaults:
## - Biome ID map:           res://assets/map/Biomes.png
## - Country ID map:         res://assets/map/map.png
## - Water mask map:         res://assets/map/kingdoms/Water.png
## - Per-kingdom overlays:   res://assets/map/kingdoms/*.png (optional, not yet
##   wired into queries but available for future use such as highlighting
##   current kingdom or drawing borders).
##
## Each unique RGB color in the biome/country maps is assigned a stable
## integer ID starting from 0 in load order. You can treat those IDs as
## biome/country enums elsewhere.
##
## World/tile coordinate mapping:
## - WORLD_W_TILES / WORLD_H_TILES are given by export properties. If they
##   are left as 0, they will default to the dimensions of the first loaded
##   map (biome or country).
## - Tile coords are mapped to image pixels using normalized UVs so the
##   aspect ratio is preserved even if the map images and tile grid differ.

@export_file("*.png") var biome_map_texture: String = "res://assets/map/Biomes.png"
@export_file("*.png") var country_map_texture: String = "res://assets/map/map.png"
@export_file("*.png") var water_mask_texture: String = "res://assets/map/kingdoms/Water.png"

@export_group("World Grid")
@export var world_width_tiles: int = 0
@export var world_height_tiles: int = 0

var _biome_image: Image
var _country_image: Image
var _water_image: Image

var _biome_color_to_id: Dictionary = {}
var _country_color_to_id: Dictionary = {}

func _ready() -> void:
	_load_maps()

func reload_maps() -> void:
	"""Explicitly reload all images and rebuild color palettes."""
	_load_maps()

func get_world_size_tiles() -> Vector2i:
	return Vector2i(max(1, world_width_tiles), max(1, world_height_tiles))

func get_biome_at_tile(tile: Vector2i) -> int:
	"""Return biome ID for given tile, or -1 if unknown/undefined."""
	if _biome_image.is_empty():
		return -1
	var p: Vector2i = _tile_to_pixel(tile, _biome_image)
	_biome_image.lock()
	var c: Color = _biome_image.get_pixel(p.x, p.y)
	_biome_image.unlock()
	var key: int = _color_key(c)
	return _biome_color_to_id.get(key, -1)

func get_country_at_tile(tile: Vector2i) -> int:
	"""Return country ID for given tile, or -1 if unknown/undefined."""
	if _country_image.is_empty():
		return -1
	var p: Vector2i = _tile_to_pixel(tile, _country_image)
	_country_image.lock()
	var c: Color = _country_image.get_pixel(p.x, p.y)
	_country_image.unlock()
	var key: int = _color_key(c)
	return _country_color_to_id.get(key, -1)

func is_water(tile: Vector2i) -> bool:
	"""Return true if tile is water according to the water mask image.

	If no water mask is configured or loaded, this will always return false.
	You can extend this later to derive water from a dedicated biome ID if you
	prefer a single combined map.
	"""
	if _water_image.is_empty():
		return false
	var p: Vector2i = _tile_to_pixel(tile, _water_image)
	_water_image.lock()
	var c: Color = _water_image.get_pixel(p.x, p.y)
	_water_image.unlock()
	# Treat non-transparent pixels as water. Adjust threshold as needed
	# depending on how Water.png is authored.
	return c.a > 0.1

# -----------------------------------------------------------------------------
# Internal loading / palette building
# -----------------------------------------------------------------------------

func _load_maps() -> void:
	_biome_image = Image.new()
	_country_image = Image.new()
	_water_image = Image.new()
	_biome_color_to_id.clear()
	_country_color_to_id.clear()

	if biome_map_texture != "":
		_biome_image = _load_image_res(biome_map_texture)
		if not _biome_image.is_empty():
			if world_width_tiles <= 0:
				world_width_tiles = _biome_image.get_width()
			if world_height_tiles <= 0:
				world_height_tiles = _biome_image.get_height()
			_biome_color_to_id = _build_palette(_biome_image)

	if country_map_texture != "":
		_country_image = _load_image_res(country_map_texture)
		if not _country_image.is_empty():
			if world_width_tiles <= 0:
				world_width_tiles = _country_image.get_width()
			if world_height_tiles <= 0:
				world_height_tiles = _country_image.get_height()
			_country_color_to_id = _build_palette(_country_image)

	if water_mask_texture != "":
		_water_image = _load_image_res(water_mask_texture)

func _load_image_res(path: String) -> Image:
	# Export-safe way to obtain an Image from an imported texture resource.
	if not ResourceLoader.exists(path):
		return Image.new()
	var res: Resource = load(path)
	if res == null:
		return Image.new()
	if res is Texture2D:
		var img: Image = (res as Texture2D).get_image()
		if img == null:
			return Image.new()
		return img
	# Fallback: try loading directly from disk (editor-only / debug).
	var img_file := Image.new()
	var err := img_file.load(path)
	if err == OK:
		return img_file
	return Image.new()

func _build_palette(img: Image) -> Dictionary:
	# Build a dictionary mapping RGB colors -> compact integer IDs.
	var palette: Dictionary = {}
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 0 or h <= 0:
		return palette
	img.lock()
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a <= 0.05:
				continue
			var key: int = _color_key(c)
			if not palette.has(key):
				var new_id: int = palette.size()
				palette[key] = new_id
	img.unlock()
	return palette

static func _color_key(c: Color) -> int:
	# Quantize to 8-bit RGB and pack into a 24-bit integer key.
	return (int(c.r8) << 16) | (int(c.g8) << 8) | int(c.b8)

# -----------------------------------------------------------------------------
# Tile <-> pixel mapping
# -----------------------------------------------------------------------------

func _tile_to_pixel(tile: Vector2i, img: Image) -> Vector2i:
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 0 or h <= 0:
		return Vector2i()
	var ww: int = max(1, world_width_tiles)
	var hh: int = max(1, world_height_tiles)

	var u: float = clamp(float(tile.x) / float(ww), 0.0, 0.999999)
	var v: float = clamp(float(tile.y) / float(hh), 0.0, 0.999999)

	var px: int = int(u * float(w))
	var py: int = int(v * float(h))
	return Vector2i(px, py)
