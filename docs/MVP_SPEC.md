# VillageGame MVP Specification

## Core fantasy
The player is an immortal young-looking witch who protects one village across centuries. Villagers age, form relationships, inherit a changing culture, and die while the witch remains unchanged. Magical research can consume years or decades, so every breakthrough protects future generations at the cost of missing part of the current generation's life.

To villagers, the witch is an increasingly legendary figure who disappears into research for long periods and returns with knowledge when the village needs it.

## Product direction
VillageGame is now a portrait-first mobile puzzle game. The magic-circle research screen is the primary play surface. The village simulation remains active underneath it, but its role is to create stakes, objectives, historical consequences, and generational stories for the puzzles rather than to be the main movement/exploration game.

The core loop is:
1. The village presents a need or threat.
2. The player designs a magic circle under geometric and mana constraints.
3. A successful theory becomes village knowledge.
4. Years or decades pass.
5. The village changes, generations turn over, and a new research problem emerges.

## Fixed design decisions
- Engine: Godot 4.7
- Primary commercial release target: iOS App Store
- Web build: continuously updated rapid-playtest channel
- Primary orientation: portrait / vertical phone layout
- Reference viewport: 720 x 1280 (9:16)
- Final art direction: polished pixel-art fantasy with restrained UI illustration
- Player: immortal female witch, visually unchanged across centuries
- Protagonist visual language: long silver hair, purple eyes, dark navy-to-violet witch clothing, gold trim, large witch hat, celestial star/moon motifs
- Global palette: midnight navy, violet, antique gold, pale violet-white magical light
- Initial villagers: 20
- One in-game day: 6 real minutes at normal speed
- Endless play: hundreds of in-game years are possible
- Threats: hunger, disease, monsters
- Magic contributes to combat, healing, agriculture, construction, and weather
- Villagers can use discovered magic according to village knowledge, occupation, and aptitude
- Research uses magic-circle puzzles
- Shapes in a magic circle have semantic roles such as magical field, range/containment, power, duration, stability, and mana efficiency
- Research sessions can skip years or decades while the village simulation continues

## Puzzle rules for the current prototype
- The current board has nine semantic rune slots arranged as a magic circle rather than shown as a square grid.
- Center slot = magical field/core.
- Corner slots = boundary, range, and containment.
- Edge slots = mana flow, power, and duration.
- Research challenges specify minimum power, range, stability, duration, maximum mana cost, and minimum used glyphs.
- More than one circle can solve a challenge.
- Matching opposite glyphs can create stabilizing connections.
- Five current magical fields: Healing, Agriculture, Construction, Weather, Combat.
- These rules are prototype grammar and can expand into rings, drawn connections, rotation, and spatial geometry later.

## Village meta simulation
- Villagers still use utility-style decisions and retain age, occupation, personality, relationships, health, respect for the witch, and learned magic.
- Food security, disease pressure, and monster threat remain aggregate village pressures.
- Research knowledge spreads to suitable villagers.
- Long research absences advance the village simulation and trigger generational turnover.
- The main screen surfaces this simulation as village pulse indicators and a chronological history feed rather than requiring the player to walk around the village.
- Full genealogy will eventually replace the current simplified descendant-replacement shortcut.

## Current visual vertical slice
- Animated midnight starfield / nebula background with violet and gold accents
- Portrait 9:16 UI with iOS safe-area handling
- Witch portrait asset slot in the header; the prototype falls back to a celestial emblem until final character art is committed
- Large animated magic-circle centerpiece with rings, runic ticks, mana connections, stability chords, and breakthrough burst
- Touch-friendly rune nodes placed directly on the circle
- Gold-accented research objective card, live spell metrics, and large confirm/reset controls
- Village pulse cards for harvest, disease, and monster threat
- Village chronicle panel showing recent history
- Research-success return card explaining how many years passed and what knowledge entered village culture
- 20 autonomous villagers and the existing long-term simulation remain active underneath the presentation layer
- Automated Godot smoke tests, Web preview deployment, and unsigned iOS Xcode-project validation

## Deliberately de-emphasized from the old prototype
- Free top-down walking is no longer the primary loop.
- The placeholder village map and on-screen movement buttons are no longer the main presentation.
- Direct villager greeting and tower-entry controls are not central to the portrait puzzle UI.

## Non-goals for this slice
- Final protagonist pixel-art asset integration
- Final title/logo and store icon
- Full marriage / childbirth / genealogy
- Full world-map combat actors
- Advanced economy and inventories
- Detailed disease taxonomy
- Hundreds of spells
- Multiple explorable maps
- Production App Store signing or TestFlight upload before Apple Developer credentials exist
