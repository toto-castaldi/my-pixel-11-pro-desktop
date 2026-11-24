# Invariants and consistency

- I file gestiti dall'app Terminal (REQ-NFR-002) non vengono mai scritti: `install.sh` opera solo sotto `$HOME`, tramite apt e con `systemctl --user`.
- `install.sh` è idempotente: ogni passo verifica lo stato prima di agire, e un link già corretto non viene toccato.
- Un file dell'utente non viene mai sovrascritto senza un backup.
- Il ritorno a Weston è sempre possibile rimuovendo l'override: nessun file di Weston viene disinstallato o modificato.
