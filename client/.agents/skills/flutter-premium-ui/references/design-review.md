# TapItTrip Flutter UI review checklist

Mark each item ✅ / ⚠️ / ❌ and fix every ❌ before finishing.

1. **Brand** — Navy primary, orange secondary, colors read from `colorScheme` (no hex in widgets).
2. **Hierarchy** — One clear primary action; one orange focal point; readable headings.
3. **Tokens** — Spacing 4/8/12/16/24/32, radius 8/12/16, `TextTheme` styles only.
4. **States** — Loading, empty, error + retry, offline/stale.
5. **Accessibility** — 4.5:1 contrast, semantic labels, 48 dp targets, works at 200% text.
6. **Layout** — No overflow on small phones, keyboard open, or tablets; dark mode correct.
7. **Simplicity** — No forced itinerary, no deep flows, no decorative gradients/shadows.
8. **Verified** — Widget tests added; `dart format`, `flutter analyze`, `flutter test` actually run.

Report what was verified and what remains untested.
