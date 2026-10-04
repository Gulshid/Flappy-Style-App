#!/usr/bin/env python3
"""
Generates every image and sound used by the game (original artwork and
synthesized audio, so there are no licence issues).

Run from the project root:   python3 tools/generate_assets.py
Needs:                       pip install pillow numpy

Output:  assets/images/*.png   assets/audio/*.wav
Edit the colours / frequencies below and re-run to restyle the game.
"""
import math
import os
import wave

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "assets", "images")
AUD = os.path.join(ROOT, "assets", "audio")
os.makedirs(IMG, exist_ok=True)
os.makedirs(AUD, exist_ok=True)

SS = 4  # supersampling factor for smooth edges


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


# ---------------------------------------------------------------- BIRD
def make_bird(name, wing_angle, wing_dy):
    W, H = 80, 64
    w, h = W * SS, H * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    outline = hexc("#7A4B00")
    lw = 3 * SS

    # body
    body = (0.04 * w, 0.08 * h, 0.84 * w, 0.92 * h)
    d.ellipse(body, fill=hexc("#FFD54F"), outline=outline, width=lw)
    # belly
    d.ellipse((0.20 * w, 0.52 * h, 0.76 * w, 0.88 * h), fill=hexc("#FFF3C4"))
    d.ellipse(body, outline=outline, width=lw)

    # beak
    beak = [(0.76 * w, 0.40 * h), (0.99 * w, 0.52 * h), (0.76 * w, 0.66 * h)]
    d.polygon(beak, fill=hexc("#FF7043"))
    d.line(beak + [beak[0]], fill=outline, width=int(lw * 0.7), joint="curve")

    # eye
    ex, ey, er = 0.62 * w, 0.34 * h, 0.15 * w
    d.ellipse((ex - er, ey - er, ex + er, ey + er), fill=(255, 255, 255, 255), outline=outline, width=int(lw * 0.7))
    pr = er * 0.45
    d.ellipse((ex + er * 0.15 - pr, ey - pr, ex + er * 0.15 + pr, ey + pr), fill=(20, 20, 20, 255))

    # wing (separate layer so it can be rotated)
    ww, wh = int(0.42 * w), int(0.26 * h)
    wing = Image.new("RGBA", (ww + 2 * lw, wh + 2 * lw), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wing)
    wd.ellipse((lw, lw, lw + ww, lw + wh), fill=hexc("#FFB300"), outline=outline, width=lw)
    wing = wing.rotate(wing_angle, expand=True, resample=Image.BICUBIC)
    cx, cy = 0.34 * w, (0.55 + wing_dy) * h
    img.alpha_composite(wing, (int(cx - wing.width / 2), int(cy - wing.height / 2)))

    img = img.resize((W, H), Image.LANCZOS)
    img.save(os.path.join(IMG, name))


make_bird("bird_0.png", wing_angle=35, wing_dy=-0.10)   # wing up
make_bird("bird_1.png", wing_angle=0, wing_dy=0.0)      # wing middle
make_bird("bird_2.png", wing_angle=-35, wing_dy=0.10)   # wing down


# ---------------------------------------------------------------- PIPES
def pipe_column_color(x, w):
    t = x / (w - 1)
    base = np.array(hexc("#73BF2E")[:3], dtype=float)
    light = np.array(hexc("#A5E85A")[:3], dtype=float)
    dark = np.array(hexc("#4E9A1B")[:3], dtype=float)
    edge = np.array(hexc("#2E5E0E")[:3], dtype=float)
    # vertical highlight and shadow strips
    if t < 0.06 or t > 0.94:
        c = edge
    elif 0.14 <= t < 0.30:
        c = light
    elif 0.78 <= t < 0.92:
        c = dark
    else:
        c = base
    return tuple(int(v) for v in c) + (255,)


def make_pipe_body():
    W, H = 128, 32
    img = Image.new("RGBA", (W, H))
    px = img.load()
    for x in range(W):
        col = pipe_column_color(x, W)
        for y in range(H):
            px[x, y] = col
    img.save(os.path.join(IMG, "pipe_body.png"))


def make_pipe_cap():
    W, H = 128, 40
    img = Image.new("RGBA", (W, H))
    px = img.load()
    for x in range(W):
        col = pipe_column_color(x, W)
        for y in range(H):
            # dark outline all around the cap
            if y < 5 or y >= H - 5:
                px[x, y] = hexc("#2E5E0E")
            else:
                px[x, y] = col
    # soft shadow where the cap meets the body (bottom edge of this image)
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle((0, H - 12, W, H - 6), fill=(0, 0, 0, 45))
    # This drawing has its body-side at the BOTTOM edge, so it is the cap of
    # the TOP pipe (the cap sits at the lower end of the top pipe).
    img.save(os.path.join(IMG, "pipe_cap_top.png"))
    # Flipped copy: body-side at the top edge = cap of the BOTTOM pipe.
    img.transpose(Image.FLIP_TOP_BOTTOM).save(os.path.join(IMG, "pipe_cap_bottom.png"))


make_pipe_body()
make_pipe_cap()


# ---------------------------------------------------------------- GROUND
def make_ground():
    W, H = 128, 64  # W is a multiple of both stripe (32) and grass (16) periods
    img = Image.new("RGBA", (W, H))
    px = img.load()
    dirt = hexc("#DED895")
    dirt_dark = hexc("#CDC57A")
    grass = hexc("#73BF2E")
    grass_light = hexc("#9BE04A")
    grass_dark = hexc("#4C8C1A")
    for x in range(W):
        depth = 10 + abs((x % 16) - 8) // 2     # jagged grass edge
        for y in range(H):
            if y < 3:
                px[x, y] = grass_light
            elif y < depth:
                px[x, y] = grass
            elif y < depth + 2:
                px[x, y] = grass_dark
            else:
                px[x, y] = dirt_dark if ((x + y) % 32) < 12 else dirt
    img.save(os.path.join(IMG, "ground.png"))


make_ground()


# ---------------------------------------------------------------- CLOUDS
def make_clouds():
    W, H = 512, 192
    w, h = W * SS, H * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    white = (255, 255, 255, 235)

    def cloud(cx, cy, r):
        parts = [(-1.2, 0.2, 0.7), (-0.4, -0.3, 1.0), (0.6, -0.1, 0.85), (1.3, 0.25, 0.6)]
        for ox in (-w, 0, w):  # wrap so the tile is seamless
            x0 = cx + ox
            for dx, dy, rr in parts:
                px_, py_, pr = x0 + dx * r, cy + dy * r, rr * r
                d.ellipse((px_ - pr, py_ - pr, px_ + pr, py_ + pr), fill=white)
            d.rectangle((x0 - 1.4 * r, cy + 0.1 * r, x0 + 1.6 * r, cy + 0.85 * r), fill=white)
        # flat bottom: erase anything below the base line
        for ox in (-w, 0, w):
            x0 = cx + ox
            d.rectangle((x0 - 3 * r, cy + 0.85 * r, x0 + 3 * r, h), fill=(0, 0, 0, 0))

    cloud(0.15 * w, 0.55 * h, 0.17 * h)
    cloud(0.42 * w, 0.30 * h, 0.11 * h)
    cloud(0.66 * w, 0.62 * h, 0.15 * h)
    cloud(0.90 * w, 0.28 * h, 0.09 * h)
    img = img.resize((W, H), Image.LANCZOS)
    img.save(os.path.join(IMG, "clouds.png"))


make_clouds()


# ---------------------------------------------------------------- HILLS
def make_hills():
    W, H = 512, 128
    w, h = W * SS, H * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def layer(color, base, a1, k1, p1, a2, k2, p2):
        pts = [(0, h)]
        for x in range(0, w + 1, 4):
            t = 2 * math.pi * x / w
            y = base - a1 * math.sin(k1 * t + p1) - a2 * math.sin(k2 * t + p2)
            pts.append((x, y * h))
        pts.append((w, h))
        d.polygon(pts, fill=color)

    # integer frequencies (k) over the tile width -> perfectly seamless
    layer(hexc("#A8E0B8"), 0.55, 0.14, 2, 0.4, 0.06, 5, 1.7)   # far hills
    layer(hexc("#82CF98"), 0.75, 0.10, 3, 2.0, 0.05, 7, 0.3)   # near hills
    img = img.resize((W, H), Image.LANCZOS)
    img.save(os.path.join(IMG, "hills.png"))


make_hills()


# ---------------------------------------------------------------- AUDIO
SR = 44100


def write_wav(name, samples):
    samples = np.asarray(samples, dtype=np.float64)
    samples = samples / max(1e-9, np.max(np.abs(samples))) * 0.6
    # 3 ms fade in/out to avoid clicks
    f = int(0.003 * SR)
    samples[:f] *= np.linspace(0, 1, f)
    samples[-f:] *= np.linspace(1, 0, f)
    data = (samples * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(AUD, name), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(data)


def t_axis(sec):
    return np.linspace(0, sec, int(SR * sec), endpoint=False)


def tone(freq, sec, decay=8.0, shape="sine"):
    t = t_axis(sec)
    ph = 2 * np.pi * freq * t
    if shape == "triangle":
        wave_ = 2 / np.pi * np.arcsin(np.sin(ph))
    elif shape == "square":
        wave_ = np.sign(np.sin(ph)) * 0.5
    else:
        wave_ = np.sin(ph)
    return wave_ * np.exp(-decay * t)


def sweep(f0, f1, sec, decay=10.0):
    t = t_axis(sec)
    freq = f0 + (f1 - f0) * (t / sec)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return np.sin(phase) * np.exp(-decay * t)


rng = np.random.default_rng(7)

# flap: quick rising chirp + a little air noise
flap = sweep(380, 820, 0.11, decay=14) + 0.15 * rng.standard_normal(int(SR * 0.11)) * np.exp(-30 * t_axis(0.11))
write_wav("flap.wav", flap)

# score: two bright ping notes
ping = np.concatenate([tone(988, 0.07, 10), tone(1319, 0.16, 9)])
write_wav("score.wav", ping)

# hit: noise burst + low thump
n = 0.18
hit = 0.7 * rng.standard_normal(int(SR * n)) * np.exp(-22 * t_axis(n)) + 1.0 * sweep(190, 70, n, decay=18)
write_wav("hit.wav", hit)

# game over: three falling notes
over = np.concatenate([
    tone(440, 0.16, 6, "triangle"),
    tone(349, 0.16, 6, "triangle"),
    tone(262, 0.34, 5, "triangle"),
])
write_wav("game_over.wav", over)

print("assets written to", os.path.join(ROOT, "assets"))
