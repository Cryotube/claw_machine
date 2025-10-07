# Claw and Snackle Game Architecture Document

## Introduction
Claw and Snackle is architected as a Godot 4.5 project that balances believable claw-machine physics with mobile-first responsiveness. This document establishes the technical foundation for AI-driven development, enforcing Test-Driven Development (TDD), a 60+ FPS target on iPhone 12/Pixel 6 class devices, and a pure typed GDScript strategy tuned to the project’s performance needs.

### Starter Template or Existing Project
No starter template or legacy project will be used. We will initialize a fresh Godot 4.5 project configured with the Forward+ renderer (with mobile fallback), mobile export presets, and our own scene hierarchy. The repository exposes `scripts/godot-cli.sh`, a wrapper that proxies the installed Godot 4.5 binary with the project path preconfigured so every development agent can run `--headless` tests and exports inside the repo. Autoload singletons, InputMap actions, and TDD tooling (GUT with optional GodotTestDriver) will be configured during setup to keep iteration fast while guaranteeing the required performance envelope.

### Change Log
| Date       | Version | Description                                                      | Author |
|------------|---------|------------------------------------------------------------------|--------|
| 2025-10-01 | v0.1    | Initial architecture draft aligned to PRD/UX and Godot 4.5 toolchain requirements. | Dan (Game Architect) |

## High Level Architecture
### Technical Summary
Claw and Snackle uses a modular Godot 4.5 architecture centered on scene composition and autoloaded service singletons. Typed GDScript powers every layer—from UI and orchestration through claw simulation, pooling, and analytics—reinforcing a single-language codebase that favors deterministic gameplay and rapid iteration. Core patterns include signal-driven messaging, Resource-based configuration, deterministic state machines, and autoload services for state, orders, audio, and settings. All work is validated via `scripts/godot-cli.sh --headless`, enforcing the GUT-driven TDD discipline and keeping the project export-ready.

### High Level Overview
1. **Node Architecture:** Scene composition governs the experience—`SessionRoot.tscn` instantiates claw cabinet, HUD, customer queue, and tutorial overlay as siblings for clean separation.
2. **Language Strategy:** Typed GDScript handles UI, state flow, services, physics orchestration, and analytics—no secondary language runtime is used.
3. **Repository Layout:** Single Godot project with `src/` for scenes and scripts, `resources/` for data and themes, and `tests/` for GUT suites.
4. **Systems:** Autoload singletons (`GameState`, `OrderService`, `SignalHub`, `Settings`, `AudioDirector`) coordinate gameplay, while resource-driven tables (orders, waves, customer profiles) keep tuning designer-friendly.
5. **Gameplay Loop:** Input → ClawRig solver → Grab/Release events → Order resolution → Score/life updates → Wave pacing, mediated by the signal hub to reduce coupling.
6. **Performance & TDD:** 60+ FPS target reinforced by pooling, solver tuning, and mandatory test execution through the CLI wrapper before merges.

### High Level Project Diagram
```
res://
├── main/Main.tscn
├── scenes/
│   ├── session/
│   │   ├── SessionRoot.tscn
│   │   ├── ClawCabinet.tscn
│   │   ├── CustomerQueue.tscn
│   │   └── HUD/
│   │       ├── SessionHUD.tscn
│   │       └── TutorialOverlay.tscn
│   ├── menu/
│   │   ├── TitleScreen.tscn
│   │   └── OptionsMenu.tscn
│   └── utility/
│       ├── CameraRig.tscn
│       └── PoolSpawner.tscn
├── autoload/
│   ├── GameState.gd
│   ├── OrderService.gd
│   ├── SignalHub.gd
│   └── Settings.gd
├── scripts/
│   ├── gameplay/
│   ├── services/
│   └── ui/
├── resources/
│   ├── data/
│   ├── curves/
│   └── themes/
└── tests/
    └── gut/
```

### Architectural and Design Patterns
- **Scene composition over deep inheritance** keeps systems modular and testable.
- **Signal-driven communication** via `SignalHub` autoload decouples systems (order updates, patience warnings, combo changes).
- **Resource-driven configuration** (orders, waves, claw tuning, audio mixes) lets designers iterate without code changes.
- **Object pooling** for seafood, particles, and debris prevents allocation spikes and sustains 60+ FPS.
- **Explicit state machines** govern game flow, claw behavior, tutorials, and HUD banners for predictable transitions and easy testing.

## Tech Stack
### Platform Infrastructure
- Godot 4.5 Forward+ renderer with mobile fallback presets.
- `scripts/godot-cli.sh` wrapper proxies the Godot 4.5 binary with project path preconfigured for consistent `--headless` test/export execution.
- Git + Git LFS for large binaries; hooks can invoke the wrapper to block commits without passing tests.
- Local Bash scripts and future CI (GitHub Actions) rely on the same wrapper for parity.
- Target platforms: iOS (Metal) and Android (Vulkan with GLES fallback), both supporting portrait/landscape UX.

### Technology Stack Table
| Layer | Technology | Purpose | Notes |
|-------|------------|---------|-------|
| Engine | Godot 4.5 | Core runtime, scene/tree management | Forward+ renderer, mobile exports configured |
| Scripting (UI/Logic) | Typed GDScript | HUD, state orchestration, services | Static typing enforced, signals cached |
| Scripting (Simulation) | Typed GDScript | Claw solver, pooling, analytics stub | Deterministic loops, avoids allocations |
| Testing | GUT, GodotTestDriver (opt) | Unit/integration, UI automation | Run via CLI wrapper `--headless` |
| Automation | Bash + `scripts/godot-cli.sh` | Tests, exports, lint hooks | Single entry point for developers & CI |
| Assets | GLB models, Texture2D atlases, AudioStream resources | Visual/audio pipeline | Atlased textures, mipmaps per platform |
| Persistence | ConfigFile, JSON resources | Save data & settings | AES-256 encryption + HMAC |
| Analytics | GDScript stub logging locally | Future-proof instrumentation | Thread-safe queue writes to `user://analytics.log` |

## Game Data Models
1. **OrderDefinition (Resource)** – `id`, `seafood_type`, `prep_style`, `base_score`, `decay_curve`, `tutorial_hint`.
2. **WaveConfig (Resource)** – `wave_id`, `spawn_schedule`, `max_concurrent_cats`, `patience_multiplier`, `cabinet_clutter_level`.
3. **CustomerProfile (Resource)** – `species`, `entry_animation`, `patience_base`, `favorite_orders`, `voice_bank`.
4. **ClawState (GDScript class)** – `position`, `velocity`, `cable_tension`, `gripping`, `grip_force`, `grabbed_item_id`.
5. **CabinetItemDescriptor (Resource)** – `item_id`, `mesh`, `mass`, `grip_threshold`, `pool_size`, `soft_body_config`.
6. **SettingsProfile (ConfigFile/Resource)** – `colorblind_mode`, `haptics_enabled`, `camera_sensitivity`, `audio_mix`.

Resources live under `res://resources/` with validation helpers to guarantee designer edits remain consistent. Test fixtures mirror these resources inside `res://tests/fixtures/` for deterministic TDD.

## Game Systems & Components
### Core Systems
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

### System Interaction (Session Core)
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

### System Interaction (Wave Flow)
```
[GameState] → [OrderService] → [CustomerQueue]
      │              │               │
      │              └─wave events──►│
      │                               ▼
      └─life/score signals──►[SignalHub]──►[SessionHUD]
```

## Gameplay Systems Architecture
### Gameplay Overview
- **Session Flow:** `Boot → Title → Menu → {Tutorial | ScoreRun}`. Score runs iterate waves until lives reach zero, then transition to Game Over; tutorial completion flag stored in persistence.
- **Core Loop:** Inputs steer the claw, the solver validates grabs, and OrderService resolves success/failure with scoring, life adjustments, and wave pacing per PRD FR1–FR7.
- **Metrics:** GameState tracks score, combo, lives, wave index, and high score persistence (NFR4). Analytics stub logs key events for future insight.

### Gameplay Components
| Component | Description | Implementation Notes |
|-----------|-------------|----------------------|
| **Claw Rig** | 3D scene containing arm, grabber, cable joints, and soft-body seafood anchors | Driven by `ClawRigSolver` (typed GDScript); zero-allocation update loop; soft-body integration described below |
| **Order Lifecycle** | End-to-end management of cat requests and fulfillment outcomes | Resource-driven orders, patience curves, SignalHub events, UX-driven HUD cues |
| **Customer Queue** | Animated cat arrivals, patience display, reaction playback | Integrates with audio/haptics and wave pacing multipliers |
| **Wave Controller** | Config-driven scheduling of arrivals, patience, and cabinet clutter | `WaveConfig` resources authored via curves; designers tweak without code |
| **Tutorial Orchestrator** | Stepwise onboarding with fail recovery and orientation awareness | Resource-defined steps; interacts with HUD and input guidance |
| **Feedback Controller** | VFX/SFX/Haptics on success/failure, respecting UX “Feel the Claw” | Lightweight loops to maintain FPS |

## Node Architecture Details
### Node Patterns
- Scene composition instantiates feature scenes as children of `SessionRoot`, allowing isolated testing.
- Autoloads handle global services; dependencies injected via exported references instead of `get_node()` calls.
- Orientation adapters manage portrait/landscape layout changes per UX spec.
- Pool managers remain resident and emit instanced nodes on demand, avoiding runtime `PackedScene.instantiate()` overheads.

### Resource Architecture
- Config resources (orders, waves, claw tuning, audio mixes) stored under `res://resources/data/` with validation methods.
- Themes (`base_theme.tres` + overrides) match UX Control hierarchies.
- Curve resources drive patience depletion and claw damping.
- Localization-ready string tables set up for future expansion.
- Test fixtures mimic production resources in `res://tests/fixtures/`.

## Physics Configuration
### Physics Settings
- `physics/common/physics_ticks_per_second = 60` to align with FPS target.
- Global gravity `Vector3(0, -9.81, 0)`; an interior `Area3D` applies a −20% gravity modifier for freezer viscosity.
- Continuous collision detection enabled on claw gripper, seafood soft bodies, and anchor points.
- Soft-body iteration count set to 15 to prevent jitter while remaining mobile-friendly.
- Solver iterations set to 16 for stable articulated joints interacting with soft bodies.

### Rigidbody & Soft-Body Patterns
- **Claw Rig:** Articulated via `Generic6DOFJoint3D` with preconfigured limits controlled by the typed GDScript solver; no runtime joint mutation.
- **Grabbable Seafood:** Implemented as `SoftBody3D` meshes (rounded cube, sphere, rounded pyramid, rounded cylinder variations) with pinned vertices allowing gentle deformation when gripped. Collision proxies use `ConcavePolygonShape3D` for accurate contact tests. Solver transitions items to kinematic attachment when grabbed, preserving deformation until release.
- **Fallback Mode:** Settings toggle can swap in pooled rigid bodies for low-end devices, handled by `CabinetItemPool`.
- **Cabinet Debris:** Pooled `RigidBody3D` nodes forced to sleep off-camera to conserve CPU.

## Input System Architecture
### Input Actions Configuration
| Action | Type | Touch Binding | Gamepad Binding | Notes |
|--------|------|---------------|-----------------|-------|
| `claw_move` | Vector2 | Virtual joystick (bottom-left portrait, bottom-center landscape) | Left stick | Normalized vector forwarded to the GDScript solver |
| `claw_lower` | Digital | Hold grab button | South button | Initiates descent & grip warmup |
| `claw_grip` | Digital | Tap action button | East button | Clamps grip force, supports tap cadence |
| `claw_release` | Digital | Swipe up/drop zone proximity | West button | Releases item, auto-trigger near chute |
| `ui_pause` | Digital | Pause icon top-right | Start/Options | Pauses timers and opens overlay |
| `camera_pan` | Analog | Two-finger drag | Right stick | Damped per Settings sensitivity |
| `accessibility_toggle` | Digital | HUD quick toggles | D-pad shortcuts | Toggles haptics/colorblind mode |

### Input Handling Patterns
- `ClawInputController` centralizes `_unhandled_input`, translating gestures into InputMap events for parity across devices.
- Orientation changes emitted by `Settings` autoload reposition HUD controls within thumb reach as specified in the UX doc.
- Dead zones, smoothing, and aim assist logic implemented in GDScript before forwarding to the solver.
- Long-press detection triggers aim correction cues after repeated misses to support accessibility goals.
- Input recordings captured for deterministic regression tests executed through the CLI wrapper.

## State Machine Architecture
### Game State Machine
```
Boot → Title → Menu → {Tutorial | ScoreRun}
ScoreRun → WaveActive ↔ WaveSummary → GameOver → Menu
Tutorial → TutorialComplete → Menu
```
Pause overlays operate orthogonally. `GameState` autoload implements the finite-state machine with enum keys, handler dictionaries, and `state_changed` signals for HUD/audio subscribers.

### Entity State Machines
- **Customers:** `waiting → served → departing` or `waiting → impatient → failed` with GDScript mini state nodes per instance.
- **Claw Rig:** Typed GDScript FSM states (`Idle`, `Aiming`, `Descending`, `Gripping`, `Retracting`, `Carrying`, `Dropping`).
- **Tutorial:** Resource-defined step machine gating controls and repeating instructions after failures.
- **HUD Components:** `OrderBanner` states (`hidden`, `pending`, `warning`, `critical`, `fulfilled`) drive color and animation changes.

## UI Architecture
### UI System Selection
- Godot Control nodes with typed GDScript logic; no external UI frameworks.
- `UIManager` autoload coordinates theme swaps, orientation adjustments, and quick toggles.
- Animations handled via `AnimationPlayer` resources to stay performant.

### UI Navigation System
- Main menu uses stacked buttons sized for thumb reach with focus hints for controllers.
- In-session HUD sits on a dedicated `CanvasLayer` to avoid interfering with 3D content.
- Pause overlay uses a centered card with safe-area padding and accessible focus traversal.

## UI Component System
### Component Library
- `OrderBanner.tscn`, `PatienceMeter.tscn`, `VirtualJoystick.tscn`, `QuickToggle.tscn`, and `WaveSummaryCard.tscn` live under `res://ui/components/` today, tracked within the `/resources` asset library; hook up these shipped scenes instead of placeholders while migration to `res://resources/scenes/ui/components/` is underway.
- Components emit domain signals consumed by services via `SignalHub`.

### Data Binding
- Signal-based binding with typed DTOs from `OrderService` to `SessionHUD` avoids fragile string lookups.
- `Settings` autoload emits structured changes consumed by interested components to update colors, haptics, and layouts live.

## UI State Management
- HUD uses `StateController` scripts with enums to transition component states explicitly.
- Quick toggles maintain local state mirrored to `SettingsProfile` for persistence.
- `ModalStack` service ensures only the topmost overlay handles input.

## Scene Management Architecture
### Scene Structure
- `SceneDirector` autoload handles additive scene loading, fade transitions, and asynchronous preloading.
- Scenes grouped by domain (`menu`, `session`, `tutorial`, `utility`) and sub-scenes instanced via exported PackedScene references for testability.

### Scene Loading System
- Preload next scene while fading out current to avoid mid-transition hitching.
- In-session transitions (wave summary) swap sub-scenes instead of reloading the entire scene tree.
- CLI smoke tests load critical scenes headless to prevent missing dependencies.

## Data Persistence Architecture
### Save Data Structure
- `user://claw_and_snackle/save_v1.dat` encrypted file storing `high_scores`, `settings`, and `tutorial_completed` data.
- JSON payload encrypted with AES-256 CBC; HMAC-SHA256 appended for tamper detection.

### Persistence Strategy
- `PersistenceService` autoload writes via worker thread to avoid frame stalls.
- Saves triggered on wave completion and settings changes with debounce timers.
- Schema versioned with migration helpers for future updates.

## Save System Implementation
- API: `PersistenceService.save_game(GameSnapshot snapshot)` / `load_game()` returning optional snapshot.
- Backup copy maintained; load failure emits `save_corrupted` signal prompting UX notification and fallback to defaults.

## Analytics Integration
### Event Design
| Event ID | Trigger | Payload |
|----------|---------|---------|
| `order_fulfilled` | Successful delivery | `wave`, `combo`, `time_remaining`, `fish_type` |
| `order_failed` | Patience expiry or wrong item | `wave`, `reason`, `fish_type` |
| `tutorial_step_completed` | Completing a tutorial step | `step_id`, `duration` |
| `toggle_accessibility` | Changing a quick toggle | `setting`, `value`, `context` |
| `menu_nav` | Menu action selected | `source`, `action`, `timestamp_ms` |
| `game_over_shown` | Game over screen displayed | `score`, `wave`, `failure_reason`, `duration_sec`, `auto`, `timestamp_ms` |
| `practice_result` | Practice cabinet result | `result`, `descriptor_id`, `remaining_time`, `normalized_remaining`, `timestamp_ms` |
| `options_adjusted` | Slider/button change in options | `setting`, `value`, `tab`, `timestamp_ms` |

### Implementation
- `AnalyticsStub` GDScript singleton queues events and writes JSONL to `user://analytics.log` on flush; ready for future network uploader.
- Thread-safe queue allows headless execution without blocking gameplay.

## Multiplayer Architecture
Multiplayer is out of scope for the MVP. This section documents the decision so future contributors do not introduce networking complexities prematurely.

## Rendering Pipeline Configuration
### Render Pipeline Setup
- Forward+ renderer with SMAA fallback for low-end devices.
- Static GI baked for freezer cabinet; dynamic lighting limited to key/fill lights within session scene.
- Texture import presets enforce ASTC (primary) and ETC2 fallback, with anisotropic filtering capped at 4×.

### Rendering Optimization
- LODs configured for cat patrons and claw machinery; `VisibleOnScreenNotifier3D` disables off-screen clutter updates.
- HUD consolidated into a single `CanvasLayer` with atlas textures to minimise draw calls.
- Soft-body seafood meshes capped under ~500 vertices with simplified materials.

## Shader Guidelines
### Usage Patterns
- Godot shader language for freezer frost overlays, patience meter glows, and accessibility filters.
- Screen-space colorblind shaders toggled by `Settings` autoload.

### Performance Guidelines
- No branching in fragment shaders; prefer texture lookups.
- Precompute data in Resources and push via uniforms.
- Validate shader parameters through CLI-driven GUT tests where applicable.

## Sprite Management
### Organization
- Textures live under the shared `res://resources/` tree (for example `res://resources/textures/`) grouped by HUD, characters, and FX so feature branches can wire real atlases over placeholder anchors.
- Atlases generated with Godot importer; naming convention `hud_atlas_*` for clarity.

### Optimization
- Mobile builds use lossy compression (~0.7 quality) and mipmaps.
- Animated sprites converted to `SpriteFrames` resources to minimize runtime work.

## Particle System Architecture
### Design
- `ParticleSystem3D` resources for claw sparkles, freezer breath, and cat reactions stored under `res://resources/vfx/` so systems drop in the shipped effects rather than empty nodes.
- Emission triggered via `SignalHub` events to keep systems decoupled.

### Performance
- Particle counts capped at ≤200 per effect, with pooled emitters reused.
- Texture sheet animations baked during import.
- CLI stress scene ensures particle-heavy moments remain within frame budget.

## Audio Architecture
### System Design
- AudioServer bus layout: `Master → {Music, SFX, VO, UI, Haptics}`. `AudioDirector` autoload manages routing and snapshots.
- Haptics integrated via platform-specific stubs (CoreHaptics on iOS, vibration service on Android).
- Audio assets live under `res://resources/audio/`; wire these banks directly so features play the shipped sounds instead of silent placeholders.

### Categories
| Category | Examples | Notes |
|----------|----------|-------|
| Music | Calm lobby, escalating wave music | Crossfaded based on wave intensity |
| SFX | Claw motor, grip clamp, seafood squish | Duck under VO when necessary |
| VO/Meows | Cat reactions, penguin tips | 3D positional audio near counter |
| UI | Button taps, toggle clicks | Respect accessibility volume preferences |
| Haptics | Grab feedback, patience warnings | Adjustable via quick toggles |

## Audio Mixing Configuration
### Mixer Setup
- Bus compressors/limiters tuned for mobile speakers.
- Exported `AudioMixProfile` resources define mixes for Tutorial, Calm Wave, Intense Wave states.

### Dynamic Mixing
- `AudioDirector` listens to SignalHub events (`patience_warning`, `wave_complete`) to adjust bus gains.
- Sidechain compression dips music when VO plays.
- Haptic intensity scaled with wave difficulty and accessibility settings.

## Sound Bank Management
### Asset Organization
- Assets live under `res://resources/audio/` (categorised by `music/`, `sfx/`, `vo/`, `ui/`) with metadata stored in `SoundBank.tres` to make the shipped banks available during implementation.

### Streaming Strategy
- Music streamed from OGG; SFX preloaded into memory.
- Streaming progress monitored to avoid stutters; export tests ensure required assets are packaged.

## Godot Development Conventions
### Best Practices
- Typed GDScript for all scripts; avoid runtime `get_node()` inside hot loops.
- Cache dependencies via exported references or `onready` variables.
- Connect signals in code with `Callable` references for clarity and diffability.

### Workflow Conventions
- All development agents run `scripts/godot-cli.sh --headless --path . --test` before commits.
- Scene transitions go through `SceneDirector` to avoid duplicated logic.
- Soft-body tuning tools reside under `addons/softbody_tuner/` for consistent adjustments.

## External Integrations
No external SDKs or services are integrated in the MVP. This explicit note prevents accidental scope creep.

## Core Game Workflows
1. **Feature Development** – Write GUT tests first, implement feature, run `scripts/godot-cli.sh --headless --path . --test`, and optional `--check-scenes` smoke tests.
2. **Content Updates** – Designers adjust Resource assets, export new `.tres`, and rerun headless tests to ensure serialization integrity.
3. **Export Validation** – Use wrapper for `--export-release` commands (e.g., `scripts/godot-cli.sh --headless --export-release ios ios_export.pck`). Same commands will be used in CI.
4. **Performance Profiling** – Launch the profiler, record baselines, and commit snapshots; run soft-body stress scene headless to confirm frame timing stays under 16.6 ms.

## Godot Project Structure
```
project.godot
scripts/
  godot-cli.sh
  build-export.sh
src/
  scenes/
  autoload/
  gameplay/
  services/
  ui/
resources/
  data/
  themes/
  curves/
  audio/
addons/
  softbody_tuner/
tests/
  gut/
    unit/
    integration/
docs/
  prd.md
  front-end-spec.md
  architecture.md
```

## Infrastructure and Deployment
### Godot Build Configuration
- Wrapper script ensures all CLI commands pass `--path .` and other required flags.
- Export presets capture iOS/Android credentials; secrets injected via environment variables.

### Deployment Strategy
- MVP uses manual local exports validated via wrapper.
- Future GitHub Actions workflow will call the same script for tests and exports, uploading artifacts for QA.

### Environments
- `dev` (debug overlays), `release` (optimized), and `profiling` (instrumented) build configurations toggled through feature flags.

### Platform-Specific Settings
- iOS: Metal renderer, 60 FPS cap, CoreHaptics entitlements, mobile-safe icon set.
- Android: Vulkan primary, GLES3 fallback, adaptive icons, vibration permission gating.
- Wrapper ensures `--feature mobile` is enabled for mobile builds.

## Coding Standards
### Core Standards
- Follow project development guidelines: static typing everywhere, no per-frame allocations, and no direct `load()` in gameplay.
- Keep comments concise, focusing on architectural rationale.

### Godot Naming Conventions
- Scenes use PascalCase (`SessionHUD.tscn`), script files snake_case, classes PascalCase, and signals snake_case.

### Critical Godot Rules
- Always preload resources, rely on pooling for dynamic objects, profile before merging, and run CLI headless tests plus exports before PR submission.

### Godot-Specific Guidelines
- `_ready` handles dependency binding; `_physics_process` drives the solver; `_process` avoided unless required.
- Cache nodes, avoid per-frame string ops, prefer `PackedVector3Array` for physics data.

## Test Strategy and Standards
### Testing Philosophy
- **Approach:** TDD (mandatory)  
- **Coverage Goal:** ≥80% for typed GDScript modules  
- **Frameworks:** GUT (GDScript), optional GodotTestDriver for UI  
- **Performance Tests:** Stress scenes must maintain 60+ FPS

### Godot Test Types and Organization
- **GDScript (GUT):** `res://tests/gut/` with `test_*.gd`. Focus on node interactions, Resource loading, and signal flows. Tests executed via CLI wrapper.
- **Optional UI Tests:** GodotTestDriver scripts validate HUD states and accessibility toggles when needed.

### Test Data Management
- Deterministic Resource fixtures (e.g., `test_wave_table.tres`, `test_order_catalog.tres`).
- Minimal test scenes for session smoke tests and claw stress profiles.
- Signal testing via spies; performance validation uses CLI headless runs capturing profiler stats.

## Performance and Security Considerations
### Save Data Security
- **Encryption:** AES-256 CBC with device-based key derivation (PBKDF2) and per-file salt.
- **Validation:** HMAC-SHA256 to detect tampering.
- **Anti-Tampering:** Versioned payload with checksum fallback; on failure, revert to backup.

### Platform Security Requirements
- Mobile permissions limited to haptics/vibration and storage; prompt only when needed.
- Comply with App Store / Play Store privacy rules; document offline-only analytics stub.
- Provide privacy policy covering encrypted saves and local analytics logs.

### Multiplayer Security
- Not applicable for MVP; documented to avoid accidental scope creep.

## Checklist Results Report
_Architecture checklist has not yet been executed. Run `*execute-checklist game-architect-checklist` after review to populate this section._

## Next Steps
1. Review the architecture with game design and UX stakeholders for alignment.
2. Initialize the Godot 4.5 project, configure autoloads, InputMap, Resources, and commit `scripts/godot-cli.sh`.
3. Run baseline headless tests (`scripts/godot-cli.sh --headless --path . --test`) to validate tooling.
4. Coordinate with the Game Scrum Master to seed implementation stories based on this document.

### Game Developer Prompt
> Implement approved stories referencing `docs/architecture.md`. Use typed GDScript for every subsystem—from UI and orchestration through claw control, pooling, and analytics—and keep scripts in the shared `src/` namespace. Follow TDD strictly: author GUT coverage first, then run `scripts/godot-cli.sh --headless --path . --test` and the necessary export commands. Maintain the 60+ FPS target by honoring pooling, soft-body solver constraints, and autoload patterns. Update the story’s Dev Agent Record and ensure all HUD accessibility toggles remain responsive.
