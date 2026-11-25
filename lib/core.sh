# shellcheck shell=bash
# Pure functions of install.sh: they compute paths, lists and decisions
# from their arguments only. No filesystem, network, apt or systemd access,
# so they can be unit tested with bats.

# Print the usage text of install.sh.
core_usage() {
	cat <<'EOF'
Uso: ./install.sh [opzioni]

Prepara la VM Debian dell'app Terminal di Android per il desktop Hyprland:
installa i pacchetti elencati in packages/*.list e collega i dotfile
elencati in config/links.list sotto $HOME con link simbolici, salvando
una copia di backup di ogni file sostituito. È rieseguibile: una seconda
esecuzione non cambia nulla.

Opzioni:
  --session weston    torna alla sessione Weston dell'app Terminal: toglie
                      l'unità weston.service del progetto e la maschera di
                      weston.socket; non installa né rimuove pacchetti
  --session hyprland  torna alla sessione Hyprland: equivale a ./install.sh
  -h, --help          mostra questo messaggio ed esce senza modificare il sistema

Il cambio di sessione ha effetto alla successiva apertura del display, o
subito con: systemctl --user restart weston
EOF
}

# Parse the command line. Prints the action: "help", "install",
# "weston" (remove the override) or "error:<argument>" for an unknown or
# incomplete argument. "--session hyprland" is the same as no arguments.
core_parse_args() {
	if [ "$#" -eq 0 ]; then
		echo "install"
		return 0
	fi
	case "$1" in
		-h | --help)
			[ "$#" -eq 1 ] && echo "help" || echo "error:$2"
			;;
		--session)
			if [ "$#" -lt 2 ]; then
				echo "error:$1"
			elif [ "$#" -gt 2 ]; then
				echo "error:$3"
			else
				case "$2" in
					weston) echo "weston" ;;
					hyprland) echo "install" ;;
					*) echo "error:$1 $2" ;;
				esac
			fi
			;;
		*) echo "error:$1" ;;
	esac
}

# Read list lines from stdin and print the meaningful entries, one per line:
# comments (from '#') and surrounding blanks are removed, empty lines skipped.
core_list_entries() {
	local line
	while IFS= read -r line || [ -n "$line" ]; do
		line="${line%%#*}"
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"
		[ -n "$line" ] && printf '%s\n' "$line"
	done
	return 0
}

# Given the requested packages (args after "--") and the installed ones
# (args before "--"), print the requested packages that are missing,
# preserving their order and removing duplicates.
# Usage: core_missing_packages <installed...> -- <requested...>
core_missing_packages() {
	local -A installed=()
	local -A seen=()
	local pkg
	while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
		installed["$1"]=1
		shift
	done
	[ "$#" -gt 0 ] && shift
	for pkg in "$@"; do
		if [ -z "${installed[$pkg]:-}" ] && [ -z "${seen[$pkg]:-}" ]; then
			seen["$pkg"]=1
			printf '%s\n' "$pkg"
		fi
	done
	return 0
}

# Absolute target of a dotfile link: <home>/<relative target>.
core_link_target() {
	local home="$1" rel="$2"
	printf '%s/%s\n' "${home%/}" "${rel#/}"
}

# Absolute source of a dotfile link: <repo>/<relative source>.
core_link_source() {
	local repo="$1" rel="$2"
	printf '%s/%s\n' "${repo%/}" "${rel#/}"
}

# Backup path of a file replaced by a link: <target>.bak-<stamp>.
core_backup_path() {
	local target="$1" stamp="$2"
	printf '%s.bak-%s\n' "$target" "$stamp"
}

# Decide what to do with a link target, given what is there now.
#   kind:    "missing", "link", "file" (any other existing entry)
#   current: the link destination when kind is "link"
#   source:  the wanted link destination
# Prints "skip" (already correct), "link" (create it) or
# "backup" (move the existing entry away, then create the link).
core_link_action() {
	local kind="$1" current="$2" source="$3"
	case "$kind" in
		missing) echo "link" ;;
		link)
			if [ "$current" = "$source" ]; then
				echo "skip"
			else
				echo "backup"
			fi
			;;
		*) echo "backup" ;;
	esac
}

# Command line of the graphical session, one string to split on blanks.
#   start_hyprland: path of start-hyprland
#   present:        "yes" when that path is an executable file
# Hyprland when present, otherwise Weston with the same command as the
# system unit /etc/systemd/user/weston.service.
core_session_command() {
	local start_hyprland="$1" present="$2"
	if [ "$present" = "yes" ]; then
		printf '%s\n' "$start_hyprland"
	else
		echo "/usr/bin/weston --modules=systemd-notify.so --xwayland --continue-without-input"
	fi
}

# Variables a Hyprland session leaves in the systemd user manager
# environment, one line, separated by blanks. Removed when the session
# stops (ExecStopPost of systemd/weston.service) and by
# "./install.sh --session weston": with WAYLAND_DISPLAY left there the
# stock Weston unit would run nested on a socket that no longer exists.
core_session_env_vars() {
	echo "WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE"
}

# Decide how to mask a user unit, given what is at its path now
# (kind and current as in core_link_action). Prints "skip" (already
# masked), "mask" (create the link to /dev/null) or "backup" (move the
# existing entry away, then mask).
core_mask_action() {
	local kind="$1" current="$2"
	case "$(core_link_action "$kind" "$current" /dev/null)" in
		skip) echo "skip" ;;
		link) echo "mask" ;;
		*) echo "backup" ;;
	esac
}

# Decide what to do with an entry the project created under $HOME, when
# removing it (kind and current as in core_link_action; expected is the
# link destination the project wrote). Prints "skip" (nothing there),
# "remove" (the project's link) or "keep" (any other entry: it belongs to
# the user and is left alone).
core_unlink_action() {
	local kind="$1" current="$2" expected="$3"
	case "$kind" in
		missing) echo "skip" ;;
		link)
			if [ "$current" = "$expected" ]; then
				echo "remove"
			else
				echo "keep"
			fi
			;;
		*) echo "keep" ;;
	esac
}

# Name of the fixed Wayland socket used by the guest agent
# linux_vm_manager of the Terminal app for the clipboard shared with
# Android (REQ-DSK-005).
core_agent_socket() {
	echo "wayland-0"
}

# Decide how to make the agent socket an alias of the compositor socket.
#   kind:    what is at $XDG_RUNTIME_DIR/wayland-0 now: "missing", "link",
#            "socket" or "file" (any other entry)
#   current: the link destination when kind is "link"
#   wanted:  the compositor socket ($WAYLAND_DISPLAY of Hyprland)
#   alive:   "yes" when a compositor holds wayland-0.lock
# Prints "skip" (nothing to do), "link" (create the link) or "replace"
# (remove the entry, then create the link). A socket with a live
# compositor and any other kind of entry are never touched.
core_agent_socket_action() {
	local kind="$1" current="$2" wanted="$3" alive="$4"
	if [ -z "$wanted" ] || [ "$wanted" = "$(core_agent_socket)" ]; then
		echo "skip"
		return 0
	fi
	case "$kind" in
		missing) echo "link" ;;
		link)
			if [ "$current" = "$wanted" ]; then
				echo "skip"
			else
				echo "replace"
			fi
			;;
		socket)
			if [ "$alive" = "yes" ]; then
				echo "skip"
			else
				echo "replace"
			fi
			;;
		*) echo "skip" ;;
	esac
}

# Decide what to do with the agent socket when the session stops or the
# override is removed: only a link (the alias created by the project) is
# removed, so no alias is left towards a socket that no longer exists.
# Prints "remove" or "skip".
core_agent_socket_unlink_action() {
	local kind="$1"
	if [ "$kind" = "link" ]; then
		echo "remove"
	else
		echo "skip"
	fi
}
