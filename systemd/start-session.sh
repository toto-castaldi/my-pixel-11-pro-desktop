#!/usr/bin/env bash
# Start command of systemd/weston.service: Hyprland when start-hyprland is
# installed, otherwise Weston with the command of the system unit, so the
# display never stays empty (REQ-SES-001).
set -euo pipefail

# The unit runs this file through a symbolic link: find the repository.
REPO_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=lib/core.sh
. "$REPO_DIR/lib/core.sh"

# The path can be changed only to simulate a missing Hyprland.
start_hyprland="${MPD_START_HYPRLAND:-/usr/bin/start-hyprland}"
present="no"
[ -x "$start_hyprland" ] && present="yes"

read -r -a cmd <<<"$(core_session_command "$start_hyprland" "$present")"
if [ "$present" = "yes" ]; then
	echo "Avvio Hyprland: ${cmd[*]}"
else
	echo "$start_hyprland non trovato: avvio Weston: ${cmd[*]}"
fi
# The compositor always runs on DRM. A previous Hyprland session leaves
# WAYLAND_DISPLAY and DISPLAY in the user manager environment, and with
# them Weston would try to run nested and fail.
unset WAYLAND_DISPLAY DISPLAY
# Hyprland links wayland-0 to its own socket once started (hyprland.lua);
# a link left by a previous session would point to a closed socket and
# would keep Weston from opening wayland-0.
"$REPO_DIR/systemd/session-socket.sh" unlink
exec "${cmd[@]}"
