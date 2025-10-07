# Data Persistence Architecture
## Save Data Structure
- `user://claw_and_snackle/save_v1.dat` encrypted file storing run history, session summaries, tutorial state, accessibility palette, and options payloads.
- JSON payload encrypted with AES-256 CBC + PKCS7 padding; HMAC-SHA256 appended for tamper detection before writing to disk.
- Schema metadata persisted alongside payload (`schema_version`, `saved_at_ms`) to support forward-compatible migrations (see `res://resources/data/save_schema_v1.tres`).
- Run history capped at 25 records, newest-first, each entry capturing `{score, wave, failure_reason, duration_sec, combo_peak, timestamp_sec}`.
- Summary block caches `high_score`, `previous_high_score`, `previous_score`, `best_wave`, `fastest_duration_sec`, and `last_run` snapshot for Records UI.

## Persistence Strategy
- `PersistenceService` autoload serialises state on a background tick (500 ms debounce) and exposes `flush_now()` for deterministic writes during tests.
- Saves triggered by settings changes, accessibility toggles, tutorial completion, and run summaries emitted from `RunSummaryService`.
- AES-256 keys derived per-device using PBKDF2 (12k rounds) with per-file salt + IV; authenticated writes leverage backup/temporary files to resist corruption.
- Schema versioned with migration helpers for future updates and validated against `save_schema_v1.tres`.

## Run Summary Integration
- `RunSummaryService` (session-scoped node) aggregates score, wave, combo peak, failure reason, and wave history while broadcasting `run_summary_ready`.
- `OrderResolutionPipeline` finalises runs through `RunSummaryService` and persists the resulting summary via `PersistenceService.append_run_record`.
- `SignalHub` distributes `run_summary_ready`, `high_score_updated`, and `save_operation_failed` events to HUD widgets and analytics listeners.
- Session HUD includes a `HighScorePanel` reacting to real-time score deltas (via `score_updated`) and persistence confirmed highs, keeping UX aligned with UX brief.
