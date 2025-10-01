#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: Godot binary not found at $GODOT_BIN" >&2
  exit 1
fi

# If no --path passed, default to repository root so Godot picks up project.godot.
if [[ " $* " != *" --path "* ]]; then
  set -- --path "$SCRIPT_DIR" "$@"
fi

exec "$GODOT_BIN" "$@"
