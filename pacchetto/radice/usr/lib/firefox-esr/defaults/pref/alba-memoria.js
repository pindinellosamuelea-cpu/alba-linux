// Alba Linux: Firefox più leggero sulla memoria (meno processi in parallelo,
// le schede non usate da tempo vengono "messe a dormire" se la RAM scarseggia).
pref("dom.ipc.processCount", 4);
pref("browser.tabs.unloadOnLowMemory", true);
pref("browser.sessionstore.interval", 60000);
// Musica e video protetti (Apple Music, Netflix, Spotify web...): Firefox
// scarica da solo il componente necessario (Widevine) la prima volta.
pref("media.eme.enabled", true);
pref("media.gmp-widevinecdm.enabled", true);
pref("media.gmp-widevinecdm.visible", true);
