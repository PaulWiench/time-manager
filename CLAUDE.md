# CLAUDE.md — time-manager

Personal Android-first time-tracking app. Flutter/Dart, Drift (SQLite),
Riverpod, native Kotlin + Jetpack Glance widget, fl_chart + CustomPainter,
sideload-only distribution.

## Source of truth for design

Full requirements, data model, UX/screen architecture, and tech-stack decisions
were locked *before* implementation started and live in the Obsidian Study
vault, not in this repo: `Study/Projects/TimeManager/` (Requirements & Scope,
Data Model, UX & Screen Architecture, Tech Stack, TimeManager Log.md). Read
those before making any decision that contradicts what's here — this repo
implements that spec, it doesn't redefine it.

## Implementation plan

The milestone plan (scaffold → data layer → domain engines → Riverpod wiring →
design-system spec checkpoint → core UI → widget → stats/charts →
polish/release) is at
`/home/paulos/.claude/plans/groovy-twirling-meteor.md`. Check current milestone
progress there before assuming where the build stands.

**Milestone 5 is a hard checkpoint**: implementation stops before any UI code
is written so Paul can take a design-system + screen spec doc to Claude Design
externally. Do not start Milestone 6 (Core UI) without his explicit go-ahead.

## Architecture

```
lib/
  main.dart / app.dart        # entrypoint, MaterialApp, theming
  core/theme/                 # design tokens (placeholder until M5 spec lands)
  data/database/               # Drift: tables, Database, DAOs, migrations
  data/repositories/           # repository wrappers over Drift
  domain/                      # pure Dart, no Flutter imports — unit tested.
                                # break_engine, recalculation_engine,
                                # midnight_cutoff, holiday_calculator,
                                # vacation_rollover
  providers/                   # Riverpod providers wiring repos + domain
                                # engines over Drift watch streams
  features/{onboarding,home,history,stats,settings}/
  widgets/                     # shared UI: timeline, progress-ring painter
android/app/src/main/kotlin/.../widget/  # native Glance widget (Milestone 7)
```

Domain logic is kept Flutter-free specifically so the break-law/recalculation
algorithms are unit testable without a widget test harness — that's where
correctness actually matters (see the Requirements doc's worked examples).

## Documentation obligations (read this before touching the repo)

Two logs are kept current throughout the build, not written up after the fact:

1. **Obsidian project log** — a brief dated entry in
   `Study/Projects/TimeManager/TimeManager Log.md` after each milestone.
2. **`docs/build-log.html`** — a self-contained, two-part local HTML file:
   - Top = human-friendly story (screenshots, what led to what, problems and
     how they were solved) for Paul, updated at milestone/decision/bug
     boundaries.
   - Bottom = long-form technical log, appended after *every* small step
     (every file, every schema decision, every bug+fix) — the persistent
     technical memory between sessions.

   Append to it via the `<!-- STORY_ENTRIES_END -->` / `<!-- TECH_LOG_END -->`
   markers in the file; don't rewrite existing entries.

## Toolchain

Flutter 3.35.2 (stable), Dart 3.9.0, Android SDK 36.1.0-rc1 (licenses
accepted). AVDs: `Medium_Phone_API_36.0`, `flutter_emulator`. `kotlinc` isn't
on PATH — Milestone 7 relies on Android Studio's bundled Gradle/Kotlin
toolchain; verify at the start of that milestone.

## Git

This repo pushes to the personal `PaulWiench` GitHub account (default
`github.com` host, HTTPS) — the only account authenticated via `gh` on this
machine.
