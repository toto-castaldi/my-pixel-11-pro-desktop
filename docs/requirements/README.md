# Requirements — my-pixel-11-pro-desktop

**Target version:** nessuna versione aperta

**State:** baseline

The *what* of the project, one file per requirement (`docs/process/docs.md` §1). The *how* is in `docs/design/`. Every change of scope or behavior is recorded here before updating backlog and implementation (`docs/PROCESS.md` §3, `docs/process/docs.md`). List the requirements with `python3 .agents/tools/backlog.py docs`; read only the files you need.

| File | Content |
| --- | --- |
| `README.md` | goal, actors, scope of the open version, requirement areas |
| `glossary.md` | terms used in requirements, backlog and code |
| `acceptance.md` | release acceptance of the open version |
| `REQ-<AREA>-NNN.md` | one requirement; copy `_TEMPLATE.md` |

## Goal

Trasformare la VM Debian dell'app Terminal di Android sul Pixel 11 Pro in un desktop Linux completo basato su Hyprland, riproducibile da zero con questo repository (script di installazione e dotfile).

## Actors

- **Utente:** il proprietario del telefono. Usa la VM come utente `droid` con `sudo`, apre il display grafico dall'app Terminal, esegue `install.sh` e usa il desktop.

## Scope

Nessuna versione è aperta: scope e accettazione si definiscono quando se ne apre una. Le capacità già rilasciate sono descritte dai requisiti.

## Areas

Functional requirement IDs: `REQ-<AREA>-NNN`; non-functional: `REQ-NFR-NNN`. Areas used in this project:

| Area | Meaning |
| ---- | ------- |
| `SES` | sessione grafica: compositor sul display del Terminal e ritorno a Weston |
| `DSK` | desktop: applicazioni e configurazione della sessione Hyprland |
| `INS` | installazione: script, pacchetti, dotfile e backup |
| `NFR` | non-functional requirements |
