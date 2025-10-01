# UI Architecture
## UI System Selection
- Godot Control nodes with typed GDScript logic; no external UI frameworks.
- `UIManager` autoload coordinates theme swaps, orientation adjustments, and quick toggles.
- Animations handled via `AnimationPlayer` resources to stay performant.

## UI Navigation System
- Main menu uses stacked buttons sized for thumb reach with focus hints for controllers.
- In-session HUD sits on a dedicated `CanvasLayer` to avoid interfering with 3D content.
- Pause overlay uses a centered card with safe-area padding and accessible focus traversal.
