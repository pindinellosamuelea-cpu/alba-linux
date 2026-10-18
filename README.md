# Alba Linux 🌅

Semplice come Windows, libero e sicuro come Linux.
Basata su **Debian 13 "trixie"** (la base più stabile e compatibile), con desktop **XFCE** leggero configurato in stile Windows 11 e un'identità tutta sua.

## Cosa c'è dentro

| Area | Cosa trovi |
|---|---|
| **Interfaccia** | Barra in basso con Start e app al centro, area notifiche e orologio a destra, finestre con pulsanti a destra e aggancio ai bordi. Tema chiaro/scuro, sfondo e logo Alba, app *Benvenuto in Alba*. |
| **Scorciatoie Windows** | ⊞ Start · ⊞+E file · ⊞+D desktop · ⊞+L blocca · ⊞+←/→ affianca · ⊞+Shift+S cattura · Ctrl+Shift+Esc gestione attività · Alt+F4 · Alt+Tab |
| **Programmi .exe** | Doppio clic e si aprono, senza installare nulla. Wine è integrato nel sistema e già completo di .NET (Wine Mono), Visual C++ 2015‑2022, componenti web (Gecko) e DirectX su Vulkan (DXVK). I programmi installati compaiono nel menu Start. |
| **Uso quotidiano** | Firefox, LibreOffice, VLC, visualizzatore immagini e PDF, scanner, stampanti, negozio di app (Flathub). |
| **Programmazione** | VSCodium, Git, Python, Node.js, Java, compilatori C/C++, Docker. |
| **Gaming** | Steam con Proton, Lutris, GameMode, MangoHud, driver Vulkan a 32 e 64 bit. |
| **PC poco potenti** | XFCE leggero, RAM compressa (zram), servizi pesanti avviati solo quando servono. |
| **Grafica** | AMD, Intel e NVIDIA (anche modelli vecchi) funzionano subito con i driver liberi. Per NVIDIA, *Driver grafici* sceglie e installa il driver ufficiale adatto al modello. Voce di avvio "grafica sicura" per i casi difficili. |
| **Rete e Bluetooth** | Firmware per Wi‑Fi interno e chiavette USB (Intel, Realtek, Broadcom, Atheros/Qualcomm, MediaTek, Marvell…), Ethernet, modem USB, Bluetooth. |

## Sicurezza

- **Firewall attivo** di serie: blocca tutte le connessioni in entrata.
- **Aggiornamenti di sicurezza automatici** ogni giorno.
- **AppArmor** attivo per isolare i programmi.
- **Protezioni del kernel** e di rete (`/etc/sysctl.d/90-alba-sicurezza.conf`).
- **Controllo dei .exe** stile SmartScreen: alla prima apertura Alba mostra da quale sito è stato scaricato il file e permette di controllarlo con l'antivirus ClamAV.
- **Secure Boot** supportato, nessun servizio di accesso remoto attivo, schermo bloccato dopo la sospensione.
- **Punti di ripristino** con Timeshift.

## Come ottenere l'ISO

### Opzione A — Senza PC Linux (GitHub, consigliata)
1. Carica questa cartella in un repository GitHub **pubblico**.
2. Vai su **Actions → Costruisci ISO Alba → Run workflow**.
3. Dopo circa un'ora scarica l'ISO da **Artifacts** (`alba-linux-iso`).

### Opzione B — Sul tuo computer
Con Docker (Linux, oppure Windows con WSL2 + Docker Desktop):
```bash
sudo ./build.sh
```
Servono circa 25 GB liberi e una connessione Internet. Il risultato è `alba-linux-amd64.hybrid.iso`.

## Provarla e installarla
1. Scrivi l'ISO su una chiavetta USB (≥ 8 GB) con **Ventoy**, **balenaEtcher** o **Rufus** (modalità DD).
2. Avvia il PC dalla chiavetta: Alba parte in modalità live senza toccare il disco (utente `alba`).
3. Dalla finestra di benvenuto premi **Installa Alba** e segui la procedura guidata.

Puoi provarla anche in una macchina virtuale (VirtualBox, VMware, GNOME Boxes) con almeno 4 GB di RAM.

## Limiti da conoscere (in modo onesto)
- **Processori:** PC con processore x86 a 64 bit (Intel/AMD, praticamente tutti dal 2008 in poi). Debian 13 non supporta più i vecchi processori solo a 32 bit; Mac con chip Apple e dispositivi ARM richiedono una versione diversa.
- **Programmi .exe:** la grande maggioranza funziona, ma non il 100%. Non funzionano driver Windows, alcuni antivirus/anti‑cheat a livello di kernel e qualche software molto recente (es. alcune versioni di Adobe). Per i giochi usa Steam con Proton.
- **NVIDIA recenti:** il driver ufficiale si installa con un clic dopo l'installazione (serve Internet). Con Secure Boot attivo ti verrà chiesto di confermare una chiave al riavvio.
- **Zero bug garantiti non esistono** in nessun sistema operativo: Alba usa la versione stabile di Debian, la più collaudata, proprio per ridurli al minimo.

## Personalizzare
- Pacchetti: `config/package-lists/*.list.chroot`
- Script eseguiti durante la costruzione: `config/hooks/normal/`
- File copiati nel sistema (tema, scorciatoie, app Alba): `config/includes.chroot/`
- Sfondo e logo: `python3 strumenti/genera-grafica.py`
- Lingua, tastiera e fuso orario: riga `--bootappend-live` in `auto/config` (predefiniti: italiano, tastiera svizzera + italiana con Alt+Shift, Europe/Zurich).
