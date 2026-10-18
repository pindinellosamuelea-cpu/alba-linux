#!/usr/bin/env python3
"""Genera lo sfondo e il logo PNG di Alba Linux (richiede Pillow).

Uso:  python3 strumenti/genera-grafica.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "config", "includes.chroot")
W, H = 2560, 1440
random.seed(7)


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def gradiente(stops, t):
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        if t <= p1:
            return mix(c0, c1, (t - p0) / (p1 - p0) if p1 > p0 else 0)
    return stops[-1][1]


def sfondo():
    orizzonte = int(H * 0.66)
    cielo = [(0.0, hexrgb("#0b0f29")), (0.35, hexrgb("#1c1a46")), (0.62, hexrgb("#4a2c5e")),
             (0.85, hexrgb("#b4506a")), (1.0, hexrgb("#ff9a5a"))]
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = min(y / orizzonte, 1.0)
        base = gradiente(cielo, t)
        for x in range(W):
            # leggero rumore per evitare bande di colore (sfumature fluide)
            n = random.uniform(-1.2, 1.2)
            px[x, y] = tuple(int(max(0, min(255, c + n))) for c in base)

    # stelle
    d = ImageDraw.Draw(img)
    for _ in range(260):
        x, y = random.randrange(W), random.randrange(int(H * 0.45))
        a = random.uniform(0.25, 1.0) * (1 - y / (H * 0.45))
        r = random.choice([1, 1, 1, 2])
        c = tuple(int(v * a + px[x, y][i] * (1 - a)) for i, v in enumerate((255, 240, 230)))
        d.ellipse([x - r, y - r, x + r, y + r], fill=c)

    # alone del sole
    alone = Image.new("RGB", (W, H), (0, 0, 0))
    da = ImageDraw.Draw(alone)
    cx, cy = int(W * 0.62), orizzonte
    for i in range(60, 0, -1):
        r = int(18 * i)
        k = (1 - i / 60) ** 2.2
        da.ellipse([cx - r * 1.6, cy - r, cx + r * 1.6, cy + r],
                   fill=tuple(int(v * k) for v in (255, 130, 70)))
    alone = alone.filter(ImageFilter.GaussianBlur(60))
    img = add(img, alone)

    # sole che sorge
    sole = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ds = ImageDraw.Draw(sole)
    R = 170
    for y in range(cy - R, cy + 1):
        t = (y - (cy - R)) / R
        c = gradiente([(0, hexrgb("#ffe08a")), (0.6, hexrgb("#ffa055")), (1, hexrgb("#ff6a4a"))], t)
        half = math.sqrt(max(R * R - (cy - y) ** 2, 0))
        ds.line([(cx - half, y), (cx + half, y)], fill=tuple(int(v) for v in c) + (255,))
    img = Image.alpha_composite(img.convert("RGBA"), sole)

    # colline a strati
    strati = [
        (orizzonte - 10, 70, 0.0021, 1.3, "#5a2f58"),
        (orizzonte + 40, 90, 0.0016, 4.1, "#3a2148"),
        (orizzonte + 120, 110, 0.0012, 2.2, "#221636"),
        (orizzonte + 230, 90, 0.0019, 5.5, "#130e24"),
    ]
    for base_y, amp, freq, fase, col in strati:
        strato = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        dl = ImageDraw.Draw(strato)
        punti = [(0, H)]
        for x in range(0, W + 8, 8):
            y = base_y - amp * (0.6 * math.sin(x * freq + fase) + 0.4 * math.sin(x * freq * 2.3 + fase * 1.7))
            punti.append((x, y))
        punti.append((W, H))
        dl.polygon(punti, fill=hexrgb(col) + (255,))
        strato = strato.filter(ImageFilter.GaussianBlur(1.2))
        img = Image.alpha_composite(img, strato)

    # riflesso del sole sul primo strato (linee come nel logo)
    dr = ImageDraw.Draw(img)
    for i, (w, a) in enumerate([(300, 120), (190, 90), (100, 60)]):
        y = orizzonte + 26 + i * 26
        dr.rounded_rectangle([cx - w, y, cx + w, y + 7], radius=4, fill=(255, 150, 90, a))
    return img.convert("RGB")


def add(a, b):
    from PIL import ImageChops
    return ImageChops.add(a, b)


def logo(lato):
    S = 4  # supersampling per bordi morbidi
    n = lato * S
    k = n / 256
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    # fondo arrotondato con sfumatura
    fondo = Image.new("RGBA", (n, n))
    pf = ImageDraw.Draw(fondo)
    for y in range(n):
        c = gradiente([(0, hexrgb("#151a3d")), (0.6, hexrgb("#2d2560")), (1, hexrgb("#5a3360"))], y / n)
        pf.line([(0, y), (n, y)], fill=tuple(int(v) for v in c) + (255,))
    maschera = Image.new("L", (n, n), 0)
    ImageDraw.Draw(maschera).rounded_rectangle([8 * k, 8 * k, 248 * k, 248 * k], radius=56 * k, fill=255)
    img.paste(fondo, (0, 0), maschera)
    d = ImageDraw.Draw(img)
    sole = lambda t: tuple(int(v) for v in gradiente(
        [(0, hexrgb("#ffd06a")), (0.55, hexrgb("#ff8a4c")), (1, hexrgb("#e8475f"))], t)) + (255,)
    # raggi
    for x1, y1, x2, y2 in [(128, 40, 128, 60), (62, 70, 75, 84), (194, 70, 181, 84),
                           (36, 128, 54, 132), (220, 128, 202, 132)]:
        d.line([(x1 * k, y1 * k), (x2 * k, y2 * k)], fill=sole(0.2), width=int(11 * k))
        for (x, y) in [(x1, y1), (x2, y2)]:
            r = 5.5 * k
            d.ellipse([x * k - r, y * k - r, x * k + r, y * k + r], fill=sole(0.2))
    # sole
    cx, cy, R = 128 * k, 154 * k, 60 * k
    for yy in range(int(cy - R), int(cy)):
        half = math.sqrt(max(R * R - (cy - yy) ** 2, 0))
        d.line([(cx - half, yy), (cx + half, yy)], fill=sole((yy - (cy - R)) / R))
    # linee dell'orizzonte
    for x1, x2, y, col in [(40, 216, 160, "#ffb27a"), (78, 178, 182, "#ff8a4c"), (104, 152, 203, "#e8475f")]:
        d.rounded_rectangle([x1 * k - 4 * k, (y - 4) * k, x2 * k + 4 * k, (y + 4) * k], radius=4 * k,
                            fill=hexrgb(col) + (255,))
    return img.resize((lato, lato), Image.LANCZOS)


def logo_avvio():
    img = Image.new("RGBA", (420, 240), (0, 0, 0, 0))
    img.alpha_composite(logo(150), (135, 0))
    try:
        font = ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-SemiBold.otf", 46)
    except OSError:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 46)
    d = ImageDraw.Draw(img)
    testo = "Alba"
    w = d.textlength(testo, font=font)
    d.text(((420 - w) / 2, 168), testo, font=font, fill=(255, 236, 224, 255))
    return img


if __name__ == "__main__":
    os.makedirs(os.path.join(BASE, "usr/share/backgrounds/alba"), exist_ok=True)
    os.makedirs(os.path.join(BASE, "usr/share/alba"), exist_ok=True)
    sfondo().save(os.path.join(BASE, "usr/share/backgrounds/alba/alba.png"), optimize=True)
    logo(256).save(os.path.join(BASE, "usr/share/alba/logo.png"))
    logo_avvio().save(os.path.join(BASE, "usr/share/alba/logo-avvio.png"))
    print("Grafica generata.")
