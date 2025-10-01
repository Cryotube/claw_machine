# Sprite Management
## Organization
- Textures live under the shared `res://resources/` tree (e.g., `res://resources/textures/`) grouped by HUD, characters, and FX so feature work can reuse the shipped atlases instead of empty placeholders.
- Atlases generated with Godot importer; naming convention `hud_atlas_*` for clarity.

## Optimization
- Mobile builds use lossy compression (~0.7 quality) and mipmaps.
- Animated sprites converted to `SpriteFrames` resources to minimize runtime work.
