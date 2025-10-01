# Audio Architecture
## System Design
- AudioServer bus layout: `Master → {Music, SFX, VO, UI, Haptics}`. `AudioDirector` autoload manages routing and snapshots.
- Haptics integrated via platform-specific stubs (CoreHaptics on iOS, vibration service on Android).
- Audio assets live under `res://resources/audio/`; integrate these banks directly so shipped effects replace temporary anchors during implementation.

## Categories
| Category | Examples | Notes |
|----------|----------|-------|
| Music | Calm lobby, escalating wave music | Crossfaded based on wave intensity |
| SFX | Claw motor, grip clamp, seafood squish | Duck under VO when necessary |
| VO/Meows | Cat reactions, penguin tips | 3D positional audio near counter |
| UI | Button taps, toggle clicks | Respect accessibility volume preferences |
| Haptics | Grab feedback, patience warnings | Adjustable via quick toggles |
