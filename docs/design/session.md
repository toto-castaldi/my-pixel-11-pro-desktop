# Sessione grafica

All'apertura di una shell interattiva, l'app Terminal Android esegue `/etc/profile.d/activate_display.sh`. Con gfxstream attivo, questo lancia `/usr/local/bin/enable_gfxstream`, che scrive `~/weston.env`, apre una sessione logind su `tty1` e avvia `systemctl --user start weston`. Weston gira con il backend DRM sul display virtuale `CrosvmDisplay`, che Android mostra nella finestra del Terminal.

Il progetto non modifica quei file: definisce in `~/.config/systemd/user/` un `weston.service` che ha la precedenza su quello di `/etc/systemd/user/` e avvia Hyprland sul DRM, e maschera `weston.socket`. Hyprland legge le stesse variabili di `~/weston.env` (zink su Vulkan gfxstream).

Hyprland non può girare annidato dentro Weston 14: richiede `wl_compositor` versione 6, Weston offre la 5.

## Input

L'app Terminal espone alla VM quattro dispositivi virtio di crosvm, che Hyprland legge con libinput: tastiera, mouse relativo, touchscreen multitouch e trackpad multitouch. Tastiera e mouse arrivano solo dalla vista grafica (Display) dell'app e solo quando la sua finestra ha il focus di Android. Nella vista testuale i tasti vanno alla shell e non a Hyprland.

La tastiera virtio non ha i tasti SUPER/Meta: Meta lo prende Android, che toglie il focus alla finestra. Android consuma anche Tab, e quindi Alt+Tab. Alt, Ctrl (sinistri e destri), AltGr, Caps Lock, Esc, i tasti funzione e Print (keysym `Print`) arrivano a Hyprland. Il touch dello schermo del telefono arriva come touch assoluto.

Comportamento al riavvio e agli aggiornamenti dell'app: definito da SPIKE-002.
