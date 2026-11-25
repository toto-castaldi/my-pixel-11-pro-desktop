# Technical design — my-pixel-11-pro-desktop

**Target version:** nessuna versione aperta

The *how* of the project, one file per topic (`docs/process/docs.md` §2). Requirements are in `docs/requirements/`. Items reference a topic as `design/<topic>` (the file `docs/design/<topic>.md`). Topics grow with the items that introduce or change design choices; relevant decisions with meaningful alternatives go into `docs/adr/`. List the topics with `python3 .agents/tools/backlog.py docs`; read only the files you need.

Add a topic by copying `_TEMPLATE.md` to `<topic>.md` (lowercase kebab-case); split a topic that covers more than one subject.

## Initial architectural decisions

| Decision | Choice | Rationale |
| -------- | ------ | --------- |
| Compositor | Hyprland 0.55 da `trixie-backports`, con configurazione Lua | Richiesto dall'utente; è l'unica versione disponibile per trixie |
| Avvio della sessione | Hyprland sostituisce Weston sul DRM tramite un `weston.service` utente in `~/.config/systemd/user/` | L'annidamento dentro Weston 14 non funziona (`wl_compositor` v5 contro v6 richiesta); l'override non tocca i file dell'app Terminal (REQ-NFR-002) |
| Rendering | Le variabili di `~/weston.env` (zink su Vulkan gfxstream) | Sono quelle che l'app Terminal prepara per l'accelerazione GPU |
| Dotfile | Link simbolici da `$HOME` ai file del repository, con backup | Ogni modifica locale è subito versionata |
| Linguaggio degli script | Bash, con funzioni pure separate dagli effetti | Disponibile ovunque nella VM; le funzioni pure si testano con bats |
| Modificatore delle scorciatoie | `ALT`, alternativa `CTRL + ALT` | SUPER/Meta e Tab non arrivano a Hyprland dalla finestra del Terminal |
| Server audio | PulseAudio dell'immagine, volume con `pactl`, modulo waybar `pulseaudio` | PipeWire non risolve il blocco, che sta in Android; PulseAudio è già installato |
| Quality gate | shellcheck, `Hyprland --verify-config`, bats | Copre script e configurazione senza toccare il sistema |
| Socket della clipboard condivisa | Link `wayland-0 → $WAYLAND_DISPLAY` creato all'avvio di Hyprland (`systemd/session-socket.sh`) | Hyprland 0.55 rifiuta `--socket` senza `--wayland-fd` (passaggio di un socket già aperto); il link non cambia il socket delle app della sessione e non tocca il ripiego su Weston (`design/session`) |

## Open decisions

Decisions still to be closed and the backlog items that will close them:

Nessuna.
