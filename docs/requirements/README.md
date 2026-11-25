# Requirements — my-pixel-11-pro-desktop

**Target version:** v0.2.0

**State:** baseline

The *what* of the project, one file per requirement (`docs/process/docs.md` §1). The *how* is in `docs/design/`. Every change of scope or behavior is recorded here before updating backlog and implementation (`docs/PROCESS.md` §3, `docs/process/docs.md`). List the requirements with `python3 .agents/tools/backlog.py docs`; read only the files you need.

| File | Content |
| --- | --- |
| `README.md` | goal, actors, scope of the open version, requirement areas |
| `glossary.md` | terms used in requirements, backlog and code |
| `acceptance.md` | release acceptance of the open version |
| `REQ-<AREA>-NNN.md` | one requirement; copy `_TEMPLATE.md` |

## Goal

Trasformare la VM Debian dell'app Terminal di Android sul Pixel 11 Pro in un desktop Linux completo basato su Hyprland, riproducibile da zero con questo repository (script di installazione e dotfile). La v0.2.0 è riuscita quando il testo copiato in un'app Android si incolla nella sessione Hyprland e viceversa, attraverso il canale della clipboard dell'app Terminal, senza perdere nulla del desktop esistente.

## Actors

- **Utente:** il proprietario del telefono. Usa la VM come utente `droid` con `sudo`, apre il display grafico dall'app Terminal, esegue `install.sh` e usa il desktop.

## Scope

### In scope for v0.2.0

- Clipboard di testo condivisa nei due versi tra la sessione Hyprland e le app Android (REQ-DSK-005), anche dopo un riavvio della VM, senza perdere il ritorno a Weston.

### Out of scope for v0.2.0

Do not introduce these without first updating the requirements and the backlog:

- Condivisione di immagini o altri contenuti non testuali nella clipboard.
- Controllo del volume (REQ-DSK-004).
- Tema grafico coordinato tra le applicazioni.
- Applicazioni desktop aggiuntive (browser, file manager, editor) e ambienti di sviluppo.
- Profili di schermo diversi per telefono e monitor esterno.
- Modifiche ai file di sistema gestiti dall'app Terminal.

## Areas

Functional requirement IDs: `REQ-<AREA>-NNN`; non-functional: `REQ-NFR-NNN`. Areas used in this project:

| Area | Meaning |
| ---- | ------- |
| `SES` | sessione grafica: compositor sul display del Terminal e ritorno a Weston |
| `DSK` | desktop: applicazioni e configurazione della sessione Hyprland |
| `INS` | installazione: script, pacchetti, dotfile e backup |
| `NFR` | non-functional requirements |
