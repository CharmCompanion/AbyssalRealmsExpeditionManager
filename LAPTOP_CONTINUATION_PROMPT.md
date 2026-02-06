# 🌙 LAPTOP CONTINUATION — LORD CREATOR + PREVIEW (CreateTown)
**Project:** Abyssal Realms Expedition Manager
**Session Date:** Dec 15, 2025
**Status:** Lord creator stabilized + simplified ✅

---

## ✅ Update (Dec 17, 2025) — TownView UI, Map overlay, addon picks

### TownView UI changes
- Left icon bar is **thin again** and the toggle arrow is **inside the bar** (not a separate large button).
- When collapsed, the bar leaves a small **peek** so the arrow remains clickable.

### “Make the map work” (in-UI verification)
- Added a **Map overlay panel** (full-screen overlay) so the map can be checked inside the UI.
- Open/close:
   - Click the **City/Map icon** on the left bar
   - Press **F3**
   - Press **Esc** to close
- Map texture used: `res://assets/map/map.png`

### Addon decisions (no building addons for now)
- **Lord control (pick):** https://godotengine.org/asset-library/asset/3934 (State Machine Third Person Controller)
- **FreeCam (pick):** https://godotengine.org/asset-library/asset/4138 (Fly Camera)
- **Skip building templates/addons** for now; we’ll build a custom system later.

### Skill tree addon (approved)
- **Use:** https://godotengine.org/asset-library/asset/2270 (Worldmap Builder - Skill Trees and Level Select Menus)
- Intended in-game design: Lord skill trees grouped into 3 town-management categories:
   1) **Provisioning** (food, storage, logistics)
   2) **Governance** (laws, taxes, stability)
   3) **Crafting & Construction** (build efficiency, materials, production)

### Files touched for TownView update
- scenes/ui/TownView.tscn
- scripts/ui/TownView.gd

---

## ✅ Update (Dec 16, 2025) — TownView placeholders

### What we added
- TownView now has a **top bar portrait slot** (placeholder) that renders the Lord using the saved `run_code` → `lord_appearance` recipe.
- TownView now has a **40px left icon bar** (placeholder) with a Buildings icon; currently it just toggles the existing left building list visibility.

### Files touched
- scenes/ui/TownView.tscn
   - Applied the shared UI theme and added the portrait + left icon bar placeholder.
- scripts/ui/TownView.gd
   - Decodes `run_code`, reads `lord_appearance`, and applies it to the portrait rig.
   - Connects the Buildings icon to toggle the left building list.
- scripts/ui/LordModelPreview.gd
   - Added exported `center_offset` so the portrait framing can be centered differently than the full-body preview.

### Notes
- The icon popups / proper panel-sized menus are intentionally deferred; placeholders only for now.
- If the portrait looks off: tweak `preview_scale` + `center_offset` on the `PortraitRig` node in TownView.

### Next (when continuing)
- CreateTown options logic: resource step sizes (+1 start, +10 holding), “extra dungeons” slider clickability, seed-change/revert rules, Random across all tabs (except names).
- TownView UI: pause menu, tooltip redesign, and later convert icon buttons to open standard-size panels.
- Fix runtime issues: GOAP `world_state` nil crash, export-unsafe isometric tile loading warnings.

This prompt replaces the older “S13 UI reskin” continuation. Current focus is the Lord creation experience inside CreateTown.

---

## ✅ What we finished today

### 1) Fixed hard blockers (Godot parse errors + vanished parent warnings)
- Removed corrupted/duplicated trailing code that was breaking parsing.
- Cleaned old “vanished parent path” references in the Lord options UI.

### 2) Lord has **no weapon** and **no mount**
- Removed the weapon row and any weapon wiring.
- Removed mounts from the Lord UI.

### 3) Lord preview is now **body + clothing only**
The Lord preview rig and renderer were simplified so the Lord only uses:
- Body
- Head
- Hands
- Legs
- Chest
- Belt
- Shoes

Removed from Lord entirely:
- Weapons, Offhand, Shield
- Bag/backpack grid
- Mount
- Ranged/Magic
- Shadow/Effect/Slash/Special

### 4) Files that were edited (core)
- scenes/ui/CreateTown.tscn
   - Lord PreviewRig layers were pruned to “body + clothing only”.
   - Mounts/weapon UI elements removed.
   - Backpack/Off-hand grids removed from Lord UI.
- scripts/ui/LordModelPreview.gd
   - Renderer no longer knows about weapon/mount/combat/effect layers.
- scripts/ui/LordKitOptions.gd
   - Replaced with a clean implementation that only drives the clothing/body rows + idle actions.

---

## 📌 Current intended design (authoritative)

### Lord
- Purpose: cosmetic Lord look setup only.
- Has: body + clothing parts.
- Does NOT have: weapons, mounts, offhands, shields, ranged, magic.

### Adventurers (future)
- Adventurers may eventually have weapons/mounts, but those will be crafted-driven and may live in a separate system.
- We are not building the Adventurer creator right now.

---

## 🔜 What’s left to do next

### A) Quick validation pass in Godot (high priority)
- Open CreateTown and click into the Lord tab.
- Confirm there are no scene load warnings and the preview animates (Idle/Walk) with 8-direction rotation.
- Confirm each row changes the correct preview layer immediately.

### B) UI polish/cleanup (only if needed)
- If TopGrids is now mostly empty (Idles only), consider renaming/re-spacing it (keep simplest possible).
- Confirm the “Equipment” heading still makes sense now that Lord only has clothing/body parts.

### C) Save/serialize (later)
- Decide where the chosen Lord appearance should be stored (resource/save file fields) so TownView can load it.

---

## Notes / Constraints
- Keep Lord creator minimal: no hats/capes request anymore.
- Do not reintroduce weapon/mount UI for Lord.
- Adventurer creator is deferred.

---

## 🔥 Newly reported issues (Dec 15 late)

### 1) Script broke again: LordKitOptions parse error
Godot error:
- `res://scripts/ui/LordKitOptions.gd:328 - Parse Error: Expected statement, found "Indent" instead.`

What to do next:
- Open `scripts/ui/LordKitOptions.gd` and scroll to the reported line.
- Look for a stray indented block at top-level (common cause after merges/partial pastes).
- Fix by deleting the stray indented lines OR re-copying in the clean version.
- Re-run: the Lord tab should load without script errors.

### 2) Lord tab right panel layout is too wide (overflow)
Observed in-editor: the Lord Name + Equipment rows are spilling past the right panel width.

What to do next (layout goals):
- The right panel should fit everything, with vertical scrolling only.
- Align controls cleanly: arrows-to-arrows / swatches-to-swatches (don’t align to the check button).

Likely fixes in `scenes/ui/CreateTown.tscn` (do these when you’re ready):
- Reduce per-button `custom_minimum_size` in the row controls.
- Ensure each row HBox has sane `size_flags_horizontal` and children don’t expand unexpectedly.
- Ensure the container hierarchy constrains width (the ScrollContainer should not force children wider than the panel).
- Adjust the GridContainer columns/spacing so the two-column layout stays flush inside the panel.

5. If no messages at all → hover events not firing (mouse_filter problem)

**Possible Solutions:**
- If Glow/BG not found: Verify scene file structure matches expected hierarchy
- If hover not firing: Check mouse_filter settings in scene file
- If z_index issues: Ensure Glow has z_index = -1 and BG has z_index = -1

### Priority 2: Enlarge Map ⏳
**User Request:** "Map is so hard to see or read - need it larger"  
**Current Issue:** Map texture on CreateCharacter scene is too small for readability  
**Requirements:**
- Increase map size while staying within brown book borders
- Maintain responsive layout
- Consider placing map on its own page/section

**Implementation Plan:**
1. Find map node in CreateCharacter.tscn (search for "map.png")
2. Increase custom_minimum_size or anchor coverage
3. Test at different resolutions
4. Ensure no overflow beyond brown borders

### Priority 3: SVG Zoom System ⏳
**User Request:** "Add SVG addon for infinite zooming with mask effect"  
**Vision:** Default size shows map through cutout window, can zoom in/out without extending past mask  
**Requirements:**
- Integrate SVG addon (user mentioned it before)
- Create mask/viewport effect
- Map zooms behind mask, never extends past boundaries
- Infinite zoom capability

**Implementation Plan:**
1. Research Godot SVG addon options
2. Create SubViewport or ClipContainer for mask effect
3. Implement zoom controls (mouse wheel? +/- buttons?)
4. Ensure map center point stays fixed during zoom
5. Add visual borders/frame around map window

### Priority 4: Kingdom Location Marker System ⏳
**User Request:** "Show blinking dot on map when kingdom selected, randomly placed in that kingdom's colored area"  
**Requirements:**
- Each kingdom has defined color area on map
- When kingdom panel clicked → random point in that color area
- Blinking/animated dot marker (visible and attention-grabbing)
- "Randomize Location" button next to town name input
- Marker changes when different kingdom selected

**Implementation Plan:**
1. Define kingdom color regions (pixel coordinates or polygon areas)
2. Create random point generator within region bounds
3. Add AnimatedSprite2D or ColorRect with animation for blinking dot
4. Connect to kingdom selection system (`_select_kingdom` function)
5. Add "Randomize" button next to town name LineEdit
6. Update marker position on button press

### Priority 5: Dynamic Seed System ⏳
**User Request:** "Seed number must update when ANY configuration changes - lord name, deity, kingdom, town name, or stats"  
**Vision:** Every unique configuration = unique seed number for exact reproduction  
**Requirements:**
- Seed updates on:
  - Lord name text change
  - Deity panel selection
  - Kingdom panel selection
  - Town name change
  - Any custom stat adjustments
- Seed is deterministic (same inputs = same seed)
- Can input seed to restore exact configuration

**Implementation Plan:**
1. Create hash function combining all inputs:
   ```gdscript
   func _calculate_seed_from_config() -> int:
       var config_string = str(lord_name, deity_name, kingdom_name, town_name, custom_stats)
       return config_string.hash()
   ```
2. Connect signals:
   - `lord_name_input.text_changed` → `_recalculate_seed()`
   - `_select_deity()` → `_recalculate_seed()`
   - `_select_kingdom()` → `_recalculate_seed()`
   - `town_name_input.text_changed` → `_recalculate_seed()`
3. Implement reverse: seed input → restore configuration
4. Store configuration alongside seed in save file

---

## 🧪 TESTING INSTRUCTIONS

### Test 1: TopMenu Gold Hover ✅
1. Launch game
2. Hover over Start/Settings/Quit buttons
3. **Expected:** Buttons show gold tint (Color(1.0, 0.8, 0.3, 0.3))
4. **If white:** Check TopMenu.gd for GOLD_GLOW_COLOR constant

### Test 2: SaveSelect Button Hover ✅
1. Open SaveSelect scene
2. Hover over Copy/Delete/Select/Back buttons
3. **Expected:** Buttons show gold tint + hover sound plays
4. **If no effect:** Check SaveSelect.gd `_wire_bottom_bar()` connections

### Test 3: CreateCharacter Panel Hover ⏳ **NEEDS USER TESTING**
1. Open CreateCharacter scene
2. Open console/output panel
3. Hover over Nivarius deity panel
4. **Check console for:**
   - "[CreateCharacter] Deity hover: Nivarius"
   - "[CreateCharacter] Applied hover glow to: Nivarius"
   - "[CreateCharacter] Set BG color to: Color(...)"
   - "[CreateCharacter] Set Glow visible: true on panel: NivariusPanel"
5. **If no output:** Hover events not firing
6. **If ERROR messages:** Scene structure doesn't match script expectations
7. **If output OK but no visual glow:** z_index or visibility issue

---

## 📋 QUICK REFERENCE CHECKLIST

### ✅ Completed Items:
- [x] Brown border containment (perfect positioning)
- [x] Text readability (appropriate font sizes)
- [x] Input box sizing (consistent heights)
- [x] Panel standardization (uniform sizing)
- [x] Mouse event detection (`mouse_filter = 0` on all panels)
- [x] TopMenu button gold hover
- [x] SaveSelect button gold hover
- [x] CreateCharacter debug logging added

### ⏳ In Progress / Pending:
- [ ] CreateCharacter glow verification (needs user testing with debug output)
- [ ] Map enlargement (not started)
- [ ] SVG zoom system (not started)
- [ ] Kingdom location marker system (not started)
- [ ] Dynamic seed system (not started)

### 🎯 Next Session Goals:
1. **IMMEDIATE:** User tests CreateCharacter hover and provides console output
2. **NEXT:** Fix any glow issues based on debug output
3. **THEN:** Enlarge map for better readability
4. **THEN:** Implement SVG zoom with mask effect
5. **THEN:** Add kingdom location marker system
6. **FINALLY:** Implement dynamic seed system

---

**STATUS:** Gold theme standardized across all UI | CreateCharacter glow needs testing  
**CONFIDENCE:** High for completed work | Medium for CreateCharacter glow (awaiting user feedback)  
**NEXT MILESTONE:** Map enhancements and location marker system  

---

## 🏗️ TOWN VIEW SYSTEM CREATED (December 9, 2025)

### ✅ COMPLETED:
1. **Created TownView.tscn** - Redesigned with book UI style (no book graphic, matches other scenes)
2. **Created TownView.gd** - Full script with grid generation, building previews, resource management
3. **Linked "Found Settlement" button** - CreateCharacter now transitions to TownView after character creation
4. **Building models imported** - All 7 buildings in assets/buildings/ (.glb format)
5. **Created townview.txt** - Design documentation updated with grid specifications
6. **Grid plane system** - 20x20 grid with 2-meter cells, procedurally generated

### 📐 UI Layout (REDESIGNED):
- **Desk background** - Same as other scenes for visual continuity
- **Parchment placeholder** - Beige ColorRect matching book page color
- **PageContainer** - Uses exact same anchors as CreateCharacter (0.153, 0.068, 0.847, 0.932)
- **Top bar** - Resource displays with medieval font (Gold, Wood, Stone)
- **Left panel** - Building panels with 3D model preview + name below (80px height each)
- **Center** - SubViewport with isometric grid plane (20x20 cells, 2m each = 40m x 40m)
- **Right panel** - Selected building info, Place/Rotate/Back buttons

### 🎨 Styling Details:
- **Font**: antiquity-print.ttf throughout
- **Text color**: Brown (0.68235, 0.54118, 0.14902) matching other UIs
- **Grid texture**: Procedural parchment with brown grid lines
- **Building previews**: Each building has own SubViewport with isometric camera
- **Compact design**: Tight spacing, smaller fonts (9-14px) to fit more content

### 🏘️ Buildings Available:
1. Academy (School.glb) - Essential
2. Temple (Temple.glb) - Essential  
3. Adventurer's Guild (Guild.glb) - Essential
4. Bank (Bank.glb) - Essential
5. Cottage (Cottage.glb) - Housing
6. Estate (Estate.glb) - Housing
7. Lord's Manor (Manor.glb) - Housing

### 🔄 MAJOR UI REDESIGN (December 9, 2025 - Second Session):

**User Feedback:** "UI looks like crap, building panels should be squares not rectangles, map twice as wide, building info as hover tooltip, add top bar with lord/town/resources"

**Changes Made:**
1. **Square building panels** - Changed from 280x80px to 150x150px squares
2. **Larger previews** - SubViewport height increased from 50px to 120px
3. **Removed right info panel** - Replaced with floating hover tooltip
4. **Enhanced top bar** - Added 2 rows:
   - Row 1: Lord name, Town name, Deity name
   - Row 2: Gold, Wood, Stone, Iron, Food, Population
5. **Wider map** - Center view now 2x wider (size_flags_stretch_ratio = 2.0, viewport 1024x600)
6. **Left panel narrower** - Reduced from 280px to 180px to give map more space
7. **Hover tooltips** - Show building info on mouse_entered, hide on mouse_exited
8. **Script rewrite** - Removed all right panel references, added hover events, character data integration

### 🎨 TODO (Priority Order):
1. **CRITICAL: Load character data from CreateCharacter** - Currently shows "Unknown" placeholders for lord/town/deity
2. **Building drag & drop on grid** - Currently places at center (0,0,0)
3. **Grid cell highlighting on hover** - Show which cell mouse is over
4. **Snap-to-grid for building placement** - Align to 2m grid cells
5. **Multiple building instances** - Currently only places one at center
6. **Building rotation** - 90° rotation before/after placement
7. **Camera pan/zoom for town view** - Navigate large settlements
8. **Save/load settlement data** - Persist building positions
9. **Parchment texture asset** - Replace beige ColorRect placeholder
10. **Book closing → parchment scroll animation** - Scene transition effect

### 📁 Files Modified (Latest Session):
- `scenes/ui/TownView.tscn` - COMPLETELY REDESIGNED (square panels, wider map, hover tooltip, enhanced top bar)
- `scripts/ui/TownView.gd` - REWRITTEN (removed right panel logic, added hover events, character data fields)
- `townview.txt` - UPDATED with new square layout specs

**TRANSITION FLOW:** MainMenu → SaveSelect → CreateCharacter → **TownView** (NEW)

---

*This document provides complete context for continuing development. Please test CreateCharacter hover with console output and report findings before proceeding to map work.*