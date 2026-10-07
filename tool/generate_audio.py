#!/usr/bin/env python3
"""Synthesizes the original UI sound effects and the background music loop (no external assets)."""
import wave, numpy as np, os

def write(path, data, sr):
    data = np.clip(data, -1, 1)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes((data * 32767).astype("<i2").tobytes())

SR = 22050
def tone(freq, dur, vol=0.5, sr=SR, harm=(1.0, 0.3, 0.1), attack=0.01, decay=6.0):
    t = np.arange(int(dur * sr)) / sr
    s = sum(h * np.sin(2 * np.pi * freq * (i + 1) * t) for i, h in enumerate(harm))
    env = np.minimum(t / attack, 1.0) * np.exp(-decay * t)
    return vol * s / sum(harm) * env

def seq(notes, gap, sr=SR):
    total = int((max(s for s, _ in notes) + max(len(x) / sr for _, x in notes)) * sr) + 1
    out = np.zeros(total)
    for start, x in notes:
        i = int(start * sr); out[i:i + len(x)] += x[: total - i]
    return out

n = lambda m: 440 * 2 ** ((m - 69) / 12)  # midi -> Hz
write("assets/audio/ui/tap.wav", tone(900, 0.07, 0.4, decay=40), SR)
write("assets/audio/ui/correct.wav", seq([(0, tone(n(72), .25, .5)), (0.12, tone(n(76), .3, .5))], 0), SR)
write("assets/audio/ui/oops.wav", seq([(0, tone(n(62), .22, .35, harm=(1, .1))), (0.14, tone(n(57), .3, .35, harm=(1, .1)))], 0), SR)
write("assets/audio/rewards/star.wav", seq([(i * 0.07, tone(n(79 + i * 3), .25, .4, decay=8)) for i in range(5)], 0), SR)
write("assets/audio/rewards/win.wav", seq([(0, tone(n(72), .3, .5)), (0.15, tone(n(76), .3, .5)), (0.3, tone(n(79), .3, .5)), (0.45, tone(n(84), .8, .55, decay=3))], 0), SR)

# Background music: 24 s calm C-major-pentatonic loop, 16 kHz mono to keep the APK small.
MSR = 16000; bpm = 96; beat = 60 / bpm; bars = 12
total = int(bars * 4 * beat * MSR) + MSR
music = np.zeros(total)
penta = [60, 62, 64, 67, 69, 72, 74, 76]
chords = [[48, 55, 64], [53, 60, 69], [55, 62, 71], [48, 55, 64]]
rng = np.random.default_rng(7)
for bar in range(bars):
    chord = chords[bar % 4]
    for k, m in enumerate(chord):
        music[int((bar * 4 * beat) * MSR):][: int(4 * beat * MSR)] += 0  # no-op, keeps indexing explicit
        x = tone(n(m), 4 * beat, 0.10, MSR, harm=(1, .15), attack=0.2, decay=0.6)
        i = int(bar * 4 * beat * MSR); music[i:i + len(x)] += x[: total - i]
    for step in range(8):
        m = penta[int(rng.integers(0, len(penta)))] if step % 2 == 0 else penta[(bar + step) % len(penta)]
        x = tone(n(m), 0.5, 0.16, MSR, harm=(1, .25, .05), decay=5)
        i = int((bar * 4 + step * 0.5) * beat * MSR); music[i:i + len(x)] += x[: total - i]
music = music[: int(bars * 4 * beat * MSR)]
fade = int(0.05 * MSR); music[:fade] *= np.linspace(0, 1, fade); music[-fade:] *= np.linspace(1, 0, fade)
music /= max(1e-6, np.abs(music).max()) / 0.8
write("assets/audio/music/sely_theme.wav", music, MSR)
print("audio ok")
