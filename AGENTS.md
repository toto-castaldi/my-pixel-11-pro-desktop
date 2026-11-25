# AGENTS.md

## 0. Process

This project follows the shared process in [`docs/PROCESS.md`](docs/PROCESS.md); it says which files of `docs/process/` to read for each topic. Claude Code already has it in context through `CLAUDE.md` and does not read it again; other agents read it before doing any work.

This file contains only project-specific rules. Where it conflicts with `docs/PROCESS.md`, the process wins unless the deviation is listed in [Process overrides](#8-process-overrides).

At the start of every session run `python3 .agents/tools/backlog.py status`, then `show` for the relevant items. Read and change the backlog only through that CLI (`docs/PROCESS.md` §3).

## 1. Project

- **Name:** `my-pixel-11-pro-desktop`
- **Summary:** trasforma la VM Debian dell'app Terminal di Android sul Pixel 11 Pro in un desktop Linux completo basato su Hyprland, riproducibile da zero con questo repository (script di installazione e dotfile).
- **Current version:** see `python3 .agents/tools/backlog.py status`.
- **Requirements:** `docs/requirements/` · **Design:** `docs/design/` (one file each, list them with `python3 .agents/tools/backlog.py docs`; read only those you need)

## 2. Language

- **Project language:** Italian
- Project content (`docs/PROCESS.md` §2) and user-facing messages, including the output of `install.sh`, are written in the project language.
- Code identifiers and code comments: English.

## 3. Scope

The scope of the current version is defined in `docs/requirements/README.md`. Do not implement anything listed there as out of scope without first updating requirements and backlog and agreeing the scope change with the user.

- The target is only the VM of the Android Terminal app (Debian 13 trixie, aarch64, user `droid`); no other distributions or machines.
- Never modify the files managed by the Terminal app (`docs/requirements/REQ-NFR-002.md`): everything lives under `$HOME` or comes from Debian packages.

## 4. Stack and architecture

Unless a different decision is recorded in the backlog and in the technical design:

- Bash for `install.sh` and `lib/*.sh`; Lua for the Hyprland configuration (API `hl.*` of Hyprland 0.55)
- apt (Debian trixie and `trixie-backports`)
- Hyprland 0.55, waybar, fuzzel, foot, swaybg, hyprlock, mako, grim, slurp, cliphist
- no database; state is the files under `$HOME`
- shellcheck, bats
- the Terminal app VM itself, user-level systemd units

Architecture and module boundaries: three modules (`docs/design/modules.md`): INSTALL (`install.sh`, `lib/`, `packages/`), SESSION (`systemd/`), DESKTOP (`config/`). `install.sh` keeps pure functions (paths, lists, decisions) separate from side effects (apt, filesystem, systemd) so that the pure ones are unit-testable.

## 5. Domain rules

- `install.sh` is idempotent: a second run changes nothing and creates no backups.
- A user file is never replaced without a backup.
- Returning to Weston must always remain possible by removing the override; Weston is never uninstalled.
- Dotfiles are applied as symbolic links into the repository, never as copies.
- `sudo` is used only for apt.

## 6. Quality gate

Closing gate (`docs/PROCESS.md` §6), all run by `./scripts/gate.sh`:

```bash
shellcheck install.sh lib/*.sh scripts/*.sh systemd/*.sh
Hyprland --verify-config -c config/hypr/hyprland.lua
bats tests/
# no build step
```

Preparation: `sudo apt-get install -y shellcheck bats` and Hyprland from `trixie-backports` (`sudo apt-get install -y -t trixie-backports hyprland`).

Integration and end-to-end suites: there is no automated suite. Integration is running `./install.sh` on the VM and checking the item's criteria; end-to-end is the procedure of `docs/requirements/acceptance.md` on a freshly reset VM with the display open. Both need the Terminal app VM; report their results in the item's `outcome`. Do not claim a criterion about the display, input or reboot as verified without having observed it on the VM.

## 7. Definition of Done additions

In addition to `docs/PROCESS.md` §6:

- `./install.sh` run twice on the VM: the second run reports no changes.
- The files listed in REQ-NFR-002 are unchanged after the item's work.
- The README documents every new command, shortcut and folder the item introduces.

## 8. Process overrides

None.

## 9. Security and configuration

- Never commit secrets: SSH keys, tokens, passwords. The GitHub SSH key lives only in `~/.ssh/` of the VM.
- Local configuration is the environment written by the Terminal app (`~/weston.env`), never versioned; the project reads it and does not change it.
- Do not log tokens, credentials or sensitive personal data.

## 10. Parallel work

Settings of `docs/PROCESS-PARALLEL.md`, which explains them; read it before working on an item if `Shared claims` or `Parallel work` is `on`.

- **Shared claims:** on
- **Parallel work:** on
- **Workspace root:** `../my-pixel-11-pro-desktop-work`
- **Worker agent command:** `pi --approve` (not used: the orchestrator runs in Claude Code)
