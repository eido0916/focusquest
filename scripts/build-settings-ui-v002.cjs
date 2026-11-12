// Code-native vector artwork; preserves all earlier UI materials.
const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art/settings_ui_v002');
const app = path.join(root, 'mobile/assets/images/settings_ui_v002');
const defs = `<defs>
 <linearGradient id="gold" x2=".25" y2="1"><stop stop-color="#fff0ab"/><stop offset=".32" stop-color="#eab74e"/><stop offset=".55" stop-color="#9c601b"/><stop offset=".75" stop-color="#ffe4a0"/><stop offset="1" stop-color="#c88d2c"/></linearGradient>
 <linearGradient id="blue" x2=".2" y2="1"><stop stop-color="#063c80"/><stop offset=".45" stop-color="#00295d"/><stop offset="1" stop-color="#001938"/></linearGradient>
 <linearGradient id="dark" x2="1" y2=".5"><stop stop-color="#102432"/><stop offset=".55" stop-color="#071b29"/><stop offset="1" stop-color="#122735"/></linearGradient>
 <linearGradient id="coin" x2="1" y2=".4"><stop stop-color="#ffdf87"/><stop offset=".5" stop-color="#f8cd68"/><stop offset="1" stop-color="#dca849"/></linearGradient>
 <linearGradient id="switch" x2="1" y2="1"><stop stop-color="#ad7c25"/><stop offset=".55" stop-color="#d5a338"/><stop offset="1" stop-color="#f8d77e"/></linearGradient>
 </defs>`;
const svg = (w,h,body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${defs}${body}</svg>`;
function diamond(x,y,s=12) {return `<path d="M${x} ${y-s} Q${x+s*.3} ${y-s*.25} ${x+s} ${y} Q${x+s*.3} ${y+s*.25} ${x} ${y+s} Q${x-s*.3} ${y+s*.25} ${x-s} ${y} Q${x-s*.3} ${y-s*.25} ${x} ${y-s}Z" fill="#061d37" stroke="url(#gold)" stroke-width="2.6"/><path d="M${x} ${y-s*.5}L${x+s*.3} ${y}L${x} ${y+s*.5}L${x-s*.3} ${y}Z" fill="#ffe3a0"/>`;}
function corner(x,y,sx,sy) {return `<g transform="translate(${x} ${y}) scale(${sx} ${sy})" fill="none" stroke-linecap="round" stroke-linejoin="round">
 <path d="M0 55C12 50 0 37 8 25C16 13 30 18 27 5L4 2L8 18C20 10 23 24 14 29C2 36 12 48 4 56M3 4L23 9L11 16Z" stroke="#35210d" stroke-width="7"/>
 <path d="M0 55C12 50 0 37 8 25C16 13 30 18 27 5L4 2L8 18C20 10 23 24 14 29C2 36 12 48 4 56M3 4L23 9L11 16Z" stroke="url(#gold)" stroke-width="3.5"/>
 <path d="M15 43C34 28 34 9 51 9C62 9 57 24 48 18M30 9L41 3L53 6M8 23L19 18" stroke="url(#gold)" stroke-width="2.5"/></g>`;}
function frame(w,h,fill='blue',rosette=true) {
 const edge=`M32 12H${w-32}Q${w-12} 12 ${w-12} 32V${h-32}Q${w-12} ${h-12} ${w-32} ${h-12}H32Q12 ${h-12} 12 ${h-32}V32Q12 12 32 12Z`;
 let body=`<path d="${edge}" fill="url(#${fill})" stroke="#21190e" stroke-width="9"/><path d="${edge}" fill="none" stroke="url(#gold)" stroke-width="5"/><rect x="18" y="18" width="${w-36}" height="${h-36}" rx="15" fill="none" stroke="#f4c662" stroke-width="1.2"/>`;
 if(rosette) for(const cx of [100,w-100]) {body+=`<g transform="translate(${cx} ${h/2})" opacity=".10" stroke="#3e8ec7" fill="none">`;for(let a=0;a<360;a+=45) body+=`<path transform="rotate(${a})" d="M0 -${h*.36}L7 -8L${h*.22} 0L7 8L0 ${h*.36}L-7 8L-${h*.22} 0L-7 -8Z"/>`;body+='</g>';}
 return body+corner(6,6,1,1)+corner(w-6,6,-1,1)+corner(6,h-6,1,-1)+corner(w-6,h-6,-1,-1)+diamond(w/2,12,12)+diamond(w/2,h-12,9);
}
const icons={
 phone:'<rect x="24" y="11" width="24" height="48" rx="5"/><rect x="29" y="18" width="14" height="30" fill="#ffdb7f"/><circle cx="36" cy="54" r="2" fill="#ffdb7f"/>',
 overlay:'<rect x="15" y="15" width="19" height="19" rx="5"/><rect x="38" y="15" width="19" height="19" rx="5"/><rect x="15" y="38" width="19" height="19" rx="5"/><rect x="38" y="38" width="19" height="19" rx="5"/>',
 shield:'<path d="M36 8L57 14V33Q56 50 36 63Q16 50 15 33V14Z"/><path d="M36 10V59Q52 49 54 33V16Z" fill="#ffe7a0"/>',
 music:'<path d="M38 11V45C20 37 12 55 23 60C31 64 43 56 43 47V21C57 31 63 14 44 10Z"/>',
 sound:'<path d="M12 28H24L40 14V58L24 44H12Q9 44 9 40V32Q9 28 12 28Z"/><path d="M48 25Q59 36 48 47M55 17Q74 36 55 55" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round"/>',
 cloud:'<path d="M20 53C0 50 7 28 22 30C23 9 51 9 53 31C72 29 76 52 58 53Z" fill="none" stroke="currentColor" stroke-width="5" stroke-linejoin="round"/>',
 warning:'<circle cx="36" cy="36" r="29"/><path d="M36 22V38" stroke="#322512" stroke-width="7" stroke-linecap="round"/><circle cx="36" cy="49" r="3.5" fill="#322512"/>',
 back:'<path d="M43 17L24 36L43 55M25 36H60" fill="none" stroke="currentColor" stroke-width="7" stroke-linejoin="miter"/>',
 chevron:'<path d="M28 16L46 36L28 56" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>',
};
(async()=>{
 for(const dir of [app,path.join(art,'materials'),path.join(art,'vectors')]) fs.mkdirSync(dir,{recursive:true});
 const entries=[];
 async function save(name,w,h,body) {const source=svg(w,h,body); fs.writeFileSync(path.join(art,'vectors',name+'.svg'),source); const png=await sharp(Buffer.from(source)).png().toBuffer();for(const dir of [app,path.join(art,'materials')])fs.writeFileSync(path.join(dir,name+'.png'),png);entries.push({name,width:w,height:h,file:`materials/${name}.png`});}
 await save('title',660,154,frame(660,154));
 await save('section',840,100,frame(840,100));
 await save('panel',840,400,frame(840,400,'dark',false));
 await save('button',260,88,frame(260,88));
 await save('back',100,100,frame(100,100,'blue',false));
 await save('row',780,116,'<rect x="1" y="1" width="778" height="114" rx="10" fill="url(#dark)" stroke="#8c9088" stroke-width="1.3"/>');
 await save('notice',780,96,'<path d="M9 1H771L779 9V87L771 95H9L1 87V9Z" fill="#2c2519" fill-opacity=".95" stroke="#cda249" stroke-width="1.5"/>');
 for (const [name,body] of Object.entries(icons)) {
 await save('icon-'+name,72,72,`<g fill="#f5ce76" color="#f5ce76">${body}</g>`);
 if(['phone','overlay','cloud'].includes(name)) await save('medallion-'+name,88,88,`<circle cx="44" cy="44" r="41" fill="url(#coin)" stroke="#a8792b" stroke-width="3"/><circle cx="44" cy="44" r="38" fill="none" stroke="#ffe9a7" stroke-width="2"/><g transform="translate(8 8)" fill="#07517c" color="#07517c">${body}</g>`);
 }
 for(const enabled of [true,false])await save('toggle-'+(enabled?'on':'off'),108,58,`<rect x="3" y="4" width="102" height="50" rx="25" fill="${enabled?'url(#switch)':'#3e5260'}" stroke="#ffe4a2" stroke-width="3"/><circle cx="${enabled?80:28}" cy="29" r="20" fill="#fffdf5" stroke="#fff4d0" stroke-width="1"/>`);
 fs.copyFileSync(path.join(root,'mobile/assets/images/lobby/castle_courtyard.png'),path.join(app,'background.png'));
 fs.copyFileSync(path.join(app,'background.png'),path.join(art,'materials/background.png'));
 fs.copyFileSync('C:/Users/eido0/AppData/Local/Temp/codex-clipboard-e4775408-5cf0-4d1d-9246-bf9c34f4f900.png',path.join(art,'reference.png'));
 fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify({version:'v002',method:'Individual code-native SVG artwork, rasterized for Flutter; existing castle background reused',assets:entries},null,2));
 const tiles=await Promise.all(entries.map(async(e)=>({input:await sharp(path.join(app,e.name+'.png')).resize(250,140,{fit:'contain',background:'#213b52'}).extend({top:24,bottom:6,left:5,right:5,background:'#213b52'}).composite([{input:Buffer.from(`<svg width="250" height="24"><text x="5" y="16" fill="#ffe2a0" font-size="14">${e.name}</text></svg>`),top:0,left:5}]).png().toBuffer(),left:(entries.indexOf(e)%4)*260,top:Math.floor(entries.indexOf(e)/4)*170})));
 await sharp({create:{width:1040,height:Math.ceil(entries.length/4)*170,channels:4,background:'#213b52'}}).composite(tiles).png().toFile(path.join(art,'material_catalog.png'));
 console.log(`Created ${entries.length} individual assets + background`);
})();
