from pathlib import Path
from PIL import Image, ImageDraw
import json, shutil, hashlib, html
import numpy as np

def separate_original_cells(atlas,cols=8,rows=3):
 # Segment connected drawn pixels before extraction, so a sword tip crossing
 # a nominal grid line is not truncated or attached to the previous drawing.
 a=np.array(atlas);h,w=a.shape[:2];mask=a[:,:,3]>=128
 runs=[];parent=[];prev=[]
 def root(i):
  while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
  return i
 for y,row in enumerate(mask):
  edges=np.diff(np.r_[False,row,False].astype(np.int8));starts=np.where(edges==1)[0];ends=np.where(edges==-1)[0];cur=[]
  for x0,x1 in zip(starts,ends):
   k=len(runs);runs.append((y,int(x0),int(x1)));parent.append(k);cur.append(k)
   for p in prev:
    _,l,r=runs[p]
    if r<x0:continue
    if l>x1:break
    parent[root(k)]=root(p)
  prev=cur
 components={}
 for i,r in enumerate(runs):components.setdefault(root(i),[]).append(r)
 groups=[[] for _ in range(cols*rows)];counts=[]
 for rr in components.values():
  area=sum(r-l for y,l,r in rr)
  if area<3:continue
  cx=sum((l+r-1)/2*(r-l) for y,l,r in rr)/area;cy=sum(y*(r-l) for y,l,r in rr)/area
  col=max(0,min(cols-1,int(cx/(w/cols))));row=max(0,min(rows-1,round(cy/(h/rows)-.55)))
  groups[row*cols+col].extend(rr)
 bounds=[]
 for i,rr in enumerate(groups):
  assert rr,('empty original cell',i)
  ox=round((i%cols)*w/cols);oy=round((i//cols)*h/rows)
  bounds.append((min(l for y,l,r in rr)-ox,min(y for y,l,r in rr)-oy,max(r for y,l,r in rr)-ox,max(y for y,l,r in rr)+1-oy))
 common=(min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds))
 cells=[]
 for i,rr in enumerate(groups):
  ox=round(i%cols*w/cols);oy=round(i//cols*h/rows);arr=np.zeros((common[3]-common[1],common[2]-common[0],4),dtype=np.uint8)
  for y,l,r in rr:
   arr[y-oy-common[1],l-ox-common[0]:r-ox-common[0]]=a[y,l:r];arr[y-oy-common[1],l-ox-common[0]:r-ox-common[0],3]=255
  cells.append(Image.fromarray(arr))
 return cells,common

