# State Machine Architecture
## Game State Machine
```
Boot → Title → Menu → {Tutorial | ScoreRun}
ScoreRun → WaveActive ↔ WaveSummary → GameOver → Menu
Tutorial → TutorialComplete → Menu
```
Pause overlays operate orthogonally. `GameState` autoload implements the finite-state machine with enum keys, handler dictionaries, and `state_changed` signals for HUD/audio subscribers.

## Entity State Machines
- **Customers:** `waiting → served → departing` or `waiting → impatient → failed` with GDScript mini state nodes per instance.
- **Claw Rig:** Typed GDScript FSM states (`Idle`, `Aiming`, `Descending`, `Gripping`, `Retracting`, `Carrying`, `Dropping`).
- **Tutorial:** Resource-defined step machine gating controls and repeating instructions after failures.
- **HUD Components:** `OrderBanner` states (`hidden`, `pending`, `warning`, `critical`, `fulfilled`) drive color and animation changes.
