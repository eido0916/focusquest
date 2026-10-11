from pathlib import Path
p=Path(__file__).resolve().parent.parent/'index.html'
s=p.read_text(encoding='utf-8')
s=s.replace('<h2>character_01</h2>','<h2>character_01 · 待機基準の頭身 v002</h2><p>左から待機・走行・攻撃・スキル。各動作を待機の頭と体の大きさに合わせました。</p><img style="width:1024px;max-width:100%" src="character_01_proportions_comparison.png" alt="待機を基準にした頭身比較">')
p.write_text(s,encoding='utf-8')
