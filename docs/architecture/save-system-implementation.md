# Save System Implementation
- API: `PersistenceService.save_game(GameSnapshot snapshot)` / `load_game()` returning optional snapshot.
- Backup copy maintained; load failure emits `save_corrupted` signal prompting UX notification and fallback to defaults.
