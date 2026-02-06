## Final Fantasy Crystal Chronicles: My Life as a King

### 1. Town Building
- Core Loop: Play as a young king rebuilding a ruined kingdom.
- Construction: Place buildings (houses, shops, guilds, facilities) on a grid-based map. Each building unlocks new gameplay features or resources.
- Resource Management: Use “Elementite” (magical resource) to construct buildings and expand the town.
- Upgrades: Buildings can be upgraded for increased benefits (e.g., more residents, better equipment).
- Expansion: Unlock new areas for construction as the game progresses.

### 2. Missions & Adventuring
- Indirect Control: The king does not fight; instead, he recruits adventurers (NPCs) to explore dungeons and defeat monsters.
- Mission Assignment: Assign quests to adventurers via the Adventurer’s Guild. Missions vary in difficulty and rewards.
- Progress Reports: Adventurers return with reports, loot, and experience, which can be used to improve the town or adventurers.
- Party Formation: Adventurers form parties based on their classes and relationships.

### 3. Narrative & Event Systems
- Daily Cycle: The game operates on a day-by-day schedule. Each day, players plan actions, assign missions, and manage the town.
- Story Progression: Narrative unfolds through scripted events, character interactions, and town growth milestones.
- Special Events: Festivals, visiting characters, and story events provide unique opportunities and challenges.

### 4. NPC Interactions
- Adventurers: Recruit, train, and equip NPCs. Each has stats, classes, and personalities.
- Residents: Townsfolk provide feedback, requests, and can be influenced by town development.
- Relationships: NPCs develop relationships, affecting party formation and mission success.

### 5. Subsystems
- Economy: Shops generate income, which can be reinvested.
- Research: Unlock new building types and upgrades via research.
- Customization: Town layout and aesthetics can be personalized.
- Feedback Loops: Success in missions leads to town growth, which enables tougher missions and more complex management.

---

## Final Fantasy Crystal Chronicles: My Life as a Darklord

### 1. Tower Defense & Dungeon Building
- Core Loop: Play as the Darklord’s daughter, defending a tower from invading heroes.
- Floor Construction: Build and customize tower floors with traps, monsters, and obstacles.
- Resource Management: Use “Dark Power” to build floors and summon monsters.
- Strategic Placement: Each floor type and monster has strengths/weaknesses; placement is key to defense.

### 2. Missions & Waves
- Hero Waves: Heroes attack in waves, each with unique abilities and classes.
- Objective: Prevent heroes from reaching the top of the tower.
- Progression: New floors, monsters, and traps are unlocked as the game advances.

### 3. Narrative & Event Systems
- Story Progression: Narrative unfolds through cutscenes and boss battles.
- Special Events: Unique hero types, boss waves, and story-driven challenges.

### 4. NPC Interactions
- Monsters: Summon and manage monsters with different stats and abilities.
- Heroes: Each hero has AI behaviors, requiring adaptive defense strategies.

### 5. Subsystems
- Upgrades: Monsters and traps can be upgraded for better defense.
- Resource Economy: Balance spending on immediate defense vs. long-term upgrades.
- Customization: Tower layout and monster selection can be tailored to player strategy.

---

## Design Lessons & References

### References
- [My Life as a King - Wikipedia](https://en.wikipedia.org/wiki/Final_Fantasy_Crystal_Chronicles:_My_Life_as_a_King)
- [My Life as a Darklord - Wikipedia](https://en.wikipedia.org/wiki/Final_Fantasy_Crystal_Chronicles:_My_Life_as_a_Darklord)
- [GameFAQs Guides](https://gamefaqs.gamespot.com/wii/943676-final-fantasy-crystal-chronicles-my-life-as-a-king/faqs)
- [IGN Reviews](https://www.ign.com/games/final-fantasy-crystal-chronicles-my-life-as-a-king)

### Design Lessons
- Indirect Control: Both games use indirect player agency (managing NPCs or defenses) rather than direct combat, encouraging strategic planning.
- Daily/Turn-Based Cycles: Structuring gameplay around daily cycles or waves provides clear pacing and opportunities for feedback.
- Event-Driven Progression: Scripted events and milestones keep the narrative engaging and provide variety.
- NPC Depth: Giving NPCs personalities, relationships, and growth systems adds depth and replayability.
- Resource Management: Balancing short-term needs (defense, missions) with long-term growth (town/tower upgrades) creates meaningful choices.
- Customization: Allowing players to personalize layouts and strategies increases engagement.
- Feedback Loops: Success leads to more options, creating a satisfying sense of progression.

---

## Implementation Planning Tips

- Subsystem Modularity: Design town/tower building, mission assignment, event handling, and NPC management as modular systems for flexibility.
- Data-Driven Events: Use event scripting to trigger narrative and gameplay changes.
- AI Behaviors: Implement simple but varied AI for NPCs and enemies to encourage strategic planning.
- UI/UX: Provide clear feedback on daily cycles, mission results, and resource changes.
- Scalability: Plan for expanding content (new buildings, monsters, events) via data files or DLC.
