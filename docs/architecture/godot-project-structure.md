# Godot Project Structure
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

## Repository Conventions
- `.gitignore` extends the official Godot template: ignore `.godot/`, `*.import`, generated `build/` exports, and `*/.godot/editor_settings-3.tres` artifacts.
- Track `editor_settings-override.tres` under `config/` with agreed snapping/grid/theme preferences; contributors copy it into their local Godot config so gizmos and formatting stay aligned.
- Shell helpers belong in `scripts/`—automation and developers call `scripts/godot-cli.sh` so tests/exports never bypass our headless validation.
- `resources/` is the shared asset library (meshes, materials, VFX, UI scenes); integrate existing assets from here during implementation instead of leaving placeholder anchors.
