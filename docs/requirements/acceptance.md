# Release acceptance — v0.1.0

The version can be closed only when:

- Su una VM dell'app Terminal reimpostata, seguendo solo il README (accesso a GitHub, clone, `./install.sh`, riapertura del display), il display mostra Hyprland con renderer accelerato dalla GPU.
- Nella stessa sessione funzionano: waybar con workspace e ora; launcher; terminale; tastiera italiana; le scorciatoie documentate; sfondo; blocco e sblocco dello schermo; una notifica di prova; screenshot a schermo intero e di un'area; incolla dalla cronologia della clipboard.
- La sessione Hyprland si ripresenta dopo un riavvio completo della VM.
- Il comando documentato riporta il display a Weston e il comando inverso a Hyprland.
- Una seconda esecuzione di `install.sh` non cambia nulla e non crea backup.
- I file di sistema dell'app Terminal elencati in REQ-NFR-002 sono identici a prima dell'installazione.
