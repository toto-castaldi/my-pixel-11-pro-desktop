# Desktop

I dotfile stanno in `config/<applicazione>/` e vengono collegati in `~/.config/<applicazione>/`. Hyprland usa la configurazione Lua introdotta nella 0.55 (`~/.config/hypr/hyprland.lua`, API `hl.*`), con Hyprland 0.55 da `trixie-backports`.

Componenti: foot (terminale), fuzzel (launcher), waybar (barra), tastiera `it`. Il blur è disattivato per contenere il carico sulla GPU virtualizzata. All'avvio Hyprland esporta l'ambiente grafico verso D-Bus e systemd (`dbus-update-activation-environment`) e lancia waybar.

Le scorciatoie usano `ALT` come modificatore principale, con `CTRL + ALT` per quelle che rischiano di scontrarsi con le applicazioni. Non si usano SUPER né scorciatoie con Tab, perché non arrivano a Hyprland (`design/session`). AltGr resta libero per il layout `it`.

Audio e clipboard: definiti da SPIKE-003 e SPIKE-004.
