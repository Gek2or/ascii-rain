"""Run a translated Godot canvas fragment in Mesa EGL. NOT a Godot runtime test."""
import os,ctypes as C,ctypes.util,re
from pathlib import Path
import numpy as np
os.environ.setdefault('LIBGL_ALWAYS_SOFTWARE','1')
os.environ.setdefault('EGL_PLATFORM','surfaceless')
E=C.CDLL(ctypes.util.find_library('EGL'))
G=C.CDLL(ctypes.util.find_library('GL'))
def ef(name,rest,args):
 f=getattr(E,name);f.restype=rest;f.argtypes=args;return f
def gf(name,rest,args):
 f=getattr(G,name);f.restype=rest;f.argtypes=args;return f
P=C.c_void_p;I=C.c_int;U=C.c_uint;F=C.c_float
get=ef('eglGetDisplay',P,[P]);display=get(P(0))
ma=I();mi=I();assert ef('eglInitialize',U,[P,C.POINTER(I),C.POINTER(I)])(display,C.byref(ma),C.byref(mi)), 'EGL init failed'
assert ef('eglBindAPI',U,[U])(0x30A2)
attrs=(I*13)(0x3033,1,0x3040,8,0x3024,8,0x3023,8,0x3022,8,0x3021,8,0x3038)
conf=P();n=I();assert ef('eglChooseConfig',U,[P,C.POINTER(I),C.POINTER(P),I,C.POINTER(I)])(display,attrs,C.byref(conf),1,C.byref(n)) and n.value
pb=(I*5)(0x3057,16,0x3056,16,0x3038)
surf=ef('eglCreatePbufferSurface',P,[P,P,C.POINTER(I)])(display,conf,pb)
ca=(I*7)(0x3098,3,0x30FB,3,0x30FD,1,0x3038)
ctx=ef('eglCreateContext',P,[P,P,P,C.POINTER(I)])(display,conf,P(0),ca)
assert surf and ctx
assert ef('eglMakeCurrent',U,[P,P,P,P])(display,surf,surf,ctx)
getstr=gf('glGetString',C.c_char_p,[U]);print('GL_RENDERER',getstr(0x1F01).decode());print('GL_VERSION',getstr(0x1F02).decode())
create=gf('glCreateShader',U,[U]);shsrc=gf('glShaderSource',None,[U,I,C.POINTER(C.c_char_p),C.POINTER(I)])
compile_=gf('glCompileShader',None,[U]);getshiv=gf('glGetShaderiv',None,[U,U,C.POINTER(I)]);shlog=gf('glGetShaderInfoLog',None,[U,I,C.POINTER(I),C.c_char_p])
def shader(kind,text):
 sh=create(kind);p=C.c_char_p(text.encode());shsrc(sh,1,C.byref(p),None);compile_(sh);status=I();getshiv(sh,0x8B81,C.byref(status))
 if not status.value:
  buf=C.create_string_buffer(32768);shlog(sh,len(buf),None,buf);raise RuntimeError(buf.value.decode())
 return sh
prognew=gf('glCreateProgram',U,[]);attach=gf('glAttachShader',None,[U,U]);link=gf('glLinkProgram',None,[U]);getprog=gf('glGetProgramiv',None,[U,U,C.POINTER(I)]);proglog=gf('glGetProgramInfoLog',None,[U,I,C.POINTER(I),C.c_char_p])
VERT='''#version 330 core
out vec2 test_uv;
void main() { vec2 p=vec2((gl_VertexID << 1)&2, gl_VertexID&2); test_uv=p; gl_Position=vec4(p*2.0-1.0,0.0,1.0); }
'''
def translate(path):
 s=Path(path).read_text()
 s=re.sub(r'^shader_type[^;]+;','',s,flags=re.M);s=re.sub(r'^render_mode[^;]+;','',s,flags=re.M)
 s=re.sub(r'(uniform\s+\w+\s+\w+)\s*:\s*[^=;]+',r'\1 ',s)
 s=s.replace('void fragment()', 'void main()')
 return '#version 330 core\nin vec2 test_uv;\nuniform vec2 SCREEN_PIXEL_SIZE;\n#define SCREEN_UV test_uv\nout vec4 COLOR;\n'+s

def program(path):
 p=prognew();attach(p,shader(0x8B31,VERT));attach(p,shader(0x8B30,translate(path)));link(p);status=I();getprog(p,0x8B82,C.byref(status))
 if not status.value:
  buf=C.create_string_buffer(32768);proglog(p,len(buf),None,buf);raise RuntimeError(buf.value.decode())
 return p
use=gf('glUseProgram',None,[U]);loc=gf('glGetUniformLocation',I,[U,C.c_char_p]);u1f=gf('glUniform1f',None,[I,F]);u2f=gf('glUniform2f',None,[I,F,F]);u1i=gf('glUniform1i',None,[I,I])
gentex=gf('glGenTextures',None,[I,C.POINTER(U)]);bindtex=gf('glBindTexture',None,[U,U]);teximg=gf('glTexImage2D',None,[U,I,I,I,I,I,U,U,P]);texparam=gf('glTexParameteri',None,[U,U,I]);active=gf('glActiveTexture',None,[U]);deltex=gf('glDeleteTextures',None,[I,C.POINTER(U)])
genfb=gf('glGenFramebuffers',None,[I,C.POINTER(U)]);bindfb=gf('glBindFramebuffer',None,[U,U]);fbt=gf('glFramebufferTexture2D',None,[U,U,U,U,I]);fbstat=gf('glCheckFramebufferStatus',U,[U]);delfb=gf('glDeleteFramebuffers',None,[I,C.POINTER(U)])
viewport=gf('glViewport',None,[I,I,I,I]);draw=gf('glDrawArrays',None,[U,I,I]);readpx=gf('glReadPixels',None,[I,I,I,I,U,U,P]);finish=gf('glFinish',None,[])
genvao=gf('glGenVertexArrays',None,[I,C.POINTER(U)]);bindvao=gf('glBindVertexArray',None,[U]);vao=U();genvao(1,C.byref(vao));bindvao(vao)
gf('glDisable',None,[U])(0x0BD0) # GL_DITHER

def texture(arr,linear=False):
 a=np.asarray(arr,dtype=np.float32);a=np.ascontiguousarray(a)
 if a.ndim==2:a=np.repeat(a[:,:,None],3,axis=2)
 h,w,channels=a.shape
 if channels==3:a=np.ascontiguousarray(np.concatenate([a,np.ones((h,w,1),np.float32)],axis=2))
 t=U();gentex(1,C.byref(t));bindtex(0x0DE1,t);texparam(0x0DE1,0x2801,0x2601 if linear else 0x2600);texparam(0x0DE1,0x2800,0x2601 if linear else 0x2600)
 texparam(0x0DE1,0x2802,0x812F);texparam(0x0DE1,0x2803,0x812F)
 teximg(0x0DE1,0,0x8814,w,h,0,0x1908,0x1406,a.ctypes.data_as(P))
 return t

def render(prog,src,atlas,coverage=None,**uniforms):
 use(prog);h,w=src.shape[:2];textures=[]
 for index,(name,arr) in enumerate([('screen_texture',src),('glyph_atlas',atlas),('coverage_atlas',coverage)]):
  if arr is None: continue
  active(0x84C0+index);t=texture(arr,index==0);textures.append(t);u1i(loc(prog,name.encode()),index)
 active(0x84C0+5);out=texture(np.zeros((h,w,4),np.float32));textures.append(out)
 fb=U();genfb(1,C.byref(fb));bindfb(0x8D40,fb);fbt(0x8D40,0x8CE0,0x0DE1,out,0);assert fbstat(0x8D40)==0x8CD5
 u2f(loc(prog,b'SCREEN_PIXEL_SIZE'),1/w,1/h)
 for k,v in uniforms.items():u1f(loc(prog,k.encode()),float(v))
 viewport(0,0,w,h);draw(0x0004,0,3);finish()
 result=np.zeros((h,w,4),np.float32);readpx(0,0,w,h,0x1908,0x1406,result.ctypes.data_as(P))
 bindfb(0x8D40,0);delfb(1,C.byref(fb))
 for t in textures:deltex(1,C.byref(t))
 return result

if __name__=='__main__':
 import sys
 p=program(sys.argv[1]);print('TRANSLATED_FRAGMENT_COMPILE_LINK_OK',p)
