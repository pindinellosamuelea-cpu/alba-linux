#!/bin/bash
# Collega un computer con Alba già installata al canale aggiornamenti
# e installa subito le novità. Non cancella file né programmi.
#
# Uso (nel Terminale):
#   curl -fsSL https://raw.githubusercontent.com/pindinellosamuelea-cpu/alba-linux/main/aggiorna-alba.sh | sudo bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Avvia il comando con sudo davanti."
  exit 1
fi

BASE=https://raw.githubusercontent.com/pindinellosamuelea-cpu/alba-linux
CANALE="$BASE/apt ./"
CHIAVE=/usr/share/keyrings/alba-archive-keyring.asc
export DEBIAN_FRONTEND=noninteractive

echo "==> Collego Alba al canale aggiornamenti…"
# Con la firma digitale se il canale è firmato, altrimenti solo HTTPS
if curl -fsSL -o "$CHIAVE" "$BASE/main/pacchetto/chiave-pubblica.asc" && \
   curl -fsSL -o /dev/null "$BASE/apt/InRelease"; then
  echo "deb [signed-by=$CHIAVE] $CANALE" > /etc/apt/sources.list.d/alba.list
  echo "    (canale firmato)"
else
  echo "deb [trusted=yes] $CANALE" > /etc/apt/sources.list.d/alba.list
fi

echo "==> Scarico le novità (qualche minuto)…"
apt-get update
apt-get install -y alba-sistema

echo
echo "============================================================"
echo " Fatto! Alba è aggiornata alla versione $(cat /usr/share/alba/versione)."
echo " Riavvia il computer per vedere il nuovo aspetto."
echo " Da ora gli aggiornamenti arrivano da soli in Impostazioni."
echo "============================================================"
