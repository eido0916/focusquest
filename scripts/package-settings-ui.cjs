const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art/settings_ui_v001');
const app = path.join(root, 'mobile/assets/images/settings_ui_v001');

(async () => {
  const input = JSON.parse(fs.readFileSync(path.join(art, 'generation.json'), 'utf8'));
  for (const dir of [app, path.join(art, 'raw'), path.join(art, 'materials')]) fs.mkdirSync(dir, {recursive:true});
  const manifest = [];
  for (const asset of input.assets) {
    fs.copyFileSync(asset.source, path.join(art, 'raw', `${asset.name}.png`));
    const image = sharp(asset.source);
    let rect;
    if (asset.name !== 'background') {
      const {data, info} = await image.ensureAlpha().raw().toBuffer({resolveWithObject:true});
      let x0=info.width,y0=info.height,x1=0,y1=0,transparent=0;
      for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) {
        const a=data[(y*info.width+x)*4+3];
        if(a===0) transparent++;
        if(a>200) {x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
      }
      if(!transparent) throw Error(`${asset.name} lacks transparent alpha`);
      rect = {left:x0,top:y0,width:x1-x0+1,height:y1-y0+1};
      image.extract(rect);
    }
    const png = await image.resize(asset.width,asset.height,{fit:'fill'}).png().toBuffer();
    for(const dir of [app,path.join(art,'materials')]) fs.writeFileSync(path.join(dir,`${asset.name}.png`),png);
    manifest.push({name:asset.name,file:`materials/${asset.name}.png`,width:asset.width,height:asset.height,crop:rect,
      runtime:`mobile/assets/images/settings_ui_v001/${asset.name}.png`});
  }
  fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify({version:'v001',generator:'built-in image_gen',assets:manifest},null,2));
  console.log(JSON.stringify(manifest,null,2));
})().catch(e=>{console.error(e);process.exit(1)});
