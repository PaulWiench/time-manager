# TimeManager — Design System & Screen Specification

This is a **brief for a visual design pass**, not a finished design system. Every functional requirement below is fixed (it comes from the app's locked Requirements & Data Model docs); every purely *visual* decision — palette, type, spacing scale, motion, iconography — is deliberately left open, flagged in §7, for this document's next step: feeding it into a design tool to get the visual language right before any screen gets built.

Implementation (Flutter, Material 3 base) is otherwise complete through the data and business-logic layers. This document is the handoff point before screen code gets written.

---

## 1. Product Context

TimeManager is a **personal, solo-use** Android time-tracking app: log work sessions, get automatic German legal break deductions, track a running hour balance against a weekly target, and manage leave. Not commercial — no onboarding funnel to optimize, no engagement mechanics, no ads, no accounts. One person opens it several times a day for a few seconds each time (check in, check out, glance at balance) and occasionally longer (reviewing history, checking stats).

**Personality the design should convey:** calm, trustworthy, precise, fast-to-glance. This is closer in spirit to a well-made instrument (a good watch, a clean spreadsheet) than to a consumer/social app. It should feel modern and visually polished — that's an explicit product goal — without becoming showy or animation-heavy in a way that slows down a two-second glance at the balance number.

---

## 2. Design Direction Brief

Fixed constraints (from the UX doc):
- **Not monochrome** — one or two accent colors against a neutral base.
- **Dark and light mode**, following system default, both must feel equally considered (not one "real" theme with an inverted afterthought).
- **Modern, clean.**

Semantic color needs the palette must support (functional, not decorative):
- A **tracking** state, a **break** state, and a **checked-out/idle** state — distinct enough to read at a glance on the small widget ring, not just in the full app. These are the single most-glanced-at pixels in the whole product.
- A single **warning** treatment (Requirements is explicit: one "warning color," not a red/green dichotomy) applied to numbers already on screen — a balance past a configured floor/cap, vacation days past a configured threshold. Never a separate alert color system, never a banner or icon-badge language — just the number itself shifting into the warning treatment.
- A neutral treatment for **synthetic breaks** on the timeline that's visually distinct from **real breaks** and from **leave blocks** — three different block types that appear adjacent to each other on the same timeline and must be tellable apart without reading a label.

Open, for the design pass: exact seed color(s), exact neutral scale, whether the accent(s) shift between light/dark or stay constant, and how "warning" reads against both themes without borrowing red (which would imply a second semantic dimension the product doesn't have).

---

## 3. Platform & Technical Constraints

- **Flutter, Material 3** as the base widget toolkit — the design should work with (not fight) Material 3's component shapes and theming system (`ColorScheme`, `TextTheme`), since that's what gets implemented. A from-scratch bespoke design language is out of scope for a solo project.
- **Android-first**, phone form factors. No tablet/foldable-specific layout work planned for v1.
- **The home-screen widget is native Kotlin (Jetpack Glance), not Flutter** — its visual language (colors, the progress ring specifically) needs to be portable to Android's native widget APIs, which are more constrained than Flutter's canvas. Keep the ring/color-state design simple enough to render natively.
- **Charts**: `fl_chart` for standard shapes (line, bar), hand-rolled `CustomPainter` for the heatmap and progress rings. Whatever visual style is chosen for charts needs to be achievable in these two toolkits, not assume a charting library with more built-in styling options.
- Sideload-only distribution — no Play Store listing, no store-graphics requirements.

---

## 4. Navigation Structure

Bottom navigation, 4 items: **Home · History · Stats · Settings**.

History's Month/Week/Day modes are view-states inside the History tab, not separate nav destinations. Stats' three tabs (Overview/Patterns/Leave) are an in-screen tab bar, not bottom-nav items.

---

## 5. Screen-by-Screen Specification

For each screen: what's on it, its states, and its interaction rules. Visual treatment (spacing, exact component styling) is intentionally not specified here — that's the design pass's job.

### 5.1 Onboarding

First-launch only. A **4-step, cancelable wizard**, one field per step, each prefilled with a sensible default the user can accept or change:

1. Weekly hours (default 40)
2. Work days (default Mon–Fri)
3. Starting balance (default 0)
4. Auto-break enabled (default on)

- An **X** at any step cancels the wizard immediately: whatever steps were already confirmed are kept, the rest silently default, and the user drops straight to Home. No "are you sure" dialog.
- Not asked here at all, silently defaulted, editable later in Settings: vacation quota (30 days/year), minimum session length (5 min), restrict check-in (off).

**Design need:** a step indicator/progress marker that reads clearly at 4 steps, a per-step layout that comfortably holds one input + its default + an accept/skip affordance, and a cancel (X) that's discoverable but not confusable with "back."

### 5.2 Home

The daily-glance screen. Contains, top to bottom (order not prescribed):
- Vertical **timeline** of today's check-in/check-out events (shared component with History's expanded day view — see §6.1)
- **Running timer** on the active session (elapsed time since last check-in), if one is active
- **Progress bar** toward today's target
- **Today's total hours**
- **Today's surplus or remaining time**
- **Total running balance**

**Empty state** (before any check-in has ever happened today): a prompt (e.g. "No sessions yet today") replaces the timeline, with a large, primary **Check In** action. The progress bar still shows 0/target; the balance still shows the current running total (not zero).

**Design need:** this screen needs to work at a glance — the balance and today's-progress numbers are the two most-read pieces of information in the whole app and should have clear visual priority over the timeline detail below them.

### 5.3 History

**Navigation:** arrow-based stepping (±1 unit at whatever zoom level is active) plus a date picker for jumping directly to any date.

**View hierarchy — Month → Week → Day**, one consistent "list of rows, tap a row to zoom in" pattern at every level (tentative pending a mockup, per the UX doc — this hierarchy is the part most likely to get refined once there's something to look at):
- **Month mode:** scrollable list of month-summary rows (total hours, balance delta) → tap to drill into that month's Week mode
- **Week mode:** list of week-summary rows → tap to drill into that week's Day mode
- **Day mode:** the day-row list below

**Day row — collapsed:** date, net worked hours, balance delta for that day (e.g. "+0:45" / "−1:30"), a compact indicator for leave/holiday.

**Day row — expanded:** the same timeline component as Home, applied to that past date, plus the day-level `notes` field and any per-session `notes`.

**Break editing** (on the expanded timeline): synthetic breaks are shown as a visually distinct block from real breaks — never hidden, since the net-hours number otherwise wouldn't visibly account for the gap. Tap a synthetic break, then delete it to convert that time back to work time. **No confirmation dialog on delete** — this is a private, personal-use app, not something an employer audits. Deleting flags that day as break-deduction-overridden.

**Empty-day states**, visually distinguished by case:
- A **past scheduled workday with no entry** — flagged (e.g. red text/icon), since it's actively dragging the balance down.
- A **non-workday** (weekend/rest day) — neutral/blank.
- A **future date** — neutral, never flagged as missed.

**Design need:** three distinct empty-state treatments that read clearly in a dense list of day rows, and a "list of rows → tap to zoom in" pattern that stays visually consistent across all three zoom levels without feeling repetitive.

### 5.4 Stats

**Global time-range selector** (last week / month / 6 months / year / custom) applies to all charts except Leave, which is always year-scoped with its own separate year selector (ignores the global range — vacation quotas are inherently annual).

Three tabs, charts within each ranked by priority (order matters — most important chart first):

**Overview**
1. Balance trend over time (line chart) — cumulative hour balance across the selected range
2. Weekly target hit rate — how many weeks in range hit the weekly-hour target
3. Overtime accumulation rate — the *rate* the balance is growing/shrinking, distinct from the raw trend line above

**Patterns**
1. Monthly overview heatmap (GitHub-style) — color intensity = hours worked that day
2. Daily hours bar chart — one bar per day, net worked hours
3. Hours by day of week (bar chart, averaged)
4. Earliest/latest check-in patterns — distribution of check-in times

**Leave**
- Leave breakdown: vacation used vs. remaining (out of the configured quota), sick days taken. Year-scoped only, own year selector.

**Empty/insufficient-data state:** each chart independently shows a "not enough data yet" placeholder when there isn't enough in the selected range, rather than rendering a sparse or misleading chart.

**Design need:** this is the screen with the most distinct chart types (line, bar ×3, heatmap, distribution) — they need a shared visual language (a consistent "chart card" treatment) so the tab doesn't feel like six unrelated widgets glued together. The heatmap and the check-in-time distribution are the two chart types without an off-the-shelf `fl_chart` shape (hand-rolled via `CustomPainter`) — worth extra design attention since there's no library default to fall back on.

### 5.5 Settings

Not detailed screen-by-screen in the UX doc (this section is a functional inventory, structure is open):
- Weekly hours, work days, starting balance (editable versions of onboarding's fields)
- Auto-break enabled toggle, minimum session length, restrict check-in toggle + work-window definition
- Balance floor/cap/annual-reset configuration
- Vacation quota, rollover policy (indefinite / expire at year end / use-by deadline)
- Public holiday list (auto-loaded, user-editable — add/edit/remove)
- Notifications — all opt-in, all off by default: forgot to check in/out, unusually long session, break nudge, balance low/high, vacation quota low/expiring, daily/weekly summary
- Audit log entry point (a dedicated, buried location — "advanced" or developer-style section, not a main nav item)

**Design need:** this is the highest-information-density screen in the app (a dozen-plus distinct settings across several logical groups) — needs a clear grouping/section system, and specifically a treatment for the audit log entry point that reads as "advanced, rarely needed" without being literally hidden.

### 5.6 Home-Screen Widget (Android, native Kotlin + Glance)

Two sizes:
- **Compact (1×1):** a circular progress ring only, showing today's net hours toward the daily target. Ring color signals state: one accent while actively tracking, a different accent while on a break, neutral/gray when checked out. Single tap toggles check-in/out — no separate "open app" zone at this size.
- **Expanded (larger):** the same ring, plus numeric today's hours and the running total balance. Two tap zones: the ring/status icon toggles check-in/out, tapping elsewhere opens the app.

Refresh: periodic (once a minute) while a session is active — not a live-ticking per-second stopwatch.

**Design need:** the ring's 3-state color language (tracking/break/checked-out) has to be legible at genuinely small (1×1 launcher icon) size and implementable in native Android widget APIs — the single most constrained design surface in the product.

---

## 6. Component Inventory

Functional spec per component — what states/variants each needs to support. Visual treatment open.

### 6.1 Timeline (shared: Home + History expanded day view)
Renders a day's check-in/check-out events plus break/leave blocks in sequence. Block types that must be visually distinguishable from each other: **work session**, **real break**, **synthetic break**, **leave block**. Must support an active (in-progress, open-ended) session at the end. Tap to expand/collapse an entry; long-press to edit.

### 6.2 Progress ring
Circular, fillable progress indicator. Used on Home and both widget sizes. Needs 3 color states (tracking / break / checked-out) plus a neutral pre-first-check-in state.

### 6.3 Progress bar (linear)
Daily-target progress, Home screen. Simpler than the ring — likely just fill percentage, no multi-state color requirement beyond an optional warning treatment if over/under significantly.

### 6.4 Day row (History)
Collapsed and expanded variants (§5.3). Collapsed needs to comfortably fit: date, net hours, balance delta (signed), a small leave/holiday indicator, and one of the three empty-state treatments when applicable.

### 6.5 Balance number
Appears in multiple places (Home, History day rows, Stats trend chart). Needs a **default** and a **warning** treatment (the single warning color from §2), toggled once a configured floor/cap is crossed — never a separate icon or badge, the number itself changes.

### 6.6 Chart card
Wrapper used across all of Stats — needs to accommodate a line chart, a bar chart, a heatmap, and a distribution chart consistently, plus an internal "not enough data" empty state that replaces the chart body without breaking the card's layout.

### 6.7 Heatmap (custom-painted)
GitHub-style calendar grid, color intensity = hours worked. No off-the-shelf shape — needs its own color-intensity scale (likely derived from the accent color, not a separate palette).

### 6.8 Onboarding step
One field, its default value, and an accept/change affordance, plus a step indicator and a cancel (X). Needs to read clearly as step *n* of 4 without feeling like a form wizard from an enterprise app.

### 6.9 Settings section/row
Grouped list rows covering toggles, numeric inputs, and navigation-to-detail rows (e.g. "Public Holidays →"). Needs a distinct "advanced/buried" treatment for the audit log entry point specifically.

### 6.10 Time-range selector
Segmented control or similar: week / month / 6 months / year / custom, used globally in Stats. A second, separate instance (year-only) needed for the Leave tab.

### 6.11 Empty-state placeholder
Three distinct variants needed: (a) Home's pre-first-check-in prompt with a primary CTA, (b) History's three empty-day treatments (missed/non-workday/future), (c) Stats' per-chart "not enough data" placeholder. These are functionally different enough that they may not share a single component, but should share a visual *language*.

---

## 7. Open Questions for the Design Pass

Everything above is fixed. These are not:

1. **Palette** — seed color(s) for the accent(s), full light/dark neutral scales, and the warning-color treatment that reads clearly without implying "error" in a red-associated way.
2. **Typography** — font family (system default vs. a chosen typeface) and type scale, with particular attention to the balance number (needs to read clearly at a glance, likely the largest/boldest text in the app) and dense list text (History day rows, Settings).
3. **Spacing/grid system** — a consistent spacing scale across screens of very different density (Home's sparse glance-screen vs. Settings' dense list).
4. **Elevation & surface treatment** — how cards (chart cards, day rows) separate from the background in both themes; Material 3's default elevation system is a reasonable starting point but not mandated.
5. **Motion** — transition style for tab switches, History's zoom-in drill navigation, and the timeline's tap-to-expand/collapse. Should stay fast and unobtrusive given how often this app is opened for a two-second glance.
6. **Iconography** — a consistent icon set/style across bottom nav, settings rows, and the widget.
7. **The ring & heatmap's exact rendering** — since both are hand-painted (not library defaults), their precise visual treatment (stroke width, corner treatment, color-intensity curve) needs explicit direction rather than inheriting from a component library.
