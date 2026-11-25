# Test strategy

| Livello | Strumento | Cosa prova | Quando |
| --- | --- | --- | --- |
| Lint | `shellcheck` | Correttezza statica degli script Bash | Quality gate |
| Configurazione | `Hyprland --verify-config` | Il file Lua di Hyprland è valido | Quality gate |
| Unit | `bats` | Le funzioni pure di `lib/` (percorsi, elenchi, decisioni di backup), senza filesystem, rete, git o systemd | Quality gate |
| Integrazione | `install.sh` sulla VM | Pacchetti, link, backup e idempotenza sul sistema reale | Durante gli item che toccano l'installazione |
| End-to-end | VM reimpostata + display | Il desktop completo dopo la procedura del README | Chiusura della versione |

Le prove di integrazione ed end-to-end richiedono la VM dell'app Terminal e l'accesso al display; i loro esiti si riportano nell'`outcome` dell'item. Il setup con cui si raggiunge la VM (telefono sul dock, adb via USB o Wi-Fi da un host adb, `ssh pixel`) è in `docs/design/dev-environment.md`.
