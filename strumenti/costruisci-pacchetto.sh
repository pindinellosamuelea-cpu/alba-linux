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
    ( cd "$LAVORO/whitesur-gtk" && ./install.sh -d "$T" -c Light -c Dark -o normal -t default ) \
      || ( cd "$LAVORO/whitesur-gtk" && ./install.sh -d "$T" ) || echo "ATTENZIONE: WhiteSur non installato"
    cp "$LAVORO/whitesur-gtk/COPYING" "$P/usr/share/doc/alba-sistema/LICENZA-tema-WhiteSur" 2>/dev/null || true
  fi
  if ! scegli_tema 'WhiteSur*Light*' 'WhiteSur*Dark*'; then
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
# --- Icone in stile macOS (WhiteSur, GPL) -------------------------------------
ICONE_CHIARO="Papirus"
ICONE_SCURO="Papirus-Dark"
if [ "${TEMA_FLUENT:-0}" = 1 ]; then
  echo ">> Integro le icone WhiteSur (stile macOS)"
  if git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$LAVORO/whitesur"; then
    mkdir -p "$P/usr/share/icons"
    ( cd "$LAVORO/whitesur" && ./install.sh -d "$P/usr/share/icons" -t default ) || echo "ATTENZIONE: icone WhiteSur non installate"
    mkdir -p "$P/usr/share/doc/alba-sistema"
    cp "$LAVORO/whitesur/COPYING" "$P/usr/share/doc/alba-sistema/LICENZA-icone-WhiteSur" 2>/dev/null || true
    if [ -d "$P/usr/share/icons/WhiteSur-dark" ] && [ -d "$P/usr/share/icons/WhiteSur" ]; then
      ICONE_CHIARO="WhiteSur"; ICONE_SCURO="WhiteSur-dark"
      rm -rf "$P/usr/share/icons/WhiteSur-light"   # variante non usata
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
XFWM_SCURO="$TEMA_SCURO"
[ -d "$P/usr/share/themes/$TEMA_SCURO/xfwm4" ] || XFWM_SCURO="Arc-Dark"
sed -i "s/@TEMA_SCURO@/$TEMA_SCURO/; s/@ICONE_SCURO@/$ICONE_SCURO/" "$P/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
sed -i "s/@ICONE_SCURO@/$ICONE_SCURO/" "$P/usr/share/alba/slick-greeter.conf.in"
sed -i "s/@TEMA_SCURO_XFWM@/$XFWM_SCURO/" "$P/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"

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
