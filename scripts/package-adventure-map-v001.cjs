const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..'),art=path.join(root,'art/adventure_map_v001'),app=path.join(root,'mobile/assets/images/adventure_map_v001');
const defs='<defs><linearGradient id="gold" x2=".2" y2="1"><stop stop-color="#fff1ae"/><stop offset=".3" stop-color="#edba46"/><stop offset=".5" stop-color="#996217"/><stop offset=".8" stop-color="#ffe6a0"/><stop offset="1" stop-color="#c18c31"/></linearGradient><linearGradient id="navy" x2=".2" y2="1"><stop stop-color="#062b5d"/><stop offset="1" stop-color="#00192f"/></linearGradient></defs>';
(async()=>{
 for(const dir of [art,app,...['materials','originals','vectors','previews'].map(d=>path.join(art,d))])fs.mkdirSync(dir,{recursive:true});
 const entries=[];
 async function save(name,buffer,w,h,method){for(const dir of [app,path.join(art,'materials')])fs.writeFileSync(path.join(dir,name+'.png'),buffer);entries.push({name,width:w,height:h,method,sha256:crypto.createHash('sha256').update(buffer).digest('hex')});}
 async function svg(name,w,h,body){const src=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${defs}${body}</svg>`;fs.writeFileSync(path.join(art,'vectors',name+'.svg'),src);await save(name,await sharp(Buffer.from(src)).png().toBuffer(),w,h,'Editable individual SVG');}
 const sources=JSON.parse(fs.readFileSync(path.join(art,'source-files.json')));
 for(const[name,file]of Object.entries(sources)){
  const original=path.join(art,'originals',name+'.png');
  const source=fs.existsSync(file)?file:original;
  if(path.resolve(source)!==path.resolve(original))fs.copyFileSync(source,original);
  const [w,h]=name.startsWith('map_')?[941,750]:name.startsWith('node_')?[220,220]:name==='header'?[900,140]:name==='details'?[900,260]:[500,100];
  let img=sharp(source);if(!name.startsWith('map_'))img=img.trim();
  await save(name,await img.resize(w,h,{fit:'fill',kernel:name.startsWith('map_')?'nearest':'lanczos3'}).png().toBuffer(),w,h,'Built-in ImageGen; alpha trim and production sizing');
 }
 for(const[name,src,w,h]of [['chapter','header',900,100],['teaser','details',900,190],['button_navy','header',500,100]]){
  if(fs.existsSync(path.join(app,src+'.png')))await save(name,await sharp(path.join(app,src+'.png')).resize(w,h,{fit:'fill'}).png().toBuffer(),w,h,'Independent frame variant from new '+src+' artwork');
 }
 const border='<path d="M13 3H207L217 13V57L207 67H13L3 57V13Z" fill="url(#navy)" stroke="#34220d" stroke-width="5"/><path d="M13 3H207L217 13V57L207 67H13L3 57V13Z" fill="none" stroke="url(#gold)" stroke-width="2.5"/>';
 await svg('node_label',220,70,border);
 await svg('selection_ring',220,220,'<circle cx="110" cy="110" r="102" fill="none" stroke="#ffcf57" stroke-width="7" opacity=".4"/><circle cx="110" cy="110" r="101" fill="none" stroke="#fff2b1" stroke-width="2.5"/>');
 const icons={
  lock:'<path d="M22 30V21C22 2 50 2 50 21V30M27 30V21C27 9 45 9 45 21V30" fill="none" stroke="#f5dca6" stroke-width="5"/><rect x="16" y="28" width="40" height="34" rx="5" fill="#f5dca6"/><path d="M36 38V50" stroke="#142e42" stroke-width="5" stroke-linecap="round"/>',
  flag:'<path d="M17 66V8" stroke="url(#gold)" stroke-width="4"/><circle cx="17" cy="7" r="4" fill="#ffe3a0"/><path d="M20 12C35 4 46 21 61 12V39C45 48 35 31 20 39Z" fill="#0871d8" stroke="#f7cf68" stroke-width="2"/>',
  crown:'<path d="M9 49L4 20L23 33L36 9L49 33L68 20L63 49Z" fill="url(#gold)" stroke="#644018" stroke-width="2"/><path d="M10 55H62V62H10Z" fill="url(#gold)"/><circle cx="36" cy="9" r="4" fill="#ffdf7d"/>',
  check:'<circle cx="36" cy="36" r="30" fill="#167d3c" stroke="#f9e9a7" stroke-width="4"/><path d="M19 36L31 48L54 23" fill="none" stroke="#fffef1" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>',
  replay:'<path d="M58 26A25 25 0 1 0 60 43" fill="none" stroke="#f8d47b" stroke-width="7"/><path d="M43 25L62 26L61 7" fill="none" stroke="#f8d47b" stroke-width="7"/>',
  chevron:'<path d="M25 14L48 36L25 58" fill="none" stroke="#f5d17e" stroke-width="7"/>',
  chevron_dark:'<path d="M25 14L48 36L25 58" fill="none" stroke="#35250d" stroke-width="7"/>',
  book:'<path d="M6 14L26 7L46 14L66 7V58L46 65L26 58L6 65Z" fill="url(#gold)" stroke="#805a22" stroke-width="2"/><path d="M26 8V57M46 14V64M15 22V50M36 25V51M56 19V48" stroke="#775b30" stroke-width="3"/>',
  compass:'<g stroke="url(#gold)" stroke-width="1.7" fill="none"><circle cx="36" cy="36" r="23"/><circle cx="36" cy="36" r="16"/><path d="M36 1L43 28L71 36L43 43L36 71L29 43L1 36L29 29Z M12 12L33 28L60 60L40 44Z M60 12L44 33L12 60L28 40Z"/><circle cx="36" cy="36" r="4" fill="#edc96b"/></g>',
 };
 for(const[name,body]of Object.entries(icons))await svg('icon_'+name,72,72,body);
 const paths=['M184 563C270 563 360 520 466 480','M466 480C600 475 676 400 767 315','M767 315C815 250 746 175 663 135'];
 const route=p=>`<path d="${p}" fill="none" stroke="#c18b28" stroke-width="12" stroke-linecap="round" stroke-dasharray="0 21" opacity=".65"/><path d="${p}" fill="none" stroke="#ffe496" stroke-width="8" stroke-linecap="round" stroke-dasharray="0 21"/><path d="${p}" fill="none" stroke="#fff7d4" stroke-width="4" stroke-linecap="round" stroke-dasharray="0 21"/>`;
 for(let i=0;i<3;i++)await svg('route_'+(i+1),941,750,route(paths[i]));
 await svg('route',941,750,paths.map(route).join(''));
 for(const[n,cx,cy]of [[3,800,315],[4,710,135]]){
  let cloud='';for(let y=-170;y<170;y+=12)for(let x=-210;x<210;x+=12){const d=x*x/44000+y*y/28000;const v=(Math.sin(x*7+y*13)+1)/2;const a=Math.max(0,1-d)*(.13+v*.27);if(a>0)cloud+=`<rect x="${cx+x}" y="${cy+y}" width="13" height="13" fill="#dde9e9" opacity="${a.toFixed(3)}"/>`;}
  await svg('fog_'+n,941,750,cloud);
 }
 fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify({version:'v001',assets:entries},null,2));
 const tiles=await Promise.all(entries.map(async(e,i)=>({input:await sharp(path.join(app,e.name+'.png')).resize(220,122,{fit:'contain',background:'#243b51'}).extend({top:25,bottom:3,left:3,right:3,background:'#243b51'}).composite([{input:Buffer.from(`<svg width="220" height="25"><text x="5" y="17" fill="#ffe2a0" font-size="14">${e.name}</text></svg>`),top:0,left:3}]).png().toBuffer(),left:(i%4)*226,top:Math.floor(i/4)*150})));
 await sharp({create:{width:904,height:Math.ceil(entries.length/4)*150,channels:4,background:'#243b51'}}).composite(tiles).png().toFile(path.join(art,'material_catalog.png'));
 console.log(`Packaged ${entries.length} separate assets.`);
})().catch(e=>{console.error(e);process.exitCode=1;});
