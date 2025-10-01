# Gameplay Systems Architecture
## Gameplay Overview
- **Session Flow:** `Boot → Title → Menu → {Tutorial | ScoreRun}`. Score runs iterate waves until lives reach zero, then transition to Game Over; tutorial completion flag stored in persistence.
- **Core Loop:** Inputs steer the claw, the solver validates grabs, and OrderService resolves success/failure with scoring, life adjustments, and wave pacing per PRD FR1–FR7.
- **Metrics:** GameState tracks score, combo, lives, wave index, and high score persistence (NFR4). Analytics stub logs key events for future insight.

## Gameplay Components
| Component | Description | Implementation Notes |
|-----------|-------------|----------------------|
| **Claw Rig** | 3D scene containing arm, grabber, cable joints, and soft-body seafood anchors | Driven by `ClawRigSolver` (typed GDScript); zero-allocation update loop; soft-body integration described below |
| **Order Lifecycle** | End-to-end management of cat requests and fulfillment outcomes | Resource-driven orders, patience curves, SignalHub events, UX-driven HUD cues |
| **Customer Queue** | Animated cat arrivals, patience display, reaction playback | Integrates with audio/haptics and wave pacing multipliers |
| **Wave Controller** | Config-driven scheduling of arrivals, patience, and cabinet clutter | `WaveConfig` resources authored via curves; designers tweak without code |
| **Tutorial Orchestrator** | Stepwise onboarding with fail recovery and orientation awareness | Resource-defined steps; interacts with HUD and input guidance |
| **Feedback Controller** | VFX/SFX/Haptics on success/failure, respecting UX “Feel the Claw” | Lightweight loops to maintain FPS |
