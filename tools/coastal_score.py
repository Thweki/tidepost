from soundtrack import RATE, TAU, voice, write
import numpy as np

TEMPI=[75,81,86,90,78,68,88,71,64,85,74,80]
KEYS=[0,5,2,-2,3,-3,2,0,-2,5,2,0]
HARMONY=[(50,57,62,65,69),(46,53,58,62,65),(53,60,65,69,72),(48,55,60,64,67),
         (43,50,55,58,62),(45,52,57,60,64),(45,52,57,61,67),(50,57,62,65,69)]
FORMS=[[0,1,2,3,4,1,6,7],[2,3,0,1,4,0,6,7],[4,0,1,3,2,4,6,7],[0,5,1,3,4,1,6,7]]
MOTIFS=[
    [(0,2,.7),(1,3,.42),(1.5,4,1.1)],[(.25,4,.6),(1,3,.75),(2.25,2,.6)],
    [(0,3,1.4),(1.75,2,.42),(2.25,1,.6)],[(0,2,2.4)],
    [(.5,2,.45),(1,3,.75),(2,4,.85)],[(0,4,.7),(1.25,3,1.5)],
    [(0,2,.42),(.5,3,.42),(1,4,.9),(2.25,3,.55)],[(0,2,2.6)]
]

def timbre(note,length,kind):
    time=np.arange(int(RATE*length))/RATE
    phase=TAU*440*2**((note-69)/12)*time
    if kind=="wire":
        tone=sum(np.sin(phase*harmonic*(1+.00012*harmonic**2))*
                 np.exp(-time*(2.3+harmonic*.87))/harmonic**.9 for harmonic in range(1,7))
        return tone*np.minimum(1,time/.006)*np.clip((length-time)/.07,0,1)
    if kind=="bow":
        modulation=.067*np.sin(TAU*time*4.7)*np.minimum(time/.3,1)
        tone=sum(np.sin((phase+modulation)*harmonic)/harmonic**1.4 for harmonic in range(1,6))
        return tone*np.minimum(1,time/.16)*np.clip((length-time)/.2,0,1)*(.9+.1*np.sin(time*2.8))
    return voice(note,length,kind)

def score(index):
    beat=60/TEMPI[index];length=round(32*3*beat*RATE)
    mix=np.zeros((length,2));key=KEYS[index];form=FORMS[index%4]
    def add(start,note,duration,kind,amp,pan):
        signal=timbre(note+key,duration*beat,kind)*amp
        stereo=signal[:,None]*np.sqrt([(1-pan)*.5,(1+pan)*.5])
        offset=round(start*beat*RATE)%length;limit=min(len(signal),length-offset)
        mix[offset:offset+limit]+=stereo[:limit]
        if limit<len(signal):mix[:len(signal)-limit]+=stereo[limit:]
    for bar in range(32):
        phrase=bar//8;measure=bar%8;base=bar*3
        chord=HARMONY[form[measure]]
        add(base,chord[0]-12,2.74,"cello",.108,-.13)
        if phrase>0 or measure%2==0:add(base+1.51,chord[1]-12,1.2,"wire",.047,-.3)
        for step,degree in enumerate([1,2,3,2,4,3]):
            if phrase==2 and step in [1,3]:continue
            add(base+step*.5+(.018 if step%2 else 0),chord[degree],1.15,
                "felt" if index%3==0 else "wire",.096 if step==0 else .058,.38*(-1)**step)
        lead=["reed","glass","bow","wire"][(index+int(phrase==2))%4]
        pattern=MOTIFS[(measure+index%3)%8] if measure!=7 else MOTIFS[7]
        for onset,degree,duration in pattern:
            shift=12 if phrase==2 or (index%4==0 and phrase==1) else 0
            if phrase==3 and measure>5:shift=0
            add(base+onset,chord[degree]+shift,duration,lead,.102,.14)
        if phrase in [1,3] and measure%2==1:
            add(base+.51,chord[2]+12,.7,"glass",.043,-.53)
            add(base+2.01,chord[3]+12,.75,"glass",.037,-.45)
        if index in [2,3,4,6,9,11] and phrase!=2:
            add(base,38,.5,"kick",.052,0);add(base+1.5,40,.3,"brush",.039,.48)
        if phrase==2 and measure in [2,6]:
            add(base+.5,chord[2]-12,2.4,"bow",.087,-.24)
    ambience=np.zeros_like(mix)
    for delay,gain in [(.13,.15),(.26,.115),(.44,.067),(.61,.038)]:
        ambience+=np.roll(mix[:,::-1],round(delay*RATE),axis=0)*gain
    write("coastal%02d"%index,np.tanh((mix+ambience)*1.65)*.86)

for chapter in range(12):score(chapter)
