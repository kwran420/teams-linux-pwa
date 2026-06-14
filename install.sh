#!/usr/bin/env bash
set -euo pipefail

APP_ID="io.github.kwran420.TeamsPwaLinux"
APP_NAME="Teams PWA Linux"

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bindir="${XDG_BIN_HOME:-$HOME/.local/bin}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
apps_dir="$data_home/applications"
icons_dir="$data_home/icons/hicolor/scalable/apps"
desktop_file="$apps_dir/$APP_ID.desktop"
launcher_file="$bindir/teams-pwa-linux"
icon_file="$icons_dir/$APP_ID.svg"

register_mime=1
install_fonts=1
install_apt_fonts=0
dry_run=0
uninstall=0

usage() {
  cat <<USAGE
Install $APP_NAME for the current user.

Usage:
  ./install.sh
  ./install.sh --no-mime
  ./install.sh --no-fonts
  ./install.sh --with-apt-fonts
  ./install.sh --dry-run
  ./install.sh --uninstall
USAGE
}

log() {
  printf '%s\n' "$*"
}

run() {
  if [[ "$dry_run" == "1" ]]; then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

install_font_setup() {
  if [[ "$install_fonts" != "1" ]]; then
    log "skipped font setup"
    return 0
  fi

  local font_args=()
  if [[ "$install_apt_fonts" == "1" ]]; then
    font_args+=(--with-apt-compat)
  fi

  if [[ "$dry_run" == "1" ]]; then
    printf 'dry-run:'
    printf ' %q' "$repo_dir/extras/install-fonts.sh" "${font_args[@]}"
    printf '\n'
    return 0
  fi

  if ! "$repo_dir/extras/install-fonts.sh" "${font_args[@]}"; then
    if [[ "$install_apt_fonts" == "1" ]]; then
      return 1
    fi
    log "warning: font setup failed; run ./extras/install-fonts.sh manually for Segoe UI-compatible rendering"
  fi
}

desktop_contents() {
  cat <<EOF
[Desktop Entry]
Type=Application
Version=1.5
Name=Teams PWA Linux
GenericName=Microsoft Teams Web Launcher
Comment=Launch Microsoft Teams PWA in a dedicated Chromium profile
Exec=$launcher_file open %U
Icon=$APP_ID
Terminal=false
Categories=Network;InstantMessaging;VideoConference;
StartupNotify=true
StartupWMClass=TeamsPwaLinux
MimeType=x-scheme-handler/web+msteams;x-scheme-handler/msteams;x-scheme-handler/ms-teams;
Actions=Cloud;Microsoft;Personal;ResetProfile;

[Desktop Action Cloud]
Name=Open Work Teams
Exec=$launcher_file --cloud

[Desktop Action Microsoft]
Name=Open Legacy Work URL
Exec=$launcher_file --microsoft

[Desktop Action Personal]
Name=Open Personal Teams
Exec=$launcher_file --personal

[Desktop Action ResetProfile]
Name=Reset Teams Profile
Exec=$launcher_file reset-profile
EOF
}

install_app() {
  run install -d "$bindir" "$apps_dir" "$icons_dir"
  run install -m 0755 "$repo_dir/bin/teams-pwa-linux" "$launcher_file"
  run install -m 0644 "$repo_dir/assets/teams-pwa-linux.svg" "$icon_file"

  if [[ "$dry_run" == "1" ]]; then
    log "dry-run: write $desktop_file"
  else
    desktop_contents >"$desktop_file"
  fi

  if command -v desktop-file-validate >/dev/null 2>&1 && [[ "$dry_run" != "1" ]]; then
    desktop-file-validate "$desktop_file"
  fi

  if command -v update-desktop-database >/dev/null 2>&1 && [[ "$dry_run" != "1" ]]; then
    update-desktop-database "$apps_dir" >/dev/null 2>&1 || true
  fi

  if [[ "$register_mime" == "1" && "$dry_run" != "1" ]] && command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default "$APP_ID.desktop" x-scheme-handler/web+msteams || true
    xdg-mime default "$APP_ID.desktop" x-scheme-handler/msteams || true
    xdg-mime default "$APP_ID.desktop" x-scheme-handler/ms-teams || true
  fi

  install_font_setup

  log "installed launcher: $launcher_file"
  log "installed desktop entry: $desktop_file"
  log "installed icon: $icon_file"

  case ":$PATH:" in
    *":$bindir:"*) ;;
    *) log "note: $bindir is not currently in PATH for this shell" ;;
  esac
}

uninstall_app() {
  run rm -f "$launcher_file" "$desktop_file" "$icon_file"
  if command -v update-desktop-database >/dev/null 2>&1 && [[ "$dry_run" != "1" ]]; then
    update-desktop-database "$apps_dir" >/dev/null 2>&1 || true
  fi
  log "removed installed launcher, desktop entry, and icon"
  log "profile data is left in ${XDG_CONFIG_HOME:-$HOME/.config}/teams-pwa-linux"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --no-mime)
      register_mime=0
      shift
      ;;
    --no-fonts)
      install_fonts=0
      shift
      ;;
    --with-apt-fonts)
      install_fonts=1
      install_apt_fonts=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --uninstall)
      uninstall=1
      shift
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$uninstall" == "1" ]]; then
  uninstall_app
else
  install_app
fi
