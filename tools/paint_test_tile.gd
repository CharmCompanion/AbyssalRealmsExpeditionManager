@tool
extends EditorScript

const SCENE_PATH := "res://scenes/world/overworld/OverworldTest.tscn"

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("[PaintTest] Failed to load scene: %s" % SCENE_PATH)
		return

	var root := packed.instantiate()
	var layer := root.get_node_or_null("GroundLayer") as TileMapLayer
	if layer == null:
		push_error("[PaintTest] GroundLayer not found in scene.")
		return

	var ts := layer.tile_set
	if ts == null:
		push_error("[PaintTest] GroundLayer has no TileSet assigned.")
		return

	var source_id := -1
	var atlas_coords := Vector2i.ZERO
	for i in range(ts.get_source_count()):
		var sid := ts.get_source_id(i)
		var source := ts.get_source(sid)
		if source is TileSetAtlasSource:
			var atlas := source as TileSetAtlasSource
			if atlas.get_tiles_count() > 0:
				atlas_coords = atlas.get_tile_id(0)
				source_id = sid
				break

	if source_id == -1:
		push_error("[PaintTest] No atlas tiles found in the TileSet.")
		return

	layer.set_cell(Vector2i.ZERO, source_id, atlas_coords, 0)
	packed.pack(root)
	if ResourceSaver.save(packed, SCENE_PATH) != OK:
		push_error("[PaintTest] Failed to save scene.")
		return

	print("[PaintTest] Wrote one tile at (0,0) using source %d coords %s." % [source_id, atlas_coords])
