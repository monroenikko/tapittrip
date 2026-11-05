---
name: flutter-premium-ui
description: Design, build, or review TapItTrip Flutter screens and widgets using the brand colors (navy primary, orange secondary), Material 3 theme tokens, accessibility, and loading/empty/error/offline states. Use for any UI work under client/lib.
---

# TapItTrip Flutter UI

Use this skill for any Flutter UI task in `client/`: new screens, widgets, theming, or UI reviews.
For state, repositories, and offline sync, also follow the root skill `tapittrip-flutter-mobile`.

## 1. Before coding
- Read `pubspec.yaml`, the current theme, routing, and a nearby screen. Match existing patterns.
- Do not add packages without explaining why and getting approval.
- Stay inside the approved milestone (`docs/milestone-log.md`).

## 2. Brand colors (always use these)
| Role | Name | Hex | Use for |
| --- | --- | --- | --- |
| **Primary** | TapIt Navy | `#00376D` | App bars, primary buttons, headings, selected nav items |
| **Secondary** | Trip Orange | `#F76405` | Accents, map pins, highlights, FAB, badges |
| Tertiary | Sky Blue | `#0166BE` | Links, info states, secondary emphasis |

- Full palette, dark mode values, contrast rules, and a copy-paste `ThemeData`: [`references/brand-colors.md`](references/brand-colors.md).
- Logo reference: [`assets/tapittrip-logo.jpg`](assets/tapittrip-logo.jpg).
- Read colors from `Theme.of(context).colorScheme` — **never hard-code hex values in widgets**.
- Navy leads, orange accents. Roughly 60% neutral surface / 30% navy / 10% orange.
- White text on orange fails contrast for normal text. Put dark text (`onSecondary`) on orange fills; use `#B84A00` for orange text on white.

## 3. Build rules
- Material 3 with a single app theme (`ThemeData` + `ColorScheme` + `TextTheme`). Support light and dark.
- Spacing scale: 4, 8, 12, 16, 24, 32. Radius scale: 8, 12, 16. No other values without reason.
- Keep it clean: no purple, no glassmorphism, no heavy shadows, no decorative gradients in UI chrome (the logo gradient is for brand art only).
- Content first. Use cards only when grouping helps.
- Small widgets, `const` where possible, lazy lists for long data. No business logic in `build`.
- Respect `SafeArea`, keyboard, and text scaling. Never fix heights around text.
- Layout by width (`LayoutBuilder`), not by device model.

## 4. Every screen needs
- Loading, empty, error (with retry), and offline/stale states.
- Semantic labels on icons/images, 48×48 dp minimum touch targets, 4.5:1 text contrast.
- Localized strings — no hard-coded user-facing text.
- Works for travelers with no itinerary (no forced setup flows).

## 5. Workflow
1. State the screen goal and the states it needs.
2. Implement using theme tokens only.
3. Check: small phone, large text (200%), dark mode, keyboard open.
4. Add widget tests for key states and interactions.
5. From `client/`: run `dart format .`, `flutter analyze`, `flutter test`. Report real results only.

Review checklist: [`references/design-review.md`](references/design-review.md). Prompt examples: [`references/example-prompt.md`](references/example-prompt.md).
