# Glossary

Terms used consistently in requirements, backlog and code.

- **App Terminal:** l'app "Terminal" di Android (Linux development environment), che esegue una VM Debian tramite Android Virtualization Framework e ne mostra la console e il display grafico.
- **VM:** la macchina virtuale Debian 13 (trixie, aarch64) gestita dall'app Terminal, con utente `droid`.
- **Display:** la finestra grafica dell'app Terminal, che mostra l'uscita DRM del display virtuale `CrosvmDisplay` della VM.
- **Compositor:** il server Wayland che gestisce il display: Weston in origine, Hyprland con questo progetto.
- **Override:** l'unità `~/.config/systemd/user/weston.service` del progetto, che ha la precedenza su quella di sistema e avvia Hyprland.
- **Dotfile:** un file di configurazione versionato in `config/` e collegato con un link simbolico sotto `$HOME`.
- **gfxstream:** il canale che porta i comandi Vulkan della VM alla GPU del telefono; OpenGL passa da zink su Vulkan.
