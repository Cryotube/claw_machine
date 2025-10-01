# Coding Standards
## Core Standards
- Follow project development guidelines: static typing everywhere, no per-frame allocations, and no direct `load()` in gameplay.
- Keep comments concise, focusing on architectural rationale.

## Godot Naming Conventions
- Scenes use PascalCase (`SessionHUD.tscn`), script files snake_case, classes PascalCase, and signals snake_case.

## Critical Godot Rules
- Always preload resources, rely on pooling for dynamic objects, profile before merging, and run CLI headless tests plus exports before PR submission.

## Godot-Specific Guidelines
- `_ready` handles dependency binding; `_physics_process` drives the solver; `_process` avoided unless required.
- Cache nodes, avoid per-frame string ops, prefer `PackedVector3Array` for physics data.
