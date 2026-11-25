# Desktop

I dotfile stanno in `config/<applicazione>/` e vengono collegati in `~/.config/<applicazione>/`. Hyprland usa la configurazione Lua introdotta nella 0.55 (`~/.config/hypr/hyprland.lua`, API `hl.*`), con Hyprland 0.55 da `trixie-backports`.

Componenti: foot (terminale), fuzzel (launcher), waybar (barra), tastiera `it`. Il blur e le ombre sono disattivati per contenere il carico sulla GPU virtualizzata. All'avvio Hyprland esporta l'ambiente grafico verso D-Bus e systemd (`dbus-update-activation-environment`) e lancia waybar. Le variabili grafiche (zink su Vulkan gfxstream) non stanno in `hyprland.lua`: arrivano da `~/weston.env` tramite l'unità (`design/session`).

File collegati da `config/links.list`: `config/hypr/hyprland.lua`, `config/waybar/config.jsonc` e `style.css`, `config/foot/foot.ini`, `config/fuzzel/fuzzel.ini`, ognuno nel percorso omonimo sotto `~/.config/`. Pacchetti in `packages/base.list`: `foot`, `waybar`, `fuzzel`, `fonts-dejavu-core` (font di barra, terminale e launcher) e `dbus-bin`. La VM ha solo la locale `C.UTF-8`: l'ora di waybar usa formati numerici (`%H:%M`, `%d/%m/%Y`) e non nomi di giorni o mesi.

Waybar: a sinistra `hyprland/workspaces`, al centro `hyprland/window`, a destra `hyprland/language` e `clock`.

Le scorciatoie usano `ALT` come modificatore principale, con `CTRL + ALT` per quelle che rischiano di scontrarsi con le applicazioni o costano care se premute per errore. Non si usano SUPER né scorciatoie con Tab, perché non arrivano a Hyprland (`design/session`). AltGr resta libero per il layout `it`.

| Bind | Azione |
| --- | --- |
| `ALT + Return` | `foot` |
| `ALT + SPACE` | `fuzzel` |
| `ALT + Q`, `ALT + F4` | chiude la finestra |
| `ALT + F` / `ALT + V` | schermo intero / flottante |
| `ALT + frecce` | focus |
| `ALT + code:10…19` | workspace 1…10 |
| `ALT + SHIFT + code:10…19` | sposta la finestra nel workspace 1…10 |
| `ALT + rotella`, `ALT + mouse:272/273` | workspace successivo/precedente, sposta/ridimensiona |
| `CTRL + ALT + Q` | esce (`hyprshutdown` se c'è, altrimenti `hl.dsp.exit()`) |

I workspace usano i keycode (`code:10` è il tasto `1`) e non i keysym, così il bind con `SHIFT` non dipende dal simbolo che il layout `it` produce con Maiusc. L'elenco per l'utente è nel README.

Audio: server PulseAudio, quello dell'immagine dell'app Terminal; PipeWire non si installa. Volume con `pactl set-sink-volume @DEFAULT_SINK@ +5%` / `-5%` e `pactl set-sink-mute @DEFAULT_SINK@ toggle`; in waybar il modulo `pulseaudio`; scorciatoie sui tasti `XF86AudioRaiseVolume`, `XF86AudioLowerVolume` e `XF86AudioMute`, con un'alternativa `ALT`. Su Android 17 `CD1A.261005.003` l'audio della VM non arriva al telefono: Android (SELinux tra crosvm e audioserver) rifiuta gli stream della scheda virtio-snd. PulseAudio non trova quindi una scheda utilizzabile e riprova circa ogni 50 secondi, restando a lungo senza rispondere ai client. Il controllo del volume (REQ-DSK-004) non fa parte della versione aperta.

Clipboard condivisa con Android: l'app Terminal la offre tramite l'agente della VM `linux_vm_manager`, che ai cambi di focus della sua finestra esegue `wl-copy` (Android → VM) e `wl-paste --no-newline` (VM → Android) come `droid` sul socket fisso `wayland-0`. Hyprland apre `wayland-1`, quindi oggi la condivisione non funziona; con `wayland-0` che punta al socket di Hyprland funziona nei due versi, solo per il testo (SPIKE-004). Il progetto non la attiva ancora: è REQ-DSK-005, pianificata per la v0.2.0.
