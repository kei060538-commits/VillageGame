# Implementation Notes

This file records provisional choices made to get the game into a playable state quickly. They are not final design commitments.

## Current prototype rules
- Research breakthrough: completing one magic-circle puzzle advances one field and spends 12 in-game years.
- Magic fields rotate through Healing, Agriculture, Construction, Weather, and Combat for the first prototype.
- A year contains 24 prototype days so long time spans can be tested quickly.
- Generational turnover is currently simplified: villagers who are elderly after a research time-skip are replaced by a younger member of the same family and occupation. Full romance, childbirth, genealogy, inheritance, and household simulation will replace this shortcut later.
- Monster activity is currently represented by a threat percentage. Full monster actors and combat come later.
- Village visuals are placeholder vector shapes. They exist only to test movement and simulation before pixel art work begins.
- Villager behavior uses utility scores for eating, sleeping, working, socializing, and wandering.

## Next systems after the first playable build
1. Proper household/family/genealogy simulation.
2. Magic-circle puzzle rules based on geometry semantics rather than target matching alone.
3. Actual monster spawning and combat.
4. Disease and food-production simulation.
5. Persistent save/load and village-history archive.
6. Pixel-art map and character pipeline.
