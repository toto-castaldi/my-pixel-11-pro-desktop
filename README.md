# my-pixel-11-pro-desktop

Un desktop Linux completo basato su [Hyprland](https://hyprland.org) per la VM Debian dell'app **Terminal** di Android sul Pixel 11 Pro, riproducibile da zero con questo repository.

L'app Terminal esegue una VM Debian 13 (trixie, aarch64) e ne mostra il display grafico, gestito di serie da Weston. Questo progetto avvia Hyprland al suo posto, con accelerazione dalla GPU del telefono (Vulkan gfxstream e zink), e configura il desktop con dotfile versionati e collegati con link simbolici.

## Stato

In sviluppo: versione **v0.1.0** in preparazione. Lo script di installazione esiste come struttura di base: gli elenchi di pacchetti e dotfile sono ancora vuoti e vengono riempiti dagli item successivi. Il piano di lavoro è in `backlog/` e si legge con `python3 .agents/tools/backlog.py status`.

## Prerequisiti

- Un Pixel con l'app Terminal di Android e il display grafico attivo.
- Nella VM: utente `droid` con `sudo`, accesso a internet, `git`.
- Una chiave SSH della VM registrata su GitHub, per clonare il repository.

## Installazione

Disponibile dalla v0.1.0:

```bash
git clone git@github.com:toto-castaldi/my-pixel-11-pro-desktop.git
cd my-pixel-11-pro-desktop
./install.sh
```

e poi riaprire il display dall'app Terminal.

`./install.sh --help` mostra l'uso senza modificare il sistema. Lo script è rieseguibile: una seconda esecuzione stampa `Nessuna modifica` e non crea backup.

## Struttura del repository

| Cartella | Contenuto |
| --- | --- |
| `install.sh` | script di installazione |
| `lib/` | funzioni dello script: `core.sh` (pure, testabili) e `effects.sh` (apt e filesystem) |
| `packages/` | elenchi dei pacchetti Debian, un pacchetto per riga; quelli da `trixie-backports` in file `*.backports.list` |
| `config/` | dotfile del desktop; `config/links.list` elenca i link da creare sotto `$HOME` (`<file nel repo> <destinazione relativa a $HOME>`) |
| `systemd/` | unità systemd utente della sessione grafica |
| `tests/` | test unitari bats |
| `scripts/` | strumenti di sviluppo (`gate.sh`) |

I file sostituiti da un link vengono salvati accanto all'originale come `<file>.bak-<data>`.

## Sviluppo

Requisiti in `docs/requirements/`, design in `docs/design/`.

Preparazione, sulla VM:

```bash
sudo apt-get install -y shellcheck bats
sudo apt-get install -y -t trixie-backports hyprland
```

Quality gate (shellcheck, `Hyprland --verify-config`, bats), con un solo comando:

```bash
./scripts/gate.sh
```
