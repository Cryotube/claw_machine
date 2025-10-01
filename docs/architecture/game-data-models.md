# Game Data Models
1. **OrderDefinition (Resource)** – `id`, `seafood_type`, `prep_style`, `base_score`, `decay_curve`, `tutorial_hint`.
2. **WaveConfig (Resource)** – `wave_id`, `spawn_schedule`, `max_concurrent_cats`, `patience_multiplier`, `cabinet_clutter_level`.
3. **CustomerProfile (Resource)** – `species`, `entry_animation`, `patience_base`, `favorite_orders`, `voice_bank`.
4. **ClawState (GDScript class)** – `position`, `velocity`, `cable_tension`, `gripping`, `grip_force`, `grabbed_item_id`.
5. **CabinetItemDescriptor (Resource)** – `item_id`, `mesh`, `mass`, `grip_threshold`, `pool_size`, `soft_body_config`.
6. **SettingsProfile (ConfigFile/Resource)** – `colorblind_mode`, `haptics_enabled`, `camera_sensitivity`, `audio_mix`.

Resources live under `res://resources/` with validation helpers to guarantee designer edits remain consistent. Test fixtures mirror these resources inside `res://tests/fixtures/` for deterministic TDD.
