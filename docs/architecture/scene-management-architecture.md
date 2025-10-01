# Scene Management Architecture
## Scene Structure
- `SceneDirector` autoload handles additive scene loading, fade transitions, and asynchronous preloading.
- Scenes grouped by domain (`menu`, `session`, `tutorial`, `utility`) and sub-scenes instanced via exported PackedScene references for testability.

## Scene Loading System
- Preload next scene while fading out current to avoid mid-transition hitching.
- In-session transitions (wave summary) swap sub-scenes instead of reloading the entire scene tree.
- CLI smoke tests load critical scenes headless to prevent missing dependencies.
