# Data Persistence Architecture
## Save Data Structure
- `user://claw_and_snackle/save_v1.dat` encrypted file storing `high_scores`, `settings`, and `tutorial_completed` data.
- JSON payload encrypted with AES-256 CBC; HMAC-SHA256 appended for tamper detection.

## Persistence Strategy
- `PersistenceService` autoload writes via worker thread to avoid frame stalls.
- Saves triggered on wave completion and settings changes with debounce timers.
- Schema versioned with migration helpers for future updates.
