# Testing Guide - Character Creation & Map System

## Quick Start Testing

### Running the Scene
1. Open Godot project: `Abyssal Realms Expedition Manager`
2. Navigate to `scenes/ui/CreateCharacter.tscn`
3. Press F6 (Run Current Scene) or click "Run Current Scene" button
4. OR: From main menu, navigate to character creation

---

## Test Suite

### ✅ Test 1: Kingdom Selection
**What to Test**: Kingdom panel and map region clicks

**Steps**:
1. Launch CreateCharacter scene
2. Enter a lord name (e.g., "TestLord")
3. Select any deity from the left panel
4. Click a kingdom panel on the left side
5. **Expected**: 
   - Kingdom panel highlights
   - Map region brightens (that kingdom's area)
   - Other regions darken
   - Location resets to first location in that kingdom
   - City dot appears on map
   - Biome display updates
   - Seed value changes

6. Now click directly on a MAP REGION (the map on the right)
7. **Expected**:
   - Same effects as clicking kingdom panel
   - Kingdom panel syncs to match map selection

**Pass Criteria**:
- ✅ Map highlighting visible
- ✅ Kingdom panel and map clicks sync
- ✅ City dot appears at location
- ✅ Biome text updates
- ✅ Seed changes

---

### ✅ Test 2: Location Cycling
**What to Test**: < > buttons cycle through kingdom locations

**Steps**:
1. Continue from Test 1 (kingdom selected)
2. Note current location name in Location Preview label
3. Click ">" (next location) button
4. **Expected**:
   - Location name changes
   - City dot moves to new position
   - Biome/climate may change (depends on location)
   - Seed value changes

5. Click ">" nine more times (total 10 clicks)
6. **Expected**:
   - Cycles through all 10 locations for that kingdom
   - After 10th location, next click wraps to location 1

7. Click "<" (previous location) button
8. **Expected**:
   - Goes back to previous location
   - Wraps around if at location 1

**Pass Criteria**:
- ✅ 10 unique locations per kingdom
- ✅ City dot moves with each location
- ✅ Wraparound works (10 → 1 and 1 → 10)
- ✅ Biome/climate updates
- ✅ Seed recalculates

**Test All Kingdoms**:
- Vylfod Dominion (coastal/northern theme)
- Rabaric Republic (plains/farmland theme)
- Kingdom of El Ruhn (mountain theme)
- Kelsin Federation (coastal theme)
- Divine Empire of Gosain (sacred plains theme)
- Yozuan Desert (desert theme)

---

### ✅ Test 3: Resource Adjustments (Original 7)
**What to Test**: +/- buttons for original resources

**Steps**:
1. Locate resource input fields on right panel:
   - Gold, Population, Food, Wood, Stone, Iron, Mana

2. For each resource, test:
   - Click "+" button → value increases
   - Click "-" button → value decreases
   - Value should not go below 0
   - Seed should recalculate after each click

3. Note adjustment amounts:
   - Gold: ±500
   - Population: ±10
   - Food: ±25
   - Wood: ±15
   - Stone: ±10
   - Iron: ±5
   - Mana: ±10

**Pass Criteria**:
- ✅ All 14 buttons functional (7 × 2)
- ✅ Values update correctly
- ✅ No negative values
- ✅ Seed changes with each adjustment

---

### ✅ Test 4: Resource Adjustments (New 6)
**What to Test**: +/- buttons for new resources

**Steps**:
1. Locate NEW resource input fields (should be below Mana):
   - Housing Capacity
   - Luxury Goods
   - Tools
   - Culture
   - Security
   - Favor

2. For each resource, test same as Test 3:
   - Click "+" button → value increases
   - Click "-" button → value decreases
   - Value should not go below 0
   - Seed should recalculate

3. Note adjustment amounts:
   - Housing: ±10
   - Luxury: ±5
   - Tools: ±5
   - Culture: ±5
   - Security: ±5
   - Favor: ±10

**Pass Criteria**:
- ✅ All 12 buttons functional (6 × 2)
- ✅ Values update correctly
- ✅ No negative values
- ✅ Seed changes with each adjustment

---

### ✅ Test 5: Seed Determinism
**What to Test**: Same inputs = same seed

**Steps**:
1. Configure character:
   - Lord Name: "TestSeed"
   - Deity: Nivarius (God of Time)
   - Kingdom: Rabaric Republic
   - Location: Click ">" 3 times (4th location)
   - Set resources to specific values:
     - Gold: 5000
     - Population: 50
     - Food: 100
     - (leave others at defaults)

2. Note the seed value displayed

3. Exit scene and re-run

4. Configure EXACT same settings again

5. **Expected**: 
   - Seed value is IDENTICAL to step 2
   - Every number, letter, resource matches = same seed

**Pass Criteria**:
- ✅ Identical configuration produces identical seed
- ✅ Changing ANY value produces different seed
- ✅ Seed is numeric (not empty/null)

---

### ✅ Test 6: Deity Modifiers
**What to Test**: Different deities affect starting resources

**Note**: This tests the calculated starting_resources dictionary. Since display labels aren't in the scene yet, you'll need to check the console output or debugger.

**Steps**:
1. Select deity: **Thorn** (Earth goddess)
2. Select kingdom: Any
3. Open debugger/console
4. Look for starting_resources output (or check in character creation data)
5. **Expected**: 
   - High wood, stone, iron, tools, security
   - Normal food

6. Change deity to: **Fortane** (Darkness goddess)
7. **Expected**:
   - High gold, mana, luxury, favor
   - Low iron, security

7. Change deity to: **Aurelia** (Light goddess)
8. **Expected**:
   - High gold, population, mana, housing, culture, favor

**Pass Criteria**:
- ✅ Different deities produce different resource modifiers
- ✅ Modifiers match deity theme (Earth → materials, Light → prosperity)
- ⚠️ Visual confirmation limited (display labels not in scene)

---

### ✅ Test 7: Map Hover Effects
**What to Test**: Hovering highlights regions (without selection)

**Steps**:
1. Start fresh CreateCharacter scene
2. Select deity and kingdom (so one region is highlighted)
3. Hover mouse over a DIFFERENT map region
4. **Expected**:
   - Hovered region brightens
   - Selected region stays highlighted
   - Other regions stay dimmed

5. Move mouse away from map
6. **Expected**:
   - Hovered region returns to dim (if not selected)
   - Selected region remains highlighted

**Pass Criteria**:
- ✅ Hover brightens region temporarily
- ✅ Selection state preserved on unhover
- ✅ Can hover over selected region without issues

---

### ✅ Test 8: Complete Character Creation Flow
**What to Test**: Full workflow from start to character creation

**Steps**:
1. Launch CreateCharacter scene fresh
2. Enter Lord Name: "Adventurer"
3. Select Deity: Seraphina (Creation)
4. Select Kingdom: Kingdom of El Ruhn (mountains)
5. Cycle to 5th location using ">"
6. Adjust resources:
   - Gold: 6000
   - Population: 60
   - Housing: 80
   - Tools: 15
   - Security: 20

7. Verify seed has updated

8. Click "Create Character" button (if exists)
9. **Expected**:
   - Console shows character_data with all values
   - Includes all 13 resources
   - Includes location_index
   - Scene changes (if save system implemented)

**Pass Criteria**:
- ✅ All inputs captured correctly
- ✅ Character data includes location_index
- ✅ All 13 resources in saved data
- ✅ Seed is deterministic

---

## Visual Verification Checklist

### UI Elements to Verify:
- [ ] Lord Name input field visible and editable
- [ ] Town Name input field visible (or auto-generated name shown)
- [ ] 6 Deity panels visible on left side
- [ ] 6 Kingdom panels visible on left side
- [ ] Map image visible on right side
- [ ] Location controls visible:
  - [ ] "Location:" label
  - [ ] "<" button
  - [ ] Location name preview (e.g., "River Crossing")
  - [ ] ">" button
- [ ] Biome Preview label (e.g., "Biome: Grassland Plains")
- [ ] Climate Preview label (e.g., "Climate: Temperate...")
- [ ] Red city dot appears on map when kingdom selected
- [ ] 13 resource containers with +/- buttons:
  - [ ] Gold (default ~4000+)
  - [ ] Population (default ~50)
  - [ ] Food (default ~100)
  - [ ] Wood (default ~50)
  - [ ] Stone (default ~30)
  - [ ] Iron (default ~15)
  - [ ] Mana (default ~25)
  - [ ] Housing Capacity (default 75)
  - [ ] Luxury Goods (default 20)
  - [ ] Tools (default 10)
  - [ ] Culture (default 10)
  - [ ] Security (default 15)
  - [ ] Favor (default 50)

### Map Interaction to Verify:
- [ ] 6 invisible button regions cover map kingdoms
- [ ] Click on map region selects that kingdom
- [ ] Selected region appears brighter than others
- [ ] Hover effect visible on non-selected regions
- [ ] City dot appears as 12x12 red square
- [ ] City dot position changes with location cycling

---

## Known Issues & Limitations

### Not Yet Implemented:
1. **Resource Display Labels**: BlessingDisplay, StartingGoldDisplay, etc.
   - These Label nodes don't exist in the scene yet
   - _update_resource_displays() won't show anything
   - Calculated values exist but not visualized
   - **Workaround**: Check console for starting_resources dict

2. **TownPage Scene**: Placeholder only
   - No resource display during gameplay
   - Future work needed

3. **Resource Relationships**: No constraints yet
   - Population can exceed Housing (should be capped)
   - No cost interactions (Culture → Gold, Security → Iron)
   - Future enhancement

### Expected Behavior:
- Seed is a very large positive or negative integer
- Location cycling wraps at boundaries (0 ↔ 9)
- Map highlighting uses color modulation (no shaders)
- Default resource values from scene file (not generated until deity selected)

---

## Debug Console Commands

### Useful GDScript Debug Checks:
If you have access to the console/debugger, you can check:

```gdscript
print("Current Seed: ", current_seed)
print("Location Index: ", current_location_index)
print("Selected Kingdom: ", selected_kingdom)
print("Starting Resources: ", starting_resources)
print("Location Data: ", _get_current_location_data())
```

### Manual Inspection Points:
- **Line 765-796**: _recalculate_seed() - verify 18 parameters
- **Line 1075-1088**: starting_resources dict - verify all 13 keys
- **Line 1091-1130**: Deity modifiers - verify multipliers apply

---

## Regression Testing

### After Any Code Changes:
1. Re-run Test 1 (Kingdom Selection)
2. Re-run Test 2 (Location Cycling)
3. Re-run Test 5 (Seed Determinism)
4. Quick check all 26 resource buttons (13 × 2)

### Signs of Problems:
- ❌ City dot doesn't appear: Check CityDot node visibility
- ❌ Location doesn't change: Check signal connections
- ❌ Seed doesn't update: Check _recalculate_seed() calls
- ❌ Resources don't adjust: Check _adjust_resource() match cases
- ❌ Map regions don't highlight: Check _highlight_kingdom_region()

---

## Performance Testing

### Expected Performance:
- Kingdom selection: Instant (<10ms)
- Location cycling: Instant (<5ms)
- Resource adjustment: Instant (<5ms)
- Seed recalculation: Instant (<2ms)
- Map highlighting: Instant (modulate is GPU-accelerated)

### Red Flags:
- ⚠️ Lag when cycling locations (should be smooth)
- ⚠️ Slow seed recalculation (hash() is fast)
- ⚠️ Frame drops when adjusting resources

---

## Test Results Template

```
Date: [DATE]
Tester: [NAME]
Godot Version: [VERSION]

Test 1 - Kingdom Selection:       [ ] Pass  [ ] Fail  [ ] Skip
Test 2 - Location Cycling:         [ ] Pass  [ ] Fail  [ ] Skip
Test 3 - Original Resources:       [ ] Pass  [ ] Fail  [ ] Skip
Test 4 - New Resources:            [ ] Pass  [ ] Fail  [ ] Skip
Test 5 - Seed Determinism:         [ ] Pass  [ ] Fail  [ ] Skip
Test 6 - Deity Modifiers:          [ ] Pass  [ ] Fail  [ ] Skip
Test 7 - Map Hover Effects:        [ ] Pass  [ ] Fail  [ ] Skip
Test 8 - Complete Flow:            [ ] Pass  [ ] Fail  [ ] Skip

Issues Found:
- [Issue description]

Notes:
- [Any additional observations]
```

---

**GOOD LUCK WITH TESTING!** 🎮
