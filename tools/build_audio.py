#!/usr/bin/env python3
"""Procedural CC0 audio for Cats Defender (WAV, 22050 Hz mono 16-bit).

SFX: shot, enemy_die, merge, ui_click, buy, repair, explosion, spikes, boxer, win, lose.
Music: menu (slow pad loop), battle (uptempo arp loop).
"""
import math
import os
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC = os.path.join(ROOT, "assets", "audio", "music")
os.makedirs(SFX, exist_ok=True)
os.makedirs(MUSIC, exist_ok=True)
SR = 22050


def write_wav(path, samples):
    pcm = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 30000)))) for s in samples)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm)
    print("[audio]", os.path.relpath(path, ROOT))


def tone(freq, dur, vol=0.5, shape="square", freq_end=None, delay_silence=0.0):
    n = int(SR * (dur + delay_silence))
    out = [0.0] * int(SR * delay_silence)
    for i in range(int(SR * dur)):
        t = i / SR
        f = freq if freq_end is None else freq + (freq_end - freq) * (t / dur)
        ph = f * t
        if shape == "square":
            v = 1.0 if (ph % 1.0) < 0.5 else -1.0
        elif shape == "sine":
            v = math.sin(2 * math.pi * ph)
        else:  # noise
            v = math.sin(2 * math.pi * ph * 1.7) * math.sin(2 * math.pi * ph * 0.31)
        env = max(0.0, 1.0 - t / dur) ** 1.5
        out.append(v * vol * env)
    return out[:n]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    m = max(abs(s) for s in out) or 1.0
    if m > 0.95:
        out = [s / m * 0.95 for s in out]
    return out


SFX_DEFS = {
    "shot": tone(880, 0.08, 0.35, "square", 440),
    "enemy_die": tone(300, 0.25, 0.4, "noise", 80),
    "merge": mix(tone(520, 0.12, 0.35, "sine", 780), tone(780, 0.18, 0.3, "sine", 1040, 0.08)),
    "ui_click": tone(1200, 0.05, 0.3, "sine"),
    "buy": mix(tone(700, 0.1, 0.3, "sine"), tone(1050, 0.12, 0.3, "sine", None, 0.07)),
    "repair": tone(500, 0.2, 0.3, "square", 900),
    "explosion": tone(120, 0.5, 0.6, "noise", 40),
    "spikes": tone(200, 0.3, 0.35, "square", 150),
    "boxer": mix(tone(150, 0.15, 0.5, "noise"), tone(98, 0.2, 0.4, "square", 60, 0.1)),
    "win": mix(tone(523, 0.15, 0.4, "sine"), tone(659, 0.15, 0.4, "sine", None, 0.15),
               tone(784, 0.3, 0.4, "sine", None, 0.3)),
    "lose": mix(tone(400, 0.25, 0.4, "sine", 300), tone(300, 0.4, 0.4, "sine", 200, 0.2)),
}


def arp(notes, bpm, dur_note=None, vol=0.3, shape="sine"):
    dur_note = dur_note or 60.0 / bpm / 2
    out = []
    for f in notes:
        out += tone(f, dur_note, vol, shape)
    return out


def scale_freqs(base, semis):
    return [base * 2 ** (s / 12) for s in semis]


battle = arp(list(scale_freqs(220, [0, 3, 7, 12, 7, 3]) * 4), BPM) if (BPM := 140) else []
menu = arp(list(scale_freqs(196, [0, 7, 12, 7]) * 4), 90, vol=0.25)

for sid, samples in SFX_DEFS.items():
    write_wav(os.path.join(SFX, f"{sid}.wav"), samples)
write_wav(os.path.join(MUSIC, "battle.wav"), battle)
write_wav(os.path.join(MUSIC, "menu.wav"), menu)
print("[audio] done")
