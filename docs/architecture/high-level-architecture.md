# High Level Architecture
## Technical Summary
Claw and Snackle uses a modular Godot 4.5 architecture centered on scene composition and autoloaded service singletons. Typed GDScript powers every layer—from UI and orchestration through claw simulation, pooling, and analytics—reinforcing a single-language codebase that favors deterministic gameplay and rapid iteration. Core patterns include signal-driven messaging, Resource-based configuration, deterministic state machines, and autoload services for state, orders, audio, and settings. All work is validated via `scripts/godot-cli.sh --headless`, enforcing the GUT-driven TDD discipline and keeping the project export-ready.

## High Level Overview
1. **Node Architecture:** Scene composition governs the experience—`SessionRoot.tscn` instantiates claw cabinet, HUD, customer queue, and tutorial overlay as siblings for clean separation.
2. **Language Strategy:** Typed GDScript handles UI, state flow, services, physics orchestration, and analytics—no secondary language runtime is used.
3. **Repository Layout:** Single Godot project with `src/` for scenes and scripts, `resources/` for data and themes, and `tests/` for GUT suites.
4. **Systems:** Autoload singletons (`GameState`, `OrderService`, `SignalHub`, `Settings`, `AudioDirector`) coordinate gameplay, while resource-driven tables (orders, waves, customer profiles) keep tuning designer-friendly.
5. **Gameplay Loop:** Input → ClawRig solver → Grab/Release events → Order resolution → Score/life updates → Wave pacing, mediated by the signal hub to reduce coupling.
6. **Performance & TDD:** 60+ FPS target reinforced by pooling, solver tuning, and mandatory test execution through the CLI wrapper before merges.

## High Level Project Diagram
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

## Architectural and Design Patterns
- **Scene composition over deep inheritance** keeps systems modular and testable.
- **Signal-driven communication** via `SignalHub` autoload decouples systems (order updates, patience warnings, combo changes).
- **Resource-driven configuration** (orders, waves, claw tuning, audio mixes) lets designers iterate without code changes.
- **Object pooling** for seafood, particles, and debris prevents allocation spikes and sustains 60+ FPS.
- **Explicit state machines** govern game flow, claw behavior, tutorials, and HUD banners for predictable transitions and easy testing.
