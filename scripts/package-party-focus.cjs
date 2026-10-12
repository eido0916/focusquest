const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art/party_focus_v001');
const app = path.join(root, 'mobile/assets/images/party_focus_v001');
const corner = '<path d="M0 25V0H25 M3 22V3H22 M0 13L7 6L13 0 M4 19Q16 18 16 7Q24 12 30 3 M7 7Q2 2 11 3Q18 5 13 11Q8 16 7 7 M1 29L8 23L3 18 M18 3L23 8L29 1"/>';
function frame(w,h) {
 return '<svg xmlns="http://www.w3.org/2000/svg" width="'+w+'" height="'+h+'" viewBox="0 0 '+w+' '+h+'"><rect x="2" y="2" width="'+(w-4)+'" height="'+(h-4)+'" fill="#07131b" fill-opacity=".88"/><g fill="none" stroke="#ac8651" stroke-width="1.1"><rect x="2" y="2" width="'+(w-4)+'" height="'+(h-4)+'"/><g transform="translate(2 2)">'+corner+'</g><g transform="translate('+(w-2)+' 2) scale(-1 1)">'+corner+'</g><g transform="translate(2 '+(h-2)+') scale(1 -1)">'+corner+'</g><g transform="translate('+(w-2)+' '+(h-2)+') scale(-1 -1)">'+corner+'</g></g></svg>';
}
(async () => {
 for (const dir of [art, app, path.join(art,'materials'), path.join(art,'previews')]) fs.mkdirSync(dir,{recursive:true});
 const svgs = {
  header_frame: frame(960,74),
  member_frame: frame(180,72),
  compass: '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="56"><g fill="none" stroke="#ac8651" stroke-width="1.2"><path d="M24 3L28 21L44 28L28 34L24 53L20 34L4 28L20 21Z M24 12L32 28L24 44L16 28Z M24 21L31 28L24 35L17 28Z M24 0V56 M0 28H48 M9 13L39 43 M39 13L9 43"/><circle cx="24" cy="28" r="3"/></g></svg>'
 };
 const manifest=[];
 for(const [name,svg] of Object.entries(svgs)) {
  fs.writeFileSync(path.join(art,'materials',name+'.svg'),svg);
  const png=await sharp(Buffer.from(svg)).png().toBuffer();
  fs.writeFileSync(path.join(art,'materials',name+'.png'),png);
  fs.writeFileSync(path.join(app,name+'.png'),png);
  const {width,height}=await sharp(png).metadata();
  manifest.push({file:name+'.png',width,height});
 }
 fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify(manifest,null,2));
 console.log('Created three separate party focus ornaments.');
})().catch(e=>{console.error(e);process.exitCode=1});
