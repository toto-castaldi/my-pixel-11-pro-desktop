# shellcheck shell=bash
# Side-effect functions of install.sh: apt and filesystem.
# sudo is used only for apt (AGENTS.md §5).

# Number of changes made in this run, reported at the end.
EFFECTS_CHANGES=0
# 1 when a user systemd unit was linked or masked in this run.
EFFECTS_UNITS_CHANGED=0

effects_log() {
	printf '==> %s\n' "$*"
}

# Install the missing packages among those listed in <dir>/*.list.
# Each line names one package; packages to take from trixie-backports go
# in files named *.backports.list.
effects_install_packages() {
	local dir="$1" file
	local -a installed requested missing target_release
	mapfile -t installed < <(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 2>/dev/null | awk '$1 == "ii" { print $2 }')
	for file in "$dir"/*.list; do
		[ -e "$file" ] || continue
		mapfile -t requested < <(core_list_entries <"$file")
		[ "${#requested[@]}" -gt 0 ] || continue
		mapfile -t missing < <(core_missing_packages "${installed[@]}" -- "${requested[@]}")
		[ "${#missing[@]}" -gt 0 ] || continue
		target_release=()
		case "$file" in
			*.backports.list) target_release=(-t trixie-backports) ;;
		esac
		effects_log "Installo i pacchetti di $(basename "$file"): ${missing[*]}"
		sudo apt-get install -y "${target_release[@]}" "${missing[@]}"
		EFFECTS_CHANGES=$((EFFECTS_CHANGES + 1))
	done
}

# Create the dotfile links listed in <manifest>: "<source in repo> <target under $HOME>".
effects_link_dotfiles() {
	local repo="$1" home="$2" manifest="$3" stamp="$4"
	local entry src_rel dst_rel src dst kind current action backup
	[ -e "$manifest" ] || return 0
	while IFS= read -r entry; do
		read -r src_rel dst_rel <<<"$entry"
		src="$(core_link_source "$repo" "$src_rel")"
		dst="$(core_link_target "$home" "$dst_rel")"
		current=""
		if [ -L "$dst" ]; then
			kind="link"
			current="$(readlink "$dst")"
		elif [ -e "$dst" ]; then
			kind="file"
		else
			kind="missing"
		fi
		action="$(core_link_action "$kind" "$current" "$src")"
		case "$action" in
			skip) continue ;;
			backup)
				backup="$(core_backup_path "$dst" "$stamp")"
				effects_log "Backup di $dst in $backup"
				mv "$dst" "$backup"
				;;
		esac
		effects_log "Collego $dst -> $src"
		case "$dst" in
			*/.config/systemd/user/*) EFFECTS_UNITS_CHANGED=1 ;;
		esac
		mkdir -p "$(dirname "$dst")"
		ln -s "$src" "$dst"
		EFFECTS_CHANGES=$((EFFECTS_CHANGES + 1))
	done < <(core_list_entries <"$manifest")
}

# Mask the user unit <name> in <home>/.config/systemd/user/ with a link to
# /dev/null, as "systemctl --user mask" does, backing up any other entry.
effects_mask_unit() {
	local home="$1" name="$2" stamp="$3"
	local dst kind current action backup
	dst="$(core_link_target "$home" ".config/systemd/user/$name")"
	current=""
	if [ -L "$dst" ]; then
		kind="link"
		current="$(readlink "$dst")"
	elif [ -e "$dst" ]; then
		kind="file"
	else
		kind="missing"
	fi
	action="$(core_mask_action "$kind" "$current")"
	case "$action" in
		skip) return 0 ;;
		backup)
			backup="$(core_backup_path "$dst" "$stamp")"
			effects_log "Backup di $dst in $backup"
			mv "$dst" "$backup"
			;;
	esac
	effects_log "Maschero $name"
	mkdir -p "$(dirname "$dst")"
	ln -s /dev/null "$dst"
	EFFECTS_CHANGES=$((EFFECTS_CHANGES + 1))
	EFFECTS_UNITS_CHANGED=1
}

# Remove the link <home>/<rel> if it points to <expected>; any other entry
# is left in place with a warning, so a user file is never lost.
effects_unlink() {
	local home="$1" rel="$2" expected="$3"
	local dst kind current
	dst="$(core_link_target "$home" "$rel")"
	current=""
	if [ -L "$dst" ]; then
		kind="link"
		current="$(readlink "$dst")"
	elif [ -e "$dst" ]; then
		kind="file"
	else
		kind="missing"
	fi
	case "$(core_unlink_action "$kind" "$current" "$expected")" in
		skip) return 0 ;;
		keep)
			effects_log "Lascio $dst: non è stato creato da questo progetto"
			return 0
			;;
	esac
	effects_log "Rimuovo $dst"
	rm "$dst"
	EFFECTS_CHANGES=$((EFFECTS_CHANGES + 1))
	case "$dst" in
		*/.config/systemd/user/*) EFFECTS_UNITS_CHANGED=1 ;;
	esac
}

# Remove WAYLAND_DISPLAY and DISPLAY from the user manager environment.
# Hyprland exports them there; with them the stock Weston unit would try
# to run nested in a compositor that no longer exists and fail. This is
# runtime state only, so it is not counted as a change.
effects_forget_session_env() {
	systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY
}

# Reload the user systemd manager when units changed in this run.
effects_reload_units() {
	[ "$EFFECTS_UNITS_CHANGED" -eq 1 ] || return 0
	effects_log "Ricarico le unità systemd utente"
	systemctl --user daemon-reload
}
