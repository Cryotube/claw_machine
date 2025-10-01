# Sound Bank Management
## Asset Organization
- Assets live under `res://resources/audio/` (categorised by `music/`, `sfx/`, `vo/`, `ui/`) with metadata stored in `SoundBank.tres` so gameplay scenes can reference the shipped mixes directly.

## Streaming Strategy
- Music streamed from OGG; SFX preloaded into memory.
- Streaming progress monitored to avoid stutters; export tests ensure required assets are packaged.
