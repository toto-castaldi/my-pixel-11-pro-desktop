# Desktop

I dotfile stanno in `config/<applicazione>/` e vengono collegati in `~/.config/<applicazione>/`. Hyprland usa la configurazione Lua introdotta nella 0.55 (`~/.config/hypr/hyprland.lua`, API `hl.*`), con Hyprland 0.55 da `trixie-backports`.

Componenti: foot (terminale), fuzzel (launcher), waybar (barra), tastiera `it`. Il blur è disattivato per contenere il carico sulla GPU virtualizzata. All'avvio Hyprland esporta l'ambiente grafico verso D-Bus e systemd (`dbus-update-activation-environment`) e lancia waybar.

Le scorciatoie usano `ALT` come modificatore principale, con `CTRL + ALT` per quelle che rischiano di scontrarsi con le applicazioni. Non si usano SUPER né scorciatoie con Tab, perché non arrivano a Hyprland (`design/session`). AltGr resta libero per il layout `it`.

Audio: server PulseAudio, quello dell'immagine dell'app Terminal; PipeWire non si installa. Volume con `pactl set-sink-volume @DEFAULT_SINK@ +5%` / `-5%` e `pactl set-sink-mute @DEFAULT_SINK@ toggle`; in waybar il modulo `pulseaudio`; scorciatoie sui tasti `XF86AudioRaiseVolume`, `XF86AudioLowerVolume` e `XF86AudioMute`, con un'alternativa `ALT`. Su Android 17 `CD1A.261005.003` l'audio della VM non arriva al telefono: Android (SELinux tra crosvm e audioserver) rifiuta gli stream della scheda virtio-snd. PulseAudio non trova quindi una scheda utilizzabile e riprova circa ogni 50 secondi, restando a lungo senza rispondere ai client. Il controllo del volume (REQ-DSK-004) non fa parte della versione aperta.

Clipboard: definita da SPIKE-004.
