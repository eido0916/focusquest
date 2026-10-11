from pathlib import Path
from PIL import Image,ImageDraw,ImageChops,ImageFilter
import math,json,sys,base64,csv
import numpy as np
BASE=Path(__file__).resolve().parent;OUT=BASE.parent
NAMES=['head','torso','pelvis','upper_arm_L','forearm_L','hand_L','upper_arm_R','forearm_R','hand_R','thigh_L','shin_L','foot_L','thigh_R','shin_R','foot_R','sword','cape_upper','cape_lower','skirt_back','skirt_front']
def extract_pixel():
 atlas=Image.open(BASE/'pixel_parts_atlas.png').convert('RGBA');a=atlas.getchannel('A');b=a.point(lambda v:255 if v>64 else 0);arr=np.array(b);W,H=atlas.size
 for i,name in enumerate(NAMES):
  cx=int((i%5+.5)*W/5);cy=int((i//5+.5)*H/4);yy,xx=np.where(arr[max(0,cy-100):cy+101,max(0,cx-100):cx+101]>0);xx+=max(0,cx-100);yy+=max(0,cy-100);j=np.argmin((xx-cx)**2+(yy-cy)**2);seed=(int(xx[j]),int(yy[j]));tmp=b.copy();ImageDraw.floodfill(tmp,seed,128,thresh=0);mask=tmp.point(lambda v:255 if v==128 else 0).filter(ImageFilter.MaxFilter(3));alpha=ImageChops.multiply(a,mask);im=atlas.copy();im.putalpha(alpha);im=im.crop(alpha.getbbox());im.save(OUT/'pixel/parts'/f'{name}.png')
def vec(angle,length):
 a=math.radians(angle);return np.array([math.sin(a)*length,math.cos(a)*length])
def ik(hip,ankle,L1=41.5,L2=40.5):
 d=ankle-hip;dist=float(np.linalg.norm(d));assert abs(L1-L2)<dist<L1+L2,('unreachable ankle',hip,ankle,dist)
 u=d/dist;along=(L1*L1-L2*L2+dist*dist)/(2*dist);off=math.sqrt(max(0,L1*L1-along*along));return hip+along*u+off*np.array([u[1],-u[0]])
def hermite(u,knots):
 for i in range(len(knots)-1):
  t0,p0,v0=knots[i];t1,p1,v1=knots[i+1]
  if u<=t1:
   q=(u-t0)/(t1-t0);dt=t1-t0
   return (2*q**3-3*q*q+1)*np.array(p0)+(q**3-2*q*q+q)*dt*np.array(v0)+(-2*q**3+3*q*q)*np.array(p1)+(q**3-q*q)*dt*np.array(v1)
 return np.array(knots[-1][1])

def foot_path(u):
 u=u%1;stance=.32;speed=55/stance
 if u<stance:return np.array([154-speed*u,212.]),0.,True
 # Contact > down > passing > push-off > flight. Heel folds behind the
 # pelvis before the swing knee advances, instead of a symmetric ellipse.
 knots=[(.32,(99,212),(-speed,0)),(.48,(97,168),(60,-210)),
        (.62,(121,154),(245,20)),(.79,(153,177),(110,210)),
        (1.,(154,212),(-speed,0))]
 ankle=hermite(u,knots)
 angle=float(hermite(u,[(.32,(0,),(0,)),(.49,(36,),(0,)),
                       (.76,(12,),(-75,)),(1.,(0,),(0,))])[0])
 return ankle,angle,False

def skeleton(t):
 u=t%1;step=u%.5
 # Down follows contact; high pelvis occurs during the flight, twice/cycle.
 hipY=float(hermite(step,[(0.,(139.,),(35.,)),(.10,(144.,),(0.,)),
                         (.28,(139.,),(-36.,)),(.43,(135.,),(0.,)),
                         (.5,(139.,),(35.,))])[0])
 twist=1.4*math.cos(2*math.pi*(u+.08))
 p={'pelvis':np.array([128.,hipY-6]),'waist':np.array([129.,hipY-13]),
    'neck':np.array([147.,hipY-66]),
    'shoulder_R':np.array([146.+twist,hipY-54]),
    'shoulder_L':np.array([136.-twist,hipY-55])}
 contact={};footangles={}
 for side,shift,hx in [('R',0,130.),('L',.5,124.)]:
  ankle,fa,c=foot_path(u+shift);hip=np.array([hx,hipY]);knee=ik(hip,ankle)
  p['hip_'+side]=hip;p['knee_'+side]=knee;p['ankle_'+side]=ankle
  footangles[side]=fa;contact[side]=c
 # Arms cross slightly before legs. The loaded sword arm has a smaller arc.
 arm=math.cos(2*math.pi*(u+.08))
 for side,a,flex in [('R',-24+31*arm,95),('L',-20-50*arm,90)]:
  shoulder=p['shoulder_'+side];elbow=shoulder+vec(a,27)
  wrist=elbow+vec(a+flex,25)
  p['elbow_'+side]=elbow;p['wrist_'+side]=wrist
  p['palm_'+side]=wrist+vec(a+flex,10.)
 p['grip']=p['palm_R']
 # Stable wrist grip; blade follows a restrained rotation, not an independent bob.
 p['sword_tip']=p['grip']+R(-5+4*arm)[:2,:2]@np.array([31.,-42.])
 return p,footangles,contact

def T(x,y):return np.array([[1,0,x],[0,1,y],[0,0,1]],float)
def R(deg):
 a=math.radians(deg);return np.array([[math.cos(a),-math.sin(a),0],[math.sin(a),math.cos(a),0],[0,0,1]])
def attach(im,anchor,dest,width,height,angle=0):
 return T(*dest)@R(angle)@np.diag([width/im.width,height/im.height,1])@T(-anchor[0]*im.width,-anchor[1]*im.height)
SPAN_CACHE={}
def bone(im,src0,src1,dst0,dst1,width):
 a=np.array(src0)*np.array(im.size);b=np.array(src1)*np.array(im.size);s=b-a;d=dst1-dst0;us=s/np.linalg.norm(s);ud=d/np.linalg.norm(d);vs=np.array([-us[1],us[0]]);vd=np.array([-ud[1],ud[0]])
 key=(id(im),tuple(src0),tuple(src1))
 if key not in SPAN_CACHE:
  yy,xx=np.where(np.array(im.getchannel('A'))>128);projection=xx*vs[0]+yy*vs[1];SPAN_CACHE[key]=max(1,float(projection.max()-projection.min()))
 # Width is measured PERPENDICULAR to the anatomical bone, not the image bbox.
 # Angled forearms otherwise become unnaturally thin when aligned with the rig.
 mat=np.eye(3);mat[:2,:2]=np.outer(ud,us)*(np.linalg.norm(d)/np.linalg.norm(s))+np.outer(vd,vs)*(width/SPAN_CACHE[key]);mat[:2,2]=dst0-mat[:2,:2]@a
 return mat
OLD={
 'upper_arm_L':((.50,.12),(.56,.89)),'upper_arm_R':((.58,.13),(.38,.89)),
 'forearm_L':((.41,.15),(.82,.91)),'forearm_R':((.65,.14),(.27,.92)),
 'thigh_L':((.53,.12),(.53,.89)),'thigh_R':((.65,.13),(.34,.89)),
 'shin_L':((.48,.15),(.44,.89)),'shin_R':((.45,.15),(.48,.89)),
 'hand_L':((.39,.15),(.69,.82)),'hand_R':((.36,.15),(.61,.76)),
 'torso':((.44,.15),(.50,.86)),'sword':((.16,.79),(.94,.05))}
PIX={name:((.5,.13),(.5,.88)) for name in ['upper_arm_L','upper_arm_R','forearm_L','forearm_R','thigh_L','thigh_R','shin_L','shin_R']}
PIX.update({'hand_L':((.47,.14),(.55,.81)),'hand_R':((.47,.13),(.62,.81)),'torso':((.45,.13),(.5,.85)),'sword':((.5,.86),(.5,.06))})
Z={'cape_lower':0,'thigh_L':10,'shin_L':11,'foot_L':12,'upper_arm_L':20,'forearm_L':21,'hand_L':22,'pelvis':40,'skirt_back':41,'thigh_R':45,'shin_R':46,'foot_R':47,'torso':60,'skirt_front':62,'upper_arm_R':66,'forearm_R':67,'cape_upper':70,'head':75,'sword':85,'hand_R':90}
class Artist:
 def __init__(self,style):
  self.style=style;self.images={n:Image.open(OUT/style/'parts'/f'{n}.png').convert('RGBA') for n in NAMES};self.sources=OLD if style=='illustration' else PIX
 def matrices(self,t):
  p,fa,contact=skeleton(t);m={};src=self.sources
  for side in ['L','R']:
   for part,j0,j1,width in [('thigh','hip','knee',18 if side=='R' else 16),('shin','knee','ankle',15 if side=='R' else 13),('upper_arm','shoulder','elbow',17 if side=='R' else 15),('forearm','elbow','wrist',15 if side=='R' else 13),('hand','wrist','palm',13 if side=='R' else 11)]:
    n=part+'_'+side;m[n]=bone(self.images[n],*src[n],p[j0+'_'+side],p[j1+'_'+side],width)
   n='foot_'+side;m[n]=attach(self.images[n],(.28,.20),p['ankle_'+side],29 if side=='R' else 27,15,fa[side])
  m['torso']=bone(self.images['torso'],*src['torso'],p['neck'],p['waist'],33)
  m['pelvis']=attach(self.images['pelvis'],(.50,.35),p['pelvis'],34,28,0)
  m['head']=attach(self.images['head'],(.43,.92) if self.style=='illustration' else (.44,.87),p['neck'],37,42,3)
  m['sword']=bone(self.images['sword'],*src['sword'],p['grip'],p['sword_tip'],12)
  m['cape_upper']=attach(self.images['cape_upper'],(.56,.26),p['neck']+np.array([-4,9]),57,33,5)
  if self.style=='illustration':m['cape_lower']=attach(self.images['cape_lower'],(.065,.065),p['neck']+np.array([-12,12]),57,105,36+5*math.sin(2*math.pi*t-.7))
  else:m['cape_lower']=attach(self.images['cape_lower'],(.93,.06),p['neck']+np.array([-12,12]),65,100,4+5*math.sin(2*math.pi*t-.7))
  m['skirt_back']=attach(self.images['skirt_back'],(.60,.12),p['waist']+np.array([-5,7]),23,28,6+4*math.sin(2*math.pi*t-.3))
  m['skirt_front']=attach(self.images['skirt_front'],(.5,.1),p['waist']+np.array([4,7]),23,29,-2+3*math.sin(2*math.pi*t+.3))
  return m,p,contact
 def render(self,t,size=1024,guides=False):
  m,p,c=self.matrices(t);scale=size/256;canvas=Image.new('RGBA',(size,size));resample=Image.Resampling.NEAREST if self.style=='pixel' else Image.Resampling.BICUBIC
  for n in sorted(NAMES,key=lambda n:Z[n]):
   inv=np.linalg.inv(np.diag([scale,scale,1])@m[n]);im=self.images[n].transform((size,size),Image.Transform.AFFINE,tuple(inv[:2,:].ravel()),resample);canvas.alpha_composite(im)
  if guides:
   d=ImageDraw.Draw(canvas)
   for side in ['L','R']:
    for a,b in [('shoulder','elbow'),('elbow','wrist'),('hip','knee'),('knee','ankle')]:d.line((*tuple(p[a+'_'+side]*scale),*tuple(p[b+'_'+side]*scale)),fill='#34c2cf',width=max(1,int(scale)))
   for name,pt in p.items():
    x,y=pt*scale;d.ellipse((x-2*scale,y-2*scale,x+2*scale,y+2*scale),fill='#fa7844')
  return canvas
def sheet(artists):
 out=Image.new('RGB',(1536,820),'#dbe4ed');d=ImageDraw.Draw(out)
 for row,artist in enumerate(artists):
  for col,f in enumerate([0,6,12,18]):
   im=artist.render(f/24,384,guides=False);out.paste(im,(384*col,410*row+24),im);d.text((384*col+10,410*row+6),f'{artist.style} / F{f:02}',fill='#253e55')
 out.save(OUT/'pose_comparison.jpg')
 guide=Image.new('RGB',(1024,550),'#dbe4ed');d=ImageDraw.Draw(guide)
 for col,f in enumerate([0,6]):
  im=artists[0].render(f/24,512,True);guide.paste(im,(col*512,25),im);d.text((col*512+16,8),f'CONNECTED JOINTS / F{f:02}',fill='#253e55')
 guide.save(OUT/'joint_guide.jpg')
def quantize_fixed(frames,colors,hard_alpha):
 # One palette for the whole cycle prevents frame-to-frame palette flicker.
 mosaic=Image.new('RGB',(128*len(frames),128),'#182534')
 for i,im in enumerate(frames):
  bg=Image.new('RGBA',im.size,'#182534');bg.alpha_composite(im);mosaic.paste(bg.convert('RGB').resize((128,128)),(128*i,0))
 pal=mosaic.quantize(colors=colors-1,method=Image.Quantize.MEDIANCUT);palette=pal.getpalette();result=[]
 for im in frames:
  a=im.getchannel('A');q=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(a.point(lambda v:255 if v>=128 else 0) if hard_alpha else a);result.append(q)
 return result
def main():
 extract_pixel();artists=[Artist('illustration'),Artist('pixel')];sheet(artists)
 if '--preview' in sys.argv:return
 allframes=[];qa={};pose_data=[]
 for t in [f/24 for f in range(24)]:
  p,fa,c=skeleton(t);pose_data.append({'frame':round(t*24),'time_seconds':t,'joints_256':{k:list(v) for k,v in p.items()},'contact':c})
 for artist in artists:
  style=artist.style;folder=OUT/style;prev=folder/'preview';runtime=folder/'runtime/run';high=folder/'production_frames/run';runtime.mkdir(parents=True,exist_ok=True);high.mkdir(parents=True,exist_ok=True)
  frames=[];bigs=[];records=[];endpoint_errors=[]
  for f in range(24):
   size=128 if style=='pixel' else 1024;im=artist.render(f/24,size);bigs.append(im);frames.append(im if style=='pixel' else im.resize((256,256),Image.Resampling.LANCZOS))
   mats,p,c=artist.matrices(f/24)
   for side in ['L','R']:
    for part,a,b in [('thigh','hip','knee'),('shin','knee','ankle'),('upper_arm','shoulder','elbow'),('forearm','elbow','wrist'),('hand','wrist','palm')]:
     n=part+'_'+side;src=artist.sources[n]
     for s,j in zip(src,[a,b]):
      pt=np.array([s[0]*artist.images[n].width,s[1]*artist.images[n].height,1]);endpoint_errors.append(float(np.linalg.norm((mats[n]@pt)[:2]-p[j+'_'+side])))
  if style=='pixel':frames=quantize_fixed(frames,32,True);bigs=[fr.resize((1024,1024),Image.Resampling.NEAREST) for fr in frames];frames=[fr.resize((256,256),Image.Resampling.NEAREST) for fr in frames]
  for f,(fr,big) in enumerate(zip(frames,bigs)):
   fr.save(runtime/f'character_01_{style}_run_{f:04}.png');big.save(high/f'character_01_{style}_run_{f:04}.png')
  frames[0].save(prev/'run_frame_00.png');timing=[round((f+1)*1000/24)-round(f*1000/24) for f in range(24)]
  frames[0].save(prev/'run.webp',save_all=True,append_images=frames[1:],duration=timing,loop=0,lossless=True)
  frames[0].save(prev/'run.png',save_all=True,append_images=frames[1:],duration=timing,loop=0,disposal=0,blend=0)
  gif=[]
  for fr in frames:
   bg=Image.new('RGBA',(512,512),'#dbe4ed');bg.alpha_composite(fr.resize((512,512),Image.Resampling.NEAREST if style=='pixel' else Image.Resampling.LANCZOS));gif.append(bg.convert('RGB'))
  durations=[(round((f+1)*100/24)-round(f*100/24))*10 for f in range(24)];gif[0].save(prev/'run.gif',save_all=True,append_images=gif[1:],duration=durations,loop=0,disposal=2)
  bounds=[fr.getchannel('A').getbbox() for fr in frames];union=[min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds)]
  contacts=[]
  for pose in pose_data:
   for side in ['L','R']:
    if pose['contact'][side]:contacts.append(abs(pose['joints_256']['ankle_'+side][1]-212))
  colors=set()
  for fr in frames:
   arr=np.array(fr);colors.update(map(tuple,arr[arr[:,:,3]==255][:,:3]))
  qa[style]={'frame_count':24,'fps':24,'duration_seconds':1,'visible_bounds_256':union,'safe_bounds_pass':union[0]>=16 and union[1]>=16 and union[2]<=240 and union[3]<=240,'bone_endpoint_error_max_px':max(endpoint_errors),'contact_ankle_y_error_max_px':max(contacts),'opaque_colors':len(colors),'pixel_grid':128 if style=='pixel' else None,'loop_joints_match':all(np.allclose(skeleton(0)[0][k],skeleton(1)[0][k]) for k in skeleton(0)[0])}
  matrices,pts,c=artist.matrices(0)
  for n in NAMES:records.append({'id':n,'file':f'../parts/{n}.png','native_size':list(artist.images[n].size),'draw_order':Z[n],'frame_00_matrix_256':matrices[n].tolist(),'bone_source_anchors_normalized':artist.sources.get(n)})
  source=folder/'source';source.mkdir(exist_ok=True)
  (source/'rig.json').write_text(json.dumps({'schema_version':4,'style':style,'coordinate_system':'256canvas,lefttoporigin,xright,ydown','anchor_256':[128,224],'parts':records,'per_frame_joints':pose_data,'animation_source':'../../source/renderer.py'},indent=2),encoding='utf-8')
  (folder/'runtime/animations.json').write_text(json.dumps({'asset_id':'character_01','variant':style,'fps':24,'duration_seconds':1,'loop':True,'root_motion':'none','frame_width':256,'frame_height':256,'pivot_px':[128,224],'safe_bounds_px':[16,16,240,240],'downsample_method':'NEAREST_FROM_128' if style=='pixel' else 'LANCZOS_FROM_1024','animation_id':'run','frame_count':24,'files':[f'run/character_01_{style}_run_{f:04}.png' for f in range(24)]},indent=2),encoding='utf-8')
  svg=['<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="1024" viewBox="0 0 256 256">']
  for n in sorted(NAMES,key=lambda n:Z[n]):
   m=matrices[n];a,b,c,d,e,f=m[0,0],m[1,0],m[0,1],m[1,1],m[0,2],m[1,2];im=artist.images[n];data=base64.b64encode((folder/'parts'/f'{n}.png').read_bytes()).decode();svg.append(f'<g id="{n}" transform="matrix({a} {b} {c} {d} {e} {f})"><image width="{im.width}" height="{im.height}" xlink:href="data:image/png;base64,{data}"/></g>')
  svg.append('</svg>');(source/'frame00_layers.svg').write_text('\n'.join(svg),encoding='utf-8')
  allframes.append(frames);print(style,qa[style],flush=True)
 # Same phase and timing, both styles displayed at equal canvas size.
 comp=[]
 for f in range(24):
  im=Image.new('RGB',(1024,560),'#dbe4ed');d=ImageDraw.Draw(im)
  for i,frames in enumerate(allframes):
   fr=frames[f].resize((512,512),Image.Resampling.NEAREST if i else Image.Resampling.LANCZOS);im.paste(fr,(512*i,40),fr);d.text((512*i+20,15),'ILLUSTRATION / VIDEO REFERENCE' if i==0 else 'PIXEL / 128 GRID',fill='#253e55')
  comp.append(im)
 comp[0].save(OUT/'comparison.gif',save_all=True,append_images=comp[1:],duration=durations,loop=0,disposal=2)
 (OUT/'qa.json').write_text(json.dumps(qa,indent=2),encoding='utf-8')
if __name__=='__main__':main()
