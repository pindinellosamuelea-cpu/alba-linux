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

/usr/bin/alba-tema chiaro
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
xfce4-panel >/tmp/pannello.log 2>&1 &
python3 /usr/bin/alba-barra-alta >/tmp/barra-alta.log 2>&1 &
foto 01-desktop-chiaro 6
# desktop con una finestra aperta (come l'anteprima approvata)
/usr/bin/alba-impostazioni --pagina aspetto >/dev/null 2>&1 &
PID=$!
foto 01-desktop-finestra 5
import -window root -crop 1600x40+0+0 "$OUT/01-barra-alta.png" 2>/dev/null
kill $PID 2>/dev/null
cat /tmp/barra-alta.log; echo "app attiva: $(cat "${XDG_RUNTIME_DIR:-/tmp}/alba-app-attiva" 2>/dev/null)"

# griglia delle app (logo di Alba / tasto Windows): prima apertura e animazione
python3 /usr/bin/alba-app --sfondo >/tmp/alba-app.log 2>&1 &
sleep 3
python3 /usr/bin/alba-app >/dev/null 2>&1 &
for n in 1 2 3; do import -window root "$OUT/03-griglia-anim-$n.png" 2>/dev/null; done
foto 02-griglia-app 2
xdotool type --delay 80 "musi" 2>/dev/null
foto 02-griglia-ricerca 1.5
xdotool key Escape Escape 2>/dev/null
sleep 1
tail -5 /tmp/alba-app.log
xdotool mousemove 1500 15 2>/dev/null
/usr/bin/alba-rapido controlli >/dev/null 2>&1 &
PID=$!
for n in 1 2 3; do import -window root "$OUT/04-rapido-anim-$n.png" 2>/dev/null; done
sleep 1; kill $PID 2>/dev/null; rm -f /tmp/alba-rapido.pid; sleep 0.5
for modo in controlli notifiche; do
  /usr/bin/alba-rapido "$modo" >/dev/null 2>&1 &
  PID=$!
  foto "05-menu-rapido-$modo" 4
  kill $PID 2>/dev/null; rm -f /tmp/alba-rapido.pid
done
/usr/bin/alba-osd --prova >/dev/null 2>&1 &
PID=$!; foto "08-indicatore-volume" 1; kill $PID 2>/dev/null
/usr/bin/alba-menu-x >/dev/null 2>&1 &
PID=$!; foto "07-menu-super-x" 3; kill $PID 2>/dev/null
/usr/bin/alba-tema scuro; sleep 2
foto 01-desktop-scuro 3
/usr/bin/alba-rapido controlli >/dev/null 2>&1 &
PID=$!; foto "06-menu-rapido-scuro" 4; kill $PID 2>/dev/null; rm -f /tmp/alba-rapido.pid
/usr/bin/alba-tema chiaro; sleep 1

for pagina in batteria aspetto wifi scheda-grafica aggiornamenti data-ora problemi telefono dispositivi tastiera suono alimentazione; do
  /usr/bin/alba-impostazioni --pagina "$pagina" >/dev/null 2>&1 &
  PID=$!
  foto "10-impostazioni-$pagina" 4
  kill $PID 2>/dev/null
done

/usr/bin/alba-tema scuro
sleep 2
/usr/bin/alba-impostazioni --pagina batteria >/dev/null 2>&1 &
PID=$!
foto 20-impostazioni-scuro 5
kill $PID 2>/dev/null

# Configurazione iniziale (primo avvio dopo l'installazione)
pkill -x xfce4-panel; pkill -x xfdesktop
for n in 0 2 3 5; do
  python3 /usr/libexec/alba/alba-oobe --prova $n >/tmp/oobe.log 2>&1 &
  PID=$!; foto "50-configurazione-$n" 3; kill $PID 2>/dev/null
done
tail -5 /tmp/oobe.log

# Schermata "Sto applicando l'aggiornamento" (tema di avvio, renderer finestra X11)
if apt-get install -y -q plymouth-x11 >/dev/null 2>&1 && [ -e /usr/lib/x86_64-linux-gnu/plymouth/renderers/x11.so ]; then
  plymouth-set-default-theme alba >/dev/null 2>&1
  pkill -x xfce4-panel; pkill -x xfdesktop
  mkdir -p /run/plymouth
  plymouthd --no-daemon --debug --debug-file=/tmp/plymouth.log --kernel-command-line="quiet splash plymouth.force-splash" >/dev/null 2>&1 &
  sleep 1
  plymouth show-splash; plymouth change-mode --system-upgrade 2>/dev/null
  plymouth system-update --progress=45
  plymouth display-message --text="Installo le novità…"
  foto 35-aggiornamento-al-riavvio 2
  plymouth quit 2>/dev/null; sleep 1
  echo "== plymouth"; grep -iE "error|script|renderer|x11|fail" /tmp/plymouth.log | tail -25
fi

# Schermata di accesso
pkill -x xfce4-panel; pkill -x xfdesktop; pkill -x xfwm4
HOME=/tmp/accesso-prova python3 /usr/libexec/alba/alba-accesso --prova >/tmp/accesso.log 2>&1 &
PID=$!
foto 30-schermata-accesso 4
kill $PID 2>/dev/null
# passaggio accesso -> desktop: "Benvenuto", poi lo sfondo diventa quello del desktop
HOME=/tmp/accesso-prova python3 /usr/libexec/alba/alba-accesso --prova --prova-ingresso >>/tmp/accesso.log 2>&1 &
PID=$!
foto 31-accesso-benvenuto 1.9
foto 32-accesso-dopo 2.5
kill $PID 2>/dev/null
cat /tmp/accesso.log 2>/dev/null | tail -5
if false && command -v slick-greeter >/dev/null; then
  mkdir -p /etc/lightdm
  slick-greeter --test-mode >/dev/null 2>&1 &
  PID=$!
  foto 30-schermata-accesso 6
  kill $PID 2>/dev/null
fi

echo "== Avvisi del tema/CSS della barra =="
grep -iE "css|theme|parsing|warning" /tmp/pannello.log | sort | uniq -c | head -30
kill %1 2>/dev/null
pkill -P $$ 2>/dev/null
exit 0
