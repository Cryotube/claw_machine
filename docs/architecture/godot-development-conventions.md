# Godot Development Conventions
## Best Practices
- Typed GDScript for all scripts; avoid runtime `get_node()` inside hot loops.
- Cache dependencies via exported references or `onready` variables.
- Connect signals in code with `Callable` references for clarity and diffability.

## Workflow Conventions
- All development agents run `scripts/godot-cli.sh --headless --path . --test` before commits.
- Scene transitions go through `SceneDirector` to avoid duplicated logic.
- Soft-body tuning tools reside under `addons/softbody_tuner/` for consistent adjustments.
