# Test Strategy and Standards
## Testing Philosophy
- **Approach:** TDD (mandatory)  
- **Coverage Goal:** ≥80% for typed GDScript modules  
- **Frameworks:** GUT (GDScript), optional GodotTestDriver for UI  
- **Performance Tests:** Stress scenes must maintain 60+ FPS

## Godot Test Types and Organization
- **GDScript (GUT):** `res://tests/gut/` with `test_*.gd`. Focus on node interactions, Resource loading, and signal flows. Tests executed via CLI wrapper.
- **Optional UI Tests:** GodotTestDriver scripts validate HUD states and accessibility toggles when needed.

## Test Data Management
- Deterministic Resource fixtures (e.g., `test_wave_table.tres`, `test_order_catalog.tres`).
- Minimal test scenes for session smoke tests and claw stress profiles.
- Signal testing via spies; performance validation uses CLI headless runs capturing profiler stats.

## Playtest Cadence
- Schedule structured playtests every Friday with 30-minute guided sessions covering tutorial onboarding, mid-wave intensity, and accessibility toggles.
- Capture quantitative notes (mis-grab rate, average order completion time) alongside qualitative feedback; log results in `qa/playtest-notes.md`.
- Block release if successive playtests report >10 % failure rate on tutorial completion or if perceived input latency surpasses targets.
