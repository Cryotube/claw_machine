# Shader Guidelines
## Usage Patterns
- Godot shader language for freezer frost overlays, patience meter glows, and accessibility filters.
- Screen-space colorblind shaders toggled by `Settings` autoload.

## Performance Guidelines
- No branching in fragment shaders; prefer texture lookups.
- Precompute data in Resources and push via uniforms.
- Validate shader parameters through CLI-driven GUT tests where applicable.
