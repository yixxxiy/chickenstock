import wave
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\assets\sfx")

SPECS = [
	("chick_raw_1.ogg", "chick_1.wav", 0.95),
	("chick_raw_2.ogg", "chick_2.wav", 0.95),
	("chick_raw_3.ogg", "chick_3.wav", 1.05),
	("hen_raw_1.ogg", "hen_1.wav", 1.35),
	("hen_raw_2.ogg", "hen_2.wav", 1.45),
]


def loudest_window(samples: np.ndarray, rate: int, dur: float) -> np.ndarray:
	win = max(1, int(rate * dur))
	if samples.size <= win:
		clip = samples.astype(np.float32)
	else:
		hop = max(1, rate // 100)
		energy = samples.astype(np.float64) ** 2
		csum = np.concatenate(([0.0], np.cumsum(energy)))
		best_i = 0
		best = -1.0
		for i in range(0, samples.size - win, hop):
			rms = csum[i + win] - csum[i]
			if rms > best:
				best = rms
				best_i = i
		clip = samples[best_i : best_i + win].astype(np.float32)
	fade = min(int(rate * 0.02), max(1, clip.size // 6))
	if fade > 1:
		ramp = np.linspace(0.0, 1.0, fade, dtype=np.float32)
		clip = clip.copy()
		clip[:fade] *= ramp
		clip[-fade:] *= ramp[::-1]
	peak = float(np.max(np.abs(clip))) if clip.size else 0.0
	if peak > 0.02:
		clip = clip * (0.92 / peak)
	return np.clip(clip, -1.0, 1.0)


def write_wav(path: Path, samples: np.ndarray, rate: int) -> None:
	pcm = (samples * 32767.0).astype(np.int16)
	with wave.open(str(path), "wb") as wf:
		wf.setnchannels(1)
		wf.setsampwidth(2)
		wf.setframerate(rate)
		wf.writeframes(pcm.tobytes())


for src_name, dst_name, dur in SPECS:
	src = ROOT / src_name
	samples, rate = sf.read(str(src), always_2d=True, dtype="float32")
	mono = samples.mean(axis=1)
	clip = loudest_window(mono, rate, dur)
	out = ROOT / dst_name
	write_wav(out, clip, rate)
	print(dst_name, "sec", round(clip.size / rate, 2), "rate", rate)

for p in ROOT.glob("*_raw_*"):
	p.unlink()
	print("removed", p.name)
