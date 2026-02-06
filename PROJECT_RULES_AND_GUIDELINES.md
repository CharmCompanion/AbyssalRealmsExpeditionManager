# Project Rules & Guidelines for AI Assistants
**Project:** Abyssal Realms Expedition Manager  
**Last Updated:** November 12, 2025  
**Purpose:** Ensure consistent AI assistance across multiple machines (laptop & desktop PC)

---

## 🤖 MANDATORY AI BEHAVIOR RULES

### Rule 0: BACKUP FILES BEFORE ANY MODIFICATIONS (CRITICAL)

**BEFORE making ANY edits to scene (.tscn) or script (.gd) files, AI MUST:**

1. **Create Manual Backup:**
   - Create `.backup` file for EACH file being modified
   - Use PowerShell: `Copy-Item "path/to/file.tscn" "path/to/file.tscn.backup"`
   - Example: `CreateCharacter.tscn` → `CreateCharacter.tscn.backup`

2. **ASK USER PERMISSION Before Proceeding:**
   - Show user what changes will be made
   - Wait for explicit "yes" or "proceed" confirmation
   - Example: "I'm about to modify CreateCharacter.tscn to add 12 overlay nodes. Backup created at CreateCharacter.tscn.backup. May I proceed?"

3. **Delete Old Backup ONLY When User Approves:**
   - After successful changes, ASK: "Changes complete and tested. May I delete the old .backup file?"
   - Wait for explicit permission before deleting
   - If user says no, keep the backup

**WHY THIS IS CRITICAL:**
- Prevents catastrophic data loss from bad edits
- Allows instant rollback if changes fail
- User MUST approve each modification step
- Never assume user wants to proceed without asking

**VIOLATION = UNACCEPTABLE:**
If AI proceeds with file modifications without creating backup and getting permission first, this is a CRITICAL ERROR.

---

### Rule 1: ALWAYS Read Context Files First
**Before starting ANY work session, the AI assistant MUST:**

1. **Read the UI Status File:**
   - Location: `imported/UI_STYLING_CONTINUE_PROMPT.md`
   - Purpose: Understand current UI issues, completed work, and next steps
   - Action: Read ENTIRE file to get full context

2. **Check for Conversation Summary:**
   - May be provided in conversation context
   - Contains: Progress tracking, lessons learned, recent operations
   - Action: Review summary to understand what was done in previous sessions

3. **Check for Active TODO Lists:**
   - May exist in conversation context or separate files
   - Shows: In-progress work, completed items, pending tasks
   - Action: Continue from where previous session left off

4. **Read This Rules File:**
   - Location: `PROJECT_RULES_AND_GUIDELINES.md` (this file)
   - Purpose: Understand project-specific rules and workflows
   - Action: Follow all rules specified here

**Why This Matters:**
- User switches between laptop and desktop PC frequently
- Continuity is CRITICAL - AI must pick up exactly where previous session ended
- Prevents repeating work or missing context

---

### Rule 2: AUTO-UPDATE UI Status Files After Every Session

**After completing ANY work on UI elements, the AI MUST automatically update:**

#### Primary File to Update:
- **File:** `imported/UI_STYLING_CONTINUE_PROMPT.md`
- **When:** After ANY changes to `.tscn` files in `scenes/ui/` folder
- **What to Update:**
  1. Mark completed items with ✅
  2. Update "Current Status" section with new state
  3. Add any NEW issues discovered
  4. Update "Next Steps" with what still needs doing
  5. Add specifications for changes made (anchors, sizes, etc.)

#### Update Format:
```markdown
### [Scene Name] - [Brief Status]
**Status:** ✅/⏳/❌ 
**Last Modified:** [Date]
**Changes Made:**
- Specific change 1 with measurements
- Specific change 2 with measurements
**Current State:** [Description]
**Next Action Required:** [What user needs to test/do]
**Known Issues:** [Any problems remaining]
```

**DO NOT wait for user to ask** - this should happen automatically at the end of every session where UI work was done.

---

### Rule 3: Brown Book Border is ABSOLUTE Law

**CRITICAL UI CONSTRAINT:**

The brown outline/border of the book texture is the **ABSOLUTE BOUNDARY** for all UI content.

**Rules:**
- ✅ Content MUST stay within brown book border
- ❌ Content MUST NEVER overlap brown border
- ❌ Content MUST NEVER extend beyond brown border
- ❌ NO exceptions, NO compromises

**How to Ensure Compliance:**
1. Use anchor-based positioning (percentages, not fixed pixels)
2. When user says "elements are extending beyond border" → Make elements SMALLER
3. Reduce font sizes, panel sizes, and container sizes as needed
4. Test at multiple resolutions if possible

**If user reports overflow:**
- Don't just adjust containers - reduce ACTUAL content size (fonts, panels, margins)
- Be aggressive with size reductions
- Better too small than overlapping border

---

### Rule 4: Theme Styling Consistency

**ALL UI panels and containers MUST follow this theme:**

#### StyleBoxFlat Standard:
```gdscript
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_[name]"]
bg_color = Color(0.15, 0.15, 0.15, 0.6)  # Grey background with transparency
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.8, 0.6, 0.3, 0.8)  # Gold/bronze border
```

**Apply to:**
- All Panel nodes that should have backgrounds
- Save slots
- Selection panels (deity, kingdom, etc.)
- Content containers that need visual separation

**DO NOT:**
- Use double outlines (only one gold border per panel)
- Use inconsistent colors
- Add borders without backgrounds
- Create transparent panels where background is needed

**User Preference:** "I love the gold outline styling" - maintain this consistently

---

### Rule 4.1: Font Rule (MainMenu Standard)

**Effective immediately:** TownView (and all future UI) must match the MainMenu font style.

**Allowed fonts (ONLY):**
- `assets/ui/font/fibberish.ttf` → titles / primary headlines
- `assets/ui/font/quaver.ttf` → default UI text, most buttons/labels, smaller text
- `assets/ui/font/Bongo-8 Mono.ttf` → rare fallback only (almost never)

**Do NOT use anymore (legacy/forbidden in active UI):**
- `assets/ui/font/antiquity-print.ttf`
- Any `CrimsonText-*` fonts
- Any other fonts outside the 3 allowed files

**Implementation guidance:**
- Prefer the shared theme `assets/ui/theme/ui_fib_quaver.tres` for defaults (Quaver).
- Explicitly set Fibberish only where you need a title-like emphasis (like MainMenu Title).
- When adding new UI, copy the visual conventions (colors, outline/shadow usage) from `scenes/ui/MainMenu.tscn`.

---

### Rule 5: NO Scrollbars Ever

**User Requirement:** "I don't want any scrollbars ever never ever"

**Rules:**
- ❌ Never use ScrollContainer unless explicitly requested
- ❌ Never allow content to overflow requiring scrolling
- ✅ Always use responsive sizing
- ✅ Reduce content size to fit within containers
- ✅ Use proper size_flags and anchors for responsive layout

**If content doesn't fit:**
1. Reduce font sizes
2. Reduce panel sizes
3. Reduce padding/margins
4. Use tighter layouts (GridContainer with less separation)
5. Split content across pages if necessary

**Never suggest scrollbars as solution.**

---

### Rule 6: Responsive Design Requirements

**All UI elements MUST be responsive:**

**Use:**
- ✅ Anchor-based positioning (0.0 to 1.0 percentages)
- ✅ Relative sizing where possible
- ✅ Proper size_flags (SIZE_EXPAND_FILL, SIZE_SHRINK_CENTER)
- ✅ GridContainer/VBoxContainer/HBoxContainer for layouts

**Avoid:**
- ❌ Large fixed pixel values for margins (max 5-10px)
- ❌ Fixed panel sizes that don't adapt
- ❌ Hardcoded positions

**Test considerations:**
- Design should work at 1920x1080, 1366x768, 2560x1440
- Content should scale appropriately
- Nothing should break at different aspect ratios

---

### Rule 7: File Organization Standards

**Scene Files:**
- Location: `scenes/ui/` for UI scenes
- Naming: PascalCase (MainMenu.tscn, SaveSelect.tscn, CreateCharacter.tscn)

**Script Files:**
- Location: `scripts/ui/` for UI scripts
- Naming: Match scene name (MainMenu.gd, SaveSelect.gd, CreateCharacter.gd)

**Asset References:**
- Always use UIDs when available
- Keep .import files synchronized
- If UID warnings appear, fix them immediately

**Documentation:**
- `imported/` folder for reference documents
- `PROJECT_RULES_AND_GUIDELINES.md` (this file) in root
- Update UI_STYLING_CONTINUE_PROMPT.md after UI work

---

### Rule 8: Communication & Workflow

**When Starting Work:**
1. Read all context files (Rule 1)
2. Acknowledge what was done previously
3. State what you plan to do next
4. Ask for clarification if context is unclear

**When Making Changes:**
1. Explain what you're changing and why
2. Provide specific measurements (anchors, sizes, etc.)
3. Make changes
4. Verify with read_file if complex changes
5. Update documentation (Rule 2)

**When Encountering Issues:**
1. Report the issue clearly
2. Explain what you tried
3. Ask user for guidance if stuck
4. Don't repeat failed approaches

**When Session Ends:**
1. Summarize what was accomplished
2. Update UI_STYLING_CONTINUE_PROMPT.md
3. State clearly what needs testing
4. List next steps for continuation

---

### Rule 9: User Can Switch Machines Anytime

**CRITICAL:** User works on both laptop and desktop PC

**This means:**
- Any work done on laptop must be documented for desktop AI to continue
- Any work done on desktop must be documented for laptop AI to continue
- UI_STYLING_CONTINUE_PROMPT.md is the "source of truth" for current state
- Never assume continuity from same machine - always read context files first

**When user returns:**
- They may have made manual edits on other machine
- Always check current file state before editing
- Ask about manual changes if files differ from expected state

---

### Rule 10: Specific Size Adjustment Protocol

**After 3 days of trial/error, we learned:**

**When user says "elements are too big" or "extending beyond border":**

❌ **DON'T:** Just adjust container anchors or padding
❌ **DON'T:** Make small incremental changes
❌ **DON'T:** Focus only on container sizes

✅ **DO:** Reduce actual content dimensions:
- Reduce font sizes (e.g., 12px → 8px → 6px)
- Reduce panel custom_minimum_size and custom_maximum_size
- Reduce GridContainer heights
- Tighten anchor spacing (e.g., 0.195-0.805 → 0.30-0.70)
- Reduce all padding to 5px or less

✅ **DO:** Be aggressive with reductions:
- Better to go too small and increase than stay too large
- If user asks for "aggressive" sizing, make it DRAMATICALLY smaller
- User explicitly requested "make it too small so I have to ask you to increase"

✅ **DO:** Apply changes in batch:
- Use PowerShell batch operations for multiple similar changes
- Make all related changes at once (fonts + panels + containers)
- Verify with read_file after batch operations

---

## 📋 QUICK REFERENCE CHECKLIST

**Every AI Session Should:**
- [ ] Read UI_STYLING_CONTINUE_PROMPT.md first
- [ ] Read PROJECT_RULES_AND_GUIDELINES.md (this file)
- [ ] Check conversation summary if provided
- [ ] Verify current file state before editing
- [ ] Follow brown border boundary rule absolutely
- [ ] Maintain theme consistency (grey bg + gold border)
- [ ] Ensure no scrollbars are created
- [ ] Update UI_STYLING_CONTINUE_PROMPT.md after work
- [ ] Provide clear summary of changes with measurements
- [ ] State next steps for continuation

**Before Ending Session:**
- [ ] All changes documented in UI_STYLING_CONTINUE_PROMPT.md
- [ ] Specifications recorded (anchors, sizes, fonts, etc.)
- [ ] Testing requirements stated clearly
- [ ] Known issues listed
- [ ] Next steps identified

---

## 🎯 CURRENT PROJECT STATE

**Active Scenes:**
1. **CreateCharacter.tscn** - Character creation with deity/kingdom selection
2. **SaveSelect.tscn** - Save file selection and management
3. **MainMenu.tscn** - Main menu interface
4. **StatsMenu.tscn** - Statistics display (newly created)

**Current Focus:** UI sizing and positioning to ensure content stays within brown book borders

**Recent Major Changes:**
- EXTREME size reduction applied to CreateCharacter (intentionally too small)
- SaveSelect buttons repositioned to bottom right
- StatsMenu scene created from MainMenu template

**Awaiting:** User testing and feedback on current sizes/positions

---

## 🔧 TECHNICAL SPECIFICATIONS

**Engine:** Godot 4.5.1.stable.official

**Key Resources:**
- Font: CrimsonText-Bold.ttf (UID: uid://cn7yn72nerg5i)
- Audio: pageturn.mp3 (UID: uid://csxti8v6gb4sx), pageturn1.mp3 (UID: uid://c1i1uvymwq0uy)
- Textures: desk.png, book_open.png, map.png

**StyleBoxFlat Theme:**
- Background: Color(0.15, 0.15, 0.15, 0.6)
- Border: Color(0.8, 0.6, 0.3, 0.8), 2px width on all sides

**Current Size Baselines (CreateCharacter):**
- PageContainer: 0.30-0.70 horizontal, 0.24-0.76 vertical
- Deity panels: 35x30 min, 50x45 max
- Kingdom panels: 55x45 min, 80x60 max
- Font sizes: 5-8px

---

## 📝 VERSION HISTORY

**v1.0 - November 12, 2025**
- Initial rules document created
- Established mandatory AI behavior rules
- Documented theme standards and UI constraints
- Added workflow protocols for machine switching

---

**Questions about these rules?** Ask the user for clarification and update this document accordingly.

**New rules needed?** User can add them at any time - AI should incorporate and follow immediately.
