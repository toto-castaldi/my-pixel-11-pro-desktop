# SPIKE-002 — Tenuta al riavvio e agli aggiornamenti dell'app Terminal

- **Date:** 2026-11-25
- **Outcome:** Partial — l'override ha retto a 8 riavvii completi registrati nel journal. I file dell'app Terminal sono scritti una volta per istanza da cloud-init e la home sopravvive a un aggiornamento dell'immagine. Il comportamento con un aggiornamento reale dell'app non è stato osservato: questa parte viene solo dall'analisi statica.
- **Requirements:** REQ-NFR-002

## Questions

1. L'override `~/.config/systemd/user/weston.service` regge a un riavvio completo della VM? Con quale esito e con quali tempi?
2. Quali file crea o riscrive l'app Terminal nella VM, e quando?
3. Quali rischi residui restano per l'override in `~/.config/systemd/user`, e cosa deve fare US-001?

## Setup della prova

- Pixel 11 Pro, app Terminal Android, VM Debian 13 aarch64, kernel `6.12.93-android16-6`. Hyprland 0.55.2 è avviato dall'override utente creato a mano sulla VM il 2026-11-24 alle 18:15:21 UTC: `~/.config/systemd/user/weston.service`, più `weston.socket` collegato a `/dev/null`.
- Accesso da `ssh pixel` (`docs/design/dev-environment.md`), solo in lettura. Il journal della VM è persistente e conserva 15 boot, dal primo avvio del 2026-11-24 alle 16:21:58 UTC.
- Su indicazione dell'utente non è stato fatto alcun riavvio controllato: la VM è condivisa con altri item. Come prova valgono i riavvii già registrati nel journal. Non c'era un aggiornamento dell'app Terminal da osservare, quindi la domanda 2 si basa sull'analisi statica dei file presenti nella VM.
- Comandi usati: `journalctl --list-boots`; `journalctl --user -b N -u weston.service`; `sudo journalctl -b N`; `stat`, `sha256sum` e `dpkg -S` sui file gestiti; lettura di `/var/lib/cloud/seed/nocloud/` e di `/var/log/cloud-init.log`; `cmp` tra `root_files/` e i file installati; lettura di `/usr/local/bin/restore-backup` e di `/etc/profile.d/restore-backup.sh`.

## Findings

### 1. Tenuta al riavvio

**L'override regge al riavvio.** In tutti gli 8 boot avvenuti dopo la creazione dell'override, `weston.service` è partito come «Hyprland (al posto di Weston)» circa 2–3 s dopo l'apertura della sessione logind su `tty1`, senza intervento manuale e senza riavvii dell'unità (`NRestarts=0` nel boot corrente). Il boot -8 (2026-11-24 18:01–18:39) non è contato, perché l'override è stato creato mentre era in corso.

| Boot | Kernel (UTC) | Sessione logind | Hyprland avviato | Fine del boot | Chiusura |
| --- | --- | --- | --- | --- | --- |
| -7 | 2026-11-24 18:48:15 | 18:48:17 | 18:48:20 | 19:01:11 | spegnimento regolare (`System is powering down`) |
| -6 | 2026-11-24 19:01:18 | 19:01:20 | 19:01:23 | 19:15:41 | spegnimento regolare |
| -5 | 2026-11-24 20:27:09 | 20:27:11 | 20:27:13 | 20:39:25 | spegnimento regolare (`systemd-shutdown`) |
| -4 | 2026-11-25 07:16:45 | 07:16:47 | 07:16:49 | 07:41:47 | interrotto: il journal si ferma senza spegnimento. È il blocco dell'app Terminal registrato da SPIKE-001 |
| -3 | 2026-11-25 07:42:04 | 07:42:06 | 07:42:09 | 07:46:11 | spegnimento regolare |
| -2 | 2026-11-25 07:46:38 | 07:46:41 | 07:46:43 | 08:00:49 | spegnimento regolare |
| -1 | 2026-11-25 12:37:13 | 12:37:15 | 12:37:18 | 12:51:18 | spegnimento regolare (`systemd-shutdown`) |
| 0 | 2026-11-25 12:51:41 | 12:51:43 | 12:51:45 | in corso | — |

- Anche dopo la chiusura brusca del boot -4 il boot successivo ha avviato Hyprland normalmente.
- Su questi boot, dal kernel all'avvio di Hyprland passano 4–5 s. L'attesa di 3 s è quella di `enable_gfxstream`: `(sleep 3s; systemctl --user start weston)`.
- Messaggi ricorrenti che non impediscono l'avvio: `Failed to initialize glamor, falling back to sw` (Xwayland, atteso con `XWAYLAND_NO_GLAMOR=1`) e, in alcuni boot, `MESA: error: on_vkGetMemoryFdKHR: Failed to export host resource to FD`.
- In nessun boot i file dell'override sono stati toccati: le date di modifica sono ancora quelle del 2026-11-24 18:15:21. `weston.socket` risulta `masked`.

### 2. File che l'app Terminal crea o riscrive, e quando

L'app Terminal prepara la VM con **cloud-init NoCloud**. A ogni boot collega come `/dev/vdb` un'immagine ISO `cidata` (file datati 2026-03-27, `instance-id: ferrochrome/788f37afbfe5c41c`), che `attach-cidata.service` monta in sola lettura su `/var/lib/cloud/seed/nocloud`. Il `user-data` crea l'utente `droid`, scrive `~/.bash_aliases` (`write_files`, `defer: true`) ed esegue `init.sh` (`runcmd`). `init.sh`:

1. installa con `dpkg -i` gli eventuali `.deb` presenti in `localdebs/` (in questa immagine non ce ne sono);
2. copia ricorsivamente `root_files/*` in `/` (`cp -vR`), sovrascrivendo;
3. esegue `chown -R droid:users /home/droid`;
4. abilita e avvia le unità `attach-cidata`, `backup_mount`, `mnt-shared.automount`, `ttyd_uds`, `ttyd_vsock_bridge.path` e `linux_vm_manager`.

Il modulo `runcmd` e `write_files` hanno frequenza `once-per-instance`. In `/var/log/cloud-init.log` `config-runcmd` risulta eseguito 1 volta, al primo boot del 2026-11-24 alle 16:21:57, e saltato negli altri 14 boot (`previously ran`). Lo stesso vale per `write-files-deferred`. Nessuno di quei file appartiene a un pacchetto Debian (`dpkg -S`: nessun risultato) e tutti coincidono byte per byte con le copie in `root_files/` (`cmp`).

| File | Scritto da | Quando | Data di modifica attuale |
| --- | --- | --- | --- |
| `/etc/profile.d/activate_display.sh` | `init.sh` (`root_files`) | primo boot di un'istanza cloud-init | 2026-11-24 16:21:57 |
| `/etc/profile.d/restore-backup.sh` | `init.sh` | idem | 2026-11-24 16:21:57 |
| `/usr/local/bin/enable_display`, `enable_gfxstream`, `restore-backup` | `init.sh` | idem | 2026-11-24 16:21:57 |
| `/etc/systemd/user/weston.service`, `weston.socket` | `init.sh` | idem | 2026-11-24 16:21:57 |
| `/etc/systemd/system/attach-cidata.service`, `backup_mount.service`, `linux_vm_manager.service`, `mnt-shared.mount`, `mnt-shared.automount`, `ttyd_uds.service`, `ttyd_vsock_bridge.path`, `ttyd_vsock_bridge.service` | `init.sh` | idem | 2026-11-24 16:21:57 |
| `/etc/systemd/zram-generator.conf`, `/etc/cloud/cloud.cfg.d/99-disable-features.cfg`, `/etc/default/grub.d/15_timeout.cfg` | `init.sh` | idem | 2026-11-24 16:21:57 |
| `/usr/bin/linux_vm_manager`, `/usr/lib64/lib{base,binder,binder_ndk,binder_rpc_unstable,cutils,c_musl,c++,log,utils}.so` | `init.sh` | idem | 2026-11-24 16:21:57 |
| `~/.config/weston.ini` | `init.sh` (`root_files/home/droid`) | idem | 2026-11-24 16:21:57 |
| `~/.bash_aliases` | cloud-init `write_files` | idem | 2026-11-24 16:21:57 |
| proprietario di tutta `/home/droid` | `init.sh` (`chown -R droid:users`) | idem | — |
| `~/weston.env` | `enable_gfxstream`, da `activate_display.sh` | a ogni shell interattiva dell'utente `droid`, comprese le login via `ssh` | 2026-11-25 12:51:42 (boot corrente) |
| `/mnt/backup` (creato o rimosso), `~/.restore_complete` | `backup_mount.service`, `restore-backup` | a ogni boot; il ripristino solo dopo un aggiornamento dell'immagine | assenti: nessun aggiornamento finora |

**A ogni boot e a ogni shell interattiva**, `activate_display.sh` esegue `enable_gfxstream`, oppure `enable_display` senza gfxstream. Lo script riscrive `~/weston.env`, apre con `sudo systemd-run` una sessione logind su `tty1` ed esegue `systemctl --user start weston`. Se Hyprland è già attivo il comando non ha effetto; se è caduto, la shell interattiva successiva lo riavvia.

**Quando l'app aggiorna l'immagine Debian**, il meccanismo previsto dai file della VM è questo (analisi statica, non osservata):

- la VM parte da un nuovo rootfs, con i file sopra riscritti dalla nuova `cidata`;
- il vecchio rootfs viene collegato come `/dev/vdc`. `backup_mount.service` lo monta su `/mnt/backup`; se il disco non c'è, rimuove la cartella;
- alla prima shell interattiva `/etc/profile.d/restore-backup.sh` lancia `sudo restore-backup`, un'interfaccia curses che:
  1. chiede conferma;
  2. copia tutta la vecchia `/home/droid` sulla nuova con `rsync -av` (o `cp -av`), senza `--delete`;
  3. propone i pacchetti presenti nel vecchio sistema e assenti nel nuovo e li installa con `apt-get install -y <pacchetto>` usando le sorgenti apt del nuovo sistema;
  4. scrive `~/.restore_complete`.
- `/etc` e le sorgenti apt del vecchio sistema non vengono ripristinate, e nemmeno i file fuori dalla home.

Se invece un aggiornamento cambiasse solo la `cidata` (nuovo `instance-id`) lasciando lo stesso rootfs, cloud-init rieseguirebbe `init.sh` e `write_files`. Sovrascriverebbe i file della tabella, compresi `~/.config/weston.ini` e `~/.bash_aliases`, e rifarebbe il `chown -R` della home. È una deduzione dal funzionamento di cloud-init (`once-per-instance`), non un comportamento osservato.

### 3. Rischi residui per l'override e raccomandazione per US-001

L'override in `~/.config/systemd/user/` è fuori da tutto ciò che l'app scrive. `init.sh` copia in home solo `.config/weston.ini`, e `restore-backup` ripristina la home intera, quindi l'override e i link simbolici dei dotfile sopravvivono anche a un aggiornamento dell'immagine. Rischi residui:

- **Override senza Hyprland dopo un aggiornamento dell'immagine (rischio principale).** La home torna con l'override, ma il nuovo rootfs non ha Hyprland. Il ripristino dei pacchetti è facoltativo e usa le sorgenti apt del nuovo sistema, che non hanno `trixie-backports`: Hyprland non viene installato, oppure arriva una versione diversa dalla 0.55. In entrambi i casi `ExecStart=/usr/bin/start-hyprland` fallisce o la configurazione Lua non è valida. Weston è mascherato e il display resta vuoto, contro lo spirito di REQ-SES-002.
- **Cambi di nome o di tipo dell'unità.** L'override funziona perché `enable_gfxstream` esegue `systemctl --user start weston`. Se un aggiornamento rinomina l'unità o la attiva diversamente (per esempio con `weston.socket` richiesto da un'altra unità), Hyprland non parte più e si torna a Weston o a nessun compositor. Va ricontrollato dopo ogni aggiornamento confrontando gli hash dei file di REQ-NFR-002.
- **Socket Wayland.** Hyprland crea `wayland-1`, mentre `linux_vm_manager` (l'agente guest dell'app) chiama `wl-copy` con `WAYLAND_DISPLAY=wayland-0`. Nel journal ci sono 17 chiamate `wl-copy` e 7 errori `Failed to connect to a Wayland server`. Non impedisce l'avvio, ma riguarda SPIKE-004 (clipboard).
- **`~/weston.env` riscritto a ogni shell interattiva.** Il contenuto viene dall'app: l'override deve continuare a leggerlo con `EnvironmentFile=-` e non deve mai scriverlo.
- **Nuova istanza cloud-init sullo stesso rootfs** (deduzione, vedi sopra): sovrascrive `~/.bash_aliases` e `~/.config/weston.ini`. Nessuno dei due è un file del progetto: `install.sh` non deve usarli né trasformarli in link.

Raccomandazione per US-001:

- Tenere il meccanismo attuale: `weston.service` in `~/.config/systemd/user/` e `weston.socket` mascherato. Regge al riavvio senza toccare i file di REQ-NFR-002.
- Aggiungere a `systemd/weston.service` un ripiego: se `/usr/bin/start-hyprland` non esiste, avviare Weston con lo stesso comando dell'unità di sistema, `/usr/bin/weston --modules=systemd-notify.so --xwayland --continue-without-input`. Il desktop resta quindi utilizzabile anche dopo un aggiornamento dell'immagine. Lo si può fare con uno script di avvio nel repository richiamato da `ExecStart`.
- Documentare nel README che, dopo un aggiornamento dell'app Terminal con ripristino del backup, va rieseguito `./install.sh` (idempotente), che reinstalla Hyprland da `trixie-backports`.
- Per il criterio «regge a un riavvio» di US-001, verificare dal journal del boot successivo (`journalctl --user -b 0 -u weston.service`) che l'unità sia partita come Hyprland, con `NRestarts=0`.

## Limits, costs and risks

- Nessun riavvio controllato e nessun aggiornamento reale dell'app, per decisione dell'utente: il comportamento all'aggiornamento è dedotto dai file presenti nella VM al 2026-11-25 (`cidata` del 2026-03-27). Una versione futura dell'app potrebbe cambiarlo.
- I boot registrati comprendono spegnimenti regolari e una chiusura brusca, ma non distinguono un riavvio della sola VM da quello del telefono: il journal non registra cosa ha fatto il lato Android.
- Il ripiego su Weston e la ripresa dopo `restore-backup` non sono stati provati.

## Recommendations

- Registrare in `docs/design/session.md` il comportamento al riavvio e all'aggiornamento (fatto in questo item).
- US-001: ripiego su Weston nell'unità e nota nel README su `./install.sh` dopo un aggiornamento dell'app, come sopra.
- SPIKE-004: tenere conto che l'agente guest usa `wl-copy` su `wayland-0` mentre Hyprland espone `wayland-1`.
- Dopo il prossimo aggiornamento reale dell'app Terminal, confrontare gli hash dei file di REQ-NFR-002 con quelli registrati in questo report (vedi Sources) e verificare l'avvio di Hyprland.

## Sources

- Journal della VM: `journalctl --list-boots`, `journalctl --user -b -7…0 -u weston.service`, `sudo journalctl -b -7…-1`, letti il 2026-11-25.
- `/var/lib/cloud/seed/nocloud/{user-data,meta-data,init.sh,root_files/}` (immagine `cidata` su `/dev/vdb`) e `/var/log/cloud-init.log` (cloud-init 25.1.4).
- `/etc/systemd/system/*.service` dell'app; `ttyd_vsock_bridge.path` riporta l'intestazione «Copyright 2026 The Android Open Source Project».
- `/usr/local/bin/restore-backup` (funzioni `restore_user_home_files`, `restore_installed_packages`) e `/etc/profile.d/restore-backup.sh`.
- Hash (prefisso SHA-256) dei file di REQ-NFR-002 al 2026-11-25: `activate_display.sh` `dac83ecd1b35e552`, `enable_display` `7edd658badca44ee`, `enable_gfxstream` `0b1421e3418687af`, `weston.service` `c939f2113a14cc94`, `weston.socket` `7ae48eba9d719372`.
- Frequenza dei moduli: documentazione di cloud-init, «Module frequency» (`once-per-instance`), https://docs.cloud-init.io/en/latest/
