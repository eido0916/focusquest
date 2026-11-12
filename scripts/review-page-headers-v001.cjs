const fs=require('fs'),path=require('path');
const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..'),stage='C:/Users/eido0/FocusQuestTools/integrated-build',art=path.join(root,'art/page_headers_v001');
(async()=>{
 fs.mkdirSync(path.join(art,'previews'),{recursive:true});
 for(const[name,id]of [['character-before','919418a2-3cd5-4038-b446-342e299a5254'],['settings-before','26b6059d-c107-44d1-9617-0f187babacea'],['adventure-reference','ef18b7db-fb5f-4848-ac10-4ce40db14d13']])fs.copyFileSync(`C:/Users/eido0/AppData/Local/Temp/codex-clipboard-${id}.png`,path.join(art,name+'.png'));
 const sources=[['character',path.join(stage,'build/unified-headers/character-375x662.png'),{left:69,top:12,width:612,height:132}],['settings',path.join(stage,'build/unified-ui/settings-470.png'),{left:123,top:41,width:705,height:138}]];
 const tiles=[];
 for(let i=0;i<sources.length;i++){
  const[name,source,rect]=sources[i];
  fs.copyFileSync(source,path.join(art,'previews',name+'-screen.png'));
  const after=await sharp(source).extract(rect).png().toBuffer();fs.writeFileSync(path.join(art,'previews',name+'-header.png'),after);
  for(const[col,input]of [[0,path.join(art,name+'-before.png')],[1,after]])tiles.push({input:await sharp(input).resize(780,170,{fit:'contain',background:'#12304a'}).png().toBuffer(),left:col*800+10,top:i*200+30});
 }
 const labels=Buffer.from('<svg width="1600" height="430"><g fill="#ffe7ac" font-size="18"><text x="20" y="23">Before</text><text x="820" y="23">After: shared adventure title plate</text></g></svg>');
 await sharp({create:{width:1600,height:430,channels:4,background:'#12304a'}}).composite([...tiles,{input:labels,left:0,top:0}]).png().toFile(path.join(art,'previews/comparison.png'));
 for(const f of ['unified-headers-tests.log','unified-headers-analyze.log','unified-headers-release.log'])if(fs.existsSync(path.join(stage,'build',f)))fs.copyFileSync(path.join(stage,'build',f),path.join(art,f));
 console.log('Saved rendered title previews and comparison.');
})();
