const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art/party_lobby_v001/materials');
const app = path.join(root, 'mobile/assets/images/party_lobby_v001');
const gold = '#eac982';
function frame(w,h,action=false,header=false) {
  const d = action ? `M36 5H${w-36}Q${w-8} 5 ${w-3} ${h/2}Q${w-8} ${h-5} ${w-36} ${h-5}H36Q8 ${h-5} 3 ${h/2}Q8 5 36 5Z`
    : `M20 5H${w-20}L${w-5} 20V${h-20}L${w-20} ${h-5}H20L5 ${h-20}V20Z`;
  const corner = '<path d="M0 24V0H24M4 20V4H20M0 12L12 0M4 22Q19 21 17 6Q23 9 29 1M7 7Q1 0 11 3Q21 7 11 13Q5 15 7 7"/>';
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><defs><linearGradient id="blue" x2=".8" y2="1"><stop stop-color="${action ? '#075196' : '#153956'}" stop-opacity=".94"/><stop offset=".55" stop-color="#082343" stop-opacity="${header ? '.86' : '.88'}"/><stop offset="1" stop-color="#06172d" stop-opacity=".94"/></linearGradient></defs><path d="${d}" fill="url(#blue)" stroke="${gold}" stroke-width="2"/><path d="${d}" transform="translate(7 5) scale(${(w-14)/w} ${(h-10)/h})" fill="none" stroke="${gold}" stroke-opacity=".4"/><g stroke="${gold}" stroke-width="1.3" fill="none"><g transform="translate(6 6)">${corner}</g><g transform="translate(${w-6} 6) scale(-1 1)">${corner}</g><g transform="translate(6 ${h-6}) scale(1 -1)">${corner}</g><g transform="translate(${w-6} ${h-6}) scale(-1 -1)">${corner}</g><path d="M${w/2-9} 5L${w/2} 0L${w/2+9} 5L${w/2} 10Z M${w/2-9} ${h-5}L${w/2} ${h-10}L${w/2+9} ${h-5}L${w/2} ${h}Z"/></g></svg>`;
}
const svgs = {
  panel: frame(640,260), header: frame(720,100,false,true),
  action: frame(640,110,true), member: frame(190,490),
  compass: `<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72"><g stroke="${gold}" stroke-width="1.3" fill="none"><circle cx="36" cy="36" r="24" opacity=".6"/><path d="M36 1L42 30L71 36L42 42L36 71L30 42L1 36L30 30Z M36 13L49 36L36 59L23 36Z M12 12L32 29L60 60L40 43Z M60 12L43 32L12 60L29 40Z"/><circle cx="36" cy="36" r="4" fill="${gold}"/></g></svg>`,
  crown: `<svg xmlns="http://www.w3.org/2000/svg" width="60" height="44"><path d="M8 33L3 11L17 21L30 3L43 21L57 11L52 33Z M8 37H52V42H8Z" fill="${gold}"/><circle cx="30" cy="4" r="3" fill="${gold}"/></svg>`,
};
(async()=>{
  for(const dir of [art,app,path.join(root,'art/party_lobby_v001/previews')]) fs.mkdirSync(dir,{recursive:true});
  for(const [name,svg] of Object.entries(svgs)) {
    fs.writeFileSync(path.join(art,name+'.svg'),svg);
    const png = await sharp(Buffer.from(svg)).png().toBuffer();
    fs.writeFileSync(path.join(art,name+'.png'),png);
    fs.writeFileSync(path.join(app,name+'.png'),png);
  }
  console.log('Saved six editable ornaments and app PNG assets.');
})().catch(e=>{console.error(e);process.exitCode=1});
