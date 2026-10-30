const sharp=require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const path=require('path');
(async()=>{
for(const name of ['timer_compass','timer_frame','ornament_top','gauge_track']){
 const {data,info}=await sharp(path.join(__dirname,'../mobile/assets/images/home_focus_ui_v002',name+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let dark=0,opaque=0;const rows=[];
 for(let y=0;y<info.height;y++){let count=0;for(let x=0;x<info.width;x++){const i=(y*info.width+x)*4;if(data[i+3]>127){opaque++;if(Math.max(data[i],data[i+1],data[i+2])<35){dark++;count++;}}}if(count>info.width*.7)rows.push(y);}
 console.log(JSON.stringify({name,width:info.width,height:info.height,dark,opaque,darkRows:rows}));
}
})().catch(console.error);
