# Game Systems & Components
## Core Systems
| System | Language | Responsibilities | Key Dependencies |
|--------|----------|------------------|------------------|
| `GameState` (autoload) | GDScript | Global run state, wave progression, life tracking, pause orchestration | `OrderService`, `SignalHub`, `Settings` |
| `OrderService` (autoload) | GDScript | Order queue lifecycle, patience curves, combo logic | `WaveConfig`, `CustomerQueue`, `SessionHUD` |
| `SignalHub` (autoload) | GDScript | Central event bus for cross-system messaging | All runtime systems |
| `ClawRigSolver` | GDScript | Inverse kinematics, cable tension, grip validation, soft-body anchoring | `CabinetItemPool`, `ClawState` |
| `ClawInputController` | GDScript | Input normalization, dead-zone handling, orientation adaptation | `VirtualJoystick`, `Settings` |
| `CabinetItemPool` | GDScript | Soft-body and rigid-body pooling, resource swaps for performance modes | `CabinetItemDescriptor` |
| `CustomerQueue` | GDScript | Cat spawn timing, animations, patience meter updates | `WaveConfig`, `AudioDirector` |
| `SessionHUD` | GDScript | HUD rendering, quick toggles, signal reactions | `Settings`, `OrderService`, `SignalHub` |
| `TutorialOrchestrator` | GDScript | Onboarding flow, step gating, hint triggers | `SessionHUD`, `ClawInputController` |
| `AccessibilityService` | GDScript | Colorblind filters, haptics, camera sensitivity updates | `SettingsProfile`, `SessionHUD` |
| `AudioDirector` | GDScript | Bus routing, dynamic mixing, haptics coordination | `AudioBus`, `SignalHub` |
| `AnalyticsStub` | GDScript | Buffered analytics events for future upload | `SignalHub`, file I/O |
| `ExportManager` | Bash + CLI | Headless test/export automation | `scripts/godot-cli.sh` |

## System Interaction (Session Core)
```
[InputMap]
   │  intents
   ▼
[ClawInputController] ──┐
                        │ grips
                        ▼
                 [ClawRigSolver]
                        │
                        ▼
                   [SignalHub]
            ┌─────────┴─────────┐
            ▼                   ▼
     [OrderService]       [SessionHUD]
            │                   │
            ▼                   ▼
    [CustomerQueue]     [AudioDirector]
```

## System Interaction (Wave Flow)
```
[GameState] → [OrderService] → [CustomerQueue]
      │              │               │
      │              └─wave events──►│
      │                               ▼
      └─life/score signals──►[SignalHub]──►[SessionHUD]
```

### Performance Budgets
- Active gameplay scene (SessionRoot) must stay under 1.4 GB on iOS / 1.6 GB on Android, tracked via `Performance` monitors with alerts in the debug HUD.
- Soft-body stress scene maintains ≥60 FPS; fallback to rigid-body mode when telemetry indicates prolonged spikes above 20 ms frame time.
