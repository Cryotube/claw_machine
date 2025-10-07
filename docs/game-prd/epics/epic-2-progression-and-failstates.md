# Epic 2: Failure Handling & Progression Scaling

## Goal
Introduce the systems that escalate difficulty across waves, enforce failure consequences, and track run statistics so the vertical slice feels complete and replayable.

## Description
- Covers FR5–FR7 for patience expiry penalties, wave pacing rules, and score/life management (docs/game-prd/requirements.md).
- Builds on `GameState`, `OrderService`, and `WaveConfig` resource orchestration defined in the architecture to deliver deterministic scaling (docs/architecture/game-systems-components.md; docs/architecture/game-data-models.md).
- Integrates analytics stubs and performance telemetry to maintain 60 FPS while difficulty increases (docs/architecture/performance-and-security-considerations.md).

### Outcomes
- Lives decrement, failure animations, and queue resets execute without desyncing HUD or audio.
- Wave controller adjusts arrival cadence, patience multipliers, and cabinet clutter via Resource-driven curves.
- Score/high score persistence works across sessions with encrypted saves targeting NFR4.

## Stories
1. **Story 2.1 – Patience Failure Consequences:** Trigger failure animations, deduct lives, and emit haptic/audio cues when timers expire.
2. **Story 2.2 – Wave Pacing & Difficulty Scaling:** Apply `WaveConfig` curves to spawn rates, patience multipliers, and clutter pools while profiling frame time.
3. **Story 2.3 – Score Tracking & Persistence:** Record score, combo, and high score metrics, persisting runs via encrypted saves and analytics events.
4. **Story 2.4 – Audio & Haptics Polish:** Configure audio buses, event table, and haptic feedback so successes, failures, and navigation feel responsive and accessible.

## Dependencies & Constraints
- Relies on Epic 1 systems for base order loop and signal plumbing.
- Requires `GameState` FSM hooks (docs/architecture/state-machine-architecture.md) and persistence pipeline (docs/architecture/data-persistence-architecture.md; docs/architecture/save-system-implementation.md).
- Telemetry must respect battery and thermal budgets while logging key wave metrics.

## Definition of Done
- Wave sessions exhibit measurable ramp without frame time spikes above 20 ms (docs/architecture/performance-and-security-considerations.md).
- Failure cases cleanly reset the cabinet, queue, and HUD without orphaned nodes or leaked resources.
- Persistence validated through automated tests and manual QA scenarios.

## Risks & Mitigations
- **Difficulty spikes:** Tune resource curves iteratively with designer feedback.
- **Persistence corruption:** Follow dual-write backup plan in save-system architecture.
- **Telemetry overhead:** Batch analytics writes asynchronously via C# stub queue.
