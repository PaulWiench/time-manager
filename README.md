# TimeManager

A personal, Android-first time-tracking app: worked hours against a weekly
target, automatic German legal break deduction (ArbZG), a running hour
balance, and leave management. Built with Flutter, Drift (SQLite), and
Riverpod. Not commercial, sideload-only.

Full design docs live in the Obsidian Study vault
(`Study/Projects/TimeManager/`), not this repo. See `CLAUDE.md` for
architecture and the implementation plan location.

Build progress and the story of how this came together:
[`docs/build-log.html`](docs/build-log.html).

## Installing

No Play Store listing — sideload the signed release APK directly:

```
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

The release build needs `android/key.properties` (gitignored, not part of
this repo) pointing at a local keystore; without it, `flutter build apk
--release` falls back to debug signing, which installs fine for testing but
shouldn't be treated as the distributable build.
