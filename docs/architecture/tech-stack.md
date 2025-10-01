# Tech Stack
## Platform Infrastructure
- Godot 4.5 Forward+ renderer with mobile fallback presets.
- `scripts/godot-cli.sh` wrapper proxies the Godot 4.5 binary with project path preconfigured for consistent `--headless` test/export execution.
- Git + Git LFS for large binaries; hooks can invoke the wrapper to block commits without passing tests.
- Local Bash scripts and future CI (GitHub Actions) rely on the same wrapper for parity.
- Target platforms: iOS (Metal) and Android (Vulkan with GLES fallback), both supporting portrait/landscape UX.

## Technology Stack Table
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

## Developer Process
- Always execute headless Godot test runs through the wrapper: `./scripts/godot-cli.sh --headless --run tests/gut`. This guarantees consistent project paths and aligns with CI expectations.
- On any crash, freeze, or non-zero exit, inspect the terminal output for parse/compiler errors and resolve them before retrying. Do not assume the failure is a runtime issue until syntax errors are cleared.
- Re-run the wrapper command after fixes to confirm the project loads and tests execute cleanly, then proceed with profiling or additional validation.
