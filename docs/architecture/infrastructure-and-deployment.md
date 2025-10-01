# Infrastructure and Deployment
## Godot Build Configuration
- Wrapper script ensures all CLI commands pass `--path .` and other required flags.
- Export presets capture iOS/Android credentials; secrets injected via environment variables.

## Deployment Strategy
- MVP uses manual local exports validated via wrapper.
- Future GitHub Actions workflow will call the same script for tests and exports, uploading artifacts for QA.

## Environments
- `dev` (debug overlays), `release` (optimized), and `profiling` (instrumented) build configurations toggled through feature flags.

## Platform-Specific Settings
- iOS: Metal renderer, 60 FPS cap, CoreHaptics entitlements, mobile-safe icon set.
- Android: Vulkan primary, GLES3 fallback, adaptive icons, vibration permission gating.
- Wrapper ensures `--feature mobile` is enabled for mobile builds.

## Release Governance
- **Versioning:** Adopt `MAJOR.MINOR.PATCH-build` (e.g., `0.4.0-b12`). Increment *PATCH* for hotfixes, *MINOR* when gameplay scope changes, and *MAJOR* for beta/launch milestones. Store the current version string in `res://resources/data/version.tres` so builds and analytics stay in sync.
- **Code Signing:**
  - iOS – use the shared `ClawSnackle.mobileprovision` profile and `Godot_ClawSnackle` signing certificate injected via environment variables (`IOS_TEAM_ID`, `IOS_SIGNING_ID`). The export preset references these placeholders and the CLI wrapper fails fast if they are missing.
  - Android – keystore `ci/keystores/clawsnackle.keystore` encrypted at rest; CI unlocks it with `ANDROID_KEYSTORE_PASS` / `ANDROID_KEY_PASS`. Local exports reference the same aliases to avoid mismatched signatures between environments.
- **Release Branching:** Tag every QA-ready build from `release/<version>` branches so rollback candidates remain reproducible with the exact export presets and assets.

## Quality Assurance Matrix
| Platform | Devices | OS Targets | Required Checks |
|----------|---------|-----------|-----------------|
| iOS | iPhone 12, iPhone 14 Pro | iOS 17+ | Headless test suite, manual playtest (portrait/landscape), thermal profile, haptics validation |
| Android | Pixel 6, Galaxy S21 | Android 13+ | Headless test suite, manual playtest, battery drain sample (15 min), adaptive icon verification |
| Emulator (sanity) | Android Studio Pixel 6 | Latest stable | Boot smoke test only – do not use for performance gating |

## Live Operations Pipeline
- Establish a bi-weekly update cadence for MVP: Wednesday code freeze, Thursday QA, Friday submission.
- Track mandatory pre-release gates: checklist sign-off, localized strings updated, analytics schema diffed, crash log review, and store metadata audit.
- Maintain `ops/release-readme.md` capturing submission notes, storefront changes, and communication plans for each release.
