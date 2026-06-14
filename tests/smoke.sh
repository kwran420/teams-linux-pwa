#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

export HOME="$tmp_dir/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$HOME"

bash -n "$repo_dir/bin/teams-pwa-linux"
bash -n "$repo_dir/install.sh"
bash -n "$repo_dir/extras/install-fonts.sh"

"$repo_dir/install.sh" --no-mime >/tmp/teams-pwa-install.log

desktop_file="$XDG_DATA_HOME/applications/io.github.kwran420.TeamsPwaLinux.desktop"
test -x "$HOME/.local/bin/teams-pwa-linux"
test -f "$desktop_file"
test -f "$XDG_DATA_HOME/icons/hicolor/scalable/apps/io.github.kwran420.TeamsPwaLinux.svg"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$desktop_file"
fi

command_output="$("$repo_dir/bin/teams-pwa-linux" print-command)"
case "$command_output" in
  *"--app=https://teams.cloud.microsoft/"*"clientType=pwa"*) ;;
  *) echo "expected cloud Teams app URL in print-command output" >&2; exit 1 ;;
esac

"$repo_dir/bin/teams-pwa-linux" --microsoft print-command | grep -q -- '--app=https://teams.microsoft.com/v2/.*clientType=pwa'
"$repo_dir/bin/teams-pwa-linux" --personal print-command | grep -q -- '--app=https://teams.live.com/v2/.*clientType=pwa'

if command -v chromium >/dev/null 2>&1; then
  profile="$tmp_dir/chromium-smoke"
  chromium --headless=new --disable-gpu --no-first-run --no-default-browser-check \
    --user-data-dir="$profile" \
    --dump-dom 'https://teams.cloud.microsoft/?clientType=pwa' 2>/dev/null |
    grep -q 'rel="manifest"'
fi

echo "smoke tests passed"
