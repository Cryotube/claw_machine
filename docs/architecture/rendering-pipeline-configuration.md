# Rendering Pipeline Configuration
## Render Pipeline Setup
- Forward+ renderer with SMAA fallback for low-end devices.
- Static GI baked for freezer cabinet; dynamic lighting limited to key/fill lights within session scene.
- Texture import presets enforce ASTC (primary) and ETC2 fallback, with anisotropic filtering capped at 4×.

## Rendering Optimization
- LODs configured for cat patrons and claw machinery; `VisibleOnScreenNotifier3D` disables off-screen clutter updates.
- Cabinet interior uses baked occluders plus `WorldEnvironment` SSAO tuned for mobile; far wall occluders combined with collider masks to prevent overdraw.
- Runtime occlusion culling toggles via `PerformanceFlags.use_occlusion_culling` so low-end devices can disable it without layout changes.
- HUD consolidated into a single `CanvasLayer` with atlas textures to minimise draw calls.
- Soft-body seafood meshes capped under ~500 vertices with simplified materials.
