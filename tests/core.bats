#!/usr/bin/env bats
# Unit tests of the pure functions in lib/core.sh: no filesystem, network or systemd.

setup() {
	# shellcheck source=../lib/core.sh
	. "$BATS_TEST_DIRNAME/../lib/core.sh"
}

@test "parse_args: no arguments means install" {
	run core_parse_args
	[ "$output" = "install" ]
}

@test "parse_args: -h and --help mean help" {
	run core_parse_args --help
	[ "$output" = "help" ]
	run core_parse_args -h
	[ "$output" = "help" ]
}

@test "parse_args: unknown argument is an error" {
	run core_parse_args --boh
	[ "$output" = "error:--boh" ]
}

@test "usage mentions --help" {
	run core_usage
	[ "$status" -eq 0 ]
	[[ "$output" == *"--help"* ]]
}

@test "list_entries: drops comments, blanks and empty lines" {
	run core_list_entries <<<$'# header\n\n  foot  \nwaybar # bar\n   # only comment\nfuzzel'
	[ "$status" -eq 0 ]
	[ "$output" = $'foot\nwaybar\nfuzzel' ]
}

@test "list_entries: last line without newline is kept" {
	run core_list_entries < <(printf 'a\nb')
	[ "$output" = $'a\nb' ]
}

@test "missing_packages: keeps order, skips installed and duplicates" {
	run core_missing_packages foot mako -- waybar foot fuzzel waybar mako
	[ "$output" = $'waybar\nfuzzel' ]
}

@test "missing_packages: nothing missing prints nothing" {
	run core_missing_packages foot -- foot
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "missing_packages: no installed packages" {
	run core_missing_packages -- foot
	[ "$output" = "foot" ]
}

@test "link_target and link_source join paths" {
	run core_link_target /home/droid/ .config/hypr/hyprland.lua
	[ "$output" = "/home/droid/.config/hypr/hyprland.lua" ]
	run core_link_source /repo config/hypr/hyprland.lua
	[ "$output" = "/repo/config/hypr/hyprland.lua" ]
}

@test "backup_path appends the stamp" {
	run core_backup_path /home/droid/.config/foot/foot.ini 20261124120000
	[ "$output" = "/home/droid/.config/foot/foot.ini.bak-20261124120000" ]
}

@test "link_action: missing target is linked" {
	run core_link_action missing "" /repo/a
	[ "$output" = "link" ]
}

@test "link_action: correct link is skipped (idempotence)" {
	run core_link_action link /repo/a /repo/a
	[ "$output" = "skip" ]
}

@test "link_action: other link or file is backed up" {
	run core_link_action link /elsewhere /repo/a
	[ "$output" = "backup" ]
	run core_link_action file "" /repo/a
	[ "$output" = "backup" ]
}

@test "session_command: Hyprland when start-hyprland is present" {
	run core_session_command /usr/bin/start-hyprland yes
	[ "$output" = "/usr/bin/start-hyprland" ]
}

@test "session_command: Weston with the system unit command when start-hyprland is missing" {
	run core_session_command /usr/bin/start-hyprland no
	[ "$output" = "/usr/bin/weston --modules=systemd-notify.so --xwayland --continue-without-input" ]
}

@test "session_env_vars: the variables Hyprland leaves in the user manager" {
	run core_session_env_vars
	[ "$output" = "WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE" ]
}

@test "mask_action: missing unit is masked" {
	run core_mask_action missing ""
	[ "$output" = "mask" ]
}

@test "mask_action: masked unit is skipped (idempotence)" {
	run core_mask_action link /dev/null
	[ "$output" = "skip" ]
}

@test "mask_action: other link or file is backed up" {
	run core_mask_action link /elsewhere
	[ "$output" = "backup" ]
	run core_mask_action file ""
	[ "$output" = "backup" ]
}

@test "parse_args: --session weston and --session hyprland" {
	run core_parse_args --session weston
	[ "$output" = "weston" ]
	run core_parse_args --session hyprland
	[ "$output" = "install" ]
}

@test "parse_args: --session without a valid name is an error" {
	run core_parse_args --session
	[ "$output" = "error:--session" ]
	run core_parse_args --session kde
	[ "$output" = "error:--session kde" ]
	run core_parse_args --session weston extra
	[ "$output" = "error:extra" ]
	run core_parse_args --help extra
	[ "$output" = "error:extra" ]
}

@test "usage mentions --session" {
	run core_usage
	[[ "$output" == *"--session weston"* ]]
	[[ "$output" == *"--session hyprland"* ]]
}

@test "unlink_action: nothing there is skipped" {
	run core_unlink_action missing "" /dev/null
	[ "$output" = "skip" ]
}

@test "unlink_action: the project's link is removed" {
	run core_unlink_action link /repo/systemd/weston.service /repo/systemd/weston.service
	[ "$output" = "remove" ]
	run core_unlink_action link /dev/null /dev/null
	[ "$output" = "remove" ]
}

@test "unlink_action: other links and files are kept" {
	run core_unlink_action link /elsewhere/weston.service /repo/systemd/weston.service
	[ "$output" = "keep" ]
	run core_unlink_action file "" /dev/null
	[ "$output" = "keep" ]
}

@test "agent_socket: the Terminal app agent uses wayland-0 (US-007)" {
	run core_agent_socket
	[ "$output" = "wayland-0" ]
}

@test "agent_socket_action: a missing wayland-0 is linked to the compositor socket" {
	run core_agent_socket_action missing "" wayland-1 no
	[ "$output" = "link" ]
}

@test "agent_socket_action: the right link is kept, a stale one replaced" {
	run core_agent_socket_action link wayland-1 wayland-1 no
	[ "$output" = "skip" ]
	run core_agent_socket_action link wayland-2 wayland-1 no
	[ "$output" = "replace" ]
}

@test "agent_socket_action: an orphan socket is replaced, a live one kept" {
	run core_agent_socket_action socket "" wayland-1 no
	[ "$output" = "replace" ]
	run core_agent_socket_action socket "" wayland-1 yes
	[ "$output" = "skip" ]
}

@test "agent_socket_action: other entries and a compositor already on wayland-0 are left alone" {
	run core_agent_socket_action file "" wayland-1 no
	[ "$output" = "skip" ]
	run core_agent_socket_action socket "" wayland-0 yes
	[ "$output" = "skip" ]
	run core_agent_socket_action missing "" wayland-0 no
	[ "$output" = "skip" ]
	run core_agent_socket_action missing "" "" no
	[ "$output" = "skip" ]
}

@test "agent_socket_unlink_action: only the alias link is removed" {
	run core_agent_socket_unlink_action link
	[ "$output" = "remove" ]
	for kind in missing socket file; do
		run core_agent_socket_unlink_action "$kind"
		[ "$output" = "skip" ]
	done
}
