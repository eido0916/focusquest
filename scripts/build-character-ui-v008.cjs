const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art/character_ui_v008');
const app = path.join(root, 'mobile/assets/images/character_ui_v008');
const svg = (w,h,body) => Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" shape-rendering="crispEdges">${body}</svg>`);
const rect = (x,y,w,h,fill,stroke='',sw=1) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${fill}"${stroke?` stroke="${stroke}" stroke-width="${sw}"`:''}/>`;
function corner(x,y,sx,sy) {
 return `<g transform="translate(${x} ${y}) scale(${sx*.65} ${sy*.65})">`+
 rect(0,0,15,4,'#39230d')+rect(0,0,4,15,'#39230d')+
 rect(1,1,12,2,'#ffe89a')+rect(1,1,2,12,'#ffe89a')+
 rect(5,5,7,7,'#d19b36','#452c12')+rect(7,7,3,3,'#092d53')+
 rect(14,2,4,3,'#ffc85f')+rect(2,14,3,4,'#ffc85f')+`</g>`;
}
function frame(w,h,paper=false,crest=false) {
 let b=rect(1,1,w-2,h-2,'#302715')+rect(2,2,w-4,h-4,'#fbe5a2')+
 rect(3,3,w-6,h-6,'#ae792b')+rect(4,4,w-8,h-8,paper?'#faedc9':'#08254a')+
 rect(5,5,w-10,h-10,'none',paper?'#d4af65':'#355a76');
 if(paper) {
  b+=`<defs><radialGradient id="paper"><stop stop-color="#fff6d9"/><stop offset="1" stop-color="#f3e4bb"/></radialGradient></defs>`+rect(8,8,w-16,h-16,'url(#paper)');
 } else {
  for(let y=13;y<h-8;y+=12)for(let x=14;x<w-8;x+=12)b+=`<path d="M${x} ${y-2}l2 2-2 2-2-2z" fill="#12385c" opacity=".45"/>`;
 }
 for(const [x,y,sx,sy] of [[0,0,1,1],[w,0,-1,1],[0,h,1,-1],[w,h,-1,-1]]) b+=corner(x,y,sx,sy);
 if(crest)for(const y of [2,h-2])b+=`<path d="M${w/2-8} ${y}l5-2 3-4 3 4 5 2-5 2-3 4-3-4z" fill="#eab958" stroke="#493012"/><rect x="${w/2-1}" y="${y-1}" width="2" height="2" fill="#fff0ab"/>`;
 return svg(w,h,b);
}
async function save(name,input) {
 const png = await sharp(input).png().toBuffer();
 fs.writeFileSync(path.join(art,'materials',name+'.png'),png);
 fs.writeFileSync(path.join(app,name+'.png'),png);
}
async function main() {
 for(const d of [art,app,path.join(art,'materials'),path.join(art,'originals')])fs.mkdirSync(d,{recursive:true});
 for(const [name,w,h,paper,crest] of [['identity_panel',400,82,false,true],['header_banner',240,44,false,true],['stat_row',200,42,false,false],['action_row',200,46,false,false],['stats_parchment',400,286,true,false]])await save(name,frame(w,h,paper,crest));
 const icons={
 stat_hp:'<path d="M12 20L3 11C-2 3 7-1 12 5C17-1 26 3 21 11Z"/>',
 stat_attack:'<path d="M4 21L2 19L14 4L21 1L20 8L7 21Z"/><path d="M2 13L12 21M3 22L1 24" fill="none" stroke="#ffd57e" stroke-width="3"/>',
 stat_defense:'<path d="M3 4L12 1L21 4V12Q20 18 12 23Q4 18 3 12Z"/>',
 stat_speed:'<path d="M7 2H14V15L21 17V21H2V17L7 15Z"/>',
 stat_critical:'<path d="M12 0L15 9L24 12L15 15L12 24L9 15L0 12L9 9Z"/>',
 certificate_icon:'<path d="M4 1H21V23H4Z"/><path d="M8 6H17M8 11H17M8 16H14" fill="none" stroke="#14375a" stroke-width="2"/>',
 chevron_icon:'<path d="M8 4L15 12L8 20" fill="none" stroke="#ffd57e" stroke-width="2"/>',
 title_icon:[-1,1].flatMap(side=>Array.from({length:6},(_,i)=>{const a=(i*22+10)*Math.PI/180,x=12+side*9*Math.sin(a),y=11-9*Math.cos(a);return `<ellipse cx="${x}" cy="${y}" rx="1.2" ry="2.3" transform="rotate(${side*(i*22+35)} ${x} ${y})"/>`;})).join('')+'<path d="M5 20L12 22L19 20M12 20V24" stroke="#ffd57e" fill="none"/>',
 };
 for(const [n,b]of Object.entries(icons))await save(n,svg(24,24,`<g fill="#ffd57e">${b}</g>`));
 await save('section_rule',svg(140,12,'<path d="M0 6H128M128 3L131 6L128 9M133 4L135 6L133 8M138 5V7" stroke="#b9893c" fill="none"/>'));
 for(const name of ['identity_divider','value_divider'])await save(name,svg(1,50,rect(0,0,1,50,'#45617a')));
 await save('exp_track',svg(200,12,rect(0,0,200,12,'#8faab6')+rect(1,1,198,10,'#1d3d58')));
 await save('exp_fill',svg(200,12,'<defs><linearGradient id="blue" x2="0" y2="1"><stop stop-color="#a3efff"/><stop offset="1" stop-color="#43b7e9"/></linearGradient></defs>'+rect(0,0,200,12,'url(#blue)')));
 if(process.argv[2]==='--frames-only')return;
 const records=JSON.parse(fs.readFileSync(path.join(root,'art/character_pixel_v007/manifest.json'),'utf8'));
 for(const r of records){
  const target=path.join(app,'standing',r.appearance);fs.mkdirSync(target,{recursive:true});
  const original=path.join(root,'art/character_pixel_v007',r.original);
  // Preserve the original drawing's detail instead of reducing to a 64px grid.
  const cropped=await sharp(original).trim({threshold:10}).png().toBuffer();
  const tile=await sharp(cropped).resize(464,464,{fit:'inside',kernel:'nearest'}).png().toBuffer();
  const m=await sharp(tile).metadata();
  await sharp({create:{width:512,height:512,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:tile,left:Math.floor((512-m.width)/2),top:488-m.height}]).png().toFile(path.join(target,r.role+'.png'));
 }
 if(process.argv[2])for(const [name,source]of [['castle_courtyard',process.argv[2]],['warrior',process.argv[3]]]){
  if(!source)continue;
  fs.copyFileSync(source,path.join(art,'originals',name+'.png'));
  if(name==='castle_courtyard')await save(name,source);
  else {
   const tile=await sharp(source).trim({threshold:10}).resize(464,464,{fit:'inside',kernel:'nearest'}).png().toBuffer();const m=await sharp(tile).metadata();
   await sharp({create:{width:512,height:512,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:tile,left:Math.floor((512-m.width)/2),top:488-m.height}]).png().toFile(path.join(app,'standing/male/warrior.png'));
  }
 }
 console.log('Packaged separate frames, icons and 32 detailed standing portraits into '+app);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
