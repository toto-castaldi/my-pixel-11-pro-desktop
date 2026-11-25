# SPIKE-001 — Input su Android: tasto SUPER, touch e trackpad

- **Date:** 2026-11-25
- **Outcome:** Partial — SUPER/Meta non arriva a Hyprland e si raccomanda ALT come modificatore (verificato con un bind reale); gesti multi-dito e trackpad non sono stati osservabili.
- **Requirements:** REQ-DSK-001

## Questions

1. Il tasto SUPER/Meta arriva a Hyprland? Quali combinazioni intercetta Android?
2. Come arrivano touch, trackpad e gesti multi-dito (eventi libinput osservati)?
3. Quale modificatore principale usare, e quali alternative?

## Setup della prova

- Pixel 11 Pro, app Terminal Android, VM Debian 13 aarch64 (kernel `6.12.93-android16`), Hyprland 0.55.2 avviato al posto di Weston dall'override utente `~/.config/systemd/user/weston.service` già presente sulla VM.
- Tastiera e mouse fisici USB collegati al telefono attraverso un dock con monitor esterno. Android passa in modalità desktop e la finestra del Terminal sta sul monitor, dove Hyprland gira a 1920x1200 (`hyprctl monitors`: `Virtual-1`, `Google Inc. CrosvmDisplay`).
- Con la porta USB occupata, adb verso il telefono passava via Wi-Fi (`adb tcpip 5555` e `adb connect`), così da osservare la VM in diretta via `ssh`.
- Strumenti: `libinput-tools` ed `evtest` installati con apt sulla VM. Lettura dei dispositivi con `sudo libinput debug-events --show-keycodes` e `sudo evtest /dev/input/eventN` (output con `stdbuf -oL`), conteggio degli interrupt delle code `events` dei dispositivi virtio in `/proc/interrupts`, `hyprctl devices`, `hyprctl cursorpos`, `hyprctl binds`.
- Verifica dei modificatori con tre bind temporanei aggiunti a runtime (`hyprctl dispatch "hl.bind(...)"`) che scrivono l'ora in un file: `ALT + Return`, `CTRL + ALT + Return`, `SUPER + Return`. Sono stati rimossi con `hyprctl reload`. Nessun file di configurazione è stato modificato.

## Findings

### 0. Dispositivi esposti dall'app Terminal

La VM vede quattro dispositivi virtio di crosvm (`/proc/bus/input/devices`, `libinput list-devices`):

| Nodo | Dispositivo | Capacità libinput | Note |
| --- | --- | --- | --- |
| `event0` | Crosvm Virtio Multitouch Touchscreen 0 | `touch` | `INPUT_PROP_DIRECT`, 11 slot, assi 0–1280 × 0–720 |
| `event1` | Crosvm Virtio Keyboard 0 | `keyboard` | 106 tasti dichiarati, LED Num/Caps/Scroll |
| `event2` | Crosvm Virtio Mouse 0 | `pointer` | relativo: `REL_X`, `REL_Y`, `REL_WHEEL`, tasti sinistro, destro e centrale |
| `event3` | Crosvm Virtio Multi-touch Trackpad 0 | `pointer gesture` | `INPUT_PROP_BUTTONPAD`, 70×50 mm, `BTN_TOOL_DOUBLETAP/TRIPLETAP/QUADTAP` |

Hyprland li riconosce tutti (`hyprctl devices`): il trackpad compare tra i mouse, il touchscreen come `Touch Device`, la tastiera con layout `it`.

**L'input arriva solo dalla vista grafica (Display) dell'app Terminal.** Nella vista testuale l'app manda i tasti alla shell attraverso la sua connessione di terminale, non ai dispositivi virtio. In 25 minuti di prove nella vista testuale le code `events` di virtio7–10 hanno registrato 0 interrupt e il cursore di Hyprland è rimasto al centro. La finestra della vista grafica deve inoltre avere il focus di Android: finché non ci si clicca dentro, tastiera e mouse restano ad Android.

### 1. SUPER/Meta e combinazioni intercettate da Android

**SUPER/Meta non arriva a Hyprland.**

- La tastiera virtio non dichiara `KEY_LEFTMETA` (125) né `KEY_RIGHTMETA` (126): nell'elenco dei tasti di `evtest /dev/input/event1` non compaiono. Mancano anche `KEY_COMPOSE` e i tasti da F13 in su. Il dispositivo quindi non può emettere SUPER in nessun caso.
- Premendo Meta, Android prende il tasto e porta il focus fuori dalla finestra di Hyprland (osservato dall'utente). Con Meta+Invio non arriva alcun evento nella VM e il bind di prova `SUPER + Return` non è mai scattato: il file di prova non è stato creato.

Tasti e combinazioni provati, con la finestra a fuoco:

| Prova | Arriva alla VM (libinput) | Note |
| --- | --- | --- |
| Meta, da solo o con Invio | no | preso da Android, il focus esce da Hyprland |
| Alt+Tab | solo `KEY_LEFTALT` | Tab non arriva; Android cambia focus |
| Tab da solo | no | nessun `KEY_TAB` in tutta la sessione (vedi rischi) |
| Alt+F4 | sì (`KEY_LEFTALT` + `KEY_F4`) | |
| Ctrl+Alt+T | sì | |
| Ctrl+Esc | sì | |
| Alt+Spazio, Ctrl+Spazio | sì | |
| Alt+Invio | sì | il bind `ALT + Return` è scattato e ha aperto foot |
| Ctrl+Alt+Invio | sì | il bind `CTRL + ALT + Return` è scattato |
| Esc, F1, F2, F4 | sì | il tasto premuto come F12 è arrivato come `KEY_F2`, probabilmente per lo strato Fn della tastiera usata; F12 è comunque dichiarato dal dispositivo |
| Print | sì, come `KEY_SYSRQ` (99) | in xkb è il keysym `Print` |
| Caps Lock | sì (`KEY_CAPSLOCK`) | |
| AltGr | sì (`KEY_RIGHTALT`) | serve al layout `it` per `@`, `#`, `[`, `]` |
| Ctrl destro | sì (`KEY_RIGHTCTRL`) | |
| lettere (`abc`) | sì | |

### 2. Touch, mouse, trackpad e gesti

- **Touch dello schermo del telefono:** arriva da `event0` come eventi touch assoluti (`TOUCH_DOWN`, `TOUCH_MOTION`, `TOUCH_UP`, `TOUCH_FRAME`). In 29 tocchi è stato usato sempre e solo lo slot 0, cioè un dito alla volta. Le coordinate stanno nello spazio 1280×720 del dispositivo anche con Hyprland a 1920×1200: è libinput a normalizzarle sull'uscita. Il touch non muove il cursore, come è normale per un touchscreen Wayland.
- **Mouse fisico USB:** arriva da `event2` come puntatore relativo. Movimento (1714 `POINTER_MOTION`), clic sinistro e destro (`POINTER_BUTTON`), rotella (`POINTER_SCROLL_WHEEL`, 15° per scatto). Funziona in Hyprland.
- **Trackpad:** non è stato osservato alcun evento da `event3` (0 interrupt su virtio10), perché nella prova non c'era un trackpad fisico. Il dispositivo dichiara le capacità per i gesti (`cap: pointer gesture`, tap a 2–4 dita, scorrimento a due dita, clickfinger), ma non è stato verificato cosa l'app Terminal ci inoltri.
- **Gesti multi-dito:** non osservati. Con il monitor esterno lo schermo del telefono non è un touchpad e non c'è stato modo di fare gesti a più dita sulla finestra di Hyprland. Restano da verificare gli `ABS_MT_SLOT` > 0 sul touchscreen e i `GESTURE_SWIPE/PINCH` sul trackpad.

### 3. Modificatore raccomandato

- **Principale: `ALT` (Alt sinistro).** Arriva sempre a Hyprland insieme ai tasti provati (lettere, Invio, Spazio, F4) ed è stato verificato con un bind reale (`ALT + Return` ha aperto foot).
- **Alternativa: `CTRL + ALT`.** Arriva anche questa combinazione (verificata con `CTRL + ALT + Return`). È più scomoda, ma non si scontra con le scorciatoie Alt delle applicazioni (per esempio Alt+B e Alt+F di readline in foot).
- **Da evitare:**
  - `SUPER`: non arriva;
  - `ALT + Tab`, e Tab in generale: Android li prende;
  - `AltGr` come modificatore: serve al layout `it`.
- **Alternativa non verificata:** rimappare Caps Lock su Super nella VM con un'opzione xkb (`caps:super`). Caps Lock arriva, ma questa strada non è stata provata.

## Limits, costs and risks

- **Tab non arriva nemmeno da solo.** In tutta la sessione non è comparso alcun `KEY_TAB`, e l'utente ha perso il focus con sequenze come Alt+Tab. Probabilmente Android usa Tab per la navigazione del focus tra le viste. Va confermato perché tocca anche l'uso normale: completamento in shell in foot, navigazione nei campi di testo.
- Le prove sono state fatte con tastiera e mouse USB su un dock con monitor esterno (modalità desktop di Android). Una tastiera Bluetooth o lo schermo del telefono da solo potrebbero comportarsi diversamente, soprattutto per le combinazioni che Android intercetta.
- Il comportamento dipende dalla versione dell'app Terminal e di Android sul telefono al 2026-11-25. Un aggiornamento può cambiare i tasti intercettati.
- Durante una prova l'app Terminal si è bloccata e la VM è ripartita (boot interrotto alle 07:41:47 UTC senza errori nel journal). La causa non è stata individuata.
- I log grezzi delle catture sono andati persi in fase di pulizia per un errore di chi ha condotto lo spike. I dati riportati qui sono gli estratti letti durante la sessione.
- Il `hyprland.lua` di esempio oggi presente sulla VM usa `SUPER` come `mainMod`, quindi le sue scorciatoie non funzionano dalla finestra del Terminal.

## Recommendations

- Registrare in `docs/design/desktop.md` `ALT` come modificatore principale delle scorciatoie (alternativa `CTRL + ALT`), senza scorciatoie basate su Tab o SUPER. US-003 lo applica in `config/hypr/hyprland.lua` e lo documenta nel README.
- Per US-005 la scorciatoia dello screenshot può usare il tasto Print (keysym `Print`, che arriva come `KEY_SYSRQ`).
- Aggiungere al backlog un item per verificare il tasto Tab nella vista grafica: se Android lo consuma, va cercata una soluzione o documentato il limite.
- Aggiungere al backlog un item, o estendere uno esistente, per i gesti multi-dito sul touchscreen e sul trackpad fisico, da fare quando un trackpad è disponibile.
- Documentare nel README che tastiera e mouse arrivano a Hyprland solo dalla vista grafica dell'app Terminal e dopo averci cliccato dentro.

## Sources

- Capacità dei dispositivi: `sudo evtest /dev/input/event{0..3}`, `sudo libinput list-devices`, `/proc/bus/input/devices` sulla VM.
- Eventi: `sudo libinput debug-events --show-keycodes` e `/proc/interrupts` (code `virtio7-events` … `virtio10-events`) durante le prove dell'utente, 2026-11-25 07:16–07:57 UTC.
- Bind di prova: `hyprctl dispatch "hl.bind(...)"`, `hyprctl binds` (modmask 8 = ALT, 12 = CTRL+ALT, 64 = SUPER).
- Codici dei tasti: `linux/input-event-codes.h` (`KEY_LEFTMETA` 125, `KEY_RIGHTMETA` 126, `KEY_SYSRQ` 99).
