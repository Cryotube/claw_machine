# Introduction
Claw and Snackle is architected as a Godot 4.5 project that balances believable claw-machine physics with mobile-first responsiveness. This document establishes the technical foundation for AI-driven development, enforcing Test-Driven Development (TDD), a 60+ FPS target on iPhone 12/Pixel 6 class devices, and a pure typed GDScript strategy tuned to the project’s performance needs.

## Starter Template or Existing Project
No starter template or legacy project will be used. We will initialize a fresh Godot 4.5 project configured with the Forward+ renderer (with mobile fallback), mobile export presets, and our own scene hierarchy. The repository exposes `scripts/godot-cli.sh`, a wrapper that proxies the installed Godot 4.5 binary with the project path preconfigured so every development agent can run `--headless` tests and exports inside the repo. Autoload singletons, InputMap actions, and TDD tooling (GUT with optional GodotTestDriver) will be configured during setup to keep iteration fast while guaranteeing the required performance envelope.

## Change Log
| Date       | Version | Description                                                      | Author |
|------------|---------|------------------------------------------------------------------|--------|
| 2025-10-01 | v0.1    | Initial architecture draft aligned to PRD/UX and Godot 4.5 toolchain requirements. | Dan (Game Architect) |
