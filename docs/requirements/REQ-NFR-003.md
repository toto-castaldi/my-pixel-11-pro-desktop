# REQ-NFR-003 — Nessun segreto nel repository

**State:** Active

Il repository non deve contenere segreti: chiavi SSH private, token, password o credenziali. Lo script di installazione non deve né generarli né copiarli nel repository. Si verifica controllando i file versionati e `.gitignore` prima di ogni commit.
