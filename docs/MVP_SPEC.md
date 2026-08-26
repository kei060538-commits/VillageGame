# VillageGame MVP Specification

## Core fantasy
The player is an immortal young-looking witch who lives beside a small village. Villagers age, marry, have children, change jobs, and die while the witch remains unchanged. The witch can live in the village freely, but long periods of magical research accelerate time. Returning from research may mean meeting descendants of people the player once knew.

## MVP goal
The first playable build should prove three things:
1. A village of 20 autonomous residents feels alive enough to watch.
2. The player can physically live among them in a top-down 2D space.
3. Magic research is a separate puzzle loop that improves the village and prepares it for stronger monsters.

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
- Villagers can use discovered magic according to the village magic level
- Research uses magic-circle puzzles
- Research sessions can skip years or decades while the village simulation continues

## Provisional decisions for implementation
- One in-game year = 24 in-game days for the prototype.
- Villagers use utility-style scoring rather than fixed schedules.
- Each villager tracks hunger, energy, health, age, occupation, home position, current action, and a small relationship map.
- The first research puzzle is a 3x3 rune grid.
- Research level is shared as village magical knowledge.
- Monsters are initially represented as periodic threat pressure rather than full combat actors.
- Research tower interaction uses the E key.
- Movement uses WASD / arrow keys.

## First vertical slice
- Simple village map rendered with placeholder shapes
- Controllable witch
- 20 autonomous villagers
- 6-minute day/night clock
- Basic villager needs and jobs
- Village event log
- Research tower
- Small magic-circle puzzle
- Research level progression
- Simple monster threat meter that rises over time and is reduced by research

## Non-goals for this slice
- Final pixel art
- Marriage / childbirth / full genealogy
- Full combat
- Advanced economy
- Detailed disease simulation
- Hundreds of spells
- Multiple maps
- External towns
