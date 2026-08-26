# Implementation Notes

This file records provisional choices made to get the game into a playable state quickly. They are not final design commitments.

## Current prototype rules
- Research uses a semantic 3x3 magic circle rather than exact-pattern matching.
- The center glyph selects the magical field, corner glyphs mainly shape range/containment, and edge glyphs mainly control power, duration, and mana flow.
- A research challenge specifies minimum power/range/stability/duration and a maximum mana cost. Multiple circle layouts can satisfy the same challenge.
- Magic fields currently rotate through Healing, Agriculture, Construction, Weather, and Combat.
- A successful research session advances one field and skips 10–30 in-game years depending on total research level.
- A year contains 24 prototype days so long time spans can be tested quickly.
- Generational turnover is still simplified: elderly or dead villagers are replaced by a younger member of the same family and occupation. Full romance, childbirth, genealogy, inheritance, and household simulation will replace this shortcut later.
- Villagers use utility-style decisions for eating, sleeping, ordinary work, magic-assisted work, socializing, seeking treatment, and wandering.
- Villagers have deterministic personality traits, relationships, respect for the witch, health state, and profession-linked magical aptitude.
- Discovered village magic spreads to villagers according to occupation and aptitude. Farmers favor Agriculture, doctors Healing, craftspeople Construction, and so on.
- Food security and disease pressure now evolve daily. Low food raises hunger; disease pressure can make individual villagers sick.
- Monster activity is still represented by a threat percentage. Combat and Construction magic reduce its growth.
- The player can press F near a villager to greet them; the interaction is written into the village chronicle.
- Village visuals are placeholder vector shapes. They exist only to test movement and simulation before pixel art work begins.

## Next systems after this milestone
1. Proper household/family/genealogy simulation instead of direct descendant replacement.
2. Actual monster actors, attacks, and player magic combat.
3. A drawn magic-circle editor with lines, rings, connections, and spatial constraints instead of button cells.
4. Persistent save/load and a browsable multi-century village-history archive.
5. Economy, inventories, farming output, and building construction.
6. Pixel-art map and character pipeline.
