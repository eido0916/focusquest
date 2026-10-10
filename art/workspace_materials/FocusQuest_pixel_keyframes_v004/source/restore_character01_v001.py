from pathlib import Path
import shutil,json,hashlib
from PIL import Image

W=Path(__file__).resolve().parent
old=W/'FocusQuest_pixel_keyframes_v001'
prior=W/'FocusQuest_pixel_keyframes_v003'
out=W/'FocusQuest_pixel_keyframes_v004'
shutil.copytree(prior,out)
src=old/'players/character_01';dst=out/'players/character_01'
shutil.copytree(src,dst,dirs_exist_ok=True)
for p in src.rglob('*'):
 if p.is_file():assert p.read_bytes()==(dst/p.relative_to(src)).read_bytes(),p
for kind in ['players','enemies']:
 for p in (prior/kind).rglob('*'):
  if p.is_file() and 'character_01' not in p.parts:assert p.read_bytes()==(out/p.relative_to(prior)).read_bytes(),p
sheet=Image.new('RGB',(1280,288),'#dbe4ed')
for i,c in enumerate(range(1,6)):
 im=Image.open(out/f'players/character_{c:02}/run/keyframes/frame_000.png').convert('RGBA').resize((256,256),Image.Resampling.NEAREST)
 sheet.paste(im,(i*256,24),im)
sheet.save(out/'player_style_comparison_final.png')
sheet.save(out/'player_style_comparison.png')
sheet=Image.new('RGB',(1024,288),'#dbe4ed')
for i,a in enumerate(['idle','run','attack_down','skill_wave']):
 im=Image.open(dst/a/'keyframes/frame_000.png').convert('RGBA').resize((256,256),Image.Resampling.NEAREST)
 sheet.paste(im,(i*256,24),im)
sheet.save(out/'character_01_style_motion_comparison.png')
sheet.save(out/'character_01_proportions_comparison.png')
page=(prior/'index.html').read_text(encoding='utf-8')
start=page.index('<h2>character_01');end=page.index('<div class="cards">',start)
page=page[:start]+'<h2>character_01 · v001の外見へ復元（v004）</h2><p>待機・走行・攻撃・スキル・連結版をv001の原画に戻しました。character_02〜05と敵はv003と同一です。</p>'+page[end:]
(out/'index.html').write_text(page,encoding='utf-8')
verify=out/'source/verify_saved.py'
verify.write_text(verify.read_text(encoding='utf-8').replace('FocusQuest_pixel_keyframes_v003.zip','FocusQuest_pixel_keyframes_v004.zip'),encoding='utf-8')
# Make regeneration use the restored originals rather than the superseded style redraw.
build=out/'source/build_catalog.py'
s=build.read_text(encoding='utf-8')
s=s.replace("OUT/'source/hero_style_v003'/action","WORKSPACE/'FocusQuest_pixel_keyframes_v001'/'players/character_01'/action")
s=s.replace("idle=OUT/'source/hero_style_v003/idle'","idle=WORKSPACE/'FocusQuest_pixel_keyframes_v001'/'players/character_01/idle'")
s=s.replace("keys=keys or sorted((source/'frames').glob('*.png'))","keys=keys or sorted((source/'frames').glob('*.png')) or sorted((source/'keyframes').glob('*.png'))")
s=s.replace('FocusQuest_pixel_keyframes_v003.zip','FocusQuest_pixel_keyframes_v004.zip')
s=s[:s.index("page=page.replace('<h2>character_01</h2>'")]+"page=page.replace('<h2>character_01</h2>','<h2>character_01 · v001の外見へ復元（v004）</h2>')\n"+s[s.index("(OUT/'index.html').write_text(page"):]
build.write_text(s,encoding='utf-8')
(out/'README.md').write_text('# FocusQuest原画アニメーション v004\n\ncharacter_01の全6動作をv001のファイルへそのまま戻しました。原画・24fps連番・GIF/APNG・配置JSON・原画一覧はv001と完全一致です。character_02〜05と敵3体はv003と同じ素材です。\n\n再生は原画の直接切り替えで、変形・補間はありません。v001に元からあった動作間の頭身・大きさの差も戻っています。v002・v003の修正はcharacter_01には適用していません。\n\nv003のSTYLE_V003.md、source/hero_style_v003、比較画像の旧制作記録は履歴であり、現行character_01の原画ではありません。\n',encoding='utf-8')
report={'character_01_restored_from':'FocusQuest_pixel_keyframes_v001','all_character_01_files_identical_to_v001':True,'all_other_character_files_identical_to_v003':True}
(out/'restore_verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(out/'source/restore_character01_v001.py').write_text(Path(__file__).read_text(encoding='utf-8'),encoding='utf-8')
print(json.dumps(report))
