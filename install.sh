#!/usr/bin/env bash
# Install the Hyprland desktop on the Android Terminal app VM.
# Idempotent: a second run changes nothing and creates no backups.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/core.sh
. "$REPO_DIR/lib/core.sh"
# shellcheck source=lib/effects.sh
. "$REPO_DIR/lib/effects.sh"

# Back to the Weston session of the Terminal app: remove the override unit
# and the mask of weston.socket. Packages and the other dotfiles stay.
session_weston() {
	effects_unlink "$HOME" .config/systemd/user/weston.service "$REPO_DIR/systemd/weston.service"
	effects_unlink "$HOME" .config/systemd/user/weston.socket /dev/null
	effects_reload_units
	effects_forget_session_env

	if [ "$EFFECTS_CHANGES" -eq 0 ]; then
		effects_log "Nessuna modifica: la sessione è già Weston."
	else
		effects_log "Fatto: $EFFECTS_CHANGES modifiche. Alla prossima apertura del display parte Weston."
		effects_log "Per passare subito a Weston: systemctl --user restart weston (o riavvia la VM)."
	fi
	effects_log "Per tornare a Hyprland: ./install.sh --session hyprland"
}

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

	if [ "$action" = "weston" ]; then
		session_weston
		return 0
	fi

	local stamp
	stamp="$(date +%Y%m%d%H%M%S)"
	effects_install_packages "$REPO_DIR/packages"
	effects_link_dotfiles "$REPO_DIR" "$HOME" "$REPO_DIR/config/links.list" "$stamp"
	effects_mask_unit "$HOME" weston.socket "$stamp"
	effects_reload_units

	if [ "$EFFECTS_CHANGES" -eq 0 ]; then
		effects_log "Nessuna modifica: il sistema è già configurato."
	else
		effects_log "Fatto: $EFFECTS_CHANGES modifiche."
	fi
	if [ "$EFFECTS_UNITS_CHANGED" -eq 1 ]; then
		effects_log "Per avviare la nuova sessione: systemctl --user restart weston (o riavvia la VM)."
	fi
}

main "$@"
