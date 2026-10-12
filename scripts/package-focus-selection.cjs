const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art/focus_selection_v001');
const app = path.join(root, 'mobile/assets/images/focus_selection_v001');
const generated = 'C:/Users/eido0/.codex/generated_images/01a12dd4-afc2-7a62-9716-0611942553d4';
const sources = {
  background:'a02dc3a9-e7a8-4060-a0ed-c6b56ab05848',
  parchment_panel:'1421a1e9-ea08-4f34-a715-8ddc8a9d788e',
  party_panel:'ec2cdd82-ea5b-4619-8bc2-e627d9e7320a',
  custom_strip:'b81e0606-05b1-4970-bd97-e10f22a12697',
  blue_button:'ca7b8790-04f8-4e78-afe4-6b9c6c663df3',
  stage_banner:'4b983551-ee5d-48e6-84a5-6fa731e9515b',
  avatar_frame:'ae7ac2c4-8f5d-482a-ba58-d81ca3f8b850',
  time_button:'b86a5f41-6368-4a00-9f0f-4f24f80934b1',
  time_selected:'f8332365-faa5-4fe6-ab25-1f30ff6222c6',
  back_button:'98f5f1f4-dcc5-42b8-a0f9-adf2b327b0de',
  navigation_panel:'cccc7e4e-6d9f-4f90-8c2d-765a691cbc50'
};
const icons = {
  hourglass:'<path d="M16 5h32v6H16zM16 53h32v6H16zM21 11v9l11 12-11 12v9h22v-9L32 32l11-12v-9" fill="none" stroke="currentColor" stroke-width="3"/><path d="m25 18 7 8 7-8zm0 29h14l-7-8z"/>',
  party:'<circle cx="32" cy="16" r="9"/><circle cx="12" cy="23" r="6"/><circle cx="52" cy="23" r="6"/><path d="M18 57V41a14 14 0 0 1 28 0v16zM2 48V37a10 10 0 0 1 13-10l5 4a18 18 0 0 0-7 16v1zm60 0V37a10 10 0 0 0-13-10l-5 4a18 18 0 0 1 7 16v1z"/>',
  list:'<circle cx="10" cy="14" r="4"/><circle cx="10" cy="32" r="4"/><circle cx="10" cy="50" r="4"/><path d="M20 10h35v8H20zM20 28h35v8H20zM20 46h35v8H20z"/>',
  compass:'<circle cx="32" cy="32" r="23" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="32" cy="32" r="18" fill="none" stroke="currentColor" stroke-width="1"/><path d="m32 1 5 24 12-10-10 13 24 4-24 5 10 12-13-10-4 24-5-24-12 10 10-13-24-4 24-5-10-12 13 10z"/><path d="m32 5 0 27 5-7zm27 27H32l7 5zM32 59V32l-5 7zM5 32h27l-7-5z" fill="#704725"/>',
  bag:'<path d="m19 8 7 11h13l8-11-8-2-7 2-7-2zM22 22C15 26 7 40 7 48c0 15 50 15 50 0 0-8-8-22-15-26z"/><path d="M21 20h23M30 25l-4 20 6 5 6-5-5-20" fill="none" stroke="#45280e" stroke-width="3"/>',
  book:'<path d="M4 10v43c9-3 19-2 28 3V14C23 8 13 7 4 10zm56 0v43c-9-3-19-2-28 3V14c9-6 19-7 28-4z" fill="none" stroke="currentColor" stroke-width="4"/><path d="M11 17h12M11 25h12M11 33h12M41 17h12M41 25h12M41 33h12" stroke="currentColor" stroke-width="3"/>',
  gear:'<path d="m26 3 12 0 2 8 7 4 8-3 6 10-6 6v8l6 6-6 10-8-3-7 4-2 8H26l-2-8-7-4-8 3-6-10 6-6v-8l-6-6 6-10 8 3 7-4z"/><circle cx="32" cy="32" r="13" fill="#092039"/><circle cx="32" cy="32" r="7"/>',
  back:'<path d="m30 10-22 22 22 22 6-6-12-12h33v-8H24l12-12z"/>',
  chevron:'<path d="m24 13 19 19-19 19" fill="none" stroke="currentColor" stroke-width="6"/>',
  divider:'<path d="M3 32h58" stroke="currentColor" stroke-width="1"/><path d="m5 32 4-4 4 4-4 4zm46 0 4-4 4 4-4 4z"/>'
};
(async()=>{
  for(const d of [art, app, path.join(art,'raw'),path.join(art,'materials'),path.join(art,'icons')])fs.mkdirSync(d,{recursive:true});
  const manifest=[];const tiles=[];
  for(const [name,id] of Object.entries(sources)){
    const src=path.join(generated,`exec-${id}.png`);
    fs.copyFileSync(src,path.join(art,'raw',name+'.png'));
    const png=await (name==='background' ? sharp(src) : sharp(src).trim({threshold:1})).png().toBuffer();
    // Trim only transparent outer margins; retain the original generated artwork.
    fs.writeFileSync(path.join(art,'materials',name+'.png'),png);
    fs.writeFileSync(path.join(app,name+'.png'),png);
    const m=await sharp(png).metadata();manifest.push({name,width:m.width,height:m.height,source:src});
    if(name!=='background'){
      const b=await sharp(png).resize(460,170,{fit:'inside'}).png().toBuffer();const p=await sharp(b).metadata();const i=tiles.length/2;
      tiles.push({input:b,left:(i%2)*500+20+Math.floor((460-p.width)/2),top:Math.floor(i/2)*220+35});
      tiles.push({input:Buffer.from(`<svg width="460" height="30"><text x="0" y="22" fill="#ffe2a2" font-size="18">${name}</text></svg>`),left:(i%2)*500+20,top:Math.floor(i/2)*220});
    }
  }
  for(const [name,body] of Object.entries(icons)){
    const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 64 64" color="#dfb36b" fill="#dfb36b">${body}</svg>`;
    fs.writeFileSync(path.join(art,'icons',name+'.svg'),svg);
    const png=await sharp(Buffer.from(svg)).png().toBuffer();
    fs.writeFileSync(path.join(app,'icon_'+name+'.png'),png);
    fs.writeFileSync(path.join(art,'materials','icon_'+name+'.png'),png);
    manifest.push({name:'icon_'+name,width:128,height:128,generator:'native SVG'});
  }
  await sharp({create:{width:1000,height:Math.ceil(tiles.length/4)*220,channels:4,background:'#16283a'}}).composite(tiles).png().toFile(path.join(art,'material_catalog.png'));
  fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify(manifest,null,2));
  console.log(manifest);
})().catch(e=>{console.error(e);process.exitCode=1});
