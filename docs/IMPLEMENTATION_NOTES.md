# Implementation Notes

This file records provisional choices made to get the game into a playable and visually coherent state quickly. They are not final design commitments.

## Current product direction
- VillageGame is portrait-first and puzzle-first for mobile/App Store play.
- The magic-circle research screen is the main gameplay surface.
- The living village simulation continues underneath the puzzle and provides stakes, objectives, long-term consequences, and historical flavor.
- Top-down free movement is retained only as legacy prototype code for now and is not the primary presentation.
- `ARCANA OF AGES` is the current provisional display title. The repository/project name remains `VillageGame`, so the public-facing title can be replaced without renaming the codebase.

## Visual baseline
- Reference viewport: 720 x 1280 (9:16).
- Main palette: midnight navy, violet, antique gold, and pale violet-white magical light.
- Protagonist direction: silver long hair, purple eyes, large witch hat, navy/violet clothing with gold trim, celestial star/moon motifs.
- The header looks for `res://art/player/witch_portrait.png`; until a final asset is intentionally committed, it uses a simple placeholder emblem.
- The research screen has an animated starfield/nebula backdrop and a custom-drawn magic circle with rings, rune ticks, mana links, stability chords, and breakthrough glow.
- The app opens on a portrait title scene with a large animated decorative magic circle, starfield, provisional `ARCANA OF AGES` treatment, and a short fade transition into the research tower.
- Native mobile layout respects the display safe area.
- Web starts with a safe English fallback while its Japanese font is unavailable. It downloads the pinned Noto Sans CJK JP subset once, caches it in `user://`, installs it as the global fallback font, and reloads the scene into Japanese. Native builds use installed Japanese system fonts. If the Web font request fails, the UI remains readable in English instead of showing tofu boxes.
- Circle, triangle, square, diamond, and star puzzle glyphs are vector-drawn by Godot instead of relying on Unicode symbol fonts, keeping their appearance consistent across Web and iOS.
- Phone readability takes priority over information density: puzzle text and touch targets are enlarged, and the village chronicle is collapsed behind a compact history control by default.

## Current puzzle rules
- Research uses a semantic nine-slot magic circle rather than exact-pattern matching.
- The center glyph selects the magical field, corner glyphs mainly shape range/containment, and edge glyphs mainly control power, duration, and mana flow.
- A research challenge specifies minimum power/range/stability/duration, minimum explicit mana links, and a maximum mana cost. Multiple circle layouts can satisfy the same challenge.
- Mobile interaction has three layers: tap a slot to choose a glyph, rotate a placed glyph in 90-degree steps to tune its behavior, and drag from one occupied slot to another to add/remove an explicit mana line.
- Glyph orientation is meaningful: outward adds range, clockwise adds duration, inward adds stability/efficiency, and counter-flow adds power. Every placed glyph therefore has both shape and direction.
- Explicit mana links also change the spell. Core-connected lines add power/stability, non-core lines add duration, same-glyph links favor stability/efficiency, mixed-glyph links favor power, and opposite-slot links add range.
- Connected lines are drawn as glowing field-colored or gold paths with moving light beads, while an in-progress drag draws a live luminous preview from the source glyph to the finger.
- The challenge requires a small network rather than disconnected symbols: current minimum link counts are 2 for Healing, 3 for Agriculture, 3 for Construction, 4 for Weather, and 3 for Combat before tier scaling.
- Magic fields are Healing, Agriculture, Construction, Weather, and Combat.
- Research fields are selected from village conditions instead of rotating blindly. Disease drives Healing, food shortages drive Agriculture/Weather, and monster pressure alternates between Combat and Construction as the village gains defensive knowledge. Quiet periods request whichever branch of village magic is lagging behind.
- The first prototype request comes from the clinic and establishes basic Healing, preserving a readable onboarding path before crisis-driven requests take over.
- The request card names who is asking and why, such as a clinic request, hunter warning, mayor request, or farm request; severity changes the request text accent.
- A successful research session advances one field and skips 10–30 in-game years depending on total research level. After the time skip, the new village state selects the next request.
- A success opens a return-to-village card rather than immediately returning to a walkable map.
- Tapping a slot opens a large six-choice glyph palette instead of requiring repeated cycling. The same palette exposes left/right 90-degree rotation controls and labels the selected role as core, boundary, or flow so the geometry teaches its own grammar.

## Village simulation retained under the puzzle
- One prototype year contains 24 in-game days so century-scale changes can be tested quickly.
- Villagers use utility-style decisions for eating, sleeping, ordinary work, magic-assisted work, socializing, seeking treatment, and wandering.
- Villagers have deterministic personality traits, relationships, respect for the witch, health state, and profession-linked magical aptitude.
- Discovered village magic spreads to villagers according to occupation and aptitude.
- Food security and disease pressure evolve daily; monster activity is represented by aggregate threat pressure.
- Generational turnover is still simplified: elderly or dead villagers are replaced by a younger member of the same family and occupation.
- The portrait main screen currently summarizes the village through harvest/disease/threat cards and a short chronological history feed.

## Next visual/gameplay systems
1. Strengthen breakthrough and return animation: freeze puzzle input briefly, flare the completed mana network, expand several white-gold wave rings, then transition into the multi-year time skip.
2. Turn village requests into multi-step research stories with named requesters, consequences, and success/failure follow-ups.
3. Add era/chapter transitions and a more developed logo treatment around the provisional title screen.
4. Integrate final protagonist portrait/pixel art only after the intended public asset is approved.
5. Add a browsable multi-century village-history archive with named descendants and remembered relationships.
6. Replace simplified descendant turnover with proper households, genealogy, inheritance, and cultural transmission.
7. Add a reusable art pipeline for rune icons, spell effects, village era cards, and App Store screenshots.
