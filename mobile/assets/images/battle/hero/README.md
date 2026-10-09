# Hero battle animations

Generated from the two supplied montage images by
`scripts/build-hero-sprites.py`.

- `frames/run/run_01.png` … `run_14.png`: transparent, normalized run frames
- `frames/attack/attack_01.png` … `attack_15.png`: transparent, normalized attack frames
- `spritesheet.png`: two-row Flame sprite sheet (run on row 0, attack on row 1)
- `spritesheet.json`: frame size, rows, timing, loop flags, and foot anchor

The app loads the JSON and sprite sheet in
`lib/game/runner/hero_animation_assets.dart`, then switches animations in
`lib/game/runner/hero_component.dart`.

The supplied images are flattened montages with some poses overlapping. The
extractor removes white backgrounds and neighbouring edge fragments, but a
pixel hidden behind an adjacent pose cannot be reconstructed from this source.
