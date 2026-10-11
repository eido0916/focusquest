from pathlib import Path
p=Path(__file__).with_name('renderer.py')
s=p.read_text(encoding='utf-8')
a=s.index('def foot_path(u):'); b=s.index('\ndef T(x,y)',a)
s=s[:a]+'''def hermite(u,knots):
 for i in range(len(knots)-1):
  t0,p0,v0=knots[i];t1,p1,v1=knots[i+1]
  if u<=t1:
   q=(u-t0)/(t1-t0);dt=t1-t0
   return (2*q**3-3*q*q+1)*np.array(p0)+(q**3-2*q*q+q)*dt*np.array(v0)+(-2*q**3+3*q*q)*np.array(p1)+(q**3-q*q)*dt*np.array(v1)
 return np.array(knots[-1][1])

def foot_path(u):
 u=u%1;stance=.38;speed=50/stance
 if u<stance:return np.array([154-speed*u,212.]),0.,True
 # Contact > down > passing > push-off > flight. Heel folds behind the
 # pelvis before the swing knee advances, instead of a symmetric ellipse.
 knots=[(.38,(104,212),(-speed,0)),(.52,(103,165),(80,-220)),
        (.64,(123,155),(240,30)),(.80,(153,177),(110,205)),
        (1.,(154,212),(-speed,0))]
 ankle=hermite(u,knots)
 angle=float(hermite(u,[(.38,(0,),(0,)),(.54,(32,),(0,)),
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
 for side,a,flex in [('R',-15+25*arm,95),('L',-15-38*arm,95)]:
  shoulder=p['shoulder_'+side];elbow=shoulder+vec(a,27)
  wrist=elbow+vec(a+flex,25)
  p['elbow_'+side]=elbow;p['wrist_'+side]=wrist
  p['palm_'+side]=wrist+vec(a+flex,10.)
 p['grip']=p['palm_R']
 # Stable wrist grip; blade follows a restrained rotation, not an independent bob.
 p['sword_tip']=p['grip']+R(-5+4*arm)[:2,:2]@np.array([31.,-42.])
 return p,footangles,contact
''' + s[b:]
s=s.replace("'schema_version':2","'schema_version':3")
s=s.replace("'ILLUSTRATION / FIXED'","'ILLUSTRATION / VIDEO REFERENCE'")
p.write_text(s,encoding='utf-8')
