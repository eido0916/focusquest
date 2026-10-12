"""Validate and package separately generated focus timer PNGs without editing them."""
from pathlib import Path
import hashlib
import json
import zipfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/focus_timer_v001'
RUNTIME = ROOT / 'mobile/assets/images/focus_timer_v001'
NAMES = ['background', 'panel_frame', 'name_banner', 'chapter_crest',
         'gold_divider', 'crossed_swords', 'timer_circle', 'gauge_frame', 'gauge_fill']
rows = []
for name in NAMES:
    path = ART / f'{name}.png'
    with Image.open(path) as image:
        if name != 'background':
            assert image.mode == 'RGBA', f'{name}: RGBA required'
            assert image.getchannel('A').getextrema()[0] == 0, f'{name}: no transparency'
        if name == 'panel_frame':
            assert image.getpixel((image.width // 2, image.height // 2))[3] == 0
        row = {'file': path.name, 'size': list(image.size), 'mode': image.mode}
    row['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
    assert path.read_bytes() == (RUNTIME / path.name).read_bytes()
    rows.append(row)
manifest = {'asset_count': len(rows), 'generator': 'built-in image_gen; one request per asset',
            'runtime_copies_identical': True, 'assets': rows}
(ART / 'verification.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
cards = ''.join(f'<figure><img src="{name}.png" alt="{name}"><figcaption><a href="{name}.png">{name}.png</a></figcaption></figure>' for name in NAMES)
(ART / 'index.html').write_text('''<!doctype html><html lang="ja"><meta charset="utf-8">
<title>FocusQuest 集中タイマー素材</title><style>
body{background:#07192c;color:#f5dfaa;font:16px system-ui;margin:32px}
h1{font-size:26px}a{color:#f5dfaa}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}
figure{margin:0;padding:16px;background:#142c42;border:1px solid #a99160;border-radius:8px}
figure img{width:100%;height:220px;object-fit:contain;background:repeating-conic-gradient(#203d53 0% 25%,#173247 0% 50%) 0/16px 16px}
figcaption{margin-top:12px}.preview{max-width:390px;width:100%;margin:20px 0}
</style><h1>FocusQuest 集中タイマー画面</h1><p>個別PNG 9点。文字・残り時間はアプリ側で表示します。</p>
<img class="preview" src="preview.png" alt="Flutter実装プレビュー"><div class="grid">''' + cards + '</div></html>', encoding='utf-8')
output = ROOT / 'output/focus_timer_v001'
output.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(output / 'FocusQuest_focus_timer_v001.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in ART.iterdir():
        if path.is_file():
            archive.write(path, f'focus_timer_v001/{path.name}')
print(json.dumps({'verified_assets': len(rows), 'package': str(output / 'FocusQuest_focus_timer_v001.zip')}, ensure_ascii=False))
