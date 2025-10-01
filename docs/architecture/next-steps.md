# Next Steps
1. Review the architecture with game design and UX stakeholders for alignment.
2. Initialize the Godot 4.5 project, configure autoloads, InputMap, Resources, and commit `scripts/godot-cli.sh`.
3. Run baseline headless tests (`scripts/godot-cli.sh --headless --path . --test`) to validate tooling.
4. Coordinate with the Game Scrum Master to seed implementation stories based on this document.

## Game Developer Prompt
> Implement approved stories referencing `docs/architecture.md`. Use typed GDScript for every subsystem—from UI and orchestration through claw control, pooling, and analytics—and keep scripts in the shared `src/` namespace. Follow TDD strictly: author GUT coverage first, then run `scripts/godot-cli.sh --headless --path . --test` and the necessary export commands. Maintain the 60+ FPS target by honoring pooling, soft-body solver constraints, and autoload patterns. Update the story’s Dev Agent Record and ensure all HUD accessibility toggles remain responsive.
