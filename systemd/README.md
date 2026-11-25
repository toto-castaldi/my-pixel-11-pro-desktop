# systemd

Unità systemd utente della sessione grafica (modulo SESSION).

- `weston.service`: sostituisce l'unità di sistema `/etc/systemd/user/weston.service`; `install.sh` la collega in `~/.config/systemd/user/`.
- `start-session.sh`: comando di avvio dell'unità, collegato in `~/.local/libexec/my-pixel-11-pro-desktop/start-session`. Avvia Hyprland, oppure Weston se `/usr/bin/start-hyprland` non esiste.
