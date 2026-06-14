# Research Notes

Date: 2026-06-14  
Test machine: Linux Mint 22.3 Cinnamon, X11, Chromium 149.0.7827.53

## Current Microsoft Guidance

Microsoft's current Linux position is web-first:

- Teams for Web is supported on Microsoft Edge, Chrome, and Firefox on Linux.
- The Teams client requirements page says Linux users have Teams for Web and Teams as a PWA.
- The Teams PWA page says Teams on the web can be installed as a PWA on Edge or Chrome.
- Microsoft recommends browser policies for PWA users: sleeping tabs, notifications, screen capture, audio capture, video capture, and cookies.

Sources:

- https://learn.microsoft.com/en-us/microsoftteams/teams-client-web
- https://learn.microsoft.com/en-us/microsoftteams/teams-client-system-requirements
- https://learn.microsoft.com/en-us/microsoftteams/teams-progressive-web-apps
- https://support.microsoft.com/en-us/teams/meetings/use-microsoft-teams-on-the-web

## Domain Migration

Microsoft still documents `https://teams.microsoft.com` as the general Teams web entry point, but Microsoft 365 is moving user-facing web apps toward `cloud.microsoft`. A Microsoft developer migration notice says Teams, Outlook, and Microsoft 365 web apps are being migrated to `cloud.microsoft`, with `teams.cloud.microsoft` available for testing and expected to operate alongside `teams.microsoft.com`.

Local checks on 2026-06-14:

- `https://teams.cloud.microsoft/?clientType=pwa` loads a Teams page with a web manifest.
- `https://teams.microsoft.com/v2/?clientType=pwa` also loads a Teams page with a web manifest.
- Both origins expose a PWA manifest when requested with a Chromium user agent.

Source:

- https://devblogs.microsoft.com/microsoft365dev/action-required-ensure-your-microsoft-teams-apps-are-ready-for-upcoming-domain-changes/

## Font Rendering

Teams and other Microsoft 365 web apps commonly request Windows-oriented font
families such as `Segoe UI`, `Segoe UI Web`, `Calibri`, and `Cambria`. A stock
Linux install may map `Segoe UI` to a generic sans-serif font, which changes
spacing and can make the UI feel wrong.

The proprietary Microsoft core fonts package on Ubuntu/Mint can add older web
fonts such as Arial and Verdana, but it does not provide Segoe UI. Microsoft's
open-source Selawik font is the better fit for Teams UI text: Microsoft
documents Selawik as an open-source replacement for Segoe UI, and Windows
typography guidance describes it as metrically compatible with Segoe UI for apps
on other platforms.

The project therefore provides `extras/install-fonts.sh` as an optional
user-level helper. It installs Selawik from Microsoft's official GitHub release
and writes fontconfig aliases mapping Teams' Segoe UI family names to Selawik.
On apt-based distros, `--with-apt-compat` also installs Carlito, Caladea, and
Liberation 2 for better Office-style fallbacks.

Sources:

- https://learn.microsoft.com/en-us/typography/font-list/selawik
- https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/typography
- https://github.com/microsoft/Selawik

## Existing Linux Wrapper

The mature community option is `IsmaelMartinez/teams-for-linux`. It is active, widely used, and feature-rich. It supports notifications, tray integration, custom backgrounds, screen sharing, and multiple profiles. It also has more moving parts: Electron, DOM access, custom notification behavior, badge tracking, packaging across several systems, and Electron security tradeoffs documented by the project.

Notable finding: the README says Electron `contextIsolation` and sandbox features are disabled to enable Teams DOM access functionality, recommending system-level sandboxing instead.

Source:

- https://github.com/IsmaelMartinez/teams-for-linux

## Rejected Options

### New Electron wrapper

Rejected for the first version. Electron would duplicate a Chromium runtime, increase package size, require frequent dependency maintenance, and tempt us into DOM scraping to add tray badges or custom notifications. That is exactly where existing wrappers accumulate breakage when Teams changes.

### Tauri/WebKitGTK

Rejected. Tauri is attractive for small Linux apps, but Tauri uses WebKitGTK on Linux. Microsoft's Teams Linux support matrix does not list Linux WebKitGTK or Safari on Linux. It lists Edge, Chrome, and Firefox on Linux, and PWA installation through Edge or Chrome.

Source:

- https://v2.tauri.app/reference/webview-versions/

### Browser enterprise policy as the default

Rejected as the default install path. `WebAppInstallForceList` is an official Chrome/Edge way to force-install PWAs, and Microsoft recommends it for managed Teams PWA deployment. It is useful for a managed mode later, but applying browser policy locally can make the browser show as managed and may affect all profiles for that browser. A user-level desktop launcher is less invasive.

Sources:

- https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/webappinstallforcelist
- https://support.google.com/chrome/a/answer/9367354

## Chosen Design

Use the official Teams PWA URL inside a dedicated Chromium-family browser profile.

The launcher:

- Uses a system-updated Chromium-family browser.
- Keeps Teams cookies, cache, and auth state away from the user's normal browser profile.
- Uses `--app=` for a standalone app window.
- Registers XDG desktop and Teams protocol handlers.
- Enables the WebRTC PipeWire capturer feature for Wayland compatibility without forcing Wayland.
- Avoids flags that disable browser security.
- Avoids Teams DOM access, injected scripts, and custom badge scraping.
- Supports both `teams.cloud.microsoft` and `teams.microsoft.com`.

Chromium documents `--user-data-dir` as the supported way to override the browser user data directory. The Mint Chromium man page also documents separate instances requiring separate user data directories.

Source:

- https://chromium.googlesource.com/chromium/src/+/HEAD/docs/user_data_dir.md

## Known Limitations

- No tray unread badge in v0.1. That would require DOM/title scraping or notification interception.
- First launch still requires Microsoft sign-in and browser permission prompts.
- HTTPS meeting links still open in the system default browser unless the source application emits a Teams protocol URL. Taking over all `https` links would be the wrong tradeoff.
- Linux notification behavior still depends on the browser and desktop environment.
- Wayland screen sharing depends on PipeWire and xdg-desktop-portal. The test machine is X11, so Wayland should be treated as supported by design but not fully validated here.

## Future Work

- Optional managed-mode installer for Chrome/Edge policies.
- Named profile support, for example `teams-pwa-linux --profile work` and `--profile client`.
- Optional URL router for users who want Teams meeting URLs opened from selected apps.
- AppImage or deb packaging after more testing.
