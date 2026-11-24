# Modules

Moduli logici del progetto, usati per classificare gli item del backlog. Non sono submodule git.

| ID | Nome | Responsabilità | Posizione |
| --- | --- | --- | --- |
| MOD-001 | INSTALL | Script di installazione, elenco dei pacchetti, collegamento dei dotfile e backup | `install.sh`, `lib/`, `packages/` |
| MOD-002 | SESSION | Avvio della sessione grafica: unità systemd utente che sostituisce Weston con Hyprland e ritorno a Weston | `systemd/` |
