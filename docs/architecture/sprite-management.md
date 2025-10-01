# Sprite Management
## Organization
- Textures under `res://art/textures/` grouped by HUD, characters, FX.
- Atlases generated with Godot importer; naming convention `hud_atlas_*` for clarity.

## Optimization
- Mobile builds use lossy compression (~0.7 quality) and mipmaps.
- Animated sprites converted to `SpriteFrames` resources to minimize runtime work.
