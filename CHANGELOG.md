# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows [Semantic Versioning](https://semver.org/). Entries are written in the project language and reference the backlog item ID.

## [Unreleased]

## [0.1.0] - 2026-11-25

### Added

- il display del Terminal avvia Hyprland al posto di Weston, con ripiego su Weston se Hyprland manca (US-001)
- ./install.sh --session weston e --session hyprland per tornare alla sessione Weston dell'app Terminal e poi a Hyprland (US-002)
- desktop base con barra waybar, launcher fuzzel, terminale foot, tastiera italiana e scorciatoie Alt (US-003)
- sfondo con swaybg, blocco schermo con hyprlock (Ctrl+Alt+L) e notifiche desktop con mako (US-004)
- screenshot dello schermo o di un'area (Alt+P, Alt+Maiusc+P) e cronologia della clipboard (Ctrl+Alt+V) (US-005)
- documentazione del setup di sviluppo con telefono su dock USB e adb via Wi-Fi (TEC-004)
- Documentazione di base del progetto: requisiti, design, backlog della v0.1.0 e regole per gli agenti (TEC-001).
- Struttura del repository, `install.sh` con `--help`, quality gate unico `scripts/gate.sh` e test unitari bats (TEC-002).

### Changed

- il README guida l'installazione completa su una VM reimpostata, con clone via HTTPS senza chiavi (US-006)

### Fixed

- il ritorno a Weston con ./install.sh --session weston funziona anche con la sessione Hyprland attiva (BUG-001)
