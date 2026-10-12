const fs=require('fs');const path=require('path');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..');const art=path.join(root,'art/focus_selection_v001');
const app=path.join(root,'mobile/assets/images/focus_selection_v001/avatars');
(async()=>{
 const refs=JSON.parse(fs.readFileSync(path.join(art,'avatar_generation.json'),'utf8').replace(/^\uFEFF/,''));
 const manifest=[];
 for(const r of refs){
  const src=r.source || r.hint.match(/as (C:\\[^\n]+\.png) by default/)[1];
  const dir=path.join(app,r.sex);const adir=path.join(art,'avatars',r.sex);
  fs.mkdirSync(dir,{recursive:true});fs.mkdirSync(adir,{recursive:true});
  // Publish the requested 64 logical pixel grid at 2x, without interpolating pixels.
  const small=await sharp(src).resize(64,64,{fit:'contain',kernel:'nearest',background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer();
  const png=await sharp(small).resize(128,128,{kernel:'nearest'}).png().toBuffer();
  fs.writeFileSync(path.join(dir,r.role+'.png'),png);fs.writeFileSync(path.join(adir,r.role+'.png'),png);
  manifest.push({role:r.role,appearance:r.sex,file:`avatars/${r.sex}/${r.role}.png`,width:128,height:128,grid:64,source:src,portrait:r.portrait,pixel:r.pixel});
 }
 const images=[];
 for(const r of manifest){
   const roleIndex=['warrior','boxer','samurai','guardian','ninja','assassin','ranger','mage','gunner','spellblade','onmyoji','reaper','angel','devil','dragon_knight','berserker'].indexOf(r.role);
   const i=roleIndex+(r.appearance==='female'?16:0);
   images.push({input:fs.readFileSync(path.join(art,r.file)),left:(i%8)*160+16,top:Math.floor(i/8)*160});
   images.push({input:Buffer.from(`<svg width="155" height="26"><text x="4" y="18" font-size="12" fill="#ffe2a2">${r.appearance} ${r.role}</text></svg>`),left:(i%8)*160,top:Math.floor(i/8)*160+128});
 }
 await sharp({create:{width:1280,height:640,channels:4,background:'#172b41'}}).composite(images).png().toFile(path.join(art,'avatar_catalog.png'));
 fs.writeFileSync(path.join(art,'avatar_manifest.json'),JSON.stringify(manifest,null,2));
 console.log('Packaged '+refs.length+' individual pixel face avatars');
})().catch(e=>{console.error(e);process.exitCode=1});
