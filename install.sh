#!/usr/bin/env bash
# Install the Hyprland desktop on the Android Terminal app VM.
# Idempotent: a second run changes nothing and creates no backups.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/core.sh
. "$REPO_DIR/lib/core.sh"
# shellcheck source=lib/effects.sh
. "$REPO_DIR/lib/effects.sh"

main() {
	local action
	action="$(core_parse_args "$@")"
	case "$action" in
		help)
			core_usage
			return 0
			;;
		error:*)
			printf 'Argomento sconosciuto: %s\n\n' "${action#error:}" >&2
			core_usage >&2
			return 2
			;;
	esac

	effects_install_packages "$REPO_DIR/packages"
	effects_link_dotfiles "$REPO_DIR" "$HOME" "$REPO_DIR/config/links.list" "$(date +%Y%m%d%H%M%S)"

	if [ "$EFFECTS_CHANGES" -eq 0 ]; then
		effects_log "Nessuna modifica: il sistema è già configurato."
	else
		effects_log "Fatto: $EFFECTS_CHANGES modifiche."
	fi
}

main "$@"
