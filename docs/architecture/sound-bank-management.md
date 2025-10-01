# Sound Bank Management
## Asset Organization
- Assets under `res://audio/` categorised by `music/`, `sfx/`, `vo/`, `ui/` with metadata stored in `SoundBank.tres`.

## Streaming Strategy
- Music streamed from OGG; SFX preloaded into memory.
- Streaming progress monitored to avoid stutters; export tests ensure required assets are packaged.
