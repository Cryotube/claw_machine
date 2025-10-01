# Requirements

## Functional
1. FR1: Cat patrons arrive at the service counter in timed intervals, announce their seafood order, and display a patience meter.
2. FR2: Requested seafood types are visualized both at the counter UI and inside the freezer cabinet so players can identify the matching item before operating the claw.
3. FR3: Players control a physics-driven claw rig inside the freezer to grab individual seafood items, including extending, aiming, lowering, and gripping actions.
4. FR4: Delivering the correct seafood to the waiting cat fulfills the order, awards score, and resets the service station for the next customer.
5. FR5: Failing to deliver an order before the patience meter expires deducts one life, triggers a short fail animation, and queues the next cat.
6. FR6: Difficulty ramps by adjusting cat arrival frequency, patience duration, and claw cabinet clutter as the session progresses, with explicit wave pacing rules for vertical slice tuning.
7. FR7: The game tracks remaining lives, cumulative score, and high score; reaching zero lives ends the run with a game-over screen.
8. FR8: Provide an onboarding tutorial that teaches touch controls, claw operation, and order flow before the full score-chase loop begins.
9. FR9: Implement a touch-friendly HUD with large tap targets, visual haptic cues, and pause/resume support tailored for portrait and landscape orientations.

## Non Functional
1. NFR1: Maintain 60 FPS on mid-range mobile hardware (e.g., iPhone 12, Pixel 6, 6 GB RAM) during typical gameplay scenarios.
2. NFR2: Support touch-first controls with optional gamepad compatibility, ensuring average perceived input latency ≤ 50 ms (p95 ≤ 70 ms) measured via in-game telemetry.
3. NFR3: Provide clear audio-visual and haptic feedback for order status (incoming, fulfilled, failed) that is readable at 720p-equivalent mobile resolutions.
4. NFR4: Persist local high scores and session statistics between runs without requiring online connectivity.
5. NFR5: Provide adjustable camera sensitivity and basic accessibility toggles (subtitles for meows, colorblind-friendly order indicators, toggleable haptics).
6. NFR6: Utilize a low-poly cel-shaded art direction with optimized shader passes, LODs, and occlusion culling tuned for mobile performance.
7. NFR7: Keep total install size under 500 MB and manage memory use below 1.4 GB (iOS) / 1.6 GB (Android) during peak gameplay to avoid thermal throttling and OS restarts.
8. NFR8: Hit load-time targets—boot-to-menu ≤ 3 s, menu-to-session ≤ 2 s, and wave transitions ≤ 1 s—using async preload and scene streaming.
9. NFR9: Maintain a 15-minute session battery drop under 6% and device temperature under 40 °C on reference hardware by dynamically throttling particle density and solver fidelity.

## Monetization & Analytics
- MVP launches without monetization; no IAP or ads are included until retention metrics validate demand.
- Analytics events include gameplay progression plus frame time, memory, and battery telemetry per wave so future monetization decisions align with performance realities.
- Any future monetization concepts must preserve the cozy restaurant fantasy and pass an ethics review before being added to backlog.

## Localization & Accessibility Pipeline
- English and Japanese shipping at MVP; localization spreadsheet exports to `res://resources/i18n/strings.csv` with automated validation in CI.
- Accessibility toggles (colorblind palettes, haptic mute, camera sensitivity) must be reachable within two taps from pause and persist across sessions.

## MVP Scope
- **Core Features:** Tutorial onboarding, score-run loop with escalating waves, physics-driven claw cabinet, accessibility toggles, analytics logging, and local persistence.
- **Deferred (Nice-to-have):** Multiplayer, seasonal events, cosmetic shop, streaming overlays, additional languages beyond JP, and live-ops events.
- **Content Minimums:** Three cabinet biomes, ten seafood item variants, six cat personas, and at least three music layers supporting intensity modulation.
- **Technical Guardrails:** Maintain SemVer build numbering, enforce TDD coverage ≥80%, and block release if telemetry exceeds latency or battery thresholds.
