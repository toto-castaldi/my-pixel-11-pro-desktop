# SPIKE-004 — Clipboard condivisa tra Hyprland e Android

- **Date:** 2026-11-25
- **Outcome:** Positive — l'app Terminal ha già un canale per la clipboard: l'agente della VM `linux_vm_manager` usa `wl-copy` e `wl-paste` sul socket `wayland-0`, mentre Hyprland è su `wayland-1`; con un link `wayland-0 → wayland-1` il copia e incolla funziona nei due versi, verificato dall'utente sul telefono.
- **Requirements:** nessuno: la condivisione è fuori dallo scope della v0.1.0 (`docs/requirements/README.md`).

## Questions

1. L'app Terminal offre un canale per la clipboard (ttyd, vsock, agente della VM)? Con quali prove?
2. Quali alternative sono praticabili (per esempio cartella condivisa, OSC 52), con quali pro e contro?
3. Se esiste una soluzione praticabile, quale idea va registrata nel backlog per una versione futura?

## Setup della prova

- Pixel 11 Pro, Android 17 (`CD1A.261005.003`), app Terminal `com.android.virtualization.terminal` versionCode 37 (APK `VmTerminalAppGoogle`), VM Debian 13 aarch64 con Hyprland 0.55.2 in esecuzione sul display del dock e `wl-clipboard` 2.2.1 (preinstallato nell'immagine).
- Accesso alla VM con `ssh pixel` e al telefono con adb via Wi-Fi dall'host adb (`docs/design/dev-environment.md`).
- Nessun file di configurazione è stato modificato. Stato temporaneo, annullato alla fine: un link `/run/user/1000/wayland-0 → wayland-1` (al suo posto c'era un socket `wayland-0` orfano, senza alcun processo in ascolto, creato durante la sessione e poi tolto insieme al link), un file di prova in `/mnt/shared/Download/`, poi cancellato, e una voce di prova copiata nella clipboard di Hyprland.
- L'APK è stato copiato sull'host di sviluppo, solo per leggerne le stringhe; non è stato installato nulla sul telefono.

## Findings

### 1. Il canale esiste: l'agente `linux_vm_manager`

**Sì.** L'immagine dell'app avvia l'unità di sistema `linux_vm_manager.service` ("Debian guest agent", `/usr/bin/linux_vm_manager`, non viene da un pacchetto Debian), che si registra su vsock presso il servizio di virtualizzazione di Android. La stessa unità gestisce anche l'inoltro delle porte, il balloon dello storage e lo spegnimento. La sua interfaccia AIDL `IDebianService` ha due metodi per la clipboard, `readClipboard` e `updateClipboard`, che usano `wl-clipboard`. Il journal li mostra così:

```
sudo: root : USER=droid ; ENV=XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 ; COMMAND=/usr/bin/wl-paste --no-newline
sudo: root : USER=droid ; ENV=XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 ; COMMAND=/usr/bin/wl-copy
```

Lato Android, nell'APK c'è la classe `com.android.virtualization.terminal.ClipboardController`, con i metodi `pushClipboardToGuest` e `pullClipboardFromGuest` e un flag `isSharedClipboardManagerEnabled`. Questo codice non è nel ramo `main` pubblico di AOSP (`packages/modules/Virtualization`, dove mancano sia `ClipboardController` sia `guest/linux_vm_manager`): le prove sono il binario, l'APK e il comportamento osservato.

**Quando si sincronizza.** Il journal registra un `wl-copy` (Android → VM) quando la finestra del Terminal riceve il focus, e un `wl-paste` (VM → Android) quando lo perde. Durante la prova le righe si alternano allo stesso modo: `wl-copy` alle 21:10:16, `wl-paste` alle 21:10:35, `wl-copy` alle 21:11:48, `wl-paste` alle 21:12:37. Non c'è un ascolto continuo: la clipboard passa solo ai cambi di focus.

**Perché oggi non funziona.** `WAYLAND_DISPLAY=wayland-0` è fisso nell'agente, ma Hyprland apre il socket `wayland-1` (`design/session`). Prima della prova ogni chiamata falliva: `Failed to connect to a Wayland server: No such file or directory` oppure, con il socket orfano, `Connection refused`, e nel journal compariva `wl-copy failed with status` o `wl-paste returned non-success status`.

**Prova.**

1. Comandi dell'agente lanciati a mano su `wayland-1`: con `wl-copy` la voce entra nella clipboard di Hyprland e `wl-paste --no-newline` la restituisce identica. Hyprland offre il protocollo data-control, quindi `wl-clipboard` funziona senza una finestra con il focus.
2. Con il link temporaneo `/run/user/1000/wayland-0 → wayland-1`, l'utente ha provato i due versi sul telefono:
   - **Android → VM:** testo copiato in un'app Android, poi incollato in foot con `CTRL + SHIFT + V` nella vista grafica del Terminal. Funziona, senza dover cambiare il focus più volte.
   - **VM → Android:** testo copiato in foot con `CTRL + SHIFT + C`, poi incollato in un'app Android. Funziona, ma serve un cambio di focus. Testuale: "per copiare da hyprland devo cambiare focus, al contrario no". È coerente con i log: la VM viene letta quando la finestra del Terminal perde il focus.
3. Con il link attivo, nel journal dell'agente non ci sono più errori.

### 2. Alternative

| Alternativa | Come funziona | Pro | Contro |
| --- | --- | --- | --- |
| Agente `linux_vm_manager` con `wayland-0` che punta a Hyprland (raccomandata) | Il canale dell'app, reso raggiungibile con un link o facendo aprire a Hyprland il socket `wayland-0` | Nativa, nei due versi, senza installare nulla su Android né nella VM (`wl-clipboard` c'è già), trasparente per tutte le app Wayland e Xwayland | Solo testo (`wl-paste --no-newline` senza `--type`); sincronizza solo ai cambi di focus; dipende da un nome di socket fisso in un componente dell'app, non documentato, che un aggiornamento può cambiare |
| Cartella condivisa `/mnt/shared` | Mount virtiofs `android` verso la memoria condivisa del telefono (`/sdcard`): un file scritto in `/mnt/shared/Download/` dalla VM si legge da Android (verificato con adb) | Funziona già, passa anche file e immagini | Non è una clipboard: servono script per scrivere e leggere un file e un'app Android che lo apra; è manuale |
| OSC 52 | Sequenza del terminale che scrive la clipboard | foot lo supporta e scrive la clipboard di Wayland, che poi l'agente passa ad Android: utile da ssh o tmux dentro foot | Il terminale web della vista testuale (ttyd 1.7.7 con xterm.js, nel binario `/usr/local/bin/ttyd`) non registra un handler per OSC 52 (ha 0, 1, 2, 4, 8, 10–12, 104, 110–112, 1337), quindi lì la sequenza viene ignorata. Nella vista testuale copia e incolla passano dagli eventi del WebView |
| Sincronizzazione via rete (app Android dedicata, per esempio di tipo KDE Connect) | Un servizio nella VM e un'app sul telefono che si parlano in rete | Indipendente dall'app Terminal | Richiede di installare un'app sul telefono e di aprire porte; un servizio in più, superfluo dato il canale nativo. Non provata |

## Limits, costs and risks

- Osservato il 2026-11-25 su Android 17 `CD1A.261005.003` con l'app Terminal versionCode 37. L'agente e il `ClipboardController` non sono nel codice pubblico di AOSP: nome del socket, comandi e momenti della sincronizzazione possono cambiare con un aggiornamento dell'app senza preavviso.
- Solo testo. Immagini e altri tipi MIME non sono stati provati e, dato `wl-paste --no-newline` senza `--type`, probabilmente non passano.
- VM → Android avviene solo quando la finestra del Terminal perde il focus: ciò che si copia in Hyprland arriva ad Android all'uscita dalla finestra, non prima.
- Il link in `/run/user/1000` è stato di runtime: sparisce a ogni riavvio della VM e va ricreato all'avvio della sessione. Non tocca i file di REQ-NFR-002.
- Non è stato verificato se `Hyprland --socket wayland-0` (opzione documentata da `Hyprland --help`, "for Wayland socket handover") funziona attraverso `start-hyprland -- --socket wayland-0`, né cosa succede se Weston, il compositor di ripiego, apre già `wayland-0`.
- Interazione con la cronologia della clipboard (REQ-DSK-003, US-005): ogni passaggio Android → VM è un `wl-copy`, quindi `cliphist` lo registra come una voce nuova. Va tenuto presente in quell'item; nel caso peggiore ogni ritorno alla finestra aggiunge di nuovo la stessa voce, ma cliphist toglie i duplicati.
- Privacy: la clipboard di Android entra nella VM a ogni ritorno sulla finestra e, con cliphist, resta nella cronologia della VM.

## Recommendations

- `design/desktop`: la clipboard condivisa con Android passa dall'agente `linux_vm_manager` dell'app, che usa `wayland-0`; con Hyprland su `wayland-1` oggi non funziona e il progetto non la attiva nella v0.1.0.
- Idea da registrare nel backlog per una versione futura, con un nuovo requisito (per esempio `REQ-DSK-005 — Clipboard condivisa con Android`): una User Story "Clipboard condivisa tra Hyprland e Android" nel modulo SESSION, in cui all'avvio della sessione `start-session` rende `wayland-0` un alias del socket di Hyprland (un link `wayland-0 → wayland-1` creato dallo script, oppure Hyprland avviato con `--socket wayland-0`; scegliere dopo aver provato la seconda strada), senza mai toccare il ripiego su Weston. Criteri: copia e incolla Android → VM e VM → Android osservati sul telefono, nessun errore `wl-copy`/`wl-paste` nel journal di `linux_vm_manager`, comportamento dopo un riavvio della VM, README con il limite del cambio di focus. Non è stato aggiunto: la condivisione è fuori dallo scope della v0.1.0 e l'item va concordato con l'utente.
- Dopo ogni aggiornamento dell'app Terminal, ricontrollare con `sudo journalctl -u linux_vm_manager | grep -E 'wl-(copy|paste)'` il socket usato dall'agente.

## Sources

- `strings /usr/bin/linux_vm_manager` (metodi `IDebianService::readClipboard` e `updateClipboard`, `WAYLAND_DISPLAY=wayland-0`, `wl-copy`, `wl-paste --no-newline`) e `systemctl cat linux_vm_manager.service` nella VM.
- `sudo journalctl -u linux_vm_manager` nella VM, il 2026-11-25, prima e durante la prova.
- Stringhe di `classes*.dex` dell'APK `VmTerminalAppGoogle` (versionCode 37): `ClipboardController`, `pushClipboardToGuest`, `pullClipboardFromGuest`, `isSharedClipboardManagerEnabled`.
- Frontend di ttyd 1.7.7 incluso in `/usr/local/bin/ttyd` (xterm.js): handler OSC registrati.
- AOSP `platform/packages/modules/Virtualization`, ramo `main`, cartelle `android/TerminalApp/java/com/android/virtualization/terminal/` e `guest/` (consultate il 2026-11-25): l'agente e il controller della clipboard non ci sono.
- `Hyprland --help` (0.55.2): opzione `--socket NAME`.
