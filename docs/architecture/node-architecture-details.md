# Node Architecture Details
## Node Patterns
- Scene composition instantiates feature scenes as children of `SessionRoot`, allowing isolated testing.
- Autoloads handle global services; dependencies injected via exported references instead of `get_node()` calls.
- Orientation adapters manage portrait/landscape layout changes per UX spec.
- Pool managers remain resident and emit instanced nodes on demand, avoiding runtime `PackedScene.instantiate()` overheads.

## Resource Architecture
- Config resources (orders, waves, claw tuning, audio mixes) stored under `res://resources/data/` with validation methods.
- Themes (`base_theme.tres` + overrides) match UX Control hierarchies.
- Curve resources drive patience depletion and claw damping.
- Localization-ready string tables set up for future expansion.
- Test fixtures mimic production resources in `res://tests/fixtures/`.
- Texture imports standardised via presets: ASTC 6×6 for 3D assets, ETC2 fallback, mipmaps enabled, srgb disabled for UI atlases to protect contrast.
- AudioWave imports downsample SFX to 44.1 kHz mono OGG and mix bus snapshots ensure compression does not exceed 128 kbps equivalent bitrates on mobile builds.
