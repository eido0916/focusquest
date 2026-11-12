const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..'),art=path.join(root,'art/adventure_map_v002');
const stage=process.argv[2]||'C:/Users/eido0/FocusQuestTools/integrated-build';
(async()=>{
 const capture=path.join(stage,'build/adventure-map-review'),previews=path.join(art,'previews');
 fs.mkdirSync(previews,{recursive:true});
 for(const file of fs.readdirSync(capture).filter(f=>f.endsWith('.png')))fs.copyFileSync(path.join(capture,file),path.join(previews,file));
 for(const[from,to]of [['map-0-760-1.0.png','corrected-large.png'],['map-1-470-1.0.png','corrected-phone.png'],['map-1-760-1.0.png','corrected-large-unblocked.png']])fs.copyFileSync(path.join(previews,from),path.join(previews,to));
 const manifest=JSON.parse(fs.readFileSync(path.join(art,'manifest.json')));
 const hash=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
 const checks=manifest.assets.map(a=>({name:a.name,match:hash(path.join(art,'materials',a.name+'.png'))===a.sha256&&hash(path.join(root,'mobile/assets/images/adventure_map_v002',a.name+'.png'))===a.sha256}));
 fs.writeFileSync(path.join(art,'asset-verification.json'),JSON.stringify(checks,null,2));
 if(checks.some(c=>!c.match))throw Error('Mist asset mismatch');
 const before=await sharp(path.join(art,'reference-before.png')).resize(760,1360,{fit:'fill'}).png().toBuffer();
 const after=path.join(previews,'corrected-large.png');
 await sharp({create:{width:1520,height:1360,channels:4,background:'#001b30'}}).composite([{input:before,left:0,top:0},{input:after,left:760,top:0}]).png().toFile(path.join(previews,'before-after.png'));
 console.log('Saved corrected previews, comparison and asset verification.');
})();
