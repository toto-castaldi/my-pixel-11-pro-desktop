# Ambiente di sviluppo e accesso alla VM

Setup di lavoro usato per sviluppare e provare il progetto sulla VM reale. Non fa parte di `install.sh`: è configurazione personale delle macchine di sviluppo, che resta fuori dal repository.

## Topologia

```
host di sviluppo ──ssh──▶ host adb ──adb (USB o Wi-Fi)──▶ Pixel 11 Pro ──nc──▶ VM Debian (droid, sshd :2222)
                                                               │
                                                USB-C: dock con monitor, tastiera, mouse
```

- **Host di sviluppo:** la macchina dove girano l'agente e il clone del repository.
- **Host adb:** una macchina con `adb` che raggiunge il telefono in uno dei due modi: collegata via USB, oppure sulla stessa rete Wi-Fi del telefono. Può coincidere con l'host di sviluppo; altrimenti l'host di sviluppo la raggiunge via ssh.
- **Pixel 11 Pro:** quando la porta USB-C è occupata dal dock con monitor esterno, tastiera e mouse, Android è in modalità desktop, la finestra del Terminal (vista grafica) sta sul monitor e adb passa via Wi-Fi.
- **VM:** sshd in ascolto sulla porta `2222` (`/etc/ssh/sshd_config.d/`), configurato a mano una volta sola. Dal telefono la VM si raggiunge al suo IP sull'interfaccia `avf_tap_fixed`; né il port forwarding dell'app Terminal né `adb forward` funzionano per questo.

## Passare adb a Wi-Fi

Si fa con il telefono ancora collegato all'host adb via USB, prima di spostarlo sul dock:

```bash
# sull'host adb
adb devices -l                                    # il telefono compare via usb
adb shell ip -br addr show wlan0                  # IP del telefono sulla rete locale
adb -s <SERIALE_USB> tcpip 5555                   # adbd ascolta in TCP sulla porta 5555
adb connect <IP_TELEFONO>:5555
adb devices -l                                    # compare anche <IP_TELEFONO>:5555
```

Poi si scollega il cavo e si collega il telefono al dock. La connessione TCP resta finché il telefono non si riavvia.

## Configurazione ssh dell'host di sviluppo

In `~/.ssh/config` dell'host di sviluppo (non versionato):

```
Host adb-host
    HostName <NOME_HOST_ADB>
    User <UTENTE_HOST_ADB>

Host pixel
    HostName <IP_VM>
    User droid
    HostKeyAlias pixel-vm
    ProxyCommand ssh adb-host 'adb connect <IP_TELEFONO>:5555 >/dev/null; adb -s <IP_TELEFONO>:5555 shell -T nc %h 2222'
```

- `adb connect` nel `ProxyCommand` ricollega adb da solo se la connessione TCP è caduta (per esempio dopo un riavvio del daemon adb sull'host adb), purché il telefono sia ancora in modalità TCP.
- `-s <IP_TELEFONO>:5555` sceglie il percorso Wi-Fi anche quando il telefono è collegato pure via USB, evitando l'errore `more than one device`. Con il telefono solo su USB si usa invece `ProxyCommand ssh adb-host 'adb shell -T nc %h 2222'`.
- Se l'host adb coincide con l'host di sviluppo, il `ProxyCommand` è lo stesso comando senza `ssh adb-host`.
- `HostKeyAlias` tiene stabile la chiave host anche se cambia `<IP_VM>`.
- Nomi, indirizzi e chiavi restano in `~/.ssh/` delle macchine; nel repository solo segnaposto.

Uso: `ssh pixel` per una shell nella VM, `ssh pixel '<comando>'` per un comando singolo.

## Recupero

| Sintomo | Causa probabile | Rimedio |
| --- | --- | --- |
| `failed to connect to <IP_TELEFONO>:5555` | Il telefono si è riavviato e adbd non è più in TCP | Ricollegare il telefono all'host adb via USB e ripetere `adb tcpip 5555` e `adb connect`; in alternativa attivare il Debug wireless nelle Opzioni sviluppatore e usare `adb pair` / `adb connect` con la porta mostrata dal telefono |
| `adb connect` va in timeout | L'IP del telefono è cambiato o telefono e host adb non sono sulla stessa rete | Leggere il nuovo IP in Impostazioni → Wi-Fi sul telefono e aggiornare `<IP_TELEFONO>` in `~/.ssh/config`; una prenotazione DHCP sul router lo rende stabile |
| adb è connesso ma `ssh pixel` non risponde | La VM è spenta o ha cambiato IP | Aprire l'app Terminal; leggere l'IP con `ssh adb-host 'adb -s <IP_TELEFONO>:5555 shell ip neigh show dev avf_tap_fixed'` e aggiornare `<IP_VM>` |
| `Connection refused` sulla porta 2222 | sshd nella VM non è attivo | Dalla vista testuale dell'app Terminal: `sudo systemctl start ssh` |

## Osservazioni

- L'input del dock arriva a Hyprland solo dalla vista grafica dell'app Terminal e solo quando la sua finestra ha il focus di Android.
- Le prove di integrazione e end-to-end (`docs/design/test-strategy.md`) si fanno su questo setup: comandi via `ssh pixel`, verifica visiva sul monitor del dock.
