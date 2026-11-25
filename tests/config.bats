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
