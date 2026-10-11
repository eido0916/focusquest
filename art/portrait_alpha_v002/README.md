# 立ち絵の透過修正 v002

2026-10-11: 男性忍者の髪・胴体・衣装の暗い線が背景と一緒に抜けていた。男女32枚を緑の背景に重ねて目視確認し、男性版16枚に見られる同様の抜けを修正した。女性版16枚は今回の見直しで同様の体の抜けを確認できず、変更していない。

`originals_before/` はアプリが使用していた男性素材のコピー、`repaired/` は組み込み画像編集ツールで背景透過を修正したPNG。ユーザーの元フォルダーとZIP、ドット絵原画・アニメーションは変更しない。アプリへの包装時は修正版を優先する。

使用ツール: built-in `image_gen.imagegen`、`transparent_background=true`。入力はそれぞれの元PNG。全身の顔・ポーズ・衣装・武器・色を保持し、暗い縫い目と装備境界の誤透過を埋め、背景と本来の隙間だけを透過するよう指定した。魔法職では魔力・光・浮遊物を残すよう指定した。生成編集のためRGBの完全一致は保証しない。

共通プロンプト:

> Repair only the transparency mask of this exact male fantasy game character cutout. Preserve the exact face, pose, proportions, costume, hair, weapons, lighting, original illustration details and entire uncropped silhouette. Restore fully opaque body, dark garment seams, belt and armor boundaries, folds, boots, gloves and hair so there are no background holes through the character. Remove only the backdrop to genuine alpha transparency. Preserve natural empty spaces outside the silhouette and between limbs and ribbons; retain decorative ragged fabric edges. Keep all magical energy, luminous glows and floating objects intact with soft alpha on glow only. Keep original colors and composition. No redesign, no new objects, no text, no white halo.

確認用プレビューと透過統計は `scripts/audit-portrait-alpha.py` で再作成する。統計の `low_alpha_in_bbox` は自然な隙間も含むため、不具合数ではない。最終判断は各画像の髪・顔・胴・腕・脚・武器・装飾を目視して行う。
