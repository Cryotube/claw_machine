# Particle System Architecture
## Design
- `ParticleSystem3D` resources for claw sparkles, freezer breath, and cat reactions stored under `res://resources/vfx/` so gameplay code can drop in the shipped effects rather than placeholder nodes.
- Emission triggered via `SignalHub` events to keep systems decoupled.

## Performance
- Particle counts capped at ≤200 per effect, with pooled emitters reused.
- Texture sheet animations baked during import.
- CLI stress scene ensures particle-heavy moments remain within frame budget.
