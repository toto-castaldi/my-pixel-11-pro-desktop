# Sessione grafica

All'apertura di una shell interattiva, l'app Terminal Android esegue `/etc/profile.d/activate_display.sh`. Con gfxstream attivo, questo lancia `/usr/local/bin/enable_gfxstream`, che scrive `~/weston.env`, apre una sessione logind su `tty1` e avvia `systemctl --user start weston`. Weston gira con il backend DRM sul display virtuale `CrosvmDisplay`, che Android mostra nella finestra del Terminal.

Il progetto non modifica quei file: definisce in `~/.config/systemd/user/` un `weston.service` che ha la precedenza su quello di `/etc/systemd/user/` e avvia Hyprland sul DRM, e maschera `weston.socket`. Hyprland legge le stesse variabili di `~/weston.env` (zink su Vulkan gfxstream).

Hyprland non può girare annidato dentro Weston 14: richiede `wl_compositor` versione 6, Weston offre la 5.

## Input

L'app Terminal espone alla VM quattro dispositivi virtio di crosvm, che Hyprland legge con libinput: tastiera, mouse relativo, touchscreen multitouch e trackpad multitouch. Tastiera e mouse arrivano solo dalla vista grafica (Display) dell'app e solo quando la sua finestra ha il focus di Android. Nella vista testuale i tasti vanno alla shell e non a Hyprland.

La tastiera virtio non ha i tasti SUPER/Meta: Meta lo prende Android, che toglie il focus alla finestra. Android consuma anche Tab, e quindi Alt+Tab. Alt, Ctrl (sinistri e destri), AltGr, Caps Lock, Esc, i tasti funzione e Print (keysym `Print`) arrivano a Hyprland. Il touch dello schermo del telefono arriva come touch assoluto.

## Riavvio e aggiornamenti dell'app

Esito di SPIKE-002 (`docs/spikes/SPIKE-002-avvio-aggiornamenti.md`).

- **Riavvio:** l'override regge. A ogni boot `enable_gfxstream` apre la sessione su `tty1` e dopo 3 s esegue `systemctl --user start weston`, che avvia Hyprland 4–5 s dopo il kernel. Ogni nuova shell interattiva di `droid` ripete il comando e riavvia Hyprland se non è attivo.
- **File dell'app:** l'app prepara la VM con cloud-init NoCloud, da un'immagine `cidata` su `/dev/vdb`. `init.sh` copia i file di sistema dell'app (quelli di REQ-NFR-002 e le sue unità in `/etc/systemd/system/`), più `~/.config/weston.ini`, e cloud-init scrive `~/.bash_aliases`. Tutto questo avviene una sola volta per `instance-id`. `~/weston.env` è riscritto a ogni shell interattiva. Il progetto non usa nessuno di questi file della home.
- **Aggiornamento dell'immagine:** il vecchio rootfs viene montato su `/mnt/backup` e `restore-backup` ripristina tutta la home, override compreso. I pacchetti si possono reinstallare solo dalle sorgenti apt del nuovo sistema, senza `trixie-backports`. Hyprland può quindi mancare mentre l'override resta attivo: l'unità del progetto deve ripiegare su Weston se `start-hyprland` non c'è, e dopo un aggiornamento va rieseguito `./install.sh`.
- **Socket:** Hyprland espone `wayland-1`; l'agente guest `linux_vm_manager` usa `wl-copy` su `wayland-0`.
