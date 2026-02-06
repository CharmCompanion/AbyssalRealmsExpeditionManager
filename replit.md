# Abyssal Realms Expedition Manager

## Overview
This is a **Godot 4.5** game project ("Abyssal Realms Expedition Manager") imported from GitHub. Since Godot is a desktop game engine, a Flask-based web project viewer has been set up to browse the project's documentation, file structure, scenes, scripts, and assets through a web interface.

## Project Architecture
- **Game Engine**: Godot 4.5 (GDScript)
- **Web Viewer**: Python/Flask app serving on port 5000
- **Main Scene**: `scenes/ui/MainMenu.tscn`
- **Key Directories**:
  - `scenes/` - Godot scene files (.tscn)
  - `scripts/` - GDScript game logic (.gd)
  - `assets/` - Game assets (sprites, textures, UI elements)
  - `addons/` - Godot plugins (GdPlanningAI, LimboAI, worldmap_builder, etc.)
  - `Chimera3D_Scaffold/` - 3D generation scaffolding
  - `Docs/` - Project documentation
  - `ai/` - AI task scripts
  - `imported/` - Imported resources and notes
  - `seed/` - Seed/data files
  - `tools/` - Tool scripts

## Web Viewer (Flask App)
- `app.py` - Main Flask application
- `templates/` - Jinja2 HTML templates
- `static/css/` - Stylesheet
- Routes:
  - `/` - Project overview with stats
  - `/browse/` - File browser
  - `/docs/` - Documentation listing
  - `/raw/<path>` - Raw file serving

## Recent Changes
- 2026-02-06: Initial Replit setup with Flask project viewer
