# Requirements — my-pixel-11-pro-desktop

**Target version:** v0.1.0

**State:** baseline

The *what* of the project, one file per requirement (`docs/process/docs.md` §1). The *how* is in `docs/design/`. Every change of scope or behavior is recorded here before updating backlog and implementation (`docs/PROCESS.md` §3, `docs/process/docs.md`). List the requirements with `python3 .agents/tools/backlog.py docs`; read only the files you need.

| File | Content |
| --- | --- |
| `README.md` | goal, actors, scope of the open version, requirement areas |
| `glossary.md` | terms used in requirements, backlog and code |
| `acceptance.md` | release acceptance of the open version |
| `REQ-<AREA>-NNN.md` | one requirement; copy `_TEMPLATE.md` |

## Goal

Trasformare la VM Debian dell'app Terminal di Android sul Pixel 11 Pro in un desktop Linux completo basato su Hyprland, riproducibile da zero con questo repository (script di installazione e dotfile). La v0.1.0 è riuscita quando, su una VM appena reimpostata, un clone del repository e `install.sh` bastano per avere sul display del Terminal un desktop Hyprland accelerato dalla GPU, con barra, launcher, terminale, sfondo, blocco schermo, notifiche, screenshot, e cronologia della clipboard.

## Actors

- **Utente:** il proprietario del telefono. Usa la VM come utente `droid` con `sudo`, apre il display grafico dall'app Terminal, esegue `install.sh` e usa il desktop.

## Scope

### In scope for v0.1.0

- Hyprland come compositor del display del Terminal al posto di Weston, con accelerazione GPU, e ritorno a Weston con un comando.
- Desktop base: waybar, fuzzel, foot, tastiera italiana, scorciatoie compatibili con l'input di Android.
- Sfondo (hyprpaper), blocco schermo (hyprlock), notifiche (mako).
- Screenshot (grim, slurp), cronologia della clipboard.
- `install.sh` rieseguibile che installa i pacchetti, collega i dotfile con link simbolici e fa backup di ciò che sostituisce.

### Out of scope for v0.1.0

Do not introduce these without first updating the requirements and the backlog:

- Condivisione della clipboard tra la VM e Android (solo indagata da una spike).
- Controllo del volume (REQ-DSK-004): rinviato perché Android blocca l'audio della VM (SPIKE-003).
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
