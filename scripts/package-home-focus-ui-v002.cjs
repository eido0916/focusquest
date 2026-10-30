const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..'),art=path.join(root,'art/home_focus_ui_v002'),app=path.join(root,'mobile/assets/images/home_focus_ui_v002');
const gen=JSON.parse(fs.readFileSync(path.join(art,'generation.json'),'utf8'));
if(fs.existsSync(path.join(art,'generation-revisions.json')))gen.entries.push(...JSON.parse(fs.readFileSync(path.join(art,'generation-revisions.json'),'utf8')).entries);
const sources=Object.fromEntries(gen.entries.map(r=>[r.name,r.source]));
const manifest=[];
async function save(name,png,source){
  fs.writeFileSync(path.join(app,name+'.png'),png);fs.writeFileSync(path.join(art,'materials',name+'.png'),png);
  const meta=await sharp(png).metadata();manifest.push({name,file:`materials/${name}.png`,width:meta.width,height:meta.height,alpha:meta.hasAlpha,source,sha256:crypto.createHash('sha256').update(png).digest('hex')});
}
async function trimmed(input){
  const {data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let x0=info.width,y0=info.height,x1=-1,y1=-1;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++)if(data[(y*info.width+x)*4+3]>20){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}
  return sharp(input).extract({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1}).png().toBuffer();
}
async function frame(source,w,h,name){
  const clean=await trimmed(sources[source]);
  const input=await sharp(clean).resize(w,h,{fit:'fill'}).png().toBuffer();
  const cx=84,cy=name==='timer_frame'?96:54;
  // Separate corner/endcap pieces and sample plain edge strips, so the
  // central gold jewel never stretches into a wide shape with the panel.
  const pieces=[];
  async function tile(rect,left,top,width=rect.width,height=rect.height){pieces.push({input:await sharp(input).extract(rect).resize(width,height,{fit:'fill'}).png().toBuffer(),left,top});}
  await tile({left:cx,top:cy,width:w-2*cx,height:h-2*cy},cx,cy);
  for(const y of [0,h-cy])await tile({left:Math.floor(w*.28),top:y,width:50,height:cy},cx,y,w-2*cx,cy);
  for(const x of [0,w-cx])await tile({left:x,top:Math.floor(h*.35),width:cx,height:Math.max(8,Math.floor(h*.1))},x,cy,cx,h-2*cy);
  for(const x of [0,w-cx])for(const y of [0,h-cy])await tile({left:x,top:y,width:cx,height:cy},x,y);
  const png=await sharp({create:{width:w,height:h,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(pieces).png().toBuffer();
  await save(name,png,source);
  if(name==='status_frame'){
    await save('ornament_top',await sharp(input).extract({left:w/2-42,top:0,width:84,height:54}).png().toBuffer(),source);
    await save('ornament_bottom',await sharp(input).extract({left:w/2-42,top:h-54,width:84,height:54}).png().toBuffer(),source);
  }
}
const symbols={
  compass:'<circle cx="36" cy="36" r="23" fill="none" stroke-width="1.7"/><path d="M36 2L42 28L69 36L43 43L36 70L29 44L3 36L29 29Z" fill="none" stroke-width="1.7"/><path d="M36 2L36 36L69 36L43 43L36 70L36 36L3 36L29 29Z" stroke="none"/><path d="M14 14L34 27L58 14L45 35L58 58L36 45L14 58L27 36Z" fill="none" stroke-width="1.3"/>',
  hourglass:'<path d="M20 8H52V17L41 32V40L52 55V64H20V55L31 40V32L20 17Z" fill="none" stroke-width="5"/><path d="M25 57L36 45L47 57V61H25Z"/>',
  chart:'<rect x="11" y="35" width="12" height="29" rx="5"/><rect x="30" y="10" width="12" height="54" rx="5"/><rect x="49" y="27" width="12" height="37" rx="5"/>',
  map:'<path d="M9 16L27 8L45 17L63 10V57L45 64L27 56L9 63Z" fill="none" stroke-width="5"/><path d="M27 9V56M45 18V63" fill="none" stroke-width="4"/>',
  sound:'<path d="M9 27H23L40 13V59L23 45H9Z"/><path d="M48 26Q58 36 48 46M55 17Q73 36 55 55" fill="none" stroke-width="4"/>',
  pause:'<circle cx="36" cy="36" r="28" fill="none" stroke-width="4"/><path d="M27 23V49M45 23V49" fill="none" stroke-width="6"/>',
  swords:'<path d="M10 6L21 10L58 48L51 55L14 18Z M62 6L51 10L14 48L21 55L58 18Z"/><path d="M43 49L59 65M29 49L13 65M44 59L62 41M28 59L10 41" fill="none" stroke-width="4"/>',
  chevron:'<path d="M27 16L47 36L27 56" fill="none" stroke-width="6"/>',
  back:'<path d="M40 16L20 36L40 56M21 36H62" fill="none" stroke-width="5"/>',
  party:'<circle cx="36" cy="19" r="10"/><circle cx="15" cy="25" r="7"/><circle cx="57" cy="25" r="7"/><path d="M21 62V44Q21 30 36 30Q51 30 51 44V62ZM3 61V43Q3 34 15 34L20 36Q15 45 17 61ZM55 61Q57 45 52 36L57 34Q69 34 69 43V61Z"/>',
};
async function main(){
  for(const dir of [app,path.join(art,'materials'),path.join(art,'originals'),path.join(art,'vectors'),path.join(art,'previews')])fs.mkdirSync(dir,{recursive:true});
  for(const r of gen.entries)fs.copyFileSync(r.source,path.join(art,'originals',r.name+'.png'));
  for(const name of ['home_background','timer_background','home_stage'])await save(name,await sharp(sources[name]).png().toBuffer(),name);
  for(const name of ['status_frame','metrics_frame','chapter_frame','action_frame','utility_frame'])await frame('wide_blue_frame',1200,240,name);
  await frame('wide_cream_frame',1200,240,'adventure_frame');await frame('timer_panel',1200,900,'timer_frame');await frame('record_plaque',600,240,'record_frame');
  await save('portrait_frame',await sharp(await trimmed(sources.portrait_frame)).resize(180,180,{fit:'fill'}).png().toBuffer(),'portrait_frame');
  await save('timer_compass',await sharp(await trimmed(sources.timer_compass)).resize(600,600,{fit:'contain',background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer(),'timer_compass');
  if(sources.gold_jewel){
    const jewel=await sharp(await trimmed(sources.gold_jewel)).resize(84,54,{fit:'contain',background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer();
    fs.writeFileSync(path.join(app,'ornament_top.png'),jewel);fs.writeFileSync(path.join(art,'materials/ornament_top.png'),jewel);
    fs.writeFileSync(path.join(app,'ornament_bottom.png'),jewel);fs.writeFileSync(path.join(art,'materials/ornament_bottom.png'),jewel);
    for(const entry of manifest.filter(r=>r.name.startsWith('ornament_'))){entry.source='gold_jewel';entry.sha256=crypto.createHash('sha256').update(jewel).digest('hex');}
  }
  for(const [name,body] of Object.entries(symbols)){
    const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="144" height="144" viewBox="0 0 72 72"><g fill="#ffdb8e" stroke="#ffdb8e" stroke-linecap="round" stroke-linejoin="round">${body}</g></svg>`;
    fs.writeFileSync(path.join(art,'vectors',`icon_${name}.svg`),svg);await save('icon_'+name,await sharp(Buffer.from(svg)).png().toBuffer(),'code-native individual SVG');
  }
  const track='<svg xmlns="http://www.w3.org/2000/svg" width="600" height="40"><rect x="2" y="2" width="596" height="36" rx="18" fill="#05263d" stroke="#80c6dc" stroke-width="3"/><rect x="6" y="6" width="588" height="28" rx="14" fill="none" stroke="#27617a"/></svg>';
  const fill='<svg xmlns="http://www.w3.org/2000/svg" width="600" height="40"><defs><linearGradient id="cyan" x2="0" y2="1"><stop stop-color="#c4ffff"/><stop offset=".35" stop-color="#64e8f6"/><stop offset="1" stop-color="#1895c7"/></linearGradient></defs><rect width="600" height="40" fill="url(#cyan)"/></svg>';
  const divider='<svg xmlns="http://www.w3.org/2000/svg" width="600" height="24"><path d="M8 12H592" stroke="#c5a45e" stroke-width="2"/><path d="M300 3L309 12L300 21L291 12Z M12 6L18 12L12 18L6 12Z M588 6L594 12L588 18L582 12Z" fill="#103255" stroke="#f5d68e" stroke-width="2"/></svg>';
  for(const [name,svg] of [['gauge_track',track],['gauge_fill',fill],['divider',divider]]){fs.writeFileSync(path.join(art,'vectors',name+'.svg'),svg);await save(name,await sharp(Buffer.from(svg)).png().toBuffer(),'code-native scalable UI material');}
  fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify(manifest,null,2));
  fs.writeFileSync(path.join(art,'index.html'),`<!doctype html><meta charset="utf-8"><title>FocusQuest Home / Focus v002</title><style>body{background:#0a2037;color:#ffe5ab;font:16px/1.6 system-ui;margin:32px}main{max-width:1120px;margin:auto}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}article{background:#183247;border:1px solid #b99351;padding:16px}article img{width:100%;max-height:280px;object-fit:contain}a{color:#9ce7ff}</style><main><h1>ホーム・集中画面 v002</h1><p>背景・装飾枠・アイコンを個別素材化。人物は既存イラスト、文字と数値はアプリ側で表示。</p><p><a href="previews/home-390x844-1.png">ホーム実装画面</a> / <a href="previews/timer-390x844-1.png">集中中の実装画面</a> / <a href="generation.json">生成プロンプト</a></p><div class="grid">${manifest.map(m=>`<article><h3>${m.name}</h3><img src="${m.file}"><p>${m.width}×${m.height}</p></article>`).join('')}</div></main>`);
  console.log(JSON.stringify({materials:manifest.length,output:app}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
