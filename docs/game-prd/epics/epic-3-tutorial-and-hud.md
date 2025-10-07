# Epic 3: Tutorial Onboarding, HUD, and Accessibility

## Goal
Deliver a polished first-time user experience with guided claw training, adaptive HUD layouts, and accessibility toggles so new players can master controls on mobile hardware.

## Description
- Addresses FR8 and FR9 for tutorial onboarding and touch-friendly HUD support, plus NFR1–NFR5 accessibility and performance expectations (docs/game-prd/requirements.md).
- Leverages `TutorialOrchestrator`, HUD component architecture, and input adaptation strategies documented for Godot (docs/architecture/game-systems-components.md; docs/architecture/ui-component-system.md; docs/architecture/input-system-architecture.md).
- Ensures Control node anchoring, localization hooks, and platform toggles follow UI architecture and accessibility guidance (docs/architecture/ui-architecture.md; docs/architecture/performance-and-security-considerations.md).

### Outcomes
- Interactive tutorial sequences gate player progression until each claw mechanic is demonstrated successfully.
- HUD adapts to portrait/landscape layouts, exposing large tap targets and quick toggles for haptics and colorblind filters.
- Accessibility options persist between sessions and integrate with audio/haptic systems without violating performance targets.

## Stories
1. **Story 3.1 – Tutorial Flow & Input Gating:** Script tutorial steps, lock controls until objectives met, and log completion flag in persistence.
2. **Story 3.2 – Responsive HUD & Pause Overlay:** Implement HUD canvas layer with thumb-friendly controls, pause menu, and orientation adjustments.
3. **Story 3.3 – Accessibility Toggles & Localization Hooks:** Wire colorblind palettes, haptic toggle, camera sensitivity slider, and string localization pipeline.
4. **Story 3.4 – SceneDirector & Navigation Shell:** Build title/menu/pause/options/records scenes, drive transitions through SceneDirector, and emit analytics events.

## Dependencies & Constraints
- Requires Epic 1 loop completion to demonstrate actual gameplay interactions.
- Depends on persistence, settings profiles, and localization assets defined in architecture (docs/architecture/game-data-models.md; docs/architecture/ui-component-system.md).
- Must respect performance budgets and maintain 60 FPS even with overlays active.

## Definition of Done
- Tutorial completion tracked and replayable, with analytics instrumentation for onboarding drop-off.
- HUD/UI assets responsive and accessible, validated through manual scenarios and automated UI tests where feasible.
- Accessibility toggles and localization updates persist across sessions and devices.

## Risks & Mitigations
- **Tutorial fatigue:** Provide skip option once completion flag set, per UX guidelines.
- **HUD clutter on small devices:** Use orientation adapters and safe-area presets to maintain readability.
- **Localization regressions:** Enforce CSV validator in CI and include fallback strings to avoid runtime crashes.
