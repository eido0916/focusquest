const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art/character_pixel_v007');
const app = path.join(root, 'mobile/assets/images/character_pixel_v007');
const original = JSON.parse(fs.readFileSync(path.join(root, 'art/focus_selection_v001/avatar_generation.json'), 'utf8').replace(/^\uFEFF/, ''));
const roles = ['warrior','boxer','samurai','guardian','ninja','assassin','ranger','mage','gunner','spellblade','onmyoji','reaper','angel','devil','dragon_knight','berserker'];
const records = ['male','female'].flatMap(sex => roles.map(role => {
  const old = original.find(r => r.role === role && r.sex === sex);
  const portrait = path.join(root, 'mobile/assets/images/lobby/portraits', sex === 'female' ? 'female' : '', role === 'gunner' && sex === 'female' ? 'gunner_dark_brown_transparent_v002.png' : role + '.png');
  return {role, sex, portrait, pixel: old.pixel, avatar:path.join(root, `mobile/assets/images/focus_selection_v001/avatars/${sex}/${role}.png`), reference: path.join(art, `references/${sex}-${role}.png`)};
}));
const label = (value, w = 768, h = 42) => Buffer.from(`<svg width="${w}" height="${h}"><text x="16" y="${Math.min(29,h-5)}" font-family="sans-serif" font-size="${h<30?16:20}" fill="#ffe3a0">${value}</text></svg>`);
async function references() {
  fs.mkdirSync(path.join(art, 'references'),{recursive:true});
  for (const r of records) {
    const inputs = [
      {input:label(`${r.sex} / ${r.role} — preserve this character's design`),left:0,top:0},
      {input:await sharp(r.portrait).resize(280,420,{fit:'contain',background:'#172b41'}).png().toBuffer(),left:0,top:50},
      {input:await sharp(r.pixel).resize(320,320,{kernel:'nearest',fit:'contain',background:'#172b41'}).png().toBuffer(),left:292,top:100},
      {input:await sharp(r.avatar).resize(128,128,{kernel:'nearest'}).png().toBuffer(),left:624,top:140},
      {input:label('ILLUSTRATION                 EXISTING BATTLE PIXELS      FACE',768,42),left:0,top:470}
    ];
    await sharp({create:{width:768,height:512,channels:4,background:'#172b41'}}).composite(inputs).png().toFile(r.reference);
  }
  fs.writeFileSync(path.join(art,'references.json'),JSON.stringify(records,null,2));
  for(const sex of ['male','female']) {
    const tiles=[];
    for(const [i,r] of records.filter(r=>r.sex===sex).entries()) tiles.push({input:await sharp(r.reference).resize(384,256).png().toBuffer(),left:i%4*384,top:Math.floor(i/4)*256});
    await sharp({create:{width:1536,height:1024,channels:4,background:'#172b41'}}).composite(tiles).png().toFile(path.join(art,`${sex}-reference-catalog.png`));
  }
  console.log(JSON.stringify(records.map(({role,sex,reference})=>({role,sex,reference}))));
}
async function packageImages() {
  const generated=JSON.parse(fs.readFileSync(path.join(art,fs.existsSync(path.join(art,'generation-final.json'))?'generation-final.json':'generation.json'),'utf8'));
  fs.mkdirSync(path.join(art,'originals'),{recursive:true});
  fs.mkdirSync(app,{recursive:true});
  fs.copyFileSync(generated.background.source,path.join(art,'originals/castle_courtyard.png'));
  const backgroundGrid=await sharp(generated.background.source).resize(256,384,{fit:'cover',kernel:'nearest'}).png().toBuffer();
  const background=await sharp(backgroundGrid).resize(768,1152,{kernel:'nearest'}).png().toBuffer();
  fs.writeFileSync(path.join(app,'castle_courtyard.png'),background);
  fs.writeFileSync(path.join(art,'castle_courtyard.png'),background);
  if(generated.stage) {
    fs.copyFileSync(generated.stage.source,path.join(art,'originals/hero_courtyard.png'));
    const stageGrid=await sharp(generated.stage.source).resize(256,192,{fit:'cover',kernel:'nearest'}).png().toBuffer();
    const stage=await sharp(stageGrid).resize(768,576,{kernel:'nearest'}).png().toBuffer();
    fs.writeFileSync(path.join(app,'hero_courtyard.png'),stage);
    fs.writeFileSync(path.join(art,'hero_courtyard.png'),stage);
  }
  const manifest=[];
  for(const r of generated.characters) {
    if(!r.source)throw new Error('Missing generated source for '+r.role);
    const prefix=`${r.sex}-${r.role}`;
    fs.copyFileSync(r.source,path.join(art,`originals/${prefix}.png`));
    const {data,info}=await sharp(r.source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    let x0=info.width,y0=info.height,x1=-1,y1=-1;
    for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++) {
      if(data[(y*info.width+x)*4+3]>127){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
    }
    if(x1<0)throw new Error('Empty original '+prefix);
    const crop={left:x0,top:y0,width:x1-x0+1,height:y1-y0+1};
    const tile=await sharp(r.source).extract(crop).resize(56,56,{fit:'inside',kernel:'nearest'}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    for(let i=3;i<tile.data.length;i+=4)tile.data[i]=tile.data[i]>127?255:0;
    const grid=await sharp({create:{width:64,height:64,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:tile.data,raw:tile.info,left:Math.floor((64-tile.info.width)/2),top:60-tile.info.height}]).png().toBuffer();
    const png=await sharp(grid).resize(128,128,{kernel:'nearest'}).png().toBuffer();
    const rgba=await sharp(png).ensureAlpha().raw().toBuffer();
    let blockExact=true,transparent=0,solid=0;
    for(let y=0;y<128;y++)for(let x=0;x<128;x++) {
      const i=(y*128+x)*4,j=((y&~1)*128+(x&~1))*4;
      for(let c=0;c<4;c++)if(rgba[i+c]!==rgba[j+c])blockExact=false;
      if(rgba[i+3]===0)transparent++;else if(rgba[i+3]===255)solid++;
    }
    if(!blockExact||!transparent||!solid||solid+transparent!==128*128)throw new Error('Pixel-grid/alpha validation failed '+prefix);
    for(const dir of [path.join(app,'standing',r.sex),path.join(art,'standing',r.sex)]) {
      fs.mkdirSync(dir,{recursive:true});fs.writeFileSync(path.join(dir,r.role+'.png'),png);
    }
    manifest.push({role:r.role,appearance:r.sex,file:`standing/${r.sex}/${r.role}.png`,width:128,height:128,logicalGrid:64,baseline:120,transparent,solid,exact2x2Blocks:blockExact,sha256:crypto.createHash('sha256').update(png).digest('hex'),reference:r.reference,original:`originals/${prefix}.png`});
  }
  fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify(manifest,null,2));
  const names=['剣士','拳闘士','侍','重騎士','忍者','アサシン','弓使い','魔法使い','ガンナー','魔剣士','陰陽師','鎌使い','天使','悪魔','ドラゴンナイト','バーサーカー'];
  const cards=manifest.map(r=>`<article><h3>${r.appearance==='female'?'女性':'男性'}・${names[roles.indexOf(r.role)]}</h3><div class="compare"><img src="references/${r.appearance}-${r.role}.png" alt="元の立ち絵・戦闘原画・顔アイコンの参照"><img class="standing" src="${r.file}" alt="新作の立ち姿"></div><a href="${r.file}">128px PNG</a> / <a href="${r.original}">生成原画</a></article>`).join('');
  fs.writeFileSync(path.join(art,'index.html'),`<!doctype html><html lang="ja"><meta charset="utf-8"><title>FocusQuest ドット絵キャラクター画面 v007</title><style>body{margin:0;background:#091c32;color:#fff5d9;font:16px/1.7 system-ui}main{max-width:1160px;margin:auto;padding:32px}a{color:#a7eaff}h1,h2,h3{color:#ffdb91}article{background:#142c43;border:2px solid #bb904b;padding:18px;margin:16px 0}.compare{display:flex;align-items:center;gap:24px}.compare img:first-child{width:65%;max-width:768px}.standing{width:256px;height:256px;image-rendering:pixelated}summary{cursor:pointer}.previews{display:flex;gap:16px}.previews img{width:42%;object-fit:contain;align-self:start}@media(max-width:700px){.compare{flex-direction:column}.compare img:first-child{width:100%}.previews img{width:48%}}</style><main><h1>キャラクター画面・ドット絵版 v007</h1><p>A案の全身表示。16職×男女、静止立ち姿32体。128×128px透過・64px論理格子・最近傍表示。</p><h2>実装画面プレビュー</h2><div class="previews"><img src="previews/character-390x844.png" alt="スマートフォン"><img src="previews/character-1086x1448.png" alt="剣士・大画面"></div><h2>32体の参照比較</h2><p>左：既存立ち絵・戦闘原画・承認済みの顔。右：新作の静止立ち姿。</p>${cards}</main></html>`);
  for(const sex of ['male','female']) {
    const tiles=[];
    for(const [i,r] of manifest.filter(r=>r.appearance===sex).entries()) {
      tiles.push({input:await sharp(path.join(art,r.file)).resize(256,256,{kernel:'nearest'}).png().toBuffer(),left:i%4*256,top:Math.floor(i/4)*280});
      tiles.push({input:label(r.role,256,24),left:i%4*256,top:Math.floor(i/4)*280+254});
    }
    await sharp({create:{width:1024,height:1120,channels:4,background:'#172b41'}}).composite(tiles).png().toFile(path.join(art,`${sex}-standing-catalog.png`));
  }
  console.log(JSON.stringify({packaged:manifest.length,pixelGridVerified:true,alphaVerified:true}));
}
(process.argv[2]==='package'?packageImages():references()).catch(e=>{console.error(e);process.exitCode=1});
