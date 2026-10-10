# Home screen assets

Reference: home_reference.png (user supplied).
Original standing character: knight_original.png (user supplied).
Runtime standing character: ../../mobile/assets/images/ui/home_knight.png.
Existing runtime scene: ../../mobile/assets/images/ui/sunlit_kingdom.png.
Responsive button frames, compass crest and navigation ornaments are painted in
../../mobile/lib/core/widgets/sunlit_widgets.dart and quest_widgets.dart.

The standing character background was removed with the built-in image_gen tool
(transparent_background: true). Original source is preserved separately.
Final prompt:

Remove the ENTIRE background behind the knight. Output must have real transparent alpha pixels everywhere outside the knight silhouette, including gaps between legs, sword and cape, shield and head. No black, brown, blue or other background, no glow behind figure. A transparent cutout asset, not a rectangular illustration. Keep original supplied knight pixels, pose, face and outfit as closely as possible. Silver gold knight with blue cape, sword and shield, full body on transparent background.

Home typography: Noto Serif JP (Google Fonts), SIL Open Font License 1.1.
Source: https://github.com/google/fonts/tree/main/ofl/notoserifjp
Font and license are retained in mobile/assets/fonts/.
