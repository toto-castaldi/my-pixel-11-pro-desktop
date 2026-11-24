# Technical design — my-pixel-11-pro-desktop

**Target version:** v0.1.0

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
| Quality gate | shellcheck, `Hyprland --verify-config`, bats | Copre script e configurazione senza toccare il sistema |

## Open decisions

Decisions still to be closed and the backlog items that will close them:

- Modificatore principale delle scorciatoie e gestione di touch e gesti — SPIKE-001
- Robustezza dell'override al riavvio e agli aggiornamenti dell'app Terminal — SPIKE-002
- Server audio (PulseAudio o PipeWire) e comando per il volume — SPIKE-003
- Fattibilità della clipboard condivisa con Android — SPIKE-004
