# Security and observability

- **Segreti:** la chiave SSH per GitHub vive solo in `~/.ssh/` della VM e non entra nel repository. `.gitignore` esclude chiavi, token e file `.env`. Lo script non genera né copia segreti.
- **Privilegi:** `install.sh` gira come utente `droid` e usa `sudo` solo per apt.
- **Log:** Hyprland e le applicazioni della sessione scrivono nel journal dell'utente (`journalctl --user -u weston`). `install.sh` stampa su stdout un riepilogo delle azioni (installato, collegato, backup, invariato).
