// Alba Linux: Firefox più leggero sulla memoria (meno processi in parallelo,
// le schede non usate da tempo vengono "messe a dormire" se la RAM scarseggia).
pref("dom.ipc.processCount", 4);
pref("browser.tabs.unloadOnLowMemory", true);
pref("browser.sessionstore.interval", 60000);
