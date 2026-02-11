# TileSet Tagger (batch labeling)

There are now two ways to tag tiles:

1) **Editor Dock (recommended)**
  - Enable the TileSet Tagger plugin and use the panel with tile previews.
  - See: [addons/tileset_tagger/README.md](addons/tileset_tagger/README.md)

2) **Script-based JSON tool**
  - Keep using `tileset_tagger.gd` if you prefer editing JSON directly.
  - It can dump, build a map, and apply custom data from JSON.

## Example tag list entry

```
{
  "source_id": 12,
  "type": "TileSetAtlasSource",
  "texture": "res://imported/Map and Character/Fantasy tileset - 2D Isometric/Environment/Ground/Ground A1_E.png",
  "tiles": [
    {"atlas_coords": [0, 0], "tag": "ground_plains"}
  ]
}
```

## What the output looks like

```
{
  "tileset": "res://assets/tilesets/fantasy_iso/Fantasy_Ground.tres",
  "tags": [
    {"source_id": 12, "atlas_coords": [0, 0], "tag": "ground_plains"}
  ]
}
```

## Notes

- Most of your sources appear to be 1-tile atlases, so `atlas_coords` will usually be `[0, 0]`.
- The output JSON is meant for your placement system to interpret tile meaning.
