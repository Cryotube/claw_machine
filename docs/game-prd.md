# Claw and Snackle Godot Product Requirements Document (PRD)

## Goals and Background Context

### Goals
- Deliver a charming 3D claw-machine-meets-restaurant experience where players embody a penguin chef serving feline patrons.
- Provide a session-based order fulfillment loop with gradually rising pressure so casual players can practice claw skills without steep skill spikes.
- Simulate believable claw machine physics inside the freezer cabinet to satisfy players seeking realistic UFO catcher gameplay at home or on the go.
- Establish a replayable score-chasing structure that tracks accuracy and timing while reinforcing service-speed mastery.
- Launch on iOS and Android with responsive touch-first controls while sustaining 60 FPS on mid-range mobile hardware.

### Background Context
Claw and Snackle is a casual restaurant management game that blends Overcooked-inspired customer flow with the tactile thrill of operating a claw machine. Players act as a penguin proprietor who must pull the requested seafood from a frozen claw cabinet before each cat patron loses patience. The freezer showcases visible fish and shellfish encased in ice blocks, turning every order into a skill-based claw challenge.

The game targets claw machine and UFO catcher enthusiasts who want a faithful physics-driven experience on mobile (iOS and Android) while still enjoying cozy restaurant vibes. No comparable 3D claw machine title currently exists, creating a clear differentiation opportunity. Success for the MVP is defined by delivering a polished vertical slice where players chase high scores across escalating difficulty, losing lives when orders expire.

### Change Log
| Date       | Version | Description                                                                 | Author        |
|------------|---------|-------------------------------------------------------------------------------|---------------|
| 2025-09-30 | v0.3    | Refined requirements for mobile UI, pacing, performance, and accessibility. | John (Game PM) |
| 2025-09-30 | v0.2    | Updated goals/background for mobile release and art/performance targets.     | John (Game PM) |
| 2025-09-30 | v0.1    | Initial PRD draft seeded with project brief details.                         | John (Game PM) |

## Requirements

### Functional
1. FR1: Cat patrons arrive at the service counter in timed intervals, announce their seafood order, and display a patience meter.
2. FR2: Requested seafood types are visualized both at the counter UI and inside the freezer cabinet so players can identify the matching item before operating the claw.
3. FR3: Players control a physics-driven claw rig inside the freezer to grab individual seafood items, including extending, aiming, lowering, and gripping actions.
4. FR4: Delivering the correct seafood to the waiting cat fulfills the order, awards score, and resets the service station for the next customer.
5. FR5: Failing to deliver an order before the patience meter expires deducts one life, triggers a short fail animation, and queues the next cat.
6. FR6: Difficulty ramps by adjusting cat arrival frequency, patience duration, and claw cabinet clutter as the session progresses, with explicit wave pacing rules for vertical slice tuning.
7. FR7: The game tracks remaining lives, cumulative score, and high score; reaching zero lives ends the run with a game-over screen.
8. FR8: Provide an onboarding tutorial that teaches touch controls, claw operation, and order flow before the full score-chase loop begins.
9. FR9: Implement a touch-friendly HUD with large tap targets, visual haptic cues, and pause/resume support tailored for portrait and landscape orientations.

### Non Functional
1. NFR1: Maintain 60 FPS on mid-range mobile hardware (e.g., iPhone 12, Pixel 6, 6 GB RAM) during typical gameplay scenarios.
2. NFR2: Support touch-first controls with optional gamepad compatibility, ensuring perceived input latency under 100 ms.
3. NFR3: Provide clear audio-visual and haptic feedback for order status (incoming, fulfilled, failed) that is readable at 720p-equivalent mobile resolutions.
4. NFR4: Persist local high scores and session statistics between runs without requiring online connectivity.
5. NFR5: Provide adjustable camera sensitivity and basic accessibility toggles (subtitles for meows, colorblind-friendly order indicators, toggleable haptics).
6. NFR6: Utilize a low-poly cel-shaded art direction with optimized shader passes and LODs to balance aesthetics with mobile performance.
7. NFR7: Keep total install size under 500 MB and manage memory use below 2 GB during peak gameplay to avoid thermal throttling and OS restarts.
