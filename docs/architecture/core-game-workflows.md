# Core Game Workflows
1. **Feature Development** – Write GUT tests first, implement feature, run `scripts/godot-cli.sh --headless --path . --test`, and optional `--check-scenes` smoke tests.
2. **Content Updates** – Designers adjust Resource assets, export new `.tres`, and rerun headless tests to ensure serialization integrity.
3. **Export Validation** – Use wrapper for `--export-release` commands (e.g., `scripts/godot-cli.sh --headless --export-release ios ios_export.pck`). Same commands will be used in CI.
4. **Performance Profiling** – Launch the profiler, record baselines, and commit snapshots; run soft-body stress scene headless to confirm frame timing stays under 16.6 ms.
