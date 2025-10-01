# Audio Mixing Configuration
## Mixer Setup
- Bus compressors/limiters tuned for mobile speakers.
- Exported `AudioMixProfile` resources define mixes for Tutorial, Calm Wave, Intense Wave states.

## Dynamic Mixing
- `AudioDirector` listens to SignalHub events (`patience_warning`, `wave_complete`) to adjust bus gains.
- Sidechain compression dips music when VO plays.
- Haptic intensity scaled with wave difficulty and accessibility settings.
