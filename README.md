# todo list

A native, local-only macOS quick-notes utility designed to sit quietly under the
notch or menu bar. It uses public AppKit/SwiftUI APIs and falls back cleanly on
displays without a notch.

## Features

- Menu bar app with a compact floating capture panel
- Create, edit, complete, pin, delete, search, and filter notes
- JSON persistence in `~/Library/Application Support/NotchNotes/notes.json`
- Automatic notch-aware positioning with a non-notch fallback
- Light/dark appearance and accessibility labels

## Build and test

```bash
swift test
./scripts/build-app.sh
open build/NotchNotes.app
```

The app is intentionally dependency-free. The build script creates and
ad-hoc-signs a runnable `.app` bundle in `build/`.
