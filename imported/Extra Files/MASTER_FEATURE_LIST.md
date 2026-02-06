# ABYSSAL REALMS EXPEDITION MANAGER - MASTER FEATURE LIST
*Comprehensive analysis of Town-Dungeon-master project for Godot conversion*

Generated: November 10, 2025

## 🎮 CORE GAME CONCEPT
**Genre**: Town Management + Dungeon Expedition RPG (Oregon Trail meets Fantasy City Builder)
**Role**: Player is a **Lord/Mayor** who manages a town and sends heroes on dungeon expeditions
**Setting**: Fantasy world with procedural dungeons, ancient ruins, and mystical elements

---

## 🏛️ TOWN MANAGEMENT SYSTEM

### 🏘️ City Building & Population
- **Population Management**: Peasants, merchants, nobles, unemployed/employed tracking
- **Building System**: Houses, farms, barracks, markets with level upgrades
- **Placement System**: Grid-based building placement with coordinates
- **Resource Production**: Buildings generate gold, food, population, security
- **Worker Assignment**: Assign population to work in different buildings
- **Housing Coverage**: Track population vs housing availability

### 💰 Resource Management
- **Primary Resources**: Gold (10,000-30,000 starting), Wood, Stone, Relics
- **Secondary Resources**: Food, Security levels
- **Resource Generation**: Buildings produce resources over time
- **Economic Balance**: Spending vs income from buildings and expeditions

### 😊 Happiness & Morale System
- **Overall Happiness**: City-wide satisfaction meter (0-100%)
- **Happiness Factors**: Housing, Food, Security, Employment, Entertainment, Health
- **City Statistics**: Crime rate, disease rate, migration pressure, service coverage
- **Dynamic Effects**: Happiness affects productivity and population growth

### 🏗️ Building Types & Progression
- **Houses**: Population growth, housing coverage
- **Farms**: Food production, sustenance
- **Barracks**: Security, military training
- **Markets**: Gold generation, trade
- **Guild Hall**: Hero recruitment and management
- **Dungeon Entrances**: Access points for expeditions
- **Level Upgrades**: Buildings can be upgraded for better efficiency

---

## 🗡️ HERO & EXPEDITION SYSTEM

### 👥 Hero Classes (4 Distinct Types)
- **Knight**: Tanky melee fighter, high HP and armor
- **Mage**: Magical damage dealer, spells and elemental attacks
- **Priest**: Healer and support, maintains party morale and health
- **Scout**: Agile explorer, trap detection and stealth abilities

### 📊 Advanced Stat System
- **Health (HP)**: Life points, damage absorption
- **Stamina (STA)**: Action points, affects ability usage
- **Sanity (SAN)**: Mental health, affected by dungeon horrors
- **Morale (MOR)**: Team spirit, affects performance
- **Corruption (COR)**: Dungeon influence, can invert equipment effects

### ⚔️ Equipment System (25+ Items)
- **Weapons**: Swords, staves, bows, daggers with unique stats
- **Armor**: Protection values, weight, durability
- **Tools**: Torches, rope, lockpicks, survival gear
- **Spellbooks**: Magical tomes with different spell types
- **Consumables**: Potions, rations, emergency supplies
- **Equipment Cards**: Detailed stat displays with effects and modifiers
- **Corruption Effects**: Equipment can become cursed/inverted

### 🏰 Procedural Dungeon System
- **Random Generation**: Each expedition creates new dungeon layouts
- **Biome Variety**: Different environments with unique challenges
- **Dynamic Depth**: Players choose target depth for risk/reward
- **Floor Progression**: Deeper floors = greater danger and rewards

### 🎲 Event System (Rich Encounter Variety)
- **Monster Battles**: Combat encounters with various creatures
- **Trap Encounters**: Mechanical and magical traps requiring skill checks
- **Environmental Hazards**: Collapsed tunnels, flooding, toxic gases
- **Ancient Libraries**: Knowledge and spell discovery opportunities  
- **Mysterious Altars**: Risk/reward magical interactions
- **Riddle Challenges**: Puzzle-solving for rewards
- **Treasure Discovery**: Loot chests, hidden caches
- **NPC Encounters**: Other explorers, merchants, hermits

---

## 🎯 PROGRESSION & META-SYSTEMS

### 📋 Quest & Contract System
- **Guild Contracts**: Accept missions for gold and reputation rewards
- **Task System**: Tutorial and progression objectives
- **Quest Tracking**: Multiple active objectives with completion states
- **Dynamic Objectives**: Quests that change based on town state

### 🏆 Achievement & Collection
- **Artifact Collection**: Rare items discovered in dungeons
- **Monster Cataloging**: Bestiary completion tracking
- **Treasure Hunting**: Valuable item collection
- **Achievement System**: Milestones and accomplishments (6/25 example)
- **Progress Tracking**: Comprehensive statistics for completionists

### 🕰️ Time & Calendar System
- **Game Calendar**: Year/day progression system
- **Expedition Duration**: Trips take time, affecting town management  
- **Seasonal Effects**: Time-based changes to resources and events
- **Historical Tracking**: Log of past expeditions and major events

### 💀 Permanent Consequences
- **Fallen Heroes**: Memorial system for lost party members
- **Equipment Loss**: Gear can be lost or destroyed in dungeons
- **Town Reputation**: Actions affect standing with various factions
- **Corruption Persistence**: Some effects carry over between expeditions

---

## 🎨 UI & AESTHETIC SYSTEMS

### 📚 Ancient Tome Theme
- **Book-Based Interface**: All UI designed as pages in an ancient tome
- **Parchment Backgrounds**: Aged paper textures throughout
- **Medieval Typography**: Period-appropriate fonts and styling
- **Illuminated Borders**: Decorative frames and ornamental elements

### 🎭 RPG UI Components  
- **Character Portraits**: Visual representation of heroes and lord
- **Stat Cards**: Detailed equipment and character information panels
- **Progress Bars**: Visual meters for health, resources, happiness
- **Modal Dialogs**: In-universe style popup information
- **Inventory Grids**: Organized equipment and item displays

### 🎵 Audio & Feedback Systems
- **Sound Effects**: Page turns, button clicks, ambient dungeon sounds
- **Audio Cues**: Success/failure feedback, notification sounds
- **Music Integration**: Atmospheric background music support
- **Volume Controls**: User preference management

### 📐 UI Layout Standards & Guidelines
*Established during Resource System Implementation (Phase 5)*

#### Grid Layout Rules:
- **Container Width**: All HBoxContainers must use 130px minimum width
- **Label Width**: All resource Labels must use 55px minimum width  
- **Button Size**: All adjustment Buttons must use 18x18px size
- **Input Size**: All LineEdits must use 35x15px size
- **Grid Separation**: 8px horizontal, 3px vertical for GridContainers
- **Internal Spacing**: 2px separation within HBoxContainers

#### Resource Organization Standards:
- **Resources Section**: Material resources (Gold, Food, Wood, Stone, Iron, Tools, Relics, Ether)
- **Economics Section**: Economic stats (People, Housing, Luxury, Culture, Security, Favor, Knowledge, Reputation)
- **Grid Layout**: 2x4 grids (4 columns, 2 rows) for both sections
- **Section Headers**: 14px font, color-coded (amber for Resources, blue for Economics)

#### Font Consistency Rules:
- **Section Headers**: 14px for "RESOURCES" and "ECONOMICS" titles
- **Standard Labels**: 9px for most resource/stat labels
- **Compact Labels**: 8px for longer text (Knowledge, Reputation)
- **Button Text**: 10px for all +/- adjustment buttons
- **Input Text**: 9px for all value input fields, center-aligned

#### Alignment Requirements:
- **Perfect Column Alignment**: Labels, buttons, and inputs must align vertically
- **Consistent Spacing**: All containers follow same internal structure
- **Visual Hierarchy**: Clear section separation with HSeparator dividers
- **Scalable Design**: Normalized positioning for responsive layouts

#### Implementation Standards:
- **Node Naming**: [Resource][Type] pattern (e.g., GoldLabel, GoldMinus, GoldInput, GoldPlus)
- **Parent Structure**: ResourcesGrid for materials, EconomicsGrid for stats
- **Signal Connections**: Centralized in _resolve_ui_nodes() function
- **State Management**: All adjustments trigger seed recalculation

*These standards ensure consistent, professional UI across all game screens and maintain perfect alignment regardless of content changes.*

---

## 🔧 TECHNICAL FEATURES

### 💾 Save System Requirements
- **Multiple Save Slots**: 4+ save files with detailed information display
- **Save File Data**: Town name, play time, resources, progression stats
- **Character Creation**: Lord customization with name, class, starting bonuses
- **Random Generation**: Procedural town names matching thematic style
- **Backup/Recovery**: Save file integrity and corruption protection

### 🎲 Random Generation Systems
- **Town Names**: Thematically appropriate procedural naming
- **Starting Resources**: Randomized initial gold/resources based on chosen god/goddess
- **Dungeon Layouts**: Procedural floor generation algorithms
- **Event Tables**: Random encounter generation with weighted probabilities
- **Loot Tables**: Equipment and treasure randomization

### ⚙️ God/Goddess Selection System
- **Divine Patrons**: Different deities provide starting bonuses
- **Blessing Effects**: Unique advantages based on chosen patron
- **Resource Modifiers**: Starting gold, population, resources affected by choice
- **Gameplay Style**: Each patron encourages different strategic approaches

---

## 🚀 IMMEDIATE IMPLEMENTATION PRIORITIES

### Phase 1: Core Save System (CURRENT)
- ✅ Save slot display with proper hover/selection
- ✅ Avatar sizing and slot styling
- ✅ Navigation flow (TopMenu → SaveSelect → TopMenu)
- 🔄 Character creation scene (CreateCharacter.tscn)
- 🔄 God/goddess selection with starting bonuses

### Phase 2: Character Creation
- Random town name generation
- Lord customization (name, appearance)  
- Divine patron selection system
- Starting resource calculation
- Save file creation and storage

### Phase 3: Core Town Management  
- Basic resource system (gold, wood, stone)
- Simple building placement
- Population management basics
- Resource generation over time

### Phase 4: Hero System Foundation
- Hero recruitment interface
- Basic stat system implementation
- Equipment assignment
- Simple expedition mechanics

---

## 📝 CONVERSION NOTES FOR GODOT

### Scene Structure Needed
- **TopMenu.tscn** ✅ (Complete)
- **SaveSelect.tscn** ✅ (Complete)  
- **CreateCharacter.tscn** (Next priority)
- **TownManagement.tscn** (Core gameplay)
- **HeroManagement.tscn** (Guild interface)
- **ExpeditionPlanning.tscn** (Pre-dungeon prep)
- **DungeonExploration.tscn** (Expedition gameplay)

### Data Systems Required
- Save/Load manager with JSON serialization
- Random generation utilities
- Resource management singleton
- Event system framework
- Audio manager for SFX/music

### Key Algorithms to Port
- Procedural name generation
- Random event selection
- Resource calculation formulas  
- Happiness/morale calculations
- Equipment stat systems

---

## 🤖 AI ASSISTANT INSTRUCTIONS

### 📋 MANDATORY READING FOR ALL AI ASSISTANTS
**Before starting ANY work session, AI assistants MUST read these files:**

1. **`PROJECT_RULES_AND_GUIDELINES.md`** - Core rules and behavior protocols
2. **`imported/UI_STYLING_CONTINUE_PROMPT.md`** - Current UI status and next steps
3. **This file (`MASTER_FEATURE_LIST.md`)** - Complete feature roadmap
4. **Any conversation summaries** provided in context

### 🔄 CURRENT SESSION CONTINUATION POINT

**Project Status:** UI Sizing & Positioning Phase  
**Last Updated:** November 12, 2025  

**IMMEDIATE PRIORITIES:**
1. **User needs to test CreateCharacter.tscn** - Elements intentionally made TOO SMALL
2. **User needs to test SaveSelect.tscn** - Buttons repositioned to bottom right
3. **User needs to test StatsMenu.tscn** - New scene structure verification

**Waiting For User Action:**
- Test current sizing in Godot
- Provide specific measurements for increases if elements too small
- Confirm button positioning is correct in SaveSelect
- Verify StatsMenu scene loads without errors

### ✅ COMPLETED WORK (Ready for Testing)
- ✅ SaveSelect loading errors fixed
- ✅ Kingdom panels gold outline styling restored  
- ✅ External resource UID warnings resolved
- ✅ Scrollbars eliminated from all scenes
- ✅ Aggressive size reduction applied to CreateCharacter (intentionally too small)
- ✅ SaveSelect buttons repositioned to bottom right corner
- ✅ StatsMenu scene created with full structure

### 📐 CRITICAL UI RULES
- **Brown Border Law:** ALL content MUST stay within brown book outline borders
- **No Scrollbars Ever:** User requirement - eliminate all ScrollContainer nodes
- **Gold Outline Theme:** Grey background (0.15, 0.15, 0.15, 0.6) + gold border (0.8, 0.6, 0.3, 0.8)
- **Responsive Design:** Use anchor-based positioning, not fixed pixels

### 🎯 NEXT STEPS PROTOCOL
1. **User Tests Current State** → Reports what needs adjustment
2. **AI Applies EXACT Measurements** → No guessing, follow user specifications
3. **Update Documentation** → Modify `imported/UI_STYLING_CONTINUE_PROMPT.md`
4. **Continue to Next Priority** → Move down the task list systematically

### 🔧 HOW TO ADD NEW FEATURES TO THIS LIST

**When adding new features or updating progress:**

1. **Find the appropriate section** (Town Management, Hero System, etc.)
2. **Add new items using this format:**
   ```markdown
   - **Feature Name**: Brief description with technical details
   ```
3. **Update Phase priorities** in the Implementation section
4. **Mark completed items** with ✅ in the progression tracking
5. **Add new scenes needed** to the Scene Structure section
6. **Update the conversion notes** if new technical requirements discovered

**When major milestones are reached:**
- Update the Phase completion status
- Move priorities from "Next" to "Current" 
- Add new phases as needed for discovered features

### 📝 FILE MAINTENANCE RULES

**This file should be updated when:**
- New features are discovered during implementation
- Game mechanics are clarified or expanded
- Technical requirements change
- Major phases are completed
- New UI scenes are needed

**Keep synchronized with:**
- `imported/UI_STYLING_CONTINUE_PROMPT.md` (current work status)
- `PROJECT_RULES_AND_GUIDELINES.md` (AI behavior rules)
- Actual scene files and implementation progress

---

*This master list serves as the complete roadmap for converting your Town-Dungeon-master browser game into the Godot-based Abyssal Realms Expedition Manager. All features have been analyzed and categorized for systematic implementation.*

**For AI Assistants:** Always read the continuation files first, then use this roadmap to understand the bigger picture and long-term goals while working on current tasks.