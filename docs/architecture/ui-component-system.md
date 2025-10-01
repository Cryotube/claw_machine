# UI Component System
## Component Library
- `OrderBanner.tscn`, `PatienceMeter.tscn`, `VirtualJoystick.tscn`, `QuickToggle.tscn`, and `WaveSummaryCard.tscn` live under `res://ui/components/` with typed scripts.
- Components emit domain signals consumed by services via `SignalHub`.

## Data Binding
- Signal-based binding with typed DTOs from `OrderService` to `SessionHUD` avoids fragile string lookups.
- `Settings` autoload emits structured changes consumed by interested components to update colors, haptics, and layouts live.

## Localization Workflow
- Translatable strings live in `res://resources/i18n/strings.csv`; designers author updates via Google Sheets and export CSV to maintain consistent keys.
- `LocalizationService` autoload loads the CSV at boot and exposes `tr_context(key, context_data)` helpers so HUD components remain data-driven.
- Build scripts validate that every new string has English and Japanese columns populated before allowing merge; missing entries fail the headless validation step.
