# Antigravity Prompt

## Purpose
This prompt is designed to allow seamless continuation of your Abyssal Realms Expedition Manager project when switching from VS Code to another environment (such as Google Antigravity). It contains all necessary context, rules, features, todos, and progress to ensure you can resume work without missing any details.

---

## Copilot Rules (as established)
- Always act as an agent: take action when possible, do not ask unnecessary questions if you can simply do something useful.
- Never terminate a task until it is fully resolved or impossible to continue.
- Use concise, action-oriented todos and update their status as you work.
- When editing files, never use `...existing code...` to represent unchanged regions Always redo the code as each file is copy and pase/.
- Never output code blocks or terminal commands unless explicitly requested.
- Always use markdown links for file and line references.
- Use KaTeX for math formatting.
- Never repeat yourself after a tool call; pick up where you left off.
- Never reference notebook cell IDs in user messages.
- Always keep the user’s workflow and context continuity as the top priority.

---

## Project: Abyssal Realms Expedition Manager

### Game Overview
Abyssal Realms Expedition Manager is a dungeon tycoon/expedition management game. The player manages expeditions, resources, and town development in a fantasy world. The project is structured for modularity and extensibility, with a focus on AI-driven planning, world generation, and user interface customization.

### Major Features (Thoroughly Explained)

#### 1. Expedition System
- Players organize and send expeditions into dungeons.
- Expeditions have objectives, party composition, inventory, and risk/reward mechanics.
- AI and player-driven decision-making for route, tactics, and resource allocation.

#### 2. Town Management
- Build, upgrade, and manage various buildings (Bank, Cottage, Estate, Guild, Manor, School, Temple, etc.).
- Each building provides unique benefits, unlocks, and resource flows.
- Town layout and upgrades impact expedition success and resource generation.

#### 3. AI Planning (GdPlanningAI Addon)
- Modular AI system for NPC and expedition planning.
- Supports autoload utilities, debug tools, and script templates for custom AI behaviors.
- Integrates with Godot’s node and resource system for extensibility.

#### 4. World Map & Biomes
- Procedural world map generation with diverse biomes.
- Biomes affect available resources, expedition risks, and town expansion.
- Visualized with custom tilesets and overlays.

#### 5. Character & Party System
- Create, customize, and manage adventurers.
- Party composition, skills, equipment, and relationships affect expedition outcomes.
- Character progression and event-driven storylines.

#### 6. UI/UX Panels & Tabs
- Modular UI panels for expedition, town, and character management.
- Tabbed interfaces for multitasking and quick access to game systems.
- Fullscreen and center panel support for immersive management.

#### 7. Scripting & Modding Support
- Organized scripts for AI, appearance, world, and tools.
- Addon structure for easy integration of new features and mods.
- Documentation and templates for community contributions.

#### 8. Audio & Visual Assets
- Custom sfx, tilesets, and UI assets for a cohesive fantasy aesthetic.
- Support for importing new assets and updating existing ones.

---

## Todos (Current)
- [ ] Finalize expedition AI logic and integrate with UI.
- [ ] Complete town building upgrade paths and effects.
- [ ] Polish world map generation and biome interactions.
- [ ] Expand character creation and progression systems.
- [ ] Refine UI/UX for multitasking and accessibility.
- [ ] Document all major systems for modding support.
- [ ] Playtest and balance resource flows and expedition risks.

---

## What’s Been Done Already
- Modular folder structure established for scripts, assets, and addons.
- GdPlanningAI addon integrated for advanced AI planning.
- Initial world map and biome system implemented.
- Core UI panels and tab system created.
- Basic town management and building system in place.
- Character and party system framework started.
- Audio/visual asset pipeline set up.
- Documentation started for major systems and modding.

---

## How to Use This Prompt
- Use this document as your main reference when switching to another environment.
- All rules, features, todos, and progress are up to date as of December 25, 2025.
- Update this file as you make progress or change requirements.
- Treat this as your “session memory” to continue work seamlessly.

---

_Last updated: December 25, 2025_
