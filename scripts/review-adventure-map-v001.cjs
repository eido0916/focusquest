const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..'),art=path.join(root,'art/adventure_map_v001');
const stage=process.argv[2]||'C:/Users/eido0/FocusQuestTools/integrated-build';
(async()=>{
 const manifest=JSON.parse(fs.readFileSync(path.join(art,'manifest.json')));
 const results=manifest.assets.map(a=>{
  const hash=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
  return{name:a.name,match:hash(path.join(art,'materials',a.name+'.png'))===a.sha256&&hash(path.join(root,'mobile/assets/images/adventure_map_v001',a.name+'.png'))===a.sha256};
 });
 fs.writeFileSync(path.join(art,'asset-verification.json'),JSON.stringify(results,null,2));
 if(results.some(r=>!r.match))throw Error('Asset mismatch');
 const previews=path.join(art,'previews'),capture=path.join(stage,'build/adventure-map-review');
 fs.mkdirSync(previews,{recursive:true});
 for(const file of fs.readdirSync(capture).filter(f=>f.endsWith('.png')))fs.copyFileSync(path.join(capture,file),path.join(previews,file));
 fs.copyFileSync(path.join(previews,'map-1-470-1.0.png'),path.join(previews,'grassland.png'));
 const tiles=await Promise.all([0,4,8,12,16,20,24,28,32].map(async(n,i)=>({
  input:await sharp(path.join(previews,`map-${n}-390-1.0.png`)).resize(220,476,{fit:'fill'}).png().toBuffer(),
  left:(i%3)*220,top:Math.floor(i/3)*476
 })));
 await sharp({create:{width:660,height:1428,channels:4,background:'#001b30'}}).composite(tiles).png().toFile(path.join(previews,'nine-chapters.png'));
 console.log(`${results.length} asset hashes match; previews saved.`);
})().catch(e=>{console.error(e);process.exitCode=1;});
