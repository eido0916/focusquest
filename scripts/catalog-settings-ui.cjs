const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const art = path.resolve(__dirname, '../art/settings_ui_v001');
(async () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(art,'manifest.json'),'utf8'));
  const files = fs.readdirSync(path.join(art,'materials')).filter(f=>f.endsWith('.png'));
  const layers=[];
  for(let i=0;i<files.length;i++) {
    const name=files[i], p=path.join(art,'materials',name);
    const info=await sharp(p).metadata();
    const png=await sharp(p).resize(290,158,{fit:'inside'}).png().toBuffer();
    const m=await sharp(png).metadata();
    const x=(i%4)*320,y=Math.floor(i/4)*210;
    layers.push({input:png,left:x+Math.floor((320-m.width)/2),top:y+35+Math.floor((158-m.height)/2)});
    layers.push({input:Buffer.from(`<svg width="320" height="32"><text x="14" y="24" font-family="sans-serif" font-size="16" fill="#ffedb9">${name} · ${info.width}×${info.height}</text></svg>`),left:x,top:y});
    if(!manifest.assets.some(a=>`${a.name}.png`===name)) manifest.assets.push({name:name.slice(0,-4),
      file:`materials/${name}`,width:info.width,height:info.height,generator:'Flutter Material Icons / native UI'});
  }
  await sharp({create:{width:1280,height:Math.ceil(files.length/4)*210,channels:4,background:'#29405b'}})
    .composite(layers).png().toFile(path.join(art,'material_catalog.png'));
  fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify(manifest,null,2));
  console.log(`${files.length} separate materials cataloged`);
})().catch(e=>{console.error(e);process.exit(1)});
