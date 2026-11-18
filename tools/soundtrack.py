import subprocess
from pathlib import Path
import numpy as np

OUT = Path(__file__).resolve().parents[1] / 'game/media'
RATE = 32000
RNG = np.random.default_rng(883)
TAU = 2*np.pi


def voice(note, duration, kind):
    time=np.arange(int(RATE*duration))/RATE
    freq=440*2**((note-69)/12); phase=TAU*freq*time
    attack=.009; release=.10
    if kind=='felt':
        wave=(np.sin(phase)+.40*np.sin(2*phase+.12)+.22*np.sin(3.005*phase)+.12*np.sin(4.02*phase)*np.exp(-time*7))*np.exp(-time*2.7)
    elif kind=='glass':
        wave=(np.sin(phase+.32*np.sin(phase*2.01)*np.exp(-time*4))+.26*np.sin(phase*3.98)*np.exp(-time*3))*np.exp(-time*2)
    elif kind=='reed':
        phase=phase+.034*np.sin(TAU*4.3*time); wave=np.sin(phase)+.21*np.sin(3*phase)+.07*np.sin(5*phase); attack=.12; release=.22
    elif kind=='cello':
        wave=np.sin(phase+.16*np.sin(.5*phase))+.21*np.sin(2*phase)+.12*np.sin(3*phase); attack=.08; release=.24
    elif kind=='brush':
        noise=RNG.normal(0,.6,len(time)); wave=np.diff(noise,prepend=0)*np.exp(-time*40); release=.03
    else:
        wave=np.sin(TAU*(60*time+.8*(1-np.exp(-time*35))))*np.exp(-time*12);release=.05
    return wave*np.minimum(1,time/attack)*np.clip((duration-time)/release,0,1)


def write(name, mix):
    data=np.asarray(np.clip(mix,-.98,.98)*32767,dtype='<i2')
    subprocess.run(['ffmpeg','-loglevel','error','-y','-f','s16le','-ar',str(RATE),'-ac','2','-i','pipe:0','-c:a','vorbis','-strict','experimental','-q:a','5',str(OUT/(name+'.ogg'))],input=data.tobytes(),check=True)


def compose(index,bpm,transpose):
    beat=60/bpm; total=round(16*4*beat*RATE); mix=np.zeros((total,2)); wet=np.zeros_like(mix)
    def place(pos,note,dur,kind,vol,pan):
        mono=voice(note+transpose,dur*beat,kind)*vol
        stereo=mono[:,None]*np.sqrt([(1-pan)/2,(1+pan)/2]); start=round(pos*beat*RATE)%total; first=min(len(mono),total-start)
        mix[start:start+first]+=stereo[:first]; mix[:len(mono)-first]+=stereo[first:]
    chords=[(50,57,62,65,69),(46,53,60,65,69),(53,60,64,67,69),(48,55,62,64,67),(43,55,58,62,65),(46,53,60,62,65),(45,52,59,61,67),(50,57,60,65,69)]
    phrases=[[(.5,69,.6),(1.5,72,.38),(2,74,1.65)],[(0,77,.8),(1,76,.48),(2,72,1.45)],[(0,69,1.25),(1.75,67,.65),(3,65,.8)],[(.25,67,2.2)],[(0,70,.8),(1.5,74,.5),(2.25,77,1.4)],[(0,77,1),(1.5,74,.5),(2.5,72,1)],[(0,69,.7),(1,67,.8),(2.5,73,.95)],[(0,74,2.8)]]
    for bar in range(16):
        chord=chords[(bar+(2 if index==1 else 0))%8]; base=bar*4
        place(base,chord[0]-12,3.65,'cello',.13,-.12)
        pattern=[[1,3,2,4,1,2],[1,2,3,2,4,3],[1,3,4,2,3,2],[2,3,4,3,1,3]][index]
        for idx,tick in enumerate([0,.75,1.5,2,2.75,3.5]): place(base+tick+.015*(idx%2),chord[pattern[idx]],1.5,'felt',.12 if idx%3==0 else .075,(-1)**idx*.37)
        for tick,note,length in phrases[bar%8]:
            pitch=note+(12 if bar>=8 and index in [0,3] else 0)
            if index==1: pitch=chord[2+(int(tick)%3)]+12
            if index==2: pitch=note-12
            place(base+tick,pitch,length,'reed' if index in [1,2] else 'glass',.115,.14)
        if bar>=8:
            place(base+3.25,chord[3]+12,.55,'glass',.052,-.52)
        if index in [1,2,3]:
            for tick in [1,3,3.75]: place(base+tick,40,.27,'brush',.028 if tick==3.75 else .046,.4)
            place(base,40,.65,'kick',.075,0)
    for delay,vol in [(.16,.18),(.31,.12),(.47,.065),(.72,.035)]: wet+=np.roll(mix[:,::-1],round(delay*RATE),axis=0)*vol
    mix+=wet; write('score'+str(index),np.tanh(mix*1.6)*.83)


if __name__=='__main__':
    for idx,(tempo,key) in enumerate([(84,0),(99,2),(76,-2),(94,5)]): compose(idx,tempo,key)
    for name,notes in {'sail':[50,57],'mail':[74,81,86],'key':[65,69,76,81],'dock':[62,69,74,78,81],'undo':[74,69],'knock':[43],'gold':[74,78,81,86,90],'page':[62,67]}.items():
        mix=np.zeros((RATE*2,2)); stride=.09 if name!='dock' else .14
        for idx,note in enumerate(notes):
            wave=voice(note,.55 if name!='sail' else .17,'glass' if name not in ['knock','sail'] else 'felt'); start=int(idx*stride*RATE); mix[start:start+len(wave)]+=wave[:,None]*.23
        write(name,mix[:start+len(wave)])
