# RTC + Untamed + National Dex Compatibility

Compatibility mod for FireRed / LeafGreen that combines:

- **RealTimeClockTest** for the three-part morning / day / night cycle.
- **Untamed Advanced** for visible overworld wild Pokémon.
- **National Dex Gen 3** for Gen 4 species and their FireRed-compatible species slots.

## What it does

The compatibility layer intercepts Untamed Advanced's wild-table lookup instead of replacing Untamed's overworld spawning system. Untamed still handles visible overworld Pokémon, spawn positions, movement, sprites, despawning, wild battles, repel checks, and shiny/personality generation.

The compatibility layer supplies the species/level table that Untamed asks for.

### Time of day

The table uses the same three periods as the Real-Time Clock mod:

| Period | Time |
| --- | --- |
| Morning | 04:00–09:59 |
| Day | 10:00–17:59 |
| Night | 18:00–03:59 |

When the period changes, existing generated overworld encounters are cleared and Untamed is given a fresh table for the new period.

### Encounter design

The Kanto tables are inspired by HeartGold/SoulSilver rather than simply copying FireRed's tables. Several things are combined:

1. **HGSS Kanto time-of-day behavior** — species can be morning-only, day-biased, night-only, or present throughout the day.
2. **Kanto ecology** — forest species prefer Viridian Forest and wooded routes; cave, Ground, Rock and Steel species prefer caves/mountains; Electric species prefer Route 10 and the Power Plant; Water/Ice species prefer the southern sea routes and Seafoam; Ghost/Dark species are weighted toward nighttime and Pokémon Tower.
3. **Progression** — level ranges rise with the route and late-game areas have the broadest National Dex access.
4. **Common-species persistence** — Pidgey, Rattata, Spearow, Zubat and other Kanto staples intentionally occur on multiple routes instead of being artificially restricted to one table.
5. **National Dex coverage** — every species #1–493 is assigned a habitat family and an eligible Kanto map/time slot. Ordinary slots are then filled with HGSS-style common species and habitat matches around those coverage slots.

The result is intentionally **HGSS-inspired rather than a byte-for-byte recreation of HGSS's encounter data**. Gen 3's overworld spawning model and the expanded National Dex require a larger pool than the original HGSS tables.

## Requirements

Install all three source mods alongside this compatibility mod:

- RealTimeClockTest
- Untamed Advanced
- National Dex Gen 3

The compatibility mod does not modify those source mods.

## Important

The Real-Time Clock showcase currently declares FireRed in its manifest. The compatibility layer declares both FireRed and LeafGreen and mirrors the RTC clock periods for its encounter selection. LeafGreen therefore requires a version of the RTC component that actually loads on LeafGreen.