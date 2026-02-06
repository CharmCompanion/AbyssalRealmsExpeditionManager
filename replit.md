# Abyssal Realms Expedition Manager

## Overview
A mobile-focused web game ported from a Godot 4.5 project, featuring an Idle MMO-inspired dark UI. The original Godot project files remain intact; the web version lives entirely in `web_game/`.

## Web Game Architecture
- **Backend**: Python/Flask serving on port 5000
- **Database**: PostgreSQL (Neon-backed via Replit)
- **Frontend**: Single-page app with vanilla JavaScript
- **Styling**: Idle MMO dark theme (CSS custom properties)

### Key Directories
- `web_game/` - Complete web game
  - `app.py` - Flask application with all API routes
  - `game_data.py` - Game constants (kingdoms, deities, biomes, buildings, resources)
  - `game_logic.py` - SimClock, DungeonThreatSystem, ExpeditionBoard, AutonomousExpeditions
  - `models.py` - SQLAlchemy SaveSlot model
  - `templates/index.html` - SPA with all game screens
  - `static/css/style.css` - Dark theme CSS
  - `static/images/map/` - Kingdom map PNGs (highlights, shadows, borders, water, names)

### Original Godot Project (preserved, not modified)
- `scripts/` - GDScript game logic
- `scenes/` - Godot scene files
- `assets/` - Game assets including kingdom map PNGs
- `addons/` - Godot plugins

## Game Systems
- **Save System**: 20-slot save/load/delete/copy with PostgreSQL persistence
- **Character Creation**: Town naming, lord naming, kingdom selection (6 kingdoms), deity assignment, seed-based resource generation, starting resource adjustment
- **Kingdom Map**: Interactive map with highlight/shadow PNG overlays per kingdom, draggable red blinking dot with pixel-based boundary detection
- **Town Management**: 10 buildings (Town Hall, Tavern, Barracks, Market, Farm, Mine, Lumber Mill, Temple, Library, Smithy) with upgrade levels and resource production
- **City Builder**: Zeus-inspired canvas-based grid (12x12) with placeable/rotatable medieval buildings using kit-bashed S13 City Builder 8-bit assets. Buildings placed via sidebar palette, validated for overlap/bounds, persisted to game_data.city_grid
- **Expeditions**: Job board (clear/scout/seal/gather missions), autonomous expedition system with departures/returns/loot/casualties
- **Dungeon Threats**: 3 dungeons per kingdom with growing threat levels, breach/raid system
- **SimClock**: Day-based progression via API ticks

## API Routes
- `GET /` - Main game page
- `GET /api/saves` - List all 20 save slots
- `POST /api/saves` - Create new save
- `POST /api/saves/<slot>/load` - Load save with computed info
- `DELETE /api/saves/<slot>` - Delete save
- `POST /api/saves/<slot>/copy` - Copy save
- `POST /api/saves/<slot>/update_dot` - Update town dot position
- `POST /api/saves/<slot>/update_city` - Save city grid layout
- `POST /api/game/tick` - Advance one day
- `POST /api/game/build` - Upgrade building
- `POST /api/game/expedition/start` - Start expedition
- `GET /api/map/boundary/<kingdom_id>` - Kingdom boundary positions

## Building Keys
Buildings use snake_case keys: town_hall, tavern, barracks, market, farm, mine, lumber_mill, temple, library, smithy

## Kingdom Data
6 kingdoms (Vylfod Dominion, Rabaric Republic, Kingdom of El'Ruhn, Kelsin Federation, Divine Empire of Gosain, Yozuan Desert) each mapped to a deity (Nivarius, Seraphina, Fortane, Thorn, Aurelia, Zephra)

## Deployment
- Development: `python -m web_game.app` (debug mode)
- Production: `gunicorn --bind=0.0.0.0:5000 --reuse-port web_game.app:app` (autoscale)

## Recent Changes
- 2026-02-06: Full web game implementation with all game systems ported from GDScript to Python/JS
- 2026-02-06: Interactive kingdom map with highlight/shadow PNG overlays and draggable boundary-constrained dot
- 2026-02-06: Fixed SQLAlchemy JSON column mutation detection with flag_modified
- 2026-02-06: Map boundary detection with finer resolution (step 10) and adjusted alpha threshold
- 2026-02-06: Added dot position persistence endpoint
- 2026-02-06: City Builder - Zeus-inspired canvas grid with kit-bashed S13 medieval building sprites, placement/rotation/demolish, persisted to game_data.city_grid
