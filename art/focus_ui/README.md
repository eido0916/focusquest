# Focus battle UI assets

- User reference: reference.png
- Reusable window: ../../mobile/assets/images/ui/focus_window.png
- Skill orb: ../../mobile/assets/images/ui/focus_skill_orb.png
- Runtime painter and replaceable logo slot: ../../mobile/lib/game/runner/fantasy_battle_hud.dart

The window uses nine-slice rendering: sculpted endcaps keep their proportions while the blank center stretches to the HUD, level window, skill window and return button.

## Logo replacement
Add the supplied logo to mobile/assets/images/ui/ and set BattleUiAssets.levelLogo to 'ui/your_logo.png'. The page also accepts levelLogoAsset for a per-character override. The image fits in a separate 80 x 92 logical slot left of the live level display. A temporary neutral shield is shown until an asset is assigned.

## Image generation
Built-in image_gen; transparent_background: true; supplied screenshot as style reference.

Window final prompt:
Use case: ui-mockup. Create one isolated reusable EMPTY UI WINDOW asset inspired by the ornate dark blue gold windows in reference. Output a single wide horizontal panel, aspect ratio 3:1, filling image almost entirely, outside transparent alpha. Deep midnight navy smooth luminous blue interior with extremely subtle engraved leaf flourishes; richly polished sculpted metallic gold double borders, elegant decorative curved gold filigree only at four corners and pointed left/right endcaps. Thin perfectly straight horizontal gold top and bottom border across central 60 percent, no center ornament so it can be nine-sliced without distortion. Crisp beautiful premium Japanese fantasy RPG, adventurous classic kingdom atmosphere with refined clean fantasy beauty. Blank central interior for live UI text. NO TEXT, NO numbers, NO icons, NO shield, NO character, NO scene, NO skill orb, NO logos. ONLY one empty ornate window, actual transparent exterior.

Skill orb final prompt:
Create one isolated circular fantasy RPG automatic skill icon on real transparent background. Reference is style guidance for bottom-right blue slash orb. A vivid electric cyan and white diagonal wind sword slash inside deep sapphire blue glass medallion, polished double sculpted metallic gold circular rim, subtle blue glow within circle. Perfectly round medallion centered, filling square image with tiny transparent margin. Elegant clean Japanese fantasy RPG art matching navy gold reference. No text, no letters, no numbers, no rectangle, no surrounding scene, no character, no logo. This is a reusable skill orb asset.
