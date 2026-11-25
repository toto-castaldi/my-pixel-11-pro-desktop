# Installazione

`install.sh`, alla radice del repo, prepara la VM: installa i pacchetti Debian (anche da `trixie-backports`), collega i dotfile del repo sotto `$HOME` con link simbolici e salva una copia di backup di ogni file che sostituisce. È rieseguibile: una seconda esecuzione non cambia nulla e non crea nuovi backup.

Le funzioni dello script stanno in `lib/` e sono separate in pure (calcolo di percorsi, elenchi e decisioni, testabili senza toccare il sistema) e con effetti (apt, filesystem, systemd).

- `lib/core.sh`: funzioni pure (argomenti, lettura degli elenchi, pacchetti mancanti, percorsi dei link e dei backup, decisione `skip`/`link`/`backup` per ogni link, decisione `skip`/`mask`/`backup` per mascherare un'unità, comando della sessione grafica).
- `lib/effects.sh`: effetti; installa con `sudo apt-get install` solo i pacchetti mancanti di `packages/*.list` (`*.backports.list` con `-t trixie-backports`) crea i link elencati in `config/links.list`, maschera `weston.socket` con un link a `/dev/null` in `~/.config/systemd/user/` ed esegue `systemctl --user daemon-reload` solo se ha cambiato un'unità.
- Formato degli elenchi: una voce per riga, commenti da `#`. `config/links.list`: `<file nel repo> <destinazione relativa a $HOME>`.
- Un link già corretto si salta; un file o un link diverso si sposta in `<destinazione>.bak-<AAAAMMGGhhmmss>` prima di creare il link.
- Alla fine lo script stampa il numero di modifiche, oppure `Nessuna modifica` se non ne ha fatte. Se ha cambiato le unità, ricorda di riavviare la sessione con `systemctl --user restart weston`.

Verifica unica di lint, configurazione Hyprland e test: `scripts/gate.sh`.

Dettagli dell'installazione completa definiti da US-006.
