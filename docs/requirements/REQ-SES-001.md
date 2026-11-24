# REQ-SES-001 — Hyprland come compositor del display

**State:** Active

Quando l'app Terminal Android attiva il display grafico, sulla finestra del display deve partire Hyprland al posto di Weston, con rendering accelerato dalla GPU del telefono (renderer OpenGL diverso da llvmpipe/softpipe). Le applicazioni Wayland e X11 (tramite Xwayland) devono potersi aprire nella sessione.
