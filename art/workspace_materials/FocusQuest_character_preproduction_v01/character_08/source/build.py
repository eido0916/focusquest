from pathlib import Path
from PIL import Image, ImageDraw
import json, csv, base64, zipfile, io, xml.etree.ElementTree as ET
BASE=Path(__file__).resolve().parent
C=BASE.parent
P=C/'parts';P.mkdir(exist_ok=True)
V=C/'preview';V.mkdir(exist_ok=True)
atlas=Image.open(BASE/'parts_atlas_corrected.png').convert('RGBA')
rects=[(30,70,240,330),(270,35,510,330),(515,60,750,255),(750,45,1005,340),(1008,65,1254,335),(35,340,220,600),(300,360,455,585),(575,360,715,595),(815,345,1000,610),(1060,345,1215,610),(65,640,240,855),(300,610,485,895),(540,605,685,890),(770,645,1000,880),(1020,610,1210,895),(45,895,200,1210),(285,940,505,1175),(500,885,750,1205),(745,920,1000,1200),(1015,915,1240,1200)]
names=['head_face','hair_back','hair_front','torso','pelvis','upper_arm_left','forearm_left','hand_left','upper_arm_right','forearm_right','hand_right','thigh_left','shin_left','foot_left','thigh_right','shin_right','foot_right','sword','jacket_tail','shirt_tail']
# x,y,width,height,z, local pivot fraction x/y, parent; anatomical right is foreground.
layout=[(121,37,30,40,60,.4,.86,'torso'),(113,32,36,43,59,.6,.86,'head_face'),(116,32,33,25,80,.6,.86,'head_face'),(110,62,45,57,70,.5,.25,'pelvis'),(110,109,45,34,45,.5,.4,'root'),(101,75,19,30,20,.82,.09,'torso'),(102,97,17,32,21,.36,.08,'upper_arm_left'),(109,123,13,22,22,.3,.08,'forearm_left'),(144,76,19,30,50,.22,.08,'torso'),(155,98,17,36,51,.35,.08,'upper_arm_right'),(166,127,16,21,90,.28,.08,'forearm_right'),(113,130,20,46,10,.46,.06,'pelvis'),(114,167,16,49,11,.5,.04,'thigh_left'),(113,209,28,15,12,.23,.15,'shin_left'),(134,130,20,46,30,.5,.06,'pelvis'),(135,167,16,49,31,.5,.04,'thigh_right'),(134,209,28,15,32,.23,.15,'shin_right'),(166.5,94,58,61,85,.19,.80,'hand_right'),(108,113,28,33,35,.5,.03,'pelvis'),(126,113,25,34,46,.5,.03,'pelvis')]
records=[];layers={}
for i,(name,rect,lay) in enumerate(zip(names,rects,layout)):
 im=atlas.crop(rect);bb=im.getchannel('A').getbbox();im=im.crop(bb);im.save(P/f'{i+1:02}_{name}.png')
 x,y,w,h,z,px,py,parent=lay
 pivot=[round(px*im.width,3),round(py*im.height,3)]
 # The sword pivot is the actual center of the fist grip hole in canvas coords.
 world=[x+px*w,y+py*h]
 if name=='sword':world=[178.8,142.4];pivot=[(world[0]-x)/w*im.width,(world[1]-y)/h*im.height]
 r=dict(id=name,file=f'../parts/{i+1:02}_{name}.png',native_size=list(im.size),position_256=[x,y],size_256=[w,h],rotation_deg=0,pivot_local_px=pivot,pivot_world_256=world,draw_order=z,parent=parent)
 records.append(r)
 layer=Image.new('RGBA',(1024,1024));layer.alpha_composite(im.resize((round(w*4),round(h*4)),Image.Resampling.LANCZOS),(round(x*4),round(y*4)));layers[name]=layer
def compose(selected=None):
 result=Image.new('RGBA',(1024,1024))
 for r in sorted(records,key=lambda r:r['draw_order']):result.alpha_composite((selected or layers)[r['id']])
 return result
full=compose();full.save(V/'character_08_A0_1024.png')
for size,file in [(256,'hero_sword_male_battle_poster.png'),(512,'hero_sword_male_home.png')]:full.resize((size,size),Image.Resampling.LANCZOS).save(V/file)
meta=dict(schema_version=1,spec_version='0.1',asset_id='character_08',approval_status='prototype_only',canvas=[1024,1024],runtime_canvas=[256,256],root_pivot_256=[128,224],safe_bounds_256=[16,16,240,240],facing='right_3quarter',reference_body_height_px=192,fps=24,root_motion='none',alpha_mode='straight',color_space='sRGB_assumed_no_ICC_conversion',downsample_method='Pillow LANCZOS',transform_convention='A0 absolute layout; local joint rotation about pivot_world_256; parent transforms apply to child, sword grip stays attached to hand',parts=records)
(BASE/'rig.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
with (BASE/'part_placement.csv').open('w',encoding='utf-8-sig',newline='') as f:
 writer=csv.writer(f);writer.writerow(['id','file','x256','y256','width256','height256','pivot_local_x','pivot_local_y','pivot_world_x256','pivot_world_y256','draw_order','parent'])
 for r in records:writer.writerow([r['id'],r['file'],*r['position_256'],*r['size_256'],*r['pivot_local_px'],*r['pivot_world_256'],r['draw_order'],r['parent']])
svg=['<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="1024" viewBox="0 0 1024 1024">']
for r in sorted(records,key=lambda r:r['draw_order']):
 data=base64.b64encode((BASE/r['file']).read_bytes()).decode();x,y=r['position_256'];w,h=r['size_256'];svg.append(f'<g id="{r["id"]}"><image x="{x*4}" y="{y*4}" width="{w*4}" height="{h*4}" preserveAspectRatio="none" xlink:href="data:image/png;base64,{data}"/></g>')
svg.append('</svg>');(BASE/'character_08_layers.svg').write_text('\n'.join(svg),encoding='utf-8')
imagexml=ET.Element('image',w='1024',h='1024',name='character_08_A0');stack=ET.SubElement(imagexml,'stack')
with zipfile.ZipFile(BASE/'character_08_layers.ora','w') as zf:
 zf.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
 for idx,r in enumerate(sorted(records,key=lambda r:r['draw_order'],reverse=True)):
  b=io.BytesIO();layers[r['id']].save(b,format='PNG');path=f'data/layer{idx:02}.png';zf.writestr(path,b.getvalue());ET.SubElement(stack,'layer',name=r['id'],src=path,x='0',y='0',opacity='1.0',visibility='visible',**{'composite-op':'svg:src-over'})
 zf.writestr('stack.xml',ET.tostring(imagexml));b=io.BytesIO();full.save(b,format='PNG');zf.writestr('mergedimage.png',b.getvalue())
# Static joint stress poses only, not animation frames. Rotate descendants together.
byid={r['id']:r for r in records}
def descendants(name):return [r['id'] for r in records if r['parent']==name]
def rotate_group(name,deg,selected):
 center=tuple(v*4 for v in byid[name]['pivot_world_256'])
 def apply(n):
  selected[n]=selected[n].rotate(-deg,Image.Resampling.BICUBIC,center=center)
  for child in descendants(n):apply(child)
 apply(name)
poses=[]
for label,joints in [('A0',[]),('ELBOW -45',[('forearm_right',-45)]),('KNEE +60',[('shin_right',60)]),('HAIR +10',[('hair_front',10)])]:
 selected=layers.copy()
 for joint,angle in joints:rotate_group(joint,angle,selected)
 pose=compose(selected);pose.save(V/(label.split()[0].lower()+'_joint_check.png'));poses.append((label,pose))
sheet=Image.new('RGB',(1600,460),'#dbe2ec');draw=ImageDraw.Draw(sheet)
for k,(label,pose) in enumerate(poses):
 pose=pose.resize((400,400),Image.Resampling.LANCZOS);sheet.paste(pose,(k*400,30),pose);draw.text((k*400+16,12),label,fill='black');draw.line((k*400,380,k*400+400,380),fill='#7595aa')
sheet.save(V/'joint_stress_sheet.jpg')
sheet=Image.new('RGB',(1250,1040),'#e7ebf0');draw=ImageDraw.Draw(sheet)
for i,r in enumerate(records):
 im=Image.open(BASE/r['file']);im.thumbnail((220,220));x=i%5*250;y=i//5*260;sheet.paste(im,(x+(250-im.width)//2,y+28),im);draw.text((x+8,y+8),f'{i+1:02} {r["id"]}',fill='black')
sheet.save(V/'parts_breakdown.jpg')
small=Image.new('RGB',(820,280),'#dbe2ec');draw=ImageDraw.Draw(small)
for k,size in enumerate([72,150,256]):
 im=full.resize((size,size),Image.Resampling.LANCZOS);small.paste(im,(40+k*260,12),im);draw.text((40+k*260,268),f'{size} px',fill='black')
small.save(V/'display_sizes.jpg')
recomp=compose();bbox=full.getchannel('A').getbbox()
qa=dict(parts_count=len(records),all_parts_rgba=all(Image.open(BASE/r['file']).mode=='RGBA' for r in records),recomposition_exact=(recomp.tobytes()==Image.open(V/'character_08_A0_1024.png').tobytes()),visible_bounds_1024=bbox,safe_bounds_pass=bool(bbox[0]>=64 and bbox[1]>=64 and bbox[2]<=960 and bbox[3]<=960),bottom_visible_256=bbox[3]/4,static_pose_checks_only=True,animation_range_pass=False,identity_approved=False,android_verified=False)
(BASE/'qa.json').write_text(json.dumps(qa,indent=2),encoding='utf-8')
print(json.dumps(qa))
