from pathlib import Path
from PIL import Image,ImageDraw,ImageChops,ImageFilter
import numpy as np, math,json,csv,io,zipfile,xml.etree.ElementTree as ET
BASE=Path(__file__).resolve().parent;OUT=BASE.parent;PARTS=OUT/'parts';PREV=OUT/'preview';RUNTIME=OUT/'runtime'
for p in [PARTS,PREV,RUNTIME]:p.mkdir(exist_ok=True)
atlas=Image.open(BASE/'parts_atlas.png').convert('RGBA');alpha=atlas.getchannel('A');binary=alpha.point(lambda v:255 if v>32 else 0)
names=['head','torso','pelvis','upper_arm_L','forearm_L','hand_L','upper_arm_R','forearm_R','hand_R','thigh_L','shin_L','foot_L','thigh_R','shin_R','foot_R','sword','cape_upper','cape_lower','skirt_back','skirt_front']
centers=[(140,140),(460,160),(740,170),(1015,160),(1260,165),(145,455),(430,430),(745,440),(1040,445),(1260,450),(145,700),(425,770),(710,700),(1000,690),(1260,770),(180,950),(445,940),(725,970),(1015,970),(1280,970)]
# Extract connected artwork, preserving its generated antialias alpha; no white-color deletion.
images={};bbs=[]
arr=np.array(binary)
for name,(cx,cy) in zip(names,centers):
 yy,xx=np.where(arr[max(0,cy-80):cy+81,max(0,cx-80):cx+81]>0);xx=xx+max(0,cx-80);yy=yy+max(0,cy-80);idx=np.argmin((xx-cx)**2+(yy-cy)**2);seed=(int(xx[idx]),int(yy[idx]))
 temp=binary.copy();ImageDraw.floodfill(temp,seed,128,thresh=0);mask=temp.point(lambda v:255 if v==128 else 0).filter(ImageFilter.MaxFilter(3));a=ImageChops.multiply(alpha,mask);bb=a.getbbox();im=atlas.copy();im.putalpha(a);im=im.crop(bb);images[name]=im;im.save(PARTS/f'{name}.png');bbs.append(bb)
# x,y,width,height, pivot x/y in 256 canvas, parent,z. All limb ends overlap under clothing.
layout=[(112,32,40,43,130,71,'torso',90),(108,66,43,53,130,78,'pelvis',65),(108,109,44,36,130,128,'root',45),(105,78,20,34,117,81,'torso',15),(101,103,20,36,112,107,'upper_arm_L',16),(104,132,14,21,111,134,'forearm_L',17),(138,77,21,34,146,80,'torso',70),(145,101,20,38,152,106,'upper_arm_R',71),(151,130,19,20,158,133,'forearm_R',100),(111,133,21,42,121,136,'pelvis',10),(111,168,20,46,121,172,'thigh_L',11),(111,207,29,17,121,211,'shin_L',12),(131,133,21,42,141,136,'pelvis',30),(131,168,20,46,141,172,'thigh_R',31),(131,207,29,17,141,211,'shin_R',32),(153,99,52,57,163,145,'hand_R',95),(99,65,63,39,130,75,'torso',80),(104,84,56,112,113,86,'torso',0),(106,130,25,29,119,132,'pelvis',40),(124,129,24,30,135,132,'pelvis',55)]
records=[]
for name,bb,lay in zip(names,bbs,layout):
 x,y,w,h,px,py,parent,z=lay;im=images[name];records.append(dict(id=name,file=f'../parts/{name}.png',position_256=[x,y],size_256=[w,h],pivot_world_256=[px,py],pivot_local_px=[(px-x)/w*im.width,(py-y)/h*im.height],native_size=list(im.size),atlas_bbox=list(bb),parent=parent,draw_order=z))
BY={r['id']:r for r in records}
def T(x,y):return np.array([[1,0,x],[0,1,y],[0,0,1]],float)
def R(deg):
 a=math.radians(deg);return np.array([[math.cos(a),-math.sin(a),0],[math.sin(a),math.cos(a),0],[0,0,1]])
def pose(kind,t):
 phase=2*math.pi*t;ang={};root=T(0,0)
 if kind=='idle':
  phase=math.pi*t;root=T(0,-.65*(1-math.cos(phase)));ang={'torso':.65*math.sin(phase),'head':-.3*math.sin(phase),'upper_arm_R':.8*math.sin(phase),'forearm_R':-.4*math.sin(phase),'cape_lower':18+2.5*math.sin(phase-.5),'cape_upper':.5*math.sin(phase-.3),'skirt_front':1.2*math.sin(phase-.2)}
 elif kind=='run':
  root=T(0,-2-1.6*math.cos(2*phase));ang={'torso':7,'head':-4,'cape_upper':-4+2*math.sin(phase-.4),'cape_lower':25+4*math.sin(phase-.8),'skirt_back':5*math.sin(phase-.5),'skirt_front':5*math.sin(phase+.4),'upper_arm_R':-8+7*math.cos(phase),'forearm_R':-20+5*math.sin(phase),'upper_arm_L':10*math.cos(phase+math.pi),'forearm_L':-8+5*math.sin(phase),'hand_R':0}
  for side,offset in [('R',0),('L',math.pi)]:
   q=phase+offset;thigh=-31*math.cos(q);knee=12+39*(.5+.5*math.sin(q));ang[f'thigh_{side}']=thigh;ang[f'shin_{side}']=knee;ang[f'foot_{side}']=-thigh-knee*.72
 else:ang={'cape_lower':18}
 return root,ang
def render(kind,t,size=1024):
 root,ang=pose(kind,t);D={'root':root};canvas=Image.new('RGBA',(size,size));scale=size/256
 def delta(name):
  if name in D:return D[name]
  r=BY[name];px,py=r['pivot_world_256'];D[name]=delta(r['parent'])@T(px,py)@R(ang.get(name,0))@T(-px,-py);return D[name]
 for r in sorted(records,key=lambda r:r['draw_order']):
  x,y=r['position_256'];w,h=r['size_256'];im=images[r['id']]
  bind=T(x,y)@np.diag([w/im.width,h/im.height,1]);matrix=np.diag([scale,scale,1])@delta(r['id'])@bind;inv=np.linalg.inv(matrix)
  layer=im.transform((size,size),Image.Transform.AFFINE,tuple(inv[:2,:].ravel()),Image.Resampling.BICUBIC);canvas.alpha_composite(layer)
 return canvas
meta=dict(schema_version=1,asset_id='character_01',spec_version='0.1',fps=24,canvas=[1024,1024],runtime_canvas=[256,256],root_pivot_256=[128,224],facing='right_3quarter',root_motion='none',alpha_mode='straight',downsample_method='Pillow LANCZOS',status='animation_prototype',parts=records,clips={'idle':{'duration_seconds':2,'frame_count':48,'loop':True},'run':{'duration_seconds':1,'frame_count':24,'loop':True}})
(BASE/'rig.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
with (BASE/'part_placement.csv').open('w',encoding='utf-8-sig',newline='') as f:
 w=csv.writer(f);w.writerow(['id','x256','y256','width256','height256','pivot_world_x256','pivot_world_y256','pivot_local_x','pivot_local_y','parent','draw_order'])
 for r in records:w.writerow([r['id'],*r['position_256'],*r['size_256'],*r['pivot_world_256'],*r['pivot_local_px'],r['parent'],r['draw_order']])
a0=render('A0',0);a0.save(PREV/'character_01_sword_A0_1024.png');a0.resize((512,512),Image.Resampling.LANCZOS).save(PREV/'hero_sword_male_home.png');a0.resize((256,256),Image.Resampling.LANCZOS).save(PREV/'hero_sword_male_battle_poster.png')
# Editable embedded-image SVG. Layout and rotation origins live in rig.json.
import base64
s=['<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="1024" viewBox="0 0 256 256">']
for r in sorted(records,key=lambda r:r['draw_order']):
 x,y=r['position_256'];w,h=r['size_256'];data=base64.b64encode((PARTS/f'{r["id"]}.png').read_bytes()).decode();s.append(f'<g id="{r["id"]}"><image x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="none" xlink:href="data:image/png;base64,{data}"/></g>')
s.append('</svg>');(BASE/'character_01_layers.svg').write_text('\n'.join(s),encoding='utf-8')
checksheet=Image.new('RGB',(1600,430),'#d8e1eb');draw=ImageDraw.Draw(checksheet)
for k,(kind,t) in enumerate([('A0',0),('run',0),('run',.25),('run',.5)]):
 im=render(kind,t,400);checksheet.paste(im,(k*400,24),im);draw.text((k*400+12,8),f'{kind} / t={t:.2f}',fill='#1f3447')
checksheet.save(PREV/'pose_check.jpg')
qa={}
for kind,count in [('idle',48),('run',24)]:
 frames=[];master=RUNTIME/kind;master.mkdir(exist_ok=True);high=OUT/'production_frames'/kind;high.mkdir(parents=True,exist_ok=True);bounds=[]
 for f in range(count):
  big=render(kind,f/24);big.save(high/f'character_01_{kind}_{f:04}.png');small=big.resize((256,256),Image.Resampling.LANCZOS);small.save(master/f'character_01_{kind}_{f:04}.png');frames.append(small)
  bounds.append(big.getchannel('A').getbbox())
 # Millisecond timebase previews: exact 1000ms/24 samples; source PNG timing is exact f/24.
 ms=[round((f+1)*1000/24)-round(f*1000/24) for f in range(count)]
 frames[0].save(PREV/f'character_01_{kind}.webp',save_all=True,append_images=frames[1:],duration=ms,loop=0,lossless=True)
 frames[0].save(PREV/f'character_01_{kind}.png',save_all=True,append_images=frames[1:],duration=ms,loop=0,disposal=0,blend=0)
 # GIF only supports10ms durations. Distribute40/50ms to preserve cycle duration.
 previews=[]
 for fr in frames:
  bg=Image.new('RGBA',(512,512),'#d8e1eb');bg.alpha_composite(fr.resize((512,512),Image.Resampling.LANCZOS));previews.append(bg.convert('RGB'))
 gd=[(round((f+1)*100/24)-round(f*100/24))*10 for f in range(count)]
 previews[0].save(PREV/f'character_01_{kind}.gif',save_all=True,append_images=previews[1:],duration=gd,loop=0,disposal=2)
 union=[min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds)]
 qa[kind]=dict(frames=count,duration_seconds=count/24,union_bounds_1024=union,safe_bounds_pass=bool(union[0]>=64 and union[1]>=64 and union[2]<=960 and union[3]<=960),loop_transform_match=bool(np.allclose(pose(kind,0)[0],pose(kind,count/24)[0]) and all(abs(v-pose(kind,count/24)[1].get(k,0))<1e-6 for k,v in pose(kind,0)[1].items())))
 print(kind,qa[kind],flush=True)
(BASE/'qa.json').write_text(json.dumps(qa,indent=2),encoding='utf-8')
(RUNTIME/'animations.json').write_text(json.dumps({**{k:v for k,v in meta.items() if k!='parts'},'animations':[{**spec,'id':kind,'files':[f'{kind}/character_01_{kind}_{f:04}.png' for f in range(spec['frame_count'])]} for kind,spec in meta['clips'].items()]},indent=2),encoding='utf-8')
print('Complete:20 PNG parts,24fps PNG frames,APNG/WebP/GIF previews',flush=True)
