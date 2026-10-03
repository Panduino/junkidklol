# Gen4Dex (RTC + Untamed + National Dex Compatibility)

Compatibility mod for FireRed / LeafGreen that combines:

- [Real Time Clock Test](https://github.com/PashleyAUS/Real-Time-Clock-for-FR-LG-Content-Editor-addon-showcase/tree/v0.1.0) for the three-part morning / day / night cycle.
- [Untamed Advanced](https://github.com/goldenroddeptstore/Untamed-Advanced) for visible overworld wild Pokémon.
- [National Dex Gen 3](https://github.com/poooooby/national_dex_gen3) for Gen 4 species and their FireRed-compatible species slots.

All these mods are required for this one to work. I have not tested it otherwise.
No sprites are supplied for gen 4's battle sprites. You will still need to source those yourself if you want a full proper experience.

## What it does

The compatibility layer intercepts Untamed Advanced's wild table lookup instead of replacing Untamed's overworld spawning system. Untamed still handles visible overworld Pokémon, spawn positions, movement, sprites, despawning, wild battles, repel checks, and shiny/personality generation.

In addition, events have been and are slowly being added for all legendaries up to gen 4, excluding Hoenn legendaries.
Navel Rock and Birth Island are implemented, you can get the Mystic Ticket from Celio after catching the legendary beasts and the legendary birds. He will also give you the aurora ticket if you have Rayquaza in your pokedex. All legendary beasts roam instead of the one that corresponds to your starter now as well.

Darkrai is waiting at the top of the Pokemon Tower post-champion, only at night. Once you approach him he will become a roamer at night.

More will be implemented, with plans for a recreation of HG/SS's Sinjoh Ruins to get Arceus, Dialga, Giratina, and Palkia. Gen 3 Legendaries should be sourced from Emerald, and are being intentionally left out (except for Deoxys) to make room for an eventual Hoenn expansion, whether it is I or someone else that makes it.

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
## Installation

Install all three dependencies alongside this compatibility mod:
- [Real Time Clock Test](https://github.com/PashleyAUS/Real-Time-Clock-for-FR-LG-Content-Editor-addon-showcase)
- [Untamed Advanced](https://github.com/goldenroddeptstore/Untamed-Advanced)
- [National Dex Gen 3](https://github.com/poooooby/national_dex_gen3)


The compatibility mod does not modify those source mods.
