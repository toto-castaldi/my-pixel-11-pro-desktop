# Context and main flows

```mermaid
flowchart LR
  A[App Terminal Android] -- avvia --> VM[VM Debian 13 aarch64]
  A -- mostra --> D[Display CrosvmDisplay]
  VM -- shell interattiva --> P[/etc/profile.d/activate_display.sh/]
  P --> E[enable_gfxstream: weston.env, sessione logind, systemctl --user start weston]
  E --> O[weston.service utente del progetto]
  O --> H[Hyprland sul DRM]
  H --> D
  H -- Vulkan gfxstream / zink --> G[GPU del telefono]
  R[(Repository)] -- install.sh --> O
  R -- symlink --> C[~/.config/...]
  C --> H
```

- **Installazione:** l'utente clona il repository nella VM ed esegue `install.sh`, che installa i pacchetti, collega i dotfile e l'override della sessione.
- **Avvio:** aprendo il display dall'app Terminal, lo script di sistema avvia "weston"; l'override fa partire Hyprland sul DRM, che legge la configurazione collegata e avvia le applicazioni della sessione.
- **Ritorno a Weston:** rimuovendo l'override torna attiva l'unità di sistema di Weston.
