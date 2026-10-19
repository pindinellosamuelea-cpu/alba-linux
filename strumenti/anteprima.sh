#!/bin/bash
# Fa delle "foto" del desktop di Alba su uno schermo virtuale, per
# controllare l'aspetto senza un computer vero. Richiede il pacchetto
# alba-sistema installato e Xvfb, xfwm4, xfce4-panel, xfdesktop4, imagemagick.
# Uso: strumenti/anteprima.sh CARTELLA_USCITA
set -u
OUT="$(readlink -f "${1:-anteprime}")"
mkdir -p "$OUT"
export HOME=/tmp/anteprima-home LANG=it_IT.UTF-8 LC_ALL=it_IT.UTF-8 ALBA_DEMO=1
rm -rf "$HOME"; mkdir -p "$HOME"; cp -a /etc/skel/. "$HOME/"
export DISPLAY=:77
Xvfb :77 -screen 0 1600x900x24 >/dev/null 2>&1 &
sleep 2
eval "$(dbus-launch --sh-syntax)"

foto() { sleep "${2:-4}"; import -window root "$OUT/$1.png" && echo "foto: $1"; }

/usr/bin/alba-tema scuro
xfsettingsd >/dev/null 2>&1 &
sleep 1
xfwm4 >/dev/null 2>&1 &
xfdesktop >/dev/null 2>&1 &
sleep 2
python3 - <<'EOF'
import subprocess
subprocess.run(["xfconf-query","-c","xfce4-desktop","-l"])
EOF
for p in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep last-image) /backdrop/screen0/monitorscreen/workspace0/last-image /backdrop/screen0/monitor0/workspace0/last-image; do
  xfconf-query -c xfce4-desktop -p "$p" -n -t string -s /usr/share/backgrounds/alba/alba.png 2>/dev/null || \
  xfconf-query -c xfce4-desktop -p "$p" -s /usr/share/backgrounds/alba/alba.png
done
xfce4-panel >/dev/null 2>&1 &
foto 01-desktop-scuro 6

xfce4-popup-whiskermenu >/dev/null 2>&1
foto 02-menu-start 3
xdotool key Escape 2>/dev/null || pkill -f whiskermenu-popup 2>/dev/null

for modo in wifi bluetooth notifiche; do
  /usr/bin/alba-rapido "$modo" >/dev/null 2>&1 &
  PID=$!
  foto "05-menu-rapido-$modo" 4
  kill $PID 2>/dev/null; rm -f /tmp/alba-rapido.pid
done

for pagina in batteria aspetto wifi scheda-grafica aggiornamenti data-ora problemi telefono dispositivi; do
  /usr/bin/alba-impostazioni --pagina "$pagina" >/dev/null 2>&1 &
  PID=$!
  foto "10-impostazioni-$pagina" 4
  kill $PID 2>/dev/null
done

/usr/bin/alba-tema chiaro
sleep 2
/usr/bin/alba-impostazioni --pagina batteria >/dev/null 2>&1 &
PID=$!
foto 20-impostazioni-chiaro 5
kill $PID 2>/dev/null

# Schermata di accesso
pkill -x xfce4-panel; pkill -x xfdesktop; pkill -x xfwm4
if command -v slick-greeter >/dev/null; then
  mkdir -p /etc/lightdm
  slick-greeter --test-mode >/dev/null 2>&1 &
  PID=$!
  foto 30-schermata-accesso 6
  kill $PID 2>/dev/null
fi

kill %1 2>/dev/null
pkill -P $$ 2>/dev/null
exit 0
