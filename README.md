# Trash Panda: App Manager

A clean, native macOS utility for managing installed apps and reclaiming disk space.
This loves digging through your system and eating the unwanted apps and garbage.

Most uninstallers only delete the .app bundle. Trash Panda goes further — it finds
every cache, preference file, log, and support folder an app leaves behind, and lets
you decide exactly what to remove.

Built with Swift, SwiftUI, and AppKit — no Python, no webview, no JS bridge.

## Features

- **Full uninstall** — removes the app bundle and all associated leftover files
- **Clear cache** — frees up cache storage without touching your settings or data
- **Reset app** — wipes all app data so it launches like a fresh install
- **Orphaned file scanner** — detects leftover files from apps that are no longer installed
- **Real app icons** — displays actual app icons pulled from each bundle via `NSWorkspace`
- **Permission check** — guides you through granting Full Disk Access on first launch
- **Safety indicators** — flags orphaned files that are still linked to an installed app so you never delete the wrong thing
- **Confirmation before every delete** — clearing cache, resetting, uninstalling, and removing
  orphaned files all ask first and say exactly what will happen
- **Trash, not permanent delete, by default** — everything goes through the Trash (via
  `NSWorkspace`) so it's recoverable; an optional **Settings → Empty Trash after deleting** toggle
  permanently frees the space immediately instead

Native macOS conventions throughout: a real sidebar (`List` + `NavigationSplitView`), a toolbar
with search/sort/refresh, and preferences in the standard Settings window (**⌘,**) instead of a tab.

## Requirements

- macOS 13 Ventura or later
- Full Disk Access (prompted on first launch)

## Build & run

```bash
open Package.swift      # opens in Xcode — press Run
# or, from Terminal:
swift run
```

## Produce a distributable app

```bash
./Scripts/build_app.sh  # assembles dist/"Trash Panda - App Manager.app", ad-hoc signed
```

Or push a `v*` tag, or run the "Build App Manager (Swift)" GitHub Actions workflow manually —
it builds on a macOS runner and, on a tag push, attaches the zipped app to a GitHub Release.

## Project layout

- `Sources/AppManager/Models` — data types (`InstalledApp`, `LeftoverFile`, `OrphanFile`)
- `Sources/AppManager/Services` — app scanning, orphan detection, file cleanup, Full Disk Access checks
- `Sources/AppManager/Settings` — persisted preferences (`UserDefaults`)
- `Sources/AppManager/ViewModels` — reactive state for the Apps/Orphaned tabs
- `Sources/AppManager/Views` — SwiftUI views
- `Resources/Icon.png` — source app icon (2048×2048); `Scripts/build_app.sh` generates `AppIcon.icns`
  from it at build time (via `sips`/`iconutil`) and embeds it into the built `.app`

## License

MIT — see [LICENSE](LICENSE).

---

Made by [Zahidul Haque Tipu](https://github.com/zhtipu1)
