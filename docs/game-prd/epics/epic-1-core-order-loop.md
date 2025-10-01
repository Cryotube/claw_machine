# Epic 1: Core Order Fulfillment Loop

## Goal
Deliver a fully playable vertical-slice loop where cat patrons arrive, announce seafood orders, and the player serves the correct item via the claw cabinet while score and service state advance.

## Description
- Aligns with FR1–FR4 for customer flow, order visualization, claw interaction, and fulfillment reset requirements (docs/game-prd/requirements.md).
- Builds on architecture guidance for session composition, autoload services, and signal-driven messaging (docs/architecture/high-level-architecture.md; docs/architecture/game-systems-components.md).
- Establishes typed GDScript services (`OrderService`, `CustomerQueue`, `SessionHUD`) plus the C# claw solver integration needed for responsive gameplay while sustaining 60+ FPS per performance guardrails (docs/architecture/performance-and-security-considerations.md).

### Outcomes
- Cat queue, order banners, and patience meters operate coherently across portrait/landscape layouts.
- Claw rig controller, solver handshake, and grab/release flow validated through Godot headless tests.
- Order fulfillment updates score/life totals and resets the station for the next customer without leaking resources.

## Stories
1. **Story 1.1 – Customer Queue & Order Announcements:** Spawn animated cat patrons with patience meters, connect `OrderService` to HUD banners, and emit order requests through `SignalHub`.
2. **Story 1.2 – Order Visualization & Cabinet Highlighting:** Sync requested seafood indicators between counter UI and freezer cabinet, including resource-driven meshes and colorblind-safe cues.
3. **Story 1.3 – Claw Rig Control and Physics Integration:** Implement `ClawInputController` gesture mapping, connect to the C# `ClawRigSolver`, and validate pool-based seafood grabs.
4. **Story 1.4 – Order Resolution, Scoring, and Reset:** Resolve success/failure via `OrderService`, award score combos, decrement lives, trigger animations, and prep next patron.

## Dependencies & Constraints
- Requires autoload singletons defined in architecture (`GameState`, `OrderService`, `SignalHub`) and session scene tree under `SessionRoot.tscn` (docs/architecture/high-level-architecture.md; docs/architecture/game-systems-components.md).
- HUD components (`OrderBanner.tscn`, `PatienceMeter.tscn`) follow UI component guidelines with static typing and signal bindings (docs/architecture/ui-component-system.md).
- Physics interactions must respect solver iteration limits, soft-body configurations, and pooling strategy (docs/architecture/physics-configuration.md; docs/architecture/node-architecture-details.md).

## Definition of Done
- All four stories pass acceptance criteria and automated tests (GUT/GoDotTest) via `scripts/godot-cli.sh --headless --test` (docs/architecture/test-strategy-and-standards.md).
- Gameplay maintains ≥60 FPS and respects memory budgets during multi-cat waves (docs/architecture/performance-and-security-considerations.md).
- Order lifecycle telemetry hooks and resource pools exhibit no leaks in repeated wave simulations.
- Documentation updated (story files, changelog, QA notes) and scenes validated with headless `--check-scenes` smoke tests.

## Risks & Mitigations
- **Soft-body spikes:** Mitigate with pooled rigid-body fallback per performance guidelines.
- **Signal coupling:** Use `SignalHub` channels defined in architecture to avoid tightly bound nodes.
- **UX regressions:** Validate portrait vs. landscape layouts through manual test cases and keep Control node anchoring per UX specs (docs/architecture/ui-architecture.md).
- **Test coverage gaps:** Enforce TDD red→green→refactor workflow with dedicated fixtures for order/wave resources.
