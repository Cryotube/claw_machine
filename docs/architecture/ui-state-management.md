# UI State Management
- HUD uses `StateController` scripts with enums to transition component states explicitly.
- Quick toggles maintain local state mirrored to `SettingsProfile` for persistence.
- `ModalStack` service ensures only the topmost overlay handles input.
