#!/usr/bin/env python3
"""Deterministic original ambience; no sampled works, external assets or voices."""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
RATE=22050
DURATION=16

def write(name: str, signal: np.ndarray) -> None:
    # All oscillators use integer periods over the loop; fades guard noise seam.
    signal-=signal.mean()
    signal=np.clip(signal,-0.75,0.75)
    path=ROOT/'assets/ambient'/name
    path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(RATE)
        wav.writeframes(np.round(signal*32767).astype('<i2').tobytes())

def build() -> None:
    t=np.arange(RATE*DURATION,dtype=np.float64)/RATE
    rng=np.random.default_rng(128121)
    noise=rng.normal(0,1,t.size)
    spectrum=np.fft.rfft(noise)
    hz=np.fft.rfftfreq(t.size,1/RATE)
    # Circular FFT-filtered noise has no special splice boundary.
    wind=np.fft.irfft(spectrum*np.exp(-(hz/1400)**2)/(1+(hz/110)**1.2),t.size)
    wind/=max(1.0,wind.std()*9)
    hum=(0.09*np.sin(2*np.pi*55*t)+0.04*np.sin(2*np.pi*110*t))*(0.65+0.10*np.sin(2*np.pi*0.25*t))
    archival=hum+wind*0.17
    for start in [2.3,5.5,10.4,13.2]:
        u=t-start; env=np.where(u>=0,np.exp(-np.maximum(u,0)*38),0)
        archival+=env*(0.07*np.sin(2*np.pi*780*u)+0.025*np.sin(2*np.pi*1570*u))
    water=wind*(0.22+0.08*np.sin(2*np.pi*0.1875*t))
    for i in range(38):
        start=0.3+i*0.4+0.11*np.sin(i*3.1)
        u=t-start;env=np.where(u>=0,np.exp(-np.maximum(u,0)*26),0)
        water+=0.05*env*np.sin(2*np.pi*(540+80*(i%5))*u)
    # Short symmetric fade only affects the seam of relay/drop transients.
    fade=np.minimum(np.minimum(t/0.06,(DURATION-t)/0.06),1.0)
    write('archive_ventilation.wav',archival*fade)
    write('garden_rain.wav',water*fade)
    print('Generated two original 16-second mono WAV loops at 22050 Hz.')
if __name__=='__main__':build()
