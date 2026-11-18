from soundtrack import RATE, TAU, write
import numpy as np

rng=np.random.default_rng(9709)
length=6
time=np.arange(RATE*length)/RATE
def soften(noise,width):
    return np.convolve(noise,np.ones(width)/width,mode="same")
channels=[]
for side in [-1,1]:
    raw=rng.normal(0,1,time.size)
    foam=(soften(raw,4)-soften(raw,34))*(.031+.017*np.sin(TAU*time/length+side))
    phase=TAU*38*time+np.sin(TAU*2*time/length)*.14
    motor=(np.sin(phase)+.23*np.sin(2*phase)+.11*np.sin(3*phase))*.057*(.65+.35*np.cos(TAU*6*time))
    channels.append(foam+motor)
write("engine",np.stack(channels,axis=1))
time=np.arange(int(.43*RATE))/RATE
noise=rng.normal(0,1,len(time));wave=(soften(noise,4)-soften(noise,20))*.21*np.sin(np.pi*time/.43)**2*np.exp(-time*3)
wave+=.08*np.sin(TAU*(280*time-220*time*time))*np.exp(-time*10)
write("rope",np.stack([wave,np.roll(wave,18)],axis=1))
time=np.arange(int(.34*RATE))/RATE
wave=np.sin(TAU*(720*time+95*time*time)+.2*np.sin(TAU*1440*time))*np.minimum(1,time*130)*np.exp(-time*15)*.105
write("crest",np.stack([wave,np.roll(wave,8)],axis=1))
