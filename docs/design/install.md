# Installazione

`install.sh`, alla radice del repo, prepara la VM: installa i pacchetti Debian (anche da `trixie-backports`), collega i dotfile del repo sotto `$HOME` con link simbolici e salva una copia di backup di ogni file che sostituisce. È rieseguibile: una seconda esecuzione non cambia nulla e non crea nuovi backup.

Le funzioni dello script stanno in `lib/` e sono separate in pure (calcolo di percorsi, elenchi e decisioni, testabili senza toccare il sistema) e con effetti (apt, filesystem, systemd).

Dettagli definiti da TEC-002 e US-006.
