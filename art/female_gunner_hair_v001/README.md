# 女性ガンナーのこげ茶の髪

2026-10-12: 組み込み image_gen による立ち絵の髪色変更。金髪の元画像は保存し、アプリの立ち絵と冒険者証は `mobile/assets/images/lobby/portraits/female/gunner_dark_brown_transparent_v002.png` を使用する。ドット絵の動作原画は変更しない。

## 使用したプロンプト

Use case: precise-object-edit. Edit target: the provided female gunner full-body game portrait. Change ONLY her blonde hair to rich dark chocolate brown (こげ茶, deep brown base around #38251f with muted brown highlights). Recolor every hair strand including bangs, top ponytail, loose side locks and long flowing hair behind her. Preserve the hairstyle, exact face, blue eyes, expression, skin, pose, anatomy, both pistols, blue ribbons, navy and white outfit, belts, boots, painting style, original composition and existing dark vignetted background. Keep the same full-body vertical framing, no cropped feet, no text. Do not turn the hair gold, blonde, red, or black; highlights must remain brown. Everything except hair color should remain unchanged.

## 透過版

背景除去も組み込み image_gen で実施した。プロンプトは `transparent_prompt.txt`。RGBAのアルファ0画素は833,275画素。Flutterで明るい背景に重ねて輪郭と髪の隙間を確認した。元の金髪版、こげ茶の背景付き版も保存する。更新した冒険者証は `mobile/assets/images/certificates_landscape_v002/gunner_female_dark_brown_v003.png`。
