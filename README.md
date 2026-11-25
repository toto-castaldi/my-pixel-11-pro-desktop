# my-pixel-11-pro-desktop

Un desktop Linux completo basato su [Hyprland](https://hyprland.org) per la VM Debian dell'app **Terminal** di Android sul Pixel 11 Pro, riproducibile da zero con questo repository.

L'app Terminal esegue una VM Debian 13 (trixie, aarch64) e ne mostra il display grafico, gestito di serie da Weston. Questo progetto avvia Hyprland al suo posto, con accelerazione dalla GPU del telefono (Vulkan gfxstream e zink), e configura il desktop con dotfile versionati e collegati con link simbolici.

## Stato

In sviluppo: versione **v0.1.0** in preparazione. Lo script di installazione avvia Hyprland al posto di Weston sul display, con barra, launcher, terminale, tastiera italiana, scorciatoie, sfondo, blocco schermo, notifiche, screenshot e cronologia della clipboard. Il piano di lavoro è in `backlog/` e si legge con `python3 .agents/tools/backlog.py status`.

## Prerequisiti

- Un Pixel con l'app Terminal di Android e il display grafico attivo.
- Nella VM: utente `droid` con `sudo` e accesso a internet.

## Installazione

Su una VM appena creata o reimpostata, i comandi si danno nella vista testuale (Terminal) dell'app.

1. Aggiornare l'elenco dei pacchetti e installare `git`, che l'immagine della VM non contiene:

   ```bash
   sudo apt-get update
   sudo apt-get install -y git
   ```

2. Dare una password all'utente `droid`, che serve per sbloccare lo schermo:

   ```bash
   sudo passwd droid
   ```

3. Clonare il repository nella home ed eseguire lo script (il repository è pubblico: il clone via HTTPS non richiede chiavi né un account GitHub):

   ```bash
   cd ~
   git clone https://github.com/toto-castaldi/my-pixel-11-pro-desktop.git
   cd my-pixel-11-pro-desktop
   ./install.sh
   ```

Lo script installa Hyprland da `trixie-backports`, collega l'unità `~/.config/systemd/user/weston.service` del progetto e maschera `weston.socket`: quando l'app Terminal apre il display parte Hyprland al posto di Weston. Per passare subito alla nuova sessione:

```bash
systemctl --user restart weston
```

oppure riavviare la VM. Se Hyprland non è installato, la stessa unità avvia Weston, così il display non resta vuoto. Il log della sessione si legge con `journalctl --user -u weston`.

`./install.sh --help` mostra l'uso senza modificare il sistema. Lo script è rieseguibile: una seconda esecuzione stampa `Nessuna modifica` e non crea backup.

## Uso del desktop

All'avvio della sessione compare in alto la barra (waybar) con i workspace, il titolo della finestra attiva, il layout di tastiera e l'ora; un clic sull'ora mostra anche la data. Il layout di tastiera è italiano (`it`); AltGr resta disponibile per `@`, `#`, `[` e `]`.

Lo sfondo è `config/hypr/wallpaper.png`, mostrato da swaybg: è un gradiente generato per questo progetto e rilasciato in pubblico dominio ([CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)). Per cambiarlo basta sostituire il file nel clone e riavviare la sessione. Le notifiche delle applicazioni compaiono in alto a destra (mako) e si chiudono da sole dopo 5 secondi o con un clic; per provarle:

```bash
notify-send "prova"
```

Tastiera e mouse arrivano a Hyprland solo dalla vista grafica (Display) dell'app Terminal, e solo dopo aver cliccato dentro la sua finestra. Il tasto SUPER (Meta) e il tasto Tab li prende Android: per questo le scorciatoie usano `Alt`.

| Scorciatoia | Azione |
| --- | --- |
| `Alt + Invio` | apre il terminale (foot) |
| `Alt + Spazio` | apre il launcher delle applicazioni (fuzzel) |
| `Alt + Q` oppure `Alt + F4` | chiude la finestra attiva |
| `Alt + F` | schermo intero sì/no |
| `Alt + V` | finestra flottante sì/no |
| `Alt + frecce` | sposta il focus tra le finestre |
| `Alt + 1` … `Alt + 0` | va al workspace da 1 a 10 |
| `Alt + Maiusc + 1` … `Alt + Maiusc + 0` | sposta la finestra attiva nel workspace da 1 a 10 |
| `Alt + rotella del mouse` | passa al workspace successivo o precedente |
| `Alt + tasto sinistro` / `Alt + tasto destro`, trascinando | sposta / ridimensiona la finestra |
| `Alt + P` | screenshot dello schermo intero |
| `Alt + Maiusc + P` | screenshot di un'area: si seleziona trascinando il mouse, `Esc` annulla |
| `Ctrl + Alt + V` | cronologia della clipboard: la voce scelta torna nella clipboard e si incolla come al solito (`Ctrl + V`, nel terminale `Ctrl + Maiusc + V`) |
| `Ctrl + Alt + L` | blocca lo schermo (hyprlock); si sblocca digitando la password dell'utente e Invio |
| `Ctrl + Alt + Q` | esce dalla sessione Hyprland |

Gli screenshot sono salvati in PNG nella cartella `~/Pictures/Screenshots/`, con il nome `AAAAMMGG-HHMMSS.png`; una notifica indica il file. La cronologia della clipboard (cliphist) conserva i testi copiati durante la sessione Hyprland, anche tra un riavvio e l'altro; si svuota con `cliphist wipe`.

Dopo l'uscita il display resta vuoto finché la sessione non riparte: si riapre il display dall'app Terminal, oppure da una shell della VM:

```bash
systemctl --user start weston
```

I dotfile del desktop stanno in `config/` e sono collegati in `~/.config/` con link simbolici: una modifica nel clone vale per Hyprland dopo `hyprctl reload` e per waybar, foot, fuzzel, hyprlock e mako alla loro riapertura (`makoctl reload` per mako).

## Dopo un aggiornamento dell'app Terminal

Un aggiornamento dell'immagine della VM, con il ripristino del backup, riporta la home ma non i pacchetti da `trixie-backports`: il display mostra Weston invece di Hyprland. Basta rieseguire lo script dal clone del repository, che reinstalla Hyprland da `trixie-backports`:

```bash
cd ~/my-pixel-11-pro-desktop
./install.sh
systemctl --user restart weston
```

## Tornare a Weston

Per tornare alla sessione Weston dell'app Terminal, ad esempio se Hyprland non parte bene:

```bash
cd ~/my-pixel-11-pro-desktop
./install.sh --session weston
```

Il comando toglie l'unità `~/.config/systemd/user/weston.service` del progetto e la maschera di `weston.socket`, così torna in uso l'unità di sistema dell'app Terminal. Non installa né rimuove pacchetti e lascia al loro posto gli altri dotfile; Weston non viene mai disinstallato. Un file in quei percorsi che non è stato creato dal progetto resta dov'è, con un avviso. Il cambio ha effetto alla successiva apertura del display; per passare subito:

```bash
systemctl --user restart weston
```

Il comando toglie anche `WAYLAND_DISPLAY` e `DISPLAY` di Hyprland dall'ambiente dei servizi utente, che altrimenti farebbero partire Weston dentro un compositor che non c'è più. La sessione Hyprland li toglie da sola quando si ferma, anche per un riavvio o per l'uscita con Ctrl+Alt+Q.

Per tornare a Hyprland:

```bash
./install.sh --session hyprland
```

che equivale a `./install.sh`: anche lo script senza opzioni, ad esempio dopo un aggiornamento dell'app, riporta la sessione Hyprland. Entrambi i comandi sono rieseguibili: la seconda volta stampano `Nessuna modifica`.

## Struttura del repository

| Cartella | Contenuto |
| --- | --- |
| `install.sh` | script di installazione |
| `lib/` | funzioni dello script: `core.sh` (pure, testabili) e `effects.sh` (apt e filesystem) |
| `packages/` | elenchi dei pacchetti Debian, un pacchetto per riga; quelli da `trixie-backports` in file `*.backports.list` |
| `config/` | dotfile del desktop, uno per applicazione: `hypr/` (Hyprland, `hyprland.lua`), `waybar/` (barra), `foot/` (terminale), `fuzzel/` (launcher), `mako/` (notifiche); `config/links.list` elenca i link da creare sotto `$HOME` (`<file nel repo> <destinazione relativa a $HOME>`) |
| `systemd/` | unità systemd utente della sessione grafica (`weston.service`) e il suo comando di avvio (`start-session.sh`, collegato in `~/.local/libexec/my-pixel-11-pro-desktop/`) |
| `tests/` | test unitari bats |
| `scripts/` | strumenti di sviluppo (`gate.sh`) |

I file sostituiti da un link vengono salvati accanto all'originale come `<file>.bak-<data>`.

## Sviluppo

Requisiti in `docs/requirements/`, design in `docs/design/`. Il setup per lavorare sulla VM con il telefono collegato a monitor, tastiera e mouse (adb via Wi-Fi e `ssh pixel`) è descritto in `docs/design/dev-environment.md`.

Preparazione, sulla VM:

```bash
sudo apt-get install -y shellcheck bats
sudo apt-get install -y -t trixie-backports hyprland
```

Quality gate (shellcheck, `Hyprland --verify-config`, bats), con un solo comando:

```bash
./scripts/gate.sh
```
