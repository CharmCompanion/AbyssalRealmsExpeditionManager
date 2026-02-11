# TileSet Tagger (Editor Panel)

This editor dock lets you batch-tag tiles with a preview so you know what you're labeling.
Tags are stored in the TileSet custom data layer named `tag`.

## Enable the plugin
1) In Godot: Project -> Project Settings -> Plugins.
2) Enable **TileSet Tagger**.
3) A new dock appears on the right.

## Workflow
1) Click **Browse** to pick a TileSet (.tres).
2) Click **Load**.
3) Select tiles using:
   - **Click** to select a single tile (clears current selection).
   - **Shift‑click** to multi‑select tiles.
   - **Ctrl‑click** to toggle selection (add/remove without clearing others).
   - **Alt‑click** to clear the tag on that tile.
4) Enter metadata for selected tiles:
   - **Tag**: Semantic label (e.g., `building_house_small`)
   - **Direction**: N, NE, E, SE, S, SW, W, NW, or None
   - **Animation**: Check if this tile is an animation frame
   - **Type**: Animation type (e.g., walk, idle, attack) - auto-detected from folder path
5) Click **Apply** to apply all metadata (or enable Paint mode).
6) **Paint mode**: Check "Paint" to apply metadata on each click (Alt‑click erases).
7) **History dropdown**: Previously used tags appear in the dropdown for quick reuse.
8) Optional: use **Dump** or **Export Map** to create JSON files.

## JSON files
- **Dump** writes `tileset_tags.json` (all tiles + current tags).
- **Import** reads a JSON and applies tags to the TileSet.
- **Export Map** writes a compact tag map for gameplay code.

## Notes
- This only supports atlas sources (the common case in your kit).
- Tags are stored in the TileSet itself, so renaming files won't break logic.
- History is saved to `tools/tileset_tagger/tag_history.json` and persists across sessions.
- Metadata is stored in custom data layers: `tag`, `direction`, `is_animation`, `animation_type`.
- Animation type is auto-detected from folder names like `/walk/`, `/idle/`, `/attack/` in the texture path.
- When selecting a tile, existing metadata is loaded and displayed in the UI.
