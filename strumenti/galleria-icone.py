#!/usr/bin/python3
"""Disegna in un PNG le icone principali del tema di Alba (per controllarle).
Uso: galleria-icone.py USCITA.png"""
import sys
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk  # noqa: E402
import cairo  # noqa: E402

conf = dict(l.strip().replace('"', "").split("=", 1) for l in open("/usr/share/alba/tema.conf") if "=" in l)
APP = ["firefox-esr", "firefox", "system-file-manager", "org.gnome.Software", "preferences-system", "steam",
       "vlc", "libreoffice-writer", "libreoffice-calc", "libreoffice-impress", "utilities-terminal",
       "org.kde.kdenlive", "gimp", "blender", "obs", "codium", "utilities-system-monitor", "accessories-calculator",
       "folder", "folder-download", "folder-documents", "folder-pictures", "user-trash", "drive-removable-media"]
SIMBOLICHE = ["network-wireless-signal-excellent-symbolic", "bluetooth-active-symbolic", "audio-volume-high-symbolic",
              "battery-full-charging-symbolic", "alba-campanella-symbolic", "system-search-symbolic"]
L, CELLA = 1300, 96
superficie = cairo.ImageSurface(cairo.FORMAT_ARGB32, L, 520)
cr = cairo.Context(superficie)
y = 0
for nome_tema, sfondo in ((conf.get("ICONE_SCURO", "Papirus-Dark"), (0.118, 0.122, 0.169)),
                          (conf.get("ICONE_CHIARO", "Papirus"), (0.95, 0.95, 0.97))):
    tema = Gtk.IconTheme()
    tema.set_custom_theme(nome_tema)
    cr.set_source_rgb(*sfondo)
    cr.rectangle(0, y, L, 260)
    cr.fill()
    cr.set_source_rgb(1 - sfondo[0], 1 - sfondo[1], 1 - sfondo[2])
    cr.move_to(10, y + 18)
    cr.set_font_size(14)
    cr.show_text(f"Icone: {nome_tema}")
    x, riga = 10, y + 30
    for i, n in enumerate(APP):
        try:
            pix = tema.load_icon(n, 64, Gtk.IconLookupFlags.FORCE_SIZE)
        except Exception:  # noqa: BLE001
            continue
        Gdk.cairo_set_source_pixbuf(cr, pix, x, riga)
        cr.paint()
        x += 76
        if x > L - 80:
            x, riga = 10, riga + 76
    x, riga = 10, riga + 84
    for n in SIMBOLICHE:
        try:
            info = tema.lookup_icon(n, 24, Gtk.IconLookupFlags.FORCE_SIZE)
            pix, _ = info.load_symbolic(Gdk.RGBA(*(1 - c for c in sfondo), 1), None, None, None)
        except Exception:  # noqa: BLE001
            continue
        Gdk.cairo_set_source_pixbuf(cr, pix, x, riga)
        cr.paint()
        x += 40
    y += 260
superficie.write_to_png(sys.argv[1])
print("galleria:", sys.argv[1])
