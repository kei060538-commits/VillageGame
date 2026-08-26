# Implementation Notes

This file records provisional choices made to get the game into a playable and visually coherent state quickly. They are not final design commitments.

## Current product direction
- VillageGame is portrait-first and puzzle-first for mobile/App Store play.
- The magic-circle research screen is the main gameplay surface.
- The living village simulation continues underneath the puzzle and provides stakes, objectives, long-term consequences, and historical flavor.
- Top-down free movement is retained only as legacy prototype code for now and is not the primary presentation.

## Visual baseline
- Reference viewport: 720 x 1280 (9:16).
- Main palette: midnight navy, violet, antique gold, and pale violet-white magical light.
- Protagonist direction: silver long hair, purple eyes, large witch hat, navy/violet clothing with gold trim, celestial star/moon motifs.
- The header looks for `res://art/player/witch_portrait.png`; until a final asset is intentionally committed, it uses a celestial placeholder emblem.
- The research screen has an animated starfield/nebula backdrop and a custom-drawn magic circle with rings, rune ticks, mana links, stability chords, and breakthrough glow.
- Native mobile layout respects the display safe area.

## Current puzzle rules
- Research uses a semantic nine-slot magic circle rather than exact-pattern matching.
- The center glyph selects the magical field, corner glyphs mainly shape range/containment, and edge glyphs mainly control power, duration, and mana flow.
- A research challenge specifies minimum power/range/stability/duration and a maximum mana cost. Multiple circle layouts can satisfy the same challenge.
- Matching glyphs across opposite slots create a stability/efficiency bonus and are visualized as brighter chords.
- Magic fields currently rotate through Healing, Agriculture, Construction, Weather, and Combat.
- A successful research session advances one field and skips 10–30 in-game years depending on total research level.
- A success opens a return-to-village card rather than immediately returning to a walkable map.

## Village simulation retained under the puzzle
- One prototype year contains 24 in-game days so century-scale changes can be tested quickly.
- Villagers use utility-style decisions for eating, sleeping, ordinary work, magic-assisted work, socializing, seeking treatment, and wandering.
- Villagers have deterministic personality traits, relationships, respect for the witch, health state, and profession-linked magical aptitude.
- Discovered village magic spreads to villagers according to occupation and aptitude.
- Food security and disease pressure evolve daily; monster activity is represented by aggregate threat pressure.
- Generational turnover is still simplified: elderly or dead villagers are replaced by a younger member of the same family and occupation.
- The portrait main screen currently summarizes the village through harvest/disease/threat cards and a short chronological history feed.

## Next visual/gameplay systems
1. Replace placeholder rune cycling with a more tactile drag/rotate/connect magic-circle interaction.
2. Create proper puzzle objective cards generated from actual village crises and requests.
3. Add a title screen, logo treatment, chapter/era transitions, and stronger breakthrough/return animation.
4. Integrate final protagonist portrait/pixel art only after the intended public asset is approved.
5. Add a browsable multi-century village-history archive with named descendants and remembered relationships.
6. Replace simplified descendant turnover with proper households, genealogy, inheritance, and cultural transmission.
7. Add a reusable art pipeline for rune icons, spell effects, village era cards, and App Store screenshots.
