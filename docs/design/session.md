# Sessione grafica

All'apertura di una shell interattiva, l'app Terminal Android esegue `/etc/profile.d/activate_display.sh`. Con gfxstream attivo, questo lancia `/usr/local/bin/enable_gfxstream`, che scrive `~/weston.env`, apre una sessione logind su `tty1` e avvia `systemctl --user start weston`. Weston gira con il backend DRM sul display virtuale `CrosvmDisplay`, che Android mostra nella finestra del Terminal.

Il progetto non modifica quei file: definisce in `~/.config/systemd/user/` un `weston.service` che ha la precedenza su quello di `/etc/systemd/user/` e avvia Hyprland sul DRM, e maschera `weston.socket`. Hyprland legge le stesse variabili di `~/weston.env` (zink su Vulkan gfxstream).

Hyprland non può girare annidato dentro Weston 14: richiede `wl_compositor` versione 6, Weston offre la 5.

Comportamento di input, riavvio e aggiornamenti dell'app: definiti da SPIKE-001 e SPIKE-002.
