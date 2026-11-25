#!/usr/bin/env bash
# Alias of the Wayland socket used by the guest agent linux_vm_manager of
# the Terminal app for the clipboard shared with Android (REQ-DSK-005).
# The agent runs wl-copy and wl-paste on the fixed socket wayland-0, while
# Hyprland opens wayland-1 (design/session).
#   link:   make wayland-0 a symbolic link to $WAYLAND_DISPLAY; run by
#           hyprland.lua when Hyprland starts
#   unlink: remove that link; run by start-session before the compositor
#           starts, by ExecStopPost of weston.service and by
#           ./install.sh --session weston
set -euo pipefail

# The script runs through a symbolic link: find the repository.
REPO_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=lib/core.sh
. "$REPO_DIR/lib/core.sh"

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
path="$runtime_dir/$(core_agent_socket)"

kind="missing"
current=""
alive="no"
if [ -L "$path" ]; then
	kind="link"
	current="$(readlink "$path")"
elif [ -S "$path" ]; then
	kind="socket"
	# libwayland compositors hold an exclusive flock on <socket>.lock.
	if [ -e "$path.lock" ] && ! flock -n "$path.lock" true; then
		alive="yes"
	fi
elif [ -e "$path" ]; then
	kind="file"
fi

case "${1:-}" in
	link)
		wanted="${WAYLAND_DISPLAY:-}"
		case "$(core_agent_socket_action "$kind" "$current" "$wanted" "$alive")" in
			skip)
				echo "$path lasciato com'è ($kind${current:+ -> $current}, compositor su ${wanted:-?})"
				;;
			link)
				ln -s "$wanted" "$path"
				echo "Collego $path -> $wanted"
				;;
			replace)
				rm -f "$path"
				ln -s "$wanted" "$path"
				echo "Sostituisco $path ($kind) con il link -> $wanted"
				;;
		esac
		;;
	unlink)
		if [ "$(core_agent_socket_unlink_action "$kind")" = "remove" ]; then
			rm -f "$path"
			echo "Rimuovo il link $path -> $current"
		fi
		;;
	*)
		echo "Uso: $(basename "$0") link|unlink" >&2
		exit 2
		;;
esac
