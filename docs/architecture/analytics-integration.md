# Analytics Integration
## Event Design
| Event ID | Trigger | Payload |
|----------|---------|---------|
| `order_fulfilled` | Successful delivery | `wave`, `combo`, `time_remaining`, `fish_type` |
| `order_failed` | Patience expiry or wrong item | `wave`, `reason`, `fish_type` |
| `tutorial_step_completed` | Completing a tutorial step | `step_id`, `duration` |
| `toggle_accessibility` | Changing a quick toggle | `setting`, `value` |

## Implementation
- `AnalyticsStub` GDScript singleton queues events and writes JSONL to `user://analytics.log` on flush; ready for future network uploader.
- Thread-safe queue allows headless execution without blocking gameplay.
- Performance telemetry events (`frame_time`, `memory_static`, `battery_pct`) captured once per wave; analytics payload enables correlating player churn with device strain.
