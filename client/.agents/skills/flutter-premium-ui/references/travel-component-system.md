# TapItTrip Travel Component Design System

This document specifies the exact component patterns, layouts, and widget styling for TapItTrip mobile screens, derived from the approved travel companion design system.

All components use TapItTrip's brand palette (TapIt Navy `#00376D` as primary, Trip Orange `#F76405` as secondary accent, Sky Blue `#0166BE` as tertiary info) reading strictly from `Theme.of(context).colorScheme`.

---

## 1. Palette Mapping from Design Mockups

| Mockup Element | Role in TapItTrip | Color Token | Hex / Value |
| --- | --- | --- | --- |
| **Dark green fills** (CTA, top bar, active pill) | Primary brand action & structure | `colorScheme.primary` | `#00376D` (TapIt Navy) |
| **Green badge / active highlight** | Status, progress & attention | `colorScheme.secondary` | `#F76405` (Trip Orange) |
| **Info chips, weather & route lines** | Secondary links & info states | `colorScheme.tertiary` | `#0166BE` (Sky Blue) |
| **Background canvas** | Soft, airy travel canvas | `colorScheme.surface` | `#F7F9FC` (light) / `#121417` (dark) |
| **Card fills & dialogs** | Elevated neutral container | `colorScheme.surface` | White `#FFFFFF` with `outlineVariant` border |
| **Quick Action / Chip fills** | Subtle container fill | `surfaceContainerHighest` | `0.3` to `0.5` opacity |

---

## 2. Core Travel Components

### 2.1 Hero & Search Pill Bar
- **Header**: Editorial typography (`headlineMedium` with serif or soft bold weight), subtitle in `bodyMedium` (`colorScheme.onSurfaceVariant`).
- **Floating Search Pill**:
  - Height: `52-56 dp`, `BorderRadius.circular(28)` (Stadium shape).
  - Background: `colorScheme.surface` with `outlineVariant` border and subtle shadow (`elevation: 1` or `BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))`).
  - Leading search icon (`Icons.search`), trailing circular icon button (`40x40 dp`) filled with `colorScheme.primary` and white icon (voice or filter).

### 2.2 Inspiring Destination Cards (Horizontal Carousel)
- **Dimensions**: `130-150 dp` width, `170-190 dp` height.
- **Border Radius**: `BorderRadius.circular(16)`.
- **Visuals**: Full-bleed cover photo with a bottom linear gradient overlay (`Colors.transparent` to `Colors.black.withOpacity(0.7)`).
- **Text Overlay**: Destination name (`bodyMedium` bold, white) and country subtitle (`labelSmall`, white/70% opacity) positioned in the bottom left, accompanied by a subtle arrow circle badge.

### 2.3 Quick Action Squircles
- **Container**: `BorderRadius.circular(16)`, aspect ratio roughly 1:1 (`72x72 dp` to `80x80 dp`).
- **Background**: `colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)`.
- **Content**: Centered duotone or outline icon (`28 dp`) in `colorScheme.primary`, with `labelSmall` text below (`AI Itinerary`, `Smart Route`, `Budget Plan`, `Travel Guide`).
- **Touch Target**: Full card tap target with ripple.

### 2.4 Trip Header & Attendee Pile
- **Destination Title**: `titleLarge` bold, accompanied by an inline edit pencil icon button.
- **Duration Metadata**: Pill badge or text (`bodySmall`) showing `X Days • Y Nights • Date Range`.
- **Avatar Stack**: Overlapping circular avatars (`28-32 dp` diameter, `-8 dp` margin) showing travelers, ending in a `+N` overflow chip.
- **Destination Thumbnail**: Rounded image (`BorderRadius.circular(12)`, `56x56 dp` to `64x64 dp`) on the right.

### 2.5 Route Optimization & Metric Cards
- **Header**: Rounded badge with checkmark: "AI Route Optimized".
- **Path Graphic**: Dotted line between origin and destination stops.
- **Metric Chips Row**:
  - Distance chip (`142 km`), Cost chip (`$1,240`), Impact/CO2 chip (`18 kg`).
  - Container: `BorderRadius.circular(10)` with outline border, small icon, and bold stat.

### 2.6 Segmented Pill Filter Tabs
- **Layout**: Horizontal scrollable list of stadium pills (`BorderRadius.circular(20)`).
- **Selected Tab**:
  - Background: `colorScheme.primary` (TapIt Navy).
  - Text: `colorScheme.onPrimary` (White, `labelMedium` bold).
- **Unselected Tab**:
  - Background: Transparent or `surfaceContainerLow`.
  - Border: `1 dp` `colorScheme.outlineVariant`.
  - Text: `colorScheme.onSurfaceVariant`.

### 2.7 Timeline & Day Activity List
- **Timeline Indicator**:
  - Circle badge (`32x32 dp`) filled with `colorScheme.primary` (or outline for uncompleted), white text showing `Day 1`, `Day 2`, `Day 3`.
  - Connected by a continuous vertical connector line (`2 dp` width, `colorScheme.outlineVariant`).
- **Activity Card**:
  - `BorderRadius.circular(14)`, subtle border.
  - Left icon indicating activity type (✈ flight, 🏨 hotel, 🏛 attraction, 🍽 dining, 🏝 nature).
  - Title: `titleSmall` bold.
  - Bulleted highlights: `• Airport Pickup • Hotel Check-in • Sunset View` in `bodySmall`.
  - Right: Activity thumbnail photo (`48x48 dp`, `BorderRadius.circular(8)`).
- **Add Activity Button**: Outlined or dashed row with `+ Add Activity` centered.

### 2.8 Boarding Pass & Travel Booking Cards
- **Two-Segment Ticket Design**:
  - **Header Band**: Top rounded corners (`BorderRadius.vertical(top: Radius.circular(16))`), filled with `colorScheme.primary`. Contains "BOARDING PASS" text in white and live status badge ("On Time ✈") filled with `colorScheme.secondary` (Trip Orange) or `onPrimaryContainer`.
  - **Body Section**: Bottom rounded corners (`BorderRadius.vertical(bottom: Radius.circular(16))`), white/surface fill, subtle circular notches/perforations between header and body.
  - **Flight Route**: Departure airport code (`CGK`) with time/date ➔ Airplane icon with duration (`2h 10m`) ➔ Arrival airport code (`DPS`) with time/date.
  - **Details Row**: Flight number, Gate, Seat, and scannable QR Code on the right.

### 2.9 Hotel & Stay Card
- Horizontal card (`BorderRadius.circular(14)`).
- Left: Stay thumbnail photo (`60x60 dp`, `BorderRadius.circular(10)`).
- Middle: Label ("Hotel" / "Airbnb"), Name ("Kayon Resort Ubud"), stay dates and nights.
- Right: Navigation chevron.

### 2.10 Dashboard Stat Widgets (2-Column Grid)
- **Weather Widget**:
  - Temperature display (`26°` bold), condition label ("Partly Cloudy"), weather icon.
- **Trip Progress Widget**:
  - Circular progress ring (`colorScheme.secondary` Trip Orange, stroke width `4-6 dp`).
  - Centered percentage text (`87%`).
  - Label below: "Completed".
- **Packing Checklist Widget**:
  - Header: "Packing Checklist", count `7 of 10 packed`.
  - Linear progress bar in `colorScheme.primary` / `colorScheme.secondary`.
  - Checked item list with custom checkmark indicators.

### 2.11 Floating Action CTAs & Bottom Navigation
- **Floating Main CTA**:
  - Stadium pill button (`BorderRadius.circular(28)`, height `52-56 dp`).
  - Background: `colorScheme.primary` (TapIt Navy).
  - Text & Icon: White `onPrimary`, e.g. "✨ Optimize with AI" or "⬇ View E-Ticket".
  - Position: Sticky bottom over surface with subtle drop shadow.
- **Bottom Navigation Bar**:
  - 4 destination tabs: `Home`, `Itinerary`, `Bookings`, `Profile`.
  - Active tab: Highlighted with `colorScheme.primary` icon + label.
  - Inactive tab: `colorScheme.onSurfaceVariant`.
  - Background: `colorScheme.surface` with subtle top hairline border.

---

## 3. Implementation Rules for Flutter Widgets

1. **Tokens Only**: Never hard-code hex colors or arbitrary pixel values in widget trees. Read all colors from `Theme.of(context).colorScheme`.
2. **Spacing & Radii**:
   - Radii: `8` (inner badges/chips), `12` (sub-cards & thumbnails), `16` (standard cards & dialogs), `28` (stadium search and CTA buttons).
   - Spacing: `4`, `8`, `12`, `16`, `24`, `32`.
3. **Contrast & Accessibility**:
   - Primary buttons: White text on TapIt Navy `#00376D` (11.9:1 ratio).
   - Secondary badges: Dark text `#1F1000` on Trip Orange `#F76405` (6.0:1 ratio).
   - Touch targets: Minimum `48x48 dp` for buttons, pills, and tapable cards.
4. **Offline & Empty States**:
   - Every list, carousel, and widget must provide an offline/cached presentation, a clean loading shimmer/indicator, and an inviting empty state without forcing unnecessary itinerary creation.
