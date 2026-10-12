const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const generated = 'C:/Users/eido0/.codex/generated_images/01a12b28-b6b0-7471-9caa-efaccf4ad84b';
const art = path.join(root, 'art/adventure_ui_v001');
const app = path.join(root, 'mobile/assets/images/adventure_ui_v001');
const sources = {
  status_panel:'9ad91681-77b8-4cc6-ace2-3e5f9779ee97',
  stage_banner:'b5a5696b-8e3c-49b1-ad37-ecfe94316dae',
  phase_panel:'5d5da4c0-0380-4037-ac3a-ab31c71acea7',
  attack_button:'06a967b1-8984-410a-a544-e71aed87e6a5',
  skill_button:'5c9c11f5-052c-4aac-9c21-1e196f0c4b5f',
  auto_button:'0c02c161-3663-4b8d-bb77-86ba9a12b139',
  utility_button:'bcef13e9-cb5e-4d2f-bb28-f046b62c465c',
  caption_frame:'231bf892-494a-40fc-828d-692897b90c0c',
  portrait_frame:'0ec026de-e055-42f9-b47a-be9a495badfb',
  hp_frame:'200a9b61-f684-4d04-a095-f4647cc4bdcf',
};
(async () => {
  for(const dir of [art, app, path.join(art,'raw'), path.join(art,'frames')]) fs.mkdirSync(dir,{recursive:true});
  const manifest = [];
  const tiles = [];
  let index=0;
  for(const [name,id] of Object.entries(sources)) {
    const src=path.join(generated,`exec-${id}.png`);
    fs.copyFileSync(src,path.join(art,'raw',`${name}.png`));
    const {data,info}=await sharp(src).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    let minX=info.width,minY=info.height,maxX=-1,maxY=-1,transparent=0;
    for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) {
      const alpha=data[(y*info.width+x)*4+3];
      if(alpha===0) transparent++;
      if(alpha>32){minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);}
    }
    if(transparent===0) throw Error(`${name}: missing transparency`);
    const rect={left:minX,top:minY,width:maxX-minX+1,height:maxY-minY+1};
    const png=await sharp(src).extract(rect).png().toBuffer();
    fs.writeFileSync(path.join(art,'frames',`${name}.png`),png);
    fs.writeFileSync(path.join(app,`${name}.png`),png);
    manifest.push({name,file:`frames/${name}.png`,width:rect.width,height:rect.height,
      source:`raw/${name}.png`,crop:rect,hasTransparentPixels:true});
    const tile=await sharp(png).resize(460,190,{fit:'inside'}).png().toBuffer();
    const m=await sharp(tile).metadata();
    const x=(index%2)*520+30,y=Math.floor(index/2)*250+38;
    tiles.push({input:tile,left:x+Math.floor((460-m.width)/2),top:y+Math.floor((190-m.height)/2)});
    tiles.push({input:Buffer.from(`<svg width="490" height="30"><text x="0" y="22" font-size="20" fill="#f5d492" font-family="sans-serif">${name} · ${rect.width} × ${rect.height}</text></svg>`),left:x,top:y-32});
    index++;
  }
  await sharp({create:{width:1040,height:1250,channels:4,background:'#172333'}}).composite(tiles).png().toFile(path.join(art,'frame_catalog.png'));
  fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify({version:'v001',generator:'built-in image_gen',assets:manifest},null,2));
  console.log(JSON.stringify(manifest.map(({name,width,height})=>({name,width,height})),null,2));
})().catch(e=>{console.error(e);process.exitCode=1});
