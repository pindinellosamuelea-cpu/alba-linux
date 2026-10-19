#!/bin/bash
# Costruisce l'ISO di Alba Linux.
#
# Funziona su qualsiasi Linux con Docker (anche Windows con WSL2 + Docker
# Desktop): la costruzione avviene in un contenitore Debian 13, così il
# risultato è identico ovunque. Su Debian 13 si può anche costruire
# direttamente senza Docker.
#
# Requisiti: ~25 GB liberi, 4 GB di RAM, connessione Internet.
# Tempo: 30-90 minuti a seconda della connessione.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

costruisci() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y live-build debootstrap xorriso squashfs-tools mtools \
    dosfstools ca-certificates curl gnupg python3 python3-pil fonts-dejavu-core \
    dpkg-dev git sassc
  chmod +x auto/* config/hooks/normal/*.hook.chroot strumenti/*.sh
  # Il pacchetto alba-sistema (aspetto, Impostazioni, aggiornamenti)
  mkdir -p config/packages.chroot
  if ! ls config/packages.chroot/alba-sistema_*.deb >/dev/null 2>&1; then
    TEMA_FLUENT=1 bash strumenti/costruisci-pacchetto.sh "${ALBA_VERSIONE:-1.1.0}" config/packages.chroot
  fi
  lb clean --purge 2>/dev/null || true
  lb config
  lb build
  ISO="$(ls -1 alba-linux*.iso | head -1)"
  sha256sum "$ISO" > "$ISO.sha256"
  echo
  echo "Fatto! ISO pronta: $ISO"
}

if [ "${1:-}" = "--dentro" ]; then
  costruisci
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  echo ">> Costruzione in un contenitore Debian 13 (trixie)…"
  docker run --rm --privileged \
    -v "$PWD":/alba -w /alba -e ALBA_VERSIONE \
    debian:trixie bash /alba/build.sh --dentro
elif grep -q 'VERSION_CODENAME=trixie' /etc/os-release 2>/dev/null; then
  [ "$(id -u)" -eq 0 ] || { echo "Esegui con sudo: sudo ./build.sh"; exit 1; }
  costruisci
else
  echo "Serve Docker oppure un sistema Debian 13."
  echo "Installa Docker: https://docs.docker.com/engine/install/"
  exit 1
fi
