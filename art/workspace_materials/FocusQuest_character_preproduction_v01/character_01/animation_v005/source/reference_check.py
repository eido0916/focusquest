from PIL import Image, ImageDraw
import numpy as np
import json, math
import renderer as r

KEYS=[(0,'1 (R) / CONTACT'),(2,'2 / DOWN'),(4,'3 / PASSING'),(6,'4 / PUSH OFF'),(9,'5 / FLIGHT'),(12,'1 (L) / CONTACT')]

def angle(p,a,b,c):
    v=p[a]-p[b];w=p[c]-p[b]
    return math.degrees(math.acos(np.clip(np.dot(v,w)/np.linalg.norm(v)/np.linalg.norm(w),-1,1)))

def main():
    out=r.OUT
    poses={f:r.skeleton(f/24) for f,_ in KEYS}
    p,c=poses[0][0],poses[0][2]
    checks={
      'contact_front_leg_extended':angle(p,'hip_R','knee_R','ankle_R')>160,
      'contact_front_foot_ahead':p['ankle_R'][0]>p['hip_R'][0],
      'contact_rear_heel_folded':p['ankle_L'][0]<p['hip_L'][0] and p['ankle_L'][1]<p['knee_L'][1],
      'down_hip_lower_than_contact':poses[2][0]['hip_R'][1]>p['hip_R'][1],
      'passing_support_ankle_under_hip':abs(poses[4][0]['ankle_R'][0]-poses[4][0]['hip_R'][0])<5,
      'push_off_knee_forward':poses[6][0]['knee_L'][0]>poses[6][0]['hip_L'][0]+30,
      'flight_both_feet_off_ground':not any(poses[9][2].values()),
      'flight_hip_higher':poses[9][0]['hip_R'][1]<p['hip_R'][1],
      'opposite_contact_at_frame12':poses[12][2]['L'] and not poses[12][2]['R'],
      'arms_opposite_to_front_leg':p['palm_L'][0]>p['palm_R'][0],
    }
    checks={key:bool(value) for key,value in checks.items()}
    assert all(checks.values()),checks
    checks['contact_knee_angle_degrees']=angle(p,'hip_R','knee_R','ankle_R')
    checks['key_frames']=[f for f,_ in KEYS]
    checks['source']='reference/run_poses.png'
    (out/'reference_pose_verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
    sheet=Image.new('RGB',(1536,870),'#e5ebf2');d=ImageDraw.Draw(sheet)
    artists=[r.Artist('illustration'),r.Artist('pixel')]
    for col,(f,label) in enumerate(KEYS):
        x=col*256;p=poses[f][0]
        d.text((x+8,8),label,fill='#20364c')
        d.text((x+8,26),f'FRAME {f:02} / 24 FPS',fill='#61768b')
        # Code-native motion guide, drawn from the actual joint data.
        def pt(name):return tuple(p[name]+np.array([x,45]))
        ground=224+45
        d.line((x+8,ground,x+248,ground),fill='#98aabf',width=2)
        for side,color in [('L','#89929d'),('R','#26394c')]:
            for a,b in [('hip','knee'),('knee','ankle'),('shoulder','elbow'),('elbow','wrist')]:
                d.line((*pt(a+'_'+side),*pt(b+'_'+side)),fill=color,width=8)
        d.line((*pt('pelvis'),*pt('neck')),fill='#26394c',width=13)
        nx,ny=pt('neck');d.ellipse((nx-13,ny-34,nx+13,ny-5),fill='#ffffff',outline='#26394c',width=2)
        for row,artist in enumerate(artists):
            im=Image.open(out/artist.style/'runtime/run'/f'character_01_{artist.style}_run_{f:04}.png').convert('RGBA')
            y=300+row*280
            sheet.paste(im,(x,y),im)
            d.text((x+8,y-15),artist.style.upper(),fill='#20364c')
            d.line((x+8,y+224,x+248,y+224),fill='#98aabf',width=1)
    sheet.save(out/'key_poses.jpg',quality=94)
    print('Reference pose checks passed:',checks,flush=True)

if __name__=='__main__':main()
