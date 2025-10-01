# Performance and Security Considerations
## Save Data Security
- **Encryption:** AES-256 CBC with device-based key derivation (PBKDF2) and per-file salt.
- **Validation:** HMAC-SHA256 to detect tampering.
- **Anti-Tampering:** Versioned payload with checksum fallback; on failure, revert to backup.

## Platform Security Requirements
- Mobile permissions limited to haptics/vibration and storage; prompt only when needed.
- Comply with App Store / Play Store privacy rules; document offline-only analytics stub.
- Provide privacy policy covering encrypted saves and local analytics logs.

## Performance Budgets
- **Frame Time:** Maintain ≤16.6 ms average and ≤20 ms 99th percentile on target hardware; capture profiler exports for every release build.
- **Scene Memory:** Cap active scene memory at 1.4 GB on iOS and 1.6 GB on Android; monitor via `Performance.get_monitor(Performance.MONITOR_MEMORY_STATIC)` with alerts logged if thresholds are exceeded.
- **Load Times:** Boot-to-menu ≤3 s, menu-to-session ≤2 s, wave-to-wave transitions ≤1 s by preloading assets and using async scene swaps.
- **Battery Envelope:** Session playtests run 15 minutes on Pixel 6 / iPhone 12 should show <6 % battery drop and <40 °C device temperature; throttle particle density and soft-body detail when telemetry exceeds these limits.

## Risk Register (Top 5)
| Risk | Impact | Mitigation | Owner |
|------|--------|-----------|-------|
| Soft-body solver spikes frame time | High | Maintain pooled rigid fallback, run weekly stress scene telemetry | Lead Gameplay Eng |
| Asset bloat inflates memory footprint | Medium | Enforce import presets, validate budgets during PR reviews | Tech Art |
| Battery/thermal throttling | High | Monitor telemetry, auto-toggle low-power mode when temperature exceeds limits | Systems Eng |
| Save data corruption | Medium | Keep dual-write backup strategy, surface recovery UI | Platform Eng |
| Store submission rejection | Medium | Pre-flight privacy checklist, maintain signing docs | Product Ops |

## Rollback and Communication
- Use version tags and export bundle hashes to identify rollback candidates swiftly.
- Publish release notes and known issues internally before store submission; customer-facing notes live in `ops/release-readme.md` (mirrors app store metadata).
- If a blocking issue is found post-release, flip `FeatureFlags.low_power_mode` remotely via config patch and trigger the documented rollback path (hotfix build or store takedown).

## Multiplayer Security
- Not applicable for MVP; documented to avoid accidental scope creep.
