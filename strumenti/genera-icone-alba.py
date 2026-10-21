#!/usr/bin/python3
"""Alba Linux - crea il tema di icone "Alba" (stile B, "Alba vetro").

Ogni icona di app sta su una tessera di vetro chiaro arrotondata:
 - le app di sistema più comuni hanno un simbolo Alba disegnato a linee, colorato;
 - tutte le altre icone (Fluent) vengono messe, rimpicciolite, sulla stessa tessera.
Tutto il resto (cartelle, file, simboli della barra) arriva da Fluent.

Uso: genera-icone-alba.py CARTELLA_ICONE   (contiene già Fluent e Fluent-dark)
Crea CARTELLA_ICONE/Alba e CARTELLA_ICONE/Alba-dark.
"""
import os
import re
import sys

# simboli a linee (griglia 24x24, come le anteprime approvate)
G = {
    "file": '<path d="M3 7.5a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2V17a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M3 10h18"/>',
    "internet": '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.6 2.4 3.6 5.3 3.6 8.5s-1 6.1-3.6 8.5c-2.6-2.4-3.6-5.3-3.6-8.5s1-6.1 3.6-8.5z"/>',
    "posta": '<rect x="3" y="5.5" width="18" height="13" rx="2.5"/><path d="M3.8 7l8.2 6 8.2-6"/>',
    "musica": '<path d="M9 17.5V6l11-2v11.5"/><circle cx="6.5" cy="17.5" r="2.5"/><circle cx="17.5" cy="15.5" r="2.5"/>',
    "documenti": '<path d="M6 3h8l4 4v14H6z"/><path d="M14 3v4h4M9 11h6M9 14h6M9 17h4"/>',
    "fogli": '<rect x="4" y="4" width="16" height="16" rx="2.5"/><path d="M4 9.5h16M4 14.5h16M10 4v16"/>',
    "presentazioni": '<rect x="3" y="4.5" width="18" height="12" rx="2"/><path d="M12 16.5v3.5M8.5 20h7M8 12l3-3 2 2 3-3"/>',
    "programmi": '<path d="M5 8h14l-1.2 11.5a1.8 1.8 0 0 1-1.8 1.5H8a1.8 1.8 0 0 1-1.8-1.5z"/><path d="M9 10V7a3 3 0 0 1 6 0v3"/>',
    "impostazioni": '<circle cx="12" cy="12" r="3"/><path d="M12 2.8v2.4M12 18.8v2.4M2.8 12h2.4M18.8 12h2.4M5.5 5.5l1.7 1.7M16.8 16.8l1.7 1.7M5.5 18.5l1.7-1.7M16.8 7.2l1.7-1.7"/><circle cx="12" cy="12" r="6.5"/>',
    "foto": '<rect x="3" y="5" width="18" height="14" rx="2.5"/><circle cx="9" cy="10" r="1.8"/><path d="M4 17l5-4.5 4 3.5 3-2.5 4 3.5"/>',
    "video": '<rect x="3" y="6" width="13" height="12" rx="2.5"/><path d="M16 10.5l5-3v9l-5-3"/>',
    "calcolatrice": '<rect x="5" y="3" width="14" height="18" rx="2.5"/><path d="M8 7.5h8M8.5 12h.01M12 12h.01M15.5 12h.01M8.5 16h.01M12 16h.01M15.5 16h.01"/>',
    "attivita": '<rect x="3" y="4" width="18" height="16" rx="2.5"/><path d="M6 15l3-4 3 2 3-5 3 4"/>',
    "note": '<path d="M6 3h12v18H6z"/><path d="M9 8h6M9 12h6M9 16h3"/>',
    "camera": '<path d="M4 8h3l1.5-2.5h7L17 8h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>',
    "windows": '<rect x="3.5" y="5" width="17" height="14" rx="2.5"/><path d="M3.5 9h17M7 7h.01M9.5 7h.01"/><path d="M9 13l2 2 4-4"/>',
    "aiuto": '<circle cx="12" cy="12" r="8.5"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.3 2.4c-.5.2-.8.6-.8 1.1V14M12 17h.01"/>',
    "scanner": '<path d="M4 8V5h3M17 5h3v3M20 16v3h-3M7 19H4v-3M7 12h10"/>',
    "app": '<rect x="4" y="4" width="6" height="6" rx="1.5"/><rect x="14" y="4" width="6" height="6" rx="1.5"/><rect x="4" y="14" width="6" height="6" rx="1.5"/><rect x="14" y="14" width="6" height="6" rx="1.5"/>',
    "cestino": '<path d="M4.5 7h15M9.5 7V4.5h5V7M6.5 7l1 13h9l1-13"/>',
    "cestino-pieno": '<path d="M4.5 7h15M9.5 7V4.5h5V7M6.5 7l1 13h9l1-13"/><path d="M10 11v5M14 11v5"/>',
    "terminale": '<rect x="3" y="4.5" width="18" height="15" rx="2.5"/><path d="M7 10l3 2.5L7 15M12.5 15H17"/>',
    "testo": '<path d="M5 4h10l4 4v12H5z"/><path d="M8.5 16.5l1-3 6-6 2 2-6 6z"/>',
    "dischi": '<rect x="3.5" y="6" width="17" height="12" rx="2.5"/><path d="M7 14.5h.01M10 14.5h5"/>',
    "archivio": '<rect x="4" y="4" width="16" height="16" rx="2.5"/><path d="M12 4v3M12 9v2M12 13v2M10.5 16h3v2h-3z"/>',
    "lettore": '<path d="M6 3h8l4 4v14H6z"/><path d="M14 3v4h4M9.5 12.5l5 2.5-5 2.5z"/>',
    "schermata": '<path d="M4 8V5h3M17 5h3v3M20 16v3h-3M7 19H4v-3"/><circle cx="12" cy="12" r="3"/>',
    "sicurezza": '<path d="M12 3l7.5 3v5.5c0 4.5-3.2 8-7.5 9.5-4.3-1.5-7.5-5-7.5-9.5V6z"/><path d="M9 12l2 2 4-4"/>',
    "stampanti": '<path d="M7 9V4h10v5"/><rect x="3.5" y="9" width="17" height="8" rx="2"/><path d="M7 14h10v6H7z"/>',
    "backup": '<path d="M4.5 12a7.5 7.5 0 1 0 2.2-5.3L4.5 9"/><path d="M4.5 4.5V9H9M12 8v4l3 2"/>',
    "giochi": '<path d="M7 8h10a4 4 0 0 1 4 4v1a3 3 0 0 1-5.4 1.8L14.5 13.5h-5l-1.1 1.3A3 3 0 0 1 3 13v-1a4 4 0 0 1 4-4z"/><path d="M7.5 10v3M6 11.5h3M16 11h.01M17.5 12.5h.01"/>',
}
# colore di ogni simbolo (chiaro, scuro)
C = {
    "file": ("#f07a1e", "#ffa45c"), "internet": ("#1f6fe0", "#6aa8ff"), "posta": ("#139a9a", "#5ad1c9"),
    "musica": ("#e0315a", "#ff7a98"), "documenti": ("#2d55d6", "#7a9bff"), "fogli": ("#1f9a54", "#5fd38a"),
    "presentazioni": ("#e0582a", "#ff9a6a"), "programmi": ("#e8860f", "#ffbf52"), "impostazioni": ("#4d5668", "#c3cad8"),
    "foto": ("#e8960f", "#ffd06a"), "video": ("#7a4ee0", "#b48cff"), "calcolatrice": ("#4d5668", "#c3cad8"),
    "attivita": ("#d63a6a", "#ff8aa8"), "note": ("#c9970a", "#ffe27a"), "camera": ("#454e5e", "#c3cad8"),
    "windows": ("#2a6ad6", "#6aa8ff"), "aiuto": ("#8460e0", "#c0a8ff"), "scanner": ("#2a9a92", "#8ad8d0"),
    "app": ("#f07a1e", "#ffa45c"), "cestino": ("#6b7385", "#c3cad8"), "cestino-pieno": ("#6b7385", "#c3cad8"),
    "terminale": ("#2a2f3a", "#e8ecf2"), "testo": ("#2d55d6", "#7a9bff"), "dischi": ("#4d5668", "#c3cad8"),
    "archivio": ("#a0662a", "#e0a86a"), "lettore": ("#d63a3a", "#ff8a8a"), "schermata": ("#2a9a92", "#8ad8d0"),
    "sicurezza": ("#1f9a54", "#5fd38a"), "stampanti": ("#4d5668", "#c3cad8"), "backup": ("#139a9a", "#5ad1c9"),
    "giochi": ("#25a86a", "#7ae0a0"),
}
# nomi delle icone (come le chiedono i programmi) -> simbolo Alba
NOMI = {
    "file": ["system-file-manager", "org.xfce.thunar", "thunar", "file-manager", "org.gnome.Nautilus",
             "user-home", "folder-home"],
    "internet": ["web-browser", "internet-web-browser", "applications-internet"],
    "posta": ["internet-mail", "mail-client", "applications-mail"],
    "musica": ["multimedia-audio-player", "rhythmbox", "org.gnome.Rhythmbox3", "alba-apple-music", "audio-player"],
    "documenti": ["libreoffice-writer", "libreoffice-main", "libreoffice-startcenter", "accessories-text-editor-office"],
    "fogli": ["libreoffice-calc"],
    "presentazioni": ["libreoffice-impress"],
    "programmi": ["gnome-software", "org.gnome.Software", "system-software-install", "software-store",
                  "system-software-update", "software-center"],
    "impostazioni": ["preferences-system", "alba-impostazioni", "org.xfce.settings.manager", "preferences-desktop",
                     "xfce4-settings-manager", "gnome-control-center"],
    "foto": ["org.xfce.ristretto", "ristretto", "image-viewer", "eog", "org.gnome.eog", "shotwell", "gthumb"],
    "video": ["vlc", "totem", "org.gnome.Totem", "multimedia-video-player", "video-player", "celluloid", "mpv"],
    "calcolatrice": ["accessories-calculator", "galculator", "org.gnome.Calculator", "gnome-calculator"],
    "attivita": ["utilities-system-monitor", "org.xfce.taskmanager", "xfce4-taskmanager", "gnome-system-monitor",
                 "alba-gestione-attivita"],
    "camera": ["camera-app", "guvcview", "cheese", "org.gnome.Cheese", "camera-web", "accessories-camera"],
    "windows": ["wine", "alba-programma-windows", "application-x-ms-dos-executable", "wine-program"],
    "aiuto": ["help-browser", "help-contents", "system-help", "yelp"],
    "scanner": ["simple-scan", "org.gnome.SimpleScan", "scanner", "xsane"],
    "app": ["alba-app", "view-app-grid", "applications-all"],
    "cestino": ["user-trash"],
    "cestino-pieno": ["user-trash-full"],
    "terminale": ["utilities-terminal", "org.xfce.terminal", "xfce4-terminal", "terminal", "org.gnome.Terminal"],
    "testo": ["accessories-text-editor", "org.xfce.mousepad", "mousepad", "text-editor", "org.gnome.TextEditor", "gedit"],
    "dischi": ["gnome-disks", "org.gnome.DiskUtility", "drive-harddisk-system", "gparted"],
    "archivio": ["file-roller", "org.gnome.FileRoller", "xarchiver", "ark", "engrampa"],
    "lettore": ["atril", "org.gnome.Evince", "evince", "accessories-document-viewer", "document-viewer"],
    "schermata": ["org.xfce.screenshooter", "applets-screenshooter", "accessories-screenshot", "screenshot"],
    "sicurezza": ["gufw", "clamtk", "security-high", "preferences-system-firewall"],
    "stampanti": ["printer", "system-config-printer", "preferences-desktop-printer"],
    "backup": ["timeshift", "deja-dup", "org.gnome.DejaDup", "backup"],
    "giochi": ["applications-games", "input-gaming", "gamemode"],
}
# app famose: il marchio resta (ma va sulla tessera di vetro come le altre)
TESSERA = {
    False: dict(da="#ffffff", da_a="0.97", a="#fbf6f1", a_a="0.86", bordo="#ffffff", bordo_a="0.95",
                ombra="#5a2a00", ombra_a="0.10", riflesso_a="0.55"),
    True: dict(da="#4a4656", da_a="0.95", a="#2e2b38", a_a="0.92", bordo="#ffffff", bordo_a="0.14",
               ombra="#000000", ombra_a="0.25", riflesso_a="0.10"),
}


def tessera(scuro):
    t = TESSERA[scuro]
    return f'''<defs><linearGradient id="albaTv" x1="0" y1="0" x2="0.35" y2="1">
<stop offset="0" stop-color="{t['da']}" stop-opacity="{t['da_a']}"/><stop offset="1" stop-color="{t['a']}" stop-opacity="{t['a_a']}"/></linearGradient>
<linearGradient id="albaTr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity="{t['riflesso_a']}"/><stop offset="0.5" stop-color="#ffffff" stop-opacity="0"/></linearGradient></defs>
<rect x="4" y="5.5" width="56" height="56" rx="15" fill="{t['ombra']}" fill-opacity="{t['ombra_a']}"/>
<rect x="4" y="4" width="56" height="56" rx="15" fill="url(#albaTv)"/>
<rect x="4.5" y="4.5" width="55" height="27" rx="14.5" fill="url(#albaTr)"/>
<rect x="4.5" y="4.5" width="55" height="55" rx="14.5" fill="none" stroke="{t['bordo']}" stroke-opacity="{t['bordo_a']}"/>'''


def icona_simbolo(chiave, scuro):
    colore = C[chiave][1 if scuro else 0]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">{tessera(scuro)}'
            f'<g transform="translate(15 15) scale(1.4167)" fill="none" stroke="{colore}" stroke-width="1.8" '
            f'stroke-linecap="round" stroke-linejoin="round">{G[chiave]}</g></svg>\n')


RADICE = re.compile(r"<svg\b([^>]*)>", re.S)


def numero(v):
    m = re.match(r"\s*([0-9.]+)", v or "")
    return float(m.group(1)) if m else None


def icona_avvolta(svg, scuro):
    """Mette un'icona esistente (SVG) al centro della tessera, al 66%."""
    m = RADICE.search(svg)
    if not m:
        return None
    attr = m.group(1)
    vb = re.search(r'viewBox\s*=\s*"([^"]+)"', attr)
    if vb:
        viewbox = vb.group(1)
    else:
        w = numero((re.search(r'\bwidth\s*=\s*"([^"]+)"', attr) or [None, None])[1])
        h = numero((re.search(r'\bheight\s*=\s*"([^"]+)"', attr) or [None, None])[1])
        if not w or not h:
            return None
        viewbox = f"0 0 {w:g} {h:g}"
    # attributi della radice da tenere (namespace, stile), senza posizione/dimensioni
    tieni = re.sub(r'\s(width|height|x|y|viewBox|version|id|enable-background|xml:space)\s*=\s*"[^"]*"', "", attr)
    interno = svg[m.end():svg.rfind("</svg>")]
    prima = svg[:m.start()]
    if "<!DOCTYPE" in prima and "[" in prima:   # entità: troppo complicato, si lascia l'originale
        return None
    lato = 42
    pos = (64 - lato) / 2
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64">'
            f'{tessera(scuro)}<svg{tieni} x="{pos:g}" y="{pos:g}" width="{lato}" height="{lato}" viewBox="{viewbox}">'
            f'{interno}</svg></svg>\n')


INDICE = """[Icon Theme]
Name={nome}
Comment=Icone di Alba Linux: tessere di vetro
Inherits={eredita},hicolor
Example=folder

Directories=scalable/apps

[scalable/apps]
Context=Applications
Size=64
MinSize=16
MaxSize=512
Type=Scalable
"""


def crea(base, nome, sorgente, scuro):
    dest = os.path.join(base, nome, "scalable", "apps")
    os.makedirs(dest, exist_ok=True)
    with open(os.path.join(base, nome, "index.theme"), "w") as f:
        f.write(INDICE.format(nome=nome, eredita=sorgente))
    fatti = set()
    # 1. simboli Alba per le app di sistema
    for chiave, nomi in NOMI.items():
        contenuto = icona_simbolo(chiave, scuro)
        for n in nomi:
            with open(os.path.join(dest, n + ".svg"), "w") as f:
                f.write(contenuto)
            fatti.add(n)
    # 2. tutte le altre icone di app di Fluent, sulla tessera
    apps = os.path.join(base, sorgente, "scalable", "apps")
    avvolte = saltate = collegamenti = 0
    if os.path.isdir(apps):
        for f in sorted(os.listdir(apps)):
            if not f.endswith(".svg") or f[:-4] in fatti:
                continue
            p = os.path.join(apps, f)
            if os.path.islink(p):
                bersaglio = os.readlink(p)
                if "/" not in bersaglio:            # collegamento nella stessa cartella
                    os.symlink(bersaglio, os.path.join(dest, f))
                    collegamenti += 1
                continue
            try:
                svg = open(p, encoding="utf-8").read()
            except (OSError, UnicodeDecodeError):
                saltate += 1
                continue
            nuovo = icona_avvolta(svg, scuro)
            if nuovo is None:
                saltate += 1
                continue
            with open(os.path.join(dest, f), "w", encoding="utf-8") as out:
                out.write(nuovo)
            avvolte += 1
    # collegamenti rimasti senza destinazione (la destinazione era un simbolo Alba: va bene)
    for f in os.listdir(dest):
        p = os.path.join(dest, f)
        if os.path.islink(p) and not os.path.exists(p):
            os.remove(p)
    print(f"{nome}: {len(fatti)} simboli Alba, {avvolte} icone su tessera, {collegamenti} collegamenti, {saltate} lasciate a Fluent")


if __name__ == "__main__":
    base = sys.argv[1]
    crea(base, "Alba", "Fluent", False)
    crea(base, "Alba-dark", "Fluent-dark" if os.path.isdir(os.path.join(base, "Fluent-dark")) else "Fluent", True)
