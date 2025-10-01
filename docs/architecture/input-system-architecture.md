# Input System Architecture
## Input Actions Configuration
| Action | Type | Touch Binding | Gamepad Binding | Notes |
|--------|------|---------------|-----------------|-------|
| `claw_move` | Vector2 | Virtual joystick (bottom-left portrait, bottom-center landscape) | Left stick | Normalized vector forwarded to the GDScript solver |
| `claw_lower` | Digital | Hold grab button | South button | Initiates descent & grip warmup |
| `claw_grip` | Digital | Tap action button | East button | Clamps grip force, supports tap cadence |
| `claw_release` | Digital | Swipe up/drop zone proximity | West button | Releases item, auto-trigger near chute |
| `ui_pause` | Digital | Pause icon top-right | Start/Options | Pauses timers and opens overlay |
| `camera_pan` | Analog | Two-finger drag | Right stick | Damped per Settings sensitivity |
| `accessibility_toggle` | Digital | HUD quick toggles | D-pad shortcuts | Toggles haptics/colorblind mode |

## Input Handling Patterns
- `ClawInputController` centralizes `_unhandled_input`, translating gestures into InputMap events for parity across devices.
- Orientation changes emitted by `Settings` autoload reposition HUD controls within thumb reach as specified in the UX doc.
- Dead zones, smoothing, and aim assist logic implemented in GDScript before forwarding to the solver.
- Long-press detection triggers aim correction cues after repeated misses to support accessibility goals.
- Input recordings captured for deterministic regression tests executed through the CLI wrapper.
