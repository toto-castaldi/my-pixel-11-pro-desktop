# REQ-NFR-002 — Nessuna modifica ai file di sistema dell'app Terminal

**State:** Active

L'installazione non deve modificare i file che l'app Terminal Android gestisce nella VM (`/etc/profile.d/activate_display.sh`, `/usr/local/bin/enable_display`, `/usr/local/bin/enable_gfxstream`, `/etc/systemd/user/weston.*`). Tutte le personalizzazioni stanno nella home dell'utente o in pacchetti Debian, così sopravvivono agli aggiornamenti dell'app. Si verifica confrontando quei file prima e dopo l'installazione.
