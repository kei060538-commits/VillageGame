# VillageGame MVP Specification

## Core fantasy
The player is an immortal young-looking witch who lives beside a small village. Villagers age, form relationships, inherit a changing culture, and die while the witch remains unchanged. The witch can live in the village freely, but magical research takes years or decades. Returning from the tower may mean meeting descendants of people the player once knew.

To villagers, the witch is a respected and increasingly legendary figure who disappears into research for long periods and returns when the village needs knowledge or protection.

## MVP goal
The first playable build should prove four things:
1. A village of 20 autonomous residents feels alive enough to watch and interact with.
2. The player can physically live among them in a top-down 2D space.
3. Magic research is a real puzzle system whose geometry has gameplay meaning.
4. Research changes village survival and is inherited by ordinary villagers.

## Fixed design decisions
- Engine: Godot 4.7
- View: 2D top-down
- Final art direction: pixel art
- Initial villagers: 20
- Player: immortal female witch, respected by villagers
- One in-game day: 6 real minutes at normal speed
- Endless play: hundreds of in-game years are possible
- Threats: hunger, disease, monsters
- Magic contributes to combat, healing, agriculture, construction, and weather
- Villagers can use discovered magic according to village knowledge, occupation, and aptitude
- Research uses magic-circle puzzles
- Shapes in a magic circle have semantic roles such as magical field, range/containment, power, duration, stability, and mana efficiency
- Research sessions can skip years or decades while the village simulation continues

## Provisional decisions for implementation
- One in-game year = 24 in-game days for the prototype.
- Villagers use utility-style scoring rather than fixed schedules.
- Each villager tracks hunger, energy, health, age, occupation, personality traits, relationships, respect for the witch, current action, and learned magic.
- The prototype magic-circle board is 3x3: center = field/core, corners = boundary, edges = mana flow.
- Research challenges are constraint puzzles and allow multiple valid solutions.
- Research level is shared as village magical knowledge.
- Monsters are initially represented as threat pressure rather than full combat actors.
- Food security and disease pressure are aggregate village systems for the current slice.
- Research tower interaction uses E; greeting nearby villagers uses F.
- Movement uses WASD / arrow keys.

## Current vertical slice
- Simple village map rendered with placeholder shapes
- Controllable immortal witch
- 20 autonomous villagers
- 6-minute day/night clock
- Needs, jobs, personality-biased decisions, sickness, and social relationships
- Village chronicle/event log
- Food security and disease pressure
- Research tower with long time skips
- Semantic magic-circle constraint puzzle
- Five magical fields: Healing, Agriculture, Construction, Weather, Combat
- Profession-based adoption of discovered magic by villagers
- Monster threat meter affected by village magical development
- Simplified generational replacement during long time skips

## Non-goals for this slice
- Final pixel art
- Full marriage / childbirth / genealogy
- Full combat actors and spell casting in the world
- Advanced economy and inventories
- Detailed disease taxonomy
- Hundreds of spells
- Multiple maps
- External towns
