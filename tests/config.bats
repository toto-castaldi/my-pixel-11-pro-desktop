#!/usr/bin/env bats
# Checks on the versioned desktop configuration (US-003): they only read
# repository files, they create nothing.

setup() {
	# shellcheck source=../lib/core.sh
	. "$BATS_TEST_DIRNAME/../lib/core.sh"
	REPO="$BATS_TEST_DIRNAME/.."
	HYPR="$REPO/config/hypr/hyprland.lua"
}

@test "links.list: every source exists in the repository" {
	local src dst
	while read -r src dst; do
		[ -n "$dst" ]
		[ -f "$REPO/$src" ] || { echo "missing: $src"; return 1; }
	done < <(core_list_entries <"$REPO/config/links.list")
}

@test "links.list: desktop dotfiles are linked into ~/.config" {
	run core_list_entries <"$REPO/config/links.list"
	[[ "$output" == *"config/hypr/hyprland.lua .config/hypr/hyprland.lua"* ]]
	[[ "$output" == *"config/waybar/config.jsonc .config/waybar/config.jsonc"* ]]
	[[ "$output" == *"config/waybar/style.css .config/waybar/style.css"* ]]
	[[ "$output" == *"config/foot/foot.ini .config/foot/foot.ini"* ]]
	[[ "$output" == *"config/fuzzel/fuzzel.ini .config/fuzzel/fuzzel.ini"* ]]
}

@test "packages: desktop applications are installed" {
	run core_list_entries <"$REPO/packages/base.list"
	[[ "$output" == *$'\nwaybar'* ]]
	[[ "$output" == *$'\nfuzzel'* ]]
	[[ "$output" == *"foot"* ]]
}

@test "hyprland.lua: italian keyboard layout and no blur" {
	grep -Eq 'kb_layout *= *"it"' "$HYPR"
	run grep -A2 'blur = {' "$HYPR"
	[[ "$output" == *"enabled = false"* ]]
}

@test "hyprland.lua: ALT is the main modifier, SUPER and Tab are never bound" {
	grep -Eq 'local mainMod *= *"ALT"' "$HYPR"
	run grep -nE 'hl\.bind\(.*(SUPER|[Tt]ab\b)' "$HYPR"
	[ "$status" -eq 1 ]
}

@test "hyprland.lua: documented shortcuts are bound" {
	grep -q 'mainMod .. " + Return", hl.dsp.exec_cmd(terminal)' "$HYPR"
	grep -q 'mainMod .. " + SPACE",  hl.dsp.exec_cmd(menu)' "$HYPR"
	grep -q 'mainMod .. " + Q",      hl.dsp.window.close()' "$HYPR"
	grep -q 'hl.bind("CTRL + ALT + Q"' "$HYPR"
	grep -q 'hl.dsp.focus({ workspace = i })' "$HYPR"
	grep -q 'hl.dsp.window.move({ workspace = i })' "$HYPR"
}

@test "hyprland.lua: waybar starts with the session" {
	grep -q 'hl.exec_cmd("waybar")' "$HYPR"
	grep -q 'dbus-update-activation-environment --systemd' "$HYPR"
}

@test "waybar: shows workspaces and clock" {
	grep -q '"hyprland/workspaces"' "$REPO/config/waybar/config.jsonc"
	grep -q '"clock"' "$REPO/config/waybar/config.jsonc"
}

@test "links.list: wallpaper, lock screen and notifications are linked (US-004)" {
	run core_list_entries <"$REPO/config/links.list"
	[[ "$output" == *"config/hypr/wallpaper.png .config/hypr/wallpaper.png"* ]]
	[[ "$output" == *"config/hypr/hyprlock.conf .config/hypr/hyprlock.conf"* ]]
	[[ "$output" == *"config/mako/config .config/mako/config"* ]]
}

@test "packages: swaybg, mako and notify-send from trixie, hyprlock from backports, no hyprpaper" {
	run core_list_entries <"$REPO/packages/base.list"
	[[ "$output" == *"swaybg"* ]]
	[[ "$output" == *"mako-notifier"* ]]
	[[ "$output" == *"libnotify-bin"* ]]
	run core_list_entries <"$REPO/packages/hyprland.backports.list"
	[[ "$output" == *"hyprlock"* ]]
	run grep -q hyprpaper "$REPO/packages/base.list" "$REPO/packages/hyprland.backports.list" "$REPO/config/links.list"
	[ "$status" -eq 1 ]
}

@test "wallpaper: the versioned image is a PNG" {
	run head -c 8 "$REPO/config/hypr/wallpaper.png"
	[[ "$output" == $'\x89PNG'* ]]
}

@test "hyprland.lua: wallpaper and notifications start with the session, CTRL + ALT + L locks" {
	grep -q 'local wallpaper = "swaybg -m fill -i ~/.config/hypr/wallpaper.png"' "$HYPR"
	grep -q 'hl.exec_cmd(wallpaper)' "$HYPR"
	grep -q 'hl.exec_cmd("mako")' "$HYPR"
	grep -q 'hl.bind("CTRL + ALT + L",       hl.dsp.exec_cmd(locker)' "$HYPR"
	grep -q 'local locker   = "pidof hyprlock || hyprlock"' "$HYPR"
}

@test "hyprlock.conf: wallpaper background without blur and a password field" {
	grep -q 'path = ~/.config/hypr/wallpaper.png' "$REPO/config/hypr/hyprlock.conf"
	grep -q 'blur_passes = 0' "$REPO/config/hypr/hyprlock.conf"
	grep -q '^input-field {' "$REPO/config/hypr/hyprlock.conf"
}

@test "packages: screenshot and clipboard tools are installed (US-005)" {
	run core_list_entries <"$REPO/packages/base.list"
	for p in grim slurp wl-clipboard cliphist; do
		[[ "$output" == *$'\n'"$p"* ]] || { echo "missing: $p"; return 1; }
	done
}

@test "hyprland.lua: screenshots go to ~/Pictures/Screenshots, ALT + P and ALT + SHIFT + P capture (US-005)" {
	grep -q 'f="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"' "$HYPR"
	grep -q "local shotFull = shotFile .. ' && grim \"\$f\"'" "$HYPR"
	grep -q "g=\"\$(slurp)\" && grim -g \"\$g\" \"\$f\"" "$HYPR"
	grep -q 'mainMod .. " + P",         hl.dsp.exec_cmd(shotFull)' "$HYPR"
	grep -q 'mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(shotArea)' "$HYPR"
}

@test "hyprland.lua: cliphist records the clipboard, CTRL + ALT + V opens the history (US-005)" {
	grep -q 'hl.exec_cmd(clipStore)' "$HYPR"
	grep -q 'local clipStore   = "wl-paste --type text --watch cliphist store"' "$HYPR"
	grep -q 'cliphist list | fuzzel --dmenu' "$HYPR"
	grep -q 'cliphist decode | wl-copy' "$HYPR"
	grep -q 'hl.bind("CTRL + ALT + V",       hl.dsp.exec_cmd(clipHistory)' "$HYPR"
}

@test "weston.service: the session leaves no Wayland variables in the user manager (BUG-001)" {
	local unit="$REPO/systemd/weston.service"
	grep -qx 'Environment=HYPRLAND_NO_SD_VARS=1' "$unit"
	grep -qx "ExecStopPost=/usr/bin/systemctl --user unset-environment $(core_session_env_vars)" "$unit"
}

@test "shared clipboard: wayland-0 follows Hyprland and is removed when the session stops (US-007)" {
	run core_list_entries <"$REPO/config/links.list"
	[[ "$output" == *"systemd/session-socket.sh .local/libexec/my-pixel-11-pro-desktop/session-socket"* ]]
	grep -q 'hl.exec_cmd(agentSocket)' "$HYPR"
	grep -q 'my-pixel-11-pro-desktop/session-socket link"' "$HYPR"
	grep -qx 'ExecStopPost=-%h/.local/libexec/my-pixel-11-pro-desktop/session-socket unlink' "$REPO/systemd/weston.service"
	grep -q 'session-socket.sh" unlink' "$REPO/systemd/start-session.sh"
	grep -q 'effects_forget_agent_socket' "$REPO/install.sh"
}

@test "weston.service: the stale weston.socket is stopped, so the stock Weston gets wayland-0 back (US-007)" {
	grep -qx 'ExecStartPre=-/usr/bin/systemctl --user --no-block stop weston.socket' "$REPO/systemd/weston.service"
	run grep -E '^(Requires|BindsTo|Wants)=.*weston.socket' "$REPO/systemd/weston.service"
	[ "$status" -ne 0 ]
}
