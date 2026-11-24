# Configuration and local runtime

- **Ambiente grafico:** `~/weston.env`, scritto dall'app Terminal a ogni attivazione del display, definisce `MESA_LOADER_DRIVER_OVERRIDE=zink`, `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/gfxstream_vk_icd.json`, `MESA_VK_WSI_DEBUG=sw,linear`, `XWAYLAND_NO_GLAMOR=1`. L'override lo legge come `EnvironmentFile`; il progetto non lo modifica.
- **Sessione:** l'override imposta `XDG_SESSION_TYPE=wayland`, `XDG_CURRENT_DESKTOP=Hyprland` e `DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus` (bus di sessione di `dbus-user-session`).
- **Posizioni:** dotfile in `config/<app>/` → `~/.config/<app>/`; unità systemd in `systemd/` → `~/.config/systemd/user/`; backup accanto al file sostituito con suffisso `.bak-<data>`.
- **Comandi:** `./install.sh` per installare o riallineare, `./install.sh --help` per le opzioni; il quality gate è in `AGENTS.md` §6.
