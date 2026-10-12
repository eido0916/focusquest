const fs=require('fs');const path=require('path');const assert=require('assert');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..');const art=path.join(root,'art/focus_selection_v001');
(async()=>{
 const manifest=JSON.parse(fs.readFileSync(path.join(art,'avatar_manifest.json')));
 assert.equal(manifest.length,32,'All sixteen male and female avatars must be present');
 assert.equal(new Set(manifest.map(x=>x.appearance+'/'+x.role)).size,32);
 for(const r of manifest){
  const src=path.join(art,r.file);const runtime=path.join(root,'mobile/assets/images/focus_selection_v001',r.file);
  assert(fs.readFileSync(src).equals(fs.readFileSync(runtime)),r.file+' runtime differs');
  const {data,info}=await sharp(src).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  assert.equal(info.width,128);assert.equal(info.height,128);
  let empty=0,solid=0;
  for(let y=0;y<128;y+=2)for(let x=0;x<128;x+=2){
   const i=(y*128+x)*4;
   for(const offset of [4,128*4,128*4+4])for(let c=0;c<4;c++)assert.equal(data[i+c],data[i+offset+c],r.file+' interpolated pixel');
   if(data[i+3]===0)empty++;else solid++;
  }
  assert(empty>0&&solid>256,r.file+' blank or missing transparency');
 }
 const materials=JSON.parse(fs.readFileSync(path.join(art,'manifest.json')));
 for(const r of materials){
  const file=path.join(art,'materials',r.name+'.png');
  assert(fs.existsSync(file));
  assert(fs.readFileSync(file).equals(fs.readFileSync(path.join(root,'mobile/assets/images/focus_selection_v001',r.name+'.png'))));
 }
 console.log(`Verified ${manifest.length} gender/role avatars, 128px RGBA, exact 2x logical grid, and ${materials.length} separate UI materials.`);
})().catch(e=>{console.error(e);process.exitCode=1});
