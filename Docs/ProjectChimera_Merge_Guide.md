# Project Chimera Merge & 3D Transition Guide

This document details every step required to merge your existing game into the new Project Chimera design, transition from 2D isometric to 3D, and update all relevant systems and assets. Use this as a checklist and reference during your migration.

---

## Table of Contents

1. Overview
2. Inventory & Audit
3. Removal of Deprecated Systems
4. 3D World & Town Layout
5. 3D Character Creator
6. 3D Pet System
7. Building & System Mapping
8. UI & Camera Overhaul
9. Save/Load System Update
10. Testing & Validation
11. Final Checklist

---

## 1. Overview

- **Goal:** Merge all relevant features from your current game into Project Chimera, update to a full 3D workflow, and remove obsolete systems (NPCs, expeditions, etc.).
- **Scope:** Covers asset, code, and design migration, with a focus on modularity and future expansion.

---

## 2. Inventory & Audit

**Steps:**
- List all current game systems, assets, and scripts.
- Categorize each as: _Keep_, _Update_, or _Remove_.
- Document dependencies between systems (e.g., expeditions depend on NPCs).

**Deliverable:**  
_A spreadsheet or markdown list of all systems/assets with their migration status._

---

## 3. Removal of Deprecated Systems

**Remove:**
- NPC/adventurer creation, management, and related UI.
- Expedition mechanics (sending parties out of town, expedition maps, rewards).
- Any 2D-specific rendering, sprites, or UI code not reusable in 3D.

**Action:**
- Comment out or delete code/assets.
- Update documentation to reflect removals.

---

## 4. 3D World & Town Layout

**Steps:**
- Design a 3D town hub with all required buildings (see Project Chimera spec).
- Block out the town using primitive meshes (cubes, planes) for initial prototyping.
- Plan navigation paths and building placement for player and pets.

**Deliverable:**  
_A Godot scene file with the basic 3D town layout and placeholder buildings._

---

## 5. 3D Character Creator

### A. Asset Preparation
- Create/import modular 3D meshes: head, torso, arms, legs, hair, accessories, clothing.
- Rig all parts to a common skeleton for animation compatibility.
- Prepare texture/material variants for customization.

### B. System Implementation
- Build a Godot scene for the character creator.
- Attach modular parts as children of a root node (e.g., `CharacterBody3D`).
- Implement UI for part selection, color picking, and preview.
- Add save/load functionality for character configurations.

### C. Animation
- Import or create basic animations (idle, walk, run).
- Ensure all modular parts animate correctly with the skeleton.

**Deliverable:**  
_A working 3D character creator scene in Godot, with modular customization and animation preview._

---

## 6. 3D Pet System

**Steps:**
- Update pet assets to 3D (modular if possible, or use simple low-poly models).
- Implement pet following/player interaction in 3D.
- Update pet stat display and management UI for 3D context.
- Prepare basic pet animations (idle, walk, interact).

**Deliverable:**  
_A 3D pet system integrated into the town scene, with basic interaction and stat display._

---

## 7. Building & System Mapping

**Steps:**
- Map old buildings to new Project Chimera equivalents (e.g., Temple → Clinic).
- Remove or repurpose buildings not needed in the new design.
- Update building interaction logic for 3D (proximity triggers, world-space UI).
- Ensure all core buildings from the Chimera spec are present and functional.

**Deliverable:**  
_A mapping table of old→new buildings, and updated building scripts in Godot._

---

## 8. UI & Camera Overhaul

**UI:**
- Redesign all UI for 3D (use Godot’s `Control` nodes, world-space overlays as needed).
- Update HUDs for player, pet, and building interactions.

**Camera:**
- Implement 3D camera controls (orbit, follow, zoom).
- Ensure camera works well with town layout and character movement.

**Deliverable:**  
_New 3D UI scenes and camera scripts._

---

## 9. Save/Load System Update

**Steps:**
- Update save data structures to include 3D character/pet configurations and town state.
- Ensure compatibility with new modular systems.
- Test saving/loading of all major game states.

**Deliverable:**  
_Updated save/load scripts and documentation._

---

## 10. Testing & Validation

**Steps:**
- Playtest all migrated systems in 3D.
- Check for missing features, bugs, or broken interactions.
- Validate that all Project Chimera core loops (pet management, building use, combat preview) function as intended.

**Deliverable:**  
_A bug/issue tracker and playtest feedback notes._

---

## 11. Final Checklist

- [ ] Inventory complete, all systems categorized.
- [ ] Deprecated systems removed.
- [ ] 3D town layout blocked out.
- [ ] 3D character creator functional.
- [ ] 3D pet system integrated.
- [ ] Buildings mapped and updated.
- [ ] 3D UI and camera implemented.
- [ ] Save/load system updated.
- [ ] Core gameplay tested and validated.

---

**Keep this document updated as you progress. Each section can be expanded with more detail or subtasks as needed.**