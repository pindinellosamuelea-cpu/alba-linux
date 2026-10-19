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

echo "==> Collego Alba al canale aggiornamenti…"
cat > /etc/apt/sources.list.d/alba.list <<'EOF'
# Canale aggiornamenti di Alba Linux
deb [trusted=yes] https://raw.githubusercontent.com/pindinellosamuelea-cpu/alba-linux/apt ./
EOF

echo "==> Scarico le novità (qualche minuto)…"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y alba-sistema

echo
echo "============================================================"
echo " Fatto! Alba è aggiornata alla versione $(cat /usr/share/alba/versione)."
echo " Riavvia il computer per vedere il nuovo aspetto."
echo " Da ora gli aggiornamenti arrivano da soli in Impostazioni."
echo "============================================================"
