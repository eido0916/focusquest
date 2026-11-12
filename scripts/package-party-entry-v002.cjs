const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art/party_entry_v002');
const app = path.join(root, 'mobile/assets/images/party_entry_v002');
const generated = 'C:/Users/eido0/.codex/generated_images/01a185e3-7b7e-76f3-85b4-0b43316837ce';
const sources = {
  background: ['exec-c26c7229-1b1d-4335-80e1-83e10781d441.png', 941, 1672],
  action: ['exec-e4fe32f3-23b5-424e-8efd-c76d0bf82dbd.png', 800, 145],
  title: ['exec-7fae9ca6-e024-4e9c-9b81-29a3d15fccab.png', 820, 104],
  information: ['exec-1979601c-a253-41a3-bdd2-f8f28e67f6dd.png', 800, 150],
  back: ['exec-16a5e327-c918-4e05-a2e4-aa8914ee58f3.png', 104, 104],
};
const defs = `<defs><linearGradient id="gold" x2=".2" y2="1"><stop stop-color="#fff3b9"/><stop offset=".3" stop-color="#ffce58"/><stop offset=".5" stop-color="#a96310"/><stop offset=".72" stop-color="#ffe08d"/><stop offset="1" stop-color="#bf7e1d"/></linearGradient><linearGradient id="blue" x2=".4" y2="1"><stop stop-color="#00316c"/><stop offset="1" stop-color="#00163c"/></linearGradient></defs>`;
const corner = `<path d="M3 30C16 27 1 13 12 8C20 2 32 8 31 2M3 3L20 3L10 12M9 24C25 17 21 7 36 7" fill="none" stroke="url(#gold)" stroke-width="2.6" stroke-linecap="round"/>`;
const vectors = {
  'icon-back': [72,72,'<path d="M40 16L20 36L40 56M22 36H61" fill="none" stroke="#ffce60" stroke-width="8"/>'],
  compass: [80,80,`<g stroke="url(#gold)" fill="none" stroke-width="1.4"><circle cx="40" cy="40" r="25"/><circle cx="40" cy="40" r="18"/>${[0,45,90,135].map(a=>`<path transform="rotate(${a} 40 40)" d="M40 2L46 32L78 40L46 46L40 78L34 46L2 40L34 34Z"/>`).join('')}<path d="M40 6L51 40L40 74L29 40Z"/><path d="M6 40L40 29L74 40L40 51Z"/><circle cx="40" cy="40" r="4" fill="#f6c55f"/></g>`],
  'icon-create': [64,64,'<g fill="#fffdf6"><circle cx="27" cy="19" r="11"/><circle cx="47" cy="23" r="8"/><path d="M6 53V44C6 29 47 29 47 44V53ZM45 35C58 34 62 40 62 48V53H51V44C51 40 49 37 45 35Z"/><path d="M24 30L27 35L30 30L29 44H25Z" fill="#073066"/></g>'],
  'icon-join': [64,64,'<path d="M26 9H50Q55 9 55 14V50Q55 55 50 55H26V48H48V16H26Z" fill="#fffdf6"/><path d="M5 32H35M22 19L36 32L22 45" fill="none" stroke="#fffdf6" stroke-width="7" stroke-linejoin="miter"/>'],
  'icon-chevron': [48,64,'<path d="M15 14L33 32L15 50" fill="none" stroke="#fffdf6" stroke-width="7"/>'],
  separator: [4,64,'<path d="M2 1V63" stroke="#d7cda7" stroke-opacity=".7" stroke-width="1.4"/>'],
};
(async () => {
  for (const dir of [app, art, path.join(art,'materials'),path.join(art,'originals'),path.join(art,'vectors'),path.join(art,'previews')]) fs.mkdirSync(dir,{recursive:true});
  fs.copyFileSync('C:/Users/eido0/AppData/Local/Temp/codex-clipboard-1b16c0db-4bc7-4e21-a541-decef66f5a24.png',path.join(art,'reference.png'));
  const entries = [];
  async function save(name,buffer,width,height,method) {
    for (const dir of [app,path.join(art,'materials')]) fs.writeFileSync(path.join(dir,name+'.png'),buffer);
    entries.push({name,width,height,method,sha256:crypto.createHash('sha256').update(buffer).digest('hex')});
  }
  for(const [name,[file,w,h]] of Object.entries(sources)) {
    fs.copyFileSync(path.join(generated,file),path.join(art,'originals',name+'.png'));
    let image=sharp(path.join(generated,file));
    if(name!=='background') image=image.trim();
    await save(name,await image.resize(w,h,{fit:'fill',kernel:name==='background'?'nearest':'lanczos3'}).png().toBuffer(),w,h,'Built-in ImageGen; alpha-trimmed and sized for Flutter');
  }
  for(const [name,[w,h,body]] of Object.entries(vectors)) {
    const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${defs}${body}</svg>`;
    fs.writeFileSync(path.join(art,'vectors',name+'.svg'),svg);
    await save(name,await sharp(Buffer.from(svg)).png().toBuffer(),w,h,'Individual editable SVG, matching existing project ornaments');
  }
  fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify({version:'v002',assets:entries},null,2));
  const tiles=await Promise.all(entries.map(async(e,i)=>({input:await sharp(path.join(app,e.name+'.png')).resize(330,190,{fit:'contain',background:'#2a435c'}).extend({top:26,bottom:4,left:4,right:4,background:'#2a435c'}).composite([{input:Buffer.from(`<svg width="330" height="26"><text x="7" y="18" fill="#ffe0a0" font-size="16">${e.name}</text></svg>`),top:0,left:4}]).png().toBuffer(),left:(i%3)*338,top:Math.floor(i/3)*220})));
  await sharp({create:{width:1014,height:Math.ceil(entries.length/3)*220,channels:4,background:'#2a435c'}}).composite(tiles).png().toFile(path.join(art,'material_catalog.png'));
  console.log(`Saved ${entries.length} independent party-entry assets.`);
})();
