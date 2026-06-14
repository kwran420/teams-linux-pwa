# Teams PWA Linux

A small Linux desktop launcher for Microsoft Teams on the web.

This is not an Electron client and it does not reimplement Teams. It launches the official Teams PWA URL in a dedicated Chromium-family browser profile, adds a desktop entry, and registers Teams protocol handlers.

## Why this approach

Microsoft's current Linux guidance is web/PWA-first: Teams for Web is supported on current Edge, Chrome, and Firefox on Linux, and Linux users have access to Teams for Web and Teams as a PWA. Microsoft documents Teams PWA installation through Edge or Chrome and recommends browser policies for notifications, screen capture, audio, video, cookies, and sleeping-tab behavior.

The existing `teams-for-linux` project is active and feature-rich, but it is an Electron wrapper around the Teams web app. It also documents that Electron `contextIsolation` and sandbox features are disabled to support Teams DOM access. This project intentionally avoids DOM scraping, injected scripts, custom notification scraping, tray badge logic, and a bundled Electron runtime.

Tauri is not a good fit for this specific app. On Linux, Tauri uses WebKitGTK; Microsoft supports Safari only on macOS for Teams for Web, not WebKitGTK on Linux. A Chromium-family browser is the closer match to Microsoft's Linux PWA path.

## Install

```bash
./install.sh
```

Then launch **Teams PWA Linux** from the app menu, or run:

```bash
teams-pwa-linux
```

The installer writes only user-level files under `~/.local` and `~/.config`.

## Fonts

If the Teams UI text looks off on Linux, the usual missing font is `Segoe UI`.
The Ubuntu/Mint `ttf-mscorefonts-installer` package adds older Microsoft core
web fonts such as Arial and Verdana, but it does not include Segoe UI.

This repo includes an optional helper that installs Microsoft's open-source
Segoe UI replacement, Selawik, and maps Teams' Segoe UI font requests to it for
the current user:

```bash
./extras/install-fonts.sh
```

For better Office document and attachment fallbacks on apt-based distros:

```bash
./extras/install-fonts.sh --with-apt-compat
```

Restart the Teams PWA window after changing fonts.

## Browser Selection

The launcher looks for browsers in this order:

1. `microsoft-edge-stable`
2. `microsoft-edge`
3. `google-chrome-stable`
4. `google-chrome`
5. `chrome`
6. `chromium`
7. `chromium-browser`
8. `brave-browser`
9. `vivaldi`

Override it with:

```bash
TEAMS_PWA_BROWSER=/usr/bin/chromium teams-pwa-linux
```

## URLs

The default work URL is:

```text
https://teams.cloud.microsoft/?clientType=pwa
```

Use the older Microsoft Teams origin when needed:

```bash
teams-pwa-linux --microsoft
```

Use personal Teams:

```bash
teams-pwa-linux --personal
```

## Recovery

Check the local setup:

```bash
teams-pwa-linux status
teams-pwa-linux doctor
```

Reset the dedicated Teams browser profile:

```bash
teams-pwa-linux reset-profile
```

Clear the launcher cache:

```bash
teams-pwa-linux clear-cache
```

Uninstall the app entry and launcher:

```bash
./install.sh --uninstall
```

Profile data is intentionally left behind on uninstall. Remove it with `teams-pwa-linux reset-profile` first if you want a clean reinstall.

## Validation

```bash
./tests/smoke.sh
```

The smoke test checks shell syntax, a temp-home install, desktop-file validity, command generation, and a headless Chromium load of the Teams PWA page.

## Research Notes

Key sources checked on June 14, 2026:

- Microsoft Teams PWA docs: https://learn.microsoft.com/en-us/microsoftteams/teams-progressive-web-apps
- Teams web prerequisites: https://learn.microsoft.com/en-us/microsoftteams/teams-client-web
- Teams client system requirements: https://learn.microsoft.com/en-us/microsoftteams/teams-client-system-requirements
- Teams web support page: https://support.microsoft.com/en-us/teams/meetings/use-microsoft-teams-on-the-web
- cloud.microsoft Teams domain migration: https://devblogs.microsoft.com/microsoft365dev/action-required-ensure-your-microsoft-teams-apps-are-ready-for-upcoming-domain-changes/
- Microsoft Selawik font: https://learn.microsoft.com/en-us/typography/font-list/selawik
- Chromium user data directory docs: https://chromium.googlesource.com/chromium/src/+/HEAD/docs/user_data_dir.md
- FreeDesktop desktop entry spec: https://specifications.freedesktop.org/desktop-entry/latest-single/
- Existing Electron wrapper: https://github.com/IsmaelMartinez/teams-for-linux
- Tauri webview versions: https://v2.tauri.app/reference/webview-versions/

## Disclaimer

This project is independent and is not affiliated with Microsoft. Microsoft Teams is a Microsoft product and trademark. The included icon is original and intentionally not a Microsoft Teams logo.
