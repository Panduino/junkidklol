# G9 Battle Sprites - Gen 3

FireRed/LeafGreen compatibility renderer for **G9 Battle Sprites**.

This mod does not redistribute G9's sprite pack. Install the release build of
`g9-battle-sprites` (the release ZIP contains the actual front/back sheets)
alongside this mod. `national_dex_gen3` is optional but supported: when
installed, its added species use the same animated renderer as #001-386.

## What it does

- Replaces FireRed/LeafGreen front and back battle pictures with G9's DBK sheets.
- Uses the installed G9 mod's own `data/dbk_data.lua` species-to-sheet mapping.
- Supports normal and shiny front/back folders.
- Animates horizontal G9 sheets in battle instead of flattening them to a still.
- Keeps FireRed's native battler placement/effects because the adapter supplies
  a 64x64 current frame through the normal Gen 3 Pokemon picture path.
- Falls back to the original FireRed picture whenever a G9 sheet cannot be
  resolved.

## Status

Initial Gen 3 renderer port. The adapter intentionally uses `engine_internals`
because the public cross-mod API exposes G9's exports but not its release asset
filesystem, and G9 does not currently export its live battle frame.
