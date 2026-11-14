"""Workshop GP SFX v2: thiết kế lại hiệu ứng âm thanh bằng tổng hợp có lớp.

Khác bản v1 (sine + envelope): mỗi âm có transient, thân âm (marimba / chuông FM /
kèn đồng additive), nhiễu lọc (whoosh, lấp lánh), bão hoà nhẹ và reverb ngắn.
Tất cả là âm tổng hợp nguyên bản, không dùng sample ngoài.

Chạy:  python build_sfx_v2.py --out <thư mục>     (mặc định: ../audio_v2)
"""
from __future__ import annotations

import argparse
import json
import math
import wave
from pathlib import Path

import numpy as np
from scipy import signal as sps

RATE = 44100
rng = np.random.default_rng(2026)


# ------------------------------------------------------------------ cơ bản

def n_(sec: float) -> int:
    return int(round(sec * RATE))


def tt(sec: float) -> np.ndarray:
    return np.arange(n_(sec)) / RATE


def midi(n: float) -> float:
    return 440.0 * 2 ** ((n - 69) / 12)


def env_ad(sec: float, attack: float, decay: float) -> np.ndarray:
    """Attack tuyến tính rồi tắt dần theo hàm mũ (decay = thời gian giảm 60 dB)."""
    t = tt(sec)
    a = np.minimum(t / max(attack, 1e-4), 1.0)
    d = np.exp(-6.9 * np.maximum(t - attack, 0) / max(decay, 1e-4))
    return a * d


def fade_out(x: np.ndarray, sec: float = 0.01) -> np.ndarray:
    k = min(len(x), n_(sec))
    if k > 0:
        ramp = np.linspace(1, 0, k) ** 2
        x[-k:] *= ramp if x.ndim == 1 else ramp[:, None]
    return x


def place(dst: np.ndarray, src: np.ndarray, at_sec: float, gain: float = 1.0, pan: float = 0.0) -> None:
    """Trộn src (mono hoặc stereo) vào dst stereo tại thời điểm at_sec, pan -1..1 (equal power)."""
    s = n_(at_sec)
    if s >= len(dst):
        return
    if src.ndim == 1:
        gl, gr = math.cos((pan + 1) * math.pi / 4), math.sin((pan + 1) * math.pi / 4)
        src = np.stack([src * gl, src * gr], axis=1) * math.sqrt(2)
    e = min(len(dst), s + len(src))
    dst[s:e] += src[: e - s] * gain


def canvas(sec: float) -> np.ndarray:
    return np.zeros((n_(sec), 2))


def bp(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    sos = sps.butter(order, [lo, min(hi, RATE / 2 - 100)], btype="band", fs=RATE, output="sos")
    return sps.sosfilt(sos, x, axis=0)


def lp(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    sos = sps.butter(order, min(f, RATE / 2 - 100), btype="low", fs=RATE, output="sos")
    return sps.sosfilt(sos, x, axis=0)


def hp(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    sos = sps.butter(order, f, btype="high", fs=RATE, output="sos")
    return sps.sosfilt(sos, x, axis=0)


def svf_sweep(x: np.ndarray, f0: float, f1: float, q: float = 2.0, curve: float = 1.0) -> np.ndarray:
    """Band-pass state-variable quét tần số f0 -> f1 (theo log), dùng cho whoosh."""
    n = len(x)
    pos = (np.arange(n) / max(n - 1, 1)) ** curve
    freqs = f0 * (f1 / f0) ** pos
    g = np.tan(np.pi * np.minimum(freqs, RATE * 0.45) / RATE)
    k = 1.0 / q
    out = np.empty(n)
    ic1 = ic2 = 0.0
    for i in range(n):
        gi = g[i]
        a1 = 1.0 / (1.0 + gi * (gi + k))
        v3 = x[i] - ic2
        v1 = a1 * ic1 + gi * a1 * v3
        v2 = ic2 + gi * v1
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        out[i] = v1
    return out


def noise(sec: float) -> np.ndarray:
    return rng.standard_normal(n_(sec))


# ------------------------------------------------------------------ nhạc cụ

def marimba(f: float, sec: float = 0.5, bright: float = 1.0) -> np.ndarray:
    """Thanh gỗ: partial 1, 3.99, 10.7 tắt nhanh dần + tiếng gõ ngắn."""
    t = tt(sec)
    x = np.sin(2 * np.pi * f * t) * np.exp(-t * 9)
    x += 0.35 * bright * np.sin(2 * np.pi * f * 3.99 * t) * np.exp(-t * 28)
    x += 0.12 * bright * np.sin(2 * np.pi * f * 10.7 * t) * np.exp(-t * 70)
    strike = bp(noise(0.012), 1500, 6000) * np.exp(-tt(0.012) * 400) * 0.25 * bright
    x[: len(strike)] += strike
    x *= np.minimum(t / 0.0015, 1)
    return fade_out(x, 0.03)


def bell(f: float, sec: float = 1.0, ratio: float = 3.5, index: float = 2.2, decay: float = 3.5) -> np.ndarray:
    """Chuông FM (kiểu glockenspiel / celesta), chỉ số điều chế giảm dần -> trong dần."""
    t = tt(sec)
    idx = index * np.exp(-t * 6)
    x = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * ratio * t))
    x += 0.25 * np.sin(2 * np.pi * f * 2.0 * t) * np.exp(-t * decay * 2.5)
    x *= np.minimum(t / 0.001, 1) * np.exp(-t * decay)
    return fade_out(x, 0.05)


def brass(freqs: list[float], sec: float, attack: float = 0.05, release: float = 0.25, peak_bright: float = 7.0) -> np.ndarray:
    """Kèn đồng additive: độ sáng (số hoạ âm) nở lên lúc attack rồi dịu lại; có rung nhẹ."""
    t = tt(sec)
    bright = 1.5 + peak_bright * np.minimum(t / attack, 1) * np.exp(-t * 2.5)
    amp = np.minimum(t / attack, 1) * np.minimum(np.maximum(sec - t, 0) / release, 1)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(t / 0.25, 1)
    out = np.zeros_like(t)
    for j, f in enumerate(freqs):
        det = 1 + (j - len(freqs) / 2) * 0.0015
        ph = 2 * np.pi * np.cumsum(f * det * vib) / RATE
        for h in range(1, 30):
            if f * h > 14000:
                break
            out += np.sin(h * ph) * (1 / h) * np.exp(-(h - 1) / bright)
    out = np.tanh(out * amp * 0.6)
    return out


def sparkle(sec: float, count: int, f_lo: float = 2500, f_hi: float = 6500, rise: bool = True) -> np.ndarray:
    """Lấp lánh: nhiều chuông nhỏ ngẫu nhiên, stereo."""
    out = canvas(sec + 0.4)
    for i in range(count):
        pos = (i / max(count - 1, 1)) if rise else rng.random()
        at = pos * sec * 0.9 + rng.random() * 0.03
        f = f_lo * (f_hi / f_lo) ** (pos if rise else rng.random())
        place(out, bell(f * (1 + rng.random() * 0.02), 0.35, 2.0, 0.8, 9), at, 0.18, rng.uniform(-0.8, 0.8))
    return out


def whoosh(sec: float, f0: float, f1: float, q: float = 1.8) -> np.ndarray:
    t = tt(sec)
    x = svf_sweep(noise(sec), f0, f1, q)
    return x * np.sin(np.pi * t / sec) ** 2


def cymbal(sec: float, swell: bool = False) -> np.ndarray:
    t = tt(sec)
    x = hp(noise(sec), 5000, 4) + 0.4 * bp(noise(sec), 3000, 9000)
    e = (np.minimum(t / sec, 1) ** 2) if swell else np.exp(-t * 4) * np.minimum(t / 0.002, 1)
    return x * e


def room(x: np.ndarray, sec: float = 0.6, wet: float = 0.18, damp: float = 6000, predelay: float = 0.008) -> np.ndarray:
    """Reverb bằng chập với IR nhiễu tắt dần, hai kênh khác nhau để có độ rộng stereo."""
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    t = tt(sec)
    tail = np.zeros((n_(sec) + n_(predelay), 2))
    for c in range(2):
        ir = lp(rng.standard_normal(len(t)), damp, 1) * np.exp(-6.9 * t / sec)
        ir /= np.sqrt(np.sum(ir ** 2))
        tail[n_(predelay):, c] = ir
    out = np.zeros((len(x) + len(tail), 2))
    out[: len(x)] += x
    for c in range(2):
        conv = sps.fftconvolve(x[:, c], tail[:, c])
        out[: len(conv), c] += wet * conv
    return out


def master(x: np.ndarray, peak: float, sat: float = 1.2) -> np.ndarray:
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    x = hp(x, 70, 2)
    x = x - np.mean(x, axis=0)
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m
    x = np.tanh(x * sat) / np.tanh(sat)
    # Cắt đuôi im lặng (< -60 dB) rồi fade cuối.
    mag = np.max(np.abs(x), axis=1)
    idx = np.nonzero(mag > 0.001)[0]
    end = min(len(x), (idx[-1] + n_(0.02)) if len(idx) else len(x))
    x = fade_out(x[:end].copy(), 0.02)
    x[: n_(0.0005)] *= np.linspace(0, 1, n_(0.0005))[:, None]
    return x * peak


# ------------------------------------------------------------------ các cue

def ui_click():
    # Tiếng bấm "xúc giác": tick nhiễu cao + pop có pitch rơi + thân gỗ nhẹ.
    o = canvas(0.12)
    tick = bp(noise(0.006), 2500, 9000) * np.exp(-tt(0.006) * 900)
    t = tt(0.05)
    pop = np.sin(2 * np.pi * np.cumsum(900 + 1400 * np.exp(-t * 180)) / RATE) * np.exp(-t * 110)
    place(o, tick, 0, 0.7)
    place(o, pop, 0, 0.8)
    place(o, marimba(midi(84), 0.1, 0.4), 0.001, 0.25)
    return master(room(o, 0.25, 0.08), 0.42)


def ui_tab():
    o = canvas(0.25)
    place(o, bp(noise(0.005), 3000, 9000) * np.exp(-tt(0.005) * 900), 0, 0.4)
    place(o, marimba(midi(76), 0.22, 0.8), 0, 0.8, -0.1)
    place(o, marimba(midi(83), 0.2, 0.5), 0.035, 0.45, 0.15)
    return master(room(o, 0.35, 0.12), 0.40)


def ui_back():
    o = canvas(0.3)
    place(o, marimba(midi(79), 0.22, 0.7), 0, 0.7, 0.1)
    place(o, marimba(midi(74), 0.25, 0.7), 0.055, 0.75, -0.1)
    return master(room(o, 0.35, 0.12), 0.40)


def ui_confirm():
    o = canvas(0.45)
    place(o, marimba(midi(72), 0.25, 0.8), 0, 0.7, -0.15)
    place(o, marimba(midi(79), 0.3, 0.8), 0.06, 0.8, 0.15)
    place(o, bell(midi(91), 0.4, 3.5, 1.2, 8), 0.06, 0.18)
    return master(room(o, 0.45, 0.15), 0.44)


def ui_error():
    # Hai tiếng "thụp" trầm, mờ (lowpass) – báo lỗi mà không chói tai.
    o = canvas(0.4)
    for i, at in enumerate([0.0, 0.12]):
        t = tt(0.16)
        f = midi(46 - i)
        x = sum(np.sin(2 * np.pi * f * h * t) / h for h in (1, 3, 5, 7))
        x = lp(x * np.exp(-t * 20) * np.minimum(t / 0.003, 1), 900, 2)
        place(o, x, at, 0.8)
        place(o, lp(noise(0.02), 1200) * np.exp(-tt(0.02) * 200), at, 0.25)
    return master(room(o, 0.3, 0.08), 0.42, 1.6)


def upgrade():
    # Whoosh đi lên + arpeggio gỗ + chuông lấp lánh ở đỉnh.
    o = canvas(1.0)
    place(o, whoosh(0.4, 400, 5000), 0, 0.22)
    for i, n in enumerate([69, 73, 76, 81]):
        place(o, marimba(midi(n), 0.45, 0.9), 0.06 + i * 0.065, 0.55, -0.3 + i * 0.2)
    place(o, bell(midi(93), 0.8, 3.5, 2.0, 4), 0.28, 0.35)
    place(o, bell(midi(100), 0.6, 2.0, 1.0, 6), 0.3, 0.15, 0.4)
    place(o, sparkle(0.3, 6, 3500, 7000), 0.28, 0.6)
    return master(room(o, 0.9, 0.22), 0.55)


def reward():
    o = canvas(1.3)
    for i, n in enumerate([72, 76, 79, 84]):
        place(o, bell(midi(n + 12), 1.0, 3.5, 2.0, 3.0), i * 0.075, 0.45, -0.3 + i * 0.2)
        place(o, marimba(midi(n), 0.4, 0.6), i * 0.075, 0.35)
    place(o, sparkle(0.5, 10, 3000, 8000), 0.2, 0.7)
    place(o, cymbal(0.5, swell=True), 0, 0.03)
    return master(room(o, 1.1, 0.25), 0.58)


def unlock():
    # Chốt khoá cơ khí (2 tiếng clack) rồi hợp âm chuông mở ra.
    o = canvas(1.3)
    for at, f in [(0.0, 2200), (0.07, 1600)]:
        c = bp(noise(0.03), f, f * 3, 2) * np.exp(-tt(0.03) * 160)
        t = tt(0.04)
        body = np.sin(2 * np.pi * (f / 4) * t) * np.exp(-t * 120)
        place(o, c, at, 0.6)
        place(o, body, at, 0.4)
    place(o, whoosh(0.35, 800, 6000, 2.5), 0.08, 0.15)
    for i, n in enumerate([67, 71, 74, 79]):
        place(o, bell(midi(n + 12), 1.1, 3.5, 1.8, 2.8), 0.16 + i * 0.03, 0.32, -0.3 + i * 0.2)
    place(o, sparkle(0.4, 8, 3500, 8000), 0.2, 0.5)
    return master(room(o, 1.0, 0.22), 0.56)


def coin_pickup():
    # Hai nốt chuông sáng (B5 -> E6) – kiểu nhặt xu, có tiếng kim loại.
    o = canvas(0.7)
    place(o, bell(midi(83), 0.18, 1.41, 3.0, 9), 0, 0.5, -0.1)
    place(o, bell(midi(88), 0.6, 1.41, 3.0, 4.5), 0.07, 0.6, 0.1)
    place(o, bell(midi(100), 0.4, 3.5, 1.0, 8), 0.07, 0.15, 0.3)
    place(o, bp(noise(0.004), 5000, 12000) * np.exp(-tt(0.004) * 1200), 0, 0.3)
    return master(room(o, 0.5, 0.15), 0.52)


def daily_gift():
    o = canvas(1.4)
    place(o, whoosh(0.5, 300, 7000, 1.5), 0, 0.22)
    place(o, cymbal(0.45, swell=True), 0, 0.05)
    for i, n in enumerate([72, 79, 84, 88, 91]):
        place(o, bell(midi(n + 12), 0.9, 3.5, 1.6, 3.2), 0.35 + i * 0.06, 0.32, -0.4 + i * 0.2)
    place(o, marimba(midi(72), 0.5, 0.7), 0.35, 0.45)
    place(o, marimba(midi(60), 0.5, 0.4), 0.35, 0.4)
    place(o, sparkle(0.6, 14, 2500, 9000), 0.35, 0.75)
    return master(room(o, 1.2, 0.28), 0.58)


def mission_complete():
    o = canvas(1.4)
    place(o, brass([midi(67), midi(72), midi(76)], 0.16, 0.02, 0.06), 0, 0.5)
    place(o, brass([midi(72), midi(76), midi(79), midi(84)], 0.75, 0.03, 0.4), 0.18, 0.6)
    place(o, bell(midi(96), 1.0, 3.5, 2.0, 3), 0.18, 0.2, 0.3)
    place(o, cymbal(0.9), 0.18, 0.08)
    place(o, sparkle(0.4, 6, 3500, 7500), 0.2, 0.45)
    return master(room(o, 1.0, 0.22), 0.48)


def promotion():
    # Fanfare lên hạng: 3 nốt kèn đồng đi lên + hợp âm lớn + cymbal + lấp lánh.
    o = canvas(2.0)
    place(o, cymbal(0.4, swell=True), 0, 0.06)
    for i, n in enumerate([67, 72, 76]):
        place(o, brass([midi(n), midi(n - 12)], 0.13, 0.015, 0.05), 0.0 + i * 0.13, 0.5)
    place(o, brass([midi(60), midi(67), midi(72), midi(76), midi(79)], 1.1, 0.03, 0.6), 0.4, 0.65)
    t = tt(0.25)
    timp = np.sin(2 * np.pi * np.cumsum(midi(36) * (1 + 0.3 * np.exp(-t * 30))) / RATE) * np.exp(-t * 9)
    place(o, timp, 0.4, 0.7)
    place(o, cymbal(1.3), 0.4, 0.1)
    place(o, sparkle(0.7, 14, 3000, 9000), 0.45, 0.6)
    return master(room(o, 1.3, 0.25), 0.5)


def finish():
    # Về đích: fanfare + cờ phất (whoosh) + cymbal.
    o = canvas(2.0)
    place(o, whoosh(0.3, 600, 4000, 1.2), 0, 0.2)
    place(o, brass([midi(72), midi(79)], 0.12, 0.012, 0.04), 0.05, 0.5)
    place(o, brass([midi(72), midi(79)], 0.12, 0.012, 0.04), 0.2, 0.5)
    place(o, brass([midi(65), midi(72), midi(77), midi(81)], 0.18, 0.015, 0.06), 0.35, 0.55)
    place(o, brass([midi(67), midi(72), midi(76), midi(79), midi(84)], 1.0, 0.03, 0.55), 0.55, 0.65)
    place(o, cymbal(1.2), 0.55, 0.1)
    place(o, sparkle(0.6, 10, 3000, 8500), 0.6, 0.5)
    return master(room(o, 1.2, 0.24), 0.5)


def start_beep(f: float, sec: float) -> np.ndarray:
    """Đèn xuất phát: tiếng beep điện tử sạch (vuông mềm, lọc), giống bảng đèn thật."""
    t = tt(sec)
    x = sum(np.sin(2 * np.pi * f * h * t) / h for h in (1, 3, 5))
    x = lp(x, 4000, 2) * np.minimum(t / 0.004, 1) * np.minimum(np.maximum(sec - t, 0) / 0.02, 1)
    return x


def countdown_tick():
    o = canvas(0.4)
    place(o, start_beep(784, 0.16), 0, 0.8)
    return master(room(o, 0.5, 0.2, 5000, 0.02), 0.32, 1.0)


def countdown_go():
    o = canvas(1.2)
    place(o, start_beep(1568, 0.5), 0, 0.7)
    place(o, start_beep(784, 0.5), 0, 0.3)
    place(o, whoosh(0.6, 200, 3000, 1.2), 0.05, 0.18)
    # Gầm động cơ bật lên ngắn.
    t = tt(0.7)
    f = 60 + 140 * (1 - np.exp(-t * 6))
    ph = 2 * np.pi * np.cumsum(f) / RATE
    eng = sum(np.sin(h * ph) / h for h in range(1, 14))
    eng = lp(eng * (1 + 0.3 * np.sin(ph * 0.5)), 2200) * np.sin(np.pi * t / 0.7) ** 0.5
    place(o, np.tanh(eng * 1.5), 0.05, 0.35)
    return master(room(o, 0.7, 0.2, 5000, 0.02), 0.42, 1.1)


def tyre_squeak():
    # Rít lốp: nhiễu dải hẹp có tâm dao động ngẫu nhiên + thành phần tonal rung.
    sec = 0.45
    t = tt(sec)
    wob = np.cumsum(rng.standard_normal(len(t))) / RATE * 60
    wob = wob - np.linspace(wob[0], wob[-1], len(t))
    fc = 1900 + 250 * np.sin(2 * np.pi * 7 * t) + 300 * wob
    tone = np.sin(2 * np.pi * np.cumsum(fc) / RATE)
    tone += 0.3 * np.sin(2 * np.pi * np.cumsum(fc * 2.02) / RATE)
    nz = svf_sweep(noise(sec), 2300, 1700, 6)
    e = np.minimum(t / 0.03, 1) * np.minimum(np.maximum(sec - t, 0) / 0.12, 1)
    x = (0.5 * tone * (0.7 + 0.3 * rng.random(len(t))) + 1.2 * nz) * e
    return master(room(x, 0.4, 0.12), 0.32, 1.4)


def car_pass():
    # Xe vụt qua: động cơ có hiệu ứng Doppler (cao -> thấp), to dần rồi nhỏ, pan trái -> phải.
    sec = 1.1
    t = tt(sec)
    c = sec / 2
    f = 150 * (1 + 0.18 * np.tanh(-(t - c) * 8))
    ph = 2 * np.pi * np.cumsum(f) / RATE
    eng = sum(np.sin(h * ph + 0.3 * np.sin(ph * 0.5)) / h ** 0.8 for h in range(1, 20))
    eng = np.tanh(eng * 0.8)
    dist = 1 / (0.15 + ((t - c) * 3) ** 2)
    bright = lp(eng, 1200) + (dist / dist.max()) * hp(eng, 1200) * 0.6
    wind = bp(noise(sec), 300, 3000) * 0.4
    x = (bright + wind) * dist / dist.max()
    pan = np.tanh((t - c) * 4)
    st = np.stack([x * np.cos((pan + 1) * np.pi / 4), x * np.sin((pan + 1) * np.pi / 4)], axis=1)
    return master(room(st, 0.5, 0.1), 0.5, 1.3)


CUES = {
    "ui_click": ui_click, "ui_tab": ui_tab, "ui_back": ui_back, "ui_confirm": ui_confirm,
    "ui_error": ui_error, "upgrade": upgrade, "reward": reward, "unlock": unlock,
    "mission_complete": mission_complete, "promotion": promotion, "coin_pickup": coin_pickup,
    "daily_gift": daily_gift, "finish": finish, "countdown_tick": countdown_tick,
    "countdown_go": countdown_go, "tyre_squeak": tyre_squeak, "car_pass": car_pass,
}


def write_wav(path: Path, data: np.ndarray) -> dict:
    pcm = np.rint(np.clip(data, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(pcm.tobytes())
    return {
        "path": "audio/" + path.name, "duration": round(len(data) / RATE, 4), "sample_rate": RATE,
        "channels": 2, "bits": 16, "loop": False,
        "peak": round(float(np.max(np.abs(pcm))) / 32767, 5),
        "rms": round(float(np.sqrt(np.mean(data ** 2))), 5),
        "origin": "original layered procedural synthesis v2, not a recording",
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(Path(__file__).resolve().parent.parent / "audio_v2"))
    ap.add_argument("--only", nargs="*")
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    records = []
    for name, fn in CUES.items():
        if args.only and name not in args.only:
            continue
        rec = write_wav(out / f"{name}.wav", fn())
        records.append(rec)
        print(f"{name:18s} {rec['duration']:.3f}s peak {rec['peak']:.3f} rms {rec['rms']:.3f}")
    (out / "catalog_v2.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
