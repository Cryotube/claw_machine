# Phase 1 UX Alignment – Screen Refresh Brief

## Overview
This brief translates the front-end spec into implementation-ready requirements for the Title, Main Menu, Pause, Options, Records, and Game Over experiences. It is the handoff artifact for the Game Developer to replace current placeholder layouts while preserving mobile performance targets and accessibility goals.

All screens follow these shared rules:
- Respect safe areas via `Settings.get_safe_padding(is_portrait)` for portrait and landscape.
- Minimum hit target is 56 px square; primary CTAs are 64 px.
- Typography uses the base cozy theme with high-contrast palettes that meet WCAG AA on both ENG/JA strings.
- Animations must disable gracefully when reduced motion is enabled.

## Title Screen (`ui/screens/title_screen.tscn`)
- **Hero Composition:** Full-bleed background illustration (penguin & claw vignette) with a slow panning parallax (≤24 fps). Include a 1.5 s logo shimmer that pauses when reduced motion is enabled.
- **Primary CTA Stack:** Replaces linear buttons with a centered tile strip:
  - `Start Score Run` (primary gradient tile, occupies 70% width portrait / 45% width landscape).
  - `Tutorial`, `Practice`, `Options`, `Records` as compact tiles under the hero CTA.
- **Utility Row:** Bottom-left build label, bottom-right locale toggle icon button with flag/avatar glyph.
- **Input Hooks:** Entire screen accepts `ui_accept` to start; analytics event `menu_nav` emitted with `{source: "title", action: "start"}` or respective tile action.

## Main Menu (`ui/screens/main_menu.tscn`)
- **Tile Grid:** 2×3 layout in portrait, horizontal carousel (5 items) in landscape. Each tile includes icon + label + short blurb. Tile order:
  1. Start Score Run (primary)
  2. Tutorial
  3. Practice Cabinet
  4. Options
  5. Records
- **State Feedback:** Tiles glow on focus and show subtle “breathing” scale animation (disabled in reduced motion). Locked states (e.g., Practice WIP) display ribbon.
- **Safe-Area Anchoring:** Grid sits within 8% horizontal inset portrait, 12% landscape.
- **Analytics:** Every selection emits `menu_nav` with `{source: "main_menu", action: <tile_id>}` before transition.

## Pause Overlay (`ui/screens/pause_overlay.tscn`)
- **Structure:** Center card with Resume, Restart, Options, Quit buttons; quick-toggle toolbar anchored along bottom edge (haptics, colorblind palette cycle, sensitivity preset). Toolbar buttons use toggle states with icon + label chips.
- **Behavior:** Opening pause calls `SceneDirector.lock_input(true)` and dims session canvas to 35% opacity. Closing releases lock. Add 180 ms ease-in fade (skip when reduced motion).
- **Accessibility:** First focus target = Resume; quick toggles accessible via shoulder buttons on controllers.
- **Analytics:** Quick toggles publish `toggle_accessibility` with `{setting: <id>, value: <bool/int>, context: "pause"}`.

## Options Hub (`ui/screens/options_screen.tscn`)
- **Tabbed Layout:** Three tabs across top (Controls, Audio, Accessibility); swipeable on touch, `ui_left/right` for controller. Persist active tab in metadata.
- **Controls Tab:** Camera sensitivity slider (0.5–2.0), invert X/Y toggles, tutorial reset button (`Settings.mark_tutorial_complete(false)` workflow). Includes live joystick preview.
- **Audio Tab:** Master/Music/SFX sliders (0–1.0), mute toggle; updates `AudioDirector` buses immediately; haptic strength slider (0–1.0) for future tactile tuning.
- **Accessibility Tab:** Reduced motion toggle, colorblind palette dropdown with live preview, subtitle toggle, caption text-size slider (S/M/L). Subtitle toggle persists via `PersistenceService`.
- **Persistence:** Each change queues save through `PersistenceService` (debounced). Reduced motion + palette already persist; extend to all others.
- **Analytics:** Each adjustment fires `toggle_accessibility` or `options_adjusted` with `{setting, value, source: <tab>}`.

## Records Screen (`ui/screens/records_screen.tscn`)
- **Summary Card:** Displays High Score, Best Wave, Fastest Order Time, Last Run Delta. Each metric uses icon + label pair.
- **History Panel:** Scroll list of last 10 runs pulled from persistence (date/time localized via `LocalizationService`). Each row: wave, score, fail reason badge, time survived.
- **Call to Action:** Primary `Play Again`, secondary `Share Highlight` (stub event). Auto-focus primary CTA.
- **Empty State:** Friendly illustration + prompt to “Start your first shift” when no local history.
- **Analytics:** Viewing emits `screen_view` metadata with `entry_reason`; CTA logs `menu_nav` (`records_play_again`, `records_share`).

## Game Over (`ui/screens/game_over_screen.tscn`)
- **Hero Layout:** Large cat reaction art, summary score card, combo peak, lives lost, run duration.
- **Auto-Advance:** 6 s countdown chip; progress ring animates unless reduced motion set. On expiry, transition to Records with metadata `{"entry": "auto"}`.
- **Controls:** Continue button, plus share icon button. Continue triggers `menu_nav` (`game_over_continue`) and transitions to Records.
- **Analytics:** Emit `game_over_shown` on entry with `{score, wave, failure_reason, duration_ms}`; when auto-advancing, include `{"auto": true}`.

## Asset & Theme Notes
- Tile icons sourced from `resources/ui/menu_icons/`. Add new hero/background textures to `resources/ui/backgrounds/`.
- Update `ui/themes/cozy_theme.tres` with tile styles, toolbar chips, and tabbed panel theme variants.
- Ensure all new UI text keys exist in localization CSV (`resources/i18n/ui_screens.csv`) with ENG/JA strings.
