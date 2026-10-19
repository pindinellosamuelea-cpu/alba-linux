#!/usr/bin/python3
"""Alba Linux - genera le icone della barra (Wi-Fi, volume, batteria, Bluetooth)
in stile Windows 11: forme piene e ben leggibili anche a 16 pixel.

Solo riempimenti (niente "stroke"), così GTK le ricolora bene come icone
simboliche: bianche sulla barra scura, scure sui menu chiari.
Le parti "spente" (tacche del Wi-Fi mancanti) sono semitrasparenti.

Uso: genera-icone-barra.py CARTELLA_SVG [anteprima.png]
"""
import math
import os
import sys

COLORE = "#bebebe"
SPENTO = 0.28


def cerchio(cx, cy, r, n=28):
    return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)]


def settore(cx, cy, r1, r2, a1, a2, n=24):
    """Corona circolare fra r1 e r2, angoli in gradi (0 = destra, -90 = su)."""
    fuori = [(cx + r2 * math.cos(math.radians(a1 + (a2 - a1) * i / n)),
              cy + r2 * math.sin(math.radians(a1 + (a2 - a1) * i / n))) for i in range(n + 1)]
    if r1 <= 0:
        return fuori + [(cx, cy)]
    dentro = [(cx + r1 * math.cos(math.radians(a2 - (a2 - a1) * i / n)),
               cy + r1 * math.sin(math.radians(a2 - (a2 - a1) * i / n))) for i in range(n + 1)]
    return fuori + dentro


def segmento(x1, y1, x2, y2, s):
    """Linea spessa s come rettangolo (con estremi arrotondati a parte)."""
    d = math.hypot(x2 - x1, y2 - y1) or 1
    nx, ny = -(y2 - y1) / d * s / 2, (x2 - x1) / d * s / 2
    return [(x1 + nx, y1 + ny), (x2 + nx, y2 + ny), (x2 - nx, y2 - ny), (x1 - nx, y1 - ny)]


def linea(punti, s):
    forme = []
    for (a, b), (c, d) in zip(punti, punti[1:]):
        forme.append(segmento(a, b, c, d, s))
    for x, y in punti:
        forme.append(cerchio(x, y, s / 2, 16))
    return forme


def rettangolo(x, y, l, a, r=0.0):
    if r <= 0:
        return [(x, y), (x + l, y), (x + l, y + a), (x, y + a)]
    p = []
    for cx, cy, a0 in ((x + l - r, y + r, -90), (x + l - r, y + a - r, 0), (x + r, y + a - r, 90), (x + r, y + r, 180)):
        p += [(cx + r * math.cos(math.radians(a0 + 90 * i / 6)), cy + r * math.sin(math.radians(a0 + 90 * i / 6)))
              for i in range(7)]
    return p


def percorso(poligoni):
    return " ".join("M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in p) + " Z" for p in poligoni)


class Icona:
    def __init__(self):
        self.parti = []  # (poligoni, opacità, buchi)

    def piena(self, *poligoni, opacita=1.0):
        self.parti.append((list(poligoni), opacita, False))
        return self

    def bucata(self, *poligoni, opacita=1.0):
        """Il primo poligono è il contorno, gli altri sono buchi (evenodd)."""
        self.parti.append((list(poligoni), opacita, True))
        return self

    def svg(self):
        righe = ['<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">']
        for poligoni, opacita, buchi in self.parti:
            attr = f' opacity="{opacita}"' if opacita < 1 else ""
            attr += ' fill-rule="evenodd"' if buchi else ""
            righe.append(f'  <path fill="{COLORE}"{attr} d="{percorso(poligoni)}"/>')
        righe.append("</svg>")
        return "\n".join(righe) + "\n"


# ------------------------------------------------------------------ Wi-Fi
WIFI_C = (8, 14.0)
WIFI_A = (-130, -50)
WIFI_BANDE = [(0, 2.6), (3.6, 5.7), (6.7, 8.8), (9.8, 11.9)]


def wifi(tacche, spento=False, sbarrato=False, escl=False):
    ic = Icona()
    for i, (r1, r2) in enumerate(WIFI_BANDE):
        acceso = i < tacche and not spento
        forma = settore(*WIFI_C, r1, r2, *WIFI_A)
        ic.piena(forma, opacita=1.0 if acceso else SPENTO)
    if sbarrato:
        ic.piena(*linea([(2.2, 1.6), (14.2, 13.6)], 1.6))
    if escl:  # rete senza internet / non collegata: piccola croce in basso a destra
        ic.piena(*linea([(11.2, 11.0), (14.6, 14.4)], 1.5), *linea([(14.6, 11.0), (11.2, 14.4)], 1.5))
    return ic


# ------------------------------------------------------------------ Volume
def volume(onde, muto=False):
    ic = Icona()
    cassa = [(1.2, 5.6), (4.2, 5.6), (8.0, 2.2), (8.0, 13.8), (4.2, 10.4), (1.2, 10.4)]
    ic.piena(cassa)
    if muto:
        ic.piena(*linea([(10.4, 5.8), (14.6, 10.2)], 1.5), *linea([(14.6, 5.8), (10.4, 10.2)], 1.5))
        return ic
    for i, (r1, r2) in enumerate([(2.0, 3.4), (4.4, 5.8), (6.8, 8.2)][:3]):
        if i < onde:
            ic.piena(settore(8.0, 8.0, r1 + 0.6, r2 + 0.6, -50, 50))
        else:
            ic.piena(settore(8.0, 8.0, r1 + 0.6, r2 + 0.6, -50, 50), opacita=SPENTO)
    return ic


# ------------------------------------------------------------------ Batteria
def batteria(livello, carica=False):
    ic = Icona()
    esterno = rettangolo(0.6, 4.0, 13.2, 8.0, 2.0)
    interno = rettangolo(1.9, 5.3, 10.6, 5.4, 1.0)
    ic.bucata(esterno, interno)
    ic.piena(rettangolo(14.2, 6.3, 1.4, 3.4, 0.6))
    if carica:
        # in carica: fulmine al centro (la percentuale è scritta accanto)
        ic.piena([(8.3, 5.7), (5.0, 8.4), (7.0, 8.4), (6.2, 10.3), (9.5, 7.6), (7.5, 7.6)])
    elif livello > 0:
        l = max(1.2, 9.0 * livello / 100)
        ic.piena(rettangolo(2.7, 6.1, l, 3.8, 0.6))
    return ic


# ------------------------------------------------------------------ Bluetooth
def bluetooth(stato="acceso"):
    ic = Icona()
    s = 1.45
    runa = [(3.6, 4.8), (11.2, 11.0), (7.6, 14.2), (7.6, 1.8), (11.2, 5.0), (3.6, 11.2)]
    op = SPENTO if stato == "spento" else 1.0
    ic.piena(*linea(runa, s), opacita=op)
    if stato == "spento":
        ic.piena(*linea([(2.2, 1.8), (13.8, 14.2)], 1.6))
    if stato == "connesso":
        ic.piena(cerchio(2.2, 8.0, 1.2), cerchio(13.8, 8.0, 1.2))
    return ic


def tutte():
    ic = {}
    for t in range(5):
        ic[f"alba-wifi-{t}-symbolic"] = wifi(t)
    ic["alba-wifi-scollegato-symbolic"] = wifi(0, escl=True)
    ic["alba-wifi-spento-symbolic"] = wifi(0, spento=True, sbarrato=True)
    ic["alba-volume-0-symbolic"] = volume(0)
    ic["alba-volume-1-symbolic"] = volume(1)
    ic["alba-volume-2-symbolic"] = volume(2)
    ic["alba-volume-3-symbolic"] = volume(3)
    ic["alba-volume-muto-symbolic"] = volume(0, muto=True)
    for l in range(0, 101, 10):
        ic[f"alba-batteria-{l}-symbolic"] = batteria(l)
        ic[f"alba-batteria-{l}-carica-symbolic"] = batteria(l, carica=True)
    ic["alba-bluetooth-symbolic"] = bluetooth("acceso")
    ic["alba-bluetooth-connesso-symbolic"] = bluetooth("connesso")
    ic["alba-bluetooth-spento-symbolic"] = bluetooth("spento")
    return ic


def anteprima(icone, file, scala=6):
    from PIL import Image, ImageDraw
    nomi = list(icone)
    col = 12
    cella = 16 * scala + 14
    righe = (len(nomi) + col - 1) // col
    out = Image.new("RGB", (col * cella, righe * cella * 2), (30, 31, 43))
    chiaro = Image.new("RGB", (col * cella, righe * cella), (243, 243, 243))
    out.paste(chiaro, (0, righe * cella))
    for sfondo, (y0, colore) in enumerate([(0, (255, 255, 255)), (righe * cella, (40, 40, 40))]):
        for i, n in enumerate(nomi):
            x, y = (i % col) * cella + 7, y0 + (i // col) * cella + 7
            for poligoni, opacita, buchi in icone[n].parti:
                maschera = Image.new("L", (16 * scala, 16 * scala), 0)
                d = ImageDraw.Draw(maschera)
                for j, p in enumerate(poligoni):
                    d.polygon([(a * scala, b * scala) for a, b in p], fill=0 if (buchi and j > 0) else 255)
                tinta = Image.new("RGB", maschera.size, colore)
                out.paste(tinta, (x, y), maschera.point(lambda v, o=opacita: int(v * o)))
    out.save(file)


if __name__ == "__main__":
    cartella = sys.argv[1]
    os.makedirs(cartella, exist_ok=True)
    icone = tutte()
    for nome, ic in icone.items():
        with open(os.path.join(cartella, nome + ".svg"), "w") as f:
            f.write(ic.svg())
    if len(sys.argv) > 2:
        anteprima(icone, sys.argv[2])
    print(f"{len(icone)} icone in {cartella}")
