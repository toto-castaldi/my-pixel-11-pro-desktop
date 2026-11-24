#!/usr/bin/env bash
# Closing quality gate (AGENTS.md §6): lint, Hyprland config check, unit tests.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

step() {
	printf '\n==> %s\n' "$*"
}

step "shellcheck"
shellcheck install.sh lib/*.sh scripts/*.sh

step "Hyprland --verify-config"
Hyprland --verify-config -c config/hypr/hyprland.lua

step "bats"
bats tests/

printf '\n==> Quality gate superato.\n'
