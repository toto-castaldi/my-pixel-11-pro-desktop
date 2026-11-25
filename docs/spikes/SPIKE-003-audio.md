# SPIKE-003 — Audio nella VM: PulseAudio e tasti volume

- **Date:** 2026-11-25
- **Outcome:** Partial — l'audio della VM non arriva al telefono, perché Android rifiuta gli stream di crosvm; i comandi del volume (`pactl`) e il modulo waybar sono individuati e i comandi verificati su un sink nullo; si raccomanda di restare su PulseAudio.
- **Requirements:** REQ-DSK-003

## Questions

1. Un suono riprodotto nella VM si sente dal telefono? Con quale test?
2. Con quale comando si alza, abbassa e silenzia il volume, e quale modulo waybar usare?
3. Conviene restare su PulseAudio o passare a PipeWire?

## Setup della prova

- Pixel 11 Pro, Android 17 (`CD1A.261005.003`, patch di sicurezza 2026-10-05), app Terminal `com.android.virtualization.terminal` versionCode 37, VM Debian 13 aarch64, Hyprland in esecuzione sul display del dock.
- Accesso alla VM con `ssh pixel` e al telefono con adb via Wi-Fi dall'host adb (`docs/design/dev-environment.md`). Lato Android: `logcat`, `dumpsys media.audio_flinger`, `dumpsys package`.
- Sulla VM è stato installato `alsa-utils` con apt per provare ALSA senza PulseAudio (`aplay`, `amixer`); resta installato.
- Nessun file di configurazione è stato modificato. PulseAudio utente è stato fermato e riavviato una volta (`systemctl --user stop/start pulseaudio.socket pulseaudio.service`). Le prove di volume hanno usato un'istanza PulseAudio temporanea in `/tmp`, poi chiusa e rimossa.

## Findings

### 1. Il suono della VM non arriva al telefono

**No.** Lo stream si interrompe lato Android prima che venga riprodotto qualcosa. Lo confermano i log e una prova di ascolto: con `speaker-test -D hw:0,0 -c 2 -r 48000 -F S16_LE -t sine -f 440 -l 1` (tono a 440 Hz) il comando è fallito subito con `Setting of hwparams failed: Input/output error`, e l'utente, in ascolto, dal telefono non ha sentito niente.

Pacchetti e servizi nella VM: `pulseaudio` 17.0 e `pulseaudio-utils` sono installati e il servizio utente `pulseaudio` è attivo; PipeWire non è installato (ci sono solo le librerie `libpipewire-0.3-0t64` e `libwireplumber-0.5-0`, che servono a waybar).

L'app Terminal espone una scheda audio virtio:

- `/proc/asound/cards`: `0 [SoundCard]: virtio-snd - VirtIO SoundCard`; `aplay -l`: un dispositivo `hw:0,0` con un'uscita (stream 0) e un ingresso (stream 1). Non ci sono controlli di mixer.
- I parametri hardware (`aplay --dump-hw-params`) sono plausibili: U8/S16_LE/S24_LE/S32_LE, da 1 a 6 canali, da 8000 a 48000 Hz.

Test usato, con PulseAudio fermo:

```bash
aplay -D hw:0,0 -f S16_LE -c 2 -r 44100 -d 2 /dev/zero
# aplay: set_params:1456: Unable to install hw params
```

Lo stesso errore esce con 48000 e 44100 Hz, S16_LE e S32_LE, mono e stereo. Nel kernel della VM ogni tentativo produce `virtio_snd virtio15: control message (0x00000102) timeout` (`0x0102` è `VIRTIO_SND_R_PCM_PREPARE`). Sul telefono, nello stesso istante, `logcat` del processo `crosvm` dell'app Terminal mostra la causa:

```
crosvm  : [Card 0] VIRTIO_SND_R_PCM_PREPARE for stream id=0 failed. Error code: VIRTIO_SND_S_IO_ERR. Actual error: Failed to create stream: Failed to open stream
AudioStreamBuilder: rate = 44100, channels = 2, ... dir = OUTPUT
libbinder.IPCThreadState: Binder transaction failure ... BR_FAILED_REPLY (29201), error: -1 (Operation not permitted)
AudioTrack: createTrack_l(0): Could not get control block
AAudio  : AAudioStreamBuilder_openStream() returns -896 = AAUDIO_ERROR_INTERNAL
avc: denied { read write } ... scontext=u:r:crosvm_vu_snd:s0:... tcontext=u:object_r:audioserver:s0 tclass=memfd_file permissive=0
```

crosvm apre lo stream di uscita con AAudio, ma la policy SELinux di questa build impedisce al dominio `crosvm_vu_snd` di accedere alla memoria condivisa (`memfd`) che `audioserver` gli passa per l'AudioTrack. La traccia viene quindi scartata. Lo stream di ingresso fallisce allo stesso modo (`AudioRecord: createRecord_l ... could not create record track`), benché l'app abbia il permesso `RECORD_AUDIO` concesso. Ci sono anche negazioni di `find` sui servizi `audio` e `media.metrics`, per lo stesso dominio.

Si tratta di un limite della piattaforma Android, non della VM: né PulseAudio né PipeWire possono aggirarlo. Potrà cambiare con un aggiornamento di Android o dell'app Terminal.

**Effetto collaterale su PulseAudio.** `module-udev-detect` prova a caricare la scheda all'avvio e poi ogni 50 secondi circa (`Failed to find a working profile`, `Failed to load module "module-alsa-card"`). Ogni tentativo resta bloccato nei timeout di virtio-snd: l'avvio del servizio richiede circa 50 secondi e, mentre prova, PulseAudio non risponde ai client. In questa sessione `pactl info` è andato in timeout o ha avuto `Connection refused` in tutte le prove sul server dell'utente. Nel frattempo `logcat` sul telefono riceve centinaia di errori di crosvm e di negazioni SELinux. Senza una scheda funzionante, il server ha solo sink fittizi.

### 2. Comandi del volume e modulo waybar

Comandi, verificati con `pactl` 17.0 su un'istanza PulseAudio temporanea con un sink nullo (`module-null-sink`). È stata necessaria perché il server dell'utente non rispondeva:

| Azione | Comando | Esito osservato |
| --- | --- | --- |
| alza | `pactl set-sink-volume @DEFAULT_SINK@ +5%` | 50% → 55% |
| abbassa | `pactl set-sink-volume @DEFAULT_SINK@ -5%` | il volume scende (verificato con -10%: 55% → 45%) |
| muto (on/off) | `pactl set-sink-mute @DEFAULT_SINK@ toggle` | `Mute: yes`, poi `Mute: no` |
| lettura | `pactl get-sink-volume @DEFAULT_SINK@`, `pactl get-sink-mute @DEFAULT_SINK@` | |

`pactl` fa parte di `pulseaudio-utils`, già presente nella VM. `wpctl` richiede WirePlumber, che non è installato; funziona solo dopo il passaggio a PipeWire.

**Modulo waybar:** `pulseaudio`. Waybar 0.12.0 della VM è compilato sia con `libpulse` sia con `libwireplumber` (`ldd`), quindi ha entrambi i moduli. Il modulo `pulseaudio` parla il protocollo di PulseAudio e funzionerebbe anche con `pipewire-pulse`. Il modulo `wireplumber` funziona solo con PipeWire. Con il server attuale, che non risponde, il modulo `pulseaudio` non è stato provato sulla barra.

**Tasti volume.** La tastiera virtio dichiara `KEY_MUTE` (113), `KEY_VOLUMEDOWN` (114) e `KEY_VOLUMEUP` (115) (bitmap `KEY` in `/proc/bus/input/devices`), che in xkb sono `XF86AudioMute`, `XF86AudioLowerVolume` e `XF86AudioRaiseVolume`. Non è stato verificato se Android li inoltra alla VM o li tiene per il proprio volume. I tasti fisici del telefono regolano comunque il volume di Android. Come fallback servono scorciatoie con `ALT` (`design/desktop`).

### 3. PulseAudio o PipeWire

**Conviene restare su PulseAudio.** I motivi:

- Passare a PipeWire non risolve nulla: il blocco è in Android (SELinux tra crosvm e audioserver), a valle di qualunque server audio della VM.
- PulseAudio è già nell'immagine dell'app Terminal, con `pactl`. PipeWire richiederebbe di installare `pipewire-pulse` e `wireplumber` (in trixie 1.4.2 e 0.5.8, in backports `pipewire-pulse` 1.6.9) e di disattivare e mascherare le unità utente `pulseaudio.service` e `pulseaudio.socket`, perché i due server prendono lo stesso socket. Sarebbe uno stato in più da installare, mantenere e annullare, senza alcun beneficio.
- waybar e `pactl` funzionano con entrambi, quindi restare su PulseAudio non preclude un passaggio futuro.
- Non è stato verificato se WirePlumber riprova la scheda in un ciclo come `module-udev-detect`. È un motivo in più per non cambiare ora.

## Limits, costs and risks

- Osservato il 2026-11-25 su Android 17 `CD1A.261005.003` con l'app Terminal versionCode 37. La causa è nella policy SELinux della build e potrebbe sparire con un aggiornamento: va ricontrollata dopo ogni aggiornamento (la prova è il comando `aplay` di cui sopra).
- La prova di ascolto è stata fatta solo con l'audio del telefono, sul dock. Non sono state provate l'uscita sul dock (HDMI/USB) né le cuffie Bluetooth, ma l'errore avviene prima della scelta del dispositivo di uscita.
- Il ciclo di tentativi di PulseAudio occupa la VM e riempie il logcat del telefono. Un client PulseAudio che si collega al server dell'utente (per esempio waybar o `pactl` in una scorciatoia) può restare bloccato per decine di secondi.
- REQ-DSK-003 e `acceptance.md` chiedono di alzare, abbassare e silenziare il volume e di vederne il livello nella barra. Con un sink nullo è realizzabile, ma il volume non avrebbe effetto udibile. Va deciso con l'utente se il requisito resta così, viene rinviato o viene ridotto.

## Recommendations

- `design/desktop`: server audio PulseAudio, comandi `pactl set-sink-volume @DEFAULT_SINK@ ±5%` e `pactl set-sink-mute @DEFAULT_SINK@ toggle`, modulo waybar `pulseaudio`, scorciatoie `XF86Audio*` più un'alternativa con `ALT`.
- Proposta da concordare con l'utente: per la v0.1.0, rinviare a una versione successiva la parte di REQ-DSK-003 sul volume, oppure ridurla a «comandi e barra presenti, effetto udibile non garantito finché Android blocca l'audio della VM». Poi aggiornare requisito, `acceptance.md` e backlog.
- Possibile item tecnico (non aggiunto): evitare il ciclo di `module-udev-detect`, per esempio con un `~/.config/pulse/default.pa` che include quello di sistema e carica `module-null-sink` al posto del rilevamento ALSA, così il server risponde subito. Va valutato insieme alla decisione precedente.
- Dopo ogni aggiornamento di Android o dell'app Terminal, ripetere la prova `aplay -D hw:0,0 …` e controllare in `logcat` le negazioni `crosvm_vu_snd`.

## Sources

- Specifica virtio-snd, codici delle richieste di controllo (`VIRTIO_SND_R_PCM_PREPARE` = `0x0102`): OASIS Virtual I/O Device (VIRTIO) Version 1.3, §5.14 Sound Device.
- Log raccolti il 2026-11-25: `dmesg` della VM, `journalctl --user -u pulseaudio`, `logcat -b all` e `dumpsys media.audio_flinger` del telefono.
