const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..'),art=path.join(root,'art/adventure_map_v002'),app=path.join(root,'mobile/assets/images/adventure_map_v002');
(async()=>{
 for(const dir of [art,app,...['materials','vectors','previews'].map(n=>path.join(art,n))])fs.mkdirSync(dir,{recursive:true});
 const entries=[];
 for(const[n,x,y]of [[3,800,315],[4,710,135]]){
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="941" height="750"><defs><radialGradient id="mist"><stop stop-color="#ebf1ed" stop-opacity=".44"/><stop offset=".55" stop-color="#dde7e2" stop-opacity=".28"/><stop offset="1" stop-color="#e4ece8" stop-opacity="0"/></radialGradient></defs><g fill="url(#mist)"><ellipse cx="${x}" cy="${y}" rx="170" ry="139"/><ellipse cx="${x-58}" cy="${y+48}" rx="146" ry="82"/><ellipse cx="${x+72}" cy="${y-38}" rx="138" ry="90"/></g></svg>`;
  fs.writeFileSync(path.join(art,`vectors/fog_${n}.svg`),svg);
  const png=await sharp(Buffer.from(svg)).png().toBuffer();
  for(const dir of [app,path.join(art,'materials')])fs.writeFileSync(path.join(dir,`fog_${n}.png`),png);
  entries.push({name:`fog_${n}`,width:941,height:750,sha256:crypto.createHash('sha256').update(png).digest('hex')});
 }
 fs.writeFileSync(path.join(art,'manifest.json'),JSON.stringify({version:'v002',method:'Editable SVG mist; v001 illustration and frame artwork retained',assets:entries},null,2));
 console.log('Saved smooth independent mist overlays.');
})();
