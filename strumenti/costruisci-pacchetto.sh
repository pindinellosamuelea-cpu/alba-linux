#!/bin/bash
# Costruisce il pacchetto "alba-sistema" (.deb) che porta gli aggiornamenti
# di Alba sui computer già installati.
#
# Uso: strumenti/costruisci-pacchetto.sh VERSIONE CARTELLA_USCITA
# Con TEMA_FLUENT=1 scarica e integra il tema Fluent (stile Windows 11).
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

VERSIONE="${1:?Specifica la versione, es. 1.1.0}"
USCITA="$(readlink -f "${2:-dist}")"
LAVORO="$(mktemp -d)"
P="$LAVORO/alba-sistema"
mkdir -p "$USCITA" "$P"

cp -a pacchetto/radice/. "$P/"
mkdir -p "$P/DEBIAN" "$P/usr/share/alba" "$P/usr/share/themes"
sed "s/@VERSIONE@/$VERSIONE/" pacchetto/DEBIAN/control.in > "$P/DEBIAN/control"
cp pacchetto/DEBIAN/postinst pacchetto/DEBIAN/triggers "$P/DEBIAN/"
echo "$VERSIONE" > "$P/usr/share/alba/versione"
date -u +%Y-%m-%dT%H:%M > "$P/usr/share/alba/data-versione"
cp novita.json "$P/usr/share/alba/novita.json" 2>/dev/null || true

# --- Tema ---------------------------------------------------------------------
# Prima scelta: WhiteSur (stile macOS). Riserva: Fluent (stile Windows 11),
# poi Materia dai repository Debian.
TEMA_CHIARO="Materia-light"
TEMA_SCURO="Materia-dark"
T="$P/usr/share/themes"
scegli_tema() {  # nome-ricerca-chiaro nome-ricerca-scuro
  local c s
  c="$(cd "$T" && ls -d $1 2>/dev/null | grep -viE 'compact|solid|nord|hdpi|xhdpi' | while read -r d; do [ -d "$d/gtk-3.0" ] && echo "$d"; done | head -1)"
  s="$(cd "$T" && ls -d $2 2>/dev/null | grep -viE 'compact|solid|nord|hdpi|xhdpi' | while read -r d; do [ -d "$d/gtk-3.0" ] && echo "$d"; done | head -1)"
  if [ -n "$c" ] && [ -n "$s" ]; then TEMA_CHIARO="$c"; TEMA_SCURO="$s"; return 0; fi
  return 1
}
if [ "${TEMA_FLUENT:-0}" = 1 ]; then
  mkdir -p "$P/usr/share/doc/alba-sistema"
  echo ">> Integro il tema WhiteSur (stile macOS)"
  if git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$LAVORO/whitesur-gtk"; then
    # Nuova grafica 1.2: tema costruito con l'accento arancio di Alba e le
    # trasparenze (variante "normal"). Se non riesce: pacchetti già pronti.
    if ( cd "$LAVORO/whitesur-gtk" && TERM=dumb SUDO_USER="$(id -un)" USER="$(id -un)" timeout 900 ./install.sh -d "$T" -c light -c dark -o normal -t orange --silent-mode ) \
         > "$LAVORO/whitesur.log" 2>&1 && [ -d "$T/WhiteSur-Light-orange/gtk-3.0" ]; then
      echo ">> WhiteSur costruito con l'accento arancio"
    else
      echo "ATTENZIONE: WhiteSur arancio non costruito, uso i pacchetti pronti"; tail -30 "$LAVORO/whitesur.log"; ls "$T"
      for v in Light Dark; do
        tar -xJf "$LAVORO/whitesur-gtk/release/WhiteSur-$v.tar.xz" -C "$T" || echo "ATTENZIONE: WhiteSur-$v non estratto"
      done
    fi
    cp "$LAVORO/whitesur-gtk/COPYING" "$P/usr/share/doc/alba-sistema/LICENZA-tema-WhiteSur" 2>/dev/null || true
  fi
  if ! scegli_tema 'WhiteSur-Light-orange' 'WhiteSur-Dark-orange' && ! scegli_tema 'WhiteSur*Light*' 'WhiteSur*Dark*'; then
    echo ">> WhiteSur non disponibile, provo Fluent"
    find "$T" -mindepth 1 -maxdepth 1 ! -name Alba -exec rm -rf {} +
    if git clone --depth 1 https://github.com/vinceliuice/Fluent-gtk-theme.git "$LAVORO/fluent"; then
      ( cd "$LAVORO/fluent" && { ./install.sh -d "$T" -c light dark -s standard --tweaks round || ./install.sh -d "$T"; } ) \
        || echo "ATTENZIONE: installazione Fluent non riuscita"
      cp "$LAVORO/fluent/COPYING" "$P/usr/share/doc/alba-sistema/LICENZA-tema-Fluent" 2>/dev/null || true
    fi
    scegli_tema '*Light*' '*Dark*' || echo "ATTENZIONE: nessun tema scaricato, uso Materia"
  fi
  # Teniamo solo le due varianti usate (pacchetto più leggero)
  ( cd "$T" && for d in *; do
      [ "$d" = "$TEMA_CHIARO" ] || [ "$d" = "$TEMA_SCURO" ] || [ "$d" = "Alba" ] || rm -rf "$d"; done )
fi
# --- Icone: Fluent (pulite e professionali, GPL) -------------------------------
ICONE_CHIARO="Papirus"
ICONE_SCURO="Papirus-Dark"
if [ "${TEMA_FLUENT:-0}" = 1 ]; then
  echo ">> Integro le icone Fluent"
  if git clone --depth 1 https://github.com/vinceliuice/Fluent-icon-theme.git "$LAVORO/fluent-icone"; then
    mkdir -p "$P/usr/share/icons" "$P/usr/share/doc/alba-sistema"
    ( cd "$LAVORO/fluent-icone" && ./install.sh -d "$P/usr/share/icons" ) || echo "ATTENZIONE: icone Fluent non installate"
    cp "$LAVORO/fluent-icone/COPYING" "$P/usr/share/doc/alba-sistema/LICENZA-icone-Fluent" 2>/dev/null || true
    if [ -d "$P/usr/share/icons/Fluent-dark" ] && [ -d "$P/usr/share/icons/Fluent" ]; then
      ICONE_CHIARO="Fluent"; ICONE_SCURO="Fluent-dark"
      rm -rf "$P/usr/share/icons/Fluent-light"
      # Icone della barra e delle Impostazioni rapide: proprio quelle Fluent
      # scelte dall'utente (le versioni "symbolic", pulite a ogni dimensione),
      # copiate con nomi Alba così non vengono sostituite da varianti diverse.
      SIMB="$P/usr/share/icons/Fluent/symbolic"
      DEST="$P/usr/share/icons/hicolor/scalable/status"
      copia() { # alba-nome  nome-fluent
        local f
        f="$(find -L "$SIMB" -name "$2.svg" 2>/dev/null | head -1)"
        [ -n "$f" ] && cp -L "$f" "$DEST/$1.svg" && return 0
        echo "   (manca $2: tengo l'icona Alba)"
      }
      copia alba-wifi-0-symbolic network-wireless-signal-none-symbolic
      copia alba-wifi-1-symbolic network-wireless-signal-weak-symbolic
      copia alba-wifi-2-symbolic network-wireless-signal-ok-symbolic
      copia alba-wifi-3-symbolic network-wireless-signal-good-symbolic
      copia alba-wifi-4-symbolic network-wireless-signal-excellent-symbolic
      copia alba-wifi-scollegato-symbolic network-wireless-disconnected-symbolic
      copia alba-wifi-spento-symbolic network-wireless-offline-symbolic
      copia alba-volume-0-symbolic audio-volume-muted-symbolic
      copia alba-volume-1-symbolic audio-volume-low-symbolic
      copia alba-volume-2-symbolic audio-volume-medium-symbolic
      copia alba-volume-3-symbolic audio-volume-high-symbolic
      copia alba-volume-muto-symbolic audio-volume-muted-symbolic
      for l in 0 10 20 30 40 50 60 70 80 90 100; do
        copia "alba-batteria-$l-symbolic" "battery-level-$l-symbolic"
        if [ "$l" = 100 ]; then copia "alba-batteria-100-carica-symbolic" battery-level-100-charged-symbolic
        else copia "alba-batteria-$l-carica-symbolic" "battery-level-$l-charging-symbolic"; fi
      done
      copia alba-bluetooth-symbolic bluetooth-active-symbolic
      copia alba-bluetooth-connesso-symbolic bluetooth-active-symbolic
      copia alba-bluetooth-spento-symbolic bluetooth-disabled-symbolic
      copia alba-ingranaggio-symbolic emblem-system-symbolic
      # Nuova grafica 1.2: icone delle app su tessere di vetro (stile "Alba vetro")
      if python3 pacchetto/radice/usr/libexec/alba/alba-icone tema "$P/usr/share/icons" && [ -f "$P/usr/share/icons/Alba/index.theme" ]; then
        ICONE_CHIARO="Alba"; ICONE_SCURO="Alba-dark"
      else
        echo "ATTENZIONE: icone Alba non create, resto su Fluent"
      fi
    fi
  fi
fi
echo ">> Icone: chiaro=$ICONE_CHIARO scuro=$ICONE_SCURO"
echo ">> Temi: chiaro=$TEMA_CHIARO scuro=$TEMA_SCURO"
cat > "$P/usr/share/alba/tema.conf" <<EOF
TEMA_CHIARO="$TEMA_CHIARO"
TEMA_SCURO="$TEMA_SCURO"
ICONE_CHIARO="$ICONE_CHIARO"
ICONE_SCURO="$ICONE_SCURO"
EOF
# Nuova grafica 1.2: tema predefinito chiaro con vetro
XFWM_CHIARO="$TEMA_CHIARO"
[ -d "$P/usr/share/themes/$TEMA_CHIARO/xfwm4" ] || XFWM_CHIARO="Arc"
sed -i "s/@TEMA_CHIARO@/$TEMA_CHIARO/; s/@ICONE_CHIARO@/$ICONE_CHIARO/" "$P/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
sed -i "s/@ICONE_SCURO@/$ICONE_SCURO/" "$P/usr/share/alba/slick-greeter.conf.in"
sed -i "s/@TEMA_CHIARO_XFWM@/$XFWM_CHIARO/" "$P/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"

# --- Canale aggiornamenti: firmato (se c'è la chiave) o solo HTTPS ----------------
CANALE="https://raw.githubusercontent.com/pindinellosamuelea-cpu/alba-linux/apt ./"
if [ "${ALBA_FIRMATO:-0}" = 1 ]; then
  mkdir -p "$P/usr/share/keyrings"
  cp pacchetto/chiave-pubblica.asc "$P/usr/share/keyrings/alba-archive-keyring.asc"
  printf '# Canale aggiornamenti di Alba Linux (firmato)\ndeb [signed-by=/usr/share/keyrings/alba-archive-keyring.asc] %s\n' "$CANALE" \
    > "$P/etc/apt/sources.list.d/alba.list"
  echo ">> Canale aggiornamenti: firmato"
else
  printf '# Canale aggiornamenti di Alba Linux\ndeb [trusted=yes] %s\n' "$CANALE" > "$P/etc/apt/sources.list.d/alba.list"
  echo ">> Canale aggiornamenti: non firmato (manca la chiave)"
fi

# --- Permessi -------------------------------------------------------------------
find "$P" -type d -exec chmod 755 {} +
find "$P" -type f -exec chmod 644 {} +
chmod 755 "$P"/usr/bin/* "$P"/usr/libexec/alba/* "$P/DEBIAN/postinst"
rmdir "$P/usr/share/themes" 2>/dev/null || true

dpkg-deb --root-owner-group -Zxz --build "$P" "$USCITA/alba-sistema_${VERSIONE}_all.deb"
rm -rf "$LAVORO"
echo ">> Pacchetto pronto: $USCITA/alba-sistema_${VERSIONE}_all.deb"
