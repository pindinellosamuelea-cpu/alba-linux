# Alba Linux: lavori del 20 ottobre 2026 (dalle 14:00)

Richieste di Alessandro (messaggio delle 06:11). Stato RAM dall'ultimo riepilogo (1.1.39, Firefox chiuso): 1,9 GB usati.

1. **Dall'accesso al desktop**: passaggio fluido, coerente, senza animazioni senza senso e senza scatti. La dissolvenza aggiunta ieri non è piaciuta ed è stata tolta.
2. **Revisione completa di tutto il sistema**, dal primo punto all'ultimo: animazioni, transizioni, schermate sbagliate, RAM, CPU, GPU. Tutto deve essere coerente.
   - **Microfono**: livelli e driver. A volte non capta la voce, problema che prima con altri sistemi non c'era. Da controllare: PipeWire, guadagno e AGC, firmware SOF/HDA, porta jack/mic interno, echo-cancel.
3. **OSD del volume e della luminosità** quando si usano i tasti Fn:
   - un solo indicatore che si aggiorna, mai 300 notifiche;
   - stile Windows 11 (in basso al centro), oppure in alto;
   - icone Wi-Fi, Bluetooth e batteria da ritoccare, tutte coerenti.
4. **Ventole**: curva graduale in base alla temperatura (per esempio a 70 °C sale piano), non da 0 a 1600 giri di colpo. Portatile MSI GL63 8SE: valutare isw/msi-ec, nbfc-linux, fancontrol, altrimenti spiegare il limite.
   - **Widget sulla schermata di accesso**, interattivi: meteo, calendario, eventualmente musica.
   - **Grafica più seria**: icone e grafica meno da giocattolo, senza cambiare il font.
5. **Aspetto più professionale**, che sembri un sistema serio.
   - **Apple Music / iTunes**: app (es. Cider) o web app installata come programma.
   - **Office**: integrazione semplice e fluida (LibreOffice con aspetto e formati Microsoft, apertura dei file .docx/.xlsx/.pptx, magari OnlyOffice).
   - **Driver Surface**: completare e verificare.
6. **Controllo di driver e aggiornamenti**: aggiornamenti automatici, driver aggiornati, schede di acquisizione (cinesi e di marca), webcam, microfono, layout della tastiera.
7. **Installer della ISO in stile Windows ma migliore**: niente modalità live "prova Alba".
   - L'installazione parte subito: scegli il disco, conferma, e l'installazione è pulita.
   - Poi stacchi la chiavetta e al primo avvio fai la configurazione (OOBE: lingua, tastiera, Wi-Fi, utente, fuso orario), tutto con grafica Alba.

## Versione
Questo è un aggiornamento importante: esce come **Alba 1.2**. Nel workflow la versione passa da `1.1.<run>` a `1.2.<run>` solo quando i lavori sono pronti (non prima, per non pubblicare una 1.2 incompleta). Nelle novità e nella pagina Aggiornamenti va presentata come "Alba 1.2".
