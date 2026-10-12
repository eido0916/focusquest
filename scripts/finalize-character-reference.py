from pathlib import Path
import shutil, zipfile, html

root = Path(__file__).resolve().parents[1]
art = root / 'art/character_ui_v002'
preview = art / 'previews'
preview.mkdir(exist_ok=True)
for source, name in [
    (root / 'output/character_lobby/character-390x1150.png', 'character_full.png'),
    (root / 'output/character_lobby/character-390x844.png', 'character_phone.png'),
    (root / 'output/character_lobby/titles-844.png', 'titles.png'),
    (root / 'art/focus_selection_v001/preview_390.png', 'focus_phone.png'),
]:
    assert source.exists(), source
    shutil.copy2(source, preview / name)
cards = []
for directory in ('materials', 'role_logos', 'previews'):
    cards.append(f'<h2>{directory}</h2><div class="grid">')
    for p in sorted((art / directory).glob('*.png')):
        rel = p.relative_to(art).as_posix()
        cards.append(f'<a href="{rel}" download><figure><img src="{rel}" alt="{html.escape(p.stem)}"><figcaption>{html.escape(p.name)}</figcaption></figure></a>')
    cards.append('</div>')
(art / 'index.html').write_text('''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>FocusQuest キャラクター画面 素材一覧</title><style>body{margin:32px;background:#071b30;color:#fff3d9;font-family:serif}h1,h2{color:#ffd58b}p{line-height:1.7}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px}a{color:#ffd58b;text-decoration:none}figure{margin:0;padding:16px;background:#102f4d;border:1px solid #b79861;border-radius:8px}img{width:100%;height:180px;object-fit:contain}figcaption{margin-top:12px;text-align:center}h2:last-of-type+.grid img{height:400px}</style><h1>FocusQuest キャラクター画面 v002</h1><p>19点の個別UI素材と、添付ファイルの職業ロゴ16点。画像を選択すると個別PNGを保存できます。<br>称号は既存設定に合わせLv.1〜8で解放。画面の文字や数値は実際のアプリから描画しています。</p>''' + ''.join(cards) + '</html>', encoding='utf-8')
archive = root / 'output/FocusQuest_character_ui_v002_materials.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in art.rglob('*'):
        if p.is_file():
            z.write(p, 'FocusQuest_character_ui_v002/' + p.relative_to(art).as_posix())
print(archive)
