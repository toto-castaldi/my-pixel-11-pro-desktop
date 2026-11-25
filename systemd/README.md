# systemd

Unità systemd utente della sessione grafica (modulo SESSION).

- `weston.service`: sostituisce l'unità di sistema `/etc/systemd/user/weston.service`; `install.sh` la collega in `~/.config/systemd/user/`. All'arresto toglie dall'ambiente del manager utente le variabili lasciate da Hyprland (`WAYLAND_DISPLAY`, `DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`).
- `start-session.sh`: comando di avvio dell'unità, collegato in `~/.local/libexec/my-pixel-11-pro-desktop/start-session`. Avvia Hyprland, oppure Weston se `/usr/bin/start-hyprland` non esiste.
- `session-socket.sh`: collegato in `~/.local/libexec/my-pixel-11-pro-desktop/session-socket`. `link` rende `$XDG_RUNTIME_DIR/wayland-0`, il socket che l'app Terminal usa per la clipboard condivisa con Android, un link al socket di Hyprland (lo lancia `hyprland.lua`); `unlink` lo toglie (avvio e arresto della sessione, `./install.sh --session weston`).

`./install.sh --session weston` toglie il link di `weston.service` e la maschera di `weston.socket` (torna l'unità di sistema di Weston); `./install.sh --session hyprland` li rimette.
