const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..'),art=path.join(root,'art/adventure_map_v003'),app=path.join(root,'mobile/assets/images/adventure_map_v003');
const cache='C:/Users/eido0/.codex/generated_images/01a185e3-7b7e-76f3-85b4-0b43316837ce';
(async()=>{
 for(const d of [art,app,...['originals','materials','vectors','previews'].map(n=>path.join(art,n))])fs.mkdirSync(d,{recursive:true});
 const entries=[];
 async function save(name,data){for(const d of [app,path.join(art,'materials')])fs.writeFileSync(path.join(d,name+'.png'),data);const m=await sharp(data).metadata();entries.push({name,width:m.width,height:m.height,sha256:crypto.createHash('sha256').update(data).digest('hex')});}
 const sources={landscape:'exec-4d2ddbd9-9b9d-4560-9bc3-32eb3bbed937.png',ghost_ship:'exec-ce6138a9-84a7-45ec-b724-e78fbe8803d6.png',node_boss:'exec-6cb31257-cf53-45b2-856a-b063d29f338c.png'};
 for(const[name,file]of Object.entries(sources)){const original=path.join(art,'originals',name+'.png');if(fs.existsSync(path.join(cache,file)))fs.copyFileSync(path.join(cache,file),original);let img=sharp(original);if(name==='node_boss')img=img.trim();await save(name,await img.resize(name==='landscape'?941:name==='node_boss'?220:880,name==='landscape'?1550:name==='node_boss'?220:180,{fit:'fill',kernel:name==='node_boss'?'lanczos3':'nearest'}).png().toBuffer());}
 // A landscape vignette from the SAME artwork rather than the side-view battle tile.
 await save('meadow_thumbnail',await sharp(path.join(app,'landscape.png')).extract({left:0,top:260,width:540,height:340}).resize(540,340,{kernel:'nearest'}).png().toBuffer());
 const defs='<defs><radialGradient id="mist"><stop stop-color="#eaf0ec" stop-opacity=".77"/><stop offset=".55" stop-color="#e6eee9" stop-opacity=".53"/><stop offset="1" stop-color="#e4ece8" stop-opacity="0"/></radialGradient><radialGradient id="glow"><stop stop-color="#fffce4"/><stop offset=".4" stop-color="#ffdf64" stop-opacity=".75"/><stop offset="1" stop-color="#ffc83e" stop-opacity="0"/></radialGradient><linearGradient id="gold" x2=".3" y2="1"><stop stop-color="#fff3b0"/><stop offset=".4" stop-color="#e7ac2e"/><stop offset=".6" stop-color="#906013"/><stop offset="1" stop-color="#ffe697"/></linearGradient></defs>';
 async function svg(name,w,h,body){const src=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">${defs}${body}</svg>`;fs.writeFileSync(path.join(art,'vectors',name+'.svg'),src);await save(name,await sharp(Buffer.from(src)).png().toBuffer());}
 const anchors=[[184,563],[466,480],[767,315],[663,135]];
 const paths=['M184 563C285 586 344 507 466 480','M466 480C618 487 654 377 767 315','M767 315C782 243 763 185 663 135'];
 await svg('route',941,750,paths.map(p=>`<path d="${p}" fill="none" stroke="#f7b52a" stroke-width="13" stroke-dasharray="0 19" stroke-linecap="round" opacity=".58"/><path d="${p}" fill="none" stroke="#ffe794" stroke-width="9" stroke-dasharray="0 19" stroke-linecap="round"/><path d="${p}" fill="none" stroke="#fffce8" stroke-width="6" stroke-dasharray="0 19" stroke-linecap="round"/>`).join(''));
 for(const[n,cx,cy]of [[3,795,300],[4,690,135]]){
  let body='';for(let i=0;i<17;i++){const angle=i*2.4;const x=cx+Math.cos(angle)*((i%4)*36),y=cy+Math.sin(angle)*((i%5)*22);body+=`<ellipse cx="${x}" cy="${y}" rx="${100+(i%3)*25}" ry="${51+(i%4)*13}" fill="url(#mist)"/>`;}
  await svg('fog_'+n,941,750,body);
 }
 await svg('frontier_glow',220,220,'<circle cx="110" cy="110" r="110" fill="url(#glow)"/>');
 await svg('icon_compass',72,72,'<g fill="none" stroke="url(#gold)" stroke-width="1.8"><path d="M36 1L42 29L67 36L42 43L36 71L30 43L5 36L30 29Z"/><circle cx="36" cy="36" r="13"/><path d="M36 6V24M36 48V66M10 36H24M48 36H62"/><circle cx="36" cy="36" r="3" fill="#f5d787"/></g>');
 await svg('icon_flag',72,90,'<path d="M18 84V10" stroke="#503712" stroke-width="7"/><path d="M18 84V10" stroke="url(#gold)" stroke-width="3"/><path d="M18 2L24 9L18 16L12 9Z" fill="url(#gold)" stroke="#563b13"/><path d="M22 20C39 11 44 29 67 21L58 34L66 45C44 54 39 36 22 45Z" fill="#0063d6" stroke="#ffe49a" stroke-width="2"/><path d="M27 22V43" stroke="#9ad9ff" stroke-width="2"/>');
 await svg('icon_crown',90,72,'<g fill="url(#gold)" stroke="#6b4310" stroke-width="1.5"><path d="M12 49L8 18L27 36L33 14L45 32L57 14L63 36L82 18L78 49Z"/><path d="M12 50Q45 41 78 50L75 60Q45 53 15 60Z"/><circle cx="8" cy="17" r="4"/><circle cx="33" cy="12" r="4"/><circle cx="57" cy="12" r="4"/><circle cx="82" cy="17" r="4"/><path d="M45 7L50 13L45 20L40 13Z"/></g><circle cx="45" cy="49" r="3" fill="#0870cf"/>');
 fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify({version:'v003',backgroundInstances:1,routeAnchors:anchors,assets:entries},null,2));
 for(const[name,id]of [['reference-before','a05eb5cf-1e00-420f-b779-48d643ed1ace'],['reference-design','119263c6-7a3f-40a2-ad0a-371adfee1327']])fs.copyFileSync(`C:/Users/eido0/AppData/Local/Temp/codex-clipboard-${id}.png`,path.join(art,name+'.png'));
 console.log(`Saved ${entries.length} individual assets, originals, editable vectors and hashes.`);
})().catch(e=>{console.error(e);process.exitCode=1});
